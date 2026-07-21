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
import br.com.saborearte.model.Usuario.TemaUsuario;
import br.com.saborearte.utils.Conexao;

@WebServlet("/ConfiguracaoController")
public class ConfiguracaoController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            System.out.println("ConfiguracaoController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar ConfiguracaoController", e);
        }
    }

    // ===== GET — exibe a tela de configurações =====

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!estaLogado(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        // PRG: resgata mensagens da sessão e remove logo em seguida
        String sucesso = (String) session.getAttribute("sucesso");
        String erro    = (String) session.getAttribute("erro");
        if (sucesso != null) { request.setAttribute("sucesso", sucesso); session.removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("erro",    erro);    session.removeAttribute("erro");    }
        String aba = request.getParameter("aba");
        request.setAttribute("aba", aba != null ? aba : "seguranca");

        request.setAttribute("currentPage", "configuracoes");
        
        request.getRequestDispatcher("/pages/configuracoes.jsp").forward(request, response);
    }

    // ===== POST — recebe action e direciona =====

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
                case "tema"  -> atualizarTema(request, response, session);
                case "senha" -> atualizarSenha(request, response, session);
                default      -> response.sendRedirect(request.getContextPath() + "/ConfiguracaoController");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/ConfiguracaoController");
        }
    }

    // ===== AÇÃO: TEMA =====

    private void atualizarTema(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws Exception {

        Usuario logado = (Usuario) session.getAttribute("usuarioLogado");
        String temaParam = request.getParameter("tema"); // LIGHT | DARK | HIGH_CONTRAST

        try {
            TemaUsuario novoTema = TemaUsuario.valueOf(temaParam);

            boolean ok = usuarioDAO.atualizarTema(logado.getId_usuario(), novoTema);

            if (ok) {
                logado.setTema(novoTema);
                session.setAttribute("usuarioLogado", logado);
                session.setAttribute("sucesso", "Preferências de aparência atualizadas!");
            } else {
                session.setAttribute("erro", "Não foi possível salvar o tema. Tente novamente.");
            }
        } catch (IllegalArgumentException e) {
            session.setAttribute("erro", "Tema inválido.");
        }

        response.sendRedirect(request.getContextPath() + "/ConfiguracaoController?aba=conta");
    }

    // ===== AÇÃO: SENHA =====

    private void atualizarSenha(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws Exception {

        Usuario logado = (Usuario) session.getAttribute("usuarioLogado");

        String senhaAtual     = request.getParameter("senhaAtual");
        String novaSenha      = request.getParameter("novaSenha");
        String confirmarSenha = request.getParameter("confirmarSenha");

        if (novaSenha == null || !novaSenha.equals(confirmarSenha)) {
            session.setAttribute("erro", "A nova senha e a confirmação não conferem.");
            response.sendRedirect(request.getContextPath() + "/ConfiguracaoController?aba=seguranca");
            return;
        }

        if (novaSenha.length() < 8) {
            session.setAttribute("erro", "A nova senha deve ter no mínimo 8 caracteres.");
            response.sendRedirect(request.getContextPath() + "/ConfiguracaoController?aba=seguranca");
            return;
        }

        // Busca o usuário completo (a senha atual salva vem junto)
        Usuario usuario = usuarioDAO.buscarUsuarioPorId(logado.getId_usuario());

        if (usuario == null || usuario.getSenha_usuario() == null
                || !usuario.getSenha_usuario().equals(senhaAtual)) {
            session.setAttribute("erro", "A senha atual informada está incorreta.");
            response.sendRedirect(request.getContextPath() + "/ConfiguracaoController?aba=seguranca");
            return;
        }

        usuario.setSenha_usuario(novaSenha);
        boolean ok = usuarioDAO.atualizarUsuario(usuario);

        if (ok) {
            session.setAttribute("sucesso", "Senha alterada com sucesso! Use-a no próximo acesso.");
        } else {
            session.setAttribute("erro", "Não foi possível alterar a senha. Tente novamente.");
        }

        response.sendRedirect(request.getContextPath() + "/ConfiguracaoController?aba=seguranca");
    }

    // ===== UTILITÁRIO: verifica se há usuário logado =====

    private boolean estaLogado(HttpSession session) {
        return session != null && session.getAttribute("usuarioLogado") != null;
    }
}