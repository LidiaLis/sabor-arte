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

import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.model.Fluxo;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Receita.StatusAtividade;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller responsavel pela tela de revisao/gestao de receitas do editor
 * (receitas-editor.jsp).
 *
 * REESCRITO no mesmo padrao do CategoriaController:
 *  - GET forward direto pra JSP (sem JSON), com mensagens flash de
 *    sucesso/erro lidas da sessao e limpas em seguida;
 *  - POST em PRG (Post-Redirect-Get): cada acao processa e redireciona
 *    de volta pro proprio controller, nunca forward direto no POST;
 *  - catch (Exception e) generico nas acoes (mesmo estilo do
 *    CategoriaController), evitando SQLException/NumberFormatException
 *    nao tratada;
 *  - isAdmin / isAdminOuEditor / isBlank / setErroERedirect copiados do
 *    mesmo padrao usado no CategoriaController.
 *
 * Acoes esperadas:
 *   GET  (sem parametro "acao", ou acao=listar) -> lista receitas (filtro + paginacao)
 *   GET  ?acao=detalhar&id=X                    -> detalhe da receita + historico de fluxo
 *   POST ?action=aprovar                        -> aprova a receita (registra Fluxo)
 *   POST ?action=rejeitar                       -> rejeita a receita, com motivo (registra Fluxo)
 *   POST ?action=publicar                       -> publica a receita ja aprovada (registra Fluxo)
 *   POST ?action=toggleStatus                   -> ativa/inativa a receita (ReceitaDAO)
 *
 * PENDENCIAS (confirmar contra os models reais):
 *  - StatusFluxo.PUBLICADO: so confirmei APROVADO/REJEITADO no FluxoDAO real;
 *    se o enum nao tiver PUBLICADO, ajustar o metodo publicar() abaixo.
 *  - StatusAtividade.ATIVA: usado so pro rotulo da mensagem de sucesso do
 *    toggleStatus, seguindo o mesmo estilo do alterarStatus do CategoriaController;
 *    confirmar se o valor do enum e esse mesmo.
 *  - Nomes dos JSPs (/pages/receitas-editor.jsp e /pages/receita-detalhe.jsp)
 *    sao suposicao, ajustar pros nomes reais das telas.
 */
@WebServlet("/receitas")
public class ReceitaController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private ReceitaDAO receitaDAO;
    private FluxoDAO fluxoDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            receitaDAO = new ReceitaDAO(conexao);
            fluxoDAO = new FluxoDAO(conexao);
            System.out.println("ReceitaController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar ReceitaController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!isAdminOuEditor(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String sucesso = (String) session.getAttribute("sucesso");
        String erro    = (String) session.getAttribute("erro");
        if (sucesso != null) { request.setAttribute("sucesso", sucesso); session.removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("erro",    erro);    session.removeAttribute("erro");    }

        String acao = request.getParameter("acao");
        if (acao == null) acao = "listar";

        try {
            switch (acao) {
                case "detalhar" -> detalhar(request, response);
                default -> listar(request, response);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar receitas: " + e.getMessage());
            request.getRequestDispatcher("/pages/receitas-editor.jsp").forward(request, response);
        }
    }

    // ===== LISTAGEM (filtro + paginacao) =====
    private void listar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String filtro = request.getParameter("filtro"); // texto de busca (titulo, autor...)
        String statusParam = request.getParameter("status"); // ATIVA / INATIVA / null=todas
        String autorIdParam = request.getParameter("autorId");
        int page = parseIntOrDefault(request.getParameter("page"), 1);
        int size = parseIntOrDefault(request.getParameter("size"), 10);

        StatusAtividade status = null;
        if (!isBlank(statusParam)) {
            try {
                status = StatusAtividade.valueOf(statusParam);
            } catch (IllegalArgumentException e) {
                request.setAttribute("erro", "Status invalido: " + statusParam);
            }
        }
        Integer autorId = (!isBlank(autorIdParam)) ? Integer.parseInt(autorIdParam) : null;

        // ATENCAO: isto lista por StatusAtividade (ativa/inativa), nao pelo status
        // de fluxo (pendente/aprovada/rejeitada). Se a tela precisar filtrar por
        // status de REVISAO, sera necessario um metodo novo, algo como:
        //   fluxoDAO.listarReceitasPorStatusFluxo(StatusFluxo status, String filtro, int page, int size)
        // que junte Receita com o ultimo registro de Fluxo de cada uma.
        List<Receita> receitas = receitaDAO.listarReceitasAdmin(filtro, status, autorId, page, size);
        int total = receitaDAO.contarReceitasAdmin(filtro, status, autorId);

        request.setAttribute("receitas", receitas);
        request.setAttribute("total", total);
        request.setAttribute("page", page);
        request.setAttribute("size", size);
        request.setAttribute("filtro", filtro);
        request.setAttribute("statusFiltro", statusParam);

        request.getRequestDispatcher("/pages/receitas-editor.jsp").forward(request, response);
    }

    // ===== DETALHE + HISTORICO DE FLUXO =====
    private void detalhar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int id = parseIntOrDefault(request.getParameter("id"), -1);
        if (id == -1) {
            request.setAttribute("erro", "id obrigatorio.");
            listar(request, response);
            return;
        }

        Receita receita = receitaDAO.buscarReceitaPorId(id);
        if (receita == null) {
            request.setAttribute("erro", "Receita nao encontrada.");
            listar(request, response);
            return;
        }

        List<Fluxo> historico = fluxoDAO.listarPorReceita(id);

        request.setAttribute("receita", receita);
        request.setAttribute("historicoFluxo", historico);
        request.getRequestDispatcher("/pages/receita-detalhe.jsp").forward(request, response);
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

        if (!isAdminOuEditor(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "") {
                case "aprovar"      -> aprovar(request, response);
                case "rejeitar"     -> rejeitar(request, response);
                case "publicar"     -> publicar(request, response);
                case "toggleStatus" -> toggleStatus(request, response);
                default             -> response.sendRedirect(request.getContextPath() + "/receitas");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/receitas");
        }
    }

    // ===== ACAO: APROVAR =====
    private void aprovar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));
        String comentario = request.getParameter("comentario"); // opcional

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");

        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(editor.getId_usuario());
        fluxo.setStatus_fluxo(StatusFluxo.APROVADO);
        fluxo.setObservacao_fluxo(comentario);
        fluxoDAO.registrarFluxo(fluxo);

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" aprovada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: REJEITAR =====
    private void rejeitar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));
        String motivo = request.getParameter("motivo"); // obrigatorio na tela

        if (isBlank(motivo)) {
            setErroERedirect(request, response, "Motivo da rejeicao e obrigatorio.");
            return;
        }

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");

        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(editor.getId_usuario());
        fluxo.setStatus_fluxo(StatusFluxo.REJEITADO);
        fluxo.setObservacao_fluxo(motivo.trim());
        fluxoDAO.registrarFluxo(fluxo);

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" rejeitada.");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: PUBLICAR =====
    private void publicar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        Usuario editor = (Usuario) request.getSession(false).getAttribute("usuarioLogado");

        Fluxo fluxo = new Fluxo();
        fluxo.setReceita(receitaId);
        fluxo.setUsuario(editor.getId_usuario());
        fluxoDAO.registrarFluxo(fluxo);

        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" publicada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // ===== ACAO: ATIVAR / INATIVAR =====
    private void toggleStatus(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int receitaId = Integer.parseInt(request.getParameter("receitaId"));

        Receita receita = receitaDAO.buscarReceitaPorId(receitaId);
        if (receita == null) {
            setErroERedirect(request, response, "Receita nao encontrada.");
            return;
        }

        StatusAtividade novoStatus = receitaDAO.toggleStatusAtividade(receitaId);

        String label = novoStatus == StatusAtividade.ativo ? "ativada" : "inativada";
        request.getSession().setAttribute("sucesso",
                "Receita \"" + receita.getTitulo_receita() + "\" " + label + " com sucesso!");
        response.sendRedirect(request.getContextPath() + "/receitas");
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
        return u != null && u.getTipo_usuario() == TipoUsuario.ADMIN;
    }

    private boolean isAdminOuEditor(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
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

    private void setErroERedirect(HttpServletRequest request, HttpServletResponse response, String msg)
            throws IOException {
        request.getSession().setAttribute("erro", msg);
        response.sendRedirect(request.getContextPath() + "/receitas");
    }
}