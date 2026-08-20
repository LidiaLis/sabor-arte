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
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Fila de Revisão</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--moss:#4a5e3a;--moss-dark:#2f3d25;--sage:#a3b18a;--cream:#f5f0e8;--cream-dark:#e6dece;--white:#faf8f4;--text:#1e2718;--muted:#7c8873;--gold:#c4a265;--orange:#c4832a;--green:#3a7a4a;--red:#9b4444;--sidebar-w:260px}
  *{box-sizing:border-box} body{margin:0;background:var(--cream);color:var(--text);font-family:'DM Sans',sans-serif}
  .main{margin-left:var(--sidebar-w);min-height:100vh}.topbar{height:64px;padding:0 36px;background:var(--white);border-bottom:1px solid var(--cream-dark);display:flex;align-items:center}
  .crumb{font-size:12px;color:var(--muted)}.content{padding:38px 32px 60px;max-width:1500px;margin:auto}
  .title{font:500 31px 'Playfair Display',serif}.title em{color:var(--moss);font-weight:400}.subtitle{font-size:12px;color:var(--muted);margin-top:5px}
  .flash{padding:13px 16px;margin:18px 0;border-radius:4px;font-size:13px}.flash.ok{background:#e8f4eb;color:#286038;border:1px solid #b9d6c0}.flash.error{background:#fdf0f0;color:#843636;border:1px solid #e2bebe}
  .stats{display:grid;grid-template-columns:repeat(4,minmax(150px,1fr));gap:16px;margin:25px 0}
  .stat{background:var(--white);border:1px solid var(--cream-dark);border-top:3px solid var(--moss);padding:17px;display:flex;gap:13px;align-items:center}
  .stat.pending{border-top-color:var(--orange)}.stat.green{border-top-color:var(--green)}.stat.gold{border-top-color:var(--gold)}
  .stat-icon{font-size:21px}.stat-value{font:700 22px 'Playfair Display',serif}.stat-label{font-size:10px;text-transform:uppercase;letter-spacing:.8px;color:var(--muted)}
  .layout{display:grid;grid-template-columns:255px 1fr;gap:18px;align-items:start}
  .panel,.table-card{background:var(--white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden}
  .panel-title,.table-head{padding:15px 17px;border-bottom:1px solid var(--cream-dark);font-size:12px;text-transform:uppercase;letter-spacing:1px}
  .filter{padding:17px;display:grid;gap:14px}.filter label{font-size:10px;text-transform:uppercase;letter-spacing:.8px;color:var(--muted)}
  .input,.select{width:100%;padding:11px 12px;border:1px solid var(--cream-dark);background:#f8f4ed;color:var(--text);font:13px inherit;border-radius:3px}
  .btn{border:1px solid var(--cream-dark);background:var(--white);color:var(--moss-dark);padding:9px 12px;font:600 12px inherit;text-decoration:none;border-radius:3px;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;gap:5px}
  .btn.primary{background:var(--moss);border-color:var(--moss);color:white}.btn.approve{border-color:#a7cbb0;color:#286038}.btn.reject{border-color:#ddb2b2;color:#843636}
  .table-head{display:flex;justify-content:space-between;align-items:center}.count{background:var(--cream-dark);padding:3px 8px;border-radius:10px;font-size:10px}
  .table-scroll{overflow:auto}table{width:100%;border-collapse:collapse;min-width:900px}th{background:#f4eee4;color:var(--muted);font-size:9px;text-transform:uppercase;letter-spacing:.8px;text-align:left;padding:12px}td{padding:13px 12px;border-top:1px solid var(--cream-dark);font-size:12px;vertical-align:top}
  .actions{display:flex;gap:6px;flex-wrap:wrap}.reject-form{display:flex;gap:5px;align-items:center}.reject-form input{width:130px;padding:8px;border:1px solid var(--cream-dark);font:11px inherit}
  .empty{text-align:center;padding:70px 20px;color:var(--muted);font:italic 18px 'Playfair Display',serif}
  .footer{display:flex;justify-content:space-between;align-items:center;padding:14px 17px;border-top:1px solid var(--cream-dark);font-size:11px;color:var(--muted)}
  .pages{display:flex;gap:4px}.page{min-width:30px;padding:7px;border:1px solid var(--cream-dark);text-align:center;text-decoration:none;color:var(--moss);font-size:11px}.page.active{background:var(--moss);color:white}
  @media(max-width:1000px){.main{margin-left:0}.layout{grid-template-columns:1fr}.stats{grid-template-columns:repeat(2,1fr)}}@media(max-width:580px){.content{padding:24px 14px}.stats{grid-template-columns:1fr}}
</style>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/conteudo-design-system.css">
</head>
<body>
<% request.setAttribute("currentPage", "receitas"); %>
<jsp:include page="/pages/includes/sidebar.jsp" />
<main class="main">
  <header class="topbar"><div class="crumb">Principal &nbsp;/&nbsp; Revisão editorial</div></header>
  <div class="content">
    <div class="title">Fila de <em>Revisão</em></div>
    <div class="subtitle"><%= h(request.getAttribute("dataPainel")) %> · somente receitas aguardando aprovação</div>

    <% if (request.getAttribute("sucesso") != null) { %><div class="flash ok"><%= h(request.getAttribute("sucesso")) %></div><% } %>
    <% if (request.getAttribute("erro") != null) { %><div class="flash error"><%= h(request.getAttribute("erro")) %></div><% } %>

    <section class="stats">
      <div class="stat pending"><div class="stat-icon">📝</div><div><div class="stat-value sa-stat-number"><%= intAttr(request,"totalAguardando") %></div><div class="stat-label">Aguardando revisão</div></div></div>
      <div class="stat"><div class="stat-icon">✅</div><div><div class="stat-value sa-stat-number"><%= intAttr(request,"totalRevisadasHoje") %></div><div class="stat-label">Revisadas hoje</div></div></div>
      <div class="stat green"><div class="stat-icon">🚀</div><div><div class="stat-value sa-stat-number"><%= intAttr(request,"totalPublicadasHoje") %></div><div class="stat-label">Publicadas hoje</div></div></div>
      <div class="stat gold"><div class="stat-icon">📅</div><div><div class="stat-value sa-stat-number"><%= intAttr(request,"totalAgendadas") %></div><div class="stat-label">Agendadas</div></div></div>
    </section>

    <section class="sa-filter-panel">
        <div class="sa-filter-heading">🔍 Filtros da fila editorial</div>
        <form class="sa-filter-toolbar sa-filter-toolbar-compact" method="get" action="<%= ctx %>/ReceitaController">
          <div class="sa-field"><label for="busca">Pesquisar</label><input id="busca" name="busca" value="<%= h(busca) %>" placeholder="Título ou autor"></div>
          <div class="sa-field"><label for="categoria">Categoria</label><select id="categoria" name="idCategoria"><option value="">Todas</option><% for(Categoria categoria:categorias){ %><option value="<%= categoria.getId_categoria() %>" <%= idCategoria != null && idCategoria == categoria.getId_categoria() ? "selected" : "" %>><%= h(categoria.getNome_categoria()) %></option><% } %></select></div>
          <input type="hidden" name="size" value="<%= size %>">
          <div class="sa-filter-actions"><button class="sa-button sa-button-primary" type="submit">Aplicar filtros</button><a class="sa-button" href="<%= ctx %>/ReceitaController">✕ Limpar</a></div>
        </form>
    </section>

      <section class="table-card sa-content-card">
        <div class="table-head"><span>Receitas em revisão</span><span class="count"><%= total %></span></div>
        <div class="table-scroll">
          <table>
            <thead><tr><th>Receita</th><th>Autor</th><th>Categoria</th><th>Enviada em</th><th>Aguardando</th><th>Status</th><th>Ações</th></tr></thead>
            <tbody>
            <% for (Receita receita : receitas) { %>
              <tr>
                <td><strong><%= h(receita.getTitulo_receita()) %></strong></td>
                <td><%= h(receita.getNome_usuario()) %></td>
                <td><%= h(receita.getNome_categoria()) %></td>
                <td><%= h(receita.getData_criacao_receita()) %></td>
                <td><%= h(tempos.get(receita.getId_receita())) %></td>
                <td><span class="sa-status-pill sa-status-pending">Aguardando aprovação</span></td>
                <td><div class="actions">
                  <a class="btn" href="<%= ctx %>/ReceitaController?action=detalhar&amp;idReceita=<%= receita.getId_receita() %>">👁 Ver</a>
                  <form method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="aprovar"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><button class="btn approve" type="submit">✓ Aprovar</button></form>
                  <form class="reject-form" method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="rejeitar"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><input name="motivo" required maxlength="500" placeholder="Motivo"><button class="btn reject" type="submit">✕ Rejeitar</button></form>
                </div></td>
              </tr>
            <% } %>
            <% if (receitas.isEmpty()) { %><tr><td colspan="7"><div class="empty">📭 Nenhuma receita aguardando revisão</div></td></tr><% } %>
            </tbody>
          </table>
        </div>
        <footer class="footer">
          <span>Exibindo <%= receitas.size() %> de <%= total %> receita(s)</span>
          <nav class="pages"><% for(int p=1;p<=totalPages;p++){ %><a class="page <%= p==pageAtual ? "active" : "" %>" href="<%= ctx %>/ReceitaController?page=<%= p %>&amp;size=<%= size %>&amp;busca=<%= buscaUrl %><%= idCategoria == null ? "" : "&amp;idCategoria=" + idCategoria %>"><%= p %></a><% } %></nav>
        </footer>
      </section>
  </div>
</main>
</body>
</html>
