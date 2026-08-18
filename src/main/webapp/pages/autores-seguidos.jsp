<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="java.util.List" %>

<%--
    SERVLET RESPONSÁVEL: SeguidorController  (GET /SeguidorController?action=listar)
    O servlet faz:
      1. List<Usuario> seguidos = seguidorDAO.listarSeguidos(idUsuarioLogado);
         (com total_receitas_publicadas já preenchido por autor)
      2. request.setAttribute("seguidos", seguidos);
      3. forward pra /pages/autores-seguidos.jsp
--%>
<%
    List<Usuario> seguidos = (List<Usuario>) request.getAttribute("seguidos");
    if (seguidos == null) seguidos = new java.util.ArrayList<>();
    String _ctx = request.getContextPath();

    // Paleta de cores pro avatar quando o autor não tem foto (cicla pelas 6 opções)
    String[] cores = {
        "linear-gradient(135deg,#c4a265,#dfc094);color:#2f3d25",
        "linear-gradient(135deg,#8a6a46,#b0896a);color:white",
        "linear-gradient(135deg,#4a6a7a,#6a8a9a);color:white",
        "linear-gradient(135deg,#4a5e3a,#6b7f59);color:white",
        "linear-gradient(135deg,#8a9480,#a3b18a);color:#2f3d25",
        "linear-gradient(135deg,#b5654a,#d69072);color:white"
    };
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Autores Seguidos</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--error:#9b4444;--error-bg:#fdf0f0;--sidebar-w:260px;
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:'DM Sans',sans-serif; background:var(--cream); color:var(--text-dark); min-height:100vh; display:flex; }

  /* SIDEBAR — estilos vêm do include /pages/includes/sidebar.jsp */

  .main { margin-left:var(--sidebar-w); flex:1; min-height:100vh; display:flex; flex-direction:column; }
  .topbar { background:var(--warm-white); border-bottom:1px solid var(--cream-dark); padding:0 40px; height:56px; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:50; }
  .page-crumb { font-size:12px; color:var(--text-light); display:flex; align-items:center; gap:6px; }
  .page-crumb .current { color:var(--moss); font-weight:500; }
  .topbar-back { display:inline-flex; align-items:center; gap:6px; font-size:12px; color:var(--text-mid); text-decoration:none; font-weight:500; }
  .topbar-back:hover { color:var(--moss); }

  .content { flex:1; padding:28px 40px 40px; }

  .page-header { display:flex; align-items:center; gap:14px; margin-bottom:22px; }
  .page-header-icon { width:46px; height:46px; border-radius:50%; background:linear-gradient(135deg,var(--moss-dark),var(--moss)); display:flex; align-items:center; justify-content:center; font-size:20px; color:white; flex-shrink:0; }
  .page-title { font-family:'Playfair Display',serif; font-size:25px; font-weight:500; color:var(--text-dark); line-height:1.1; }
  .page-title em { font-style:italic; color:var(--moss); }
  .page-subtitle { font-size:12.5px; color:var(--text-light); font-weight:300; margin-top:3px; }

  .followed-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:18px; }
  .followed-card { background:var(--warm-white); border:1px solid var(--cream-dark); border-radius:4px; overflow:hidden; display:flex; flex-direction:column; transition:box-shadow 0.2s,transform 0.2s; }
  .followed-card:hover { box-shadow:0 10px 26px rgba(47,61,37,0.12); transform:translateY(-2px); }

  .fc-head { padding:16px 18px; border-bottom:1px solid var(--cream-dark); display:flex; align-items:center; gap:13px; }
  .fc-avatar { width:50px; height:50px; border-radius:50%; flex-shrink:0; display:flex; align-items:center; justify-content:center; font-family:'Nunito',sans-serif; font-size:18px; font-weight:800; overflow:hidden; }
  .fc-avatar img { width:100%; height:100%; object-fit:cover; }
  .fc-head-info { flex:1; min-width:0; }
  .fc-name { font-family:'Playfair Display',serif; font-size:14.5px; font-weight:700; color:var(--text-dark); line-height:1.25; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .fc-role { font-size:11px; color:var(--text-light); font-weight:300; margin-top:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .fc-unfollow-badge { flex-shrink:0; width:30px; height:30px; border-radius:50%; background:rgba(196,162,101,0.12); border:1px solid rgba(196,162,101,0.35); color:var(--gold); display:flex; align-items:center; justify-content:center; font-size:13px; cursor:pointer; transition:all 0.2s; }
  .fc-unfollow-badge:hover { background:var(--error-bg); border-color:rgba(155,68,68,0.35); color:var(--error); }

  .fc-body { padding:14px 18px 18px; flex:1; display:flex; flex-direction:column; }
  .fc-count { font-size:11.5px; color:var(--moss); font-weight:600; margin-bottom:14px; }

  .fc-actions { margin-top:auto; }
  .fc-btn-primary { display:flex; align-items:center; justify-content:center; gap:6px; background:var(--moss); color:var(--cream); border:none; border-radius:2px; padding:9px 12px; font-family:'DM Sans',sans-serif; font-size:12.5px; font-weight:600; cursor:pointer; text-decoration:none; transition:background 0.2s; }
  .fc-btn-primary:hover { background:var(--moss-dark); }

  .empty-state { display:none; text-align:center; padding:80px 20px; }
  .empty-state.show { display:block; }
  .empty-icon { font-size:52px; margin-bottom:16px; }
  .empty-title { font-family:'Playfair Display',serif; font-size:21px; font-weight:700; color:var(--text-dark); margin-bottom:8px; }
  .empty-text { font-size:14px; color:var(--text-light); font-weight:300; margin-bottom:20px; }
  .empty-cta { display:inline-flex; align-items:center; gap:8px; background:var(--moss); color:var(--cream); border:none; border-radius:2px; padding:10px 22px; font-family:'DM Sans',sans-serif; font-size:13px; font-weight:600; cursor:pointer; text-decoration:none; }
  .empty-cta:hover { background:var(--moss-dark); }

  @media (max-width:1100px) { .followed-grid { grid-template-columns:1fr 1fr; } }
  @media (max-width:768px)  { .main { margin-left:0; } .content { padding:20px; } .topbar { padding:0 20px; } }
  @media (max-width:560px)  { .followed-grid { grid-template-columns:1fr; } }
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Painel</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Autores Seguidos</span>
    </div>
    <a class="topbar-back" href="<%= _ctx %>/pages/perfil-visitante.jsp">← Voltar ao perfil</a>
  </div>

  <div class="content">

    <div class="page-header">
      <div class="page-header-icon">♥</div>
      <div>
        <div class="page-title">Autores que você <em>segue</em></div>
        <div class="page-subtitle" id="pageSubtitle">
          <%= seguidos.size() %> autor<%= seguidos.size() == 1 ? "" : "es" %> seguido<%= seguidos.size() == 1 ? "" : "s" %>
        </div>
      </div>
    </div>

    <div class="followed-grid" id="followedGrid" style="<%= seguidos.isEmpty() ? "display:none;" : "" %>">
      <% for (int i = 0; i < seguidos.size(); i++) {
           Usuario autor = seguidos.get(i);
           String nome = autor.getNome_usuario() != null ? autor.getNome_usuario() : "";
           String cargo = autor.getTitulo_usuario() != null && !autor.getTitulo_usuario().trim().isEmpty()
                          ? autor.getTitulo_usuario() : "Autor";
           String inicial = nome.length() > 0 ? nome.substring(0,1).toUpperCase() : "?";
           String foto = autor.getFoto_usuario();
           String corEstilo = cores[i % cores.length];
      %>
        <div class="followed-card" data-author-id="<%= autor.getId_usuario() %>">
          <div class="fc-head">
            <div class="fc-avatar" style="background:<%= corEstilo %>">
              <% if (foto != null && !foto.trim().isEmpty()) { %>
                <img src="<%= _ctx %><%= foto %>" alt="<%= nome %>">
              <% } else { %>
                <%= inicial %>
              <% } %>
            </div>
            <div class="fc-head-info">
              <div class="fc-name"><%= nome %></div>
              <div class="fc-role"><%= cargo %></div>
            </div>
            <div class="fc-unfollow-badge" onclick="unfollowCard(this, <%= autor.getId_usuario() %>)" title="Deixar de seguir">♥</div>
          </div>
          <div class="fc-body">
            <div class="fc-count">🍽️ <%= autor.getTotal_receitas_publicadas() %> receitas publicadas</div>
            <div class="fc-actions">
              <a class="fc-btn-primary" href="<%= _ctx %>/AutorController?id=<%= autor.getId_usuario() %>">👁 Ver receitas</a>
            </div>
          </div>
        </div>
      <% } %>
    </div>

    <div class="empty-state<%= seguidos.isEmpty() ? " show" : "" %>" id="emptyState">
      <div class="empty-icon">♡</div>
      <div class="empty-title">Você ainda não segue ninguém</div>
      <div class="empty-text">Explore os autores do blog e clique em "Seguir" para acompanhá-los por aqui.</div>
      <a class="empty-cta" href="<%= _ctx %>/pages/autores-visitante.jsp">Explorar autores →</a>
    </div>

  </div>
</main>

<script>
  var CONTEXT_PATH = '<%= _ctx %>';

  function unfollowCard(btn, idSeguido) {
    fetch(CONTEXT_PATH + '/SeguidorController', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: 'action=deixarDeSeguir&idSeguido=' + idSeguido
    })
    .then(function(res) {
      if (res.status === 401) {
        window.location.href = CONTEXT_PATH + '/LoginController';
        throw new Error('não logado');
      }
      return res.text();
    })
    .then(function() {
      var card = btn.closest('.followed-card');
      card.style.transition = 'opacity .2s, transform .2s';
      card.style.opacity = '0';
      card.style.transform = 'scale(.96)';
      setTimeout(function() {
        card.remove();
        atualizarEstado();
      }, 200);
    })
    .catch(function(err) { console.error(err); });
  }

  function atualizarEstado() {
    var total = document.querySelectorAll('#followedGrid .followed-card').length;
    document.getElementById('pageSubtitle').textContent = total + (total === 1 ? ' autor seguido' : ' autores seguidos');
    document.getElementById('followedGrid').style.display = total === 0 ? 'none' : 'grid';
    document.getElementById('emptyState').classList.toggle('show', total === 0);
  }
</script>
</body>
</html>
