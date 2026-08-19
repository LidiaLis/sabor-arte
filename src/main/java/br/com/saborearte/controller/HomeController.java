package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.CategoriaDAO;
import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.utils.Conexao;

/**
 * Controller da tela Inicio.
 *
 * Serve DUAS JSPs com os MESMOS dados (receitas em destaque, categorias
 * principais com contagem, autores em destaque):
 *   - /pages/home-publico.jsp   -> ninguem logado (sidebar com Login/Cadastro)
 *   - /pages/home-visitante.jsp -> usuario logado como VISITANTE
 *
 * AJUSTE: se AUTOR/EDITOR/ADMIN tambem passarem por essa Home (em vez de
 * caírem direto no dashboard deles), decida aqui pra qual JSP mandar —
 * por enquanto qualquer tipo logado que não seja VISITANTE cai na home
 * publica, o que provavelmente não é o certo. Me diga a regra que eu ajusto.
 */
@WebServlet("/HomeController")
public class HomeController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final int LIMITE_RECEITAS_DESTAQUE = 3;
    private static final int LIMITE_CATEGORIAS        = 6;
    private static final int LIMITE_AUTORES_DESTAQUE  = 5;

    private Connection conexao;
    private ReceitaDAO receitaDAO;
    private CategoriaDAO categoriaDAO;
    private UsuarioDAO usuarioDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            receitaDAO   = new ReceitaDAO(conexao);
            categoriaDAO = new CategoriaDAO(conexao);
            usuarioDAO   = new UsuarioDAO(conexao);
            System.out.println("HomeController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar HomeController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Usuario usuarioLogado = (session != null) ? (Usuario) session.getAttribute("usuarioLogado") : null;

        try {
            List<Receita> receitasDestaque = receitaDAO.listarReceitasDestaque(LIMITE_RECEITAS_DESTAQUE);
            request.setAttribute("receitasDestaque", receitasDestaque);

            List<Categoria> categoriasPrincipais = categoriaDAO.listarCategoriasComContagem(LIMITE_CATEGORIAS);
            request.setAttribute("categoriasPrincipais", categoriasPrincipais);

            // listarAutoresPublicos ja traz total_receitas_publicadas pronto;
            // aqui so ordena por quem publicou mais e pega os N primeiros.
            List<Usuario> autoresDestaque = usuarioDAO.listarAutoresPublicos().stream()
                    .sorted(Comparator.comparingInt(Usuario::getTotal_receitas_publicadas).reversed())
                    .limit(LIMITE_AUTORES_DESTAQUE)
                    .collect(Collectors.toList());
            request.setAttribute("autoresDestaque", autoresDestaque);

            if (usuarioLogado != null) {
                request.getRequestDispatcher("/home.jsp").forward(request, response);
            } else {
                request.getRequestDispatcher("/home.jsp").forward(request, response);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar a página inicial: " + e.getMessage());
            String destino = (usuarioLogado != null) ? "/pages/home-visitante.jsp" : "/pages/home-publico.jsp";
            request.getRequestDispatcher(destino).forward(request, response);
        }
    }
}