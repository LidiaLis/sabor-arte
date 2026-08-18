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

import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.SeguidorDAO;
import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.utils.Conexao;

/**
 * Tela pública de detalhe do autor (autor-detalhe.jsp).
 * Recebe ?id=<id_usuario> e monta:
 *  - "autor"      -> Usuario (com total_receitas_publicadas / total_comentarios já
 *                    preenchidos por UsuarioDAO.buscarAutorPublicoPorId)
 *  - "receitas"   -> List<Receita> publicadas desse autor
 *  - "seguindo"   -> Boolean: usuário logado já segue esse autor? (null se não logado)
 *  - "souEuMesmo" -> Boolean: o autor sendo visto é o próprio usuário logado?
 */
@WebServlet("/AutorController")
public class AutorController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // Limite de receitas trazidas para a aba "Receitas". Ajuste se quiser paginar depois.
    private static final int LIMITE_RECEITAS = 100;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private ReceitaDAO receitaDAO;
    private SeguidorDAO seguidorDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            receitaDAO = new ReceitaDAO(conexao);
            seguidorDAO = new SeguidorDAO(conexao);
            System.out.println("AutorController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar AutorController", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idParam = request.getParameter("id");

        if (idParam == null || idParam.trim().isEmpty()) {
            // Sem id -> volta pra listagem de autores.
            // AJUSTE o caminho abaixo se o nome real da sua rota de listagem for outro.
            response.sendRedirect(request.getContextPath() + "/pages/autores-visitante.jsp");
            return;
        }

        int idUsuario;
        try {
            idUsuario = Integer.parseInt(idParam.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/pages/autores-visitante.jsp");
            return;
        }

        try {
            Usuario autor = usuarioDAO.buscarAutorPublicoPorId(idUsuario);

            if (autor == null) {
                // Autor não existe, não é AUTOR/EDITOR/ADMIN, ou está inativo.
                request.getSession().setAttribute("erro", "Autor não encontrado.");
                response.sendRedirect(request.getContextPath() + "/pages/autores-visitante.jsp");
                return;
            }

            List<Receita> receitas =
                    receitaDAO.listarReceitasPublicadasPorAutor(idUsuario, LIMITE_RECEITAS);

            // Estado do botão "Seguir": só verifica se tiver alguém logado.
            HttpSession session = request.getSession(false);
            Usuario logado = (session != null) ? (Usuario) session.getAttribute("usuarioLogado") : null;

            Boolean seguindo = null;
            boolean souEuMesmo = false;

            if (logado != null) {
                souEuMesmo = (logado.getId_usuario() == idUsuario);
                if (!souEuMesmo) {
                    seguindo = seguidorDAO.jaSegue(logado.getId_usuario(), idUsuario);
                }
            }

            request.setAttribute("autor", autor);
            request.setAttribute("receitas", receitas);
            request.setAttribute("seguindo", seguindo);
            request.setAttribute("souEuMesmo", souEuMesmo);

            request.getRequestDispatcher("/pages/autor-detalhe.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar autor: " + e.getMessage());
            request.getRequestDispatcher("/pages/autor-detalhe.jsp").forward(request, response);
        }
    }
}