<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="br.com.saborearte.model.Comentario" %>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
      .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }
  private int n(Object value) { return value instanceof Number ? ((Number)value).intValue() : 0; }
%>
<%
  List<Comentario> comentarios = (List<Comentario>) request.getAttribute("comentarios");
  if (comentarios == null) comentarios = Collections.emptyList();
  String ctx = request.getContextPath();
  String filtro = request.getAttribute("filtro") == null ? "" : String.valueOf(request.getAttribute("filtro"));
  String statusFiltro = request.getAttribute("statusFiltro") == null ? "" : String.valueOf(request.getAttribute("statusFiltro"));
  String dataFiltro = request.getAttribute("data") == null ? "" : String.valueOf(request.getAttribute("data"));
  int pageAtual = Math.max(1, n(request.getAttribute("page")));
  int pageSize = Math.max(1, n(request.getAttribute("size")));
  int total = n(request.getAttribute("total"));
  int totalPages = Math.max(1, (int)Math.ceil(total / (double)pageSize));
  String queryBase = "filtro=" + URLEncoder.encode(filtro, StandardCharsets.UTF_8)
      + "&status=" + URLEncoder.encode(statusFiltro, StandardCharsets.UTF_8)
      + "&data=" + URLEncoder.encode(dataFiltro, StandardCharsets.UTF_8)
      + "&size=" + pageSize;
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Central de Moderação de Comentários</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;
    --draft:#6a7a8a;--draft-bg:#eef1f4;--archived:#8a7a6a;--archived-bg:#f4f0ec;
    --revision:#a05a3a;--revision-bg:#f6e6de;--error:#9b4444;--error-bg:#fdf0f0;
    --sidebar-w:260px;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  /* ===== SIDEBAR ===== */
  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,0.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,0.1) 0%,transparent 60%);pointer-events:none;}
  .sidebar-brand{padding:28px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .brand-row{display:flex;align-items:center;gap:12px;}
  .brand-badge{width:38px;height:38px;background:linear-gradient(135deg,var(--moss-light),var(--sage));border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  .brand-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--cream);display:block;line-height:1;}
  .brand-sub{font-size:10px;color:var(--sage);text-transform:uppercase;letter-spacing:1.2px;margin-top:3px;display:block;font-weight:300;}
  .sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;cursor:pointer;}
  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,#8e44ad,#6c3483);border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--cream);flex-shrink:0;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:300;}
  .sidebar-nav{flex:1;padding:16px 0;position:relative;z-index:1;}
  .nav-section-label{font-size:9px;text-transform:uppercase;letter-spacing:1.8px;color:rgba(163,177,138,0.5);padding:16px 24px 6px;font-weight:500;}
  .nav-item{display:flex;align-items:center;gap:12px;padding:11px 24px;color:rgba(245,240,232,0.7);text-decoration:none;font-size:14px;font-weight:400;cursor:pointer;transition:all 0.2s;border-left:3px solid transparent;}
  .nav-item:hover{color:var(--cream);background:rgba(255,255,255,0.06);border-left-color:var(--sage);}
  .nav-item.active{color:var(--cream);background:rgba(163,177,138,0.15);border-left-color:var(--sage-light);font-weight:500;}
  .nav-icon{width:22px;text-align:center;font-size:16px;flex-shrink:0;}
  .nav-badge{margin-left:auto;background:var(--gold);color:var(--moss-dark);font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;padding:2px 7px;border-radius:10px;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:2px;color:rgba(245,240,232,0.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all 0.2s;}
  .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}

  /* ===== MAIN / TOPBAR ===== */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .topbar-left{display:flex;align-items:center;gap:14px;}
  .menu-toggle{display:none;background:none;border:none;font-size:24px;cursor:pointer;color:var(--text-dark);padding:4px;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:16px;}
  .notif-btn{width:36px;height:36px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;position:relative;transition:all 0.2s;}
  .notif-btn:hover{background:var(--cream-dark);}
  .notif-dot{position:absolute;top:4px;right:4px;width:8px;height:8px;background:var(--gold);border-radius:50%;border:2px solid var(--warm-white);}

  /* ===== CONTENT ===== */
  .content{flex:1;padding:50px 40px 40px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:36px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}

  /* ===== STAT CARDS (compactos) ===== */
  .stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:22px;}
  .stat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;padding:14px 16px;position:relative;overflow:hidden;transition:transform 0.2s,box-shadow 0.2s;cursor:default;display:flex;align-items:center;gap:12px;}
  .stat-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(47,61,37,0.1);}
  .stat-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
  .stat-card.pending::before{background:linear-gradient(90deg,var(--pending),#e8a84a);}
  .stat-card.moss::before{background:linear-gradient(90deg,var(--moss),var(--sage));}
  .stat-card.red::before{background:linear-gradient(90deg,var(--error),#c96a6a);}
  .stat-card.gold::before{background:linear-gradient(90deg,var(--gold),var(--gold-light));}
  .stat-icon{width:34px;height:34px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
  .stat-card.pending .stat-icon{background:rgba(196,131,42,0.12);}
  .stat-card.moss .stat-icon{background:rgba(74,94,58,0.1);}
  .stat-card.red .stat-icon{background:rgba(155,68,68,0.1);}
  .stat-card.gold .stat-icon{background:rgba(196,162,101,0.1);}
  .stat-text{min-width:0;}
  .stat-value{font-family:'Nunito',sans-serif;font-size:24px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:2px;letter-spacing:-0.5px;transition:color 0.2s;}
  .stat-label{font-size:10.5px;color:var(--text-light);text-transform:uppercase;letter-spacing:0.6px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

  /* ===== FILTER PANEL (lateral) ===== */
  .content-layout{display:grid;grid-template-columns:260px 1fr;gap:24px;align-items:start;}
  .right-panel{min-width:0;}
  .filter-panel{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;position:sticky;top:88px;}
  .filter-panel-head{padding:14px 18px;border-bottom:1px solid var(--cream-dark);font-size:11px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1.2px;display:flex;align-items:center;gap:8px;}
  .filter-bar{display:flex;flex-direction:column;align-items:stretch;gap:16px;padding:18px;}
  .filter-field{display:flex;flex-direction:column;gap:6px;width:100%;}
  .filter-label{font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1px;}
  .filter-input,.filter-select{width:100%;padding:9px 12px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);background:var(--cream);transition:border-color 0.2s,box-shadow 0.2s;outline:none;}
  .filter-input:focus,.filter-select:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.08);}
  .search-wrap{display:flex;align-items:center;gap:8px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;padding:9px 14px;transition:border-color 0.2s,box-shadow 0.2s;width:100%;}
  .search-wrap:focus-within{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,0.08);}
  .search-wrap input{border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;flex:1;min-width:0;}
  .search-wrap input::placeholder{color:var(--text-light);font-weight:300;}
  .btn-clear-filters{width:100%;padding:9px 16px;background:none;border:1.5px solid var(--cream-dark);border-radius:2px;color:var(--text-mid);font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;white-space:nowrap;}
  .btn-clear-filters:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}

  /* ===== TABLE CARD ===== */
  .table-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .table-card-head{padding:16px 22px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .table-card-title{font-size:15px;font-weight:600;color:var(--text-dark);}
  .table-card-meta{font-size:11px;color:var(--text-light);font-weight:300;}
  .table-wrap{overflow-x:auto;}
  .data-table{width:100%;border-collapse:collapse;font-size:13px;}
  .data-table thead th{padding:10px 16px;text-align:left;background:var(--cream);border-bottom:2px solid var(--cream-dark);font-size:10px;text-transform:uppercase;letter-spacing:1px;color:var(--text-light);font-weight:700;white-space:nowrap;}
  .data-table tbody tr{border-bottom:1px solid var(--cream-dark);transition:background 0.12s;}
  .data-table tbody tr:last-child{border-bottom:none;}
  .data-table tbody tr:hover{background:rgba(245,240,232,0.7);}
  .data-table tbody tr.is-blocked{opacity:0.55;}
  .data-table td{padding:12px 16px;color:var(--text-mid);vertical-align:middle;}

  .table-footer{padding:12px 20px;border-top:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .footer-info{font-size:11px;color:var(--text-light);font-weight:300;}
  .footer-info strong{font-family:'Nunito',sans-serif;font-weight:700;color:var(--text-mid);}
  .pagination{display:flex;gap:4px;}
  .pag-btn{width:28px;height:28px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-family:'Nunito',sans-serif;font-size:11px;font-weight:700;color:var(--text-light);display:flex;align-items:center;justify-content:center;transition:all 0.15s;}
  .pag-btn:hover{border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}
  .pag-btn:disabled{opacity:0.35;cursor:not-allowed;}
  .pag-btn:disabled:hover{border-color:var(--cream-dark);color:var(--text-light);}

  .author-cell{display:flex;align-items:center;gap:9px;}
  .author-dot{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;color:white;flex-shrink:0;}
  .author-name{font-size:12.5px;color:var(--text-dark);font-weight:600;}
  .author-tag{font-size:10px;color:var(--text-light);font-weight:300;}

  .recipe-tag{font-size:12px;color:var(--text-mid);display:flex;align-items:center;gap:6px;max-width:150px;}

  .comment-preview{font-size:12.5px;color:var(--text-mid);max-width:230px;overflow:hidden;text-overflow:ellipsis;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5;font-style:italic;}

  .report-badge{display:inline-flex;align-items:center;gap:5px;background:var(--error-bg);color:var(--error);font-family:'Nunito',sans-serif;font-weight:800;font-size:12px;padding:4px 10px;border-radius:20px;}

  .reason-tag{display:inline-block;background:var(--cream);border:1px solid var(--cream-dark);color:var(--text-mid);font-size:10.5px;font-weight:600;padding:3px 9px;border-radius:20px;white-space:nowrap;}

  .pill{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:2px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;white-space:nowrap;}
  .pill-dot{width:5px;height:5px;border-radius:50%;background:currentColor;}
  .pill.pendente{background:var(--pending-bg);color:var(--pending);}
  .pill.aprovado{background:var(--published-bg);color:var(--published);}
  .pill.resolvido{background:var(--published-bg);color:var(--published);}
  .pill.removido{background:var(--error-bg);color:var(--error);}
  .pill.rejeitado{background:var(--revision-bg);color:var(--revision);}
  .pill.bloqueado{background:var(--draft-bg);color:var(--draft);}

  .row-actions{display:flex;gap:5px;flex-wrap:wrap;} .row-actions form{display:inline-flex;}
  .row-btn{width:27px;height:27px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-size:12px;display:flex;align-items:center;justify-content:center;color:var(--text-light);transition:all 0.15s;}
  .row-btn:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}
  .row-btn.keep:hover{border-color:var(--published);color:var(--published);background:var(--published-bg);}
  .row-btn.remove:hover{border-color:var(--error);color:var(--error);background:var(--error-bg);}
  .row-btn.resolve:hover{border-color:var(--gold);color:var(--pending);background:var(--gold-pale);}
  .row-btn.block:hover{border-color:var(--draft);color:var(--draft);background:var(--draft-bg);}
  .row-btn:disabled{opacity:0.3;cursor:not-allowed;}
  .row-btn:disabled:hover{border-color:var(--cream-dark);color:var(--text-light);background:none;}

  .empty-state{text-align:center;padding:70px 30px;}
  .empty-icon{font-size:48px;margin-bottom:14px;opacity:0.4;}
  .empty-text{font-family:'Playfair Display',serif;font-size:18px;color:var(--text-light);font-style:italic;margin-bottom:6px;}
  .empty-sub{font-size:13px;color:var(--text-light);font-weight:300;}

  /* ===== MODALS ===== */
  .modal-overlay{position:fixed;inset:0;background:rgba(30,39,24,0.55);backdrop-filter:blur(2px);display:none;align-items:center;justify-content:center;z-index:300;padding:24px;}
  .modal-overlay.open{display:flex;}
  .modal-box{background:var(--warm-white);border-radius:4px;max-width:560px;width:100%;max-height:88vh;overflow:hidden;box-shadow:0 24px 60px rgba(30,39,24,0.3);animation:modalIn 0.25s ease;display:flex;flex-direction:column;}
  .modal-box.tiny{max-width:420px;}
  @keyframes modalIn{from{opacity:0;transform:translateY(10px) scale(.98);}to{opacity:1;transform:none;}}
  .modal-head{padding:20px 24px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;background:var(--warm-white);flex-shrink:0;}
  .modal-title{font-family:'Playfair Display',serif;font-size:19px;font-weight:600;color:var(--text-dark);}
  .modal-close{width:30px;height:30px;border:none;background:var(--cream);border-radius:2px;cursor:pointer;font-size:16px;color:var(--text-mid);flex-shrink:0;transition:all 0.15s;}
  .modal-close:hover{background:var(--cream-dark);color:var(--text-dark);}
  .modal-body{padding:24px;overflow-y:auto;flex:1;}
  .modal-footer{padding:16px 24px;border-top:1px solid var(--cream-dark);display:flex;flex-wrap:wrap;justify-content:flex-end;gap:10px;flex-shrink:0;}
  .confirm-message{font-size:13.5px;color:var(--text-mid);line-height:1.7;}
  .confirm-icon{width:46px;height:46px;border-radius:50%;background:var(--gold-pale);display:flex;align-items:center;justify-content:center;font-size:20px;margin-bottom:16px;}

  .btn{display:inline-flex;align-items:center;gap:7px;padding:9px 18px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;white-space:nowrap;}
  .btn:hover{transform:translateY(-1px);box-shadow:0 3px 10px rgba(0,0,0,0.12);}
  .btn-primary{background:var(--moss);color:var(--cream);}
  .btn-primary:hover{background:var(--moss-dark);}
  .btn-gold{background:var(--gold);color:var(--moss-dark);}
  .btn-gold:hover{background:var(--gold-light);}
  .btn-green{background:var(--published);color:var(--warm-white);}
  .btn-green:hover{background:#2c6038;}
  .btn-red{background:var(--error);color:var(--warm-white);}
  .btn-red:hover{background:#7c3535;}
  .btn-outline{background:none;color:var(--text-mid);border:1.5px solid var(--cream-dark);}
  .btn-outline:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}
  .btn:disabled{opacity:0.4;cursor:not-allowed;transform:none !important;box-shadow:none !important;}

  /* View comment modal specifics */
  .view-user-row{display:flex;align-items:center;gap:12px;margin-bottom:18px;padding-bottom:18px;border-bottom:1px solid var(--cream-dark);}
  .view-user-avatar{width:46px;height:46px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:15px;color:white;flex-shrink:0;}
  .view-user-name{font-size:14px;font-weight:700;color:var(--text-dark);}
  .view-user-sub{font-size:11.5px;color:var(--text-light);font-weight:300;}
  .view-block{margin-bottom:20px;}
  .view-block:last-child{margin-bottom:0;}
  .view-block-title{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--moss);margin-bottom:10px;display:flex;align-items:center;gap:7px;}
  .comment-full{background:var(--cream);border:1px solid var(--cream-dark);border-radius:3px;padding:16px;font-size:14px;color:var(--text-dark);line-height:1.7;font-style:italic;}
  .view-meta-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px 20px;}
  .view-meta-item{font-size:12.5px;color:var(--text-mid);}
  .view-meta-item b{color:var(--text-dark);display:block;font-weight:600;margin-bottom:2px;font-size:10px;text-transform:uppercase;letter-spacing:0.6px;color:var(--text-light);}
  .view-meta-item span{font-size:13px;color:var(--text-dark);font-weight:500;}
  .report-reasons-list{display:flex;flex-wrap:wrap;gap:6px;}

  /* Toast */
  .toast{position:fixed;bottom:28px;right:28px;background:var(--moss-dark);color:var(--cream);padding:14px 20px;border-radius:3px;font-size:13px;font-weight:500;box-shadow:0 12px 30px rgba(30,39,24,0.3);display:flex;align-items:center;gap:10px;z-index:400;transform:translateY(20px);opacity:0;pointer-events:none;transition:all 0.3s ease;}
  .toast.show{transform:translateY(0);opacity:1;}
  .toast.success{background:var(--moss-dark);}
  .toast.red{background:#6e3232;}
  .toast.gray{background:#4a4a4a;}
  .toast.gold{background:#8a6d2e;}

  /* ===== RESPONSIVE ===== */
  @media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:900px){.content-layout{grid-template-columns:1fr;} .filter-panel{position:static;} .view-meta-grid{grid-template-columns:1fr;}}
  @media(max-width:768px){.sidebar{transform:translateX(-100%);transition:transform 0.3s;} .sidebar.open{transform:translateX(0);} .main{margin-left:0;} .content{padding:24px 20px;} .topbar{padding:0 20px;} .menu-toggle{display:block;}}
  @media(max-width:480px){.stats-row{grid-template-columns:1fr;}}
</style>
</head>
<body>

<!-- ===== SIDEBAR EDITOR (estático) ===== -->
<%
  request.setAttribute("currentPage", "comentarios");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />

<div id="overlay" onclick="closeSidebar()" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:99"></div>

<main class="main">
  <div class="topbar">
    <div class="topbar-left">
      <button class="menu-toggle" onclick="toggleSidebar()">☰</button>
      <div class="page-crumb">
        <span>Principal</span>
        <span style="color:var(--cream-dark)">/</span>
        <span class="current">Comentários</span>
      </div>
    </div>
    <div class="topbar-right">

    </div>
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Central de <em>Moderação</em></div>
        <div class="section-date">Acompanhe comentários pendentes, mantidos e removidos</div>
      </div>
    </div>

    <!-- STAT CARDS -->
    <div class="stats-row">
      <div class="stat-card pending">
        <div class="stat-icon">🚩</div>
        <div class="stat-text">
          <div class="stat-value"><%= n(request.getAttribute("totalComentarios")) %></div>
          <div class="stat-label">Total de Comentários</div>
        </div>
      </div>
      <div class="stat-card moss">
        <div class="stat-icon">⏳</div>
        <div class="stat-text">
          <div class="stat-value"><%= n(request.getAttribute("totalPendentes")) %></div>
          <div class="stat-label">Pendentes</div>
        </div>
      </div>
      <div class="stat-card red">
        <div class="stat-icon">🗑</div>
        <div class="stat-text">
          <div class="stat-value"><%= n(request.getAttribute("totalRemovidos")) %></div>
          <div class="stat-label">Comentários Removidos</div>
        </div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">🚫</div>
        <div class="stat-text">
          <div class="stat-value"><%= n(request.getAttribute("totalAprovados")) %></div>
          <div class="stat-label">Mantidos no Ar</div>
        </div>
      </div>
    </div>

    <div class="content-layout">

      <!-- FILTER PANEL (lateral) -->
      <div class="filter-panel">
        <div class="filter-panel-head">🔍 Filtros</div>
        <form class="filter-bar" method="get" action="<%= ctx %>/comentarios-moderacao">
          <div class="filter-field"><span class="filter-label">Pesquisar</span><div class="search-wrap"><span>🔍</span><input type="text" name="filtro" value="<%= h(filtro) %>" placeholder="Comentário, usuário ou receita"></div></div>
          <div class="filter-field"><span class="filter-label">Status</span><select class="filter-select" name="status">
            <option value="">Todos</option>
            <option value="PENDENTE" <%= "PENDENTE".equals(statusFiltro) ? "selected" : "" %>>Pendente</option>
            <option value="APROVADO" <%= "APROVADO".equals(statusFiltro) ? "selected" : "" %>>Mantido</option>
            <option value="REMOVIDO" <%= "REMOVIDO".equals(statusFiltro) ? "selected" : "" %>>Removido</option>
            <option value="REJEITADO" <%= "REJEITADO".equals(statusFiltro) ? "selected" : "" %>>Rejeitado</option>
          </select></div>
          <div class="filter-field"><span class="filter-label">Data</span><input type="date" class="filter-input" name="data" value="<%= h(dataFiltro) %>"></div>
          <input type="hidden" name="size" value="<%= pageSize %>">
          <button class="btn btn-primary" type="submit">Aplicar filtros</button>
          <a class="btn-clear-filters" href="<%= ctx %>/comentarios-moderacao">✕ Limpar filtros</a>
        </form>
      </div>

      <!-- TABLE -->
      <div class="right-panel">
        <div class="table-card">
          <div class="table-card-head">
            <div class="table-card-title">💬 Moderação de comentários</div>
            <div class="table-card-meta"><%= total %> comentário(s) encontrado(s)</div>
          </div>
          <div class="table-wrap">
            <table class="data-table">
              <thead><tr><th>Usuário</th><th>Receita</th><th>Comentário</th><th>Data</th><th>Status</th><th>Ações</th></tr></thead>
              <tbody id="tableBody">
              <% for (Comentario comentario : comentarios) {
                   String nome = h(comentario.getNome_usuario());
                   String inicial = nome.isEmpty() ? "?" : nome.substring(0, 1).toUpperCase();
                   String status = comentario.getStatus_comentario() == null ? "" : comentario.getStatus_comentario().name();
                   String pill = status.toLowerCase(); %>
                <tr>
                  <td><div class="author-cell"><div class="author-dot" style="background:var(--moss)"><%= inicial %></div><div><div class="author-name"><%= nome %></div><div class="author-tag">ID <%= comentario.getUsuario() %></div></div></div></td>
                  <td><div class="recipe-tag">🍽️ <%= h(comentario.getTitulo_receita()) %></div></td>
                  <td><div class="comment-preview">“<%= h(comentario.getTexto_comentario()) %>”</div></td>
                  <td><%= h(comentario.getData_criacao_comentario()) %></td>
                  <td><span class="pill <%= pill %>"><span class="pill-dot"></span><%= h(status) %></span></td>
                  <td><div class="row-actions">
                    <% if ("PENDENTE".equals(status)) { %>
                    <form method="post" action="<%= ctx %>/comentarios-moderacao"><input type="hidden" name="action" value="manter"><input type="hidden" name="comentarioId" value="<%= comentario.getId_comentario() %>"><button class="row-btn keep" type="submit" title="Manter comentário">✓</button></form>
                    <form method="post" action="<%= ctx %>/comentarios-moderacao"><input type="hidden" name="action" value="remover"><input type="hidden" name="comentarioId" value="<%= comentario.getId_comentario() %>"><button class="row-btn remove" type="submit" title="Remover comentário">🗑</button></form>
                    <% } %>
                    <form method="post" action="<%= ctx %>/comentarios-moderacao" onsubmit="return confirm('Inativar este usuário?')"><input type="hidden" name="action" value="inativarUsuario"><input type="hidden" name="usuarioId" value="<%= comentario.getUsuario() %>"><button class="row-btn block" type="submit" title="Inativar usuário">🚫</button></form>
                  </div></td>
                </tr>
              <% } %>
              <% if (comentarios.isEmpty()) { %><tr><td colspan="6"><div class="empty-state"><div class="empty-icon">🕊️</div><div class="empty-text">Nenhum comentário encontrado</div><div class="empty-sub">Ajuste os filtros ou aguarde novas ocorrências.</div></div></td></tr><% } %>
              </tbody>
            </table>
          </div>
          <div class="table-footer">
            <div class="footer-info">Página <strong><%= pageAtual %></strong> de <strong><%= totalPages %></strong> · <%= total %> registro(s)</div>
            <div class="pagination">
              <a class="pag-btn" href="<%= ctx %>/comentarios-moderacao?<%= queryBase %>&page=<%= Math.max(1, pageAtual - 1) %>">‹</a>
              <% for (int p = 1; p <= totalPages; p++) { %><a class="pag-btn <%= p == pageAtual ? "active" : "" %>" href="<%= ctx %>/comentarios-moderacao?<%= queryBase %>&page=<%= p %>"><%= p %></a><% } %>
              <a class="pag-btn" href="<%= ctx %>/comentarios-moderacao?<%= queryBase %>&page=<%= Math.min(totalPages, pageAtual + 1) %>">›</a>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</main>

<script>
function toggleSidebar(){
  document.getElementById('sidebar')?.classList.toggle('open');
  document.getElementById('overlay')?.classList.toggle('open');
}
</script>
</body>
</html>


