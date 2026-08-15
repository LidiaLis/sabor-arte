<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="br.com.saborearte.model.Categoria.StatusCategoria" %>
<%@ page import="br.com.saborearte.model.CategoriaEmoji" %>
<%@ page import="br.com.saborearte.model.CategoriaCor" %>
<%!
    // Escapa texto para uso seguro dentro de HTML (texto e atributos)
    private String esc(Object val) {
        if (val == null) return "";
        return val.toString()
                .replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }

    // Escapa texto para uso seguro dentro de string JavaScript
    private String jsEsc(Object val) {
        if (val == null) return "";
        return val.toString()
                .replace("\\", "\\\\")
                .replace("'", "\\'")
                .replace("\"", "\\\"")
                .replace("\n", " ")
                .replace("\r", "");
    }
    %>

  <%
    List<Categoria> categorias = (List<Categoria>) request.getAttribute("categorias");
    if (categorias == null) categorias = new java.util.ArrayList<>();
    
    /* ── Contagens para os cards de stats ── */
    long totalCategorias = (categorias != null) ? categorias.size() : 0;
    long totalAtivas = 0;
    if (categorias != null) {
        totalAtivas = categorias.stream()
                .filter(c -> c.getStatus_categoria() == StatusCategoria.ATIVA)
                .count();
    }
    long totalInativas = totalCategorias - totalAtivas;
    %>
    <%

    List<CategoriaEmoji> emojis = (List<CategoriaEmoji>) request.getAttribute("emojis");
    List<CategoriaCor> cores = (List<CategoriaCor>) request.getAttribute("cores");
    String msgSucesso = (String) request.getAttribute("sucesso");
    String msgErro = (String) request.getAttribute("erro");
    String ctx = request.getContextPath();
    %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Categorias</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root{--moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;--sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;--warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;--gold:#c4a265;--gold-light:#dfc094;--pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;--inactive:#9b4444;--sidebar-w:260px;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,.1) 0%,transparent 60%);pointer-events:none;}

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
  .btn-primary{display:flex;align-items:center;gap:8px;background:var(--moss);color:var(--cream);padding:10px 20px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s,transform .15s;}
  .btn-primary:hover{background:var(--moss-dark);transform:translateY(-1px);}

  .cat-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;}

  .cat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;overflow:hidden;transition:transform .2s,box-shadow .2s;}
  .cat-card:hover{transform:translateY(-3px);box-shadow:0 12px 32px rgba(47,61,37,.12);}
  .cat-card-header{padding:18px 20px;display:flex;align-items:center;gap:14px;border-bottom:1px solid var(--cream-dark);}
  .cat-emoji-box{width:48px;height:48px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;}
  .cat-card-info{flex:1;}
  .cat-card-name{font-family:'Playfair Display',serif;font-size:16px;font-weight:700;color:var(--text-dark);line-height:1;margin-bottom:3px;}
  .cat-card-body{padding:16px 20px;}
  .cat-desc{font-size:12px;color:var(--text-mid);font-weight:300;line-height:1.5;}
  .cat-card-footer{display:flex;align-items:center;gap:6px;padding:12px 20px;background:var(--cream);border-top:1px solid var(--cream-dark);flex-wrap:wrap;}
	.cat-status{display:flex;align-items:center;gap:5px;font-size:11px;color:var(--text-mid);margin-right:auto;}
	.status-dot-sm{width:6px;height:6px;border-radius:50%;}
	.active-dot{background:var(--published);}
	.inactive-dot{background:var(--inactive);}
	.form-inline{display:inline;margin:0;}
	
	.action-group{display:flex;align-items:center;gap:6px;}
	.act-btn{width:30px;height:30px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:13px;cursor:pointer;transition:all .15s;}
	.act-btn:hover{border-color:var(--moss);background:rgba(74,94,58,.05);}
	.act-btn.danger:hover{border-color:var(--inactive);background:rgba(155,68,68,.06);}
	.act-btn.reactivate:hover{border-color:var(--published);background:var(--published-bg);}

  .empty-state{grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--text-light);}
  .empty-state .empty-icon{font-size:44px;margin-bottom:14px;}
  .empty-state h3{font-family:'Playfair Display',serif;font-size:18px;color:var(--text-dark);margin-bottom:6px;}
  .empty-state p{font-size:13px;font-weight:300;}

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

  .edit-preview-bar{display:flex;align-items:center;gap:14px;padding:14px 16px;border-radius:2px;border:1px solid var(--cream-dark);background:var(--cream);margin-bottom:4px;}
  .edit-preview-icon{width:44px;height:44px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;transition:background .3s;}
  .edit-preview-name{font-family:'Playfair Display',serif;font-size:15px;font-weight:700;color:var(--text-dark);}
  .edit-preview-lbl{font-size:9px;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);font-weight:500;margin-left:auto;}

  .form-label{font-size:10px;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);font-weight:700;display:block;margin-bottom:6px;}
  .form-input{width:100%;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;padding:9px 12px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;transition:border-color .2s;}
  .form-input:focus{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,.06);}
  textarea.form-input{resize:vertical;min-height:72px;}

  .color-row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;}
  .color-swatch{width:32px;height:32px;border-radius:2px;cursor:pointer;border:2.5px solid transparent;transition:all .15s;flex-shrink:0;}
  .color-swatch:hover{transform:scale(1.1);}
  .color-swatch.selected{border-color:var(--text-dark);transform:scale(.87);}

  .emoji-row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;max-height:160px;overflow-y:auto;padding:2px;}
  .emoji-opt{width:36px;height:36px;border:1.5px solid var(--cream-dark);background:var(--cream);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;cursor:pointer;transition:all .15s;flex-shrink:0;}
  .emoji-opt:hover{border-color:var(--moss);background:rgba(74,94,58,.06);}
  .emoji-opt.selected{border-color:var(--moss);background:rgba(74,94,58,.12);box-shadow:0 0 0 2px rgba(74,94,58,.18);}
  .emoji-add{width:36px;height:36px;border:1.5px dashed var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:18px;color:var(--text-light);transition:all .15s;flex-shrink:0;}
  .emoji-add:hover{border-color:var(--moss);color:var(--moss);}

  /* MODAL EMOJI PICKER (emojis pré-definidos no JSP) */
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

  .btn-ghost{background:none;color:var(--text-mid);border:1.5px solid var(--cream-dark);border-radius:2px;padding:9px 18px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:all .2s;}
  .btn-ghost:hover{border-color:var(--moss-light);color:var(--moss);}
  .btn-criar,.btn-salvar{background:var(--moss);color:var(--cream);border:none;border-radius:2px;padding:9px 20px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s;}
  .btn-criar:hover,.btn-salvar:hover{background:var(--moss-dark);}

  .toast{position:fixed;bottom:28px;right:28px;background:var(--moss-dark);color:var(--cream);padding:12px 18px;border-radius:2px;font-size:13px;font-weight:500;box-shadow:0 8px 24px rgba(0,0,0,.25);z-index:999;transform:translateY(80px);opacity:0;transition:all .35s cubic-bezier(.34,1.56,.64,1);display:flex;align-items:center;gap:8px;}
  .toast.show{transform:translateY(0);opacity:1;}
  .toast.error{background:#7a3232;}

/* STATS */
.stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-bottom:30px;}
.stat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;padding:22px 20px;position:relative;overflow:hidden;transition:transform .2s,box-shadow .2s;}
.stat-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(47,61,37,.1);}
.stat-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
.stat-card.moss::before{background:linear-gradient(90deg,var(--moss),var(--sage));}
.stat-card.green::before{background:linear-gradient(90deg,var(--published),#5ab870);}
.stat-card.pending::before{background:linear-gradient(90deg,var(--pending),#e8a84a);}
.stat-card.blue::before{background:linear-gradient(90deg,#2a72a8,#5aa0d8);}
.stat-icon{width:38px;height:38px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:17px;margin-bottom:14px;}
.stat-card.moss .stat-icon{background:rgba(74,94,58,.1);}
.stat-card.green .stat-icon{background:rgba(58,122,74,.1);}
.stat-card.pending .stat-icon{background:rgba(196,131,42,.12);}
.stat-card.blue .stat-icon{background:rgba(42,114,168,.1);}
.stat-value{font-family:'Nunito',sans-serif;font-size:38px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:4px;letter-spacing:-1px;}
.stat-label{font-size:12px;color:var(--text-light);text-transform:uppercase;letter-spacing:.8px;font-weight:500;}

/* TOOLBAR */
.toolbar{display:flex;align-items:center;gap:12px;margin-bottom:20px;flex-wrap:wrap;}
.filter-select{background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;padding:8px 12px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);cursor:pointer;outline:none;transition:border-color .2s;}
.filter-select:focus{border-color:var(--moss-light);}
.search-bar{display:flex;align-items:center;gap:8px;background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;padding:8px 14px;flex:1;max-width:320px;}
.search-bar:focus-within{border-color:var(--moss-light);}
.search-bar input{border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;flex:1;}
.search-bar input::placeholder{color:var(--text-light);}
.toolbar-spacer{flex:1;}

/* PAGINAÇÃO (mesmo padrão visual da tela de usuários) */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:18px 4px 4px;margin-top:8px;}
.pag-info{font-size:12px;color:var(--text-light);font-weight:300;}
.pag-btns{display:flex;gap:4px;}
.pag-btn{min-width:32px;height:32px;padding:0 8px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:12px;cursor:pointer;color:var(--text-mid);font-family:'Nunito',sans-serif;font-weight:700;transition:all .15s;}
.pag-btn:hover:not(:disabled){border-color:var(--moss);color:var(--moss);}
.pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}
.pag-btn:disabled{opacity:.4;cursor:not-allowed;}

@media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
@media(max-width:480px){.stats-row{grid-template-columns:1fr;}}

  @media(max-width:1100px){.cat-grid{grid-template-columns:1fr 1fr;}}
  @media(max-width:768px){.sidebar{display:none;}.main{margin-left:0;}.content{padding:20px;}.topbar{padding:0 20px;}.cat-grid{grid-template-columns:1fr;}.pagination{flex-direction:column;gap:10px;align-items:flex-start;}}
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar-editor-admin.jsp" />

<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Gestão</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Categorias</span>
    </div>

  </div>

  <div class="content">
    <div class="section-header">
      <div>
        <div class="section-title">Gestão de <em>Categorias</em></div>
      </div>
      <button class="btn-primary" type="button" id="btnNovaCat">✚ Nova Categoria</button>
    </div>

    <%-- ===== CARDS DE STATS ===== --%>
    <div class="stats-row">
      <div class="stat-card moss">
        <div class="stat-icon">📂</div>
        <div class="stat-value"><%= totalCategorias %></div>
        <div class="stat-label">Total de Categorias</div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">✅</div>
        <div class="stat-value"><%= totalAtivas %></div>
        <div class="stat-label">Ativas</div>
      </div>
      <div class="stat-card pending">
        <div class="stat-icon">⏸️</div>
        <div class="stat-value"><%= totalInativas %></div>
        <div class="stat-label">Inativas</div>
      </div>
    </div>

    <%-- ===== TOOLBAR: BUSCA + FILTRO ===== --%>
    <div class="toolbar">
      <div class="search-bar">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" id="campoBusca" placeholder="Buscar categorias…">
      </div>
      <select class="filter-select" id="filterStatus">
        <option value="ativa" selected>Ativa</option>
        <option value="inativa">Inativa</option>
        <option value="">Todos os status</option>
      </select>
      <div class="toolbar-spacer"></div>
    </div>

    <div class="cat-grid" id="catGrid">
<%
    if (categorias != null && !categorias.isEmpty()) {
        for (Categoria cat : categorias) {
            boolean ativa = cat.getStatus_categoria() == StatusCategoria.ATIVA;
            String novoStatus = ativa ? "inativa" : "ativa";
            String statusLabel = ativa ? "Ativa" : "Inativa";
            String dotClass = ativa ? "active-dot" : "inactive-dot";
            String toggleLabel = ativa ? "🚫 Desativar" : "🔄 Ativar";
%>
<div class="cat-card" data-status="<%= ativa ? "ativa" : "inativa" %>">        <div class="cat-card-header">
          <div class="cat-emoji-box" data-cor="<%= esc(cat.getCor_categoria()) %>"><%= cat.getEmoji_categoria() %></div>
          <div class="cat-card-info">
            <div class="cat-card-name"><%= esc(cat.getNome_categoria()) %></div>
          </div>
        </div>
        <div class="cat-card-body">
          <div class="cat-desc"><%= esc(cat.getDescricao_categoria()) %></div>
        </div>
        <div class="cat-card-footer">
          <span class="cat-status">
            <span class="status-dot-sm <%= dotClass %>"></span>
            <%= statusLabel %>
          </span>

          <div class="action-group">
            <button class="act-btn btn-editar" type="button" title="Editar"
                    data-id="<%= cat.getId_categoria() %>"
                    data-nome="<%= esc(cat.getNome_categoria()) %>"
                    data-desc="<%= esc(cat.getDescricao_categoria()) %>"
                    data-emoji="<%= esc(cat.getEmoji_categoria()) %>"
                    data-cor="<%= esc(cat.getCor_categoria()) %>">✏️</button>

            <form class="form-inline" method="post" action="<%= ctx %>/CategoriaController">
              <input type="hidden" name="action" value="status">
              <input type="hidden" name="id" value="<%= cat.getId_categoria() %>">
              <input type="hidden" name="novoStatus" value="<%= novoStatus %>">
              <button class="act-btn <%= ativa ? "danger" : "reactivate" %>" type="submit"
                      title="<%= ativa ? "Desativar" : "Ativar" %>"><%= ativa ? "🚫" : "🔄" %></button>
            </form>

          </div>
        </div>
      </div>
<%
        }
    } else {
%>
      <div class="empty-state">
        <div class="empty-icon">🍳</div>
        <h3>Nenhuma categoria cadastrada</h3>
        <p>Clique em "Nova Categoria" para criar a primeira.</p>
      </div>
<%
    }
%>
    </div><%-- /cat-grid --%>

    <%-- ===== PAGINAÇÃO ===== --%>
    <div class="pagination" id="pagination">
      <div class="pag-info" id="pagInfo">—</div>
      <div class="pag-btns" id="pagBtns"></div>
    </div>

  </div><%-- /content --%>
</main>

<%-- ===== MODAL NOVA CATEGORIA ===== --%>
<div class="modal-overlay" id="modalNovaCat">
  <div class="modal-nova-cat">
    <form method="post" action="<%= ctx %>/CategoriaController">
      <input type="hidden" name="action" value="cadastrar">
      <input type="hidden" name="emoji" id="novaCatEmojiInput" value="<%= (emojis != null && !emojis.isEmpty()) ? esc(emojis.get(0).getUnicode_emoji()) : "" %>">
      <input type="hidden" name="cor" id="novaCatCorInput" value="<%= (cores != null && !cores.isEmpty()) ? esc(cores.get(0).getUnicode_cor()) : "" %>">

      <div class="modal-nova-cat-head">
        <div class="modal-nova-cat-title">✚ Nova Categoria</div>
        <button class="modal-close-btn" type="button" id="btnFecharNovaCat">✕</button>
      </div>
      <div class="modal-nova-cat-body">
        <div>
          <label class="form-label">Nome da Categoria</label>
          <input class="form-input" type="text" name="nome" id="novaCatNome" placeholder="ex: Bebidas" required>
        </div>
        <div>
          <label class="form-label">Descrição</label>
          <textarea class="form-input" name="descricao" id="novaCatDesc" rows="3" placeholder="Descreva brevemente esta categoria…"></textarea>
        </div>
        <div>
          <label class="form-label">Ícone</label>
          <div class="emoji-row" id="novaEmojiRow" data-input="novaCatEmojiInput">
<%
    if (emojis != null) {
        for (int i = 0; i < emojis.size(); i++) {
            CategoriaEmoji e = emojis.get(i);
            String selCls = (i == 0) ? " selected" : "";
%>
            <div class="emoji-opt<%= selCls %>" data-emoji="<%= esc(e.getUnicode_emoji()) %>"><%= e.getUnicode_emoji() %></div>
<%
        }
    }
%>
            <div class="emoji-add" data-target="novaEmojiRow" title="Mais emojis">+</div>
          </div>
        </div>
        <div>
          <label class="form-label">Cor de Destaque</label>
          <div class="color-row" id="novaColorRow" data-input="novaCatCorInput">
<%
    if (cores != null) {
        for (int i = 0; i < cores.size(); i++) {
            CategoriaCor c = cores.get(i);
            String selCls = (i == 0) ? " selected" : "";
%>
            <div class="color-swatch<%= selCls %>" data-cor="<%= esc(c.getUnicode_cor()) %>" style="background:<%= esc(c.getUnicode_cor()) %>" title="<%= esc(c.getUnicode_cor()) %>"></div>
<%
        }
    }
%>
          </div>
        </div>
      </div>
      <div class="modal-nova-cat-footer">
        <button class="btn-ghost" type="button" id="btnCancelarNovaCat">Cancelar</button>
        <button class="btn-criar" type="submit">✚ Criar Categoria</button>
      </div>
    </form>
  </div>
</div>

<%-- ===== MODAL EDITAR CATEGORIA ===== --%>
<div class="modal-overlay" id="modalEditarCat">
  <div class="modal-nova-cat">
    <form method="post" action="<%= ctx %>/CategoriaController">
      <input type="hidden" name="action" value="atualizar">
      <input type="hidden" name="id" id="editCatId">
      <input type="hidden" name="emoji" id="editCatEmojiInput">
      <input type="hidden" name="cor" id="editCatCorInput">

      <div class="modal-nova-cat-head">
        <div class="modal-nova-cat-title">✏️ Editar Categoria</div>
        <button class="modal-close-btn" type="button" id="btnFecharEditarCat">✕</button>
      </div>
      <div class="modal-nova-cat-body">
        <div class="edit-preview-bar" id="editPreviewBar">
          <div class="edit-preview-icon" id="editPreviewIcon">🎂</div>
          <div class="edit-preview-name" id="editPreviewName">Nome</div>
          <span class="edit-preview-lbl">Pré-visualização</span>
        </div>
        <div>
          <label class="form-label">Nome da Categoria</label>
          <input class="form-input" type="text" name="nome" id="editCatNome" placeholder="Nome da categoria" required>
        </div>
        <div>
          <label class="form-label">Descrição</label>
          <textarea class="form-input" name="descricao" id="editCatDesc" rows="3" placeholder="Descreva brevemente esta categoria…"></textarea>
        </div>
        <div>
          <label class="form-label">Ícone</label>
          <div class="emoji-row" id="editEmojiRow" data-input="editCatEmojiInput">
<%
    if (emojis != null) {
        for (CategoriaEmoji e : emojis) {
%>
            <div class="emoji-opt" data-emoji="<%= esc(e.getUnicode_emoji()) %>"><%= e.getUnicode_emoji() %></div>
<%
        }
    }
%>
            <div class="emoji-add" data-target="editEmojiRow" title="Mais emojis">+</div>
          </div>
        </div>
        <div>
          <label class="form-label">Cor de Destaque</label>
          <div class="color-row" id="editColorRow" data-input="editCatCorInput">
<%
    if (cores != null) {
        for (CategoriaCor c : cores) {
%>
            <div class="color-swatch" data-cor="<%= esc(c.getUnicode_cor()) %>" style="background:<%= esc(c.getUnicode_cor()) %>" title="<%= esc(c.getUnicode_cor()) %>"></div>
<%
        }
    }
%>
          </div>
        </div>
      </div>
      <div class="modal-nova-cat-footer">
        <button class="btn-ghost" type="button" id="btnCancelarEditarCat">Cancelar</button>
        <button class="btn-salvar" type="submit">💾 Salvar Alterações</button>
      </div>
    </form>
  </div>
</div>

<%-- ===== MODAL EMOJI PICKER (lista fixa, pré-definida aqui no JSP) ===== --%>
<div class="modal-overlay" id="emojiModal">
  <div class="modal-sub">
    <div class="modal-sub-head">
      <div class="modal-sub-title">Escolher ícone</div>
      <button class="modal-close-btn" type="button" id="closeEmojiModal">✕</button>
    </div>
    <div class="modal-sub-body">
      <div class="emoji-cats" id="emojiCats">
        <button class="emoji-cat-btn active" type="button" data-cat="all">Todos</button>
        <button class="emoji-cat-btn" type="button" data-cat="food">Comida</button>
        <button class="emoji-cat-btn" type="button" data-cat="drink">Bebidas</button>
        <button class="emoji-cat-btn" type="button" data-cat="veggie">Vegetais</button>
        <button class="emoji-cat-btn" type="button" data-cat="sweet">Doces</button>
        <button class="emoji-cat-btn" type="button" data-cat="other">Outros</button>
      </div>
      <div class="emoji-picker-grid" id="emojiPickerGrid">
        <%-- preenchido via JS a partir do EMOJI_DB pré-definido --%>
      </div>
    </div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
(function() {
  var MSG_SUCESSO = "<%= jsEsc(msgSucesso) %>";
  var MSG_ERRO = "<%= jsEsc(msgErro) %>";

  // ─── LISTA FIXA DE EMOJIS (pré-definida aqui no JSP, não vem do banco) ──
  var EMOJI_DB = {
    food:   ['🍔','🍕','🌮','🌯','🥙','🫔','🥗','🍜','🍝','🍲','🥘','🫕','🍛','🍣','🍤','🍱','🥟','🍗','🍖','🥩','🥚','🧆','🥞','🧇'],
    drink:  ['🥤','🍹','🍸','🍷','🍺','🧃','☕','🍵','🧋','🥛','🫖','🍶','🥂','🍻'],
    veggie: ['🥬','🥦','🥕','🌽','🧅','🧄','🫑','🍆','🥑','🍅','🥒','🥝','🍋','🫐','🍓','🍇','🍒','🍑','🥭','🍍'],
    sweet:  ['🎂','🍰','🧁','🍩','🍪','🍫','🍬','🍭','🍦','🍧','🍨','🥐','🍞','🥖','🥨'],
    other:  ['🫕','🥘','🍲','🥣','🥗','🧑‍🍳','👨‍🍳','🍽️','🥄','🔪','🫙','🧂','🌶️','🫚','🫛']
  };
  var ALL_EMOJIS = Array.from(new Set([].concat(EMOJI_DB.food, EMOJI_DB.drink, EMOJI_DB.veggie, EMOJI_DB.sweet, EMOJI_DB.other)));

  function openModal(m){ m.classList.add('open'); }
  function closeModal(m){ m.classList.remove('open'); }

  function showToast(msg, isError) {
    var t = document.getElementById('toast');
    t.textContent = (isError ? '⚠️ ' : '✅ ') + msg;
    t.classList.toggle('error', !!isError);
    t.classList.add('show');
    setTimeout(function(){ t.classList.remove('show'); }, 3200);
  }

  function hexToRgba(hex, alpha) {
    if (!hex) return 'rgba(74,94,58,' + alpha + ')';
    hex = hex.trim();
    if (hex.indexOf('rgb') === 0) return hex;
    hex = hex.replace('#','');
    if (hex.length === 3) hex = hex.split('').map(function(c){return c+c;}).join('');
    if (hex.length !== 6) return 'rgba(74,94,58,' + alpha + ')';
    var r = parseInt(hex.substring(0,2),16);
    var g = parseInt(hex.substring(2,4),16);
    var b = parseInt(hex.substring(4,6),16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
  }

  document.querySelectorAll('.cat-emoji-box[data-cor]').forEach(function(box) {
    box.style.background = hexToRgba(box.dataset.cor, 0.14);
  });

  if (MSG_SUCESSO) showToast(MSG_SUCESSO, false);
  if (MSG_ERRO) showToast(MSG_ERRO, true);

  // ─── MODAL NOVA CATEGORIA ───────────────────────────────────────────────
  var modalNova = document.getElementById('modalNovaCat');
  document.getElementById("btnNovaCat").addEventListener("click", function () {
	    document.getElementById("novaCatNome").value = "";
	    document.getElementById("novaCatDesc").value = "";
	    openModal(modalNova);
	});
  document.getElementById("btnFecharNovaCat")
  .addEventListener("click", function () {
      closeModal(modalNova);
  });

document.getElementById("btnCancelarNovaCat")
  .addEventListener("click", function () {
      closeModal(modalNova);
  });

  // ─── MODAL EDITAR CATEGORIA ─────────────────────────────────────────────
  var modalEditar = document.getElementById('modalEditarCat');

  document.getElementById('catGrid').addEventListener('click', function(e) {
    var btn = e.target.closest('.btn-editar');
    if (!btn) return;

    document.getElementById('editCatId').value = btn.dataset.id;
    document.getElementById('editCatNome').value = btn.dataset.nome;
    document.getElementById('editCatDesc').value = btn.dataset.desc;
    document.getElementById('editCatEmojiInput').value = btn.dataset.emoji;
    document.getElementById('editCatCorInput').value = btn.dataset.cor;

    document.getElementById('editPreviewIcon').textContent = btn.dataset.emoji;
    document.getElementById('editPreviewIcon').style.background = hexToRgba(btn.dataset.cor, 0.14);
    document.getElementById('editPreviewName').textContent = btn.dataset.nome;

    document.querySelectorAll('#editEmojiRow .emoji-opt').forEach(function(el) {
      el.classList.toggle('selected', el.dataset.emoji === btn.dataset.emoji);
    });
    document.querySelectorAll('#editColorRow .color-swatch').forEach(function(el) {
      el.classList.toggle('selected', el.dataset.cor === btn.dataset.cor);
    });

    openModal(modalEditar);
  });

  document.getElementById('editCatNome').addEventListener('input', function() {
    document.getElementById('editPreviewName').textContent = this.value || 'Nome';
  });

  document.getElementById("btnFecharEditarCat")
  .addEventListener("click", function () {
      closeModal(modalEditar);
  });

document.getElementById("btnCancelarEditarCat")
  .addEventListener("click", function () {
      closeModal(modalEditar);
  });
  // ─── SELEÇÃO DE EMOJI / COR (genérico para os dois modais) ─────────────
  document.addEventListener('click', function(e) {
    var opt = e.target.closest('.emoji-opt');
    if (opt) {
      var row = opt.closest('.emoji-row');
      row.querySelectorAll('.emoji-opt').forEach(function(el){ el.classList.remove('selected'); });
      opt.classList.add('selected');
      var inputId = row.dataset.input;
      if (inputId) document.getElementById(inputId).value = opt.dataset.emoji;
      if (inputId === 'editCatEmojiInput') {
        document.getElementById('editPreviewIcon').textContent = opt.dataset.emoji;
      }
      return;
    }

    var sw = e.target.closest('.color-swatch');
    if (sw) {
      var crow = sw.closest('.color-row');
      crow.querySelectorAll('.color-swatch').forEach(function(el){ el.classList.remove('selected'); });
      sw.classList.add('selected');
      var cInputId = crow.dataset.input;
      if (cInputId) document.getElementById(cInputId).value = sw.dataset.cor;
      if (cInputId === 'editCatCorInput') {
        document.getElementById('editPreviewIcon').style.background = hexToRgba(sw.dataset.cor, 0.14);
      }
    }
  });

  // ─── CONFIRMAÇÃO DE EXCLUSÃO ─────────────────────────────────────────────
  document.querySelectorAll('.form-excluir').forEach(function(form) {
    form.addEventListener('submit', function(e) {
      var nome = form.querySelector('.footer-act-btn.danger').dataset.nome || 'esta categoria';
      if (!confirm('Tem certeza que deseja excluir a categoria "' + nome + '"?')) {
        e.preventDefault();
      }
    });
  });

  // ─── FECHAR MODAL CLICANDO FORA ─────────────────────────────────────────
  [modalNova, modalEditar].forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m); });
  });

//─── BUSCA + FILTRO DE STATUS + PAGINAÇÃO ───────────────────────────────
  var PAGE_SIZE = 6;      // quantos cards por página — ajuste à vontade
  var paginaAtual = 1;
  var todosCards = Array.from(document.querySelectorAll('#catGrid .cat-card'));

  // Retorna os cards que batem com busca + filtro de status (sem mexer no DOM ainda)
  function getCardsFiltrados() {
    var termo = document.getElementById('campoBusca').value.trim().toLowerCase();
    var status = document.getElementById('filterStatus').value;

    return todosCards.filter(function(card) {
      var nome = (card.querySelector('.cat-card-name') || {}).textContent || '';
      var bateNome = nome.toLowerCase().indexOf(termo) !== -1;
      var bateStatus = !status || card.dataset.status === status;
      return bateNome && bateStatus;
    });
  }

  function renderPagina() {
    var filtrados = getCardsFiltrados();
    var totalPaginas = Math.max(1, Math.ceil(filtrados.length / PAGE_SIZE));

    if (paginaAtual > totalPaginas) paginaAtual = totalPaginas;
    if (paginaAtual < 1) paginaAtual = 1;

    // esconde todos, depois mostra só o "fatia" da página atual
    todosCards.forEach(function(card) { card.style.display = 'none'; });

    var inicio = (paginaAtual - 1) * PAGE_SIZE;
    var fim = inicio + PAGE_SIZE;
    filtrados.slice(inicio, fim).forEach(function(card) { card.style.display = ''; });

    renderInfo(filtrados.length, inicio, fim);
    renderBotoes(totalPaginas);
  }

  function renderInfo(total, inicio, fim) {
    var info = document.getElementById('pagInfo');
    if (total === 0) {
      info.textContent = 'Nenhuma categoria encontrada';
      return;
    }
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
      b.addEventListener('click', function() {
        paginaAtual = page;
        renderPagina();
      });
      wrap.appendChild(b);
    }

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
  document.getElementById('filterStatus').addEventListener('change', function() {
    paginaAtual = 1;
    renderPagina();
  });

  // primeira renderização ao carregar a página
  renderPagina();
  
//================= EMOJI PICKER =================

  var emojiModal = document.getElementById("emojiModal");
  var emojiGrid = document.getElementById("emojiPickerGrid");
  var currentEmojiRow = null;

  // abre o picker
  document.addEventListener("click", function(e){

      var btn = e.target.closest(".emoji-add");
      if(!btn) return;

      currentEmojiRow = document.getElementById(btn.dataset.target);

      renderEmojiGrid("all");

      openModal(emojiModal);
  });

  // fecha
document.getElementById("closeEmojiModal")
    .addEventListener("click", function () {
        closeModal(emojiModal);
    });

  emojiModal.addEventListener("click", function(e){
      if(e.target === emojiModal){
          closeModal(emojiModal);
      }
  });

  // troca categoria
  document.querySelectorAll(".emoji-cat-btn").forEach(function(btn){

      btn.addEventListener("click", function(){

          document.querySelectorAll(".emoji-cat-btn")
              .forEach(function(b){
                  b.classList.remove("active");
              });

          btn.classList.add("active");

          renderEmojiGrid(btn.dataset.cat);
      });

  });

  // desenha emojis
  function renderEmojiGrid(cat){

      emojiGrid.innerHTML = "";

      var lista =
          cat === "all"
              ? ALL_EMOJIS
              : EMOJI_DB[cat] || [];

      lista.forEach(function(emoji){

          var div = document.createElement("div");

          div.className = "emoji-picker-item";
          div.textContent = emoji;

          div.addEventListener("click", function () {

        	    var input =
        	        document.getElementById(
        	            currentEmojiRow.dataset.input
        	        );

        	    input.value = emoji;

        	    currentEmojiRow.querySelectorAll(".emoji-opt")
        	        .forEach(function(el){
        	            el.classList.remove("selected");
        	        });

        	    var existente =
        	        currentEmojiRow.querySelector(
        	            '[data-emoji="' + emoji + '"]'
        	        );

        	    if(existente){

        	        existente.classList.add("selected");

        	    }else{

        	        var novo = document.createElement("div");

        	        novo.className = "emoji-opt selected";
        	        novo.dataset.emoji = emoji;
        	        novo.textContent = emoji;

        	        currentEmojiRow.insertBefore(
        	            novo,
        	            currentEmojiRow.querySelector(".emoji-add")
        	        );
        	    }

        	    if(currentEmojiRow.dataset.input === "editCatEmojiInput"){
        	        document.getElementById("editPreviewIcon").textContent = emoji;
        	    }

        	    closeModal(emojiModal);

        	});

          emojiGrid.appendChild(div);

      });

  }
})();
</script>
</body>
</html>
