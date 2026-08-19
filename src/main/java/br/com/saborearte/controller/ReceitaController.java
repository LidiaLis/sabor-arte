package br.com.saborearte.controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.CategoriaDAO;
import br.com.saborearte.dao.ComentarioDAO;
import br.com.saborearte.dao.FavoritoDAO;
import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.dao.IngredienteDAO;
import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.dao.PassoDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Ingrediente;
import br.com.saborearte.model.Log;
import br.com.saborearte.model.Passo;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Receita.StatusAtividade;
import br.com.saborearte.model.Receita.StatusReceita;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.StatusUsuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

/**
 * Porta de entrada única do módulo de receitas.
 *
 * GET carrega uma visão por perfil ou o detalhe único. POST valida novamente
 * perfil, propriedade e estado, executa a operação e aplica PRG. O servlet não
 * mantém Connection ou DAO em campos compartilhados entre requisições.
 */
@WebServlet(urlPatterns={"/ReceitaController","/receitas"})
public class ReceitaController extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int TAMANHO_PUBLICO = 12;
    private static final int TAMANHO_PRIVADO = 10;
    private static final int TAMANHO_MAXIMO = 100;
    private static final String ROTA_CANONICA = "/ReceitaController";
    private static final String JSP_LISTA = "/pages/receitas.jsp";
    private static final String JSP_AUTOR = "/pages/receitas-autor.jsp";
    private static final String JSP_EDITOR = "/pages/receitas-editor.jsp";
    private static final String JSP_DETALHE = "/pages/receita-detalhe.jsp";
    private static final String CSRF_SESSION = "receitaCsrfToken";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        transferirFlash(request);
        prepararCsrf(request);

        String action = normalizar(request.getParameter("action"));
        try (Connection connection = Conexao.getConnection()) {
            Daos daos = new Daos(connection);
            if (action == null) {
                listarPorPerfil(request, response, daos);
                return;
            }
            switch (action) {
                case "detalhar" -> detalhar(request, response, daos);
                case "editar" -> editar(request, response, daos);
                default -> response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ação GET inválida.");
            }
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SecurityException e) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, e.getMessage());
        } catch (SQLException e) {
            logServidor("Falha ao carregar receitas", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Não foi possível carregar as receitas.");
        }
    }

    private void listarPorPerfil(HttpServletRequest request, HttpServletResponse response, Daos daos)
            throws SQLException, ServletException, IOException {
        Usuario usuarioLogado = usuarioLogado(request);
        if (usuarioLogado == null || usuarioLogado.getTipo_usuario() == TipoUsuario.VISITANTE) {
            carregarPublicoVisitante(request, response, daos, usuarioLogado);
        } else if (usuarioLogado.getTipo_usuario() == TipoUsuario.AUTOR) {
            carregarAutor(request, response, daos, usuarioLogado);
        } else if (usuarioLogado.getTipo_usuario() == TipoUsuario.EDITOR) {
            carregarEditor(request, response, daos);
        } else if (usuarioLogado.getTipo_usuario() == TipoUsuario.ADMIN) {
            carregarAdministrador(request, response, daos);
        } else {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
        }
    }

    private void carregarPublicoVisitante(HttpServletRequest request, HttpServletResponse response,
            Daos daos, Usuario usuarioLogado) throws SQLException, ServletException, IOException {
        String busca = normalizar(request.getParameter("busca"));
        Integer idCategoria = inteiroOpcional(request.getParameter("idCategoria"), "Categoria inválida.");
        int page = pagina(request);
        int size = tamanho(request, TAMANHO_PUBLICO);
        int offset = (page - 1) * size;
        List<Receita> receitas = daos.receita.listarPublicadas(busca, idCategoria, size, offset);
        int total = daos.receita.contarPublicadas(busca, idCategoria);

        prepararAtributosLista(request, receitas, daos.categoria.listarCategoriasAtivas(),
                page, size, total, busca, idCategoria, null, StatusAtividade.ativo.name());
        request.setAttribute("perfil", usuarioLogado == null ? "PUBLICO" : "VISITANTE");
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void carregarAutor(HttpServletRequest request, HttpServletResponse response,
            Daos daos, Usuario usuarioLogado) throws SQLException, ServletException, IOException {
        List<Receita> receitas = daos.receita.listarPorAutor(usuarioLogado.getId_usuario());
        prepararAtributosLista(request, receitas, daos.categoria.listarCategoriasAtivas(),
                1, Math.max(1, receitas.size()), receitas.size(), null, null, null, null);
        request.setAttribute("perfil", "AUTOR");
        request.getRequestDispatcher(JSP_AUTOR).forward(request, response);
    }

    private void carregarEditor(HttpServletRequest request, HttpServletResponse response, Daos daos)
            throws SQLException, ServletException, IOException {
        String busca = normalizar(request.getParameter("busca"));
        Integer idCategoria = inteiroOpcional(request.getParameter("idCategoria"), "Categoria inválida.");
        int page = pagina(request);
        int size = tamanho(request, TAMANHO_PRIVADO);
        int offset = (page - 1) * size;
        List<Receita> receitas = daos.receita.listarFilaRevisao(busca, idCategoria, size, offset);
        int total = daos.receita.contarFilaRevisao(busca, idCategoria);

        prepararAtributosLista(request, receitas, daos.categoria.listarCategoriasAtivas(),
                page, size, total, busca, idCategoria,
                StatusReceita.aguardando_aprovacao.name(), StatusAtividade.ativo.name());
        request.setAttribute("perfil", "EDITOR");
        request.setAttribute("dataPainel", DateTimeFormatter.ofPattern("dd/MM/yyyy", Locale.forLanguageTag("pt-BR"))
                .format(java.time.LocalDate.now()));
        request.setAttribute("totalAguardando", total);
        request.setAttribute("totalRevisadasHoje", daos.fluxo.contarRevisadosHoje());
        request.setAttribute("totalPublicadasHoje", daos.receita.contarPublicadasHoje());
        request.setAttribute("totalAgendadas", daos.receita.contarAgendadas());
        Map<Integer, String> tempos = new LinkedHashMap<>();
        for (Receita receita : receitas) {
            tempos.put(receita.getId_receita(), formatarTempoAguardando(receita.getData_criacao_receita()));
        }
        request.setAttribute("tempoAguardandoPorReceita", tempos);
        request.getRequestDispatcher(JSP_EDITOR).forward(request, response);
    }

    private void carregarAdministrador(HttpServletRequest request, HttpServletResponse response, Daos daos)
            throws SQLException, ServletException, IOException {
        String busca = normalizar(request.getParameter("busca"));
        Integer idCategoria = inteiroOpcional(request.getParameter("idCategoria"), "Categoria inválida.");
        StatusAtividade status = statusAtividadeOpcional(request.getParameter("statusAtividade"));
        String statusReceita = statusReceitaOpcional(request.getParameter("statusReceita"));
        int page = pagina(request);
        int size = tamanho(request, TAMANHO_PRIVADO);
        int offset = (page - 1) * size;
        List<Receita> receitas = daos.receita.listarAdministracao(
                busca, status, idCategoria, statusReceita, size, offset);
        int total = daos.receita.contarAdministracao(busca, status, idCategoria, statusReceita);

        prepararAtributosLista(request, receitas, daos.categoria.listarCategoriasAtivas(),
                page, size, total, busca, idCategoria, statusReceita, status == null ? null : status.name());
        request.setAttribute("perfil", "ADMIN");
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void prepararAtributosLista(HttpServletRequest request, List<Receita> receitas,
            List<Categoria> categorias, int page, int size, int total, String busca,
            Integer idCategoria, String statusReceita, String statusAtividade) {
        request.setAttribute("receitas", receitas);
        request.setAttribute("categorias", categorias);
        request.setAttribute("page", page);
        request.setAttribute("size", size);
        request.setAttribute("total", total);
        request.setAttribute("totalPages", Math.max(1, (int) Math.ceil(total / (double) size)));
        request.setAttribute("busca", busca);
        request.setAttribute("idCategoria", idCategoria);
        request.setAttribute("statusReceita", statusReceita);
        request.setAttribute("statusAtividade", statusAtividade);
    }

    private void detalhar(HttpServletRequest request, HttpServletResponse response, Daos daos)
            throws SQLException, ServletException, IOException {
        int idReceita = inteiroPositivo(request.getParameter("idReceita"), "Receita inválida.");
        Usuario usuarioLogado = usuarioLogado(request);
        boolean acessoGerenciado = usuarioLogado != null
                && usuarioLogado.getTipo_usuario() != TipoUsuario.VISITANTE;
        Receita receita = acessoGerenciado
                ? daos.receita.buscarPorIdGerenciado(idReceita)
                : daos.receita.buscarPublicadaAtivaPorId(idReceita);
        if (receita == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Receita não encontrada.");
            return;
        }

        boolean publicaEAtiva = receita.getStatus_receita() == StatusReceita.publicada
                && receita.getStatus_atividade() == StatusAtividade.ativo;
        boolean proprietario = usuarioLogado != null
                && usuarioLogado.getTipo_usuario() == TipoUsuario.AUTOR
                && receita.getUsuario() == usuarioLogado.getId_usuario();
        boolean moderador = usuarioLogado != null
                && (usuarioLogado.getTipo_usuario() == TipoUsuario.EDITOR
                    || usuarioLogado.getTipo_usuario() == TipoUsuario.ADMIN);
        if (!publicaEAtiva && !proprietario && !moderador) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Acesso negado à receita.");
            return;
        }

        boolean autenticadoAtivo = usuarioLogado != null
                && usuarioLogado.getStatus_usuario() == StatusUsuario.ATIVO;
        request.setAttribute("receita", receita);
        request.setAttribute("ingredientes", daos.ingrediente.listarIngredientesPorReceita(idReceita));
        request.setAttribute("passos", daos.passo.listarPassosPorReceita(idReceita));
        request.setAttribute("comentarios", publicaEAtiva
                ? daos.comentario.listarComentariosPorReceita(idReceita)
                : Collections.emptyList());
        request.setAttribute("historicoFluxo", proprietario || moderador
                ? daos.fluxo.listarPorReceita(idReceita)
                : Collections.emptyList());
        request.setAttribute("favorita", autenticadoAtivo
                && daos.favorito.isFavorito(usuarioLogado.getId_usuario(), idReceita));
        request.setAttribute("podeEditar", proprietario && podeEditar(receita));
        request.setAttribute("podeModerar", moderador
                && receita.getStatus_receita() == StatusReceita.aguardando_aprovacao);
        request.setAttribute("podeComentar", autenticadoAtivo && publicaEAtiva);
        request.setAttribute("podeAlterarAtividade", usuarioLogado != null
                && (usuarioLogado.getTipo_usuario() == TipoUsuario.ADMIN || proprietario));
        request.getRequestDispatcher(JSP_DETALHE).forward(request, response);
    }

    private void editar(HttpServletRequest request, HttpServletResponse response, Daos daos)
            throws SQLException, ServletException, IOException {
        Usuario usuarioLogado = exigirAutor(request);
        int idReceita = inteiroPositivo(request.getParameter("idReceita"), "Receita inválida.");
        Receita receita = daos.receita.buscarPorIdGerenciado(idReceita);
        if (receita == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Receita não encontrada.");
            return;
        }
        if (receita.getUsuario() != usuarioLogado.getId_usuario()) {
            throw new SecurityException("Receita não pertence ao autor logado.");
        }
        if (receita.getStatus_receita() != StatusReceita.rascunho
                && receita.getStatus_receita() != StatusReceita.rejeitada) {
            throw new SecurityException("Somente rascunhos ou receitas rejeitadas podem ser editados.");
        }

        request.setAttribute("receitaEdicao", receita);
        request.setAttribute("ingredientesEdicao", daos.ingrediente.listarIngredientesPorReceita(idReceita));
        request.setAttribute("passosEdicao", daos.passo.listarPassosPorReceita(idReceita));
        request.setAttribute("abrirFormularioReceita", Boolean.TRUE);
        carregarAutor(request, response, daos, usuarioLogado);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        Usuario usuarioLogado = usuarioLogado(request);
        if (usuarioLogado == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        if (!validarCsrf(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Token de segurança inválido.");
            return;
        }

        String action = normalizar(request.getParameter("action"));
        if (action == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ação POST obrigatória.");
            return;
        }

        try (Connection connection = Conexao.getConnection()) {
            Daos daos = new Daos(connection);
            switch (action) {
                case "salvarRascunho" -> criarReceita(request, connection, daos, false);
                case "enviarRevisao" -> enviarRevisao(request, connection, daos);
                case "atualizarRascunho" -> atualizarReceita(request, connection, daos, false);
                case "atualizarEnviarRevisao" -> atualizarReceita(request, connection, daos, true);
                case "aprovar" -> moderarReceita(request, connection, daos, true);
                case "rejeitar" -> moderarReceita(request, connection, daos, false);
                case "alterarAtividade" -> alterarAtividade(request, connection, daos);
                default -> {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ação POST inválida.");
                    return;
                }
            }
            response.sendRedirect(request.getContextPath() + ROTA_CANONICA);
        } catch (IllegalArgumentException | IllegalStateException e) {
            definirFlash(request, "erro", e.getMessage());
            response.sendRedirect(request.getContextPath() + ROTA_CANONICA);
        } catch (SecurityException e) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, e.getMessage());
        } catch (SQLException e) {
            logServidor("Falha ao alterar receita", e);
            definirFlash(request, "erro", "Não foi possível concluir a operação da receita.");
            response.sendRedirect(request.getContextPath() + ROTA_CANONICA);
        }
    }

    private void criarReceita(HttpServletRequest request, Connection connection, Daos daos, boolean enviar)
            throws SQLException {
        Usuario autor = exigirAutor(request);
        Receita receita = montarReceita(request, daos, autor,
                enviar ? StatusReceita.aguardando_aprovacao : StatusReceita.rascunho);
        ItensFormulario itens = lerItens(request);
        executarTransacao(connection, () -> {
            int idReceita = daos.receita.cadastrarReceita(receita);
            salvarItens(daos, idReceita, itens);
            if (enviar) daos.receita.registrarFluxo(idReceita, autor.getId_usuario(), StatusFluxo.PENDENTE, null);
            registrarAuditoria(daos, autor, enviar ? "ENVIAR_REVISAO" : "CRIAR_RASCUNHO",
                    (enviar ? "Receita criada e enviada para revisão: " : "Rascunho criado: ")
                            + receita.getTitulo_receita());
        });
        definirFlash(request, "sucesso", enviar ? "Receita enviada para revisão." : "Rascunho salvo com sucesso.");
    }

    private void enviarRevisao(HttpServletRequest request, Connection connection, Daos daos) throws SQLException {
        String id = normalizar(request.getParameter("idReceita"));
        if (id == null) {
            criarReceita(request, connection, daos, true);
            return;
        }
        Usuario autor = exigirAutor(request);
        int idReceita = inteiroPositivo(id, "Receita inválida.");
        executarTransacao(connection, () -> {
            daos.receita.enviarParaRevisao(idReceita, autor.getId_usuario());
            daos.receita.registrarFluxo(idReceita, autor.getId_usuario(), StatusFluxo.PENDENTE, null);
            registrarAuditoria(daos, autor, "ENVIAR_REVISAO", "Receita enviada para revisão: " + idReceita);
        });
        definirFlash(request, "sucesso", "Receita enviada para revisão.");
    }

    private void atualizarReceita(HttpServletRequest request, Connection connection, Daos daos, boolean enviar)
            throws SQLException {
        Usuario autor = exigirAutor(request);
        int idReceita = inteiroPositivo(request.getParameter("idReceita"), "Receita inválida.");
        Receita receita = montarReceita(request, daos, autor,
                enviar ? StatusReceita.aguardando_aprovacao : StatusReceita.rascunho);
        receita.setId_receita(idReceita);
        ItensFormulario itens = lerItens(request);
        executarTransacao(connection, () -> {
            daos.receita.atualizarReceitaEditavel(receita);
            daos.ingrediente.removerIngredientesDaReceita(idReceita);
            daos.passo.excluirPassosDaReceita(idReceita);
            salvarItens(daos, idReceita, itens);
            daos.receita.atualizarStatusReceita(idReceita,
                    enviar ? StatusReceita.aguardando_aprovacao : StatusReceita.rascunho);
            if (enviar) daos.receita.registrarFluxo(idReceita, autor.getId_usuario(), StatusFluxo.PENDENTE, null);
            registrarAuditoria(daos, autor, enviar ? "ENVIAR_REVISAO" : "ATUALIZAR_RASCUNHO",
                    (enviar ? "Receita atualizada e reenviada: " : "Rascunho atualizado: ")
                            + receita.getTitulo_receita());
        });
        definirFlash(request, "sucesso",
                enviar ? "Receita atualizada e enviada para revisão." : "Rascunho atualizado com sucesso.");
    }

    private void moderarReceita(HttpServletRequest request, Connection connection, Daos daos, boolean aprovar)
            throws SQLException {
        Usuario moderador = exigirModerador(request);
        int idReceita = inteiroPositivo(request.getParameter("idReceita"), "Receita inválida.");
        String motivo = normalizar(request.getParameter("motivo"));
        if (!aprovar && motivo == null) throw new IllegalArgumentException("Motivo da rejeição é obrigatório.");
        Receita receita = daos.receita.buscarPorIdGerenciado(idReceita);
        if (receita == null) throw new IllegalArgumentException("Receita não encontrada.");
        executarTransacao(connection, () -> {
            daos.receita.atualizarStatusComFluxo(idReceita, moderador.getId_usuario(),
                    aprovar ? StatusReceita.publicada : StatusReceita.rejeitada,
                    aprovar ? StatusFluxo.APROVADO : StatusFluxo.REJEITADO,
                    aprovar ? null : motivo);
            registrarAuditoria(daos, moderador, aprovar ? "APROVAR_RECEITA" : "REJEITAR_RECEITA",
                    (aprovar ? "Receita aprovada: " : "Receita rejeitada: ") + receita.getTitulo_receita());
        });
        definirFlash(request, "sucesso", aprovar ? "Receita aprovada e publicada." : "Receita rejeitada.");
    }

    private void alterarAtividade(HttpServletRequest request, Connection connection, Daos daos) throws SQLException {
        Usuario usuario = usuarioLogado(request);
        int idReceita = inteiroPositivo(request.getParameter("idReceita"), "Receita inválida.");
        StatusAtividade status = statusAtividadeObrigatorio(request.getParameter("statusAtividade"));
        Receita receita = daos.receita.buscarPorIdGerenciado(idReceita);
        if (receita == null) throw new IllegalArgumentException("Receita não encontrada.");
        boolean admin = usuario.getTipo_usuario() == TipoUsuario.ADMIN;
        boolean proprietario = usuario.getTipo_usuario() == TipoUsuario.AUTOR
                && receita.getUsuario() == usuario.getId_usuario();
        if (!admin && !proprietario) throw new SecurityException("Sem permissão para alterar a atividade.");
        executarTransacao(connection, () -> {
            daos.receita.alterarAtividade(idReceita, status, admin ? null : usuario.getId_usuario());
            registrarAuditoria(daos, usuario, "ALTERAR_ATIVIDADE",
                    "Receita " + idReceita + " alterada para " + status.name());
        });
        definirFlash(request, "sucesso", "Atividade da receita atualizada.");
    }

    private Receita montarReceita(HttpServletRequest request, Daos daos, Usuario autor, StatusReceita status)
            throws SQLException {
        String titulo = obrigatorio(request.getParameter("titulo"), "Título é obrigatório.");
        int idCategoria = inteiroPositivo(request.getParameter("idCategoria"), "Categoria inválida.");
        int tempoPreparo = inteiroPositivo(request.getParameter("tempoPreparo"), "Tempo de preparo inválido.");
        String rendimento = obrigatorio(request.getParameter("rendimento"), "Rendimento é obrigatório.");
        Categoria categoria = daos.categoria.buscarCategoriaPorId(idCategoria);
        if (categoria == null || categoria.getStatus_categoria() != Categoria.StatusCategoria.ATIVA) {
            throw new IllegalArgumentException("Categoria inválida ou inativa.");
        }
        Receita receita = new Receita();
        receita.setCategoria(idCategoria);
        receita.setUsuario(autor.getId_usuario());
        receita.setTitulo_receita(titulo);
        receita.setDescricao_receita(valorOuVazio(request.getParameter("descricao")));
        receita.setTempo_preparo_receita(tempoPreparo);
        receita.setRendimento_receita(rendimento);
        receita.setImagem_receita(valorOuVazio(request.getParameter("imagemUrl")));
        receita.setStatus_receita(status);
        receita.setStatus_atividade(StatusAtividade.ativo);
        return receita;
    }

    private ItensFormulario lerItens(HttpServletRequest request) {
        String[] nomes = valores(request, "ingredienteNome");
        String[] quantidades = valores(request, "ingredienteQuantidade");
        String[] unidades = valores(request, "ingredienteUnidade");
        String[] titulos = valores(request, "passoTitulo");
        String[] descricoes = valores(request, "passoDescricao");
        if (nomes.length == 0 || nomes.length != quantidades.length || nomes.length != unidades.length) {
            throw new IllegalArgumentException("Informe ao menos um ingrediente com quantidade e unidade.");
        }
        BigDecimal[] quantidadesDecimais = new BigDecimal[quantidades.length];
        for (int i = 0; i < nomes.length; i++) {
            nomes[i] = obrigatorio(nomes[i], "Nome do ingrediente é obrigatório.");
            unidades[i] = obrigatorio(unidades[i], "Unidade do ingrediente é obrigatória.");
            try {
                BigDecimal quantidade = new BigDecimal(obrigatorio(quantidades[i], "Quantidade é obrigatória."));
                if (quantidade.signum() <= 0) throw new NumberFormatException();
                quantidadesDecimais[i] = quantidade;
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("A quantidade deve ser um número positivo.");
            }
        }
        if (descricoes.length == 0) throw new IllegalArgumentException("Informe ao menos um passo.");
        if (titulos.length != 0 && titulos.length != descricoes.length) {
            throw new IllegalArgumentException("Títulos e descrições dos passos estão desalinhados.");
        }
        for (int i = 0; i < descricoes.length; i++) {
            descricoes[i] = obrigatorio(descricoes[i], "Descrição do passo é obrigatória.");
        }
        return new ItensFormulario(nomes, quantidadesDecimais, unidades, titulos, descricoes);
    }

    private void salvarItens(Daos daos, int idReceita, ItensFormulario itens) throws SQLException {
        for (int i = 0; i < itens.nomes.length; i++) {
            Ingrediente ingrediente = daos.ingrediente.buscarOuCriar(itens.nomes[i]);
            daos.ingrediente.adicionarIngredienteNaReceita(idReceita, ingrediente.getId_ingrediente(),
                    itens.quantidades[i], itens.unidades[i]);
        }
        for (int i = 0; i < itens.descricoes.length; i++) {
            String titulo = i < itens.titulos.length ? normalizar(itens.titulos[i]) : null;
            daos.passo.cadastrarPasso(new Passo(idReceita, i + 1,
                    titulo == null ? "Passo " + (i + 1) : titulo, itens.descricoes[i]));
        }
    }

    private void registrarAuditoria(Daos daos, Usuario usuario, String acao, String descricao)
            throws SQLException {
        Log log = new Log();
        log.setUsuario(usuario.getId_usuario());
        log.setAcao_log(acao);
        log.setDetalhe_log(descricao);
        log.setEntidade_log("RECEITA");
        daos.log.registrar(log, "RECEITA");
    }

    private void executarTransacao(Connection connection, TrabalhoSql trabalho) throws SQLException {
        boolean autoCommitAnterior = connection.getAutoCommit();
        try {
            connection.setAutoCommit(false);
            trabalho.executar();
            connection.commit();
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(autoCommitAnterior);
        }
    }

    private void transferirFlash(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return;
        for (String nome : new String[] { "sucesso", "erro" }) {
            Object valor = session.getAttribute(nome);
            if (valor != null) {
                request.setAttribute(nome, valor);
                session.removeAttribute(nome);
            }
        }
    }

    private void definirFlash(HttpServletRequest request, String nome, String mensagem) {
        request.getSession(true).setAttribute(nome, mensagem);
    }

    private Usuario usuarioLogado(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session == null ? null : (Usuario) session.getAttribute("usuarioLogado");
    }

    private Usuario exigirAutor(HttpServletRequest request) {
        Usuario usuarioLogado = usuarioLogado(request);
        if (usuarioLogado == null || usuarioLogado.getTipo_usuario() != TipoUsuario.AUTOR
                || usuarioLogado.getStatus_usuario() != StatusUsuario.ATIVO) {
            throw new SecurityException("Acesso restrito a autores ativos.");
        }
        return usuarioLogado;
    }

    private Usuario exigirModerador(HttpServletRequest request) {
        Usuario usuarioLogado = usuarioLogado(request);
        if (usuarioLogado == null || usuarioLogado.getStatus_usuario() != StatusUsuario.ATIVO
                || (usuarioLogado.getTipo_usuario() != TipoUsuario.EDITOR
                    && usuarioLogado.getTipo_usuario() != TipoUsuario.ADMIN)) {
            throw new SecurityException("Acesso restrito a editores e administradores ativos.");
        }
        return usuarioLogado;
    }

    private boolean podeEditar(Receita receita) {
        return receita.getStatus_receita() == StatusReceita.rascunho
                || receita.getStatus_receita() == StatusReceita.rejeitada;
    }

    private int pagina(HttpServletRequest request) {
        return inteiroComPadrao(request.getParameter("page"), 1, 1, Integer.MAX_VALUE, "Página inválida.");
    }

    private int tamanho(HttpServletRequest request, int padrao) {
        return inteiroComPadrao(request.getParameter("size"), padrao, 1, TAMANHO_MAXIMO, "Tamanho inválido.");
    }

    private int inteiroComPadrao(String valor, int padrao, int minimo, int maximo, String mensagem) {
        if (normalizar(valor) == null) return padrao;
        try {
            int numero = Integer.parseInt(valor);
            if (numero < minimo || numero > maximo) throw new NumberFormatException();
            return numero;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(mensagem);
        }
    }

    private int inteiroPositivo(String valor, String mensagem) {
        if (normalizar(valor) == null) throw new IllegalArgumentException(mensagem);
        return inteiroComPadrao(valor, -1, 1, Integer.MAX_VALUE, mensagem);
    }

    private Integer inteiroOpcional(String valor, String mensagem) {
        if (normalizar(valor) == null) return null;
        return inteiroPositivo(valor, mensagem);
    }

    private StatusAtividade statusAtividadeOpcional(String valor) {
        if (normalizar(valor) == null) return null;
        return statusAtividadeObrigatorio(valor);
    }

    private String statusReceitaOpcional(String valor) {
        String normalizado = normalizar(valor);
        if (normalizado == null) return null;
        try {
            return StatusReceita.valueOf(normalizado.toLowerCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Status da receita inválido.");
        }
    }

    private void prepararCsrf(HttpServletRequest request) {
        if (usuarioLogado(request) == null) return;
        HttpSession session = request.getSession(true);
        String token = (String) session.getAttribute(CSRF_SESSION);
        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute(CSRF_SESSION, token);
        }
        request.setAttribute("csrfToken", token);
    }

    private boolean validarCsrf(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        Object esperado = session.getAttribute(CSRF_SESSION);
        String recebido = request.getParameter("csrfToken");
        return esperado instanceof String && recebido != null
                && MessageDigest.isEqual(((String) esperado).getBytes(StandardCharsets.UTF_8),
                        recebido.getBytes(StandardCharsets.UTF_8));
    }

    private StatusAtividade statusAtividadeObrigatorio(String valor) {
        try {
            return StatusAtividade.valueOf(obrigatorio(valor, "Status de atividade obrigatório.")
                    .toLowerCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Status de atividade inválido.");
        }
    }

    private String obrigatorio(String valor, String mensagem) {
        String normalizado = normalizar(valor);
        if (normalizado == null) throw new IllegalArgumentException(mensagem);
        return normalizado;
    }

    private String normalizar(String valor) {
        if (valor == null) return null;
        String resultado = valor.trim();
        return resultado.isEmpty() ? null : resultado;
    }

    private String valorOuVazio(String valor) {
        String normalizado = normalizar(valor);
        return normalizado == null ? "" : normalizado;
    }

    private String[] valores(HttpServletRequest request, String nome) {
        String[] valores = request.getParameterValues(nome);
        return valores == null ? new String[0] : valores;
    }

    private String formatarTempoAguardando(String dataCriacao) {
        if (normalizar(dataCriacao) == null) return "—";
        try {
            LocalDateTime inicio = LocalDateTime.parse(dataCriacao.replace(' ', 'T').substring(0, 19));
            long horas = Math.max(0, Duration.between(inicio, LocalDateTime.now()).toHours());
            if (horas < 1) return "menos de 1h";
            if (horas < 24) return horas + "h";
            long dias = horas / 24;
            return dias + (dias == 1 ? " dia" : " dias");
        } catch (RuntimeException e) {
            return "—";
        }
    }

    private void logServidor(String contexto, Exception e) {
        getServletContext().log(contexto, e);
    }

    @FunctionalInterface
    private interface TrabalhoSql {
        void executar() throws SQLException;
    }

    private static final class ItensFormulario {
        private final String[] nomes;
        private final BigDecimal[] quantidades;
        private final String[] unidades;
        private final String[] titulos;
        private final String[] descricoes;

        private ItensFormulario(String[] nomes, BigDecimal[] quantidades, String[] unidades,
                String[] titulos, String[] descricoes) {
            this.nomes = nomes;
            this.quantidades = quantidades;
            this.unidades = unidades;
            this.titulos = titulos;
            this.descricoes = descricoes;
        }
    }

    private static final class Daos {
        private final ReceitaDAO receita;
        private final CategoriaDAO categoria;
        private final IngredienteDAO ingrediente;
        private final PassoDAO passo;
        private final FluxoDAO fluxo;
        private final ComentarioDAO comentario;
        private final FavoritoDAO favorito;
        private final LogDAO log;

        private Daos(Connection connection) {
            receita = new ReceitaDAO(connection);
            categoria = new CategoriaDAO(connection);
            ingrediente = new IngredienteDAO(connection);
            passo = new PassoDAO(connection);
            fluxo = new FluxoDAO(connection);
            comentario = new ComentarioDAO(connection);
            favorito = new FavoritoDAO(connection);
            log = new LogDAO(connection);
        }
    }
}
