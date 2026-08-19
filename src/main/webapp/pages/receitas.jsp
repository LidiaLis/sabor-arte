<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value)
      .replace("&", "&amp;")
      .replace("<", "&lt;")
      .replace(">", "&gt;")
      .replace("\"", "&quot;")
      .replace("'", "&#39;");
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
  Usuario usuario = (Usuario) session.getAttribute("usuarioLogado");
  boolean usuarioAutenticado = usuario != null;
  String tipoUsuario = usuarioAutenticado && usuario.getTipo_usuario() != null
      ? usuario.getTipo_usuario().toString()
      : "PUBLICO";
  String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Receitas</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:         #4a5e3a;
    --moss-dark:    #2f3d25;
    --moss-mid:     #3d5030;
    --moss-light:   #6b7f59;
    --sage:         #a3b18a;
    --sage-light:   #c8d5b9;
    --cream:        #f5f0e8;
    --cream-dark:   #e6dece;
    --warm-white:   #faf8f4;
    --text-dark:    #1e2718;
    --text-mid:     #4a5240;
    --text-light:   #8a9480;
    --gold:         #c4a265;
    --gold-light:   #dfc094;
    --gold-pale:    #f5ead6;
    --pending:      #c4832a;
    --pending-bg:   #fdf2e3;
    --published:    #3a7a4a;
    --published-bg: #e8f4eb;
    --draft:        #6a7a8a;
    --draft-bg:     #eef1f4;
    --archived:     #8a7a6a;
    --archived-bg:  #f4f0ec;
    --sidebar-w:    260px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'DM Sans', sans-serif;
    background: var(--cream);
    color: var(--text-dark);
    min-height: 100vh;
    display: flex;
    overflow-x: hidden;
  }

  /* ===== SIDEBAR ===== */
  .sidebar {
    width: var(--sidebar-w);
    background: var(--moss-dark);
    display: flex;
    flex-direction: column;
    position: fixed;
    top: 0; left: 0; bottom: 0;
    z-index: 100;
    overflow-y: auto;
  }

  .sidebar::before {
    content: '';
    position: absolute;
    inset: 0;
    background:
      radial-gradient(ellipse 200% 60% at 50% 0%, rgba(74,94,58,0.5) 0%, transparent 60%),
      radial-gradient(ellipse 100% 40% at 50% 100%, rgba(163,177,138,0.1) 0%, transparent 60%);
    pointer-events: none;
  }

  .sidebar-brand {
    padding: 28px 24px 22px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
    position: relative; z-index: 1;
  }

  .brand-row { display: flex; align-items: center; gap: 12px; }

  .brand-badge {
    width: 38px; height: 38px;
    background: linear-gradient(135deg, var(--moss-light), var(--sage));
    border-radius: 2px;
    display: flex; align-items: center; justify-content: center;
    font-size: 18px; flex-shrink: 0;
  }

  .brand-title {
    font-family: 'Playfair Display', serif;
    font-size: 18px; font-weight: 700;
    color: var(--cream); display: block; line-height: 1;
  }

  .brand-sub {
    font-size: 10px; color: var(--sage);
    text-transform: uppercase; letter-spacing: 1.2px;
    margin-top: 3px; display: block; font-weight: 300;
  }

  .sidebar-user {
    padding: 18px 24px;
    border-bottom: 1px solid rgba(255,255,255,0.07);
    display: flex; align-items: center; gap: 12px;
    position: relative; z-index: 1;
  }

a.sidebar-user,
a.sidebar-user:link,
a.sidebar-user:visited,
a.sidebar-user:hover,
a.sidebar-user:active {
  text-decoration: none;
  color: inherit;
}

  .user-avatar {
    width: 38px; height: 38px;
    background: linear-gradient(135deg, var(--gold), var(--gold-light));
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif;
    font-weight: 800; font-size: 13px;
    color: var(--moss-dark); flex-shrink: 0;
  }

  .user-name { font-size: 13px; font-weight: 600; color: var(--cream); }
  .user-role-badge { font-size: 10px; color: var(--gold-light); text-transform: uppercase; letter-spacing: 0.8px; font-weight: 300; }

  .sidebar-nav { flex: 1; padding: 16px 0; position: relative; z-index: 1; }

  .nav-section-label {
    font-size: 9px; text-transform: uppercase; letter-spacing: 1.8px;
    color: rgba(163,177,138,0.5); padding: 16px 24px 6px; font-weight: 500;
  }

  .nav-item {
    display: flex; align-items: center; gap: 12px;
    padding: 11px 24px;
    color: rgba(245,240,232,0.7);
    text-decoration: none; font-size: 14px; font-weight: 400;
    cursor: pointer; transition: all 0.2s;
    border-left: 3px solid transparent;
  }
  .nav-item:hover { color: var(--cream); background: rgba(255,255,255,0.06); border-left-color: var(--sage); }
  .nav-item.active { color: var(--cream); background: rgba(163,177,138,0.15); border-left-color: var(--sage-light); font-weight: 500; }

  .nav-icon { width: 22px; text-align: center; font-size: 16px; flex-shrink: 0; }

  .nav-badge {
    margin-left: auto;
    background: var(--gold); color: var(--moss-dark);
    font-family: 'Nunito', sans-serif;
    font-size: 10px; font-weight: 800;
    padding: 2px 7px; border-radius: 10px;
  }

  .sidebar-bottom {
    padding: 16px 24px 24px;
    border-top: 1px solid rgba(255,255,255,0.08);
    position: relative; z-index: 1;
  }

  .btn-logout {
    display: flex; align-items: center; gap: 10px;
    width: 100%; padding: 10px 16px;
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.1); border-radius: 2px;
    color: rgba(245,240,232,0.7);
    font-family: 'DM Sans', sans-serif; font-size: 13px;
    cursor: pointer; transition: all 0.2s;
  }
  .btn-logout:hover { background: rgba(155,68,68,0.2); border-color: rgba(155,68,68,0.3); color: #e8a0a0; }

  /* ===== MAIN ===== */
  .main { margin-left: var(--sidebar-w); flex: 1; min-height: 100vh; display: flex; flex-direction: column; }

  .topbar {
    background: var(--warm-white); border-bottom: 1px solid var(--cream-dark);
    padding: 0 40px; height: 64px;
    display: flex; align-items: center; justify-content: space-between;
    position: sticky; top: 0; z-index: 50;
  }

  .page-crumb { font-size: 12px; color: var(--text-light); display: flex; align-items: center; gap: 6px; font-weight: 300; }
  .page-crumb .current { color: var(--moss); font-weight: 500; }

  .topbar-right { display: flex; align-items: center; gap: 16px; }

  .notif-btn {
    width: 36px; height: 36px; background: var(--cream);
    border: 1.5px solid var(--cream-dark); border-radius: 2px;
    display: flex; align-items: center; justify-content: center;
    cursor: pointer; font-size: 16px; position: relative; transition: all 0.2s;
  }
  .notif-btn:hover { background: var(--cream-dark); }
  .notif-dot { position: absolute; top: 4px; right: 4px; width: 8px; height: 8px; background: var(--gold); border-radius: 50%; border: 2px solid var(--warm-white); }

  /* ===== CONTENT ===== */
  .content { flex: 1; padding: 24px 40px; }

  .section-header { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 16px; }
  .section-title { font-family: 'Playfair Display', serif; font-size: 26px; font-weight: 500; color: var(--text-dark); line-height: 1; }
  .section-title em { font-style: italic; color: var(--moss); }

  /* ===== TOOLBAR (busca + filtro em listbox) ===== */
  .toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 14px; flex-wrap: wrap; }
  .search-bar {
    display: flex; align-items: center; gap: 8px;
    background: var(--warm-white); border: 1.5px solid var(--cream-dark);
    border-radius: 2px; padding: 8px 14px; flex: 1; max-width: 320px;
  }
  .search-bar:focus-within { border-color: var(--moss-light); }
  .search-bar input { border: none; background: none; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark); outline: none; flex: 1; }
  .search-bar input::placeholder { color: var(--text-light); }
  .filter-select {
    background: var(--warm-white); border: 1.5px solid var(--cream-dark);
    border-radius: 2px; padding: 8px 12px;
    font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark);
    cursor: pointer; outline: none; transition: border-color .2s;
  }
  .filter-select:focus { border-color: var(--moss-light); }
  .toolbar-spacer { flex: 1; }

  /* ===== RECEITAS GRID ===== */
  .recipes-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; align-items: start; }

  .recipe-card {
    background: var(--warm-white);
    border: 1px solid var(--cream-dark);
    border-radius: 6px; overflow: hidden;
    transition: transform 0.25s, box-shadow 0.25s;
  }
  .recipe-card:hover { transform: translateY(-5px); box-shadow: 0 20px 48px rgba(47,61,37,0.16); }

  .recipe-img-wrap { position: relative; overflow: hidden; height: 118px; }
  .recipe-img-wrap img { width: 100%; height: 100%; object-fit: cover; display: block; }

  .recipe-body { padding: 12px 16px 10px; }
  .recipe-cat { font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: var(--moss-light); font-weight: 600; margin-bottom: 4px; }
  .recipe-name { font-family: 'Playfair Display', serif; font-size: 14px; font-weight: 700; color: var(--text-dark); line-height: 1.3; margin-bottom: 8px; }

  .recipe-author { display: flex; align-items: center; gap: 7px; }
  .author-dot {
    width: 22px; height: 22px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif;
    font-size: 9px; font-weight: 800; color: white; flex-shrink: 0;
  }
  .author-name { font-size: 12px; color: var(--text-mid); font-weight: 400; }

  .recipe-footer {
    display: flex; align-items: center; gap: 6px;
    justify-content: flex-end;
    padding: 10px 16px;
    border-top: 1px solid var(--cream-dark);
    background: var(--cream);
  }
  .footer-btn {
    padding: 6px 12px; border: 1.5px solid var(--cream-dark);
    background: var(--warm-white); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500;
    color: var(--text-mid); cursor: pointer; transition: all 0.15s;
    display: flex; align-items: center; justify-content: center; gap: 4px; white-space: nowrap;
  }
  .footer-btn:hover { border-color: var(--moss); color: var(--moss); background: rgba(74,94,58,0.05); }
  .footer-btn.toggle-favorito:hover { border-color: var(--gold); color: var(--gold); background: rgba(196,162,101,0.08); }
  .footer-btn.favorited { border-color: var(--gold); color: var(--gold); background: var(--gold-pale); }
  .footer-btn.favorited:hover { background: var(--gold-pale); border-color: var(--gold); color: var(--gold); }

  /* ===== EMPTY STATE ===== */
  .empty-state { grid-column: 1 / -1; text-align: center; padding: 60px 20px; color: var(--text-light); }
  .empty-state .empty-icon { font-size: 44px; margin-bottom: 14px; }
  .empty-state h3 { font-family: 'Playfair Display', serif; font-size: 18px; color: var(--text-dark); margin-bottom: 6px; }
  .empty-state p { font-size: 13px; font-weight: 300; }

  /* ===== PAGINAÇÃO (mesmo padrão da tela de categorias) ===== */
  .pagination { display: flex; align-items: center; justify-content: space-between; padding: 10px 4px 4px; margin-top: 4px; }
  .pag-info { font-size: 12px; color: var(--text-light); font-weight: 300; }
  .pag-btns { display: flex; gap: 4px; }
  .pag-btn {
    min-width: 32px; height: 32px; padding: 0 8px;
    border: 1.5px solid var(--cream-dark); background: var(--warm-white);
    border-radius: 2px; display: flex; align-items: center; justify-content: center;
    font-size: 12px; cursor: pointer; color: var(--text-mid);
    font-family: 'Nunito', sans-serif; font-weight: 700; transition: all 0.15s;
  }
  .pag-btn:hover:not(:disabled) { border-color: var(--moss); color: var(--moss); }
  .pag-btn.active { background: var(--moss); border-color: var(--moss); color: var(--cream); }
  .pag-btn:disabled { opacity: .4; cursor: not-allowed; }

  /* ===== RESPONSIVE ===== */
  @media (max-width: 1100px) { .recipes-grid { grid-template-columns: repeat(2, 1fr); } }
  @media (max-width: 768px)  { .sidebar { display: none; } .main { margin-left: 0; } .content { padding: 24px 20px; } .topbar { padding: 0 20px; } .pagination { flex-direction: column; gap: 10px; align-items: flex-start; } }
  @media (max-width: 580px)  { .recipes-grid { grid-template-columns: 1fr; } }
</style>
</head>
<body>

<!-- ===== SIDEBAR VISITANTE (estático) ===== -->
<%
  request.setAttribute("currentPage", "receitas");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />



<!-- MAIN -->
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Gestão</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Receitas</span>
    </div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Todas as <em>Receitas</em></div>
      </div>
    </div>

    <!-- ===== TOOLBAR: BUSCA + FILTRO DE CATEGORIA (sem filtro de status) ===== -->
    <div class="toolbar">
      <div class="search-bar">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" id="campoBusca" placeholder="Buscar receitas…">
      </div>
      <!--
        Em produção: SELECT id_categoria, nome_categoria, emoji_categoria FROM categoria
        (aqui os valores estão fixos, extraídos das categorias já usadas nos cards abaixo)
      -->
      <select class="filter-select" id="filterCategoria">
        <option value="" selected>Todas as categorias</option>
        <% for (Categoria categoria : categorias) { %>
          <option value="<%= h(categoria.getNome_categoria()) %>"><%= h(categoria.getEmoji_categoria()) %> <%= h(categoria.getNome_categoria()) %></option>
        <% } %>
      </select>
      <div class="toolbar-spacer"></div>
    </div>

    <!-- GRID -->
    <div class="recipes-grid" id="recipesGrid">
      <% for (Receita receita : receitas) { %>
        <article class="recipe-card" data-name="<%= h(receita.getTitulo_receita()) %>" data-cat="<%= h(receita.getNome_categoria()) %>">
          <div class="recipe-img-wrap">
            <img src="<%= h(receita.getImagem_receita()) %>" alt="<%= h(receita.getTitulo_receita()) %>">
          </div>
          <div class="recipe-body">
            <div class="recipe-cat"><%= h(receita.getEmoji_categoria()) %> <%= h(receita.getNome_categoria()) %></div>
            <div class="recipe-name"><%= h(receita.getTitulo_receita()) %></div>
            <div class="recipe-author">
              <div class="author-dot"><%= h(receita.getNome_usuario()).isEmpty() ? "?" : h(receita.getNome_usuario()).substring(0, 1).toUpperCase() %></div>
              <span class="author-name"><%= h(receita.getNome_usuario()) %></span>
            </div>
          </div>
          <div class="recipe-footer">
            <a class="footer-btn" href="<%= ctx %>/ReceitaController?action=detalhar&id=<%= receita.getId_receita() %>">👁 Ver</a>
            <% if (usuarioAutenticado) { %>
              <form method="post" action="<%= ctx %>/FavoritoController">
                <input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>">
                <button class="footer-btn" type="submit">☆ Favoritar</button>
              </form>
            <% } %>
            <% if ("ADMIN".equals(tipoUsuario)) { %>
              <form method="post" action="<%= ctx %>/receitas">
                <input type="hidden" name="action" value="toggleStatus">
                <input type="hidden" name="receitaId" value="<%= receita.getId_receita() %>">
                <button class="footer-btn" type="submit">Ativar/Inativar</button>
              </form>
            <% } %>
          </div>
        </article>
      <% } %>
      <% if (receitas.isEmpty()) { %>
        <div class="empty-state" id="emptyState"><div class="empty-icon">🍽️</div><h3>Nenhuma receita encontrada</h3><p>Tente novamente mais tarde.</p></div>
      <% } %>
    </div><!-- /recipes-grid -->

    <!-- ===== PAGINAÇÃO ===== -->
    <div class="pagination" id="pagination">
      <div class="pag-info" id="pagInfo">—</div>
      <div class="pag-btns" id="pagBtns"></div>
    </div>

  </div>
</main>

<script>
(function () {
  var cards = Array.from(document.querySelectorAll('#recipesGrid .recipe-card'));
  var search = document.getElementById('campoBusca');
  var category = document.getElementById('filterCategoria');
  var empty = document.getElementById('emptyState');

  function filterCards() {
    var term = search ? search.value.trim().toLowerCase() : '';
    var selected = category ? category.value : '';
    var visible = 0;
    cards.forEach(function (card) {
      var matches = (!term || (card.dataset.name || '').toLowerCase().includes(term)) &&
        (!selected || card.dataset.cat === selected);
      card.style.display = matches ? '' : 'none';
      if (matches) visible++;
    });
    if (empty) empty.style.display = visible ? 'none' : '';
    var info = document.getElementById('pagInfo');
    if (info) info.textContent = visible ? visible + ' receita(s)' : 'Nenhuma receita encontrada';
  }

  if (search) search.addEventListener('input', filterCards);
  if (category) category.addEventListener('change', filterCards);
  filterCards();
})();
</script>
</body>
</html>
