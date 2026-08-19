package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.Month;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.dao.ReceitaDAO;
import br.com.saborearte.dao.CategoriaDAO;
import br.com.saborearte.dao.ComentarioDAO;
import br.com.saborearte.dao.FluxoDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.model.Categoria;
import br.com.saborearte.dao.FluxoDAO.FluxoRelatorio;
import br.com.saborearte.model.Fluxo.StatusFluxo;
import br.com.saborearte.model.Receita.StatusReceita;
import br.com.saborearte.model.Comentario.StatusComentario;
import br.com.saborearte.utils.Conexao;

/**
 * Um unico controller pro dashboard, que forwarda pra um unico JSP unificado
 * (/pages/dashboard.jsp) que decide o que renderizar (Admin/Autor/Editor)
 * olhando o tipo_usuario da sessao. Antes o controller tentava forwardar
 * pra 3 jsps separados (dashboard-admin/autor/editor.jsp) que nao existem
 * mais — corrigido pra usar sempre "/pages/dashboard.jsp".
 *
 * Os nomes/tipos dos atributos setados aqui foram realinhados com o que
 * dashboard.jsp de fato le (ex: ele espera int[]/String[] via arrayToJs(),
 * nao List<Integer>/List<String>; e nomes tipo "totalRascunhos" em vez de
 * "qtdRascunhos"). Sem isso o JSP ou cai no valor de fallback (nome errado)
 * ou lança ClassCastException (tipo errado).
 *
 * ARQUIVO UNIFICADO: base era a versao que forwarda pra JSP (Admin/Autor/Editor).
 * Foram incorporados do controller separado de dashboard-editor (JSON):
 *  - totalReceitas tambem exposto no dashboard do editor;
 *  - contagem de aprovadas/rejeitadas no mes atual (via FluxoDAO.listarRelatorio);
 *  - placeholder de usuariosBloqueados, ainda pendente de metodo em UsuarioDAO.
 *
 * REGRAS ASSUMIDAS (confirmar):
 *  - "Comentarios Pendentes" e "Comentarios Denunciados" no dashboard-editor
 *    usam o MESMO numero (StatusComentario.PENDENTE) — decisao confirmada
 *    com o usuario, ja que o enum nao tem um status separado pra denuncia.
 *  - "Agendadas" (dashboard-editor) = receitas com status_receita=publicada
 *    e data_publicacao_receita no futuro, ja que StatusReceita nao tem um
 *    valor "agendada" proprio.
 *  - No doughnut "Moderacao de Comentarios", a fatia "Excluidos" soma
 *    REMOVIDO + REJEITADO, porque o grafico so tem 4 fatias e o enum tem
 *    4 valores (PENDENTE ja aparece 2x, como Pendentes e Denunciados).
 *
 * PENDENCIAS HERDADAS DA VERSAO JSON (nao resolvidas neste merge):
 *  - usuarioDAO nao tem metodo de contagem por status (ex: "BLOQUEADO");
 *    qtdUsuariosBloqueados fica como placeholder (-1) ate esse metodo existir.
 *  - Confirmar se o pacote correto do util de conexao e
 *    "br.com.saborearte.utils.Conexao" (usado aqui) ou "br.com.saborearte.util.Conexao"
 *    (usado na versao JSON) — os dois arquivos originais divergiam nisso.
 *  - qtdAprovadasNoMes/qtdRejeitadasNoMes/qtdUsuariosBloqueados/
 *    qtdComentariosRemovidos sao setados mas o dashboard.jsp atual NAO os
 *    consome ainda (sobraram da versao JSON) — inofensivo, mas se um dia
 *    o dashboard.jsp for expandido pra mostrar isso, os nomes ja estao aqui.
 */
@WebServlet("/DashboardController")
public class DashboardController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;
    private ReceitaDAO receitaDAO;
    private CategoriaDAO categoriaDAO;
    private ComentarioDAO comentarioDAO;
    private FluxoDAO fluxoDAO;

    // =========================================================================
    // INIT
    // =========================================================================

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO    = new UsuarioDAO(conexao);
            receitaDAO    = new ReceitaDAO(conexao);
            categoriaDAO  = new CategoriaDAO(conexao);
            comentarioDAO = new ComentarioDAO(conexao);
            fluxoDAO      = new FluxoDAO(conexao);
            System.out.println("DashboardController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar DashboardController", e);
        }
    }

    // =========================================================================
    // GET
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuarioLogado") == null) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
        TipoUsuario tipo = usuarioLogado.getTipo_usuario();

        // So existe UM jsp de dashboard (/pages/dashboard.jsp) - ele mesmo
        // decide o que renderizar de acordo com o tipo_usuario da sessao.
        // Antes o controller tentava dar forward pra dashboard-admin.jsp /
        // dashboard-autor.jsp / dashboard-editor.jsp, que nao existem.
        if (tipo == TipoUsuario.VISITANTE) {
            // VISITANTE nao tem dashboard — manda pra Home dele
            response.sendRedirect(request.getContextPath() + "/HomeController");
            return;
        }

        try {
            switch (tipo) {
                case ADMIN  -> carregarDashboardAdmin(request);
                case AUTOR  -> carregarDashboardAutor(request, usuarioLogado.getId_usuario());
                case EDITOR -> carregarDashboardEditor(request);
                default -> { /* nao deveria cair aqui - VISITANTE ja foi tratado acima */ }
            }
            request.getRequestDispatcher("/pages/dashboard.jsp").forward(request, response);
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar o dashboard: " + e.getMessage());
            request.getRequestDispatcher("/pages/dashboard.jsp").forward(request, response);
        }
    }

    // =========================================================================
    // ADMIN
    // =========================================================================

    private void carregarDashboardAdmin(HttpServletRequest request) throws SQLException {

        request.setAttribute("totalUsuarios",    usuarioDAO.contarUsuariosAtivos());
        request.setAttribute("totalReceitas",    receitaDAO.contarTotalReceitas());
        request.setAttribute("totalComentarios", comentarioDAO.contarComentarios());
        request.setAttribute("totalCategorias",  categoriaDAO.contarCategoriasAtivas());

        // Grafico 1: Cadastros por Mes (usuarios + receitas), ultimos 6 meses
        // Nomes/tipos alinhados com dashboard.jsp (unico JSP pros 3 perfis):
        // ele espera "labelsCadastros" e arrays primitivos int[]/String[],
        // nao List<Integer>/List<String>.
        List<String> labelsMeses = ultimosMeses(6);
        request.setAttribute("labelsCadastros", labelsMeses.toArray(new String[0]));
        request.setAttribute("usuariosPorMes", toIntArray(preencherUltimosMeses(usuarioDAO.contarUsuariosPorMes(6), 6)));
        request.setAttribute("receitasPorMes", toIntArray(preencherUltimosMeses(receitaDAO.contarReceitasPorMes(6), 6)));

        // Grafico 2: Receitas por Categoria (Top 5)
        // dashboard.jsp espera dois arrays separados (nomes e contagens),
        // nao a lista de objetos Categoria.
        List<Categoria> categoriasTop5 = categoriaDAO.listarCategoriasComContagem(5);
        String[] categoriaTopNomes = new String[categoriasTop5.size()];
        int[] categoriaTopContagens = new int[categoriasTop5.size()];
        for (int i = 0; i < categoriasTop5.size(); i++) {
            Categoria c = categoriasTop5.get(i);
            categoriaTopNomes[i] = c.getNome_categoria();
            categoriaTopContagens[i] = c.getTotal_receitas();
        }
        request.setAttribute("categoriaTopNomes", categoriaTopNomes);
        request.setAttribute("categoriaTopContagens", categoriaTopContagens);
    }

    // =========================================================================
    // AUTOR
    // =========================================================================

    private void carregarDashboardAutor(HttpServletRequest request, int idAutor) throws SQLException {

        // Nomes alinhados com o que dashboard.jsp espera pro bloco AUTOR
        // (antes eram qtdRascunhos/qtdEmRevisao/qtdPublicadas, que o JSP
        // nunca lia — os cards ficavam sempre no valor de fallback).
        request.setAttribute("totalRascunhos",      receitaDAO.contarPorStatusEAutor(idAutor, StatusReceita.rascunho));
        request.setAttribute("totalEmRevisaoAutor", receitaDAO.contarPorStatusEAutor(idAutor, StatusReceita.aguardando_aprovacao));
        request.setAttribute("totalPublicadas",     receitaDAO.contarPorStatusEAutor(idAutor, StatusReceita.publicada));
        long totalVisualizacoes = receitaDAO.somarVisualizacoesPorAutor(idAutor);
        request.setAttribute("totalVisualizacoes",  (int) totalVisualizacoes);

        // Grafico 1: Receitas Publicadas por Mes, ultimos 5 meses
        List<String> labelsMeses = ultimosMeses(5);
        request.setAttribute("labelsAutor", labelsMeses.toArray(new String[0]));
        request.setAttribute("publicadasPorMes",
                toIntArray(preencherUltimosMeses(receitaDAO.contarPublicadasPorMesEAutor(idAutor, 5), 5)));

        // Grafico 2: Visualizacoes por Mes, ultimos 5 meses
        Map<Integer, Long> viewsPorMes = receitaDAO.somarVisualizacoesPorMesEAutor(idAutor, 5);
        request.setAttribute("visualizacoesPorMes", toIntArrayFromLong(preencherUltimosMesesLong(viewsPorMes, 5)));
    }

    // =========================================================================
    // EDITOR
    // =========================================================================

    private void carregarDashboardEditor(HttpServletRequest request) throws SQLException {

        int emRevisao   = receitaDAO.contarPorStatus(StatusReceita.aguardando_aprovacao);
        int agendadas   = receitaDAO.contarAgendadas();
        int comentPendentes = comentarioDAO.contarPorStatus(StatusComentario.PENDENTE);

        request.setAttribute("totalEmRevisaoEditor",   emRevisao);
        request.setAttribute("totalAgendadas",         agendadas);
        request.setAttribute("totalComentPendentes",   comentPendentes);
        // Mesma contagem: PENDENTE cobre os dois cards, por decisao do projeto.
        request.setAttribute("totalComentDenunciados", comentPendentes);

        // --- Incorporado da versao JSON (dashboard-editor via AJAX) ---
        request.setAttribute("totalReceitas", receitaDAO.contarTotalReceitas());

        // Grafico 1: Receitas Revisadas por Mes (tabela fluxo), ultimos 6 meses
        // Nomes/tipos alinhados com dashboard.jsp: espera "labelsEditor" e
        // int[] (nao List<Integer>).
        List<String> labelsMeses = ultimosMeses(6);
        request.setAttribute("labelsEditor", labelsMeses.toArray(new String[0]));
        request.setAttribute("revisadasPorMes", toIntArray(preencherUltimosMeses(fluxoDAO.contarRevisadosPorMes(6), 6)));

        // Grafico 2: Moderacao de Comentarios (doughnut)
        int aprovados = comentarioDAO.contarPorStatus(StatusComentario.APROVADO);
        int removidos = comentarioDAO.contarPorStatus(StatusComentario.REMOVIDO);
        int rejeitados = comentarioDAO.contarPorStatus(StatusComentario.REJEITADO);
        // "Excluidos" junta REMOVIDO + REJEITADO pra fechar as 4 fatias do grafico.
        int excluidos = removidos + rejeitados;

        request.setAttribute("modAprovados", aprovados);
        request.setAttribute("modPendentes", comentPendentes);
        request.setAttribute("modDenunciados", comentPendentes);
        request.setAttribute("modExcluidos", excluidos);
        // Exposto separado tambem, ja que a versao JSON tratava "removidos" a parte de "excluidos".
        request.setAttribute("qtdComentariosRemovidos", removidos);

        // --- Aprovadas/rejeitadas no mes atual + placeholder de bloqueados ---
        // NAO consumido pelo dashboard.jsp ainda (ver PENDENCIAS no cabecalho
        // da classe). Isolado em try/catch proprio DE PROPOSITO: antes essas
        // duas chamadas rodavam ANTES dos blocos acima e, se lancassem
        // SQLException, abortavam o metodo inteiro - fazendo os cards de
        // "Receitas Revisadas por Mes" e "Moderacao de Comentarios" (que SAO
        // usados na tela) carem sempre no valor mockado do JSP, mesmo com o
        // banco respondendo certo pros dados que eles realmente precisavam.
        try {
            LocalDate inicioMes = LocalDate.now().withDayOfMonth(1);
            LocalDate hoje = LocalDate.now();
            // ATENCAO: enum e APROVADO/REJEITADO (sem "A" no final), conforme o
            // FluxoDAO real (ver uso em contarRevisadosPorMes). listarRelatorio
            // devolve FluxoRelatorio (DTO com titulo/responsavel), nao Fluxo puro.
            List<FluxoRelatorio> aprovadasNoMes  = fluxoDAO.listarRelatorio(StatusFluxo.APROVADO, inicioMes, hoje);
            List<FluxoRelatorio> rejeitadasNoMes = fluxoDAO.listarRelatorio(StatusFluxo.REJEITADO, inicioMes, hoje);
            request.setAttribute("qtdAprovadasNoMes", aprovadasNoMes.size());
            request.setAttribute("qtdRejeitadasNoMes", rejeitadasNoMes.size());
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("qtdAprovadasNoMes", 0);
            request.setAttribute("qtdRejeitadasNoMes", 0);
        }

        // TODO: depende de um metodo novo em UsuarioDAO (ex: contarPorStatus("BLOQUEADO")).
        // Mantido como placeholder ate a assinatura ser definida.
        request.setAttribute("qtdUsuariosBloqueados", -1);
        // --- fim do trecho incorporado ---
    }

    // =========================================================================
    // UTILITÁRIOS
    // =========================================================================

    /** Rotulos dos ultimos N meses (mais antigo -> mais recente), ex: ["Mar","Abr","Mai"] */
    private List<String> ultimosMeses(int qtd) {
        List<String> labels = new ArrayList<>();
        LocalDate hoje = LocalDate.now();
        for (int i = qtd - 1; i >= 0; i--) {
            Month mes = hoje.minusMonths(i).getMonth();
            String label = mes.getDisplayName(TextStyle.SHORT, new Locale("pt", "BR"));
            labels.add(label.substring(0, 1).toUpperCase() + label.substring(1));
        }
        return labels;
    }

    /** Converte Map<mes,total> (1-12) num array ordenado dos ultimos N meses, preenchendo 0 onde faltar */
    private List<Integer> preencherUltimosMeses(Map<Integer, Integer> dados, int qtd) {
        List<Integer> valores = new ArrayList<>();
        LocalDate hoje = LocalDate.now();
        for (int i = qtd - 1; i >= 0; i--) {
            int mes = hoje.minusMonths(i).getMonthValue();
            valores.add(dados.getOrDefault(mes, 0));
        }
        return valores;
    }

    private List<Long> preencherUltimosMesesLong(Map<Integer, Long> dados, int qtd) {
        List<Long> valores = new ArrayList<>();
        LocalDate hoje = LocalDate.now();
        for (int i = qtd - 1; i >= 0; i--) {
            int mes = hoje.minusMonths(i).getMonthValue();
            valores.add(dados.getOrDefault(mes, 0L));
        }
        return valores;
    }

    /** Converte List<Integer> pra int[] — dashboard.jsp usa arrays primitivos (arrayToJs(int[])), nao List. */
    private int[] toIntArray(List<Integer> lista) {
        int[] arr = new int[lista.size()];
        for (int i = 0; i < lista.size(); i++) {
            Integer v = lista.get(i);
            arr[i] = (v != null) ? v : 0;
        }
        return arr;
    }

    /** Mesma ideia, mas pra List<Long> (ex: soma de visualizacoes, que pode vir como long do banco). */
    private int[] toIntArrayFromLong(List<Long> lista) {
        int[] arr = new int[lista.size()];
        for (int i = 0; i < lista.size(); i++) {
            Long v = lista.get(i);
            arr[i] = (v != null) ? v.intValue() : 0;
        }
        return arr;
    }
}