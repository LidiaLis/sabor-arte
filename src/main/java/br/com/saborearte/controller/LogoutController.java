package br.com.saborearte.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.model.Usuario;

/**
 * Controller responsável por fazer logout do usuário.
 */
@WebServlet("/LogoutController")
public class LogoutController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null) {
            Usuario usuario = (Usuario) session.getAttribute("usuarioLogado");
            if (usuario != null) {
                System.out.println("Logout realizado para: " + usuario.getEmail_usuario()
                        + " | Perfil: " + usuario.getTipo_usuario());
            }
            session.invalidate();
        }

        response.sendRedirect(request.getContextPath() + "/HomeController");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
