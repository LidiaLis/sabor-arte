<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Map" %>

<%--
    SERVLET RESPONSÁVEL: FavoritoController  (GET /FavoritoController, sem parâmetros)
    O servlet faz:
      1. List<Receita> favoritas = favoritoDAO.listarReceitasFavoritasDetalhado(idUsuarioLogado, null);
      2. request.setAttribute("receitasFavoritas", favoritas);
      3. (opcional) request.setAttribute("sucesso"/"erro", ...) vindo da session
      4. forward pra /pages/receitas-favoritas.jsp
--%>
<%
    List<Receita> favoritas = (List<Receita>) request.getAttribute("receitasFavoritas");
    if (favoritas == null) favoritas = new java.util.ArrayList<>();

    String sucesso = (String) request.getAttribute("sucesso");
    String erro    = (String) request.getAttribute("erro");

    String _ctx = request.getContextPath();

    // Categorias distintas presentes nos favoritos, pra popular o <select> de filtro
    Map<String, String> categorias = new LinkedHashMap<>(); // nome -> emoji
    for (Receita r : favoritas) {
        if (r.getNome_categoria() != null && !categorias.containsKey(r.getNome_categoria())) {
            categorias.put(r.getNome_categoria(), r.getEmoji_categoria());
        }
    }

    // Paleta cíclica pra bolinha do autor quando quisermos cor fixa por posição
    String[] coresAutor = { "#4a5e3a,#6b7f59", "#c46042,#e08060", "#a05a3a,#c07a5a", "#6a9a5a,#8aba7a", "#8a6a46,#b0896a", "#4a6a7a,#6a8a9a" };
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Receitas Favoritas</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;--sidebar-w:260px;
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:'DM Sans',sans-serif; background:var(--cream); color:var(--text-dark); min-height:100vh; display:flex; overflow-x:hidden; }

  /* SIDEBAR — estilos vêm do include /pages/includes/sidebar.jsp */

  .main { margin-left:var(--sidebar-w); flex:1; min-height:100vh; display:flex; flex-direction:column; }
  .topbar { background:var(--warm-white); border-bottom:1px solid var(--cream-dark); padding:0 40px; height:64px; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:50; }
  .page-crumb { font-size:12px; color:var(--text-light); display:flex; align-items:center; gap:6px; font-weight:300; }
  .page-crumb .current { color:var(--moss); font-weight:500; }

  .content { flex:1; padding:24px 40px; }

  .section-header { display:flex; align-items:flex-end; justify-content:space-between; margin-bottom:4px; }
  .section-title { font-family:'Playfair Display',serif; font-size:26px; font-weight:500; color:var(--text-dark); line-height:1; }
  .section-title em { font-style:italic; color:var(--moss); }
  .section-sub { font-size:12px; color:var(--text-light); font-weight:300; margin-bottom:16px; }

  .alert { padding:10px 16px; border-radius:3px; font-size:13px; margin-bottom:16px; }
  .alert-sucesso { background:#e8f4eb; color:#3a7a4a; border:1px solid rgba(58,122,74,0.25); }
  .alert-erro { background:#fdf0f0; color:#9b4444; border:1px solid rgba(155,68,68,0.25); }

  .toolbar { display:flex; align-items:center; gap:12px; margin-bottom:14px; flex-wrap:wrap; }
  .search-bar { display:flex; align-items:center; gap:8px; background:var(--warm-white); border:1.5px solid var(--cream-dark); border-radius:2px; padding:8px 14px; flex:1; max-width:320px; }
  .search-bar:focus-within { border-color:var(--moss-light); }
  .search-bar input { border:none; background:none; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); outline:none; flex:1; }
  .filter-select { background:var(--warm-white); border:1.5px solid var(--cream-dark); border-radius:2px; padding:8px 12px; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); cursor:pointer; outline:none; }
  .toolbar-spacer { flex:1; }

  .recipes-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; align-items:start; }

  .recipe-card { background:var(--warm-white); border:1px solid var(--cream-dark); border-radius:6px; overflow:hidden; transition:transform 0.25s,box-shadow 0.25s,opacity 0.25s; }
  .recipe-card:hover { transform:translateY(-5px); box-shadow:0 20px 48px rgba(47,61,37,0.16); }
  .recipe-card.removendo { opacity:0; transform:scale(0.96); }

  .recipe-img-wrap { position:relative; overflow:hidden; height:118px; }
  .recipe-img-wrap img { width:100%; height:100%; object-fit:cover; display:block; background:var(--cream-dark); }
  .fav-badge { position:absolute; top:8px; right:8px; width:26px; height:26px; border-radius:50%; background:rgba(30,39,24,0.55); display:flex; align-items:center; justify-content:center; font-size:13px; color:var(--gold-light); }

  .recipe-body { padding:12px 16px 10px; }
  .recipe-cat { font-size:10px; text-transform:uppercase; letter-spacing:1px; color:var(--moss-light); font-weight:600; margin-bottom:4px; }
  .recipe-name { font-family:'Playfair Display',serif; font-size:14px; font-weight:700; color:var(--text-dark); line-height:1.3; margin-bottom:8px; }

  .recipe-author { display:flex; align-items:center; gap:7px; }
  .author-dot { width:22px; height:22px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-family:'Nunito',sans-serif; font-size:9px; font-weight:800; color:white; flex-shrink:0; overflow:hidden; }
  .author-dot img { width:100%; height:100%; object-fit:cover; }
  .author-name { font-size:12px; color:var(--text-mid); font-weight:400; }

  .recipe-footer { display:flex; align-items:center; gap:6px; justify-content:flex-end; padding:10px 16px; border-top:1px solid var(--cream-dark); background:var(--cream); }
  .footer-btn { padding:6px 12px; border:1.5px solid var(--cream-dark); background:var(--warm-white); border-radius:2px; font-family:'DM Sans',sans-serif; font-size:11px; font-weight:500; color:var(--text-mid); cursor:pointer; transition:all 0.15s; display:flex; align-items:center; justify-content:center; gap:4px; white-space:nowrap; text-decoration:none; }
  .footer-btn:hover { border-color:var(--moss); color:var(--moss); background:rgba(74,94,58,0.05); }
  .footer-btn.toggle-desfavoritar { border-color:var(--gold); color:var(--gold); background:var(--gold-pale); }
  .footer-btn.toggle-desfavoritar:hover { border-color:#9b4444; color:#9b4444; background:rgba(155,68,68,0.06); }

  .empty-state { grid-column:1 / -1; text-align:center; padding:60px 20px; color:var(--text-light); }
  .empty-state .empty-icon { font-size:44px; margin-bottom:14px; }
  .empty-state h3 { font-family:'Playfair Display',serif; font-size:18px; color:var(--text-dark); margin-bottom:6px; }
  .empty-state p { font-size:13px; font-weight:300; }

  .pagination { display:flex; align-items:center; justify-content:space-between; padding:10px 4px 4px; margin-top:4px; }
  .pag-info { font-size:12px; color:var(--text-light); font-weight:300; }
  .pag-btns { display:flex; gap:4px; }
  .pag-btn { min-width:32px; height:32px; padding:0 8px; border:1.5px solid var(--cream-dark); background:var(--warm-white); border-radius:2px; display:flex; align-items:center; justify-content:center; font-size:12px; cursor:pointer; color:var(--text-mid); font-family:'Nunito',sans-serif; font-weight:700; transition:all 0.15s; }
  .pag-btn:hover:not(:disabled) { border-color:var(--moss); color:var(--moss); }
  .pag-btn.active { background:var(--moss); border-color:var(--moss); color:var(--cream); }
  .pag-btn:disabled { opacity:.4; cursor:not-allowed; }

  @media (max-width:1100px) { .recipes-grid { grid-template-columns:repeat(2,1fr); } }
  @media (max-width:768px)  { .main { margin-left:0; } .content { padding:24px 20px; } .topbar { padding:0 20px; } .pagination { flex-direction:column; gap:10px; align-items:flex-start; } }
  @media (max-width:580px)  { .recipes-grid { grid-template-columns:1fr; } }
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Minha Conta</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Favoritas</span>
    </div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Receitas <em>Favoritas</em></div>
      </div>
    </div>
    <div class="section-sub">As receitas que você salvou para acessar mais rápido</div>

    <% if (sucesso != null) { %><div class="alert alert-sucesso"><%= sucesso %></div><% } %>
    <% if (erro != null) { %><div class="alert alert-erro"><%= erro %></div><% } %>

    <div class="toolbar">
      <div class="search-bar">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" id="campoBusca" placeholder="Buscar nos favoritos…">
      </div>
      <select class="filter-select" id="filterCategoria">
        <option value="" selected>Todas as categorias</option>
        <% for (String catNome : categorias.keySet()) { %>
          <option value="<%= catNome %>"><%= categorias.get(catNome) != null ? categorias.get(catNome) + " " : "" %><%= catNome %></option>
        <% } %>
      </select>
      <div class="toolbar-spacer"></div>
    </div>

    <div class="recipes-grid" id="recipesGrid">
      <% if (favoritas.isEmpty()) { %>
        <div class="empty-state" id="emptyStateServidor">
          <div class="empty-icon">⭐</div>
          <h3>Nenhum favorito ainda</h3>
          <p>Explore as receitas do blog e clique em "★ Favoritar" para salvá-las aqui.</p>
        </div>
      <% } else {
           for (int i = 0; i < favoritas.size(); i++) {
             Receita r = favoritas.get(i);
             String img = r.getImagem_receita();
             String imgSrc = (img != null && !img.trim().isEmpty()) ? _ctx + img : "https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=600&q=80";
             String catNome = r.getNome_categoria() != null ? r.getNome_categoria() : "";
             String catEmoji = r.getEmoji_categoria() != null ? r.getEmoji_categoria() : "";
             String autorNome = r.getNome_usuario() != null ? r.getNome_usuario() : "";
             String autorFoto = r.getFoto_usuario();
             String iniciais = "";
             for (String parte : autorNome.trim().split("\\s+")) {
                 if (!parte.isEmpty() && iniciais.length() < 2) iniciais += parte.substring(0,1).toUpperCase();
             }
             String corAutor = coresAutor[i % coresAutor.length];
      %>
        <div class="recipe-card" data-id="<%= r.getId_receita() %>"
             data-name="<%= r.getTitulo_receita() != null ? r.getTitulo_receita().toLowerCase() : "" %>"
             data-cat="<%= catNome %>">
          <div class="recipe-img-wrap">
            <img src="<%= imgSrc %>" alt="<%= r.getTitulo_receita() %>">
            <span class="fav-badge">★</span>
          </div>
          <div class="recipe-body">
            <div class="recipe-cat"><%= catEmoji %> <%= catNome %></div>
            <div class="recipe-name"><%= r.getTitulo_receita() %></div>
            <div class="recipe-author">
              <div class="author-dot" style="background:linear-gradient(135deg,<%= corAutor %>)">
                <% if (autorFoto != null && !autorFoto.trim().isEmpty()) { %>
                  <img src="<%= _ctx %><%= autorFoto %>" alt="<%= autorNome %>">
                <% } else { %>
                  <%= iniciais %>
                <% } %>
              </div>
              <span class="author-name"><%= autorNome %></span>
            </div>
          </div>
          <div class="recipe-footer">
            <a class="footer-btn" href="<%= _ctx %>/pages/receita-detalhe-publico.jsp?id=<%= r.getId_receita() %>">👁 Ver</a>
            <button class="footer-btn toggle-desfavoritar" onclick="desfavoritar(this, <%= r.getId_receita() %>)">★ Desfavoritar</button>
          </div>
        </div>
      <% } } %>

      <div class="empty-state" id="emptyState" style="display:none;">
        <div class="empty-icon">⭐</div>
        <h3>Nenhum favorito encontrado</h3>
        <p>Você ainda não favoritou nenhuma receita, ou nenhuma bate com o filtro atual.</p>
      </div>

    </div>

    <div class="pagination" id="pagination">
      <div class="pag-info" id="pagInfo">—</div>
      <div class="pag-btns" id="pagBtns"></div>
    </div>

  </div>
</main>

<script>
(function() {
  var CONTEXT_PATH = '<%= _ctx %>';
  var PAGE_SIZE = 6;
  var paginaAtual = 1;
  var todosCards = Array.from(document.querySelectorAll('#recipesGrid .recipe-card'));

  function getCardsFiltrados() {
    var termo = document.getElementById('campoBusca').value.trim().toLowerCase();
    var categoria = document.getElementById('filterCategoria').value;

    return todosCards.filter(function(card) {
      if (card.dataset.removido === 'true') return false;
      var nome = card.dataset.name;
      var bateNome = nome.indexOf(termo) !== -1;
      var bateCategoria = categoria === '' || card.dataset.cat === categoria;
      return bateNome && bateCategoria;
    });
  }

  function renderPagina() {
    var filtrados = getCardsFiltrados();
    var totalPaginas = Math.max(1, Math.ceil(filtrados.length / PAGE_SIZE));

    if (paginaAtual > totalPaginas) paginaAtual = totalPaginas;
    if (paginaAtual < 1) paginaAtual = 1;

    todosCards.forEach(function(card) { card.style.display = 'none'; });

    var inicio = (paginaAtual - 1) * PAGE_SIZE;
    var fim = inicio + PAGE_SIZE;
    filtrados.slice(inicio, fim).forEach(function(card) { card.style.display = ''; });

    var empty = document.getElementById('emptyState');
    if (empty) empty.style.display = (todosCards.length > 0 && filtrados.length === 0) ? '' : 'none';

    renderInfo(filtrados.length, inicio, fim);
    renderBotoes(totalPaginas);
  }

  function renderInfo(total, inicio, fim) {
    var info = document.getElementById('pagInfo');
    if (!info) return;
    if (total === 0) {
      info.textContent = todosCards.length === 0 ? '—' : 'Nenhuma receita encontrada';
      return;
    }
    var mostrandoAte = Math.min(fim, total);
    info.textContent = 'Mostrando ' + (inicio + 1) + '–' + mostrandoAte + ' de ' + total;
  }

  function renderBotoes(totalPaginas) {
    var wrap = document.getElementById('pagBtns');
    if (!wrap) return;
    wrap.innerHTML = '';

    function criarBtn(label, page, opts) {
      opts = opts || {};
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'pag-btn' + (opts.active ? ' active' : '');
      b.textContent = label;
      if (opts.disabled) b.disabled = true;
      b.addEventListener('click', function() {
        paginaAtual = page;
        renderPagina();
      });
      wrap.appendChild(b);
    }

    if (todosCards.length === 0) return;

    criarBtn('‹', paginaAtual - 1, { disabled: paginaAtual === 1 });
    for (var p = 1; p <= totalPaginas; p++) {
      criarBtn(String(p), p, { active: p === paginaAtual });
    }
    criarBtn('›', paginaAtual + 1, { disabled: paginaAtual === totalPaginas });
  }

  document.getElementById('campoBusca').addEventListener('input', function() {
    paginaAtual = 1;
    renderPagina();
  });
  document.getElementById('filterCategoria').addEventListener('change', function() {
    paginaAtual = 1;
    renderPagina();
  });

  // ── Desfavoritar: AJAX de verdade pro FavoritoController ──
  window.desfavoritar = function(btn, idReceita) {
    fetch(CONTEXT_PATH + '/FavoritoController', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: 'action=desfavoritar&idReceita=' + idReceita
    })
    .then(function(res) {
      if (res.status === 401) {
        window.location.href = CONTEXT_PATH + '/LoginController';
        throw new Error('não logado');
      }
      return res.text();
    })
    .then(function() {
      var card = btn.closest('.recipe-card');
      card.classList.add('removendo');
      card.dataset.removido = 'true';
      setTimeout(renderPagina, 220);
    })
    .catch(function(err) { console.error(err); });
  };

  renderPagina();
})();
</script>
</body>
</html>
