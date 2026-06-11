<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String currentPage = (String) request.getAttribute("currentPage");
    if (currentPage == null) {
        String sp = request.getServletPath();
        if      (sp.contains("home")     || sp.equals("/") || sp.equals("/index.jsp")) currentPage = "home";
        else if (sp.contains("receita"))                                                currentPage = "receitas";
        else if (sp.contains("autor"))                                                  currentPage = "autores";
        else if (sp.contains("login"))                                                  currentPage = "login";
        else                                                                            currentPage = "home";
    }
    String _ctx = request.getContextPath();
%>

<!-- ===== OVERLAY MOBILE ===== -->
<div class="sidebar-overlay" id="sidebarOverlay" onclick="toggleSidebar()"></div>

<!-- ===== SIDEBAR PÚBLICO ===== -->
<aside class="sidebar" id="sidebar">

    <div class="sidebar-brand">
        <div class="brand-row">
            <div class="brand-badge">🌿</div>
            <div>
                <span class="brand-title">Sabor &amp; Arte</span>
                <span class="brand-sub">Blog Editorial</span>
            </div>
        </div>
    </div>

    <!-- Chamada para ação: visitante ainda não logado -->
    <div class="sidebar-cta">
        <div class="cta-text">Faça parte da comunidade</div>
        <div class="cta-sub">Crie receitas, comente e favorite</div>
        <a href="<%= _ctx %>/LoginController" class="cta-btn">Entrar agora →</a>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section-label">Explorar</div>

        <a href="<%= _ctx %>/HomeController"
           class="nav-item <%= "home".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">🏠</span>
            <span class="nav-label">Home</span>
        </a>

        <a href="<%= _ctx %>/ReceitaController"
           class="nav-item <%= "receitas".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">📝</span>
            <span class="nav-label">Receitas</span>
        </a>

        <a href="<%= _ctx %>/AutorController"
           class="nav-item <%= "autores".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">✍️</span>
            <span class="nav-label">Autores</span>
        </a>

        <div class="nav-section-label">Conta</div>

        <a href="<%= _ctx %>/LoginController"
           class="nav-item nav-item-highlight <%= "login".equals(currentPage) ? "active" : "" %>">
            <span class="nav-icon">🔑</span>
            <span class="nav-label">Login</span>
        </a>

    </nav>

    <div class="sidebar-bottom">
        <div class="sidebar-footer-info">
            © 2026 Sabor &amp; Arte
        </div>
    </div>

</aside>

<style>
    :root {
        --moss:#4a5e3a; --moss-dark:#2f3d25; --moss-mid:#3d5030; --moss-light:#6b7f59;
        --sage:#a3b18a; --sage-light:#c8d5b9; --cream:#f5f0e8; --cream-dark:#e6dece;
        --warm-white:#faf8f4; --text-dark:#1e2718; --text-mid:#4a5240; --text-light:#8a9480;
        --gold:#c4a265; --gold-light:#dfc094;
        --sidebar-w: 260px;
    }

    .sidebar-overlay {
        display: none; position: fixed; inset: 0;
        background: rgba(30,39,24,0.45); z-index: 99;
        backdrop-filter: blur(2px);
    }
    .sidebar-overlay.active { display: block; }

    .sidebar {
        width: var(--sidebar-w); background: var(--moss-dark);
        display: flex; flex-direction: column;
        position: fixed; top: 0; left: 0; bottom: 0;
        z-index: 100; overflow-y: auto;
        font-family: 'DM Sans', sans-serif;
        transition: transform .28s cubic-bezier(.25,.46,.45,.94);
    }
    .sidebar::before {
        content: ''; position: absolute; inset: 0;
        background:
            radial-gradient(ellipse 200% 60% at 50% 0%, rgba(74,94,58,.5) 0%, transparent 60%),
            radial-gradient(ellipse 100% 40% at 50% 100%, rgba(163,177,138,.1) 0%, transparent 60%);
        pointer-events: none;
    }

    /* brand */
    .sidebar-brand { padding: 28px 24px 22px; border-bottom: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; }
    .brand-row { display: flex; align-items: center; gap: 12px; }
    .brand-badge { width: 38px; height: 38px; background: linear-gradient(135deg, var(--moss-light), var(--sage)); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
    .brand-title { font-family: 'Playfair Display', serif; font-size: 18px; font-weight: 700; color: var(--cream); display: block; line-height: 1; }
    .brand-sub { font-size: 10px; color: var(--sage); text-transform: uppercase; letter-spacing: 1.2px; margin-top: 3px; display: block; font-weight: 300; }

    /* cta */
    .sidebar-cta { padding: 18px 24px; border-bottom: 1px solid rgba(255,255,255,.07); position: relative; z-index: 1; }
    .cta-text { font-size: 13px; font-weight: 600; color: var(--cream); margin-bottom: 2px; }
    .cta-sub  { font-size: 11px; color: rgba(163,177,138,.7); font-weight: 300; margin-bottom: 12px; }
    .cta-btn  { display: block; text-align: center; padding: 9px 0; background: linear-gradient(135deg, var(--moss-light), var(--moss)); color: var(--cream); text-decoration: none; border-radius: 2px; font-size: 13px; font-weight: 600; transition: opacity .2s; }
    .cta-btn:hover { opacity: .85; }

    /* nav */
    .sidebar-nav { flex: 1; padding: 16px 0; position: relative; z-index: 1; }
    .nav-section-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1.8px; color: rgba(163,177,138,.5); padding: 16px 24px 6px; font-weight: 500; }
    .nav-item { display: flex; align-items: center; gap: 12px; padding: 11px 24px; color: rgba(245,240,232,.7); text-decoration: none; font-size: 14px; font-weight: 400; cursor: pointer; transition: all .2s; border-left: 3px solid transparent; }
    .nav-item:hover { color: var(--cream); background: rgba(255,255,255,.06); border-left-color: var(--sage); }
    .nav-item.active { color: var(--cream); background: rgba(163,177,138,.15); border-left-color: var(--sage-light); font-weight: 500; }
    .nav-item-highlight { color: rgba(196,162,101,.9) !important; }
    .nav-item-highlight:hover { color: var(--gold-light) !important; }
    .nav-item-highlight.active { color: var(--gold-light) !important; border-left-color: var(--gold) !important; background: rgba(196,162,101,.1) !important; }
    .nav-icon { width: 22px; text-align: center; font-size: 16px; flex-shrink: 0; }
    .nav-label { flex: 1; }

    /* bottom */
    .sidebar-bottom { padding: 16px 24px 24px; border-top: 1px solid rgba(255,255,255,.08); position: relative; z-index: 1; }
    .sidebar-footer-info { font-size: 11px; color: rgba(163,177,138,.4); text-align: center; font-weight: 300; }

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
</script>
