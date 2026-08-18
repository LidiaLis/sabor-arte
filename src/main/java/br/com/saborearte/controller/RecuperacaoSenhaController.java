package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.CodigoRecuperacaoDAO;
import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.service.EmailService;
import br.com.saborearte.utils.Conexao;

/**
 * Controller do fluxo de recuperação de senha:
 * esqueci-senha.jsp -> verificar-codigo.jsp -> nova-senha.jsp
 *
 * Ações via POST (parametro "action"):
 *   - enviarCodigo    -> param "email"
 *   - reenviarCodigo  -> sem params (usa o e-mail já guardado na sessão)
 *   - verificarCodigo -> param "codigo" (os 6 dígitos concatenados)
 *   - redefinirSenha  -> params "novaSenha" e "confirmSenha"
 *
 * Resposta sempre em texto puro: "OK" (sucesso) ou mensagem de erro.
 * Status usados:
 *   - 400 (Bad Request)  -> erro de validação/sistema genérico
 *   - 404 (Not Found)    -> e-mail não cadastrado (só na ação enviarCodigo)
 *
 * NOTA DE SEGURANÇA: a versão anterior deste Controller respondia "OK" mesmo
 * quando o e-mail não existia, de propósito — pra não deixar visitantes
 * descobrirem quais e-mails estão cadastrados testando o formulário
 * ("user enumeration"). A pedido, isso foi trocado: agora o Controller avisa
 * explicitamente quando o e-mail não está cadastrado (status 404). Se algum
 * dia isso virar um problema (bots testando e-mails em massa, por exemplo),
 * a solução mais simples é colocar um rate-limit por IP nesse endpoint.
 */
@WebServlet("/RecuperacaoSenhaController")
public class RecuperacaoSenhaController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Quantos minutos o código de recuperação vale antes de expirar. */
    private static final int VALIDADE_CODIGO_MINUTOS = 5;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private CodigoRecuperacaoDAO codigoDAO;
    private EmailService emailService;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            codigoDAO = new CodigoRecuperacaoDAO(conexao);
            emailService = new EmailService();
            System.out.println("RecuperacaoSenhaController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar RecuperacaoSenhaController", e);
        }
    }

    // =========================================================================
    // POST
    // =========================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        String acao = request.getParameter("action");

        try {
            switch (acao != null ? acao : "") {
                case "enviarCodigo"    -> enviarCodigo(request, response);
                case "reenviarCodigo"  -> reenviarCodigo(request, response);
                case "verificarCodigo" -> verificarCodigo(request, response);
                case "redefinirSenha"  -> redefinirSenha(request, response);
                default -> erro(response, "Ação inválida.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            erro(response, "Erro inesperado: " + e.getMessage());
        }
    }

    // =========================================================================
    // 1) ESQUECI-SENHA.JSP — enviar código pro e-mail
    // =========================================================================

    private void enviarCodigo(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String email = request.getParameter("email");

        if (isBlank(email)) {
            erro(response, "Digite um e-mail.");
            return;
        }

        HttpSession session = request.getSession(true);

        // Limpa qualquer estado de uma tentativa anterior antes de começar de novo.
        session.removeAttribute("recuperacaoIdUsuario");
        session.removeAttribute("recuperacaoValidado");

        Usuario usuario = usuarioDAO.buscarUsuarioPorEmail(email.trim());

        if (usuario == null) {
            erroNaoEncontrado(response, "Este e-mail não está cadastrado em nossa base.");
            return;
        }

        String codigo = codigoDAO.gerarCodigo(usuario.getId_usuario(), VALIDADE_CODIGO_MINUTOS);

        session.setAttribute("recuperacaoIdUsuario", usuario.getId_usuario());
        session.setAttribute("recuperacaoEmail", usuario.getEmail_usuario());

        try {
            emailService.enviarCodigoRecuperacao(
                usuario.getEmail_usuario(),
                usuario.getNome_usuario(),
                codigo,
                VALIDADE_CODIGO_MINUTOS
            );
        } catch (Exception e) {
            // O código já foi gravado no banco — se o envio falhar, quem pedir
            // "reenviar" na tela seguinte gera um código novo e tenta de novo.
            e.printStackTrace();
            erro(response, "Não foi possível enviar o e-mail agora. Tente novamente em instantes.");
            return;
        }

        response.getWriter().write("OK");
    }

    // =========================================================================
    // 2) VERIFICAR-CODIGO.JSP — reenviar
    // =========================================================================

    private void reenviarCodigo(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);
        Integer idUsuario = idUsuarioNaSessao(session);

        if (idUsuario == null) {
            erro(response, "Sessão de recuperação expirada. Volte e digite seu e-mail novamente.");
            return;
        }

        String email = (String) session.getAttribute("recuperacaoEmail");
        Usuario usuario = usuarioDAO.buscarUsuarioPorEmail(email);

        String codigo = codigoDAO.gerarCodigo(idUsuario, VALIDADE_CODIGO_MINUTOS);

        try {
            emailService.enviarCodigoRecuperacao(
                email,
                usuario != null ? usuario.getNome_usuario() : null,
                codigo,
                VALIDADE_CODIGO_MINUTOS
            );
        } catch (Exception e) {
            e.printStackTrace();
            erro(response, "Não foi possível enviar o e-mail agora. Tente novamente em instantes.");
            return;
        }

        response.getWriter().write("OK");
    }

    // =========================================================================
    // 2) VERIFICAR-CODIGO.JSP — validar os 6 dígitos
    // =========================================================================

    private void verificarCodigo(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);
        Integer idUsuario = idUsuarioNaSessao(session);

        if (idUsuario == null) {
            erro(response, "Sessão de recuperação expirada. Volte e digite seu e-mail novamente.");
            return;
        }

        String codigo = request.getParameter("codigo");

        if (isBlank(codigo) || codigo.trim().length() != 6) {
            erro(response, "Preencha os 6 dígitos do código.");
            return;
        }

        boolean valido = codigoDAO.validarCodigo(idUsuario, codigo.trim());

        if (!valido) {
            erro(response, "Código inválido ou expirado.");
            return;
        }

        session.setAttribute("recuperacaoValidado", true);
        response.getWriter().write("OK");
    }

    // =========================================================================
    // 3) NOVA-SENHA.JSP — redefinir
    // =========================================================================

    private void redefinirSenha(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);
        Integer idUsuario = idUsuarioNaSessao(session);

        if (idUsuario == null) {
            erro(response, "Sessão de recuperação expirada. Volte e digite seu e-mail novamente.");
            return;
        }

        Boolean validado = session != null ? (Boolean) session.getAttribute("recuperacaoValidado") : null;

        if (validado == null || !validado) {
            erro(response, "Você precisa verificar o código antes de redefinir a senha.");
            return;
        }

        String novaSenha = request.getParameter("novaSenha");
        String confirmSenha = request.getParameter("confirmSenha");

        if (isBlank(novaSenha) || novaSenha.length() < 8) {
            erro(response, "A senha deve ter no mínimo 8 caracteres.");
            return;
        }

        if (!novaSenha.equals(confirmSenha)) {
            erro(response, "As senhas não coincidem.");
            return;
        }

        usuarioDAO.atualizarSenha(idUsuario, novaSenha);

        // Fluxo concluído — limpa o estado de recuperação da sessão.
        session.removeAttribute("recuperacaoIdUsuario");
        session.removeAttribute("recuperacaoEmail");
        session.removeAttribute("recuperacaoValidado");

        // OBS: a tela promete "desconectado de todos os dispositivos" — isso
        // exigiria invalidar as sessões ativas desse usuário em outros
        // navegadores/dispositivos, o que não dá pra fazer só com
        // HttpSession (cada dispositivo tem a sua). Pra valer isso de
        // verdade precisaria de uma tabela de sessões/tokens por usuário
        // com uma coluna tipo "senha_alterada_em" checada a cada request.
        // Deixei de fora por enquanto — me avisa se quiser que eu monte isso.

        response.getWriter().write("OK");
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private Integer idUsuarioNaSessao(HttpSession session) {
        if (session == null) return null;
        return (Integer) session.getAttribute("recuperacaoIdUsuario");
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private void erro(HttpServletResponse response, String msg) throws IOException {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().write(msg);
    }

    private void erroNaoEncontrado(HttpServletResponse response, String msg) throws IOException {
        response.setStatus(HttpServletResponse.SC_NOT_FOUND);
        response.getWriter().write(msg);
    }
}