package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.EspecialidadeDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.SeguidorDAO;
import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller unificado das telas públicas de autor. Antes existiam duas
 * classes (AutorController + AutorPublicoController) fazendo praticamente a
 * mesma coisa em duas URLs diferentes — foram fundidas aqui numa só, mapeada
 * nas duas URLs originais pra nada quebrar (links/AJAX que já apontem pra
 * qualquer uma das duas continuam funcionando).
 *
 * Três fluxos, todos via GET:
 *
 *  1) SEM parâmetro                -> listagem completa de autores públicos.
 *     Forward -> /pages/autores.jsp
 *     Atributos: listaAutores, especialidadesPorAutor, receitasPorAutor,
 *                seguidoresPorAutor, seguindoPorAutor, especialidadesFiltro,
 *                currentPage
 *
 *  2) ?id=<id_usuario>             -> detalhe completo do autor (página própria).
 *     Forward -> /pages/autor-detalhe.jsp
 *     Atributos: autor, especialidades, receitas, totalSeguidores,
 *                mostrarBotaoSeguir, seguindo, souEuMesmo
 *
 *  3) ?idAutor=<id_usuario>        -> compatibilidade com links antigos;
 *     redireciona para a página completa ?id=<id_usuario>.
 *
 * Regra do botão de Seguir (mostrarBotaoSeguir): só é true quando TODAS as
 * condições valem — (a) é a página de detalhe completa, nunca o modal;
 * (b) tem usuário logado; (c) o logado não é o próprio autor da página;
 * (d) o tipo do usuário logado é VISITANTE. Autor/Editor/Admin e visitantes
 * anônimos nunca veem o botão.
 */
@WebServlet(urlPatterns = { "/AutorController", "/AutorPublicoController" })
public class AutorController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Limite de receitas na página de detalhe completa (aba "Receitas"). */
    private static final int LIMITE_RECEITAS_DETALHE = 100;

    /** Limite de receitas no modal rápido (só uma prévia). */
    private static final int LIMITE_RECEITAS_MODAL = 3;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private EspecialidadeDAO especialidadeDAO;
    private ReceitaDAO receitaDAO;
    private SeguidorDAO seguidorDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            especialidadeDAO = new EspecialidadeDAO(conexao);
            receitaDAO = new ReceitaDAO(conexao);
            seguidorDAO = new SeguidorDAO(conexao);
            System.out.println("AutorController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar AutorController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idAutorParam = request.getParameter("idAutor"); // modal (AJAX)
        String idParam = request.getParameter("id");           // página de detalhe completa

        try {
            if (idAutorParam != null) {
                redirecionarDetalheLegado(request, response, idAutorParam);
            } else if (idParam != null && !idParam.trim().isEmpty()) {
                carregarDetalheCompleto(request, response, idParam);
            } else {
                carregarListagem(request, response);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar autores: " + e.getMessage());
            request.getRequestDispatcher("/pages/autores.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // LISTAGEM COMPLETA (autores.jsp)
    // =========================================================================

    private void carregarListagem(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        Usuario logado = usuarioLogado(request);

        // listarAutoresPublicos ja filtra tipo_usuario = 'AUTOR' e
        // status = 'ATIVO' direto no SQL (UsuarioDAO).
        List<Usuario> autores = usuarioDAO.listarAutoresPublicos();

        Map<Integer, List<Categoria>> especialidadesPorAutor = new HashMap<>();
        Map<Integer, List<Receita>> receitasPorAutor = new HashMap<>();
        Map<Integer, Integer> seguidoresPorAutor = new HashMap<>();
        Map<Integer, Boolean> seguindoPorAutor = new HashMap<>();

        for (Usuario autor : autores) {

            int idAutor = autor.getId_usuario();

            especialidadesPorAutor.put(idAutor, especialidadeDAO.listarEspecialidadesPorUsuario(idAutor));
            receitasPorAutor.put(idAutor, receitaDAO.listarReceitasPublicadasPorAutor(idAutor, LIMITE_RECEITAS_MODAL));
            seguidoresPorAutor.put(idAutor, seguidorDAO.contarSeguidores(idAutor));

            if (logado != null) {
                seguindoPorAutor.put(idAutor, seguidorDAO.jaSegue(logado.getId_usuario(), idAutor));
            }
        }

        // Categorias que têm ao menos 1 especialista -> popula o <select id="filterEspecialidade">
        List<Categoria> especialidadesFiltro = especialidadeDAO.listarCategoriasComEspecialistas();

        // "listaAutores" é o nome que autores.jsp realmente espera em
        // request.getAttribute(...).
        request.setAttribute("listaAutores", autores);
        request.setAttribute("especialidadesPorAutor", especialidadesPorAutorNomes(especialidadesPorAutor));
        request.setAttribute("receitasPorAutor", receitasPorAutor);
        request.setAttribute("seguidoresPorAutor", seguidoresPorAutor);
        request.setAttribute("seguindoPorAutor", seguindoPorAutor);
        request.setAttribute("especialidadesFiltro", especialidadesFiltro);
        request.setAttribute("currentPage", "autores");

        request.getRequestDispatcher("/pages/autores.jsp").forward(request, response);
    }

    // =========================================================================
    // DETALHE COMPLETO (autor-detalhe.jsp) — mostra o botão de Seguir
    // =========================================================================

    private void carregarDetalheCompleto(HttpServletRequest request, HttpServletResponse response, String idParam)
            throws Exception {

        int idUsuario;
        try {
            idUsuario = Integer.parseInt(idParam.trim());
        } catch (NumberFormatException e) {
            carregarListagem(request, response);
            return;
        }

        carregarDetalheAutor(request, response, idUsuario, LIMITE_RECEITAS_DETALHE,
                /* mostrarBotaoSeguir */ true, "receitas", "/pages/autor-detalhe.jsp");
    }

    // =========================================================================
    // COMPATIBILIDADE COM A ROTA ANTIGA DE DETALHE
    // =========================================================================

    private void redirecionarDetalheLegado(HttpServletRequest request,
            HttpServletResponse response, String idAutorParam) throws IOException {

        int idAutor;
        try {
            idAutor = Integer.parseInt(idAutorParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "idAutor inválido.");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/AutorController?id=" + idAutor);
    }

    // =========================================================================
    // NÚCLEO COMUM ÀS DUAS TELAS DE DETALHE
    // =========================================================================

    /**
     * Carrega os dados de um autor (usados tanto pela página de detalhe
     * completa quanto pelo modal rápido) e faz o forward pro destino certo.
     *
     * @param limiteReceitas       quantas receitas trazer (100 na página cheia, 3 no modal)
     * @param paginaCompleta       true = página de detalhe completa; false = modal rápido.
     *                             O modal nunca mostra o botão de Seguir nem calcula
     *                             "seguindo"/"souEuMesmo" — é só uma prévia pública.
     * @param nomeAtributoReceitas nome do atributo de request pra lista de
     *                             receitas ("receitas" ou "ultimasReceitas"),
     *                             mantido igual ao que cada JSP já espera
     * @param destino              caminho do forward (JSP completa ou fragment do modal)
     */
    private void carregarDetalheAutor(HttpServletRequest request, HttpServletResponse response,
            int idAutor, int limiteReceitas, boolean paginaCompleta,
            String nomeAtributoReceitas, String destino) throws Exception {

        Usuario autor = usuarioDAO.buscarAutorPublicoPorId(idAutor);

        if (autor == null) {
            // Autor não existe, não é AUTOR/EDITOR/ADMIN, ou está inativo.
            if (paginaCompleta) {
                request.getSession().setAttribute("erro", "Autor não encontrado.");
                response.sendRedirect(request.getContextPath() + "/AutorController");
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Autor não encontrado.");
            }
            return;
        }

        List<Categoria> especialidades = especialidadeDAO.listarEspecialidadesPorUsuario(idAutor);
        List<Receita> receitas = receitaDAO.listarReceitasPublicadasPorAutor(idAutor, limiteReceitas);
        int totalSeguidores = seguidorDAO.contarSeguidores(idAutor);

        Usuario logado = usuarioLogado(request);
        Boolean seguindo = null;
        boolean souEuMesmo = false;
        boolean mostrarBotaoSeguir = false;

        // Botão de Seguir: só existe na página de detalhe completa (nunca no
        // modal), só pra quem está logado, só pra quem NÃO é o próprio autor,
        // e só pra usuários do tipo VISITANTE — Autor/Editor/Admin (o
        // "público" interno da equipe) não seguem outros autores por essa tela.
        if (paginaCompleta && logado != null) {
            souEuMesmo = (logado.getId_usuario() == idAutor);
            boolean ehVisitante = logado.getTipo_usuario() == Usuario.TipoUsuario.VISITANTE;
            if (!souEuMesmo && ehVisitante) {
                seguindo = seguidorDAO.jaSegue(logado.getId_usuario(), idAutor);
                mostrarBotaoSeguir = true;
            }
        }

        request.setAttribute("autor", autor);
        request.setAttribute("especialidades", especialidades);
        request.setAttribute(nomeAtributoReceitas, receitas);
        request.setAttribute("totalSeguidores", totalSeguidores);
        request.setAttribute("mostrarBotaoSeguir", mostrarBotaoSeguir);
        request.setAttribute("seguindo", seguindo);
        request.setAttribute("souEuMesmo", souEuMesmo);

        request.getRequestDispatcher(destino).forward(request, response);
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    /**
     * autores.jsp espera Map<Integer, List<String>> (nomes das
     * especialidades, usados direto nas tags do modal). O DAO devolve
     * List<Categoria>, então convertemos aqui pra evitar o
     * ClassCastException que a JSP tomaria ao tentar iterar Categoria
     * como se fosse String.
     */
    private Map<Integer, List<String>> especialidadesPorAutorNomes(Map<Integer, List<Categoria>> origem) {
        Map<Integer, List<String>> resultado = new HashMap<>();
        for (Map.Entry<Integer, List<Categoria>> entry : origem.entrySet()) {
            List<String> nomes = new java.util.ArrayList<>();
            for (Categoria c : entry.getValue()) {
                nomes.add(c.getNome_categoria());
            }
            resultado.put(entry.getKey(), nomes);
        }
        return resultado;
    }

    private Usuario usuarioLogado(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return null;
        return (Usuario) session.getAttribute("usuarioLogado");
    }
}
