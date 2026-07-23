package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.StatusUsuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

@WebServlet("/LoginController")
public class LoginController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String senha = request.getParameter("senha");

        HttpSession session = request.getSession();

        try {
            // 1. Validação de campos vazios
            if (email == null || email.trim().isEmpty() ||
                senha == null || senha.trim().isEmpty()) {
                session.setAttribute("erro", "Preencha todos os campos.");
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }

            Connection conn = Conexao.getConnection();
            UsuarioDAO usuarioDAO = new UsuarioDAO(conn);
            Usuario usuario = usuarioDAO.login(email.trim(), senha);

            if (usuario != null) {

                // 2. Validação de status
                if (usuario.getStatus_usuario() == StatusUsuario.INATIVO) {
                    session.setAttribute("erro", "Sua conta está inativa. Fale com o administrador.");
                    response.sendRedirect(request.getContextPath() + "/LoginController");
                    return;
                }

                // 3. Sucesso — renova sessão e autentica
                session.invalidate();
                session = request.getSession(true);
                session.setAttribute("usuarioLogado", usuario);

                // 4. Redireciona conforme o perfil
                TipoUsuario tipo = usuario.getTipo_usuario();

                if (tipo == TipoUsuario.ADMIN){
                   response.sendRedirect(request.getContextPath() + "/pages/html/admin/dashboard-admin.html");
                } else if (tipo == TipoUsuario.EDITOR) {
                    response.sendRedirect(request.getContextPath() + "/pages/html/editor/dashboard-editor.html");

                } else if (tipo == TipoUsuario.AUTOR) {
                    response.sendRedirect(request.getContextPath() + "/pages/html/autor/dashboard-autor.html");

                } else if (tipo == TipoUsuario.VISITANTE) {
                    response.sendRedirect(request.getContextPath() + "/pages/html/visitante/home-visitante.html");

                } else {
                    session.setAttribute("erro", "Perfil não reconhecido. Fale com o administrador.");
                    response.sendRedirect(request.getContextPath() + "/LoginController");
                }

            } else {
                // 5. Credenciais inválidas
                session.setAttribute("erro", "E-mail ou senha incorretos.");
                response.sendRedirect(request.getContextPath() + "/LoginController");
            }

        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("erro", "Erro no servidor. Tente novamente em instantes.");
            response.sendRedirect(request.getContextPath() + "/LoginController");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null && session.getAttribute("usuarioLogado") != null) {
            response.sendRedirect(request.getContextPath() + "/DashboardController");
            return;
        }

        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }
}
