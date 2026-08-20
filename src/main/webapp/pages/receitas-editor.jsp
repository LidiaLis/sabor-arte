<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Collections" %>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value)
      .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
      .replace("\"", "&quot;").replace("'", "&#39;");
  }
  private int intAttr(javax.servlet.http.HttpServletRequest req, String name) {
    Object value = req.getAttribute(name);
    return value instanceof Number ? ((Number) value).intValue() : 0;
  }
%>
<%
  List<Receita> receitas = (List<Receita>) request.getAttribute("receitas");
  if (receitas == null) receitas = Collections.emptyList();
  List<Categoria> categorias = (List<Categoria>) request.getAttribute("categorias");
  if (categorias == null) categorias = Collections.emptyList();
  Map<Integer,String> tempos = (Map<Integer,String>) request.getAttribute("tempoAguardandoPorReceita");
  if (tempos == null) tempos = Collections.emptyMap();
  String csrfToken = request.getAttribute("csrfToken") == null ? "" : String.valueOf(request.getAttribute("csrfToken"));
  String busca = request.getAttribute("busca") == null ? "" : String.valueOf(request.getAttribute("busca"));
  Integer idCategoria = request.getAttribute("idCategoria") instanceof Integer
      ? (Integer) request.getAttribute("idCategoria") : null;
  int pageAtual = Math.max(1, intAttr(request, "page"));
  int totalPages = Math.max(1, intAttr(request, "totalPages"));
  int size = Math.max(1, intAttr(request, "size"));
  int total = intAttr(request, "total");
  String buscaUrl = java.net.URLEncoder.encode(busca, java.nio.charset.StandardCharsets.UTF_8);
  String ctx = request.getContextPath();
  String sufixoQuery = "&amp;size=" + size + "&amp;busca=" + buscaUrl + (idCategoria == null ? "" : "&amp;idCategoria=" + idCategoria);
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Fila de Revisão</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;
    --draft:#6a7a8a;--draft-bg:#eef1f4;--archived:#8a7a6a;--archived-bg:#f4f0ec;
    --revision:#a05a3a;--revision-bg:#f6e6de;--error:#9b4444;--error-bg:#fdf0f0;
    --sidebar-w:260px;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  /* ===== SIDEBAR ===== */
  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,0.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,0.1) 0%,transparent 60%);pointer-events:none;}
  .sidebar-brand{padding:28px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .brand-row{display:flex;align-items:center;gap:12px;}
  .brand-badge{width:38px;height:38px;background:linear-gradient(135deg,var(--moss-light),var(--sage));border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  .brand-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--cream);display:block;line-height:1;}
  .brand-sub{font-size:10px;color:var(--sage);text-transform:uppercase;letter-spacing:1.2px;margin-top:3px;display:block;font-weight:300;}
  .sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;cursor:pointer;}
  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,#8e44ad,#6c3483);border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--cream);flex-shrink:0;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:300;}
  .sidebar-nav{flex:1;padding:16px 0;position:relative;z-index:1;}
  .nav-section-label{font-size:9px;text-transform:uppercase;letter-spacing:1.8px;color:rgba(163,177,138,0.5);padding:16px 24px 6px;font-weight:500;}
  .nav-item{display:flex;align-items:center;gap:12px;padding:11px 24px;color:rgba(245,240,232,0.7);text-decoration:none;font-size:14px;font-weight:400;cursor:pointer;transition:all 0.2s;border-left:3px solid transparent;}
  .nav-item:hover{color:var(--cream);background:rgba(255,255,255,0.06);border-left-color:var(--sage);}
  .nav-item.active{color:var(--cream);background:rgba(163,177,138,0.15);border-left-color:var(--sage-light);font-weight:500;}
  .nav-icon{width:22px;text-align:center;font-size:16px;flex-shrink:0;}
  .nav-badge{margin-left:auto;background:var(--gold);color:var(--moss-dark);font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;padding:2px 7px;border-radius:10px;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:2px;color:rgba(245,240,232,0.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all 0.2s;}
  .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}

  /* ===== MAIN / TOPBAR ===== */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .topbar-left{display:flex;align-items:center;gap:14px;}
  .menu-toggle{display:none;background:none;border:none;font-size:24px;cursor:pointer;color:var(--text-dark);padding:4px;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:16px;}

  /* ===== CONTENT ===== */
  .content{flex:1;padding:50px 40px 40px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:36px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}

  /* ===== FLASH MESSAGES ===== */
  .flash-banner{display:flex;align-items:center;gap:10px;padding:12px 16px;border-radius:3px;font-size:13px;font-weight:500;margin-bottom:20px;}
  .flash-banner.success{background:var(--published-bg);color:var(--published);border:1px solid rgba(58,122,74,.25);}
  .flash-banner.error{background:var(--error-bg);color:var(--error);border:1px solid rgba(155,68,68,.25);}

  /* ===== STAT CARDS (compactos) ===== */
  .stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:22px;}
  .stat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;padding:14px 16px;position:relative;overflow:hidden;transition:transform 0.2s,box-shadow 0.2s;cursor:default;display:flex;align-items:center;gap:12px;}
  .stat-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(47,61,37,0.1);}
  .stat-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
  .stat-card.pending::before{background:linear-gradient(90deg,var(--pending),#e8a84a);}
  .stat-card.moss::before{background:linear-gradient(90deg,var(--moss),var(--sage));}
  .stat-card.green::before{background:linear-gradient(90deg,var(--published),#5ab870);}
  .stat-card.red::before{background:linear-gradient(90deg,var(--error),#c96a6a);}
  .stat-card.gold::before{background:linear-gradient(90deg,var(--gold),var(--gold-light));}
  .stat-icon{width:34px;height:34px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
  .stat-card.pending .stat-icon{background:rgba(196,131,42,0.12);}
  .stat-card.moss .stat-icon{background:rgba(74,94,58,0.1);}
  .stat-card.green .stat-icon{background:rgba(58,122,74,0.12);}
  .stat-card.red .stat-icon{background:rgba(155,68,68,0.1);}
  .stat-card.gold .stat-icon{background:rgba(196,162,101,0.1);}
  .stat-text{min-width:0;}
  .stat-value{font-family:'Nunito',sans-serif;font-size:24px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:2px;letter-spacing:-0.5px;transition:color 0.2s;}
  .stat-label{font-size:10.5px;color:var(--text-light);text-transform:uppercase;letter-spacing:0.6px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

  /* ===== FILTER PANEL (lateral) ===== */
  .content-layout{display:grid;grid-template-columns:260px 1fr;gap:24px;align-items:start;}
  .right-panel{min-width:0;}
  .filter-panel{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;position:sticky;top:88px;}
  .filter-panel-head{padding:14px 18px;border-bottom:1px solid var(--cream-dark);font-size:11px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1.2px;display:flex;align-items:center;gap:8px;}
  .filter-bar{display:flex;flex-direction:column;align-items:stretch;gap:16px;padding:18px;}
  .filter-field{display:flex;flex-direction:column;gap:6px;width:100%;}
  .filter-label{font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1px;}
  .filter-input,.filter-select{width:100%;padding:9px 12px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);background:var(--cream);transition:border-color 0.2s,box-shadow 0.2s;outline:none;}
  .filter-input:focus,.filter-select:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.08);}
  .btn-clear-filters{width:100%;padding:9px 16px;background:none;border:1.5px solid var(--cream-dark);border-radius:2px;color:var(--text-mid);font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;white-space:nowrap;}
  .btn-clear-filters:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}

  /* ===== TABLE CARD ===== */
  .table-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .table-card-head{padding:16px 22px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .table-card-title{font-size:15px;font-weight:600;color:var(--text-dark);}
  .table-card-meta{font-size:11px;color:var(--text-light);font-weight:300;}
  .table-wrap{overflow-x:auto;}
  .data-table{width:100%;border-collapse:collapse;font-size:13px;min-width:900px;}
  .data-table thead th{padding:10px 16px;text-align:left;background:var(--cream);border-bottom:2px solid var(--cream-dark);font-size:10px;text-transform:uppercase;letter-spacing:1px;color:var(--text-light);font-weight:700;white-space:nowrap;}
  .data-table tbody tr{border-bottom:1px solid var(--cream-dark);transition:background 0.12s;}
  .data-table tbody tr:last-child{border-bottom:none;}
  .data-table tbody tr:hover{background:rgba(245,240,232,0.7);}
  .data-table td{padding:12px 16px;color:var(--text-mid);vertical-align:middle;}

  .table-footer{padding:12px 20px;border-top:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .footer-info{font-size:11px;color:var(--text-light);font-weight:300;}
  .footer-info strong{font-family:'Nunito',sans-serif;font-weight:700;color:var(--text-mid);}
  .pagination{display:flex;gap:4px;}
  .pag-btn{width:28px;height:28px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-family:'Nunito',sans-serif;font-size:11px;font-weight:700;color:var(--text-light);display:flex;align-items:center;justify-content:center;transition:all 0.15s;text-decoration:none;}
  .pag-btn:hover{border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}

  .author-cell{display:flex;align-items:center;gap:9px;}
  .author-dot{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;color:white;flex-shrink:0;}
  .author-name{font-size:12.5px;color:var(--text-dark);font-weight:600;}
  .author-tag{font-size:10px;color:var(--text-light);font-weight:300;}

  .pill{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:2px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;white-space:nowrap;}
  .pill-dot{width:5px;height:5px;border-radius:50%;background:currentColor;}
  .pill.pendente{background:var(--pending-bg);color:var(--pending);}
  .pill.aprovado{background:var(--published-bg);color:var(--published);}
  .pill.removido{background:var(--error-bg);color:var(--error);}
  .pill.rejeitado{background:var(--revision-bg);color:var(--revision);}

  .row-actions{display:flex;gap:5px;flex-wrap:wrap;align-items:center;} .row-actions form{display:inline-flex;align-items:center;}
  .row-btn{width:27px;height:27px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-size:12px;display:flex;align-items:center;justify-content:center;color:var(--text-light);transition:all 0.15s;text-decoration:none;}
  .row-btn:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}
  .row-btn.keep:hover{border-color:var(--published);color:var(--published);background:var(--published-bg);}
  .row-btn.remove:hover{border-color:var(--error);color:var(--error);background:var(--error-bg);}
  .row-btn:disabled{opacity:0.3;cursor:not-allowed;}

  .reject-inline{display:inline-flex;align-items:center;gap:5px;}
  .reject-input{width:120px;padding:6px 8px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:11px;color:var(--text-dark);background:var(--cream);outline:none;transition:border-color .2s;}
  .reject-input:focus{border-color:var(--moss-light);background:var(--warm-white);}
  .reject-input::placeholder{color:var(--text-light);}

  .empty-state{text-align:center;padding:70px 30px;}
  .empty-icon{font-size:48px;margin-bottom:14px;opacity:0.4;}
  .empty-text{font-family:'Playfair Display',serif;font-size:18px;color:var(--text-light);font-style:italic;margin-bottom:6px;}
  .empty-sub{font-size:13px;color:var(--text-light);font-weight:300;}

  /* ===== RESPONSIVE ===== */
  @media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:900px){.content-layout{grid-template-columns:1fr;} .filter-panel{position:static;}}
  @media(max-width:768px){.sidebar{transform:translateX(-100%);transition:transform 0.3s;} .sidebar.open{transform:translateX(0);} .main{margin-left:0;} .content{padding:24px 20px;} .topbar{padding:0 20px;} .menu-toggle{display:block;}}
  @media(max-width:480px){.stats-row{grid-template-columns:1fr;}}
</style>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/conteudo-design-system.css">
</head>
<body>

<!-- ===== SIDEBAR EDITOR (estático) ===== -->
<%
  request.setAttribute("currentPage", "receitas");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />

<div id="overlay" onclick="closeSidebar()" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:99"></div>

<main class="main">
  <div class="topbar">
    <div class="topbar-left">
      <button class="menu-toggle" onclick="toggleSidebar()">☰</button>
      <div class="page-crumb">
        <span>Principal</span>
        <span style="color:var(--cream-dark)">/</span>
        <span class="current">Revisão editorial</span>
      </div>
    </div>
    <div class="topbar-right"></div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Fila de <em>Revisão</em></div>
        <div class="section-date"><%= h(request.getAttribute("dataPainel")) %> · somente receitas aguardando aprovação</div>
      </div>
    </div>

    <% if (request.getAttribute("sucesso") != null) { %>
      <div class="flash-banner success">✅ <%= h(request.getAttribute("sucesso")) %></div>
    <% } %>
    <% if (request.getAttribute("erro") != null) { %>
      <div class="flash-banner error">⚠️ <%= h(request.getAttribute("erro")) %></div>
    <% } %>

    <!-- STAT CARDS -->
    <div class="stats-row">
      <div class="stat-card pending">
        <div class="stat-icon">📝</div>
        <div class="stat-text">
          <div class="stat-value"><%= intAttr(request,"totalAguardando") %></div>
          <div class="stat-label">Aguardando Revisão</div>
        </div>
      </div>
      <div class="stat-card moss">
        <div class="stat-icon">✅</div>
        <div class="stat-text">
          <div class="stat-value"><%= intAttr(request,"totalRevisadasHoje") %></div>
          <div class="stat-label">Revisadas Hoje</div>
        </div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">🚀</div>
        <div class="stat-text">
          <div class="stat-value"><%= intAttr(request,"totalPublicadasHoje") %></div>
          <div class="stat-label">Publicadas Hoje</div>
        </div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">📅</div>
        <div class="stat-text">
          <div class="stat-value"><%= intAttr(request,"totalAgendadas") %></div>
          <div class="stat-label">Agendadas</div>
        </div>
      </div>
    </div>

    <!-- FILTER TOOLBAR -->
    <section class="sa-filter-panel">
      <div class="sa-filter-heading">🔍 Filtros da fila editorial</div>
      <form class="sa-filter-toolbar sa-filter-toolbar-compact" method="get" action="<%= ctx %>/ReceitaController">
        <div class="sa-field"><label for="busca">Pesquisar</label><input id="busca" name="busca" value="<%= h(busca) %>" placeholder="Título ou autor"></div>
        <div class="sa-field"><label for="categoria">Categoria</label>
          <select id="categoria" name="idCategoria">
            <option value="">Todas</option>
            <% for (Categoria categoria : categorias) { %>
              <option value="<%= categoria.getId_categoria() %>" <%= idCategoria != null && idCategoria == categoria.getId_categoria() ? "selected" : "" %>><%= h(categoria.getNome_categoria()) %></option>
            <% } %>
          </select>
        </div>
        <input type="hidden" name="size" value="<%= size %>">
        <div class="sa-filter-actions">
          <button class="sa-button sa-button-primary" type="submit">Aplicar filtros</button>
          <a class="sa-button" href="<%= ctx %>/ReceitaController">✕ Limpar</a>
        </div>
      </form>
    </section>

    <!-- TABLE -->
    <div class="right-panel">
      <div class="table-card sa-content-card">
        <div class="table-card-head">
          <div class="table-card-title">📝 Receitas em revisão</div>
          <div class="table-card-meta"><%= total %> receita(s) encontrada(s)</div>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead><tr><th>Receita</th><th>Autor</th><th>Categoria</th><th>Enviada em</th><th>Aguardando</th><th>Status</th><th>Ações</th></tr></thead>
            <tbody>
            <% for (Receita receita : receitas) {
                 String nomeAutor = h(receita.getNome_usuario());
                 String inicialAutor = nomeAutor.isEmpty() ? "?" : nomeAutor.substring(0, 1).toUpperCase();
            %>
              <tr>
                <td><strong><%= h(receita.getTitulo_receita()) %></strong></td>
                <td>
                  <div class="author-cell">
                    <div class="author-dot" style="background:var(--moss)"><%= inicialAutor %></div>
                    <div class="author-name"><%= nomeAutor %></div>
                  </div>
                </td>
                <td><%= h(receita.getNome_categoria()) %></td>
                <td><%= h(receita.getData_criacao_receita()) %></td>
                <td><%= h(tempos.get(receita.getId_receita())) %></td>
                <td><span class="pill pendente"><span class="pill-dot"></span>Aguardando aprovação</span></td>
                <td>
                  <div class="row-actions">
                    <a class="row-btn" href="<%= ctx %>/ReceitaController?action=detalhar&amp;idReceita=<%= receita.getId_receita() %>" title="Ver receita">👁</a>
                    <form method="post" action="<%= ctx %>/ReceitaController">
                      <input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>">
                      <input type="hidden" name="action" value="aprovar">
                      <input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>">
                      <button class="row-btn keep" type="submit" title="Aprovar receita">✓</button>
                    </form>
                    <form class="reject-inline" method="post" action="<%= ctx %>/ReceitaController">
                      <input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>">
                      <input type="hidden" name="action" value="rejeitar">
                      <input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>">
                      <input class="reject-input" name="motivo" required maxlength="500" placeholder="Motivo">
                      <button class="row-btn remove" type="submit" title="Rejeitar receita">✕</button>
                    </form>
                  </div>
                </td>
              </tr>
            <% } %>
            <% if (receitas.isEmpty()) { %>
              <tr><td colspan="7"><div class="empty-state"><div class="empty-icon">📭</div><div class="empty-text">Nenhuma receita aguardando revisão</div><div class="empty-sub">Novas submissões vão aparecer aqui automaticamente.</div></div></td></tr>
            <% } %>
            </tbody>
          </table>
        </div>
        <div class="table-footer">
          <div class="footer-info">Exibindo <strong><%= receitas.size() %></strong> de <strong><%= total %></strong> receita(s)</div>
          <div class="pagination">
            <a class="pag-btn" href="<%= ctx %>/ReceitaController?page=<%= Math.max(1, pageAtual - 1) %><%= sufixoQuery %>">‹</a>
            <% for (int p = 1; p <= totalPages; p++) { %>
              <a class="pag-btn <%= p == pageAtual ? "active" : "" %>" href="<%= ctx %>/ReceitaController?page=<%= p %><%= sufixoQuery %>"><%= p %></a>
            <% } %>
            <a class="pag-btn" href="<%= ctx %>/ReceitaController?page=<%= Math.min(totalPages, pageAtual + 1) %><%= sufixoQuery %>">›</a>
          </div>
        </div>
      </div>
    </div>

  </div>
</main>

<script>
function toggleSidebar(){
  document.getElementById('sidebar')?.classList.toggle('open');
  document.getElementById('overlay')?.classList.toggle('open');
}
function closeSidebar(){
  document.getElementById('sidebar')?.classList.remove('open');
  document.getElementById('overlay')?.classList.remove('open');
}
</script>
</body>
</html>
