<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%@ page import="br.com.saborearte.model.Comentario" %>
<%!
private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
}
%>
<%
String contextPath = request.getContextPath();
request.setAttribute("currentPage", "mensagens");
List<Comentario> comentarios = (List<Comentario>) request.getAttribute("comentarios");
if (comentarios == null) comentarios = Collections.emptyList();
String busca = request.getAttribute("busca") == null ? "" : String.valueOf(request.getAttribute("busca"));
String statusResposta = request.getAttribute("statusResposta") == null ? "todos" : String.valueOf(request.getAttribute("statusResposta"));
int pageAtual = request.getAttribute("page") instanceof Number ? ((Number) request.getAttribute("page")).intValue() : 1;
int totalPages = request.getAttribute("totalPages") instanceof Number ? ((Number) request.getAttribute("totalPages")).intValue() : 1;
int totalRecebidos = request.getAttribute("totalRecebidos") instanceof Number ? ((Number) request.getAttribute("totalRecebidos")).intValue() : 0;
int totalPendentes = request.getAttribute("totalPendentesResposta") instanceof Number ? ((Number) request.getAttribute("totalPendentesResposta")).intValue() : 0;
int totalRespondidos = request.getAttribute("totalRespondidos") instanceof Number ? ((Number) request.getAttribute("totalRespondidos")).intValue() : 0;
double avaliacaoMedia = request.getAttribute("avaliacaoMedia") instanceof Number ? ((Number) request.getAttribute("avaliacaoMedia")).doubleValue() : 0;
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Comentários Recebidos</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&amp;family=Nunito:wght@700;800&amp;family=Playfair+Display:ital,wght@0,600;1,600&amp;display=swap" rel="stylesheet">
<style>
:root{--moss:#4a5e3a;--moss-dark:#34452a;--sage:#a3b18a;--cream:#f3efe6;--cream-dark:#e5dccb;--warm:#fffdf8;--text:#293022;--mid:#596052;--light:#899080;--gold:#c4a265;--danger:#a64b47;--success:#3a7a4a}
*{box-sizing:border-box}body{margin:0;background:var(--cream);color:var(--text);font-family:'DM Sans',sans-serif}.page-shell{margin-left:240px;min-height:100vh}.content{max-width:1180px;margin:auto;padding:34px}.breadcrumb{font-size:12px;color:var(--light);margin-bottom:20px}.breadcrumb span{color:var(--moss)}.title{font:600 30px 'Playfair Display',serif}.title em{color:var(--moss)}.subtitle{color:var(--light);font-size:13px;margin-top:5px}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin:26px 0}.stat{background:var(--warm);border:1px solid var(--cream-dark);border-top:3px solid var(--sage);padding:15px 18px;display:flex;gap:12px;align-items:center}.stat:nth-child(2){border-top-color:#d08b35}.stat:nth-child(3){border-top-color:var(--success)}.stat:nth-child(4){border-top-color:var(--gold)}.stat-icon{font-size:20px}.stat-value{font:800 24px Nunito,sans-serif}.stat-label{text-transform:uppercase;color:var(--light);font-size:10px;letter-spacing:.7px}.toolbar{display:flex;justify-content:space-between;gap:15px;align-items:center;margin-bottom:20px}.search{display:flex;flex:1;max-width:520px}.search input{width:100%;padding:11px 13px;border:1px solid var(--cream-dark);background:var(--warm);font:inherit}.search button,.pill,.button{border:1px solid var(--cream-dark);background:var(--warm);padding:10px 15px;cursor:pointer;font:500 12px 'DM Sans',sans-serif}.search button{background:var(--moss);color:white;border-color:var(--moss)}.filters{display:flex;gap:7px}.pill{border-radius:20px;text-decoration:none;color:var(--mid)}.pill.active{background:var(--moss);border-color:var(--moss);color:white}.alert{padding:12px 15px;margin-bottom:15px;border:1px solid}.alert.success{background:#edf7ef;border-color:#b8d6be;color:#285c35}.alert.error{background:#fff0ef;border-color:#e2b6b3;color:#843c38}.list{display:grid;gap:13px}.card{background:var(--warm);border:1px solid var(--cream-dark);padding:18px}.card-top{display:flex;justify-content:space-between;gap:16px}.person{display:flex;gap:11px;align-items:center}.avatar{width:42px;height:42px;border-radius:50%;object-fit:cover;background:#e9e3d6;display:flex;align-items:center;justify-content:center;font-weight:700;color:var(--moss)}.name{font-weight:600}.meta,.recipe{font-size:12px;color:var(--light)}.recipe{color:var(--moss);margin-top:2px}.stars{color:var(--gold);letter-spacing:1px}.comment{line-height:1.65;margin:15px 0;color:var(--mid)}.reply{background:#f1f4ec;border-left:3px solid var(--sage);padding:12px 14px;margin:12px 0}.reply-label{font-size:10px;text-transform:uppercase;letter-spacing:.7px;color:var(--moss);font-weight:600;margin-bottom:5px}.actions{display:flex;gap:8px;justify-content:flex-end;align-items:center}.analise-badge{font-size:11px;color:var(--mid);border:1px dashed var(--gold);background:#faf3e6;padding:8px 12px;border-radius:2px;margin-right:auto}.button.primary{background:var(--moss);border-color:var(--moss);color:white}.button.danger{color:var(--danger);border-color:#dfb8b5}.empty{background:var(--warm);border:1px dashed var(--cream-dark);padding:55px;text-align:center;color:var(--light)}.pagination{display:flex;justify-content:center;align-items:center;gap:5px;margin-top:22px}.pagination a,.pagination span{min-width:36px;padding:9px;text-align:center;border:1px solid var(--cream-dark);background:var(--warm);text-decoration:none;color:var(--mid)}.pagination .active{background:var(--moss);color:white}.modal{position:fixed;inset:0;background:rgba(27,34,23,.55);display:none;align-items:center;justify-content:center;padding:20px;z-index:500}.modal.open{display:flex}.modal-box{width:min(500px,100%);background:var(--warm);border:1px solid var(--cream-dark)}.modal-head,.modal-foot{padding:16px 20px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid var(--cream-dark)}.modal-foot{border-top:1px solid var(--cream-dark);border-bottom:0;justify-content:flex-end;gap:9px}.modal-body{padding:20px}.modal-title{font:600 18px 'Playfair Display',serif}.close{border:0;background:transparent;font-size:20px;cursor:pointer}.modal textarea{width:100%;min-height:130px;padding:12px;border:1px solid var(--cream-dark);font:inherit;resize:vertical}.context-comment{background:var(--cream);padding:10px;margin-bottom:13px;color:var(--mid);font-size:13px}.hide{display:none}@media(max-width:900px){.page-shell{margin-left:0}.content{padding:22px}.stats{grid-template-columns:repeat(2,1fr)}.toolbar{align-items:stretch;flex-direction:column}.filters{overflow:auto}}@media(max-width:520px){.stats{grid-template-columns:1fr}.card-top{flex-direction:column}.actions{justify-content:flex-start;flex-wrap:wrap}}
</style>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/conteudo-design-system.css">
</head>
<body>
<jsp:include page="/pages/includes/sidebar.jsp" />
<main class="page-shell"><div class="content">
  <div class="breadcrumb">Painel do Autor / <span>Comentários Recebidos</span></div>
  <div class="title">Comentários <em>Recebidos</em> 💬</div>
  <div class="subtitle">Comentários da comunidade nas suas receitas — responda diretamente por aqui</div>

  <% if (request.getAttribute("sucesso") != null) { %><div class="alert success"><%= h(request.getAttribute("sucesso")) %></div><% } %>
  <% if (request.getAttribute("erro") != null) { %><div class="alert error"><%= h(request.getAttribute("erro")) %></div><% } %>

  <section class="stats">
<div class="stat"><div class="stat-icon">💬</div><div><div class="stat-value sa-stat-number"><%= totalRecebidos %></div><div class="stat-label">Recebidos</div></div></div>
<div class="stat"><div class="stat-icon">⏳</div><div><div class="stat-value sa-stat-number"><%= totalPendentes %></div><div class="stat-label">Não respondidos</div></div></div>
<div class="stat"><div class="stat-icon">✅</div><div><div class="stat-value sa-stat-number"><%= totalRespondidos %></div><div class="stat-label">Respondidos</div></div></div>
<div class="stat"><div class="stat-icon">⭐</div><div><div class="stat-value sa-stat-number"><%= String.format(java.util.Locale.US, "%.1f", avaliacaoMedia) %></div><div class="stat-label">Avaliação média</div></div></div>
  </section>

  <div class="toolbar">
    <form class="search" method="get" action="<%= contextPath %>/ComentarioController?view=mensagens">
      <input type="hidden" name="view" value="mensagens">
      <input type="hidden" name="statusResposta" value="<%= h(statusResposta) %>">
      <input type="search" name="busca" value="<%= h(busca) %>" placeholder="Buscar por receita, usuário ou comentário…">
      <button type="submit">Buscar</button>
    </form>
    <nav class="filters" aria-label="Filtrar mensagens">
      <a class="pill <%= "todos".equals(statusResposta) ? "active" : "" %>" href="<%= contextPath %>/ComentarioController?view=mensagens&amp;statusResposta=todos&amp;busca=<%= java.net.URLEncoder.encode(busca, "UTF-8") %>">Todos</a>
      <a class="pill <%= "pendente".equals(statusResposta) ? "active" : "" %>" href="<%= contextPath %>/ComentarioController?view=mensagens&amp;statusResposta=pendente&amp;busca=<%= java.net.URLEncoder.encode(busca, "UTF-8") %>">Não respondidos</a>
      <a class="pill <%= "respondido".equals(statusResposta) ? "active" : "" %>" href="<%= contextPath %>/ComentarioController?view=mensagens&amp;statusResposta=respondido&amp;busca=<%= java.net.URLEncoder.encode(busca, "UTF-8") %>">Respondidos</a>
    </nav>
  </div>

  <section class="list">
  <% if (comentarios.isEmpty()) { %>
    <div class="empty">Nenhum comentário encontrado para este filtro.</div>
  <% } else { for (Comentario comentario : comentarios) {
       boolean respondido = comentario.getResposta_comentario() != null && !comentario.getResposta_comentario().trim().isEmpty();
       boolean emAnalise = comentario.getStatus_comentario() != null && "PENDENTE".equals(comentario.getStatus_comentario().name());
       String inicial = comentario.getNome_usuario() == null || comentario.getNome_usuario().isEmpty() ? "?" : comentario.getNome_usuario().substring(0, 1).toUpperCase();
  %>
<article class="card sa-content-card">
      <div class="card-top">
        <div class="person">
          <% if (comentario.getFoto_usuario() != null && !comentario.getFoto_usuario().isBlank()) { %>
            <img class="avatar" src="<%= h(comentario.getFoto_usuario()) %>" alt="">
          <% } else { %><div class="avatar"><%= h(inicial) %></div><% } %>
          <div><div class="name"><%= h(comentario.getNome_usuario()) %></div><div class="recipe">em “<%= h(comentario.getTitulo_receita()) %>”</div><div class="meta"><%= h(comentario.getData_criacao_comentario()) %></div></div>
        </div>
        <div class="stars" aria-label="<%= comentario.getAvaliacao_comentario() %> de 5 estrelas"><% for (int i=1;i<=5;i++) { %><%= i <= comentario.getAvaliacao_comentario() ? "★" : "☆" %><% } %></div>
      </div>
      <div class="comment"><%= h(comentario.getTexto_comentario()) %></div>
      <% if (respondido) { %><div class="reply"><div class="reply-label">Sua resposta</div><div><%= h(comentario.getResposta_comentario()) %></div></div><% } %>
      <div class="actions">
        <% if (emAnalise) { %><span class="analise-badge">🕓 Em análise pela moderação</span><% } %>
<button type="button" class="button primary sa-button sa-button-primary js-reply" data-id="<%= comentario.getId_comentario() %>" data-comment="<%= h(comentario.getTexto_comentario()) %>" data-reply="<%= h(comentario.getResposta_comentario()) %>"><%= respondido ? "↩ Editar resposta" : "↩ Responder" %></button>
        <% if (!emAnalise) { %><button type="button" class="button danger sa-button sa-button-danger js-report" data-id="<%= comentario.getId_comentario() %>" data-user="<%= h(comentario.getNome_usuario()) %>">🚩 Denunciar</button><% } %>
      </div>
    </article>
  <% }} %>
  </section>

  <% if (totalPages > 1) { %><nav class="pagination" aria-label="Paginação">
    <% if (pageAtual > 1) { %><a href="<%= contextPath %>/ComentarioController?view=mensagens&amp;page=<%= pageAtual-1 %>&amp;statusResposta=<%= h(statusResposta) %>&amp;busca=<%= java.net.URLEncoder.encode(busca,"UTF-8") %>">←</a><% } %>
    <% for (int p=1;p<=totalPages;p++) { if (p==pageAtual) { %><span class="active"><%= p %></span><% } else { %><a href="<%= contextPath %>/ComentarioController?view=mensagens&amp;page=<%= p %>&amp;statusResposta=<%= h(statusResposta) %>&amp;busca=<%= java.net.URLEncoder.encode(busca,"UTF-8") %>"><%= p %></a><% }} %>
    <% if (pageAtual < totalPages) { %><a href="<%= contextPath %>/ComentarioController?view=mensagens&amp;page=<%= pageAtual+1 %>&amp;statusResposta=<%= h(statusResposta) %>&amp;busca=<%= java.net.URLEncoder.encode(busca,"UTF-8") %>">→</a><% } %>
  </nav><% } %>
</div></main>

<div class="modal" id="replyModal" aria-hidden="true"><div class="modal-box">
  <div class="modal-head"><div class="modal-title">Responder comentário</div><button type="button" class="close js-close">×</button></div>
  <form method="post" action="<%= contextPath %>/ComentarioController?view=mensagens">
    <input type="hidden" name="action" value="responder"><input type="hidden" name="idComentario" id="replyId">
    <div class="modal-body"><div class="context-comment" id="replyContext"></div><label for="replyText">Sua resposta será exibida publicamente</label><textarea id="replyText" name="resposta" required maxlength="2000"></textarea></div>
    <div class="modal-foot"><button type="button" class="button js-close">Cancelar</button><button type="submit" class="button primary">Publicar resposta</button></div>
  </form>
</div></div>

<div class="modal" id="reportModal" aria-hidden="true"><div class="modal-box">
  <div class="modal-head"><div class="modal-title">🚩 Denunciar comentário</div><button type="button" class="close js-close">×</button></div>
  <form method="post" action="<%= contextPath %>/ComentarioController?view=mensagens">
    <input type="hidden" name="action" value="denunciar"><input type="hidden" name="idComentario" id="reportId">
    <div class="modal-body">Enviar o comentário de <strong id="reportUser"></strong> para análise da moderação?</div>
    <div class="modal-foot"><button type="button" class="button js-close">Cancelar</button><button type="submit" class="button danger">Confirmar denúncia</button></div>
  </form>
</div></div>

<script>
(function(){
  var replyModal=document.getElementById('replyModal'), reportModal=document.getElementById('reportModal');
  function openModal(modal){modal.classList.add('open');modal.setAttribute('aria-hidden','false');}
  function closeModal(modal){modal.classList.remove('open');modal.setAttribute('aria-hidden','true');}
  document.querySelectorAll('.js-reply').forEach(function(button){button.addEventListener('click',function(){document.getElementById('replyId').value=button.dataset.id;document.getElementById('replyContext').textContent=button.dataset.comment;document.getElementById('replyText').value=button.dataset.reply||'';openModal(replyModal);});});
  document.querySelectorAll('.js-report').forEach(function(button){button.addEventListener('click',function(){document.getElementById('reportId').value=button.dataset.id;document.getElementById('reportUser').textContent=button.dataset.user;openModal(reportModal);});});
  document.querySelectorAll('.js-close').forEach(function(button){button.addEventListener('click',function(){closeModal(button.closest('.modal'));});});
  [replyModal,reportModal].forEach(function(modal){modal.addEventListener('click',function(event){if(event.target===modal)closeModal(modal);});});
})();
</script>
</body></html>
