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
import br.com.saborearte.utils.Conexao;

/**
 * Controller do fluxo de recuperação de senha:
 * esqueci-senha.html -> verificar-codigo.html -> nova-senha.html
 *
 * IMPORTANTE — mudança de abordagem em relação às 3 HTMLs como estão hoje:
 * as telas guardam e-mail/código em sessionStorage (só no navegador, nada
 * vai pro servidor). Isso não é seguro nem funcional de verdade: qualquer
 * um pode abrir nova-senha.html direto e trocar a senha de outra pessoa,
 * porque não existe checagem nenhuma no backend.
 *
 * Este Controller usa HttpSession (servidor) pra guardar o estado real do
 * fluxo: id do usuário buscado pelo e-mail, e se o código já foi validado.
 * Isso significa que as 3 páginas precisam trocar o sessionStorage por
 * chamadas fetch() pra estas 4 ações — as HTMLs como estão AINDA NÃO fazem
 * isso (só simulam com setTimeout). Vou sinalizar exatamente o que precisa
 * mudar em cada uma depois que você validar este Controller.
 *
 * Ações via POST (parametro "action"):
 *   - enviarCodigo    -> param "email"
 *   - reenviarCodigo  -> sem params (usa o e-mail já guardado na sessão)
 *   - verificarCodigo -> param "codigo" (os 6 dígitos concatenados)
 *   - redefinirSenha  -> params "novaSenha" e "confirmSenha"
 *
 * Resposta sempre em texto puro: "OK" (sucesso) ou mensagem de erro com
 * status 400 — mesmo contrato usado no SeguidorController/FavoritoController.
 */
@WebServlet("/RecuperacaoSenhaController")
public class RecuperacaoSenhaController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private CodigoRecuperacaoDAO codigoDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            codigoDAO = new CodigoRecuperacaoDAO(conexao);
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
    // 1) ESQUECI-SENHA.HTML — enviar código pro e-mail
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

        if (usuario != null) {
            String codigo = codigoDAO.gerarCodigo(usuario.getId_usuario());

            session.setAttribute("recuperacaoIdUsuario", usuario.getId_usuario());
            session.setAttribute("recuperacaoEmail", usuario.getEmail_usuario());

            // TODO: disparar e-mail de verdade aqui (ex.: JavaMail), enviando "codigo".
            // Por enquanto só loga no console pra facilitar teste local.
            System.out.println("[Recuperação de senha] código para " + usuario.getEmail_usuario() + ": " + codigo);
        }

        // Responde OK mesmo se o e-mail não existir — evita que alguém descubra
        // quais e-mails estão cadastrados só testando esse formulário.
        response.getWriter().write("OK");
    }

    // =========================================================================
    // 2) VERIFICAR-CODIGO.HTML — reenviar
    // =========================================================================

    private void reenviarCodigo(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);
        Integer idUsuario = idUsuarioNaSessao(session);

        if (idUsuario == null) {
            erro(response, "Sessão de recuperação expirada. Volte e digite seu e-mail novamente.");
            return;
        }

        String codigo = codigoDAO.gerarCodigo(idUsuario);

        String email = (String) session.getAttribute("recuperacaoEmail");
        System.out.println("[Recuperação de senha] novo código para " + email + ": " + codigo);

        response.getWriter().write("OK");
    }

    // =========================================================================
    // 2) VERIFICAR-CODIGO.HTML — validar os 6 dígitos
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
    // 3) NOVA-SENHA.HTML — redefinir
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
}