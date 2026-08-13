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
 * Controller da tela autores-publico.html.
 *
 * GET sem parâmetro -> lista todos os autores públicos (AUTOR/EDITOR/ADMIN
 * ativos) já com estatísticas, especialidades e últimas 3 receitas de cada
 * um pré-carregadas em Maps por id_usuario. Isso evita N+1 consulta na JSP:
 * ela só precisa fazer ${especialidadesPorAutor[autor.id_usuario]}, etc.
 * Forward -> /pages/autores-publico.jsp
 *
 * GET ?idAutor=X -> modo "detalhe único", pensado pra alimentar o modal via
 * AJAX (fetch da JSP fragmentada) em vez de reconstruir tudo no client-side.
 * Forward -> /pages/fragments/autor-modal.jsp
 *
 * OBS: não vi as JSPs reais ainda — os caminhos de forward e os nomes dos
 * atributos de request são a minha melhor suposição seguindo o padrão do
 * CategoriaController (/pages/<nome>.jsp). Ajusta os caminhos se o seu
 * projeto usa outra convenção de pastas.
 */
@WebServlet("/AutorPublicoController")
public class AutorPublicoController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final int RECEITAS_MODAL_LIMITE = 3;

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
            System.out.println("AutorPublicoController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar AutorPublicoController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idAutorParam = request.getParameter("idAutor");

        try {
            if (idAutorParam != null) {
                carregarDetalheUnico(request, response, idAutorParam);
            } else {
                carregarListagem(request, response);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar autores: " + e.getMessage());
            request.getRequestDispatcher("/pages/autores-publico.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // LISTAGEM COMPLETA (autores-publico.html)
    // =========================================================================

    private void carregarListagem(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        Usuario logado = usuarioLogado(request);

        List<Usuario> autores = usuarioDAO.listarAutoresPublicos();

        Map<Integer, List<Categoria>> especialidadesPorAutor = new HashMap<>();
        Map<Integer, List<Receita>> receitasPorAutor = new HashMap<>();
        Map<Integer, Integer> seguidoresPorAutor = new HashMap<>();
        Map<Integer, Boolean> seguindoPorAutor = new HashMap<>();

        for (Usuario autor : autores) {

            int idAutor = autor.getId_usuario();

            especialidadesPorAutor.put(idAutor, especialidadeDAO.listarEspecialidadesPorUsuario(idAutor));
            receitasPorAutor.put(idAutor, receitaDAO.listarReceitasPublicadasPorAutor(idAutor, RECEITAS_MODAL_LIMITE));
            seguidoresPorAutor.put(idAutor, seguidorDAO.contarSeguidores(idAutor));

            if (logado != null) {
                seguindoPorAutor.put(idAutor, seguidorDAO.jaSegue(logado.getId_usuario(), idAutor));
            }
        }

        // Categorias que têm ao menos 1 especialista -> popula o <select id="filterEspecialidade">
        List<Categoria> especialidadesFiltro = especialidadeDAO.listarCategoriasComEspecialistas();

        request.setAttribute("autores", autores);
        request.setAttribute("especialidadesPorAutor", especialidadesPorAutor);
        request.setAttribute("receitasPorAutor", receitasPorAutor);
        request.setAttribute("seguidoresPorAutor", seguidoresPorAutor);
        request.setAttribute("seguindoPorAutor", seguindoPorAutor);
        request.setAttribute("especialidadesFiltro", especialidadesFiltro);

        request.getRequestDispatcher("/pages/autores-publico.jsp").forward(request, response);
    }

    // =========================================================================
    // DETALHE ÚNICO (modal via AJAX)
    // =========================================================================

    private void carregarDetalheUnico(HttpServletRequest request, HttpServletResponse response, String idAutorParam)
            throws Exception {

        int idAutor;
        try {
            idAutor = Integer.parseInt(idAutorParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "idAutor inválido.");
            return;
        }

        Usuario autor = usuarioDAO.buscarAutorPublicoPorId(idAutor);

        if (autor == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Autor não encontrado.");
            return;
        }

        Usuario logado = usuarioLogado(request);

        List<Categoria> especialidades = especialidadeDAO.listarEspecialidadesPorUsuario(idAutor);
        List<Receita> ultimasReceitas = receitaDAO.listarReceitasPublicadasPorAutor(idAutor, RECEITAS_MODAL_LIMITE);
        int totalSeguidores = seguidorDAO.contarSeguidores(idAutor);
        boolean seguindo = logado != null && seguidorDAO.jaSegue(logado.getId_usuario(), idAutor);

        request.setAttribute("autor", autor);
        request.setAttribute("especialidades", especialidades);
        request.setAttribute("ultimasReceitas", ultimasReceitas);
        request.setAttribute("totalSeguidores", totalSeguidores);
        request.setAttribute("seguindo", seguindo);

        request.getRequestDispatcher("/pages/fragments/autor-modal.jsp").forward(request, response);
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private Usuario usuarioLogado(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return null;
        return (Usuario) session.getAttribute("usuarioLogado");
    }
}