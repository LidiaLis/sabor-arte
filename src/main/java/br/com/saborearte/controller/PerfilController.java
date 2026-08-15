package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

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
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Comentario;
import br.com.saborearte.utils.Conexao;
//TESTA DE BRANCH

@WebServlet("/PerfilController")
public class PerfilController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Quantas receitas mostrar nos mini-grids do card (Publicadas/Favoritas) */
    private static final int LIMITE_MINI_GRID = 3;

    /** Quantos comentários denunciados mostrar no card do Editor/Admin */
    private static final int LIMITE_DENUNCIADOS = 5;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private ReceitaDAO receitaDAO;
    private ComentarioDAO comentarioDAO;
    private FavoritoDAO favoritoDAO;
    private SeguidorDAO seguidorDAO;

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

            request.getRequestDispatcher("/pages/perfil.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar perfil: " + e.getMessage());
            request.getRequestDispatcher("/pages/perfil.jsp").forward(request, response);
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

        Usuario usuario = usuarioDAO.buscarUsuarioPorId(idParam);
        if (usuario == null) {
            setErroERedirect(request, response, "Usuário não encontrado.");
            return;
        }

        usuario.setTelefone_usuario(isBlank(telefone) ? "" : telefone.trim());
        usuario.setLocalizacao_usuario(isBlank(localizacao) ? "" : localizacao.trim());

        // Bio so existe pra quem tem aba Biografia (Autor / Editor / Admin)
        TipoUsuario tipo = usuario.getTipo_usuario();
        boolean temAbas = tipo == TipoUsuario.AUTOR || tipo == TipoUsuario.EDITOR;
        if (temAbas && bio != null) {
            usuario.setBio_usuario(bio.trim());
        }

        boolean ok = usuarioDAO.atualizarUsuario(usuario);
        if (!ok) {
            setErroERedirect(request, response, "Não foi possível salvar as alterações. Tente novamente.");
            return;
        }

        // Mantem a sessao sincronizada com o que acabou de ser salvo
        session.setAttribute("usuarioLogado", usuario);

        session.setAttribute("sucesso", "Dados atualizados com sucesso!");
        response.sendRedirect(request.getContextPath() + "/PerfilController");
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