<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Categorias</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root{--moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;--sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;--warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;--gold:#c4a265;--gold-light:#dfc094;--pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;--sidebar-w:260px;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,.1) 0%,transparent 60%);pointer-events:none;}
  .sidebar-brand{padding:28px 24px 22px;border-bottom:1px solid rgba(255,255,255,.08);position:relative;z-index:1;}
  .brand-row{display:flex;align-items:center;gap:12px;}
  .brand-badge{width:38px;height:38px;background:linear-gradient(135deg,var(--moss-light),var(--sage));border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  .brand-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--cream);display:block;line-height:1;}
  .brand-sub{font-size:10px;color:var(--sage);text-transform:uppercase;letter-spacing:1.2px;margin-top:3px;display:block;font-weight:300;}
  .sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;}
  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,var(--gold),var(--gold-light));border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--moss-dark);flex-shrink:0;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:.8px;font-weight:300;}
  .sidebar-nav{flex:1;padding:16px 0;position:relative;z-index:1;}
  .nav-section-label{font-size:9px;text-transform:uppercase;letter-spacing:1.8px;color:rgba(163,177,138,.5);padding:16px 24px 6px;font-weight:500;}
  .nav-item{display:flex;align-items:center;gap:12px;padding:11px 24px;color:rgba(245,240,232,.7);text-decoration:none;font-size:14px;font-weight:400;cursor:pointer;transition:all .2s;border-left:3px solid transparent;}
  .nav-item:hover{color:var(--cream);background:rgba(255,255,255,.06);border-left-color:var(--sage);}
  .nav-item.active{color:var(--cream);background:rgba(163,177,138,.15);border-left-color:var(--sage-light);font-weight:500;}
  .nav-icon{width:22px;text-align:center;font-size:16px;flex-shrink:0;}
  .nav-badge{margin-left:auto;background:var(--gold);color:var(--moss-dark);font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;padding:2px 7px;border-radius:10px;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,.08);position:relative;z-index:1;}
  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);border-radius:2px;color:rgba(245,240,232,.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all .2s;}
  .btn-logout:hover{background:rgba(155,68,68,.2);border-color:rgba(155,68,68,.3);color:#e8a0a0;}

  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:16px;}
  .topbar-search{display:flex;align-items:center;gap:8px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;padding:7px 14px;width:220px;}
  .topbar-search:focus-within{border-color:var(--moss-light);}
  .topbar-search input{border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;flex:1;}
  .topbar-search input::placeholder{color:var(--text-light);font-weight:300;}
  .notif-btn{width:36px;height:36px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;position:relative;}
  .notif-dot{position:absolute;top:4px;right:4px;width:8px;height:8px;background:var(--gold);border-radius:50%;border:2px solid var(--warm-white);}

  .content{flex:1;padding:36px 40px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:28px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}
  .btn-primary{display:flex;align-items:center;gap:8px;background:var(--moss);color:var(--cream);padding:10px 20px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s,transform .15s;}
  .btn-primary:hover{background:var(--moss-dark);transform:translateY(-1px);}

  .cat-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;}

  .cat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;overflow:hidden;transition:transform .2s,box-shadow .2s;}
  .cat-card:hover{transform:translateY(-3px);box-shadow:0 12px 32px rgba(47,61,37,.12);}
  .cat-card-header{padding:18px 20px;display:flex;align-items:center;gap:14px;border-bottom:1px solid var(--cream-dark);}
  .cat-emoji-box{width:48px;height:48px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;}
  .cat-card-info{flex:1;}
  .cat-card-name{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--text-dark);line-height:1;margin-bottom:3px;}
  .cat-card-slug{font-size:10px;color:var(--text-light);font-family:monospace;background:var(--cream);padding:2px 7px;border-radius:10px;}
  .cat-menu-btn{width:28px;height:28px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:14px;transition:all .15s;}
  .cat-menu-btn:hover{border-color:var(--moss);background:rgba(74,94,58,.05);}
  .cat-card-body{padding:16px 20px;}
  .cat-desc{font-size:12px;color:var(--text-mid);font-weight:300;line-height:1.5;margin-bottom:14px;}
  .cat-stats-row{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:14px;}
  .cat-stat{text-align:center;padding:10px 8px;background:var(--cream);border-radius:2px;}
  .cat-stat-val{font-family:'Nunito',sans-serif;font-size:20px;font-weight:800;color:var(--text-dark);line-height:1;}
  .cat-stat-lbl{font-size:9px;text-transform:uppercase;letter-spacing:.7px;color:var(--text-light);font-weight:500;margin-top:3px;}
  .cat-card-footer{display:flex;align-items:center;gap:6px;padding:12px 20px;background:var(--cream);border-top:1px solid var(--cream-dark);}
  .cat-status{display:flex;align-items:center;gap:5px;font-size:11px;color:var(--text-mid);margin-right:auto;}
  .status-dot-sm{width:6px;height:6px;border-radius:50%;}
  .active-dot{background:var(--published);}
  .footer-act-btn{padding:6px 12px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:11px;font-weight:500;color:var(--text-mid);cursor:pointer;transition:all .15s;display:flex;align-items:center;gap:4px;}
  .footer-act-btn:hover{border-color:var(--moss);color:var(--moss);}
  .footer-act-btn.danger:hover{border-color:#9b4444;color:#9b4444;}

  /* OVERLAY GERAL */
  .modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:center;justify-content:center;z-index:200;padding:20px;}
  .modal-overlay.open{display:flex;}

  /* MODAL NOVA/EDITAR CATEGORIA */
  .modal-nova-cat{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;width:100%;max-width:540px;max-height:90vh;overflow-y:auto;box-shadow:0 24px 60px rgba(0,0,0,.28);}
  .modal-nova-cat-head{padding:20px 24px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--warm-white);z-index:1;}
  .modal-nova-cat-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--text-dark);display:flex;align-items:center;gap:8px;}
  .modal-close-btn{width:30px;height:30px;border:1.5px solid var(--cream-dark);background:var(--cream);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;color:var(--text-light);transition:all .15s;}
  .modal-close-btn:hover{border-color:#9b4444;color:#9b4444;background:rgba(155,68,68,.06);}
  .modal-nova-cat-body{padding:22px 24px;display:flex;flex-direction:column;gap:16px;}
  .modal-nova-cat-footer{padding:16px 24px;border-top:1px solid var(--cream-dark);display:flex;gap:10px;justify-content:flex-end;background:var(--cream);}

  /* Preview de destaque no modal de edição */
  .edit-preview-bar{display:flex;align-items:center;gap:14px;padding:14px 16px;border-radius:2px;border:1px solid var(--cream-dark);background:var(--cream);margin-bottom:4px;}
  .edit-preview-icon{width:44px;height:44px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;transition:background .3s;}
  .edit-preview-name{font-family:'Playfair Display',serif;font-size:15px;font-weight:700;color:var(--text-dark);}
  .edit-preview-slug{font-size:10px;color:var(--text-light);font-family:monospace;}
  .edit-preview-lbl{font-size:9px;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);font-weight:500;margin-left:auto;}

  .form-label{font-size:10px;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);font-weight:700;display:block;margin-bottom:6px;}
  .form-input{width:100%;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;padding:9px 12px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;transition:border-color .2s;}
  .form-input:focus{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,.06);}
  textarea.form-input{resize:vertical;min-height:72px;}

  .form-row-2{display:grid;grid-template-columns:1fr 1fr;gap:12px;}

  .color-row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;}
  .color-swatch{width:32px;height:32px;border-radius:2px;cursor:pointer;border:2.5px solid transparent;transition:all .15s;flex-shrink:0;}
  .color-swatch:hover{transform:scale(1.1);}
  .color-swatch.selected{border-color:var(--text-dark);transform:scale(.87);}

  /* EMOJI ROW */
  .emoji-row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;}
  .emoji-opt{width:36px;height:36px;border:1.5px solid var(--cream-dark);background:var(--cream);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;cursor:pointer;transition:all .15s;flex-shrink:0;}
  .emoji-opt:hover{border-color:var(--moss);background:rgba(74,94,58,.06);}
  .emoji-opt.selected{border-color:var(--moss);background:rgba(74,94,58,.12);box-shadow:0 0 0 2px rgba(74,94,58,.18);}
  .emoji-add{width:36px;height:36px;border:1.5px dashed var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:18px;color:var(--text-light);transition:all .15s;flex-shrink:0;}
  .emoji-add:hover{border-color:var(--moss);color:var(--moss);}

  .btn-ghost{background:none;color:var(--text-mid);border:1.5px solid var(--cream-dark);border-radius:2px;padding:9px 18px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:all .2s;}
  .btn-ghost:hover{border-color:var(--moss-light);color:var(--moss);}
  .btn-criar{background:var(--moss);color:var(--cream);border:none;border-radius:2px;padding:9px 20px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s;}
  .btn-criar:hover{background:var(--moss-dark);}
  .btn-salvar{background:var(--moss);color:var(--cream);border:none;border-radius:2px;padding:9px 20px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s;}
  .btn-salvar:hover{background:var(--moss-dark);}

  /* MODAL EMOJI PICKER */
  .modal-sub{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;width:100%;max-width:360px;box-shadow:0 18px 40px rgba(0,0,0,.25);}
  .modal-sub-head{padding:14px 18px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .modal-sub-title{font-size:14px;font-weight:600;color:var(--text-dark);}
  .modal-sub-body{padding:16px 18px;}

  .emoji-cats{display:flex;gap:4px;margin-bottom:12px;flex-wrap:wrap;}
  .emoji-cat-btn{padding:4px 10px;border:1.5px solid var(--cream-dark);border-radius:10px;font-size:11px;color:var(--text-mid);cursor:pointer;background:var(--cream);font-family:'DM Sans',sans-serif;transition:all .15s;}
  .emoji-cat-btn:hover{border-color:var(--moss);color:var(--moss);}
  .emoji-cat-btn.active{background:var(--moss);color:var(--cream);border-color:var(--moss);}

  .emoji-picker-grid{display:grid;grid-template-columns:repeat(8,1fr);gap:4px;max-height:220px;overflow-y:auto;}
  .emoji-picker-grid::-webkit-scrollbar{width:4px;}
  .emoji-picker-grid::-webkit-scrollbar-thumb{background:var(--cream-dark);border-radius:2px;}
  .emoji-picker-item{width:100%;aspect-ratio:1;display:flex;align-items:center;justify-content:center;font-size:20px;border-radius:2px;cursor:pointer;transition:background .1s;}
  .emoji-picker-item:hover{background:var(--cream-dark);}
  .emoji-picker-item.in-use{background:rgba(74,94,58,.12);outline:2px solid var(--moss);outline-offset:-2px;}

  /* Toast */
  .toast{position:fixed;bottom:28px;right:28px;background:var(--moss-dark);color:var(--cream);padding:12px 18px;border-radius:2px;font-size:13px;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,.25);z-index:999;transform:translateY(80px);opacity:0;transition:all .35s cubic-bezier(.34,1.56,.64,1);display:flex;align-items:center;gap:8px;}
  .toast.show{transform:translateY(0);opacity:1;}

  @media(max-width:1100px){.cat-grid{grid-template-columns:1fr 1fr;}}
  @media(max-width:768px){.sidebar{display:none;}.main{margin-left:0;}.content{padding:20px;}.topbar{padding:0 20px;}.cat-grid{grid-template-columns:1fr;}}
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar-editor-admin.jsp" />

<%-- ===== MAIN ===== --%>
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Gestão</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Categorias</span>
    </div>
    <div class="topbar-right">
      <div class="topbar-search">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" placeholder="Buscar categorias…" id="campoBusca">
      </div>
      <div class="notif-btn">🔔<div class="notif-dot"></div></div>
    </div>
  </div>

  <div class="content">
    <div class="section-header">
      <div>
        <div class="section-title">Gestão de <em>Categorias</em></div>
        <%-- Total de categorias e receitas pode vir do backend --%>
        <div class="section-date">
          <c:choose>
            <c:when test="${not empty totalCategorias}">
              <c:out value="${totalCategorias}" /> categorias ativas ·
              <c:out value="${totalReceitas}" /> receitas organizadas
            </c:when>
            <c:otherwise>8 categorias ativas · 134 receitas organizadas</c:otherwise>
          </c:choose>
        </div>
      </div>
      <button class="btn-primary" id="btnNovaCat">✚ Nova Categoria</button>
    </div>

    <%-- ===== GRID DE CATEGORIAS ===== --%>
    <div class="cat-grid" id="catGrid">

      <%-- Renderização dinâmica via JSTL (quando a lista vier do Servlet/Controller) --%>
      <c:choose>
        <c:when test="${not empty categorias}">
          <c:forEach var="cat" items="${categorias}">
            <div class="cat-card"
                 data-name="${cat.nome}"
                 data-slug="${cat.slug}"
                 data-emoji="${cat.emoji}"
                 data-desc="${cat.descricao}"
                 data-color="${cat.corFundo}"
                 data-accent="${cat.corDestaque}">
              <div class="cat-card-header">
                <div class="cat-emoji-box" style="background:${cat.corFundo}">
                  <c:out value="${cat.emoji}" />
                </div>
                <div class="cat-card-info">
                  <div class="cat-card-name"><c:out value="${cat.nome}" /></div>
                  <span class="cat-card-slug"><c:out value="${cat.slug}" /></span>
                </div>
                <button class="cat-menu-btn">⋯</button>
              </div>
              <div class="cat-card-body">
                <div class="cat-desc"><c:out value="${cat.descricao}" /></div>
                <div class="cat-stats-row">
                  <div class="cat-stat">
                    <div class="cat-stat-val"><c:out value="${cat.totalReceitas}" /></div>
                    <div class="cat-stat-lbl">Receitas</div>
                  </div>
                  <div class="cat-stat">
                    <div class="cat-stat-val"><c:out value="${cat.avaliacao}" /></div>
                    <div class="cat-stat-lbl">Avaliação</div>
                  </div>
                  <div class="cat-stat">
                    <div class="cat-stat-val"><c:out value="${cat.viewsMes}" /></div>
                    <div class="cat-stat-lbl">Views/mês</div>
                  </div>
                </div>
              </div>
              <div class="cat-card-footer">
                <span class="cat-status">
                  <span class="status-dot-sm active-dot"></span>
                  <c:out value="${cat.ativa ? 'Ativa' : 'Inativa'}" />
                </span>
                <button class="footer-act-btn btn-editar">✏️ Editar</button>
                <button class="footer-act-btn danger" data-id="${cat.id}">🗑️</button>
              </div>
            </div>
          </c:forEach>
        </c:when>

        <%-- Fallback estático (dados de exemplo) --%>
        <c:otherwise>
          <div class="cat-card" data-name="Sobremesas" data-slug="/sobremesas" data-emoji="🎂" data-desc="Doces, bolos, tortas e sobremesas de todas as tradições culinárias." data-color="rgba(74,94,58,.1)" data-accent="#4a5e3a">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(74,94,58,.1)">🎂</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Sobremesas</div>
                <span class="cat-card-slug">/sobremesas</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Doces, bolos, tortas e sobremesas de todas as tradições culinárias.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">34</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.8</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">2.1k</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>

          <div class="cat-card" data-name="Massas" data-slug="/massas" data-emoji="🍝" data-desc="Macarrões, risotos, gnocchis e todas as especialidades italianas." data-color="rgba(196,162,101,.12)" data-accent="#c4a265">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(196,162,101,.12)">🍝</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Massas</div>
                <span class="cat-card-slug">/massas</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Macarrões, risotos, gnocchis e todas as especialidades italianas.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">28</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.6</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">1.8k</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>

          <div class="cat-card" data-name="Saladas" data-slug="/saladas" data-emoji="🥗" data-desc="Saladas frescas, nutritivas e cheias de sabor para o dia a dia." data-color="rgba(58,122,74,.1)" data-accent="#3a7a4a">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(58,122,74,.1)">🥗</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Saladas</div>
                <span class="cat-card-slug">/saladas</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Saladas frescas, nutritivas e cheias de sabor para o dia a dia.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">22</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.5</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">1.4k</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>

          <div class="cat-card" data-name="Sopas" data-slug="/sopas" data-emoji="🥣" data-desc="Caldos, cremes e sopas reconfortantes para todas as estações." data-color="rgba(196,131,42,.1)" data-accent="#c4832a">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(196,131,42,.1)">🥣</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Sopas</div>
                <span class="cat-card-slug">/sopas</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Caldos, cremes e sopas reconfortantes para todas as estações.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">18</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.7</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">960</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>

          <div class="cat-card" data-name="Carnes" data-slug="/carnes" data-emoji="🍗" data-desc="Grelhados, assados, ensopados e pratos com proteínas de qualidade." data-color="rgba(163,177,138,.15)" data-accent="#5a8a6a">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(163,177,138,.15)">🍗</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Carnes</div>
                <span class="cat-card-slug">/carnes</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Grelhados, assados, ensopados e pratos com proteínas de qualidade.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">14</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.3</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">720</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>

          <div class="cat-card" data-name="Vegano" data-slug="/vegano" data-emoji="🥬" data-desc="Receitas 100% plant-based, saborosas e nutritivas para todos." data-color="rgba(90,138,106,.1)" data-accent="#5a8a6a">
            <div class="cat-card-header">
              <div class="cat-emoji-box" style="background:rgba(90,138,106,.1)">🥬</div>
              <div class="cat-card-info">
                <div class="cat-card-name">Vegano</div>
                <span class="cat-card-slug">/vegano</span>
              </div>
              <button class="cat-menu-btn">⋯</button>
            </div>
            <div class="cat-card-body">
              <div class="cat-desc">Receitas 100% plant-based, saborosas e nutritivas para todos.</div>
              <div class="cat-stats-row">
                <div class="cat-stat"><div class="cat-stat-val">10</div><div class="cat-stat-lbl">Receitas</div></div>
                <div class="cat-stat"><div class="cat-stat-val">4.9</div><div class="cat-stat-lbl">Avaliação</div></div>
                <div class="cat-stat"><div class="cat-stat-val">540</div><div class="cat-stat-lbl">Views/mês</div></div>
              </div>
            </div>
            <div class="cat-card-footer">
              <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
              <button class="footer-act-btn btn-editar">✏️ Editar</button>
              <button class="footer-act-btn danger">🗑️</button>
            </div>
          </div>
        </c:otherwise>
      </c:choose>

    </div><%-- /cat-grid --%>
  </div><%-- /content --%>
</main>

<%-- ===== MODAL NOVA CATEGORIA ===== --%>
<div class="modal-overlay" id="modalNovaCat">
  <div class="modal-nova-cat">
    <div class="modal-nova-cat-head">
      <div class="modal-nova-cat-title">✚ Nova Categoria</div>
      <button class="modal-close-btn" id="btnFecharNovaCat">✕</button>
    </div>
    <div class="modal-nova-cat-body">
      <div>
        <label class="form-label">Nome da Categoria</label>
        <input class="form-input" type="text" id="novaCatNome" placeholder="ex: Bebidas">
      </div>
      <div>
        <label class="form-label">Descrição</label>
        <textarea class="form-input" id="novaCatDesc" rows="3" placeholder="Descreva brevemente esta categoria…"></textarea>
      </div>
      <div>
        <label class="form-label">Ícone</label>
        <div class="emoji-row" id="novaEmojiRow">
          <div class="emoji-opt selected">🥤</div>
          <div class="emoji-opt">🍵</div>
          <div class="emoji-opt">🍹</div>
          <div class="emoji-opt">🧁</div>
          <div class="emoji-opt">🫕</div>
          <div class="emoji-opt">🥘</div>
          <div class="emoji-opt">🍲</div>
          <div class="emoji-opt">🥙</div>
          <div class="emoji-add" data-target="novaEmojiRow">+</div>
        </div>
      </div>
      <div>
        <label class="form-label">Cor de Destaque</label>
        <div class="color-row" id="novaColorRow">
          <div class="color-swatch selected" style="background:#4a5e3a" title="#4a5e3a"></div>
          <div class="color-swatch" style="background:#c4a265" title="#c4a265"></div>
          <div class="color-swatch" style="background:#3a7a4a" title="#3a7a4a"></div>
          <div class="color-swatch" style="background:#c4832a" title="#c4832a"></div>
          <div class="color-swatch" style="background:#5a8a6a" title="#5a8a6a"></div>
          <div class="color-swatch" style="background:#7a6aa0" title="#7a6aa0"></div>
        </div>
      </div>
    </div>
    <div class="modal-nova-cat-footer">
      <button class="btn-ghost" id="btnCancelarNovaCat">Cancelar</button>
      <button class="btn-criar" id="btnConfirmarNovaCat">✚ Criar Categoria</button>
    </div>
  </div>
</div>

<%-- ===== MODAL EDITAR CATEGORIA ===== --%>
<div class="modal-overlay" id="modalEditarCat">
  <div class="modal-nova-cat">
    <div class="modal-nova-cat-head">
      <div class="modal-nova-cat-title">✏️ Editar Categoria</div>
      <button class="modal-close-btn" id="btnFecharEditarCat">✕</button>
    </div>
    <div class="modal-nova-cat-body">
      <div class="edit-preview-bar" id="editPreviewBar">
        <div class="edit-preview-icon" id="editPreviewIcon">🎂</div>
        <div>
          <div class="edit-preview-name" id="editPreviewName">Nome</div>
          <div class="edit-preview-slug" id="editPreviewSlug">/slug</div>
        </div>
        <span class="edit-preview-lbl">Pré-visualização</span>
      </div>
      <div>
        <label class="form-label">Nome da Categoria</label>
        <input class="form-input" type="text" id="editCatNome" placeholder="Nome da categoria">
      </div>
      <div>
        <label class="form-label">Descrição</label>
        <textarea class="form-input" id="editCatDesc" rows="3" placeholder="Descreva brevemente esta categoria…"></textarea>
      </div>
      <div>
        <label class="form-label">Ícone</label>
        <div class="emoji-row" id="editEmojiRow">
          <%-- preenchido via JS --%>
        </div>
      </div>
      <div>
        <label class="form-label">Cor de Destaque</label>
        <div class="color-row" id="editColorRow">
          <div class="color-swatch" style="background:#4a5e3a" title="#4a5e3a"></div>
          <div class="color-swatch" style="background:#c4a265" title="#c4a265"></div>
          <div class="color-swatch" style="background:#3a7a4a" title="#3a7a4a"></div>
          <div class="color-swatch" style="background:#c4832a" title="#c4832a"></div>
          <div class="color-swatch" style="background:#5a8a6a" title="#5a8a6a"></div>
          <div class="color-swatch" style="background:#7a6aa0" title="#7a6aa0"></div>
        </div>
      </div>
    </div>
    <div class="modal-nova-cat-footer">
      <button class="btn-ghost" id="btnCancelarEditarCat">Cancelar</button>
      <button class="btn-salvar" id="btnConfirmarEditarCat">💾 Salvar Alterações</button>
    </div>
  </div>
</div>

<%-- ===== MODAL EMOJI PICKER ===== --%>
<div class="modal-overlay" id="emojiModal">
  <div class="modal-sub">
    <div class="modal-sub-head">
      <div class="modal-sub-title">Escolher ícone</div>
      <button class="modal-close-btn" id="closeEmojiModal">✕</button>
    </div>
    <div class="modal-sub-body">
      <div class="emoji-cats" id="emojiCats">
        <button class="emoji-cat-btn active" data-cat="all">Todos</button>
        <button class="emoji-cat-btn" data-cat="food">Comida</button>
        <button class="emoji-cat-btn" data-cat="drink">Bebidas</button>
        <button class="emoji-cat-btn" data-cat="veggie">Vegetais</button>
        <button class="emoji-cat-btn" data-cat="sweet">Doces</button>
        <button class="emoji-cat-btn" data-cat="other">Outros</button>
      </div>
      <div class="emoji-picker-grid" id="emojiPickerGrid">
        <%-- preenchido via JS --%>
      </div>
    </div>
  </div>
</div>

<%-- TOAST --%>
<div class="toast" id="toast"></div>

<script>
// ─── DADOS DE EMOJIS ─────────────────────────────────────────────────────────
const EMOJI_DB = {
  food:   ['🍔','🍕','🌮','🌯','🥙','🫔','🥗','🍜','🍝','🍲','🥘','🫕','🍛','🍣','🍤','🍱','🥟','🍗','🍖','🥩','🥚','🧆','🥞','🧇'],
  drink:  ['🥤','🍹','🍸','🍷','🍺','🧃','☕','🍵','🧋','🥛','🫖','🍶','🥂','🍻'],
  veggie: ['🥬','🥦','🥕','🌽','🧅','🧄','🫑','🍆','🥑','🍅','🥒','🥝','🍋','🫐','🍓','🍇','🍒','🍑','🥭','🍍'],
  sweet:  ['🎂','🍰','🧁','🍩','🍪','🍫','🍬','🍭','🍦','🍧','🍨','🥐','🍞','🥖','🥨'],
  other:  ['🫕','🥘','🍲','🥣','🥗','🧑‍🍳','👨‍🍳','🍽️','🥄','🔪','🫙','🧂','🌶️','🫚','🫛']
};
const ALL_EMOJIS = [...new Set(Object.values(EMOJI_DB).flat())];

// ─── ESTADO ───────────────────────────────────────────────────────────────────
let activeEmojiTarget = null;
let editingCard = null;

// ─── UTILITÁRIOS ──────────────────────────────────────────────────────────────
function openModal(m){ m.classList.add('open'); }
function closeModal(m){ m.classList.remove('open'); }

function showToast(msg, icon='✅') {
  const t = document.getElementById('toast');
  t.innerHTML = icon + ' ' + msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2800);
}

function slugify(text) {
  return '/' + text.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim().replace(/\s+/g, '-');
}

function getSelectedEmoji(rowId) {
  const sel = document.querySelector('#' + rowId + ' .emoji-opt.selected');
  return sel ? sel.textContent : '🏷️';
}

function getSelectedColor(rowId) {
  const sel = document.querySelector('#' + rowId + ' .color-swatch.selected');
  if (!sel) return '#4a5e3a';
  return sel.title || sel.style.background;
}

// ─── MODAL NOVA CATEGORIA ─────────────────────────────────────────────────────
document.getElementById('btnNovaCat').onclick = () => {
  document.getElementById('novaCatNome').value = '';
  document.getElementById('novaCatDesc').value = '';
  openModal(document.getElementById('modalNovaCat'));
};
document.getElementById('btnFecharNovaCat').onclick = () => closeModal(document.getElementById('modalNovaCat'));
document.getElementById('btnCancelarNovaCat').onclick = () => closeModal(document.getElementById('modalNovaCat'));

document.getElementById('btnConfirmarNovaCat').onclick = function() {
  const nome = document.getElementById('novaCatNome').value.trim();
  if (!nome) { document.getElementById('novaCatNome').focus(); return; }
  const desc  = document.getElementById('novaCatDesc').value.trim() || 'Sem descrição.';
  const emoji = getSelectedEmoji('novaEmojiRow');
  const color = getSelectedColor('novaColorRow');
  const slug  = slugify(nome);

  const card = document.createElement('div');
  card.className = 'cat-card';
  card.dataset.name  = nome;
  card.dataset.slug  = slug;
  card.dataset.emoji = emoji;
  card.dataset.desc  = desc;
  card.dataset.accent = color;
  const bgColor = hexToRgba(color, 0.1);
  card.innerHTML = `
    <div class="cat-card-header">
      <div class="cat-emoji-box" style="background:${bgColor}">${emoji}</div>
      <div class="cat-card-info">
        <div class="cat-card-name">${nome}</div>
        <span class="cat-card-slug">${slug}</span>
      </div>
      <button class="cat-menu-btn">⋯</button>
    </div>
    <div class="cat-card-body">
      <div class="cat-desc">${desc}</div>
      <div class="cat-stats-row">
        <div class="cat-stat"><div class="cat-stat-val">0</div><div class="cat-stat-lbl">Receitas</div></div>
        <div class="cat-stat"><div class="cat-stat-val">—</div><div class="cat-stat-lbl">Avaliação</div></div>
        <div class="cat-stat"><div class="cat-stat-val">0</div><div class="cat-stat-lbl">Views/mês</div></div>
      </div>
    </div>
    <div class="cat-card-footer">
      <span class="cat-status"><span class="status-dot-sm active-dot"></span>Ativa</span>
      <button class="footer-act-btn btn-editar">✏️ Editar</button>
      <button class="footer-act-btn danger">🗑️</button>
    </div>`;
  document.getElementById('catGrid').appendChild(card);
  closeModal(document.getElementById('modalNovaCat'));
  showToast('Categoria "' + nome + '" criada com sucesso!');
};

// ─── MODAL EDITAR CATEGORIA ───────────────────────────────────────────────────
document.getElementById('catGrid').addEventListener('click', function(e) {
  const btn = e.target.closest('.btn-editar');
  if (!btn) return;
  const card = btn.closest('.cat-card');
  editingCard = card;
  openEditModal(card);
});

function openEditModal(card) {
  const name  = card.dataset.name  || card.querySelector('.cat-card-name').textContent;
  const slug  = card.dataset.slug  || card.querySelector('.cat-card-slug').textContent;
  const emoji = card.dataset.emoji || card.querySelector('.cat-emoji-box').textContent;
  const desc  = card.dataset.desc  || card.querySelector('.cat-desc').textContent;
  const accent = card.dataset.accent || '#4a5e3a';

  document.getElementById('editCatNome').value = name;
  document.getElementById('editCatDesc').value = desc;

  updateEditPreview(emoji, name, slug, accent);

  const editEmojiRow = document.getElementById('editEmojiRow');
  const addBtn = editEmojiRow.querySelector('.emoji-add');
  editEmojiRow.querySelectorAll('.emoji-opt').forEach(e => e.remove());
  const defaults = ['🥤','🍵','🍹','🧁','🫕','🥘','🍲','🥙'];
  const pool = defaults.includes(emoji) ? defaults : [emoji, ...defaults];
  pool.slice(0,8).forEach(em => {
    const d = document.createElement('div');
    d.className = 'emoji-opt' + (em === emoji ? ' selected' : '');
    d.textContent = em;
    editEmojiRow.insertBefore(d, addBtn);
  });

  document.querySelectorAll('#editColorRow .color-swatch').forEach(sw => {
    sw.classList.toggle('selected', sw.title === accent || sw.style.background === accent);
  });

  const nomeInput = document.getElementById('editCatNome');
  nomeInput.oninput = function() {
    const newSlug = slugify(this.value || 'categoria');
    document.getElementById('editPreviewName').textContent = this.value || 'Nome';
    document.getElementById('editPreviewSlug').textContent = newSlug;
  };

  openModal(document.getElementById('modalEditarCat'));
}

function updateEditPreview(emoji, name, slug, color) {
  document.getElementById('editPreviewIcon').textContent = emoji;
  document.getElementById('editPreviewIcon').style.background = hexToRgba(color, 0.12);
  document.getElementById('editPreviewName').textContent = name;
  document.getElementById('editPreviewSlug').textContent = slug;
}

document.getElementById('editEmojiRow').addEventListener('click', function(e) {
  if (!e.target.classList.contains('emoji-opt')) return;
  document.querySelectorAll('#editEmojiRow .emoji-opt').forEach(el => el.classList.remove('selected'));
  e.target.classList.add('selected');
  document.getElementById('editPreviewIcon').textContent = e.target.textContent;
});

document.getElementById('editColorRow').addEventListener('click', function(e) {
  const sw = e.target.closest('.color-swatch');
  if (!sw) return;
  document.querySelectorAll('#editColorRow .color-swatch').forEach(el => el.classList.remove('selected'));
  sw.classList.add('selected');
  const color = sw.title || sw.style.background;
  document.getElementById('editPreviewIcon').style.background = hexToRgba(color, 0.12);
});

document.getElementById('btnFecharEditarCat').onclick = () => closeModal(document.getElementById('modalEditarCat'));
document.getElementById('btnCancelarEditarCat').onclick = () => closeModal(document.getElementById('modalEditarCat'));

document.getElementById('btnConfirmarEditarCat').onclick = function() {
  if (!editingCard) return;
  const nome  = document.getElementById('editCatNome').value.trim();
  if (!nome) { document.getElementById('editCatNome').focus(); return; }
  const desc   = document.getElementById('editCatDesc').value.trim() || 'Sem descrição.';
  const emoji  = getSelectedEmoji('editEmojiRow');
  const color  = getSelectedColor('editColorRow');
  const slug   = slugify(nome);
  const bgColor = hexToRgba(color, 0.1);

  editingCard.dataset.name  = nome;
  editingCard.dataset.slug  = slug;
  editingCard.dataset.emoji = emoji;
  editingCard.dataset.desc  = desc;
  editingCard.dataset.accent = color;

  editingCard.querySelector('.cat-card-name').textContent = nome;
  editingCard.querySelector('.cat-card-slug').textContent = slug;
  editingCard.querySelector('.cat-emoji-box').textContent = emoji;
  editingCard.querySelector('.cat-emoji-box').style.background = bgColor;
  editingCard.querySelector('.cat-desc').textContent = desc;

  closeModal(document.getElementById('modalEditarCat'));
  showToast('Categoria "' + nome + '" atualizada!', '💾');
  editingCard = null;
};

// ─── EMOJI PICKER ─────────────────────────────────────────────────────────────
let currentEmojiCat = 'all';
let currentEmojiTargetRowId = null;

function renderEmojiPicker(cat = 'all') {
  const grid = document.getElementById('emojiPickerGrid');
  let pool = cat === 'all' ? ALL_EMOJIS : (EMOJI_DB[cat] || ALL_EMOJIS);
  const inUse = currentEmojiTargetRowId
    ? [...document.querySelectorAll('#' + currentEmojiTargetRowId + ' .emoji-opt')].map(e => e.textContent)
    : [];

  grid.innerHTML = pool.map(em =>
    `<div class="emoji-picker-item${inUse.includes(em) ? ' in-use' : ''}" data-emoji="${em}">${em}</div>`
  ).join('');
}

document.addEventListener('click', function(e) {
  const addBtn = e.target.closest('.emoji-add');
  if (!addBtn) return;
  currentEmojiTargetRowId = addBtn.dataset.target;
  activeEmojiTarget = document.getElementById(currentEmojiTargetRowId);
  currentEmojiCat = 'all';
  document.querySelectorAll('.emoji-cat-btn').forEach(b => b.classList.toggle('active', b.dataset.cat === 'all'));
  renderEmojiPicker('all');
  openModal(document.getElementById('emojiModal'));
});

document.getElementById('emojiCats').addEventListener('click', function(e) {
  const btn = e.target.closest('.emoji-cat-btn');
  if (!btn) return;
  currentEmojiCat = btn.dataset.cat;
  document.querySelectorAll('.emoji-cat-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  renderEmojiPicker(currentEmojiCat);
});

document.getElementById('emojiPickerGrid').addEventListener('click', function(e) {
  const item = e.target.closest('.emoji-picker-item');
  if (!item || !activeEmojiTarget) return;
  const emoji = item.dataset.emoji;

  const existing = [...activeEmojiTarget.querySelectorAll('.emoji-opt')].find(el => el.textContent === emoji);
  if (existing) {
    activeEmojiTarget.querySelectorAll('.emoji-opt').forEach(el => el.classList.remove('selected'));
    existing.classList.add('selected');
  } else {
    const addBtn = activeEmojiTarget.querySelector('.emoji-add');
    const div = document.createElement('div');
    div.className = 'emoji-opt selected';
    div.textContent = emoji;
    activeEmojiTarget.insertBefore(div, addBtn);
    activeEmojiTarget.querySelectorAll('.emoji-opt').forEach(el => {
      if (el !== div) el.classList.remove('selected');
    });
  }

  if (currentEmojiTargetRowId === 'editEmojiRow') {
    document.getElementById('editPreviewIcon').textContent = emoji;
  }

  closeModal(document.getElementById('emojiModal'));
});

document.addEventListener('click', function(e) {
  if (!e.target.classList.contains('emoji-opt')) return;
  const row = e.target.closest('.emoji-row');
  if (!row) return;
  row.querySelectorAll('.emoji-opt').forEach(el => el.classList.remove('selected'));
  e.target.classList.add('selected');
});

document.getElementById('closeEmojiModal').onclick = () => closeModal(document.getElementById('emojiModal'));

document.addEventListener('click', function(e) {
  const sw = e.target.closest('.color-swatch');
  if (!sw) return;
  const row = sw.closest('.color-row');
  if (!row) return;
  row.querySelectorAll('.color-swatch').forEach(el => el.classList.remove('selected'));
  sw.classList.add('selected');
});

[document.getElementById('modalNovaCat'),
 document.getElementById('modalEditarCat'),
 document.getElementById('emojiModal')].forEach(function(m) {
  m.addEventListener('click', function(e) { if (e.target === m) closeModal(m); });
});

document.getElementById('catGrid').addEventListener('click', function(e) {
  if (!e.target.closest('.footer-act-btn.danger')) return;
  const card = e.target.closest('.cat-card');
  const name = card.dataset.name || card.querySelector('.cat-card-name').textContent;
  if (confirm('Tem certeza que deseja excluir a categoria "' + name + '"?')) {
    card.style.transition = 'opacity .3s, transform .3s';
    card.style.opacity = '0';
    card.style.transform = 'scale(.96)';
    setTimeout(() => card.remove(), 300);
    showToast('Categoria "' + name + '" excluída.', '🗑️');
  }
});

// ─── UTILITÁRIO: HEX → RGBA ───────────────────────────────────────────────────
function hexToRgba(hex, alpha) {
  if (!hex || typeof hex !== 'string') return `rgba(74,94,58,${alpha})`;
  hex = hex.trim();
  if (hex.startsWith('rgba') || hex.startsWith('rgb')) return hex;
  hex = hex.replace('#','');
  if (hex.length === 3) hex = hex.split('').map(c => c+c).join('');
  if (hex.length !== 6) return `rgba(74,94,58,${alpha})`;
  const r = parseInt(hex.substring(0,2),16);
  const g = parseInt(hex.substring(2,4),16);
  const b = parseInt(hex.substring(4,6),16);
  return `rgba(${r},${g},${b},${alpha})`;
}
</script>
</body>
</html>
