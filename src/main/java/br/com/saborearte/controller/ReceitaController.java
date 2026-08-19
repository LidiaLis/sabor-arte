package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.Collections;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.CategoriaDAO;
import br.com.saborearte.dao.FavoritoDAO;
import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.dao.IngredienteDAO;
import br.com.saborearte.dao.PassoDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Fluxo;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Ingrediente;
import br.com.saborearte.model.Passo;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Receita.StatusAtividade;
import br.com.saborearte.model.Receita.StatusReceita;
import br.com.saborearte.model.ReceitaIngrediente;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;
import br.com.saborearte.utils.LogUtil;

/**
 * Controller responsavel pela tela de revisao/gestao de receitas do editor
 * (receitas-editor.jsp).
 *
 * REESCRITO no mesmo padrao do CategoriaController:
 *  - GET forward direto pra JSP (sem JSON), com mensagens flash de
 *    sucesso/erro lidas da sessao e limpas em seguida;
 *  - POST em PRG (Post-Redirect-Get): cada acao processa e redireciona
 *    de volta pro proprio controller, nunca forward direto no POST;
 *  - catch (Exception e) generico nas acoes (mesmo estilo do
 *    CategoriaController), evitando SQLException/NumberFormatException
 *    nao tratada;
 *  - isAdmin / isAdminOuEditor / isBlank / setErroERedirect copiados do
 *    mesmo padrao usado no CategoriaController.
 *
 * Acoes esperadas:
 *   GET  (sem parametro "acao", ou acao=listar) -> lista receitas (filtro + paginacao)
 *   GET  ?acao=detalhar&id=X                    -> detalhe da receita + historico de fluxo
 *   POST ?action=aprovar                        -> aprova a receita (registra Fluxo)
 *   POST ?action=rejeitar                       -> rejeita a receita, com motivo (registra Fluxo)
 *   POST ?action=publicar                       -> publica a receita ja aprovada (registra Fluxo)
 *   POST ?action=toggleStatus                   -> ativa/inativa a receita (ReceitaDAO)
 *
 * PENDENCIAS (confirmar contra os models reais):
 *  - StatusFluxo.PUBLICADO: so confirmei APROVADO/REJEITADO no FluxoDAO real;
 *    se o enum nao tiver PUBLICADO, ajustar o metodo publicar() abaixo.
 *  - StatusAtividade.ATIVA: usado so pro rotulo da mensagem de sucesso do
 *    toggleStatus, seguindo o mesmo estilo do alterarStatus do CategoriaController;
 *    confirmar se o valor do enum e esse mesmo.
 *  - Nomes dos JSPs (/pages/receitas-editor.jsp e /pages/receita-detalhe.jsp)
 *    sao suposicao, ajustar pros nomes reais das telas.
 */
@WebServlet("/receitas")
public class ReceitaController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private ReceitaDAO receitaDAO;
    private FluxoDAO fluxoDAO;
    private CategoriaDAO categoriaDAO;
    private IngredienteDAO ingredienteDAO;
    private PassoDAO passoDAO;
    private FavoritoDAO favoritoDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            receitaDAO = new ReceitaDAO(conexao);
            fluxoDAO = new FluxoDAO(conexao);
            categoriaDAO = new CategoriaDAO(conexao);
            ingredienteDAO = new IngredienteDAO(conexao);
            passoDAO = new PassoDAO(conexao);
            favoritoDAO = new FavoritoDAO(conexao);
            System.out.println("ReceitaController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar ReceitaController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null) {
            String sucesso = (String) session.getAttribute("sucesso");
            String erro = (String) session.getAttribute("erro");
            if (sucesso != null) { request.setAttribute("sucesso", sucesso); session.removeAttribute("sucesso"); }
            if (erro != null) { request.setAttribute("erro", erro); session.removeAttribute("erro"); }
        }

        String acao = request.getParameter("acao");
        if (acao == null) acao = "listar";

        try {
            switch (acao) {
                case "detalhar" -> detalhar(request, response);
                default -> listarPorPerfil(request, response);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar receitas: " + e.getMessage());
            request.getRequestDispatcher("/pages/receitas.jsp").forward(request, response);
        }
    }

    private void listarPorPerfil(HttpServletRequest request, HttpServletResponse response) throws Exception {
        Usuario usuario = usuarioLogado(request);
        request.setAttribute("categorias", categoriaDAO.listarCategoriasAtivas());

        if (usuario == null || usuario.getTipo_usuario() == TipoUsuario.VISITANTE) {
            String busca = request.getParameter("busca");
            Integer categoriaId = parseIntegerOrNull(request.getParameter("categoriaId"));
            int page = Math.max(1, parseIntOrDefault(request.getParameter("page"), 1));
            int limite = 12;
            request.setAttribute("receitas", receitaDAO.listarReceitasPublicadas(busca, categoriaId, limite, (page - 1) * limite));
            request.setAttribute("total", receitaDAO.contarReceitasPublicadas(busca, categoriaId));
            request.setAttribute("page", page);
            request.getRequestDispatcher("/pages/receitas.jsp").forward(request, response);
            return;
        }

        if (usuario.getTipo_usuario() == TipoUsuario.AUTOR) {
            request.setAttribute("receitas", receitaDAO.listarReceitasPorAutor(usuario.getId_usuario()));
            request.getRequestDispatcher("/pages/receitas-autor.jsp").forward(request, response);
            return;
        }

        listar(request, response);
    }

    // ===== LISTAGEM (filtro + paginacao) =====
    private void listar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String filtro = request.getParameter("filtro"); // texto de busca (titulo, autor...)
        String statusParam = request.getParameter("status"); // ATIVA / INATIVA / null=todas
        String autorIdParam = request.getParameter("autorId");
        int page = parseIntOrDefault(request.getParameter("page"), 1);
        int size = parseIntOrDefault(request.getParameter("size"), 10);

        StatusAtividade status = null;
        if (!isBlank(statusParam)) {
            try {
                status = StatusAtividade.valueOf(statusParam.toLowerCase());
            } catch (IllegalArgumentException e) {
                request.setAttribute("erro", "Status invalido: " + statusParam);
            }
        }
        Integer autorId = (!isBlank(autorIdParam)) ? Integer.parseInt(autorIdParam) : null;

        // ATENCAO: isto lista por StatusAtividade (ativa/inativa), nao pelo status
        // de fluxo (pendente/aprovada/rejeitada). Se a tela precisar filtrar por
        // status de REVISAO, sera necessario um metodo novo, algo como:
        //   fluxoDAO.listarReceitasPorStatusFluxo(StatusFluxo status, String filtro, int page, int size)
        // que junte Receita com o ultimo registro de Fluxo de cada uma.
        List<Receita> receitas = receitaDAO.listarReceitasAdmin(filtro, status, autorId, page, size);
        int total = receitaDAO.contarReceitasAdmin(filtro, status, autorId);

        request.setAttribute("receitas", receitas);
        request.setAttribute("total", total);
        request.setAttribute("page", page);
        request.setAttribute("size", size);
        request.setAttribute("filtro", filtro);
        request.setAttribute("statusFiltro", statusParam);
        request.setAttribute("categorias", categoriaDAO.listarCategoriasAtivas());

        Usuario usuario = usuarioLogado(request);
        String jsp = usuario != null && usuario.getTipo_usuario() == TipoUsuario.ADMIN
                ? "/pages/receitas.jsp" : "/pages/receitas-editor.jsp";
        request.getRequestDispatcher(jsp).forward(request, response);
    }

    // ===== DETALHE + HISTORICO DE FLUXO =====
    private void detalhar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int id = parseIntOrDefault(request.getParameter("id"), -1);
        if (id == -1) {
            request.setAttribute("erro", "id obrigatorio.");
            listar(request, response);
            return;
        }

        Receita receita = receitaDAO.buscarReceitaPorId(id);
        if (receita == null) {
            request.setAttribute("erro", "Receita nao encontrada.");
            listarPorPerfil(request, response);
            return;
        }

        Usuario usuario = usuarioLogado(request);
        boolean podeVerNaoPublicada = usuario != null
                && (usuario.getTipo_usuario() == TipoUsuario.ADMIN
                    || usuario.getTipo_usuario() == TipoUsuario.EDITOR
                    || (usuario.getTipo_usuario() == TipoUsuario.AUTOR
                        && receita.getUsuario() == usuario.getId_usuario()));
        if (receita.getStatus_receita() != StatusReceita.publicada && !podeVerNaoPublicada) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        List<Fluxo> historico = fluxoDAO.listarPorReceita(id);
        List<ReceitaIngrediente> ingredientes = ingredienteDAO.listarIngredientesPorReceita(id);
        List<Passo> passos = passoDAO.listarPassosPorReceita(id);
        List<Comentario> comentarios = Collections.emptyList();

        request.setAttribute("receita", receita);
        request.setAttribute("historicoFluxo", historico);
        request.setAttribute("ingredientes", ingredientes);
        request.setAttribute("passos", passos);
        request.setAttribute("comentarios", comentarios);
        request.setAttribute("favorita", usuario != null && favoritoDAO.isFavorito(usuario.getId_usuario(), id));
        request.getRequestDispatcher("/pages/receita-detalhe.jsp").forward(request, response);
    }

    // =========================================================================
    // POST
    // =========================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioLogado") == null) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "") {
                case "salvarRascunho" -> salvarNovaReceita(request, response, false);
                case "enviarRevisao"  -> salvarOuEnviarRevisao(request, response);
                case "aprovar"      -> aprovar(request, response);
                case "rejeitar"     -> rejeitar(request, response);
                case "publicar"     -> publicar(request, response);
                case "toggleStatus" -> toggleStatus(request, response);
                default             -> response.sendRedirect(request.getContextPath() + "/receitas");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/receitas");
        }
    }

    private void salvarOuEnviarRevisao(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String receitaId = request.getParameter("receitaId");
        if (isBlank(receitaId)) {
            salvarNovaReceita(request, response, true);
            return;
        }

        Usuario autor = exigirAutor(request);
        Receita receita = buscarReceitaDoAutor(Integer.parseInt(receitaId), autor);
        if (receita.getStatus_receita() != StatusReceita.rascunho
                && receita.getStatus_receita() != StatusReceita.rejeitada) {
            throw new IllegalStateException("Somente rascunhos ou receitas rejeitadas podem ser enviados.");
        }
        receitaDAO.atualizarStatusReceita(receita.getId_receita(), StatusReceita.aguardando_aprovacao);
        registrarFluxo(receita.getId_receita(), autor.getId_usuario(), StatusFluxo.PENDENTE, null);
        LogUtil.registrar(conexao, request, "edicao", "Receita",
                "Receita enviada para revisão: " + receita.getTitulo_receita());
        request.getSession().setAttribute("sucesso", "Receita enviada para revisão.");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    private void salvarNovaReceita(HttpServletRequest request, HttpServletResponse response, boolean enviar)
            throws Exception {
        Usuario autor = exigirAutor(request);
        Receita receita = montarReceita(request, autor, enviar);
        String[] nomes = valores(request, "ingredienteNome");
        String[] quantidades = valores(request, "ingredienteQuantidade");
        String[] unidades = valores(request, "ingredienteUnidade");
        String[] descricoesPassos = valores(request, "passoDescricao");
        if (descricoesPassos.length == 0) descricoesPassos = valores(request, "passo");
        String[] titulosPassos = valores(request, "passoTitulo");
        validarItens(nomes, quantidades, unidades, descricoesPassos);

        synchronized (conexao) {
            boolean autoCommitAnterior = conexao.getAutoCommit();
            try {
                conexao.setAutoCommit(false);
                int receitaId = receitaDAO.cadastrarReceita(receita);
                for (int i = 0; i < nomes.length; i++) {
                    Ingrediente ingrediente = ingredienteDAO.buscarOuCriar(nomes[i].trim());
                    ReceitaIngrediente item = new ReceitaIngrediente(
                            receitaId, ingrediente.getId_ingrediente(),
                            Integer.parseInt(quantidades[i]), unidades[i].trim());
                    ingredienteDAO.adicionarIngredienteNaReceita(item);
                }
                for (int i = 0; i < descricoesPassos.length; i++) {
                    String titulo = i < titulosPassos.length && !isBlank(titulosPassos[i])
                            ? titulosPassos[i].trim() : "Passo " + (i + 1);
                    passoDAO.cadastrarPasso(new Passo(receitaId, i + 1, titulo, descricoesPassos[i].trim()));
                }
                if (enviar) registrarFluxo(receitaId, autor.getId_usuario(), StatusFluxo.PENDENTE, null);
                conexao.commit();
                request.getSession().setAttribute("sucesso",
                        enviar ? "Receita enviada para revisão." : "Rascunho salvo com sucesso.");
            } catch (Exception e) {
                conexao.rollback();
                throw e;
            } finally {
                conexao.setAutoCommit(autoCommitAnterior);
            }
        }
        LogUtil.registrar(conexao, request, "criacao", "Receita",
                (enviar ? "Receita criada e enviada para revisão: " : "Rascunho criado: ")
                        + receita.getTitulo_receita());
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    private Receita montarReceita(HttpServletRequest request, Usuario autor, boolean enviar) throws Exception {
        String titulo = request.getParameter("titulo");
        String categoriaId = request.getParameter("categoriaId");
        String tempo = request.getParameter("tempoPreparo");
        String rendimento = request.getParameter("rendimento");
        if (isBlank(titulo) || isBlank(categoriaId) || isBlank(tempo) || isBlank(rendimento)) {
            throw new IllegalArgumentException("Título, categoria, tempo e rendimento são obrigatórios.");
        }

        Categoria categoria = categoriaDAO.buscarCategoriaPorId(Integer.parseInt(categoriaId));
        if (categoria == null || categoria.getStatus_categoria() != Categoria.StatusCategoria.ATIVA) {
            throw new IllegalArgumentException("Categoria inválida ou inativa.");
        }

        Receita receita = new Receita();
        receita.setCategoria(categoria.getId_categoria());
        receita.setUsuario(autor.getId_usuario());
        receita.setTitulo_receita(titulo.trim());
        receita.setDescricao_receita(valorOuVazio(request.getParameter("descricao")));
        receita.setTempo_preparo_receita(Integer.parseInt(tempo));
        receita.setRendimento_receita(rendimento.trim());
        receita.setImagem_receita(valorOuVazio(request.getParameter("imagemUrl")));
        receita.setStatus_receita(enviar ? StatusReceita.aguardando_aprovacao : StatusReceita.rascunho);
        receita.setStatus_atividade(StatusAtividade.ativo);
        return receita;
    }

    private void validarItens(String[] nomes, String[] quantidades, String[] unidades, String[] passos) {
        if (nomes.length == 0 || nomes.length != quantidades.length || nomes.length != unidades.length) {
            throw new IllegalArgumentException("Informe ingrediente, quantidade e unidade.");
        }
        for (int i = 0; i < nomes.length; i++) {
            if (isBlank(nomes[i]) || isBlank(quantidades[i]) || isBlank(unidades[i])
                    || Integer.parseInt(quantidades[i]) <= 0) {
                throw new IllegalArgumentException("Ingrediente inválido.");
            }
        }
        if (passos.length == 0) throw new IllegalArgumentException("Informe ao menos um passo.");
        for (String passo : passos) if (isBlank(passo)) throw new IllegalArgumentException("Passo vazio.");
    }

    // ===== ACAO: APROVAR =====
    private void aprovar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        exigirModerador(request);

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));
        String comentario = request.getParameter("comentario"); // opcional

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");

        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(editor.getId_usuario());
        fluxo.setStatus_fluxo(StatusFluxo.APROVADO);
        fluxo.setObservacao_fluxo(comentario);
        fluxoDAO.registrarFluxo(fluxo);
        receitaDAO.atualizarStatusReceita(receitaId, StatusReceita.publicada);
        LogUtil.registrar(conexao, request, "aprovacao", "Receita",
                "Receita aprovada: " + receita.getTitulo_receita());

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" aprovada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: REJEITAR =====
    private void rejeitar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        exigirModerador(request);

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));
        String motivo = request.getParameter("motivo"); // obrigatorio na tela

        if (isBlank(motivo)) {
            setErroERedirect(request, response, "Motivo da rejeicao e obrigatorio.");
            return;
        }

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");

        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(editor.getId_usuario());
        fluxo.setStatus_fluxo(StatusFluxo.REJEITADO);
        fluxo.setObservacao_fluxo(motivo.trim());
        fluxoDAO.registrarFluxo(fluxo);
        receitaDAO.atualizarStatusReceita(receitaId, StatusReceita.rejeitada);
        LogUtil.registrar(conexao, request, "rejeicao", "Receita",
                "Receita rejeitada: " + receita.getTitulo_receita());

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" rejeitada.");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: PUBLICAR =====
    private void publicar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        exigirModerador(request);

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");
        receitaDAO.atualizarStatusReceita(receitaId, StatusReceita.publicada);
        registrarFluxo(receitaId, editor.getId_usuario(), StatusFluxo.APROVADO, "Publicada");
        LogUtil.registrar(conexao, request, "publicacao", "Receita",
                "Receita publicada: " + receita.getTitulo_receita());

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" publicada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: ATIVAR / INATIVAR =====
    private void toggleStatus(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        if (!isAdmin(request.getSession(false))) {
            throw new SecurityException("Apenas administradores podem alterar a atividade.");
        }

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        StatusAtividade novoStatus = receitaDAO.toggleStatusAtividade(receitaId);

        String label = novoStatus == StatusAtividade.ativo ? "ativada" : "inativada";
        LogUtil.registrar(conexao, request, "alteracao", "Receita",
                "Receita " + label + ": " + receita.getTitulo_receita());
        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" " + label + " com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private Usuario usuarioLogado(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session == null ? null : (Usuario) session.getAttribute("usuarioLogado");
    }

    private Usuario exigirAutor(HttpServletRequest request) {
        Usuario usuario = usuarioLogado(request);
        if (usuario == null || usuario.getTipo_usuario() != TipoUsuario.AUTOR) {
            throw new SecurityException("Acesso restrito a autores.");
        }
        return usuario;
    }

    private Usuario exigirModerador(HttpServletRequest request) {
        Usuario usuario = usuarioLogado(request);
        if (usuario == null || (usuario.getTipo_usuario() != TipoUsuario.ADMIN
                && usuario.getTipo_usuario() != TipoUsuario.EDITOR)) {
            throw new SecurityException("Acesso restrito a administradores e editores.");
        }
        return usuario;
    }

    private Receita buscarReceitaDoAutor(int receitaId, Usuario autor) throws Exception {
        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null || receita.getUsuario() != autor.getId_usuario()) {
            throw new SecurityException("Receita não pertence ao autor logado.");
        }
        return receita;
    }

    private void registrarFluxo(int receitaId, int usuarioId, StatusFluxo status, String observacao)
            throws Exception {
        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(usuarioId);
        fluxo.setStatus_fluxo(status);
        fluxo.setObservacao_fluxo(observacao);
        fluxoDAO.registrarFluxo(fluxo);
    }

    private String[] valores(HttpServletRequest request, String nome) {
        String[] valores = request.getParameterValues(nome);
        return valores == null ? new String[0] : valores;
    }

    private Integer parseIntegerOrNull(String valor) {
        return isBlank(valor) ? null : Integer.valueOf(valor);
    }

    private String valorOuVazio(String valor) {
        return valor == null ? "" : valor.trim();
    }

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
        return u != null && u.getTipo_usuario() == TipoUsuario.ADMIN;
    }

    private boolean isAdminOuEditor(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
        if (u == null) return false;
        return u.getTipo_usuario() == TipoUsuario.ADMIN
            || u.getTipo_usuario() == TipoUsuario.EDITOR;
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private int parseIntOrDefault(String valor, int padrao) {
        try {
            return Integer.parseInt(valor);
        } catch (Exception e) {
            return padrao;
        }
    }

    private void setErroERedirect(HttpServletRequest request, HttpServletResponse response, String msg)
            throws IOException {
        request.getSession().setAttribute("erro", msg);
        response.sendRedirect(request.getContextPath() + "/receitas");
    }
}
