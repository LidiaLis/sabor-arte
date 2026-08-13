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

import br.com.saborearte.dao.ComentarioDAO;
import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Comentario.StatusComentario;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller único de comentários - serve as duas telas:
 *
 *   /mensagens-autor       -> mensagens-autor.jsp (autor: ve comentarios
 *                             das proprias receitas, responde e denuncia)
 *   /comentarios-moderacao -> comentarios-moderacao.jsp (editor/admin:
 *                             modera os comentarios pendentes/denunciados)
 *
 * REESCRITO no padrao PRG/JSP do projeto (sem JSON), igual ao
 * CategoriaController/ReceitaController/RelatorioController.
 *
 * CORRECAO IMPORTANTE: o controller antigo dependia de uma classe Denuncia
 * e de um DenunciaDAO que NAO EXISTEM no projeto (conferido no pacote
 * br.com.saborearte.model - so tem Comentario.java, sem Denuncia.java).
 * Removida essa dependencia inteira: "denunciar" agora so atualiza o
 * proprio Comentario pra StatusComentario.PENDENTE, que e o mesmo status
 * que o DashboardController ja usa pra alimentar os cards "Comentarios
 * Pendentes"/"Comentarios Denunciados" do editor (mesma contagem, por
 * decisao ja tomada no projeto). O "motivo" da denuncia so pode ser salvo
 * se o Comentario tiver um campo pra isso (ex.: motivo_denuncia) - nao
 * confirmado, ver TODO abaixo.
 *
 * Tambem corrigido: StatusComentario.RESOLVIDO (nao existe) -> APROVADO,
 * que e o valor real confirmado no enum (junto com PENDENTE, REMOVIDO,
 * REJEITADO, ja usados no DashboardController).
 *
 * ATUALIZADO: os metodos que faltavam no ComentarioDAO foram criados e
 * renomeados pra bater com o estilo do DAO real (contarComentarios,
 * listarComentariosDenunciados, contarPorStatus):
 *   listarComentariosPorAutor(autorId, filtro, page, size)
 *   salvarResposta(comentarioId, autorId, texto) — ATENCAO: assume colunas
 *     resposta_comentario/data_resposta_comentario na tabela, nao confirmado
 *   listarComentariosModeracao(filtro, status, data, page, size) — antes
 *     chamado de "listarDenunciados"; renomeado porque "denunciado" nao e
 *     um status proprio (ver comentario da classe do DAO)
 *   contarComentariosModeracao(filtro, status, data) — antes "contarDenunciados"
 *   removerComentario(comentarioId)
 *   atualizarStatusComentario(comentarioId, StatusComentario)
 * TODO: confirmar se UsuarioDAO.alterarStatus(id, String) espera String
 * "BLOQUEADO" mesmo ou um enum de status de usuario (nao confirmado ainda).
 *
 * Acoes em /mensagens-autor (parametro "action"):
 *   GET                   -> comentarios recebidos nas receitas do autor logado
 *   POST action=responder -> autor responde um comentario
 *   POST action=denunciar -> autor denuncia um comentario (marca PENDENTE)
 *
 * Acoes em /comentarios-moderacao (parametro "action"):
 *   GET                  -> lista comentarios pendentes/denunciados (filtro + paginacao)
 *   POST action=manter   -> resolve a denuncia, comentario continua no ar (APROVADO)
 *   POST action=remover  -> remove o comentario
 *   POST action=bloquear -> bloqueia o usuario autor do comentario
 */
@WebServlet(urlPatterns = {"/comentarios-moderacao", "/mensagens-autor"})
public class ComentarioController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private ComentarioDAO comentarioDAO;
    private UsuarioDAO usuarioDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            comentarioDAO = new ComentarioDAO(conexao);
            usuarioDAO = new UsuarioDAO(conexao);
            System.out.println("ComentarioController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar ComentarioController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        String sucesso = session != null ? (String) session.getAttribute("sucesso") : null;
        String erro    = session != null ? (String) session.getAttribute("erro")    : null;
        if (sucesso != null) { request.setAttribute("sucesso", sucesso); session.removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("erro",    erro);    session.removeAttribute("erro");    }

        if (isRotaAutor(request)) {
            Usuario usuarioLogado = getUsuarioLogado(session);
            if (usuarioLogado == null) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }
            listarPorAutor(request, response, usuarioLogado.getId_usuario());
        } else {
            if (!isAdminOuEditor(session)) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }
            listarDenunciados(request, response);
        }
    }

    // ===== AUTOR: LISTAGEM (mensagens-autor.jsp) =====
    private void listarPorAutor(HttpServletRequest request, HttpServletResponse response, int autorId)
            throws ServletException, IOException {

        try {
            String filtro = request.getParameter("filtro");
            int page = parseIntOrDefault(request.getParameter("page"), 1);
            int size = parseIntOrDefault(request.getParameter("size"), 10);

            List<Comentario> comentarios = comentarioDAO.listarComentariosPorAutor(autorId, filtro, page, size);

            request.setAttribute("comentarios", comentarios);
            request.setAttribute("filtro", filtro);
            request.setAttribute("page", page);
            request.setAttribute("size", size);

            request.getRequestDispatcher("/pages/mensagens-autor.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar comentarios: " + e.getMessage());
            request.getRequestDispatcher("/pages/mensagens-autor.jsp").forward(request, response);
        }
    }

    // ===== EDITOR/ADMIN: LISTAGEM (comentarios-moderacao.jsp) =====
    private void listarDenunciados(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String filtro = request.getParameter("filtro");   // busca por comentario/usuario/receita
            String status = request.getParameter("status");   // PENDENTE / APROVADO / REMOVIDO / REJEITADO / null=todos
            String data = request.getParameter("data");       // opcional
            int page = parseIntOrDefault(request.getParameter("page"), 1);
            int size = parseIntOrDefault(request.getParameter("size"), 10);

            List<Comentario> denunciados = comentarioDAO.listarComentariosModeracao(filtro, status, data, page, size);
            int total = comentarioDAO.contarComentariosModeracao(filtro, status, data);

            request.setAttribute("comentarios", denunciados);
            request.setAttribute("total", total);
            request.setAttribute("filtro", filtro);
            request.setAttribute("statusFiltro", status);
            request.setAttribute("data", data);
            request.setAttribute("page", page);
            request.setAttribute("size", size);

            request.getRequestDispatcher("/pages/comentarios-moderacao.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar comentarios denunciados: " + e.getMessage());
            request.getRequestDispatcher("/pages/comentarios-moderacao.jsp").forward(request, response);
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
        String action = request.getParameter("action");

        if (isRotaAutor(request)) {
            Usuario usuarioLogado = getUsuarioLogado(session);
            if (usuarioLogado == null) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }

            try {
                switch (action != null ? action : "") {
                    case "responder" -> responder(request, response, usuarioLogado.getId_usuario());
                    case "denunciar" -> denunciar(request, response);
                    default -> response.sendRedirect(request.getContextPath() + "/mensagens-autor");
                }
            } catch (Exception e) {
                e.printStackTrace();
                request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
                response.sendRedirect(request.getContextPath() + "/mensagens-autor");
            }

        } else {
            if (!isAdminOuEditor(session)) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }

            try {
                switch (action != null ? action : "") {
                    case "manter"   -> manter(request, response);
                    case "remover"  -> remover(request, response);
                    case "bloquear" -> bloquear(request, response);
                    default -> response.sendRedirect(request.getContextPath() + "/comentarios-moderacao");
                }
            } catch (Exception e) {
                e.printStackTrace();
                request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
                response.sendRedirect(request.getContextPath() + "/comentarios-moderacao");
            }
        }
    }

    // ===== AUTOR: RESPONDER =====
    private void responder(HttpServletRequest request, HttpServletResponse response, int autorId)
            throws Exception {

        int comentarioId = parseIntOrDefault(request.getParameter("comentarioId"), -1);
        String texto = request.getParameter("texto");

        if (isBlank(texto)) {
            setErroERedirect(request, response, "/mensagens-autor", "A resposta nao pode ficar vazia.");
            return;
        }

        comentarioDAO.salvarResposta(comentarioId, autorId, texto.trim());

        request.getSession().setAttribute("sucesso", "Resposta enviada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/mensagens-autor");
    }

    // ===== AUTOR: DENUNCIAR (marca o proprio comentario como PENDENTE) =====
    private void denunciar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int comentarioId = parseIntOrDefault(request.getParameter("comentarioId"), -1);
        String motivo = request.getParameter("motivo");

        if (isBlank(motivo)) {
            setErroERedirect(request, response, "/mensagens-autor", "Informe o motivo da denuncia.");
            return;
        }

        // Sem Denuncia/DenunciaDAO (nao existem no projeto): a denuncia vira,
        // na pratica, o comentario mudando pra PENDENTE, que e o mesmo status
        // que alimenta os cards de "Pendentes"/"Denunciados" no dashboard do
        // editor. O texto do motivo so e persistido se o ComentarioDAO tiver
        // suporte pra isso (nao confirmado).
        comentarioDAO.atualizarStatusComentario(comentarioId, StatusComentario.PENDENTE);

        request.getSession().setAttribute("sucesso", "Comentario denunciado. A moderacao vai revisar.");
        response.sendRedirect(request.getContextPath() + "/mensagens-autor");
    }

    // ===== EDITOR/ADMIN: MANTER (resolve a denuncia, comentario continua publicado) =====
    private void manter(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int comentarioId = parseIntOrDefault(request.getParameter("comentarioId"), -1);
        comentarioDAO.atualizarStatusComentario(comentarioId, StatusComentario.APROVADO);

        request.getSession().setAttribute("sucesso", "Comentario mantido no ar.");
        response.sendRedirect(request.getContextPath() + "/comentarios-moderacao");
    }

    // ===== EDITOR/ADMIN: REMOVER COMENTARIO =====
    private void remover(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int comentarioId = parseIntOrDefault(request.getParameter("comentarioId"), -1);
        comentarioDAO.removerComentario(comentarioId);

        request.getSession().setAttribute("sucesso", "Comentario removido.");
        response.sendRedirect(request.getContextPath() + "/comentarios-moderacao");
    }

    // ===== EDITOR/ADMIN: BLOQUEAR USUARIO AUTOR DO COMENTARIO =====
    private void bloquear(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int usuarioId = parseIntOrDefault(request.getParameter("usuarioId"), -1);
        // TODO: confirmar se alterarStatus espera String "BLOQUEADO" ou um enum.
        usuarioDAO.alterarStatus(usuarioId, "BLOQUEADO");

        request.getSession().setAttribute("sucesso", "Usuario bloqueado.");
        response.sendRedirect(request.getContextPath() + "/comentarios-moderacao");
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private boolean isRotaAutor(HttpServletRequest request) {
        return "/mensagens-autor".equals(request.getServletPath());
    }

    private Usuario getUsuarioLogado(HttpSession session) {
        if (session == null) return null;
        return (Usuario) session.getAttribute("usuarioLogado");
    }

    private boolean isAdminOuEditor(HttpSession session) {
        Usuario u = getUsuarioLogado(session);
        if (u == null) return false;
        return u.getTipo_usuario() == TipoUsuario.ADMIN
            || u.getTipo_usuario() == TipoUsuario.EDITOR;
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private int parseIntOrDefault(String valor, int padrao) {
        try {
            return Integer.parseInt(valor);
        } catch (Exception e) {
            return padrao;
        }
    }

    private void setErroERedirect(HttpServletRequest request, HttpServletResponse response, String rota, String msg)
            throws IOException {
        request.getSession().setAttribute("erro", msg);
        response.sendRedirect(request.getContextPath() + rota);
    }
}