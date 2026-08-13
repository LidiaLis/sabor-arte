package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.dao.FluxoDAO.FluxoRelatorio;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

/**
 * Controller único de relatórios - serve as duas telas:
 *
 *   /relatorio-autor  -> relatorio-autor.jsp (autor: historico de fluxo
 *                        escopado as proprias receitas)
 *   /relatorio-editor -> relatorio-editor.jsp (editor/admin: historico de
 *                        fluxo site-wide, com mini-stats por status)
 *
 * REESCRITO no padrao PRG/JSP do projeto (sem JSON), igual ao
 * CategoriaController/ReceitaController:
 *  - GET forward direto pra JSP, sessao lida via usuarioLogado + TipoUsuario;
 *  - fluxoDAO.listarRelatorio() devolve List<FluxoDAO.FluxoRelatorio> (DTO
 *    com titulo da receita e nome do responsavel ja prontos via JOIN),
 *    NAO List<Fluxo> como o controller antigo assumia;
 *  - StatusFluxo.APROVADO / REJEITADO confirmados (sem a vogal final, ver
 *    FluxoDAO.contarRevisadosPorMes). Os demais valores do enum (ex.: um
 *    status pendente/publicado) NAO foram confirmados ainda, entao as
 *    mini-stats contam so aprovados/rejeitados e agrupam o resto em
 *    "outros" pra nao travar a compilacao com nome de enum inventado.
 *
 * TODO (herdado do controller antigo): FluxoDAO.listarRelatorio(status,
 * inicio, fim) hoje e site-wide (sem autorId). Para /relatorio-autor
 * precisa de uma versao nova, ex:
 *   fluxoDAO.listarRelatorioPorAutor(autorId, status, inicio, fim)
 * Sem isso, o lado autor deste controller traz o fluxo de receitas de
 * TODOS os autores - por enquanto o metodo site-wide e usado como
 * placeholder (ver gerarAutor), igual o controller antigo ja fazia.
 *
 * TODO: FluxoRelatorio tem campos publicos (idFluxo, tituloReceita,
 * responsavel, statusDe, statusPara, observacao, dataFluxo) sem getters —
 * confirmar se a JSP consegue ler isso via EL (${item.tituloReceita}) ou
 * se vai precisar de getters no DTO.
 *
 * Acoes (parametro "acao", igual nas duas rotas):
 *   GET ?acao=gerar (ou sem parametro) -> lista de fluxo filtrada por
 *                                         status/periodo (+ mini-stats,
 *                                         so no lado editor)
 */
@WebServlet(urlPatterns = {"/relatorio-editor", "/relatorio-autor"})
public class RelatorioController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private FluxoDAO fluxoDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            fluxoDAO = new FluxoDAO(conexao);
            System.out.println("RelatorioController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar RelatorioController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (isRotaAutor(request)) {
            Usuario usuarioLogado = getUsuarioLogado(session);
            if (usuarioLogado == null) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }
            gerarAutor(request, response, usuarioLogado.getId_usuario());
        } else {
            if (!isAdminOuEditor(session)) {
                response.sendRedirect(request.getContextPath() + "/LoginController");
                return;
            }
            gerar(request, response);
        }
    }

    // ===== AUTOR: relatorio-autor.jsp =====
    private void gerarAutor(HttpServletRequest request, HttpServletResponse response, int autorId)
            throws ServletException, IOException {

        try {
            StatusFluxo status = parseStatus(request.getParameter("status"));
            LocalDate dataInicio = parseDataOuDefault(request.getParameter("dataInicio"), LocalDate.now().minusMonths(1));
            LocalDate dataFim = parseDataOuDefault(request.getParameter("dataFim"), LocalDate.now());

            // ATENCAO: chamando o metodo site-wide por enquanto - troque assim que
            // existir a versao com autorId (ver TODO no topo do arquivo). Enquanto
            // isso, esta tela mostra fluxo de receitas de outros autores tambem.
            List<FluxoRelatorio> registros = fluxoDAO.listarRelatorio(status, dataInicio, dataFim);

            request.setAttribute("registros", registros);
            request.setAttribute("dataInicio", dataInicio);
            request.setAttribute("dataFim", dataFim);
            request.setAttribute("statusFiltro", request.getParameter("status"));

            request.getRequestDispatcher("/pages/relatorio-autor.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao gerar relatorio: " + e.getMessage());
            request.getRequestDispatcher("/pages/relatorio-autor.jsp").forward(request, response);
        }
    }

    // ===== EDITOR/ADMIN: relatorio-editor.jsp (com mini-stats) =====
    private void gerar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            StatusFluxo status = parseStatus(request.getParameter("status"));
            LocalDate dataInicio = parseDataOuDefault(request.getParameter("dataInicio"), LocalDate.now().minusMonths(1));
            LocalDate dataFim = parseDataOuDefault(request.getParameter("dataFim"), LocalDate.now());

            List<FluxoRelatorio> registros = fluxoDAO.listarRelatorio(status, dataInicio, dataFim);

            // Mini-stats do topo da tela (contadas em Java a partir da lista, ja
            // que nao ha metodo de COUNT agrupado por status em FluxoDAO ainda).
            // So aprovados/rejeitados sao contados a parte porque so esses dois
            // valores do enum StatusFluxo foram confirmados ate agora.
            int aprovados = 0, rejeitados = 0, outros = 0;
            for (FluxoRelatorio fr : registros) {
                if (StatusFluxo.APROVADO.name().equals(fr.statusPara)) {
                    aprovados++;
                } else if (StatusFluxo.REJEITADO.name().equals(fr.statusPara)) {
                    rejeitados++;
                } else {
                    outros++;
                }
            }

            request.setAttribute("registros", registros);
            request.setAttribute("totalPeriodo", registros.size());
            request.setAttribute("qtdAprovados", aprovados);
            request.setAttribute("qtdRejeitados", rejeitados);
            request.setAttribute("qtdOutros", outros);
            request.setAttribute("dataInicio", dataInicio);
            request.setAttribute("dataFim", dataFim);
            request.setAttribute("statusFiltro", request.getParameter("status"));

            request.getRequestDispatcher("/pages/relatorio-editor.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao gerar relatorio: " + e.getMessage());
            request.getRequestDispatcher("/pages/relatorio-editor.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    private boolean isRotaAutor(HttpServletRequest request) {
        return "/relatorio-autor".equals(request.getServletPath());
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

    private StatusFluxo parseStatus(String statusParam) {
        return (statusParam != null && !statusParam.isEmpty())
                ? StatusFluxo.valueOf(statusParam) : null;
    }

    private LocalDate parseDataOuDefault(String valor, LocalDate padrao) {
        return (valor != null && !valor.isEmpty()) ? LocalDate.parse(valor) : padrao;
    }
}