<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>

<%--
  ============================================================================
  sidebar.jsp — menu lateral UNIVERSAL (PUBLICO / ADMIN / EDITOR / AUTOR / VISITANTE)
  ----------------------------------------------------------------------------
  Como usar em qualquer tela do sistema:

    <%
      request.setAttribute("currentPage", "perfil"); // chave da tela atual
    %>
    <jsp:include page="/pages/includes/sidebar.jsp" />

  Pre-requisitos:
    - session.getAttribute("usuarioLogado")  -> objeto Usuario (sempre setado
      no login; aqui so' e' lido, nao e' buscado nada no banco). Se for null,
      trata-se de visitante PUBLICO (ninguem logado) - sidebar mostra
      "Cadastre-se / Entrar" no lugar do card de usuario e um menu proprio.
    - request.getAttribute("currentPage")    -> String opcional, usada so'
      pra destacar (.active) o item de menu correspondente. Chaves aceitas:
      "dashboard", "usuarios", "categorias", "receitas", "relatorios",
      "auditoria", "comentarios", "mensagens", "home", "autores",
      "favoritas", "perfil", "configuracoes", "sobre" (essa ultima so' no
      menu publico)

  IMPORTANTE: "VISITANTE" (tipo_usuario = VISITANTE, alguem que se cadastrou
  como leitor) e' diferente de PUBLICO (ninguem logado). O visitante logado
  ve o menu de conta normal (favoritas, perfil, sair); o publico ve o menu
  institucional com "Cadastre-se / Entrar" e sem opcao de sair.

  O CSS das classes .sidebar, .nav-item etc. agora esta' embutido neste
  arquivo (bloco <style> abaixo, baseado no design system usado em
  sidebar-autor.html), entao o sidebar.jsp e' autossuficiente e nao depende
  mais do <style> de cada pagina que o inclui.
  ============================================================================
--%>

<%!
  /* Retorna "nav-item active" se a chave bater com a pagina atual, senao "nav-item" */
  private String navClass(String chave, String currentPage) {
    if (chave != null && chave.equals(currentPage)) return "nav-item active";
    return "nav-item";
  }

  /* Resolve o caminho da foto do usuario vindo do banco, prefixando o
     context path (igual home.jsp/usuarios.jsp). Sem isso, caminhos
     relativos tipo "/uploads/avatars/x.jpg" quebravam a imagem. */
  private String resolveFotoUrl(String ctx, String path) {
    if (path == null || path.trim().isEmpty()) return null;
    if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
      return path;
    }
    String p = path.startsWith("/") ? path : "/" + path;
    return ctx + p + "?v=" + System.currentTimeMillis();
  }
%>

<%
  Usuario u = (Usuario) session.getAttribute("usuarioLogado");
  boolean logado = (u != null);
  if (u == null) u = new Usuario();

  // "PUBLICO" = ninguem logado. So' vira VISITANTE/AUTOR/EDITOR/ADMIN quando
  // existe usuario de fato na sessao - antes disso tudo caia no mesmo "else"
  // do VISITANTE logado, por isso o publico aparecia com o menu errado.
  String tipo = logado
      ? ((u.getTipo_usuario() != null) ? u.getTipo_usuario().toString() : "VISITANTE")
      : "PUBLICO";

  String currentPage = (String) request.getAttribute("currentPage");
  if (currentPage == null) currentPage = "";

  String _ctx = request.getContextPath();

  String inicialNome = "?";
  if (u.getNome_usuario() != null && u.getNome_usuario().length() > 0) {
    inicialNome = u.getNome_usuario().substring(0, 1).toUpperCase();
  }

  String nomeExibicao = (u.getNome_usuario() != null) ? u.getNome_usuario() : "";
  String fotoUrl = resolveFotoUrl(_ctx, u.getFoto_usuario());

  String badgeLabel;
  String badgeEmoji;
  if ("ADMIN".equals(tipo)) {
    badgeLabel = "Administrador"; badgeEmoji = "\uD83D\uDC51";
  } else if ("EDITOR".equals(tipo)) {
    badgeLabel = "Editor/Moderador"; badgeEmoji = "\uD83D\uDD11";
  } else if ("AUTOR".equals(tipo)) {
    badgeLabel = "Autor"; badgeEmoji = "\u270D\uFE0F";
  } else {
    badgeLabel = "Visitante"; badgeEmoji = "";
  }
%>

<aside class="sidebar" id="sidebar" data-role="<%= tipo.toLowerCase() %>">
<style>
  :root {
    --moss:#4a5e3a; --moss-dark:#2f3d25; --moss-mid:#3d5030; --moss-light:#6b7f59;
    --sage:#a3b18a; --sage-light:#c8d5b9; --cream:#f5f0e8; --cream-dark:#e6dece;
    --warm-white:#faf8f4; --text-dark:#1e2718; --text-mid:#4a5240; --text-light:#8a9480;
    --gold:#c4a265; --gold-light:#dfc094;
    --sidebar-w: 260px;
  }

  .sidebar { width: var(--sidebar-w); background: var(--moss-dark); display: flex; flex-direction: column; position: fixed; top: 0; left: 0; bottom: 0; z-index: 100; overflow-y: auto; font-family: 'DM Sans', sans-serif; }
  .sidebar::before { content: ''; position: absolute; inset: 0; background: radial-gradient(ellipse 200% 60% at 50% 0%, rgba(74,94,58,.5) 0%, transparent 60%), radial-gradient(ellipse 100% 40% at 50% 100%, rgba(163,177,138,.1) 0%, transparent 60%); pointer-events: none; }

  .sidebar-brand { padding: 28px 24px 22px; border-bottom: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; }
  .brand-row { display: flex; align-items: center; gap: 12px; }
  .brand-badge { width: 38px; height: 38px; background: linear-gradient(135deg, var(--moss-light), var(--sage)); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
  .brand-title { font-family: 'Playfair Display', serif; font-size: 18px; font-weight: 700; color: var(--cream); display: block; line-height: 1; }
  .brand-sub { font-size: 10px; color: var(--sage); text-transform: uppercase; letter-spacing: 1.2px; margin-top: 3px; display: block; font-weight: 300; }

  /* card do usuario logado */
  .sidebar-user { padding: 16px 24px; border-bottom: 1px solid rgba(255,255,255,.07); display: flex; align-items: center; gap: 12px; position: relative; z-index: 1; transition: background .2s; }
  .sidebar-user:hover { background: rgba(255,255,255,.04); }
  .user-avatar { width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-family: 'Nunito', sans-serif; font-weight: 800; font-size: 14px; color: white; flex-shrink: 0; overflow: hidden; }
  .user-avatar img { width: 100%; height: 100%; object-fit: cover; border-radius: 50%; }
  .user-info { flex: 1; min-width: 0; }
  .user-name { font-size: 13px; font-weight: 600; color: var(--cream); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .user-role-badge { font-size: 10px; color: var(--sage-light); text-transform: uppercase; letter-spacing: .8px; font-weight: 300; }

  a.sidebar-user, a.sidebar-user:link, a.sidebar-user:visited, a.sidebar-user:hover, a.sidebar-user:active {
    text-decoration: none; color: inherit;
  }

  /* card "Cadastre-se / Entrar" pra quem nao esta logado (PUBLICO) */
  .sidebar-auth { padding: 18px 24px; border-bottom: 1px solid rgba(255,255,255,.07); display: flex; flex-direction: column; gap: 8px; position: relative; z-index: 1; }
  .sidebar-auth-hint { font-size: 11px; color: rgba(245,240,232,.55); font-weight: 300; margin-bottom: 2px; }
  .btn-sidebar { display: flex; align-items: center; justify-content: center; gap: 8px; width: 100%; padding: 9px 14px; border-radius: 2px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; cursor: pointer; text-decoration: none; transition: all .2s; }
  .btn-sidebar-solid { background: var(--gold); color: var(--moss-dark); }
  .btn-sidebar-solid:hover { background: var(--gold-light); }
  .btn-sidebar-outline { background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.15); color: rgba(245,240,232,.85); }
  .btn-sidebar-outline:hover { background: rgba(255,255,255,.12); }

  .sidebar-nav { flex: 1; padding: 16px 0; position: relative; z-index: 1; }
  .nav-section-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1.8px; color: rgba(163,177,138,.5); padding: 16px 24px 6px; font-weight: 500; }
  .nav-item { display: flex; align-items: center; gap: 12px; padding: 11px 24px; color: rgba(245,240,232,.7); text-decoration: none; font-size: 14px; font-weight: 400; cursor: pointer; transition: all .2s; border-left: 3px solid transparent; }
  .nav-item:hover { color: var(--cream); background: rgba(255,255,255,.06); border-left-color: var(--sage); }
  .nav-item.active { color: var(--cream); background: rgba(163,177,138,.15); border-left-color: var(--sage-light); font-weight: 500; }
  .nav-icon { width: 22px; text-align: center; font-size: 16px; flex-shrink: 0; }
  .nav-label { flex: 1; }

  .sidebar-bottom { padding: 16px 24px 24px; border-top: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; font-size: 11px; color: rgba(245,240,232,.45); font-weight: 300; }
  .btn-logout { display: flex; align-items: center; gap: 10px; width: 100%; padding: 10px 16px; background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.1); border-radius: 2px; color: rgba(245,240,232,.7); font-family: 'DM Sans', sans-serif; font-size: 13px; cursor: pointer; transition: all .2s; text-decoration: none; }
  .btn-logout:hover { background: rgba(155,68,68,.2); border-color: rgba(155,68,68,.3); color: #e8a0a0; }

  @media (max-width: 768px) {
    .sidebar { display: none; }
  }
</style>

  <div class="sidebar-brand">
    <div class="brand-row">
      <div class="brand-badge">🌿</div>
      <div>
        <span class="brand-title">Sabor &amp; Arte</span>
        <span class="brand-sub">Blog Editorial</span>
      </div>
    </div>
  </div>

  <% if (logado) { %>
    <a href="<%= _ctx %>/PerfilController" class="sidebar-user" title="Meu perfil">
      <div class="user-avatar" style="background:linear-gradient(135deg,#e74c3c,#c0392b);">
        <% if (fotoUrl != null) { %>
          <img src="<%= fotoUrl %>" alt="<%= nomeExibicao %>">
        <% } else { %>
          <%= inicialNome %>
        <% } %>
      </div>
      <div class="user-info">
        <div class="user-name"><%= nomeExibicao %></div>
        <div class="user-role-badge"><%= badgeEmoji %> <%= badgeLabel %></div>
      </div>
    </a>
  <% } else { %>
    <div class="sidebar-auth">
      <div class="sidebar-auth-hint">Faça parte da nossa comunidade</div>
      <a href="<%= _ctx %>/pages/cadastro.jsp" class="btn-sidebar btn-sidebar-solid">Cadastre-se</a>
      <a href="<%= _ctx %>/login.jsp" class="btn-sidebar btn-sidebar-outline">Entrar</a>
    </div>
  <% } %>

  <nav class="sidebar-nav">

    <% if ("PUBLICO".equals(tipo)) { %>

      <div class="nav-section-label">Principal</div>
      <a href="<%= _ctx %>/HomeController" class="<%= navClass("home", currentPage) %>"><span class="nav-icon">🏠</span><span class="nav-label">Início</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/AutorController" class="<%= navClass("autores", currentPage) %>"><span class="nav-icon">👩‍🍳</span><span class="nav-label">Autores</span></a>

      <div class="nav-section-label">Sobre</div>
        <a href="/saborearte/pages/html/publico/sobre.html" class="<%= navClass("sobre", currentPage) %>"><span class="nav-icon">ℹ️</span><span class="nav-label">Sobre o Sabor &amp; Arte</span></a>
        
    <% } else if ("ADMIN".equals(tipo)) { %>

      <div class="nav-section-label">Principal</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Gestão</div>
      <a href="<%= _ctx %>/UsuarioController" class="<%= navClass("usuarios", currentPage) %>"><span class="nav-icon">👥</span><span class="nav-label">Usuários</span></a>
      <a href="<%= _ctx %>/CategoriaController" class="<%= navClass("categorias", currentPage) %>"><span class="nav-icon">🏷️</span><span class="nav-label">Categorias</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>
      <a href="<%= _ctx %>/LogController" class="<%= navClass("auditoria", currentPage) %>"><span class="nav-icon">🔍</span><span class="nav-label">Auditoria</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else if ("EDITOR".equals(tipo)) { %>

      <div class="nav-section-label">Visão Geral</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Gestão</div>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/ComentarioController" class="<%= navClass("comentarios", currentPage) %>"><span class="nav-icon">💬</span><span class="nav-label">Comentários</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else if ("AUTOR".equals(tipo)) { %>

      <div class="nav-section-label">Visão Geral</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Conteúdo</div>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📖</span><span class="nav-label">Minhas Receitas</span></a>
      <a href="<%= _ctx %>/MensagemController" class="<%= navClass("mensagens", currentPage) %>"><span class="nav-icon">💬</span><span class="nav-label">Mensagens</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else { %>
      <%-- VISITANTE logado (cadastrado como leitor) - PUBLICO ja' foi tratado acima --%>

      <div class="nav-section-label">Explorar</div>
      <a href="<%= _ctx %>/HomeController" class="<%= navClass("home", currentPage) %>"><span class="nav-icon">🏠</span><span class="nav-label">Home</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/AutorController" class="<%= navClass("autores", currentPage) %>"><span class="nav-icon">✍️</span><span class="nav-label">Autores</span></a>
      <a href="<%= _ctx %>/FavoritoController" class="<%= navClass("favoritas", currentPage) %>"><span class="nav-icon">⭐</span><span class="nav-label">Favoritas</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } %>

  </nav>

  <div class="sidebar-bottom">
    <% if (logado) { %>
      <a href="<%= _ctx %>/LogoutController" class="btn-logout"><span class="nav-icon">🚪</span><span>Sair</span></a>
    <% } else { %>
      © 2026 Sabor &amp; Arte
    <% } %>
  </div>

</aside>
