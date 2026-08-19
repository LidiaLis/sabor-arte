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

import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.SeguidorDAO;
import br.com.saborearte.model.Receita.StatusReceita;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller de "seguir autor" (usuario_seguidor).
 *
 * Ações via POST (parametro "action"):
 *   - seguir          -> idSeguido obrigatório
 *   - deixarDeSeguir  -> idSeguido obrigatório
 *   - toggle          -> idSeguido obrigatório (alterna e devolve o novo estado)
 *
 * Resposta:
 *   - Se a requisição for AJAX (header X-Requested-With = XMLHttpRequest),
 *     responde texto puro: "seguindo" ou "naoSegue" (pro JS atualizar o botão
 *     sem recarregar a página, mesmo padrão do salvarEmoji do CategoriaController).
 *   - Caso contrário, faz o redirect tradicional de volta pra página anterior
 *     (Referer), ou para autores-publico.html se não houver Referer.
 *
 * GET (parametro "idSeguido") -> responde "true"/"false" se o usuário logado
 * já segue aquele autor. Útil pro JS marcar o estado inicial do botão ao
 * carregar a página, sem precisar embutir lógica de DAO na JSP.
 */
@WebServlet("/SeguidorController")
public class SeguidorController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private SeguidorDAO seguidorDAO;
    private ReceitaDAO receitaDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            seguidorDAO = new SeguidorDAO(conexao);
            receitaDAO = new ReceitaDAO(conexao);
            System.out.println("SeguidorController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar SeguidorController", e);
        }
    }

    // =========================================================================
    // GET — "action=listar" -> tela autores-seguidos.jsp
    //       (sem action) -> status "já segue?" (usado pelo JS pra pintar o botão certo)
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if ("listar".equals(request.getParameter("action"))) {
            listarSeguidos(request, response);
            return;
        }

        Usuario logado = usuarioLogado(request);

        response.setContentType("text/plain;charset=UTF-8");

        if (logado == null) {
            response.getWriter().write("false");
            return;
        }

        String idSeguidoParam = request.getParameter("idSeguido");
        if (isBlank(idSeguidoParam)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("idSeguido é obrigatório");
            return;
        }

        int idSeguido = Integer.parseInt(idSeguidoParam);
        boolean segue = false;
		try {
			segue = seguidorDAO.jaSegue(logado.getId_usuario(), idSeguido);
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

        response.getWriter().write(String.valueOf(segue));
    }

    /**
     * Lista os autores que o usuário logado segue + a contagem de receitas
     * publicadas de cada um (via ReceitaDAO), e encaminha pra autores-seguidos.jsp.
     */
    private void listarSeguidos(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Usuario logado = usuarioLogado(request);

        if (logado == null) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        try {
            List<Usuario> seguidos = seguidorDAO.listarSeguidos(logado.getId_usuario());

            // total_receitas_publicadas é campo extra (não persistido) do Usuario —
            // preenchido aqui pra alimentar o "🍽️ N receitas publicadas" do card.
            for (Usuario autor : seguidos) {
                int total = receitaDAO.contarPorStatusEAutor(autor.getId_usuario(), StatusReceita.publicada);
                autor.setTotal_receitas_publicadas(total);
            }

            request.setAttribute("seguidos", seguidos);
            request.getRequestDispatcher("/pages/autores-seguidos.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar autores seguidos: " + e.getMessage());
            request.getRequestDispatcher("/pages/autores-seguidos.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // POST — seguir / deixar de seguir / toggle
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
                response.getWriter().write("Faça login para seguir autores.");
            } else {
                response.sendRedirect(request.getContextPath() + "/LoginController");
            }
            return;
        }

        String acao = request.getParameter("action");
        String idSeguidoParam = request.getParameter("idSeguido");

        if (isBlank(idSeguidoParam)) {
            responderErro(request, response, "idSeguido é obrigatório.");
            return;
        }

        int idSeguidor = logado.getId_usuario();
        int idSeguido;

        try {
            idSeguido = Integer.parseInt(idSeguidoParam);
        } catch (NumberFormatException e) {
            responderErro(request, response, "idSeguido inválido.");
            return;
        }

        if (idSeguido == idSeguidor) {
            responderErro(request, response, "Você não pode seguir a si mesmo.");
            return;
        }

        try {
            boolean estadoFinal;

            switch (acao != null ? acao : "") {
                case "seguir" -> {
                    seguidorDAO.seguir(idSeguidor, idSeguido);
                    estadoFinal = true;
                }
                case "deixarDeSeguir" -> {
                    seguidorDAO.deixarDeSeguir(idSeguidor, idSeguido);
                    estadoFinal = false;
                }
                case "toggle" -> {
                    boolean jaSegue = seguidorDAO.jaSegue(idSeguidor, idSeguido);
                    if (jaSegue) {
                        seguidorDAO.deixarDeSeguir(idSeguidor, idSeguido);
                        estadoFinal = false;
                    } else {
                        seguidorDAO.seguir(idSeguidor, idSeguido);
                        estadoFinal = true;
                    }
                }
                default -> {
                    responderErro(request, response, "Ação inválida.");
                    return;
                }
            }

            if (isAjax(request)) {
                response.setContentType("text/plain;charset=UTF-8");
                response.getWriter().write(estadoFinal ? "seguindo" : "naoSegue");
            } else {
                request.getSession().setAttribute("sucesso",
                        estadoFinal ? "Agora você está seguindo este autor." : "Você deixou de seguir este autor.");
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
        response.sendRedirect(referer != null ? referer : request.getContextPath() + "/pages/autores.jsp");
    }
}