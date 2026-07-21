<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%
    Usuario _u    = (Usuario) session.getAttribute("usuarioLogado");
    String  _nome = (_u != null) ? _u.getNome_usuario() : "Usuário";
    String  _ini  = _nome.substring(0, 1).toUpperCase();
    String  _ctx  = request.getContextPath();

    Integer _pendReceita = (Integer) session.getAttribute("receitasPendentes");
    Integer _naoLidas    = (Integer) session.getAttribute("notifNaoLidas");
    int _receitaNr  = (_pendReceita != null) ? _pendReceita : 0;
    int _notifNr    = (_naoLidas    != null) ? _naoLidas    : 0;

    String currentPage = (String) request.getAttribute("currentPage");
    if (currentPage == null) {
        String sp = request.getServletPath();
        if      (sp.contains("dashboard"))    currentPage = "dashboard";
        else if (sp.contains("usuario"))      currentPage = "usuarios";
        else if (sp.contains("receita"))      currentPage = "receitas";
        else if (sp.contains("categoria"))    currentPage = "categorias";
        else if (sp.contains("comentario"))   currentPage = "comentarios";
        else if (sp.contains("relatorio"))    currentPage = "relatorios";
        else if (sp.contains("auditoria"))    currentPage = "auditoria";
        else if (sp.contains("configuracao"))  currentPage = "configuracoes";
        else if (sp.contains("perfil"))       currentPage = "perfil";
        else                                  currentPage = "dashboard";
    }

    String _fotoLogado = (_u != null && _u.getFoto_usuario() != null
                          && !_u.getFoto_usuario().isEmpty())
                         ? _ctx + _u.getFoto_usuario()
                         : null;
%>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar()"></div>

<aside class="sidebar" id="sidebar" data-role="admin">

    <div class="sidebar-brand">
        <div class="brand-row">
            <div class="brand-badge">🌿</div>
            <div>
                <span class="brand-title">Sabor &amp; Arte</span>
                <span class="brand-sub">Administração</span>
            </div>
        </div>
    </div>

    <div class="sidebar-user" onclick="irParaPerfil()" style="cursor:pointer;" title="Meu perfil">
        <div class="user-avatar" style="background:linear-gradient(135deg,#e74c3c,#c0392b);overflow:hidden;padding:0;">
          <% if (_fotoLogado != null) { %>
            <img src="<%= _fotoLogado %>"
                 style="width:100%;height:100%;object-fit:cover;border-radius:50%;"
                 alt="<%= _ini %>">
          <% } else { %>
            <%= _ini %>
          <% } %>
        </div>
        <div class="user-info">
            <div class="user-name"><%= _nome %></div>
            <div class="user-role-badge">👑 Administrador</div>
        </div>
        <% if (_notifNr > 0) { %>
            <span class="user-notif-badge"><%= _notifNr > 99 ? "99+" : _notifNr %></span>
        <% } %>
    </div>

    <nav class="sidebar-nav">

        <div class="nav-section-label">Visão Geral</div>

        <a href="<%= _ctx %>/pages/html/admin/dashboard-admin.html"
           class="nav-item <%= "dashboard".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">📊</span>
            <span class="nav-label">Dashboard</span>
        </a>

        <div class="nav-section-label">Gestão</div>

        <a href="<%= _ctx %>/UsuarioController"
           class="nav-item <%= "usuarios".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">👥</span>
            <span class="nav-label">Usuários</span>
        </a>

        <a href="<%= _ctx %>/CategoriaController"
           class="nav-item <%= "categorias".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">🏷️</span>
            <span class="nav-label">Categorias</span>
        </a>

        <a href="<%= _ctx %>/pages/html/admin/receita-admin.html"
           class="nav-item <%= "receitas".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">📝</span>
            <span class="nav-label">Receitas</span>
            <% if (_receitaNr > 0) { %>
                <span class="nav-badge"><%= _receitaNr > 99 ? "99+" : _receitaNr %></span>
            <% } %>
        </a>

        <div class="nav-section-label">Análise</div>

        <a href="<%= _ctx %>/pages/html/admin/relatorio-admin.html"
           class="nav-item <%= "relatorios".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">📈</span>
            <span class="nav-label">Relatórios</span>
        </a>

        <a href="<%= _ctx %>/pages/html/admin/log-admin.html"
           class="nav-item <%= "auditoria".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">🔍</span>
            <span class="nav-label">Auditoria</span>
        </a>

        <div class="nav-section-label">Conta</div>

        <a href="<%= _ctx %>/ConfiguracaoController"
           class="nav-item <%= "configuracoes".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">⚙️</span>
            <span class="nav-label">Configurações</span>
        </a>

    </nav>

    <div class="sidebar-bottom">
        <button class="btn-logout" onclick="logout()">
            <span class="nav-icon">🚪</span>
            <span>Sair</span>
        </button>
    </div>

</aside>

<style>

    .sidebar[data-role="admin"] { --role-color: #e74c3c; --role-color-soft: rgba(231,76,60,.15); }

    .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(30,39,24,.45); z-index: 99; backdrop-filter: blur(2px); }
    .sidebar-overlay.active { display: block; }

    .sidebar { width: var(--sidebar-w); background: var(--moss-dark); display: flex; flex-direction: column; position: fixed; top: 0; left: 0; bottom: 0; z-index: 100; overflow-y: auto; font-family: 'DM Sans', sans-serif; transition: transform .28s cubic-bezier(.25,.46,.45,.94); }
    .sidebar::before { content: ''; position: absolute; inset: 0; background: radial-gradient(ellipse 200% 60% at 50% 0%, rgba(74,94,58,.5) 0%, transparent 60%), radial-gradient(ellipse 100% 40% at 50% 100%, rgba(163,177,138,.1) 0%, transparent 60%); pointer-events: none; }

    .sidebar::after { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; background: var(--role-color, var(--sage)); z-index: 2; }

    .sidebar-brand { padding: 28px 24px 18px; border-bottom: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; }
    .brand-row { display: flex; align-items: center; gap: 12px; }
    .brand-badge { width: 38px; height: 38px; background: linear-gradient(135deg, var(--moss-light), var(--sage)); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
    .brand-title { font-family: 'Playfair Display', serif; font-size: 18px; font-weight: 700; color: var(--cream); display: block; line-height: 1; }
    .brand-sub { font-size: 10px; color: var(--sage); text-transform: uppercase; letter-spacing: 1.2px; margin-top: 3px; display: block; font-weight: 300; }

    .sidebar-user { padding: 14px 24px; border-bottom: 1px solid rgba(255,255,255,.07); display: flex; align-items: center; gap: 12px; position: relative; z-index: 1; transition: background .2s; }
    .sidebar-user:hover { background: rgba(255,255,255,.04); }
    .user-avatar { width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-family: 'Nunito', sans-serif; font-weight: 800; font-size: 14px; color: white; flex-shrink: 0; }
    .user-info { flex: 1; min-width: 0; }
    .user-name { font-size: 13px; font-weight: 600; color: var(--cream); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .user-role-badge { font-size: 10px; color: var(--sage-light); text-transform: uppercase; letter-spacing: .8px; font-weight: 300; }
    .user-notif-badge { width: 20px; height: 20px; background: var(--role-color, #e74c3c); color: #fff; font-family: 'Nunito', sans-serif; font-size: 10px; font-weight: 800; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

    .sidebar-nav { flex: 1; padding: 12px 0; position: relative; z-index: 1; }
    .nav-section-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1.8px; color: rgba(163,177,138,.5); padding: 14px 24px 5px; font-weight: 500; }
    .nav-item { display: flex; align-items: center; gap: 12px; padding: 10px 24px; color: rgba(245,240,232,.7); text-decoration: none; font-size: 14px; font-weight: 400; cursor: pointer; transition: all .2s; border-left: 3px solid transparent; }
    .nav-item:hover { color: var(--cream); background: rgba(255,255,255,.06); border-left-color: var(--sage); }
    .nav-item.active { color: var(--cream); background: var(--role-color-soft, rgba(163,177,138,.15)); border-left-color: var(--role-color, var(--sage-light)); font-weight: 500; }
    .nav-icon { width: 22px; text-align: center; font-size: 16px; flex-shrink: 0; }
    .nav-label { flex: 1; }
    .nav-badge { margin-left: auto; background: var(--gold); color: var(--moss-dark); font-family: 'Nunito', sans-serif; font-size: 10px; font-weight: 800; padding: 2px 7px; border-radius: 10px; }

    .sidebar-bottom { padding: 16px 24px 24px; border-top: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; }
    .btn-logout { display: flex; align-items: center; gap: 10px; width: 100%; padding: 10px 16px; background: rgba(255,255,255,.06); border: 1px solid rgba(255,255,255,.1); border-radius: 2px; color: rgba(245,240,232,.7); font-family: 'DM Sans', sans-serif; font-size: 13px; cursor: pointer; transition: all .2s; }
    .btn-logout:hover { background: rgba(155,68,68,.2); border-color: rgba(155,68,68,.3); color: #e8a0a0; }

    @media (max-width: 768px) {
        .sidebar { transform: translateX(-100%); }
        .sidebar.active { transform: translateX(0); }
    }
</style>

<script>
    function toggleSidebar() {
        document.getElementById('sidebar').classList.toggle('active');
        document.getElementById('sidebarOverlay').classList.toggle('active');
    }
    window.addEventListener('resize', function () {
        if (window.innerWidth > 768) {
            document.getElementById('sidebar').classList.remove('active');
            document.getElementById('sidebarOverlay').classList.remove('active');
        }
    });
    function logout()             { window.location.href = '<%= _ctx %>/LogoutController'; }
    function irParaPerfil()       { window.location.href = '<%= _ctx %>/pages/html/admin/perfil-admin.html'; }
    function irParaConfiguracoes(){ window.location.href = '<%= _ctx %>/ConfiguracaoController'; }
</script>
