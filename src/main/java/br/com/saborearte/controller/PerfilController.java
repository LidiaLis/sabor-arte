package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.SeguidorDAO;
import br.com.saborearte.dao.ComentarioDAO;
import br.com.saborearte.dao.FavoritoDAO;
import br.com.saborearte.dao.EspecialidadeDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.Especialidade;
import br.com.saborearte.utils.Conexao;
//TESTA DE BRANCH

@WebServlet("/PerfilController")
public class PerfilController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Quantas receitas mostrar nos mini-grids do card (Publicadas/Favoritas) */
    private static final int LIMITE_MINI_GRID = 3;

    /** Quantos comentários denunciados mostrar no card do Editor/Admin */
    private static final int LIMITE_DENUNCIADOS = 5;

    // =========================================================================
    // RESTRICOES DE ESCRITA (mesma logica aplicada no client em perfis.jsp —
    // nunca confiar so no client-side, sempre revalidar aqui tambem)
    // =========================================================================

    /** Titulo profissional: letras (com acento), numeros, espaco e pontuacao basica. */
    private static final Pattern TITULO_CARACTERES_INVALIDOS = Pattern.compile("[^A-Za-zÀ-ÖØ-öø-ÿ0-9 ·.,'\\-()&:]");

    /** Biografia: bloqueia so os caracteres usados pra injetar HTML/script. */
    private static final Pattern BIO_CARACTERES_INVALIDOS = Pattern.compile("[<>\"`]");

    /** Localizacao: precisa ser "Cidade, UF" — mesma regra do client (formatLocation em perfis.jsp). */
    private static final Pattern LOCALIZACAO_VALIDA = Pattern.compile(
            "^[A-Za-zÀ-ÖØ-öø-ÿ' -]+, [A-Z]{2}$");

    private static final List<String> UF_VALIDAS = List.of(
            "AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG","PA","PB",
            "PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO");

    /** YouTube: precisa ser link de canal/video do proprio youtube.com ou youtu.be. */
    private static final Pattern YOUTUBE_VALIDO = Pattern.compile(
            "^https://(www\\.)?(youtube\\.com/(@|channel/|c/|user/)[A-Za-z0-9._-]+|youtu\\.be/[A-Za-z0-9._-]+)/?$",
            Pattern.CASE_INSENSITIVE);

    /** Pinterest: precisa ser link do proprio pinterest.com (ou dominio regional, ex: pinterest.com.br). */
    private static final Pattern PINTEREST_VALIDO = Pattern.compile(
            "^https://([a-z]{2,3}\\.)?pinterest\\.[a-z.]{2,10}/[A-Za-z0-9._-]+/?$",
            Pattern.CASE_INSENSITIVE);

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private ReceitaDAO receitaDAO;
    private ComentarioDAO comentarioDAO;
    private FavoritoDAO favoritoDAO;
    private SeguidorDAO seguidorDAO;
    private EspecialidadeDAO especialidadeDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO    = new UsuarioDAO(conexao);
            receitaDAO    = new ReceitaDAO(conexao);
            comentarioDAO = new ComentarioDAO(conexao);
            favoritoDAO   = new FavoritoDAO(conexao);
            seguidorDAO   = new SeguidorDAO(conexao);
            especialidadeDAO = new EspecialidadeDAO(conexao);
            System.out.println("PerfilController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar PerfilController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!estaLogado(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");

        String sucesso = (String) session.getAttribute("sucesso");
        String erro    = (String) session.getAttribute("erro");
        if (sucesso != null) { request.setAttribute("sucesso", sucesso); session.removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("erro",    erro);    session.removeAttribute("erro");    }

        try {
            // Recarrega o usuario do banco pra garantir dados atualizados na tela
            Usuario usuarioAtualizado = usuarioDAO.buscarUsuarioPorId(usuarioLogado.getId_usuario());
            if (usuarioAtualizado != null) {
                usuarioLogado = usuarioAtualizado;
                session.setAttribute("usuarioLogado", usuarioLogado);
            }

            TipoUsuario tipo = usuarioLogado.getTipo_usuario();

            if (tipo == TipoUsuario.AUTOR) {

                List<Receita> receitasPublicadas =
                        receitaDAO.listarReceitasPublicadasPorAutor(usuarioLogado.getId_usuario(), LIMITE_MINI_GRID);
                request.setAttribute("receitasPublicadas", receitasPublicadas);

                // Especialidades do autor (aba "Especialidades & Redes"), vindas
                // da tabela associativa "especialidade" via EspecialidadeDAO —
                // so os id_categoria/nome/emoji das categorias marcadas
                // (sem tempo/anos, isso nao existe mais na tela de perfil).
                List<Categoria> especialidadesUsuario =
                        especialidadeDAO.listarEspecialidadesPorUsuario(usuarioLogado.getId_usuario());
                request.setAttribute("especialidadesUsuario", especialidadesUsuario);

                // Catalogo completo de categorias ativas, para popular o <select>
                // "Adicionar especialidade" (antes era uma lista fixa no HTML).
                List<Categoria> categoriasDisponiveis = especialidadeDAO.listarTodasCategoriasAtivas();
                request.setAttribute("categoriasDisponiveis", categoriasDisponiveis);

            } else if (tipo == TipoUsuario.VISITANTE) {

                List<Receita> receitasFavoritas =
                        favoritoDAO.listarReceitasFavoritasDetalhado(usuarioLogado.getId_usuario(), LIMITE_MINI_GRID);
                request.setAttribute("receitasFavoritas", receitasFavoritas);

                int qtdSeguindo = seguidorDAO.contarSeguindo(usuarioLogado.getId_usuario());
                request.setAttribute("qtdSeguindo", qtdSeguindo);

            } else if (tipo == TipoUsuario.EDITOR || tipo == TipoUsuario.ADMIN) {

                List<Comentario> comentariosDenunciados =
                        comentarioDAO.listarComentariosDenunciados(LIMITE_DENUNCIADOS);
                request.setAttribute("comentariosDenunciados", comentariosDenunciados);
            }

            request.getRequestDispatcher("/pages/perfis.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar perfil: " + e.getMessage());
            request.getRequestDispatcher("/pages/perfis.jsp").forward(request, response);
        } catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
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

        if (!estaLogado(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String acao = request.getParameter("action");

        try {
            switch (acao != null ? acao : "") {
                case "atualizarPerfil" -> atualizarPerfil(request, response, session);
                case "atualizarFoto"   -> atualizarFoto(request, response, session);
                default -> response.sendRedirect(request.getContextPath() + "/PerfilController");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/PerfilController");
        }
    }

    // =========================================================================
    // AÇÃO: ATUALIZAR PERFIL
    // =========================================================================

    private void atualizarPerfil(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws Exception {

        Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");

        int idParam = Integer.parseInt(request.getParameter("id"));
        if (idParam != usuarioLogado.getId_usuario()) {
            setErroERedirect(request, response, "Operação não permitida.");
            return;
        }

        String telefone    = request.getParameter("telefone");
        String localizacao = request.getParameter("localizacao");
        String bio          = request.getParameter("bio");

        // Novos campos (só existem no form quando a aba Biografia/Especialidades
        // aparece — mesma regra do "bio" logo abaixo)
        String titulo             = request.getParameter("titulo");
        String especialidadesIds  = request.getParameter("especialidadesIds");
        String instagram          = request.getParameter("instagram");
        String youtube            = request.getParameter("youtube");
        String pinterest          = request.getParameter("pinterest");

        Usuario usuario = usuarioDAO.buscarUsuarioPorId(idParam);
        if (usuario == null) {
            setErroERedirect(request, response, "Usuário não encontrado.");
            return;
        }

        // Avisos de campos que vieram preenchidos mas em formato invalido —
        // em vez de sumir silenciosamente, o usuario precisa saber por que
        // aquele campo especifico nao foi salvo.
        StringBuilder avisos = new StringBuilder();

        usuario.setTelefone_usuario(isBlank(telefone) ? "" : telefone.trim());

        if (isBlank(localizacao)) {
            usuario.setLocalizacao_usuario("");
        } else if (localizacaoValida(localizacao.trim())) {
            usuario.setLocalizacao_usuario(localizacao.trim());
        } else {
            avisos.append(" Localização em formato inválido (use Cidade, UF) não foi salva.");
        }

        // Bio e demais campos da aba Biografia/Especialidades so existem
        // pra quem tem essas abas (mesma regra "temAbas" do perfis.jsp: so AUTOR)
        TipoUsuario tipo = usuario.getTipo_usuario();
        boolean temAbas = tipo == TipoUsuario.AUTOR;
        if (temAbas && bio != null) {
            usuario.setBio_usuario(sanitizarBio(bio));
        }

        if (temAbas) {

            if (titulo != null) {
                usuario.setTitulo_usuario(sanitizarTitulo(titulo));
            }

            // Especialidades: gravadas na tabela associativa "especialidade"
            // via EspecialidadeDAO, em vez da antiga string separada por "|".
            // O hidden "especialidadesIds" traz os id_categoria selecionados,
            // separados por vírgula (montado no JS a partir das .tag
            // renderizadas — ver syncEspecialidades() no perfis.jsp).
            sincronizarEspecialidades(usuario.getId_usuario(), especialidadesIds);

            // Instagram/YouTube/Pinterest: o JS ja filtra/valida no client,
            // mas nunca confiamos so nisso — revalida aqui do mesmo jeito.
            if (instagram != null) {
                usuario.setInstagram_usuario(sanitizarInstagram(instagram));
            }
            if (youtube != null) {
                if (isBlank(youtube)) {
                    usuario.setYoutube_usuario("");
                } else if (YOUTUBE_VALIDO.matcher(youtube.trim()).matches()) {
                    usuario.setYoutube_usuario(youtube.trim());
                } else {
                    avisos.append(" Link do YouTube em formato inválido não foi salvo.");
                }
            }
            if (pinterest != null) {
                if (isBlank(pinterest)) {
                    usuario.setPinterest_usuario("");
                } else if (PINTEREST_VALIDO.matcher(pinterest.trim()).matches()) {
                    usuario.setPinterest_usuario(pinterest.trim());
                } else {
                    avisos.append(" Link do Pinterest em formato inválido não foi salvo.");
                }
            }
            // TikTok não existe no banco — parâmetro removido de propósito, não ler aqui.
        }

        boolean ok = usuarioDAO.atualizarUsuario(usuario);
        if (!ok) {
            setErroERedirect(request, response, "Não foi possível salvar as alterações. Tente novamente.");
            return;
        }

        // Mantem a sessao sincronizada com o que acabou de ser salvo
        session.setAttribute("usuarioLogado", usuario);

        String msgSucesso = "Dados atualizados com sucesso!" + avisos.toString();
        session.setAttribute("sucesso", msgSucesso);
        response.sendRedirect(request.getContextPath() + "/PerfilController");
    }

    // =========================================================================
    // AÇÃO: ATUALIZAR FOTO (sempre a PRÓPRIA foto — regra 6)
    // =========================================================================
    //
    // Regra: no PerfilController (tela "Meu Perfil") todo usuário logado
    // altera SOMENTE a própria foto, e Visitante nem tem essa opção.
    // Alterar a foto de OUTROS usuários é privilégio exclusivo do Admin
    // e acontece em outra tela (UsuarioController / usuarios.jsp),
    // nunca por aqui.
    private void atualizarFoto(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws Exception {

        Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");

        // Visitante não pode alterar foto de perfil
        if (usuarioLogado.getTipo_usuario() == TipoUsuario.VISITANTE) {
            setErroERedirect(request, response, "Seu perfil não tem permissão para alterar a foto.");
            return;
        }

        // Trava de segurança: mesmo que alguém manipule o form no client,
        // o PerfilController jamais altera foto de outro usuário — o "id"
        // recebido precisa ser sempre o do próprio usuário logado.
        int idParam = Integer.parseInt(request.getParameter("id"));
        if (idParam != usuarioLogado.getId_usuario()) {
            setErroERedirect(request, response, "Operação não permitida.");
            return;
        }

        String fotoBase64 = request.getParameter("fotoBase64");
        if (isBlank(fotoBase64)) {
            setErroERedirect(request, response, "Nenhuma imagem foi enviada.");
            return;
        }

        Usuario usuario = usuarioDAO.buscarUsuarioPorId(idParam);
        if (usuario == null) {
            setErroERedirect(request, response, "Usuário não encontrado.");
            return;
        }

        usuario.setFoto_usuario(fotoBase64.trim());

        boolean ok = usuarioDAO.atualizarUsuario(usuario);
        if (!ok) {
            setErroERedirect(request, response, "Não foi possível salvar a foto. Tente novamente.");
            return;
        }

        // Mantem a sessao sincronizada com o que acabou de ser salvo
        session.setAttribute("usuarioLogado", usuario);

        session.setAttribute("sucesso", "Foto de perfil atualizada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/PerfilController");
    }

    // =========================================================================
    // ESPECIALIDADES (tabela associativa, via EspecialidadeDAO)
    // =========================================================================

    /**
     * Substitui todas as especialidades do usuario pelo conjunto recebido do
     * form (ids_categoria separados por virgula, vindos do hidden
     * "especialidadesIds"). Estrategia simples: apaga tudo e reinsere so o
     * que veio marcado — evita ter que calcular diff (o que entrou/saiu) e
     * casa com o resto do PRG do controller (nunca confia no que ja estava
     * salvo, sempre reflete exatamente o que o form mandou).
     *
     * A tela de perfil nao trabalha com tempo/anos de especialidade — so
     * marca quais categorias sao especialidade do autor. O tempo_especialidade
     * exigido pela tabela e sempre gravado como 0 aqui.
     */
    private void sincronizarEspecialidades(int idUsuario, String especialidadesIdsCsv) throws SQLException {

        especialidadeDAO.removerTodasEspecialidadesDoUsuario(idUsuario);

        if (especialidadesIdsCsv == null || especialidadesIdsCsv.trim().isEmpty()) {
            return;
        }

        for (String parte : especialidadesIdsCsv.split(",")) {
            parte = parte.trim();
            if (parte.isEmpty()) continue;

            try {
                int idCategoria = Integer.parseInt(parte);

                Especialidade especialidade = new Especialidade(idUsuario, idCategoria, 0);

                especialidadeDAO.adicionarEspecialidade(especialidade);
            } catch (NumberFormatException nfe) {
                // valor invalido vindo do client -> ignora esse item e segue os demais
            }
        }
    }

    // =========================================================================
    // SANITIZACAO / VALIDACAO DE TEXTO LIVRE (espelha as mascaras do client em perfis.jsp)
    // =========================================================================

    private String sanitizarTitulo(String titulo) {
        String limpo = TITULO_CARACTERES_INVALIDOS.matcher(titulo.trim()).replaceAll("");
        if (limpo.length() > 80) limpo = limpo.substring(0, 80);
        return limpo;
    }

    private String sanitizarBio(String bio) {
        String limpo = BIO_CARACTERES_INVALIDOS.matcher(bio.trim()).replaceAll("");
        if (limpo.length() > 600) limpo = limpo.substring(0, 600);
        return limpo;
    }

    private String sanitizarInstagram(String instagram) {
        String v = instagram.trim();
        boolean comArroba = v.startsWith("@");
        String corpo = comArroba ? v.substring(1) : v;
        corpo = corpo.replaceAll("[^A-Za-z0-9._]", "");
        if (corpo.length() > 30) corpo = corpo.substring(0, 30);
        return comArroba ? "@" + corpo : corpo;
    }

    /** "Cidade, UF" com UF de verdade na lista de estados — mesma regra do formatLocation() no client. */
    private boolean localizacaoValida(String valor) {
        if (!LOCALIZACAO_VALIDA.matcher(valor).matches()) return false;
        String uf = valor.substring(valor.indexOf(",") + 1).trim();
        return UF_VALIDAS.contains(uf);
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private boolean estaLogado(HttpSession session) {
        if (session == null) return false;
        return session.getAttribute("usuarioLogado") != null;
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private void setErroERedirect(HttpServletRequest request, HttpServletResponse response, String msg)
            throws IOException {
        request.getSession().setAttribute("erro", msg);
        response.sendRedirect(request.getContextPath() + "/PerfilController");
    }
}