package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.dao.LogDAO.ResultadoLogs;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller da tela log-admin.html — acesso restrito a ADMIN.
 *
 * Por padrão (sem parâmetros na query string) traz TODOS os logs, sem
 * limite, porque a tela hoje filtra e pagina inteiramente no client-side
 * (applyFilters()/renderPage() em cima do array LOGS[]). A ideia é a JSP
 * gerar esse mesmo array via JSTL a partir de ${logs}, e o JS que já existe
 * (filtro, paginação, export PDF/Excel/Print) continua funcionando igual,
 * só que com dado real em vez de mock.
 *
 * Também aceita filtros via query string (busca, acao, entidade, periodo),
 * usando LogDAO.listarComFiltro — útil se no futuro você quiser migrar
 * esses filtros pra server-side (menos dado trafegado quando o log crescer).
 */
@WebServlet("/LogController")
public class LogController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private LogDAO logDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            logDAO = new LogDAO(conexao);
            System.out.println("LogController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar LogController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!isAdmin(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        String busca    = request.getParameter("busca");
        String acao     = request.getParameter("acao");
        String entidade = request.getParameter("entidade");
        String periodo  = request.getParameter("periodo");

        LocalDate dataInicio = null;
        LocalDate dataFim    = null;

        if (periodo != null && !periodo.isBlank()) {
            LocalDate hoje = LocalDate.now();
            switch (periodo) {
                case "hoje"  -> { dataInicio = hoje; dataFim = hoje; }
                case "7dias" -> { dataInicio = hoje.minusDays(6); dataFim = hoje; }
                case "mes"   -> { dataInicio = hoje.minusMonths(1).plusDays(1); dataFim = hoje; }
                default      -> { /* período desconhecido -> ignora o filtro */ }
            }
        }

        try {
            ResultadoLogs resultado = logDAO.listarComFiltro(
                    busca, acao, entidade, dataInicio, dataFim, 0, Integer.MAX_VALUE);

            request.setAttribute("logs", resultado.logs);
            request.setAttribute("totalLogs", resultado.total);

            // ===== Devolve os filtros aplicados, pra JSP marcar os <select>/<input> certos =====
            request.setAttribute("filtroBusca", busca);
            request.setAttribute("filtroAcao", acao);
            request.setAttribute("filtroEntidade", entidade);
            request.setAttribute("filtroPeriodo", periodo);

            request.getRequestDispatcher("/pages/log-admin.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar logs de auditoria: " + e.getMessage());
            request.getRequestDispatcher("/pages/log-admin.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
        return u != null && u.getTipo_usuario() == TipoUsuario.ADMIN;
    }
}