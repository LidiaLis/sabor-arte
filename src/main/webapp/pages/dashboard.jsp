<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.Usuario.TipoUsuario" %>
<%!
    // ===== Helpers para converter arrays Java em literais JS, sem JSTL =====
    private String arrayToJs(int[] arr) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < arr.length; i++) {
            if (i > 0) sb.append(",");
            sb.append(arr[i]);
        }
        return sb.append("]").toString();
    }

    private String arrayToJs(String[] arr) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < arr.length; i++) {
            if (i > 0) sb.append(",");
            sb.append("'").append(arr[i]).append("'");
        }
        return sb.append("]").toString();
    }
%>
<%
    // ===== Dashboard unificado — ADMIN / AUTOR / EDITOR =====
    // paginaAtual usado pelo sidebar.jsp para destacar o item de menu ativo
    request.setAttribute("paginaAtual", "dashboard");

    Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
    if (usuarioLogado == null) {
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }
    TipoUsuario tipo = usuarioLogado.getTipo_usuario();

    // ---------------------------------------------------------------------
    // TODO: substituir todo bloco abaixo pelos dados reais que o
    // DashboardController deve colocar via request.setAttribute(...).
    // Deixei fallback com os mesmos valores de exemplo dos mockups originais
    // pra dar pra visualizar a tela já rodando antes do back estar pronto.
    // ---------------------------------------------------------------------

    // --- ADMIN ---
    Integer totalUsuarios     = (Integer) request.getAttribute("totalUsuarios");
    Integer totalReceitas     = (Integer) request.getAttribute("totalReceitas");
    Integer totalComentarios  = (Integer) request.getAttribute("totalComentarios");
    Integer totalCategorias   = (Integer) request.getAttribute("totalCategorias");
    if (totalUsuarios == null)    totalUsuarios = 312;
    if (totalReceitas == null)    totalReceitas = 184;
    if (totalComentarios == null) totalComentarios = 287;
    if (totalCategorias == null)  totalCategorias = 9;

    int[] mesesUsuarios  = (int[]) request.getAttribute("usuariosPorMes");
    int[] mesesReceitas  = (int[]) request.getAttribute("receitasPorMes");
    String[] labelsAdmin = (String[]) request.getAttribute("labelsCadastros");
    if (mesesUsuarios == null)  mesesUsuarios  = new int[]{28, 34, 41, 38, 52, 47};
    if (mesesReceitas == null)  mesesReceitas  = new int[]{18, 22, 27, 24, 33, 30};
    if (labelsAdmin == null)    labelsAdmin    = new String[]{"Jan","Fev","Mar","Abr","Mai","Jun"};

    String[] categoriaNomes = (String[]) request.getAttribute("categoriaTopNomes");
    int[] categoriaContagens = (int[]) request.getAttribute("categoriaTopContagens");
    if (categoriaNomes == null)      categoriaNomes = new String[]{"Sobremesas","Massas","Saladas","Sopas","Carnes"};
    if (categoriaContagens == null)  categoriaContagens = new int[]{34, 28, 22, 18, 14};

    // --- AUTOR ---
    Integer totalRascunhos      = (Integer) request.getAttribute("totalRascunhos");
    Integer totalEmRevisaoAutor = (Integer) request.getAttribute("totalEmRevisaoAutor");
    Integer totalPublicadas     = (Integer) request.getAttribute("totalPublicadas");
    Integer totalVisualizacoes  = (Integer) request.getAttribute("totalVisualizacoes");
    if (totalRascunhos == null)      totalRascunhos = 4;
    if (totalEmRevisaoAutor == null) totalEmRevisaoAutor = 2;
    if (totalPublicadas == null)     totalPublicadas = 15;
    if (totalVisualizacoes == null)  totalVisualizacoes = 3240;

    int[] publicadasPorMes = (int[]) request.getAttribute("publicadasPorMes");
    int[] visualizacoesPorMes = (int[]) request.getAttribute("visualizacoesPorMes");
    String[] labelsAutor = (String[]) request.getAttribute("labelsAutor");
    if (publicadasPorMes == null)     publicadasPorMes = new int[]{2, 3, 2, 4, 4};
    if (visualizacoesPorMes == null)  visualizacoesPorMes = new int[]{230, 410, 380, 520, 640};
    if (labelsAutor == null)          labelsAutor = new String[]{"Jan","Fev","Mar","Abr","Mai"};

    // --- EDITOR ---
    Integer totalEmRevisaoEditor   = (Integer) request.getAttribute("totalEmRevisaoEditor");
    Integer totalAgendadas         = (Integer) request.getAttribute("totalAgendadas");
    Integer totalComentPendentes   = (Integer) request.getAttribute("totalComentPendentes");
    Integer totalComentDenunciados = (Integer) request.getAttribute("totalComentDenunciados");
    if (totalEmRevisaoEditor == null)   totalEmRevisaoEditor = 7;
    if (totalAgendadas == null)         totalAgendadas = 3;
    if (totalComentPendentes == null)   totalComentPendentes = 12;
    if (totalComentDenunciados == null) totalComentDenunciados = 6;

    int[] revisadasPorMes = (int[]) request.getAttribute("revisadasPorMes");
    String[] labelsEditor = (String[]) request.getAttribute("labelsEditor");
    if (revisadasPorMes == null) revisadasPorMes = new int[]{14, 19, 16, 22, 25, 21};
    if (labelsEditor == null)    labelsEditor = new String[]{"Jan","Fev","Mar","Abr","Mai","Jun"};

    Integer modAprovados   = (Integer) request.getAttribute("modAprovados");
    Integer modPendentes   = (Integer) request.getAttribute("modPendentes");
    Integer modDenunciados = (Integer) request.getAttribute("modDenunciados");
    Integer modExcluidos   = (Integer) request.getAttribute("modExcluidos");
    if (modAprovados == null)   modAprovados = 215;
    if (modPendentes == null)   modPendentes = 12;
    if (modDenunciados == null) modDenunciados = 6;
    if (modExcluidos == null)   modExcluidos = 9;
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js"></script>
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;
    --draft:#6a7a8a;--draft-bg:#eef1f4;--archived:#8a7a6a;--archived-bg:#f4f0ec;
    --revision:#a05a3a;--revision-bg:#f6e6de;
    --sidebar-w:260px;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,0.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,0.1) 0%,transparent 60%);pointer-events:none;}
  .sidebar-brand{padding:28px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .brand-row{display:flex;align-items:center;gap:12px;}
  .brand-badge{width:38px;height:38px;background:linear-gradient(135deg,var(--moss-light),var(--sage));border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  .brand-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--cream);display:block;line-height:1;}
  .brand-sub{font-size:10px;color:var(--sage);text-transform:uppercase;letter-spacing:1.2px;margin-top:3px;display:block;font-weight:300;}
  .sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;}
  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,var(--gold),var(--gold-light));border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--moss-dark);flex-shrink:0;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:300;}
  .sidebar-nav{flex:1;padding:16px 0;position:relative;z-index:1;}
  .nav-section-label{font-size:9px;text-transform:uppercase;letter-spacing:1.8px;color:rgba(163,177,138,0.5);padding:16px 24px 6px;font-weight:500;}
  .nav-item{display:flex;align-items:center;gap:12px;padding:11px 24px;color:rgba(245,240,232,0.7);text-decoration:none;font-size:14px;font-weight:400;cursor:pointer;transition:all 0.2s;border-left:3px solid transparent;}
  .nav-item:hover{color:var(--cream);background:rgba(255,255,255,0.06);border-left-color:var(--sage);}
  .nav-item.active{color:var(--cream);background:rgba(163,177,138,0.15);border-left-color:var(--sage-light);font-weight:500;}
  .nav-icon{width:22px;text-align:center;font-size:16px;flex-shrink:0;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:2px;color:rgba(245,240,232,0.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all 0.2s;}
  .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}

  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}

  .content{flex:1;padding:50px 40px 24px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:65px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}

  .stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin-bottom:36px;}
  .stat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;padding:24px 22px;position:relative;overflow:hidden;transition:transform 0.2s,box-shadow 0.2s;cursor:default;}
  .stat-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(47,61,37,0.1);}
  .stat-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
  .stat-card.moss::before{background:linear-gradient(90deg,var(--moss),var(--sage));}
  .stat-card.gold::before{background:linear-gradient(90deg,var(--gold),var(--gold-light));}
  .stat-card.pending::before{background:linear-gradient(90deg,var(--pending),#e8a84a);}
  .stat-card.green::before{background:linear-gradient(90deg,var(--published),#5ab870);}
  .stat-card.sage::before{background:linear-gradient(90deg,var(--sage),var(--sage-light));}
  .stat-card.alert::before{background:linear-gradient(90deg,#9b4444,#c46a6a);}
  .stat-icon{width:40px;height:40px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;margin-bottom:16px;}
  .stat-card.moss .stat-icon{background:rgba(74,94,58,0.1);}
  .stat-card.gold .stat-icon{background:rgba(196,162,101,0.1);}
  .stat-card.pending .stat-icon{background:rgba(196,131,42,0.12);}
  .stat-card.green .stat-icon{background:rgba(58,122,74,0.1);}
  .stat-card.sage .stat-icon{background:rgba(163,177,138,0.18);}
  .stat-card.alert .stat-icon{background:rgba(155,68,68,0.12);}
  .stat-value{font-family:'Nunito',sans-serif;font-size:40px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:4px;letter-spacing:-1px;}
  .stat-label{font-size:12px;color:var(--text-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:500;}

  .charts-row{display:grid;grid-template-columns:1fr 1fr;gap:20px;}
  .chart-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;padding:20px 22px;}
  .chart-card-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;}
  .chart-card-title{font-size:16px;font-weight:600;color:var(--text-dark);}
  .chart-card-sub{font-size:12px;color:var(--text-light);font-weight:300;margin-top:2px;}
  .chart-legend{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:12px;}
  .legend-item{display:flex;align-items:center;gap:5px;font-size:11px;color:var(--text-mid);}
  .legend-dot{width:10px;height:10px;border-radius:2px;flex-shrink:0;}

  @media(max-width:1280px){.charts-row{grid-template-columns:1fr;}}
  @media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:768px){.sidebar{display:none;} .main{margin-left:0;} .content{padding:24px 20px;} .topbar{padding:0 20px;}}
  @media(max-width:480px){.stats-row{grid-template-columns:1fr;}}
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Principal</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Dashboard</span>
    </div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
<%
    if (tipo == TipoUsuario.ADMIN) {
%>
        <div class="section-title">Bom dia, <em><%= usuarioLogado.getNome_usuario() %></em> 👑</div>
        <div class="section-date">Painel Administrativo</div>
<%
    } else if (tipo == TipoUsuario.AUTOR) {
%>
        <div class="section-title">Bom dia, <em><%= usuarioLogado.getNome_usuario() %></em> 👩‍🍳</div>
        <div class="section-date">Painel do Autor</div>
<%
    } else if (tipo == TipoUsuario.EDITOR) {
%>
        <div class="section-title">Bom dia, <em><%= usuarioLogado.getNome_usuario() %></em> ✏️</div>
        <div class="section-date">Painel de Edição</div>
<%
    }
%>
      </div>
    </div>

<%
    if (tipo == TipoUsuario.ADMIN) {
%>
    <!-- CARDS ADMIN: Usuários, Receitas, Comentários, Categorias -->
    <div class="stats-row">
      <div class="stat-card moss">
        <div class="stat-icon">👥</div>
        <div class="stat-value"><%= totalUsuarios %></div>
        <div class="stat-label">Usuários Cadastrados</div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">📝</div>
        <div class="stat-value"><%= totalReceitas %></div>
        <div class="stat-label">Receitas Cadastradas</div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">💬</div>
        <div class="stat-value"><%= totalComentarios %></div>
        <div class="stat-label">Comentários</div>
      </div>
      <div class="stat-card sage">
        <div class="stat-icon">📂</div>
        <div class="stat-value"><%= totalCategorias %></div>
        <div class="stat-label">Categorias</div>
      </div>
    </div>

    <div class="charts-row">
      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">📈 Cadastros por Mês</div>
            <div class="chart-card-sub">Usuários e receitas · últimos <%= labelsAdmin.length %> meses</div>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item"><div class="legend-dot" style="background:#4a5e3a"></div> Usuários</div>
          <div class="legend-item"><div class="legend-dot" style="background:#c4a265;border-radius:50%"></div> Receitas</div>
        </div>
        <div style="position:relative;width:100%;height:200px;">
          <canvas id="cadastrosChart"></canvas>
        </div>
      </div>

      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">📂 Receitas por Categoria</div>
            <div class="chart-card-sub">Top <%= categoriaNomes.length %> categorias</div>
          </div>
        </div>
        <div style="position:relative;width:100%;height:200px;">
          <canvas id="categoriaChart"></canvas>
        </div>
      </div>
    </div>
<%
    } else if (tipo == TipoUsuario.AUTOR) {
%>
    <!-- CARDS AUTOR: Rascunhos, Em revisão, Publicadas, Visualizações -->
    <div class="stats-row">
      <div class="stat-card green">
        <div class="stat-icon">📝</div>
        <div class="stat-value"><%= totalRascunhos %></div>
        <div class="stat-label">Rascunhos</div>
      </div>
      <div class="stat-card pending">
        <div class="stat-icon">📤</div>
        <div class="stat-value"><%= totalEmRevisaoAutor %></div>
        <div class="stat-label">Em Revisão</div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">✅</div>
        <div class="stat-value"><%= totalPublicadas %></div>
        <div class="stat-label">Publicadas</div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">👁️</div>
        <div class="stat-value"><%= totalVisualizacoes %></div>
        <div class="stat-label">Visualizações</div>
      </div>
    </div>

    <div class="charts-row">
      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">📈 Receitas Publicadas por Mês</div>
            <div class="chart-card-sub">Últimos <%= labelsAutor.length %> meses</div>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item"><div class="legend-dot" style="background:#4a5e3a"></div> Publicadas</div>
        </div>
        <div style="position:relative;width:100%;height:200px;">
          <canvas id="publicadasChart"></canvas>
        </div>
      </div>

      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">👁️ Visualizações por Mês</div>
            <div class="chart-card-sub">Soma de visualizacoes_receita</div>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item"><div class="legend-dot" style="background:#c4a265"></div> Visualizações</div>
        </div>
        <div style="position:relative;width:100%;height:200px;">
          <canvas id="viewsChart"></canvas>
        </div>
      </div>
    </div>
<%
    } else if (tipo == TipoUsuario.EDITOR) {
%>
    <!-- CARDS EDITOR: Em revisão, Agendadas, Comentários pendentes, Denunciados -->
    <div class="stats-row">
      <div class="stat-card pending">
        <div class="stat-icon">📝</div>
        <div class="stat-value"><%= totalEmRevisaoEditor %></div>
        <div class="stat-label">Em Revisão</div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">📅</div>
        <div class="stat-value"><%= totalAgendadas %></div>
        <div class="stat-label">Agendadas</div>
      </div>
      <div class="stat-card moss">
        <div class="stat-icon">💬</div>
        <div class="stat-value"><%= totalComentPendentes %></div>
        <div class="stat-label">Comentários Pendentes</div>
      </div>
      <div class="stat-card alert">
        <div class="stat-icon">🚩</div>
        <div class="stat-value"><%= totalComentDenunciados %></div>
        <div class="stat-label">Comentários Denunciados</div>
      </div>
    </div>

    <div class="charts-row">
      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">🔄 Receitas Revisadas por Mês</div>
            <div class="chart-card-sub">Fonte: tabela Fluxo · últimos <%= labelsEditor.length %> meses</div>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item"><div class="legend-dot" style="background:#4a5e3a"></div> Revisadas</div>
        </div>
        <div style="position:relative;width:100%;height:200px;">
          <canvas id="revisadasChart"></canvas>
        </div>
      </div>

      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <div class="chart-card-title">🛡️ Moderação de Comentários</div>
            <div class="chart-card-sub">Status atual dos comentários</div>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item"><div class="legend-dot" style="background:#3a7a4a;border-radius:50%"></div> Aprovados</div>
          <div class="legend-item"><div class="legend-dot" style="background:#c4832a;border-radius:50%"></div> Pendentes</div>
          <div class="legend-item"><div class="legend-dot" style="background:#9b4444;border-radius:50%"></div> Denunciados</div>
          <div class="legend-item"><div class="legend-dot" style="background:#6a7a8a;border-radius:50%"></div> Excluídos</div>
        </div>
        <div style="position:relative;width:100%;height:200px;padding-top:4px;">
          <canvas id="moderacaoChart"></canvas>
        </div>
      </div>
    </div>
<%
    }
%>

  </div>
</main>

<script>
<%
    if (tipo == TipoUsuario.ADMIN) {
%>
  new Chart(document.getElementById('cadastrosChart'), {
    type: 'line',
    data: {
      labels: <%= arrayToJs(labelsAdmin) %>,
      datasets: [
        {
          label: 'Usuários',
          data: <%= arrayToJs(mesesUsuarios) %>,
          borderColor: '#4a5e3a',
          backgroundColor: 'rgba(74,94,58,0.08)',
          borderWidth: 2,
          pointBackgroundColor: '#4a5e3a',
          pointRadius: 4,
          tension: 0.4,
          fill: true
        },
        {
          label: 'Receitas',
          data: <%= arrayToJs(mesesReceitas) %>,
          borderColor: '#c4a265',
          backgroundColor: 'rgba(196,162,101,0.06)',
          borderWidth: 2,
          pointBackgroundColor: '#c4a265',
          pointRadius: 4,
          tension: 0.4,
          fill: true,
          borderDash: [5,3]
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' } },
        y: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' }, beginAtZero: true }
      }
    }
  });

  new Chart(document.getElementById('categoriaChart'), {
    type: 'bar',
    data: {
      labels: <%= arrayToJs(categoriaNomes) %>,
      datasets: [{
        label: 'Receitas',
        data: <%= arrayToJs(categoriaContagens) %>,
        backgroundColor: ['#4a5e3a', '#c4a265', '#3a7a4a', '#c4832a', '#a3b18a'],
        borderRadius: 3,
        borderSkipped: false
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' }, beginAtZero: true },
        y: { grid: { display: false }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' } }
      }
    }
  });
<%
    } else if (tipo == TipoUsuario.AUTOR) {
%>
  new Chart(document.getElementById('publicadasChart'), {
    type: 'bar',
    data: {
      labels: <%= arrayToJs(labelsAutor) %>,
      datasets: [{
        label: 'Publicadas',
        data: <%= arrayToJs(publicadasPorMes) %>,
        backgroundColor: '#4a5e3a',
        borderRadius: 3,
        borderSkipped: false
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' } },
        y: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480', stepSize: 1 }, beginAtZero: true }
      }
    }
  });

  new Chart(document.getElementById('viewsChart'), {
    type: 'line',
    data: {
      labels: <%= arrayToJs(labelsAutor) %>,
      datasets: [{
        label: 'Visualizações',
        data: <%= arrayToJs(visualizacoesPorMes) %>,
        borderColor: '#c4a265',
        backgroundColor: 'rgba(196,162,101,0.1)',
        borderWidth: 2,
        pointBackgroundColor: '#c4a265',
        pointRadius: 4,
        tension: 0.4,
        fill: true
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' } },
        y: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' }, beginAtZero: true }
      }
    }
  });
<%
    } else if (tipo == TipoUsuario.EDITOR) {
%>
  new Chart(document.getElementById('revisadasChart'), {
    type: 'bar',
    data: {
      labels: <%= arrayToJs(labelsEditor) %>,
      datasets: [{
        label: 'Revisadas',
        data: <%= arrayToJs(revisadasPorMes) %>,
        backgroundColor: '#4a5e3a',
        borderRadius: 3,
        borderSkipped: false
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' } },
        y: { grid: { color: 'rgba(166,156,138,0.15)' }, ticks: { font: { family: 'DM Sans', size: 11 }, color: '#8a9480' }, beginAtZero: true }
      }
    }
  });

  new Chart(document.getElementById('moderacaoChart'), {
    type: 'doughnut',
    data: {
      labels: ['Aprovados', 'Pendentes', 'Denunciados', 'Excluídos'],
      datasets: [{
        data: [<%= modAprovados %>, <%= modPendentes %>, <%= modDenunciados %>, <%= modExcluidos %>],
        backgroundColor: ['#3a7a4a', '#c4832a', '#9b4444', '#6a7a8a'],
        borderColor: '#faf8f4',
        borderWidth: 3,
        hoverOffset: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '60%',
      plugins: { legend: { display: false } }
    }
  });
<%
    }
%>
</script>
</body>
</html>
