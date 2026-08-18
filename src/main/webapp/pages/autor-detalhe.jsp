<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Map" %>

<%--
    SERVLET RESPONSÁVEL: AutorController  (GET /AutorController?id=<id_usuario>)
    O servlet faz:
      1. Usuario autor       = usuarioDAO.buscarAutorPublicoPorId(id);
      2. List<Receita> lista = receitaDAO.listarReceitasPublicadasPorAutor(id, limite);
      3. request.setAttribute("autor", autor);
      4. request.setAttribute("receitas", lista);
      5. forward pra /pages/autor-detalhe.jsp
--%>
<%
    Usuario autor = (Usuario) request.getAttribute("autor");
    List<Receita> receitas = (List<Receita>) request.getAttribute("receitas");
    if (receitas == null) receitas = new java.util.ArrayList<>();

    String _ctx = request.getContextPath();

    // ── Guarda: sem autor, não tem o que renderizar ──
    if (autor == null) {
%>
<%
        return;
    }

    String nome   = autor.getNome_usuario() != null ? autor.getNome_usuario() : "";
    String cargo  = autor.getTitulo_usuario() != null && !autor.getTitulo_usuario().trim().isEmpty()
                    ? autor.getTitulo_usuario() : "Autor";
    String bio    = autor.getBio_usuario() != null ? autor.getBio_usuario() : "Este autor ainda não escreveu uma biografia.";
    String foto   = autor.getFoto_usuario();
    String inicial = nome.length() > 0 ? nome.substring(0, 1).toUpperCase() : "?";

    String instagram = autor.getInstagram_usuario();
    String youtube    = autor.getYoutube_usuario();
    String pinterest  = autor.getPinterest_usuario();

    boolean temRedes = (instagram != null && !instagram.trim().isEmpty())
                     || (youtube != null && !youtube.trim().isEmpty())
                     || (pinterest != null && !pinterest.trim().isEmpty());

    Boolean seguindoAttr = (Boolean) request.getAttribute("seguindo"); // null = não logado
    boolean seguindoInicial = Boolean.TRUE.equals(seguindoAttr);
    Boolean souEuMesmoAttr = (Boolean) request.getAttribute("souEuMesmo");
    boolean souEuMesmo = Boolean.TRUE.equals(souEuMesmoAttr);

    // ── Especialidades: categorias distintas presentes nas receitas do autor ──
    Map<String, String> especialidades = new LinkedHashMap<>(); // nome_categoria -> emoji_categoria
    for (Receita r : receitas) {
        if (r.getNome_categoria() != null && !especialidades.containsKey(r.getNome_categoria())) {
            especialidades.put(r.getNome_categoria(), r.getEmoji_categoria());
        }
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — <%= nome %></title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--sidebar-w:260px;
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

  .content { flex:1; padding:0 40px 40px; }

  /* HERO */
  .author-hero {
    background: linear-gradient(135deg, var(--moss-dark) 0%, var(--moss) 60%, var(--moss-light) 100%);
    border-radius:0 0 6px 6px; margin:0 -40px 26px; padding:30px 40px;
    display:flex; align-items:center; gap:22px; flex-wrap:wrap;
    box-shadow:0 6px 20px rgba(47,61,37,0.18); position:relative; overflow:hidden;
  }
  .author-hero::before { content:''; position:absolute; top:-70px; right:-70px; width:220px; height:220px; border-radius:50%; background:rgba(163,177,138,0.12); }
  .ah-avatar {
    width:78px; height:78px; border-radius:50%; flex-shrink:0; position:relative; z-index:1;
    display:flex; align-items:center; justify-content:center; overflow:hidden;
    font-family:'Nunito',sans-serif; font-size:28px; font-weight:800;
    border:4px solid rgba(255,255,255,0.25); background:linear-gradient(135deg,var(--gold),var(--gold-light)); color:var(--moss-dark);
  }
  .ah-avatar img { width:100%; height:100%; object-fit:cover; }
  .ah-info { flex:1; min-width:200px; position:relative; z-index:1; }
  .ah-name { font-family:'Playfair Display',serif; font-size:25px; font-weight:700; color:white; line-height:1.15; margin-bottom:4px; }
  .ah-role { font-size:13px; color:rgba(255,255,255,0.65); font-weight:300; margin-bottom:8px; }
  .ah-bio { font-size:12.5px; color:rgba(255,255,255,0.75); font-weight:300; max-width:520px; line-height:1.5; }
  .ah-stats { display:flex; gap:24px; position:relative; z-index:1; flex-shrink:0; }
  .ah-stat { text-align:center; }
  .ah-stat-val { font-family:'Nunito',sans-serif; font-size:21px; font-weight:800; color:white; line-height:1; }
  .ah-stat-lbl { font-size:10px; color:rgba(255,255,255,0.55); text-transform:uppercase; letter-spacing:0.7px; margin-top:3px; font-weight:300; }
  .ah-follow-btn {
    position:relative; z-index:1; flex-shrink:0;
    display:inline-flex; align-items:center; gap:7px;
    background:rgba(255,255,255,0.15); border:1px solid rgba(255,255,255,0.3); color:white;
    font-family:'DM Sans',sans-serif; font-size:13px; font-weight:600;
    padding:10px 20px; border-radius:2px; cursor:pointer; transition:all 0.2s; white-space:nowrap;
  }
  .ah-follow-btn:hover { background:rgba(255,255,255,0.26); }
  .ah-follow-btn.following { background:var(--gold); border-color:var(--gold); color:var(--moss-dark); }

  /* TABS */
  .tab-nav { display:flex; gap:2px; background:var(--cream-dark); padding:4px; border-radius:4px; margin-bottom:20px; width:fit-content; }
  .tab-btn { padding:9px 22px; border:none; border-radius:2px; background:none; font-family:'DM Sans',sans-serif; font-size:13px; font-weight:500; color:var(--text-light); cursor:pointer; transition:all 0.2s; }
  .tab-btn:hover { color:var(--text-dark); }
  .tab-btn.active { background:var(--warm-white); color:var(--moss); box-shadow:0 1px 4px rgba(0,0,0,0.08); }
  .tab-panel { display:none; }
  .tab-panel.active { display:block; animation:fadeIn 0.25s ease; }
  @keyframes fadeIn { from{opacity:0;transform:translateY(4px);} to{opacity:1;transform:translateY(0);} }

  /* SOBRE — biografia em cima, redes + especialidades lado a lado embaixo */
  .cards-grid { display:grid; grid-template-columns:1fr 1fr; grid-template-rows:1.3fr 1fr; gap:16px; height:calc(100vh - 300px); min-height:340px; }
  .card-full { grid-column:1 / -1; }
  .card { background:var(--warm-white); border:1px solid var(--cream-dark); border-radius:4px; overflow:hidden; display:flex; flex-direction:column; min-height:0; }
  .card-head { padding:12px 20px; border-bottom:1px solid var(--cream-dark); flex-shrink:0; }
  .card-head-title { font-size:13.5px; font-weight:600; color:var(--text-dark); display:flex; align-items:center; gap:9px; }
  .card-body { padding:18px 20px; flex:1; overflow-y:auto; }
  .about-text { font-size:13.5px; line-height:1.7; color:var(--text-mid); font-weight:300; }

  .tags-wrap { display:flex; flex-wrap:wrap; gap:8px; }
  .tag { display:inline-flex; align-items:center; gap:5px; background:rgba(74,94,58,0.1); border:1.5px solid rgba(74,94,58,0.22); padding:6px 13px; border-radius:20px; font-size:12.5px; color:var(--moss); font-weight:500; }
  .empty-hint { font-size:12.5px; color:var(--text-light); font-weight:300; }

  /* REDES SOCIAIS — estilo caixinha (label + valor texto, não é link) */
  .social-field { margin-bottom:14px; }
  .social-field:last-child { margin-bottom:0; }
  .social-label { font-size:10.5px; font-weight:700; letter-spacing:0.8px; text-transform:uppercase; color:var(--text-light); margin-bottom:6px; }
  .social-value-box { background:var(--cream); border:1.5px solid var(--cream-dark); border-radius:3px; padding:11px 14px; font-size:14px; color:var(--text-dark); font-weight:500; user-select:all; cursor:text; word-break:break-all; }

  /* TOOLBAR + GRID RECEITAS */
  .section-title-row { display:flex; align-items:flex-end; justify-content:space-between; margin-bottom:16px; }
  .section-title { font-family:'Playfair Display',serif; font-size:20px; font-weight:500; color:var(--text-dark); }
  .section-title em { font-style:italic; color:var(--moss); }
  .section-count { font-size:12px; color:var(--text-light); font-weight:300; }

  .toolbar { display:flex; align-items:center; gap:12px; margin-bottom:18px; flex-wrap:wrap; }
  .search-bar { display:flex; align-items:center; gap:8px; background:var(--cream); border:1.5px solid var(--cream-dark); border-radius:2px; padding:8px 14px; flex:1; max-width:320px; transition:border-color .2s,box-shadow .2s,background .2s; }
  .search-bar:focus-within { border-color:var(--moss-light); background:var(--warm-white); box-shadow:0 0 0 3px rgba(74,94,58,0.1); }
  .search-bar input { border:none; background:none; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); outline:none; flex:1; }
  .filter-select { background:var(--cream); border:1.5px solid var(--cream-dark); border-radius:2px; padding:8px 12px; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); cursor:pointer; outline:none; }
  .toolbar-spacer { flex:1; }

  .recipes-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:18px; }
  .recipe-card { background:var(--warm-white); border:1px solid var(--cream-dark); border-radius:4px; overflow:hidden; cursor:pointer; transition:transform 0.2s,box-shadow 0.2s; text-decoration:none; display:block; }
  .recipe-card:hover { transform:translateY(-3px); box-shadow:0 10px 22px rgba(47,61,37,0.14); }
  .recipe-card img { width:100%; height:130px; object-fit:cover; display:block; background:var(--cream-dark); }
  .recipe-card-body { padding:12px 14px; }
  .recipe-card-title { font-size:13px; font-weight:600; color:var(--text-dark); margin-bottom:4px; line-height:1.3; }
  .recipe-card-cat { font-size:11px; color:var(--text-light); }
  .empty-state { text-align:center; padding:60px 20px; }

  @media (max-width:1200px) { .recipes-grid { grid-template-columns:repeat(3,1fr); } }
  @media (max-width:1000px) { .cards-grid { grid-template-columns:1fr; height:auto; } }
  @media (max-width:860px)  { .recipes-grid { grid-template-columns:1fr 1fr; } .author-hero { flex-direction:column; align-items:flex-start; } .ah-stats { flex-wrap:wrap; } }
  @media (max-width:768px)  { .main { margin-left:0; } .content { padding:0 20px 30px; } .topbar { padding:0 20px; } .author-hero { margin:0 -20px 22px; padding:26px 20px; } }
  @media (max-width:480px)  { .recipes-grid { grid-template-columns:1fr; } .tab-nav { overflow-x:auto; } }
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Autores</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current"><%= nome %></span>
    </div>
    <a class="topbar-back" href="<%= _ctx %>/pages/autores-visitante.jsp">← Voltar para autores</a>
  </div>

  <div class="content">

    <div class="author-hero">
      <div class="ah-avatar">
        <% if (foto != null && !foto.trim().isEmpty()) { %>
          <img src="<%= _ctx %><%= foto %>" alt="<%= nome %>">
        <% } else { %>
          <%= inicial %>
        <% } %>
      </div>
      <div class="ah-info">
        <div class="ah-name"><%= nome %></div>
        <div class="ah-role"><%= cargo %></div>
        <div class="ah-bio"><%= bio.length() > 140 ? bio.substring(0,140) + "…" : bio %></div>
      </div>
      <div class="ah-stats">
        <div class="ah-stat"><div class="ah-stat-val"><%= autor.getTotal_receitas_publicadas() %></div><div class="ah-stat-lbl">Receitas</div></div>
        <div class="ah-stat"><div class="ah-stat-val"><%= autor.getTotal_comentarios() %></div><div class="ah-stat-lbl">Comentários</div></div>
      </div>
      <%-- Botão "Seguir": some se for o próprio autor logado vendo o próprio perfil.
           Estado inicial vem do servidor (seguindoInicial); o clique chama o
           SeguidorController via AJAX (action=toggle). Se não estiver logado,
           o servlet responde 401 e o JS manda pro login. --%>
      <% if (!souEuMesmo) { %>
        <button class="ah-follow-btn<%= seguindoInicial ? " following" : "" %>" id="ahFollowBtn" onclick="toggleFollowAuthor()">
          <span id="ahFollowIcon"><%= seguindoInicial ? "✓" : "+" %></span>
          <span id="ahFollowLabel"><%= seguindoInicial ? "Seguindo" : "Seguir" %></span>
        </button>
      <% } %>
    </div>

    <div class="tab-nav">
      <button class="tab-btn active" id="tabBtnSobre" onclick="switchTab('sobre', this)">👤 Sobre</button>
      <button class="tab-btn" id="tabBtnReceitas" onclick="switchTab('receitas', this)">📖 Receitas</button>
    </div>

    <!-- ===== ABA SOBRE ===== -->
    <div class="tab-panel active" id="tab-sobre">
      <div class="cards-grid">

        <div class="card card-full">
          <div class="card-head"><div class="card-head-title">📝 Biografia</div></div>
          <div class="card-body">
            <p class="about-text"><%= bio %></p>
          </div>
        </div>

        <div class="card">
          <div class="card-head"><div class="card-head-title">🔗 Redes sociais</div></div>
          <div class="card-body">
            <% if (!temRedes) { %>
              <div class="empty-hint">Nenhuma rede social cadastrada.</div>
            <% } else { %>
              <% if (instagram != null && !instagram.trim().isEmpty()) { %>
                <div class="social-field">
                  <div class="social-label">Instagram</div>
                  <div class="social-value-box"><%= instagram %></div>
                </div>
              <% } %>
              <% if (youtube != null && !youtube.trim().isEmpty()) { %>
                <div class="social-field">
                  <div class="social-label">YouTube</div>
                  <div class="social-value-box"><%= youtube %></div>
                </div>
              <% } %>
              <% if (pinterest != null && !pinterest.trim().isEmpty()) { %>
                <div class="social-field">
                  <div class="social-label">Pinterest</div>
                  <div class="social-value-box"><%= pinterest %></div>
                </div>
              <% } %>
            <% } %>
          </div>
        </div>

        <div class="card">
          <div class="card-head"><div class="card-head-title">🍽️ Especialidades</div></div>
          <div class="card-body">
            <% if (especialidades.isEmpty()) { %>
              <div class="empty-hint">Ainda sem receitas publicadas para gerar especialidades.</div>
            <% } else { %>
              <div class="tags-wrap">
                <% for (Map.Entry<String,String> esp : especialidades.entrySet()) { %>
                  <span class="tag"><%= esp.getValue() != null ? esp.getValue() + " " : "" %><%= esp.getKey() %></span>
                <% } %>
              </div>
            <% } %>
          </div>
        </div>

      </div>
    </div>

    <!-- ===== ABA RECEITAS ===== -->
    <div class="tab-panel" id="tab-receitas">
      <div class="section-title-row">
        <div class="section-title">Todas as <em>receitas</em></div>
        <span class="section-count"><%= receitas.size() %> receita<%= receitas.size() == 1 ? "" : "s" %></span>
      </div>

      <div class="toolbar">
        <div class="search-bar">
          <span style="font-size:14px;color:var(--text-light)">🔍</span>
          <input type="text" id="campoBuscaReceita" placeholder="Buscar receitas…" oninput="filtrarReceitas()">
        </div>
        <select class="filter-select" id="filterCategoria" onchange="filtrarReceitas()">
          <option value="todos" selected>Todas as categorias</option>
          <% for (String catNome : especialidades.keySet()) { %>
            <option value="<%= catNome %>"><%= especialidades.get(catNome) != null ? especialidades.get(catNome) + " " : "" %><%= catNome %></option>
          <% } %>
        </select>
        <div class="toolbar-spacer"></div>
      </div>

      <% if (receitas.isEmpty()) { %>
        <div class="empty-state">
          <div style="font-size:44px;margin-bottom:14px;">🍽️</div>
          <div style="font-family:'Playfair Display',serif;font-size:19px;font-weight:700;color:var(--text-dark);margin-bottom:6px;">Nenhuma receita publicada ainda</div>
          <div style="font-size:13.5px;color:var(--text-light);font-weight:300;">Quando <%= nome %> publicar receitas, elas aparecem aqui.</div>
        </div>
      <% } else { %>
        <div class="recipes-grid" id="recipesGrid">
          <% for (Receita r : receitas) {
               String img = r.getImagem_receita();
               String imgSrc = (img != null && !img.trim().isEmpty()) ? _ctx + img : "https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=400&q=80";
               String catNome = r.getNome_categoria() != null ? r.getNome_categoria() : "";
               String catEmoji = r.getEmoji_categoria() != null ? r.getEmoji_categoria() : "";
          %>
            <a class="recipe-card" href="<%= _ctx %>/pages/receita-detalhe-publico.jsp?id=<%= r.getId_receita() %>"
               data-titulo="<%= r.getTitulo_receita() != null ? r.getTitulo_receita().toLowerCase() : "" %>"
               data-categoria="<%= catNome %>">
              <img src="<%= imgSrc %>" alt="<%= r.getTitulo_receita() %>">
              <div class="recipe-card-body">
                <div class="recipe-card-title"><%= r.getTitulo_receita() %></div>
                <div class="recipe-card-cat"><%= catEmoji %> <%= catNome %></div>
              </div>
            </a>
          <% } %>
        </div>
        <div class="empty-state" id="recipesEmptyState" style="display:none;">
          <div style="font-size:44px;margin-bottom:14px;">🔍</div>
          <div style="font-family:'Playfair Display',serif;font-size:19px;font-weight:700;color:var(--text-dark);margin-bottom:6px;">Nenhuma receita encontrada</div>
          <div style="font-size:13.5px;color:var(--text-light);font-weight:300;">Tente buscar por outro termo ou categoria.</div>
        </div>
      <% } %>
    </div>

  </div>
</main>

<script>
  function switchTab(id, btn) {
    document.querySelectorAll('.tab-panel').forEach(function(p) { p.classList.remove('active'); });
    document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
    document.getElementById('tab-' + id).classList.add('active');
    btn.classList.add('active');
  }

  function filtrarReceitas() {
    var termo = document.getElementById('campoBuscaReceita').value.trim().toLowerCase();
    var categoria = document.getElementById('filterCategoria').value;
    var cards = document.querySelectorAll('#recipesGrid .recipe-card');
    var visiveis = 0;

    cards.forEach(function(card) {
      var bateBusca = !termo || card.dataset.titulo.indexOf(termo) >= 0;
      var bateCategoria = categoria === 'todos' || card.dataset.categoria === categoria;
      var mostrar = bateBusca && bateCategoria;
      card.style.display = mostrar ? '' : 'none';
      if (mostrar) visiveis++;
    });

    var grid = document.getElementById('recipesGrid');
    var empty = document.getElementById('recipesEmptyState');
    if (grid) grid.style.display = visiveis === 0 ? 'none' : 'grid';
    if (empty) empty.style.display = visiveis === 0 ? 'block' : 'none';
  }

  // ── Botão Seguir: chama o SeguidorController de verdade ──
  var AUTOR_ID = <%= autor.getId_usuario() %>;
  var seguindoAtual = <%= seguindoInicial %>;

  function toggleFollowAuthor() {
    fetch('<%= _ctx %>/SeguidorController', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: 'action=toggle&idSeguido=' + AUTOR_ID
    })
    .then(function(res) {
      if (res.status === 401) {
        window.location.href = '<%= _ctx %>/LoginController';
        throw new Error('não logado');
      }
      return res.text();
    })
    .then(function(texto) {
      seguindoAtual = (texto === 'seguindo');
      atualizarBotaoFollow();
    })
    .catch(function(err) { console.error(err); });
  }

  function atualizarBotaoFollow() {
    var btn = document.getElementById('ahFollowBtn');
    if (!btn) return;
    document.getElementById('ahFollowIcon').textContent = seguindoAtual ? '✓' : '+';
    document.getElementById('ahFollowLabel').textContent = seguindoAtual ? 'Seguindo' : 'Seguir';
    btn.classList.toggle('following', seguindoAtual);
  }
</script>
</body>
</html>
