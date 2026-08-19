<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.Usuario.TipoUsuario" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%!
    // Deixa "janeiro de 2024" com a primeira letra maiúscula -> "Janeiro de 2024"
    private String capitalizar(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
%>
<%
    // ===================================================================================
    // Tela de Autores — serve tanto o VISITANTE logado quanto o público anônimo.
    // Diferença entre os dois: só o visitante logado vê o botão "Seguir" dentro do modal.
    // O sidebar já vem pronto via include (ele mesmo decide o que mostrar por sessão).
    //
    // TODO (dados que o AutorPublicoController + DAOs precisam fornecer):
    //   - request.setAttribute("listaAutores", List<Usuario>) -> UsuarioDAO.listarAutoresPublicos()
    //     (esse metodo já preenche total_receitas_publicadas, total_comentarios,
    //      total_visualizacoes, que são os campos extras do model)
    //   - (opcional) request.setAttribute("especialidadesPorAutor", Map<Integer,List<String>>)
    //     chave = id_usuario, valor = nomes das especialidades (via EspecialidadeDAO)
    //     -> usado pras tags do modal e pro filtro por especialidade
    //   - "Últimas receitas publicadas" do modal não entrou aqui ainda (precisa de
    //     ReceitaDAO por autor) — deixei comentado no lugar certo, é só destravar depois.
    // ===================================================================================

    List<Usuario> listaAutores = (List<Usuario>) request.getAttribute("listaAutores");
    if (listaAutores == null) listaAutores = new ArrayList<Usuario>();

    @SuppressWarnings("unchecked")
    Map<Integer, List<String>> especialidadesPorAutor =
            (Map<Integer, List<String>>) request.getAttribute("especialidadesPorAutor");

    @SuppressWarnings("unchecked")
    Map<Integer, Boolean> seguindoPorAutor =
            (Map<Integer, Boolean>) request.getAttribute("seguindoPorAutor");
    if (seguindoPorAutor == null) seguindoPorAutor = new java.util.HashMap<Integer, Boolean>();

    // Categorias que têm ao menos 1 autor especialista (AutorController via
    // EspecialidadeDAO.listarCategoriasComEspecialistas()) — usadas pra montar
    // o <select> de filtro dinamicamente, em vez de uma lista fixa no HTML.
    @SuppressWarnings("unchecked")
    List<Categoria> especialidadesFiltro =
            (List<Categoria>) request.getAttribute("especialidadesFiltro");
    if (especialidadesFiltro == null) especialidadesFiltro = new ArrayList<Categoria>();

    Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
    boolean logado = (usuarioLogado != null); // true = tela do visitante / false = tela pública

    String _ctx = request.getContextPath();

    String[] bannerClasses = {"banner-1","banner-2","banner-3","banner-4","banner-5","banner-6","banner-7","banner-8"};
    String[] avatarClasses = {"avatar-gold","avatar-moss","avatar-sage","avatar-terra","avatar-blue"};

    DateTimeFormatter memberFmt = DateTimeFormatter.ofPattern("MMMM 'de' yyyy", new Locale("pt", "BR"));
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Nossos Autores</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;
    --draft:#6a7a8a;--draft-bg:#eef1f4;--archived:#8a7a6a;--archived-bg:#f4f0ec;
    --error:#9b4444;--error-bg:#f5e6e6;--sidebar-w:260px;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'DM Sans', sans-serif; background: var(--cream); color: var(--text-dark); min-height: 100vh; display: flex; }

  /* ===== MAIN ===== */
  .main { margin-left: var(--sidebar-w); flex: 1; min-height: 100vh; display: flex; flex-direction: column; }

  .topbar { background: var(--warm-white); border-bottom: 1px solid var(--cream-dark); padding: 0 40px; height: 64px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 50; }
  .page-crumb { font-size: 12px; color: var(--text-light); display: flex; align-items: center; gap: 6px; font-weight: 300; }
  .page-crumb .current { color: var(--moss); font-weight: 500; }

  .toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 14px; flex-wrap: wrap; }
  .search-bar {
    display: flex; align-items: center; gap: 8px;
    background: var(--cream); border: 1.5px solid var(--cream-dark);
    border-radius: 2px; padding: 8px 14px; flex: 1; max-width: 320px;
    transition: border-color .2s, box-shadow .2s, background .2s;
  }
  .search-bar:focus-within { border-color: var(--moss-light); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }
  .search-bar input { border: none; background: none; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark); outline: none; flex: 1; }
  .search-bar input::placeholder { color: var(--text-light); }
  .filter-select {
    background: var(--cream); border: 1.5px solid var(--cream-dark);
    border-radius: 2px; padding: 8px 12px;
    font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark);
    cursor: pointer; outline: none; transition: border-color .2s, box-shadow .2s, background .2s;
  }
  .filter-select:focus { border-color: var(--moss-light); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }
  .toolbar-spacer { flex: 1; }

  .content { flex: 1; padding: 24px 40px; }

  .section-header { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 16px; }
  .section-title { font-family: 'Playfair Display', serif; font-size: 26px; font-weight: 500; color: var(--text-dark); line-height: 1; }
  .section-title em { font-style: italic; color: var(--moss); }
  .section-count { font-size: 12px; color: var(--text-light); font-weight: 300; }

  .authors-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }

  .author-card {
    background: var(--warm-white); border: 1px solid var(--cream-dark);
    border-radius: 4px; overflow: hidden;
    transition: transform 0.22s, box-shadow 0.22s, border-color 0.22s;
    position: relative;
  }
  .author-card:hover { transform: translateY(-4px); box-shadow: 0 12px 36px rgba(47,61,37,0.13); border-color: var(--sage); }

  .card-banner { height: 118px; position: relative; overflow: hidden; }
  .banner-1 { background: linear-gradient(120deg, #2f3d25, #6b7f59); }
  .banner-2 { background: linear-gradient(120deg, #3d3525, #7f6b59); }
  .banner-3 { background: linear-gradient(120deg, #25333d, #597f79); }
  .banner-4 { background: linear-gradient(120deg, #3d2536, #7f5973); }
  .banner-5 { background: linear-gradient(120deg, #1e2a3d, #4a6285); }
  .banner-6 { background: linear-gradient(120deg, #2f3d25, #4a5e3a); }
  .banner-7 { background: linear-gradient(120deg, #3d2b25, #8a5a46); }
  .banner-8 { background: linear-gradient(120deg, #25353d, #4a7280); }
  .banner-pattern { position: absolute; inset: 0; opacity: 0.12; background-image: radial-gradient(circle, rgba(255,255,255,0.6) 1px, transparent 1px); background-size: 18px 18px; }

  .card-body-inner { padding: 0 18px 8px; }
  .author-avatar-wrap { margin-top: -34px; margin-bottom: 4px; position: relative; display: inline-block; }
  .author-avatar {
    width: 52px; height: 52px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif; font-size: 19px; font-weight: 800;
    border: 3px solid var(--warm-white); position: relative;
  }
  .avatar-gold   { background: linear-gradient(135deg, #c4a265, #dfc094); color: var(--moss-dark); }
  .avatar-moss   { background: linear-gradient(135deg, #4a5e3a, #6b7f59); color: white; }
  .avatar-sage   { background: linear-gradient(135deg, #8a9480, #a3b18a); color: var(--moss-dark); }
  .avatar-terra  { background: linear-gradient(135deg, #8a6a46, #b0896a); color: white; }
  .avatar-blue   { background: linear-gradient(135deg, #4a6a7a, #6a8a9a); color: white; }

  .verified-dot {
    position: absolute; bottom: 1px; right: 1px;
    width: 15px; height: 15px; border-radius: 50%;
    background: var(--moss); border: 2px solid var(--warm-white);
    display: flex; align-items: center; justify-content: center;
    font-size: 8px; color: white;
  }

  .author-name { font-family: 'Playfair Display', serif; font-size: 16px; font-weight: 700; color: var(--text-dark); margin-bottom: 3px; }
  .author-title { font-size: 12px; color: var(--text-light); font-weight: 300; margin-bottom: 6px; line-height: 1.4; }

  .card-footer { display: flex; align-items: center; gap: 6px; justify-content: flex-end; padding: 10px 16px; border-top: 1px solid var(--cream-dark); background: var(--cream); }
  .footer-btn {
    padding: 6px 12px; border: 1.5px solid var(--cream-dark);
    background: var(--warm-white); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500;
    color: var(--text-mid); cursor: pointer; transition: all 0.15s;
    display: flex; align-items: center; justify-content: center; gap: 4px; white-space: nowrap;
    text-decoration: none;
  }
  .footer-btn:hover { border-color: var(--moss); color: var(--moss); background: rgba(74,94,58,0.05); }

  /* ===== MODAL PERFIL ===== */
  .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 500; align-items: center; justify-content: center; padding: 16px 20px; overflow-y: auto; }
  .modal-overlay.show { display: flex; }

  .modal-profile {
    background: var(--warm-white); border-radius: 4px; width: 100%; max-width: 640px;
    max-height: calc(100vh - 32px);
    box-shadow: 0 20px 60px rgba(0,0,0,0.25); animation: slideUp 0.3s ease;
    overflow: hidden; display: flex; flex-direction: column;
  }
  @keyframes slideUp { from { opacity: 0; transform: translateY(32px); } to { opacity: 1; transform: translateY(0); } }

  .modal-header { background: linear-gradient(135deg, var(--moss-dark), var(--moss)); padding: 20px 28px 16px; position: relative; flex-shrink: 0; }
  .modal-close-btn {
    position: absolute; top: 12px; right: 12px;
    background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.2);
    width: 26px; height: 26px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    color: white; font-size: 14px; cursor: pointer; transition: background 0.2s;
  }
  .modal-close-btn:hover { background: rgba(255,255,255,0.25); }

  .modal-header-inner { display: flex; align-items: center; gap: 16px; }
  .modal-avatar {
    width: 56px; height: 56px; border-radius: 50%; flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif; font-size: 20px; font-weight: 800;
    border: 3px solid rgba(255,255,255,0.25);
  }
  .modal-author-name { font-family: 'Playfair Display', serif; font-size: 19px; font-weight: 700; color: white; margin-bottom: 2px; line-height: 1.2; }
  .modal-author-role { font-size: 12px; color: rgba(255,255,255,0.65); font-weight: 300; margin-bottom: 4px; }
  .modal-author-email { font-size: 11px; color: rgba(255,255,255,0.5); }

  .modal-stats-row { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-top: 14px; padding-top: 14px; border-top: 1px solid rgba(255,255,255,0.12); flex-wrap: wrap; }
  .modal-stats-group { display: flex; gap: 22px; }
  .modal-stat-val { font-family: 'Nunito', sans-serif; font-size: 19px; font-weight: 800; color: white; line-height: 1; }
  .modal-stat-lbl { font-size: 9px; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 0.8px; margin-top: 2px; font-weight: 300; }

  .modal-follow-btn { display: inline-flex; align-items: center; gap: 6px; background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.3); color: white; font-family: 'DM Sans', sans-serif; font-size: 12px; font-weight: 600; padding: 7px 16px; border-radius: 2px; cursor: pointer; transition: all 0.2s; white-space: nowrap; }
  .modal-follow-btn:hover { background: rgba(255,255,255,0.26); }
  .modal-follow-btn.following { background: var(--gold); border-color: var(--gold); color: var(--moss-dark); }
  .modal-follow-btn.following:hover { background: var(--gold-light); }

  .modal-body { padding: 18px 28px; overflow-y: auto; }
  .modal-section { margin-bottom: 14px; }
  .modal-section:last-child { margin-bottom: 0; }
  .modal-section-title { font-size: 10px; text-transform: uppercase; letter-spacing: 1.3px; color: var(--text-light); font-weight: 600; margin-bottom: 8px; }
  .modal-bio-text { font-size: 13px; color: var(--text-mid); line-height: 1.55; font-weight: 300; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }

  .modal-tags { display: flex; flex-wrap: wrap; gap: 6px; }
  .modal-tag { font-size: 11px; padding: 4px 12px; border-radius: 20px; background: rgba(74,94,58,0.1); color: var(--moss); font-weight: 500; border: 1px solid rgba(74,94,58,0.15); }

  .modal-social-row { display: flex; gap: 8px; flex-wrap: wrap; }
  .social-btn { display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; border: 1.5px solid var(--cream-dark); border-radius: 2px; font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500; color: var(--text-mid); text-decoration: none; transition: all 0.2s; }
  .social-btn:hover { border-color: var(--moss); color: var(--moss); background: rgba(74,94,58,0.05); }

  .modal-footer { padding: 12px 28px; border-top: 1px solid var(--cream-dark); background: rgba(245,240,232,0.4); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
  .member-since { font-size: 11px; color: var(--text-light); font-weight: 300; }

  .pagination { display: flex; align-items: center; justify-content: space-between; padding: 18px 4px 4px; margin-top: 8px; }
  .pag-info { font-size: 12px; color: var(--text-light); font-weight: 300; }
  .pag-btns { display: flex; gap: 4px; }
  .pag-btn { min-width: 32px; height: 32px; padding: 0 8px; border: 1.5px solid var(--cream-dark); background: var(--warm-white); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 12px; cursor: pointer; color: var(--text-mid); font-family: 'Nunito', sans-serif; font-weight: 700; transition: all 0.15s; }
  .pag-btn:hover:not(:disabled) { border-color: var(--moss); color: var(--moss); }
  .pag-btn.active { background: var(--moss); border-color: var(--moss); color: var(--cream); }
  .pag-btn:disabled { opacity: 0.4; cursor: not-allowed; }

  @media (max-width: 1280px) { .authors-grid { grid-template-columns: 1fr 1fr; } }
  @media (max-width: 860px)  { .authors-grid { grid-template-columns: 1fr; } }
  @media (max-width: 768px)  { .sidebar { display: none; } .main { margin-left: 0; } .content { padding: 24px 20px; } .topbar { padding: 0 20px; } .pagination { flex-direction: column; gap: 10px; align-items: flex-start; } }
  @media (max-width: 480px)  { .modal-social-row { flex-wrap: wrap; } .modal-stats-row { flex-direction: column; align-items: flex-start; gap: 10px; } .modal-follow-btn { align-self: stretch; justify-content: center; } }
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">

  <div class="topbar">
    <div class="page-crumb">
      <span>Principal</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Autores</span>
    </div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Todos os <em>Autores</em></div>
      </div>
      <span class="section-count" id="countLabel"><%= listaAutores.size() %> autores encontrados</span>
    </div>

    <div class="toolbar">
      <div class="search-bar">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" id="campoBuscaAutor" placeholder="Buscar autores…">
      </div>
      <select class="filter-select" id="filterEspecialidade">
        <option value="todos" selected>Todas as especialidades</option>
<%
        for (Categoria cat : especialidadesFiltro) {
            String nomeCat = cat.getNome_categoria() != null ? cat.getNome_categoria() : "";
            if (nomeCat.trim().isEmpty()) continue; // sem nome, nao da pra filtrar por ela
            String valorOpcao = nomeCat.toLowerCase();
            String emoji = cat.getEmoji_categoria() != null ? cat.getEmoji_categoria() + " " : "";
%>
        <option value="<%= valorOpcao %>"><%= emoji %><%= nomeCat %></option>
<%
        }
%>
      </select>
      <div class="toolbar-spacer"></div>
    </div>

    <div class="authors-grid" id="authorsGrid">
<%
    for (int i = 0; i < listaAutores.size(); i++) {
        Usuario autor = listaAutores.get(i);
        String bannerClass = bannerClasses[i % bannerClasses.length];
        String avatarClass = avatarClasses[i % avatarClasses.length];
        String inicial = (autor.getNome_usuario() != null && !autor.getNome_usuario().isEmpty())
                ? autor.getNome_usuario().substring(0, 1).toUpperCase() : "?";

        List<String> especialidades = (especialidadesPorAutor != null)
                ? especialidadesPorAutor.get(autor.getId_usuario()) : null;

        String dataCategorias = "";
        if (especialidades != null) {
            StringBuilder cats = new StringBuilder();
            for (int e = 0; e < especialidades.size(); e++) {
                if (e > 0) cats.append(",");
                cats.append(especialidades.get(e).toLowerCase());
            }
            dataCategorias = cats.toString();
        }
%>
      <div class="author-card" data-author-id="<%= autor.getId_usuario() %>" data-categories="<%= dataCategorias %>" data-name="<%= autor.getNome_usuario().toLowerCase() %>">
        <div class="card-banner <%= bannerClass %>"><div class="banner-pattern"></div></div>
        <div class="card-body-inner">
          <div class="author-avatar-wrap">
            <div class="author-avatar <%= avatarClass %>"><%= inicial %><%
                if (autor.getTipo_usuario() == TipoUsuario.ADMIN) {
            %><div class="verified-dot">✓</div><%
                }
            %></div>
          </div>
          <div class="author-name"><%= autor.getNome_usuario() %></div>
          <div class="author-title"><%= autor.getTitulo_usuario() != null ? autor.getTitulo_usuario() : "" %></div>
        </div>
        <div class="card-footer">
          <button class="footer-btn" onclick="openModal(<%= autor.getId_usuario() %>)">👁 Ver</button>
          <%-- ASSUNÇÃO: rota provável seguindo o padrão do projeto
               (Controller?param=valor). Ajusta o href se o nome real
               do controller/parâmetro que serve autor-detalhe.jsp for
               diferente. --%>
          <a class="footer-btn" href="<%= _ctx %>/AutorController?id=<%= autor.getId_usuario() %>">📄 Perfil completo</a>
        </div>
      </div>
<%
    }
%>
    </div><!-- /authors-grid -->

    <div id="emptyState" style="display:none; text-align:center; padding: 60px 20px;">
      <div style="font-size:48px; margin-bottom:16px;" id="emptyStateIcon">🔍</div>
      <div style="font-family:'Playfair Display',serif; font-size:20px; font-weight:700; color:var(--text-dark); margin-bottom:8px;" id="emptyStateTitle">Nenhum autor encontrado</div>
      <div style="font-size:14px; color:var(--text-light); font-weight:300;" id="emptyStateText">Tente buscar por outro nome ou especialidade.</div>
    </div>

    <div class="pagination" id="pagination">
      <div class="pag-info" id="pagInfo">—</div>
      <div class="pag-btns" id="pagBtns"></div>
    </div>

  </div>
</main>

<%
    for (int i = 0; i < listaAutores.size(); i++) {
        Usuario autor = listaAutores.get(i);
        String avatarClass = avatarClasses[i % avatarClasses.length];
        String inicial = (autor.getNome_usuario() != null && !autor.getNome_usuario().isEmpty())
                ? autor.getNome_usuario().substring(0, 1).toUpperCase() : "?";

        List<String> especialidades = (especialidadesPorAutor != null)
                ? especialidadesPorAutor.get(autor.getId_usuario()) : null;

        String membroDesde = (autor.getData_criacao_usuario() != null)
                ? capitalizar(autor.getData_criacao_usuario().format(memberFmt)) : "";
%>
<div class="modal-overlay" id="modalAutor<%= autor.getId_usuario() %>" onclick="closeModal(<%= autor.getId_usuario() %>, event)">
  <div class="modal-profile">
    <div class="modal-header">
      <button class="modal-close-btn" onclick="closeModalDirect(<%= autor.getId_usuario() %>)">✕</button>
      <div class="modal-header-inner">
        <div class="modal-avatar <%= avatarClass %>"><%= inicial %></div>
        <div>
          <div class="modal-author-name"><%= autor.getNome_usuario() %></div>
          <div class="modal-author-role"><%= autor.getTitulo_usuario() != null ? autor.getTitulo_usuario() : "" %></div>
          <div class="modal-author-email"><%= autor.getUsername_usuario() %><%= autor.getLocalizacao_usuario() != null && !autor.getLocalizacao_usuario().isEmpty() ? " · " + autor.getLocalizacao_usuario() : "" %></div>
        </div>
      </div>
      <div class="modal-stats-row">
        <div class="modal-stats-group">
          <div class="hero-stat"><div class="modal-stat-val"><%= autor.getTotal_receitas_publicadas() %></div><div class="modal-stat-lbl">Receitas publicadas</div></div>
          <div class="hero-stat"><div class="modal-stat-val"><%= autor.getTotal_comentarios() %></div><div class="modal-stat-lbl">Comentários</div></div>
          <div class="hero-stat"><div class="modal-stat-val"><%= autor.getTotal_visualizacoes() %></div><div class="modal-stat-lbl">Visualizações</div></div>
        </div>
<%
        if (logado) {
            boolean jaSegueEsteAutor = Boolean.TRUE.equals(seguindoPorAutor.get(autor.getId_usuario()));
%>
        <button class="modal-follow-btn<%= jaSegueEsteAutor ? " following" : "" %>"
                id="followBtn_<%= autor.getId_usuario() %>"
                onclick="toggleFollow(<%= autor.getId_usuario() %>, this)">
          <span class="follow-icon"><%= jaSegueEsteAutor ? "✓" : "+" %></span>
          <span class="follow-label"><%= jaSegueEsteAutor ? "Seguindo" : "Seguir" %></span>
        </button>
<%
        }
%>
      </div>
    </div>
    <div class="modal-body">
      <div class="modal-section">
        <div class="modal-section-title">Sobre</div>
        <div class="modal-bio-text"><%= autor.getBio_usuario() != null ? autor.getBio_usuario() : "" %></div>
      </div>
<%
        if (especialidades != null && !especialidades.isEmpty()) {
%>
      <div class="modal-section">
        <div class="modal-section-title">Especialidades</div>
        <div class="modal-tags">
<%
            for (String esp : especialidades) {
%>
          <span class="modal-tag"><%= esp %></span>
<%
            }
%>
        </div>
      </div>
<%
        }
%>
      <%-- TODO: "Últimas receitas publicadas" (modal-recipes-grid) — precisa de
           ReceitaDAO.listarUltimasPorAutor(id_usuario) pra virar List<Receita> aqui. --%>
<%
        boolean temRedeSocial = (autor.getInstagram_usuario() != null && !autor.getInstagram_usuario().isEmpty())
                || (autor.getYoutube_usuario() != null && !autor.getYoutube_usuario().isEmpty())
                || (autor.getPinterest_usuario() != null && !autor.getPinterest_usuario().isEmpty());
        if (temRedeSocial) {
%>
      <div class="modal-section" style="margin-bottom:0">
        <div class="modal-section-title">Redes sociais</div>
        <div class="modal-social-row">
<%
            if (autor.getInstagram_usuario() != null && !autor.getInstagram_usuario().isEmpty()) {
%>
          <a class="social-btn" href="https://instagram.com/<%= autor.getInstagram_usuario() %>" target="_blank">📷 <%= autor.getInstagram_usuario() %></a>
<%
            }
            if (autor.getYoutube_usuario() != null && !autor.getYoutube_usuario().isEmpty()) {
%>
          <a class="social-btn" href="<%= autor.getYoutube_usuario() %>" target="_blank">▶️ YouTube</a>
<%
            }
            if (autor.getPinterest_usuario() != null && !autor.getPinterest_usuario().isEmpty()) {
%>
          <a class="social-btn" href="<%= autor.getPinterest_usuario() %>" target="_blank">📌 Pinterest</a>
<%
            }
%>
        </div>
      </div>
<%
        }
%>
    </div>
    <div class="modal-footer">
      <span class="member-since"><%= !membroDesde.isEmpty() ? "Membro desde " + membroDesde : "" %></span>
    </div>
  </div>
</div>
<%
    }
%>

<script>
  function openModal(id) {
    var el = document.getElementById('modalAutor' + id);
    if (el) {
      el.classList.add('show');
      document.body.style.overflow = 'hidden';
    }
  }

  function closeModal(id, e) {
    if (e.target === document.getElementById('modalAutor' + id)) closeModalDirect(id);
  }

  function closeModalDirect(id) {
    var el = document.getElementById('modalAutor' + id);
    if (el) { el.classList.remove('show'); document.body.style.overflow = ''; }
  }

  // ================= SEGUIR AUTOR (só existe pro visitante logado) =================
  // Manda action=toggle pro SeguidorController via POST/AJAX (header
  // X-Requested-With), que responde texto puro "seguindo" ou "naoSegue".
  // O botão só muda de fato depois da resposta do servidor confirmar —
  // assim a tela nunca fica "seguindo" na UI sem estar seguindo no banco.
  function toggleFollow(id, btn) {
    if (btn.disabled) return;
    btn.disabled = true;

    var params = new URLSearchParams();
    params.set('action', 'toggle');
    params.set('idSeguido', id);

    fetch('<%= _ctx %>/SeguidorController', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: params.toString()
    })
      .then(function(resp) {
        if (!resp.ok) throw new Error('Falha ao seguir/deixar de seguir.');
        return resp.text();
      })
      .then(function(estado) {
        var icon = btn.querySelector('.follow-icon');
        var label = btn.querySelector('.follow-label');
        var seguindoAgora = (estado === 'seguindo');

        btn.classList.toggle('following', seguindoAgora);
        icon.textContent = seguindoAgora ? '✓' : '+';
        label.textContent = seguindoAgora ? 'Seguindo' : 'Seguir';
      })
      .catch(function(err) {
        console.error(err);
        alert('Não foi possível atualizar o "seguir" agora. Tente de novo em instantes.');
      })
      .finally(function() {
        btn.disabled = false;
      });
  }

  // ================= FILTRO + BUSCA + PAGINAÇÃO =================
  var PAGE_SIZE = 6;
  var paginaAtual = 1;
  var categoriaAtual = 'todos';
  var todosCards = Array.from(document.querySelectorAll('#authorsGrid .author-card'));

  function getCardsFiltrados() {
    var termo = document.getElementById('campoBuscaAutor').value.trim().toLowerCase();
    return todosCards.filter(function(card) {
      var nome = card.dataset.name || '';
      var cats = card.dataset.categories || '';
      var bateCategoria = (categoriaAtual === 'todos') || cats.split(',').indexOf(categoriaAtual) >= 0;
      var bateBusca = !termo || nome.indexOf(termo) >= 0 || cats.indexOf(termo) >= 0;
      return bateCategoria && bateBusca;
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

    document.getElementById('countLabel').textContent = filtrados.length + (filtrados.length === 1 ? ' autor encontrado' : ' autores encontrados');
    document.getElementById('emptyState').style.display = filtrados.length === 0 ? 'block' : 'none';

    renderInfo(filtrados.length, inicio, fim);
    renderBotoes(totalPaginas);
  }

  function renderInfo(total, inicio, fim) {
    var info = document.getElementById('pagInfo');
    if (total === 0) { info.textContent = 'Nenhum autor encontrado'; return; }
    var mostrandoAte = Math.min(fim, total);
    info.textContent = 'Mostrando ' + (inicio + 1) + '–' + mostrandoAte + ' de ' + total;
  }

  function renderBotoes(totalPaginas) {
    var wrap = document.getElementById('pagBtns');
    wrap.innerHTML = '';

    function criarBtn(label, page, opts) {
      opts = opts || {};
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'pag-btn' + (opts.active ? ' active' : '');
      b.textContent = label;
      if (opts.disabled) b.disabled = true;
      b.addEventListener('click', function() { paginaAtual = page; renderPagina(); });
      wrap.appendChild(b);
    }

    criarBtn('‹', paginaAtual - 1, { disabled: paginaAtual === 1 });
    for (var p = 1; p <= totalPaginas; p++) { criarBtn(String(p), p, { active: p === paginaAtual }); }
    criarBtn('›', paginaAtual + 1, { disabled: paginaAtual === totalPaginas });
  }

  document.getElementById('campoBuscaAutor').addEventListener('input', function() { paginaAtual = 1; renderPagina(); });
  document.getElementById('filterEspecialidade').addEventListener('change', function() { categoriaAtual = this.value; paginaAtual = 1; renderPagina(); });

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('.modal-overlay.show').forEach(function(el) {
        el.classList.remove('show');
      });
      document.body.style.overflow = '';
    }
  });

  renderPagina();
</script>
</body>
</html>
