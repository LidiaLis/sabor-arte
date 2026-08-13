package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.FavoritoDAO;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller de Favorito (favoritar/desfavoritar receita).
 *
 * GET  -> lista as receitas favoritas do usuário logado (receitas-favoritas.html)
 * POST -> ações via parametro "action": favoritar / desfavoritar / toggle
 *
 * Mesmo contrato de resposta do SeguidorController: AJAX (header
 * X-Requested-With) responde texto puro, POST tradicional faz redirect.
 */
@WebServlet("/FavoritoController")
public class FavoritoController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private FavoritoDAO favoritoDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            favoritoDAO = new FavoritoDAO(conexao);
            System.out.println("FavoritoController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar FavoritoController", e);
        }
    }

    // =========================================================================
    // GET — tela receitas-favoritas.html + status "já é favorito?"
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Usuario logado = usuarioLogado(request);

        if (logado == null) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        // Chamada AJAX pontual: /FavoritoController?idReceita=123 (verificar status)
        String idReceitaParam = request.getParameter("idReceita");
        if (idReceitaParam != null) {
            try {
                boolean favoritado = favoritoDAO.isFavorito(logado.getId_usuario(), Integer.parseInt(idReceitaParam));
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write(String.valueOf(favoritado));
            } catch (Exception e) {
                e.printStackTrace();
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
            return;
        }

        // Sem parâmetro -> carrega a listagem completa da tela receitas-favoritas.html
        String sucesso = (String) request.getSession().getAttribute("sucesso");
        String erro    = (String) request.getSession().getAttribute("erro");
        if (sucesso != null) { request.setAttribute("sucesso", sucesso); request.getSession().removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("erro",    erro);    request.getSession().removeAttribute("erro");    }

        try {
            List<Receita> favoritas = favoritoDAO.listarReceitasFavoritasDetalhado(logado.getId_usuario(), null);
            request.setAttribute("receitasFavoritas", favoritas);

            request.getRequestDispatcher("/pages/receitas-favoritas.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar receitas favoritas: " + e.getMessage());
            request.getRequestDispatcher("/pages/receitas-favoritas.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // POST — favoritar / desfavoritar / toggle
    // =========================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        Usuario logado = usuarioLogado(request);

        if (logado == null) {
            if (isAjax(request)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write("Faça login para favoritar receitas.");
            } else {
                response.sendRedirect(request.getContextPath() + "/LoginController");
            }
            return;
        }

        String acao = request.getParameter("action");
        String idReceitaParam = request.getParameter("idReceita");

        if (isBlank(idReceitaParam)) {
            responderErro(request, response, "idReceita é obrigatório.");
            return;
        }

        int idUsuario = logado.getId_usuario();
        int idReceita;

        try {
            idReceita = Integer.parseInt(idReceitaParam);
        } catch (NumberFormatException e) {
            responderErro(request, response, "idReceita inválido.");
            return;
        }

        try {
            boolean estadoFinal;

            switch (acao != null ? acao : "") {
                case "favoritar" -> {
                    favoritoDAO.favoritar(idUsuario, idReceita);
                    estadoFinal = true;
                }
                case "desfavoritar" -> {
                    favoritoDAO.desfavoritar(idUsuario, idReceita);
                    estadoFinal = false;
                }
                case "toggle" -> estadoFinal = favoritoDAO.toggleFavorito(idUsuario, idReceita);
                default -> {
                    responderErro(request, response, "Ação inválida.");
                    return;
                }
            }

            if (isAjax(request)) {
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write(estadoFinal ? "favoritado" : "naoFavoritado");
            } else {
                request.getSession().setAttribute("sucesso",
                        estadoFinal ? "Receita adicionada aos favoritos." : "Receita removida dos favoritos.");
                redirecionarDeVolta(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            responderErro(request, response, "Erro inesperado: " + e.getMessage());
        }
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private Usuario usuarioLogado(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return null;
        return (Usuario) session.getAttribute("usuarioLogado");
    }

    private boolean isAjax(HttpServletRequest request) {
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private void responderErro(HttpServletRequest request, HttpServletResponse response, String msg)
            throws IOException {
        if (isAjax(request)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write(msg);
        } else {
            request.getSession().setAttribute("erro", msg);
            redirecionarDeVolta(request, response);
        }
    }

    private void redirecionarDeVolta(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String referer = request.getHeader("Referer");
        response.sendRedirect(referer != null ? referer : request.getContextPath() + "/receitas-publico.html");
    }
}