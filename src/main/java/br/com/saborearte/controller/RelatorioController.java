package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.Collections;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.RelatorioDAO;
import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

@WebServlet(urlPatterns = { "/RelatorioController", "/relatorio-admin", "/relatorio-editor", "/relatorio-autor" })
public class RelatorioController extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Usuario usuario = getUsuario(request.getSession(false));
        if (usuario == null) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String rota = request.getServletPath();
        if ("/RelatorioController".equals(rota)) {
            despacharPorPerfil(request, response, usuario);
            return;
        }
        if ("/relatorio-admin".equals(rota) && usuario.getTipo_usuario() == TipoUsuario.ADMIN) {
            gerarAdmin(request, response);
            return;
        }
        if ("/relatorio-editor".equals(rota)
                && (usuario.getTipo_usuario() == TipoUsuario.EDITOR
                        || usuario.getTipo_usuario() == TipoUsuario.ADMIN)) {
            gerarConteudo(request, response, null, "editor");
            return;
        }
        if ("/relatorio-autor".equals(rota) && usuario.getTipo_usuario() == TipoUsuario.AUTOR) {
            gerarConteudo(request, response, usuario.getId_usuario(), "autor");
            return;
        }
        response.sendError(HttpServletResponse.SC_FORBIDDEN);
    }

    private void despacharPorPerfil(HttpServletRequest request, HttpServletResponse response, Usuario usuario)
            throws ServletException, IOException {
        if (usuario.getTipo_usuario() == TipoUsuario.ADMIN) {
            gerarAdmin(request, response);
        } else if (usuario.getTipo_usuario() == TipoUsuario.EDITOR) {
            gerarConteudo(request, response, null, "editor");
        } else if (usuario.getTipo_usuario() == TipoUsuario.AUTOR) {
            gerarConteudo(request, response, usuario.getId_usuario(), "autor");
        } else {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
        }
    }

    private void gerarAdmin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String tipo = normalizarTipoAdmin(request.getParameter("tipo"));
        String status = request.getParameter("status");
        String statusFluxoValor = request.getParameter("statusFluxo");
        LocalDate inicio = parseData(request.getParameter("dataInicio"));
        LocalDate fim = parseData(request.getParameter("dataFim"));
        try (Connection conexao = Conexao.getConnection()) {
            RelatorioDAO dao = new RelatorioDAO(conexao);
            FluxoDAO fluxoDAO = new FluxoDAO(conexao);
            request.setAttribute("tipoRelatorio", tipo);
            request.setAttribute("statusFiltro", status);
            request.setAttribute("statusFluxoFiltro", statusFluxoValor);
            request.setAttribute("dataInicio", inicio);
            request.setAttribute("dataFim", fim);
            request.setAttribute("usuarios",
                    "usuarios".equals(tipo) ? dao.listarUsuarios(status) : Collections.emptyList());
            request.setAttribute("categorias",
                    "categorias".equals(tipo) ? dao.listarCategorias(status) : Collections.emptyList());
            request.setAttribute("fluxos", "fluxo".equals(tipo)
                    ? fluxoDAO.listarRelatorio(parseStatusFluxo(statusFluxoValor), inicio, fim)
                    : Collections.emptyList());
            request.getRequestDispatcher("/pages/relatorio-admin.jsp").forward(request, response);
        } catch (Exception e) {
            encaminharErro(request, response, "/pages/relatorio-admin.jsp", e);
        }
    }

    private void gerarConteudo(HttpServletRequest request, HttpServletResponse response, Integer autorId,
            String perfil) throws ServletException, IOException {
        String tipo = normalizarTipo(request.getParameter("tipo"), "receitas", "comentarios");
        try (Connection conexao = Conexao.getConnection()) {
            RelatorioDAO dao = new RelatorioDAO(conexao);
            Integer categoria = parseInteger(request.getParameter("categoria"));
            String buscaAutor = request.getParameter("autor");
            String status = request.getParameter("status");
            LocalDate inicio = parseData(request.getParameter("dataInicio"));
            LocalDate fim = parseData(request.getParameter("dataFim"));

            request.setAttribute("tipoRelatorio", tipo);
            request.setAttribute("perfilRelatorio", perfil);
            request.setAttribute("categoriaFiltro", categoria);
            request.setAttribute("autorFiltro", buscaAutor);
            request.setAttribute("statusFiltro", status);
            request.setAttribute("dataInicio", inicio);
            request.setAttribute("dataFim", fim);
            request.setAttribute("categoriasFiltro", "receitas".equals(tipo)
                    ? dao.listarCategorias(null) : Collections.emptyList());
            request.setAttribute("receitas", "receitas".equals(tipo)
                    ? dao.listarReceitas(autorId, categoria, buscaAutor) : Collections.emptyList());
            request.setAttribute("comentarios", "comentarios".equals(tipo)
                    ? dao.listarComentarios(autorId, status, inicio, fim) : Collections.emptyList());
            request.getRequestDispatcher("/pages/relatorio-conteudo.jsp").forward(request, response);
        } catch (Exception e) {
            encaminharErro(request, response, "/pages/relatorio-conteudo.jsp", e);
        }
    }

    private void encaminharErro(HttpServletRequest request, HttpServletResponse response, String jsp, Exception e)
            throws ServletException, IOException {
        System.err.println("Erro ao gerar relatório em " + request.getServletPath());
        e.printStackTrace();
        request.setAttribute("erro", "Não foi possível gerar o relatório. Tente novamente.");
        request.getRequestDispatcher(jsp).forward(request, response);
    }

    private Usuario getUsuario(HttpSession session) {
        return session == null ? null : (Usuario) session.getAttribute("usuarioLogado");
    }

    private String normalizarTipo(String valor, String padrao, String alternativo) {
        return alternativo.equals(valor) ? alternativo : padrao;
    }

    private String normalizarTipoAdmin(String valor) {
        return "categorias".equals(valor) || "fluxo".equals(valor) ? valor : "usuarios";
    }

    private StatusFluxo parseStatusFluxo(String valor) {
        try {
            return valor == null || valor.isBlank() ? null : StatusFluxo.valueOf(valor);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private Integer parseInteger(String valor) {
        try {
            return valor == null || valor.isBlank() ? null : Integer.valueOf(valor);
        } catch (Exception e) {
            return null;
        }
    }

    private LocalDate parseData(String valor) {
        try {
            return valor == null || valor.isBlank() ? null : LocalDate.parse(valor);
        } catch (Exception e) {
            return null;
        }
    }
}
