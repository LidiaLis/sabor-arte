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

import br.com.saborearte.dao.CategoriaDAO;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.CategoriaEmoji;
import br.com.saborearte.model.CategoriaCor;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;
import br.com.saborearte.model.Categoria.StatusCategoria;


@WebServlet("/CategoriaController")
public class CategoriaController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private CategoriaDAO categoriaDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            categoriaDAO = new CategoriaDAO(conexao);
            System.out.println("CategoriaController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar CategoriaController", e);
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

        try {
            List<Categoria> categorias = categoriaDAO.listarCategorias();
            request.setAttribute("categorias", categorias);

            List<CategoriaEmoji> emojis = categoriaDAO.listarEmojis();
            request.setAttribute("emojis", emojis);

            List<CategoriaCor> cores = categoriaDAO.listarCores();
            request.setAttribute("cores", cores);

            request.getRequestDispatcher("/pages/categorias.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar categorias: " + e.getMessage());
            request.getRequestDispatcher("/pages/categorias.jsp").forward(request, response);
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

        if (!isAdminOuEditor(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String acao = request.getParameter("action");

        try {
            switch (acao != null ? acao : "") {
                case "cadastrar" -> cadastrar(request, response);
                case "atualizar" -> atualizar(request, response);
                case "excluir"   -> excluir(request, response);
                case "status"    -> alterarStatus(request, response);
                case "salvarEmoji" -> salvarEmoji(request, response);
                default          -> response.sendRedirect(request.getContextPath() + "/CategoriaController");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/CategoriaController");
        }
    }

    // =========================================================================
    // AÇÃO: CADASTRAR
    // =========================================================================

    private void cadastrar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String nome      = request.getParameter("nome");
        String descricao = request.getParameter("descricao");
        String emojiUni  = request.getParameter("emoji");
        String corUni    = request.getParameter("cor");

        if (isBlank(nome)) {
            setErroERedirect(request, response, "O nome da categoria é obrigatório.");
            return;
        }
        if (isBlank(emojiUni)) {
            setErroERedirect(request, response, "Selecione um ícone para a categoria.");
            return;
        }
        if (isBlank(corUni)) {
            setErroERedirect(request, response, "Selecione uma cor para a categoria.");
            return;
        }

        if (categoriaDAO.nomeJaExiste(nome.trim())) {
            setErroERedirect(request, response, "Já existe uma categoria com este nome.");
            return;
        }

        CategoriaEmoji emoji = categoriaDAO.buscarEmojiPorUnicode(emojiUni.trim());

        if (emoji == null) {

            categoriaDAO.cadastrarEmoji(emojiUni.trim());

            emoji = categoriaDAO.buscarEmojiPorUnicode(emojiUni.trim());
        }        CategoriaCor   cor   = categoriaDAO.buscarCorPorUnicode(corUni.trim());

        if (cor == null) {
            setErroERedirect(request, response, "Cor selecionada inválida.");
            return;
        }

        Categoria nova = new Categoria();
        nova.setNome_categoria(nome.trim());
        nova.setDescricao_categoria(isBlank(descricao) ? "" : descricao.trim());
        nova.setEmoji_categoria(emoji.getUnicode_emoji());
        nova.setCor_categoria(cor.getUnicode_cor());

        categoriaDAO.cadastrarCategoria(nova);

        request.getSession().setAttribute("sucesso", "Categoria \"" + nome.trim() + "\" criada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/CategoriaController");
    }

    // =========================================================================
    // AÇÃO: ATUALIZAR
    // =========================================================================

    private void atualizar(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int    id        = Integer.parseInt(request.getParameter("id"));
        String nome      = request.getParameter("nome");
        String descricao = request.getParameter("descricao");
        String emojiUni  = request.getParameter("emoji");
        String corUni    = request.getParameter("cor");

        if (isBlank(nome)) {
            setErroERedirect(request, response, "O nome da categoria é obrigatório.");
            return;
        }

        Categoria categoria = categoriaDAO.buscarCategoriaPorId(id);
        if (categoria == null) {
            setErroERedirect(request, response, "Categoria não encontrada.");
            return;
        }

        if (categoriaDAO.nomeJaExiste(nome.trim(), id)) {
            setErroERedirect(request, response, "Já existe outra categoria com este nome.");
            return;
        }

        if (!isBlank(emojiUni)) {

            String unicode = emojiUni.trim();

            CategoriaEmoji emoji = categoriaDAO.buscarEmojiPorUnicode(unicode);

            if (emoji == null) {
                categoriaDAO.cadastrarEmoji(unicode);
                emoji = categoriaDAO.buscarEmojiPorUnicode(unicode);
            }

            if (emoji == null) {
                setErroERedirect(request, response, "Ícone selecionado inválido.");
                return;
            }

            categoria.setEmoji_categoria(emoji.getUnicode_emoji());
        }

        if (!isBlank(corUni)) {
            CategoriaCor cor = categoriaDAO.buscarCorPorUnicode(corUni.trim());
            if (cor == null) {
                setErroERedirect(request, response, "Cor selecionada inválida.");
                return;
            }
            categoria.setCor_categoria(cor.getUnicode_cor());
        }

        categoria.setNome_categoria(nome.trim());
        categoria.setDescricao_categoria(isBlank(descricao) ? "" : descricao.trim());

        categoriaDAO.atualizarCategoria(categoria);

        request.getSession().setAttribute("sucesso", "Categoria \"" + nome.trim() + "\" atualizada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/CategoriaController");
    }

    // =========================================================================
    // AÇÃO: EXCLUIR
    // =========================================================================

    private void excluir(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);

        if (!isAdmin(session)) {
            setErroERedirect(request, response, "Apenas administradores podem excluir categorias.");
            return;
        }

        int id = Integer.parseInt(request.getParameter("id"));

        Categoria categoria = categoriaDAO.buscarCategoriaPorId(id);
        if (categoria == null) {
            setErroERedirect(request, response, "Categoria não encontrada.");
            return;
        }

        categoriaDAO.excluirCategoria(id);

        request.getSession().setAttribute("sucesso",
            "Categoria \"" + categoria.getNome_categoria() + "\" excluída com sucesso!");
        response.sendRedirect(request.getContextPath() + "/CategoriaController");
    }

    // =========================================================================
    // AÇÃO: ALTERAR STATUS
    // =========================================================================

    private void alterarStatus(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        int    id         = Integer.parseInt(request.getParameter("id"));
        String novoStatus = request.getParameter("novoStatus");

        StatusCategoria statusEnum;
        try {
            statusEnum = StatusCategoria.valueOf(novoStatus != null ? novoStatus.toUpperCase() : "");
        } catch (IllegalArgumentException e) {
            setErroERedirect(request, response, "Status inválido.");
            return;
        }

        Categoria categoria = categoriaDAO.buscarCategoriaPorId(id);
        if (categoria == null) {
            setErroERedirect(request, response, "Categoria não encontrada.");
            return;
        }

        categoria.setStatus_categoria(statusEnum);
        categoriaDAO.atualizarCategoria(categoria);

        String label = statusEnum == StatusCategoria.ATIVA ? "ativa" : "inativa";
        request.getSession().setAttribute("sucesso",
            "Categoria \"" + categoria.getNome_categoria() + "\" " + label + " com sucesso!");
        response.sendRedirect(request.getContextPath() + "/CategoriaController");
    }
    
    // =========================================================================
    // AÇÃO: SALVAR NOVO EMOJI NA LISTA
    // =========================================================================
    
    private void salvarEmoji(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        String unicode = request.getParameter("emoji");
        System.out.println("Antes do cadastro: " + unicode);

        if (isBlank(unicode)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Emoji vazio");
            return;
        }

        CategoriaEmoji emoji = categoriaDAO.buscarEmojiPorUnicode(unicode.trim());
        System.out.println("Antes do cadastro: " + unicode);

        if (emoji == null) {
            categoriaDAO.cadastrarEmoji(unicode.trim());
        }

        response.setContentType("text/plain;charset=UTF-8");
        response.getWriter().write("OK");
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

    private void setErroERedirect(HttpServletRequest request, HttpServletResponse response, String msg)
            throws IOException {
        request.getSession().setAttribute("erro", msg);
        response.sendRedirect(request.getContextPath() + "/CategoriaController");
    }
}