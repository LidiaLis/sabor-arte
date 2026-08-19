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
  String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Revisão Editorial</title>
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
  .stat-card.green::before{background:linear-gradient(90deg,var(--published),#5ab870);}
  .stat-card.gold::before{background:linear-gradient(90deg,var(--gold),var(--gold-light));}
  .stat-icon{width:34px;height:34px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0;}
  .stat-card.pending .stat-icon{background:rgba(196,131,42,0.12);}
  .stat-card.moss .stat-icon{background:rgba(74,94,58,0.1);}
  .stat-card.green .stat-icon{background:rgba(58,122,74,0.1);}
  .stat-card.gold .stat-icon{background:rgba(196,162,101,0.1);}
  .stat-text{min-width:0;}
  .stat-value{font-family:'Nunito',sans-serif;font-size:24px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:2px;letter-spacing:-0.5px;transition:color 0.2s;}
  .stat-label{font-size:10.5px;color:var(--text-light);text-transform:uppercase;letter-spacing:0.6px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

  /* ===== LAYOUT DE DUAS COLUNAS (padrão Log Admin) ===== */
  .audit-layout{display:grid;grid-template-columns:240px 1fr;gap:18px;align-items:start;}
  .left-panel{position:sticky;top:24px;}
  .panel-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .panel-head{padding:13px 18px;border-bottom:1px solid var(--cream-dark);font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1.2px;}
  .panel-body{padding:14px 16px;}
  .fgroup{margin-bottom:11px;}
  .fgroup:last-child{margin-bottom:0;}
  .flabel{display:block;font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:0.9px;margin-bottom:5px;}
  .finput,.fselect{width:100%;padding:8px 10px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;color:var(--text-dark);background:var(--cream);outline:none;transition:border-color 0.18s,box-shadow 0.18s;}
  .finput:focus,.fselect:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.07);}
  .panel-search-wrap{position:relative;}
  .panel-search-wrap .search-icon{position:absolute;left:9px;top:50%;transform:translateY(-50%);color:var(--text-light);font-size:13px;pointer-events:none;}
  .panel-search-wrap .finput{padding-left:29px;}
  .btn-clear{width:100%;padding:8px 10px;background:var(--cream-dark);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:11px;font-weight:600;color:var(--text-mid);cursor:pointer;margin-top:4px;transition:all 0.15s;}
  .btn-clear:hover{background:var(--sage-light);color:var(--moss-dark);}

  /* ===== PAINEL DE CALENDÁRIO (filtro) ===== */
  .cal-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;margin-bottom:18px;}
  .cal-card-head{padding:13px 18px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .cal-card-title{font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1.2px;display:flex;align-items:center;gap:6px;}
  .cal-nav{display:flex;align-items:center;gap:6px;}
  .cal-nav-btn{width:24px;height:24px;border:1.5px solid var(--cream-dark);background:var(--cream);border-radius:2px;cursor:pointer;font-size:11px;color:var(--text-mid);display:flex;align-items:center;justify-content:center;transition:all .15s;}
  .cal-nav-btn:hover{border-color:var(--moss);color:var(--moss);}
  .cal-body{padding:14px 16px 16px;}
  .cal-month-label{text-align:center;font-size:12px;font-weight:600;color:var(--text-dark);margin-bottom:10px;text-transform:capitalize;}
  .cal-weekdays{display:grid;grid-template-columns:repeat(7,1fr);margin-bottom:5px;}
  .cal-weekdays span{text-align:center;font-size:8.5px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:0.3px;}
  .cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:3px;}
  .cal-day{aspect-ratio:1;display:flex;flex-direction:column;align-items:center;justify-content:center;border-radius:2px;font-size:10.5px;color:var(--text-mid);cursor:default;position:relative;background:var(--cream);}
  .cal-day.empty{background:none;}
  .cal-day.has-post{cursor:pointer;background:var(--gold-pale);color:var(--moss-dark);font-weight:600;transition:all .15s;}
  .cal-day.has-post:hover{background:var(--gold-light);transform:scale(1.08);}
  .cal-day.today{outline:1.5px solid var(--moss);outline-offset:-1.5px;font-weight:700;}
  .cal-day.selected{background:var(--moss);color:var(--warm-white);}
  .cal-dot{width:3.5px;height:3.5px;border-radius:50%;background:var(--pending);margin-top:1px;}
  .cal-day.selected .cal-dot{background:var(--warm-white);}
  .cal-legend{display:flex;align-items:center;gap:6px;padding:10px 16px 0;font-size:10px;color:var(--text-light);border-top:1px solid var(--cream-dark);margin-top:2px;padding-top:10px;}
  .cal-legend-dot{width:8px;height:8px;border-radius:2px;background:var(--gold-pale);border:1px solid var(--gold-light);flex-shrink:0;}
  .cal-clear{margin-left:auto;color:var(--moss-light);cursor:pointer;font-weight:500;font-size:10px;}
  .cal-clear:hover{color:var(--moss-dark);}
  .cal-note{padding:8px 16px 12px;font-size:10px;color:var(--text-light);font-weight:300;}

  .right-panel{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .result-head{padding:14px 20px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .result-title{font-size:15px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:8px;}
  .row-count-badge{font-family:'Nunito',sans-serif;font-size:11px;font-weight:700;background:var(--cream-dark);color:var(--text-light);padding:2px 10px;border-radius:10px;}

  .table-footer{padding:12px 20px;border-top:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .footer-info{font-size:11px;color:var(--text-light);font-weight:300;}
  .footer-info strong{font-family:'Nunito',sans-serif;font-weight:700;color:var(--text-mid);}
  .pagination{display:flex;gap:4px;}
  .pag-btn{width:28px;height:28px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-family:'Nunito',sans-serif;font-size:11px;font-weight:700;color:var(--text-light);display:flex;align-items:center;justify-content:center;transition:all 0.15s;}
  .pag-btn:hover{border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}
  .pag-btn:disabled{opacity:0.35;cursor:not-allowed;}
  .pag-btn:disabled:hover{border-color:var(--cream-dark);color:var(--text-light);}

  /* ===== TABLE CARD ===== */
  .table-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .table-card-head{padding:16px 22px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .table-card-title{font-size:15px;font-weight:600;color:var(--text-dark);}
  .table-card-meta{font-size:11px;color:var(--text-light);font-weight:300;}
  .table-wrap{overflow-x:auto;}
  .data-table{width:100%;border-collapse:collapse;font-size:13px;}
  .data-table thead th{padding:10px 18px;text-align:left;background:var(--cream);border-bottom:2px solid var(--cream-dark);font-size:10px;text-transform:uppercase;letter-spacing:1px;color:var(--text-light);font-weight:700;white-space:nowrap;}
  .data-table tbody tr{border-bottom:1px solid var(--cream-dark);transition:background 0.12s;}
  .data-table tbody tr:last-child{border-bottom:none;}
  .data-table tbody tr:hover{background:rgba(245,240,232,0.7);}
  .data-table td{padding:12px 18px;color:var(--text-mid);vertical-align:middle;}

  .thumb{width:50px;height:50px;border-radius:3px;object-fit:cover;display:block;flex-shrink:0;}
  .recipe-cell{display:flex;align-items:center;gap:12px;}
  .recipe-cell-title{font-size:13px;font-weight:600;color:var(--text-dark);margin-bottom:2px;}
  .recipe-cell-cat{font-size:10px;text-transform:uppercase;letter-spacing:0.6px;color:var(--moss-light);font-weight:600;}
  .author-cell{display:flex;align-items:center;gap:8px;}
  .author-dot{width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:9px;font-weight:800;color:white;flex-shrink:0;}
  .author-name{font-size:12px;color:var(--text-mid);font-weight:500;}

  .pill{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:2px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;white-space:nowrap;}
  .pill-dot{width:5px;height:5px;border-radius:50%;background:currentColor;}
  .pill.aguardando{background:var(--pending-bg);color:var(--pending);}
  .pill.urgente{background:var(--error-bg);color:var(--error);}
  .pill.tranquilo{background:var(--published-bg);color:var(--published);}

  .wait-badge{font-size:11px;font-weight:600;padding:3px 9px;border-radius:20px;display:inline-block;}
  .wait-badge.ok{background:var(--published-bg);color:var(--published);}
  .wait-badge.warn{background:var(--pending-bg);color:var(--pending);}
  .wait-badge.late{background:var(--error-bg);color:var(--error);}

  .row-actions{display:flex;gap:6px;}
  .row-btn{width:28px;height:28px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-size:13px;display:flex;align-items:center;justify-content:center;color:var(--text-light);transition:all 0.15s;}
  .row-btn:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}
  .row-btn.publish:hover{border-color:var(--published);color:var(--published);background:var(--published-bg);}
  .row-btn.schedule:hover{border-color:var(--gold);color:var(--pending);background:var(--gold-pale);}

  .empty-state{text-align:center;padding:70px 30px;}
  .empty-icon{font-size:48px;margin-bottom:14px;opacity:0.4;}
  .empty-text{font-family:'Playfair Display',serif;font-size:18px;color:var(--text-light);font-style:italic;margin-bottom:6px;}
  .empty-sub{font-size:13px;color:var(--text-light);font-weight:300;}

  /* ===== MODALS ===== */
  .modal-overlay{position:fixed;inset:0;background:rgba(30,39,24,0.55);backdrop-filter:blur(2px);display:none;align-items:center;justify-content:center;z-index:300;padding:24px;}
  .modal-overlay.open{display:flex;}
  .modal-box{background:var(--warm-white);border-radius:4px;max-width:640px;width:100%;max-height:88vh;overflow-y:auto;box-shadow:0 24px 60px rgba(30,39,24,0.3);animation:modalIn 0.25s ease;}
  .modal-box.wide{max-width:760px;}
  .modal-box.narrow{max-width:400px;}
  @keyframes modalIn{from{opacity:0;transform:translateY(10px) scale(.98);}to{opacity:1;transform:none;}}
  .modal-head{padding:20px 24px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--warm-white);z-index:1;}
  .modal-title{font-family:'Playfair Display',serif;font-size:19px;font-weight:600;color:var(--text-dark);}
  .modal-close{width:30px;height:30px;border:none;background:var(--cream);border-radius:2px;cursor:pointer;font-size:16px;color:var(--text-mid);flex-shrink:0;transition:all 0.15s;}
  .modal-close:hover{background:var(--cream-dark);color:var(--text-dark);}
  .modal-body{padding:24px;}
  .modal-footer{padding:16px 24px;border-top:1px solid var(--cream-dark);display:flex;justify-content:flex-end;gap:10px;}

  .btn{display:inline-flex;align-items:center;gap:7px;padding:9px 18px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;white-space:nowrap;}
  .btn:hover{transform:translateY(-1px);box-shadow:0 3px 10px rgba(0,0,0,0.12);}
  .btn-primary{background:var(--moss);color:var(--cream);}
  .btn-primary:hover{background:var(--moss-dark);}
  .btn-gold{background:var(--gold);color:var(--moss-dark);}
  .btn-gold:hover{background:var(--gold-light);}
  .btn-outline{background:none;color:var(--text-mid);border:1.5px solid var(--cream-dark);}
  .btn-outline:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,0.05);}

  /* View modal specifics */
  .view-img{width:100%;height:220px;object-fit:cover;border-radius:3px;margin-bottom:18px;}
  .view-meta-row{display:flex;flex-wrap:wrap;gap:10px 20px;margin-bottom:18px;padding-bottom:18px;border-bottom:1px solid var(--cream-dark);}
  .view-meta-item{font-size:12px;color:var(--text-mid);display:flex;align-items:center;gap:6px;}
  .view-meta-item b{color:var(--text-dark);font-weight:600;}
  .view-block{margin-bottom:20px;}
  .view-block:last-child{margin-bottom:0;}
  .view-block-title{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--moss);margin-bottom:10px;display:flex;align-items:center;gap:7px;}
  .view-desc{font-size:13px;color:var(--text-mid);line-height:1.7;}
  .view-list{list-style:none;display:flex;flex-direction:column;gap:8px;}
  .view-list li{font-size:13px;color:var(--text-mid);padding-left:20px;position:relative;line-height:1.5;}
  .view-list.ingredients li::before{content:'●';position:absolute;left:0;color:var(--sage);font-size:9px;top:5px;}
  .view-list.steps{counter-reset:step;}
  .view-list.steps li{padding-left:28px;}
  .view-list.steps li::before{counter-increment:step;content:counter(step);position:absolute;left:0;top:0;width:18px;height:18px;background:var(--moss);color:var(--cream);border-radius:50%;font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;}

  /* Edit form */
  .form-group{margin-bottom:16px;}
  .form-group:last-child{margin-bottom:0;}
  .form-label{display:block;font-size:11px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:0.8px;margin-bottom:7px;}
  .form-input,.form-textarea,.form-select{width:100%;padding:10px 13px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);background:var(--cream);outline:none;transition:border-color 0.2s,box-shadow 0.2s;}
  .form-input:focus,.form-textarea:focus,.form-select:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.08);}
  .form-textarea{resize:vertical;min-height:70px;font-family:'DM Sans',sans-serif;line-height:1.5;}
  .form-row-2{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
  .dyn-row{display:flex;gap:8px;margin-bottom:8px;align-items:center;}
  .dyn-row input,.dyn-row textarea{flex:1;}
  .dyn-row-num{width:22px;height:22px;border-radius:50%;background:var(--moss);color:var(--cream);font-size:10px;font-weight:700;display:flex;align-items:center;justify-content:center;flex-shrink:0;}
  .dyn-remove{width:28px;height:28px;flex-shrink:0;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;color:var(--error);cursor:pointer;font-size:13px;transition:all 0.15s;}
  .dyn-remove:hover{background:var(--error-bg);border-color:var(--error);}
  .dyn-add{margin-top:4px;padding:7px 14px;background:none;border:1.5px dashed var(--sage);border-radius:2px;color:var(--moss);font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.15s;}
  .dyn-add:hover{background:rgba(74,94,58,0.06);}

  /* Schedule modal */
  .schedule-summary{background:var(--cream);border:1px solid var(--cream-dark);border-radius:3px;padding:14px 16px;margin-bottom:18px;font-size:13px;color:var(--text-mid);display:flex;align-items:center;gap:10px;}
  .schedule-summary b{color:var(--text-dark);}

  /* Modal de aviso (substitui o alert() nativo do navegador) */
  .alert-box{padding:30px 26px 24px;text-align:center;}
  .alert-icon{width:52px;height:52px;border-radius:50%;background:var(--pending-bg);color:var(--pending);display:flex;align-items:center;justify-content:center;font-size:24px;margin:0 auto 16px;}
  .alert-title{font-family:'Playfair Display',serif;font-size:17px;font-weight:600;color:var(--text-dark);margin-bottom:8px;}
  .alert-message{font-size:13px;color:var(--text-mid);line-height:1.6;}

  /* Toast */
  .toast{position:fixed;bottom:28px;right:28px;background:var(--moss-dark);color:var(--cream);padding:14px 20px;border-radius:3px;font-size:13px;font-weight:500;box-shadow:0 12px 30px rgba(30,39,24,0.3);display:flex;align-items:center;gap:10px;z-index:400;transform:translateY(20px);opacity:0;pointer-events:none;transition:all 0.3s ease;}
  .toast.show{transform:translateY(0);opacity:1;}
  .toast.success{background:var(--moss-dark);}
  .toast.gold{background:#8a6d2e;}

  /* ===== RESPONSIVE ===== */
  @media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:900px){.audit-layout{grid-template-columns:1fr;} .left-panel{position:static;}}
  @media(max-width:768px){.sidebar{transform:translateX(-100%);transition:transform 0.3s;} .sidebar.open{transform:translateX(0);} .main{margin-left:0;} .content{padding:24px 20px;} .topbar{padding:0 20px;} .menu-toggle{display:block;}}
  @media(max-width:480px){.stats-row{grid-template-columns:1fr;} .form-row-2{grid-template-columns:1fr;}}
</style>
</head>
<body>

<%
  request.setAttribute("currentPage", "receitas");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />

<!-- OVERLAY MOBILE -->
<div id="overlay" onclick="closeSidebar()" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:99"></div>

<main class="main">
  <div class="topbar">
    <div class="topbar-left">
      <button class="menu-toggle" onclick="toggleSidebar()">☰</button>
      <div class="page-crumb">
        <span>Principal</span>
        <span style="color:var(--cream-dark)">/</span>
        <span class="current">Revisão</span>
      </div>
    </div>
   
  </div>

  <div class="content">

    <div class="section-header">
      <div>
        <div class="section-title">Fila de <em>Revisão</em></div>
        <div class="section-date" id="headerDate"><%= h(request.getAttribute("dataPainel")) %> · Painel de Edição</div>
      </div>
    </div>

    <!-- STAT CARDS -->
    <div class="stats-row">
      <div class="stat-card pending">
        <div class="stat-icon">📝</div>
        <div class="stat-text">
          <div class="stat-value" id="statAguardando"><%= intAttr(request, "totalAguardando") %></div>
          <div class="stat-label">Aguardando Revisão</div>
        </div>
      </div>
      <div class="stat-card moss">
        <div class="stat-icon">✅</div>
        <div class="stat-text">
          <div class="stat-value" id="statRevisadas"><%= intAttr(request, "totalRevisadasHoje") %></div>
          <div class="stat-label">Revisadas Hoje</div>
        </div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">🚀</div>
        <div class="stat-text">
          <div class="stat-value" id="statPublicadas"><%= intAttr(request, "totalPublicadasHoje") %></div>
          <div class="stat-label">Publicadas Hoje</div>
        </div>
      </div>
      <div class="stat-card gold">
        <div class="stat-icon">📅</div>
        <div class="stat-text">
          <div class="stat-value" id="statAgendadas"><%= intAttr(request, "totalAgendadas") %></div>
          <div class="stat-label">Agendadas</div>
        </div>
      </div>
    </div>

    <div class="audit-layout">

      <!-- PAINEL LATERAL DE FILTROS -->
      <div class="left-panel">

        <!-- CALENDÁRIO (filtro por data de envio) -->
        <div class="cal-card">
          <div class="cal-card-head">
            <div class="cal-card-title">🗓️ Calendário</div>
            <div class="cal-nav">
              <button class="cal-nav-btn" onclick="changeMonth(-1)">‹</button>
              <button class="cal-nav-btn" onclick="changeMonth(1)">›</button>
            </div>
          </div>
          <div class="cal-body">
            <div id="calMonthLabel" class="cal-month-label"></div>
            <div class="cal-weekdays">
              <span>D</span><span>S</span><span>T</span><span>Q</span><span>Q</span><span>S</span><span>S</span>
            </div>
            <div class="cal-grid" id="calGrid"></div>
          </div>
          <div class="cal-legend">
            <div class="cal-legend-dot"></div> Dias com envio
            <span class="cal-clear" id="calClearBtn" onclick="clearDaySelection()" style="display:none;">Limpar ✕</span>
          </div>
          <div class="cal-note" id="calNote"></div>
        </div>

        <div class="panel-card">
          <div class="panel-head">Filtros</div>
          <div class="panel-body">
            <div class="fgroup">
              <label class="flabel">Pesquisar</label>
              <div class="panel-search-wrap">
                <span class="search-icon">🔍</span>
                <input type="text" class="finput" id="fSearch" placeholder="Título ou autor…" oninput="applyFilters()">
              </div>
            </div>
            <div class="fgroup">
              <label class="flabel">Categoria</label>
              <select class="fselect" id="fCategoria" onchange="applyFilters()"><option value="">Todas</option><% for (Categoria categoria : categorias) { %><option value="<%= categoria.getId_categoria() %>"><%= h(categoria.getNome_categoria()) %></option><% } %></select>
            </div>
            <div class="fgroup">
              <label class="flabel">Status</label>
              <select class="fselect" id="fStatus" onchange="applyFilters()">
                <option value="">Todos</option>
                <option value="aguardando">Aguardando</option>
                <option value="urgente">Urgente (+48h)</option>
              </select>
            </div>
            <div class="fgroup">
              <button class="btn-clear" onclick="clearFilters()">Limpar filtros</button>
            </div>
          </div>
        </div>
      </div>

      <!-- CONTEÚDO PRINCIPAL -->
      <div class="right-panel">
        <div class="result-head">
          <div class="result-title">
            📋 Receitas em Revisão
            <span class="row-count-badge" id="tableMeta"><%= receitas.size() %></span>
          </div>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Receita</th>
                <th>Autor</th>
                <th>Categoria</th>
                <th>Enviada em</th>
                <th>Tempo Aguardando</th>
                <th>Status</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody id="tableBody">
              <% for (Receita receita : receitas) { %>
                <tr data-name="<%= h(receita.getTitulo_receita()) %>">
                  <td><%= h(receita.getTitulo_receita()) %></td>
                  <td><%= h(receita.getNome_usuario()) %></td>
                  <td><%= h(receita.getNome_categoria()) %></td>
                  <td><%= h(receita.getData_criacao_receita()) %></td>
                  <td><%= h(request.getAttribute("tempoAguardando_" + receita.getId_receita())) %></td>
                  <td><%= h(receita.getStatus_receita()) %></td>
                  <td class="actions-cell">
                    <a class="action-btn" href="<%= ctx %>/receitas?acao=detalhar&amp;id=<%= receita.getId_receita() %>">👁 Ver</a>
                    <form method="post" action="<%= ctx %>/receitas"><input type="hidden" name="action" value="aprovar"><input type="hidden" name="receitaId" value="<%= receita.getId_receita() %>"><button class="action-btn" type="submit">✓ Aprovar</button></form>
                    <form method="post" action="<%= ctx %>/receitas"><input type="hidden" name="action" value="rejeitar"><input type="hidden" name="receitaId" value="<%= receita.getId_receita() %>"><button class="action-btn" type="submit">✕ Rejeitar</button></form>
                  </td>
                </tr>
              <% } %>
              <% if (receitas.isEmpty()) { %><tr><td colspan="7"><div class="empty-state"><div class="empty-icon">📭</div><div class="empty-text">Nenhuma receita encontrada</div></div></td></tr><% } %>
            </tbody>
          </table>
        </div>
        <div class="table-footer">
          <div class="footer-info">Exibindo <strong id="footerRange">0</strong> de <strong id="footerTotal">0</strong> receitas</div>
          <div class="pagination" id="pagination"></div>
        </div>
      </div>

    </div>

  </div>
</main>

<!-- ===== MODAL: VISUALIZAR ===== -->
<div class="modal-overlay" id="modalView">
  <div class="modal-box wide">
    <div class="modal-head">
      <div class="modal-title">👁 Visualizar Receita</div>
      <button class="modal-close" onclick="closeModal('modalView')">✕</button>
    </div>
    <div class="modal-body" id="viewContent"><!-- preenchido via JS --></div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal('modalView')">Fechar</button>
      <button class="btn btn-primary" id="viewEditBtn">✏ Editar Receita</button>
    </div>
  </div>
</div>

<!-- ===== MODAL: EDITAR ===== -->
<div class="modal-overlay" id="modalEdit">
  <div class="modal-box wide">
    <div class="modal-head">
      <div class="modal-title">✏ Editar Receita</div>
      <button class="modal-close" onclick="closeModal('modalEdit')">✕</button>
    </div>
    <div class="modal-body">
      <div class="form-group">
        <label class="form-label">Título</label>
        <input type="text" class="form-input" id="editTitulo">
      </div>
      <div class="form-row-2">
        <div class="form-group">
          <label class="form-label">Categoria</label>
          <select class="form-select" id="editCategoria"><option value="">Selecionar categoria…</option><% for (Categoria categoria : categorias) { %><option value="<%= categoria.getId_categoria() %>"><%= h(categoria.getNome_categoria()) %></option><% } %></select>
        </div>
        <div class="form-group">
          <label class="form-label">Autor</label>
          <input type="text" class="form-input" id="editAutor" disabled style="opacity:.6;cursor:not-allowed;">
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Descrição</label>
        <textarea class="form-textarea" id="editDescricao"></textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Ingredientes</label>
        <div id="editIngredientes"></div>
        <button type="button" class="dyn-add" onclick="addIngredienteField()">+ Adicionar ingrediente</button>
      </div>
      <div class="form-group">
        <label class="form-label">Modo de Preparo</label>
        <div id="editPreparo"></div>
        <button type="button" class="dyn-add" onclick="addPreparoField()">+ Adicionar passo</button>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal('modalEdit')">Cancelar</button>
      <button class="btn btn-primary" onclick="saveEdit()">💾 Salvar Alterações</button>
    </div>
  </div>
</div>

<!-- ===== MODAL: AGENDAR ===== -->
<div class="modal-overlay" id="modalSchedule">
  <div class="modal-box narrow">
    <div class="modal-head">
      <div class="modal-title">📅 Agendar Publicação</div>
      <button class="modal-close" onclick="closeModal('modalSchedule')">✕</button>
    </div>
    <div class="modal-body">
      <div class="schedule-summary">
        📝 <span>Receita: <b id="scheduleRecipeName">—</b></span>
      </div>
      <div class="form-group">
        <label class="form-label">Data de publicação</label>
        <input type="date" class="form-input" id="scheduleDate">
      </div>
      <div class="form-group">
        <label class="form-label">Hora de publicação</label>
        <input type="time" class="form-input" id="scheduleTime" value="08:00">
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="closeModal('modalSchedule')">Cancelar</button>
      <button class="btn btn-gold" onclick="confirmSchedule()">✓ Confirmar Agendamento</button>
    </div>
  </div>
</div>

<!-- ===== MODAL: AVISO (substitui o alert() nativo) ===== -->
<div class="modal-overlay" id="modalAlert">
  <div class="modal-box narrow" style="max-width:380px;">
    <div class="alert-box">
      <div class="alert-icon">⚠️</div>
      <div class="alert-title">Atenção</div>
      <div class="alert-message" id="alertMessage"></div>
    </div>
    <div class="modal-footer" style="justify-content:center;">
      <button class="btn btn-primary" style="min-width:110px;justify-content:center;" onclick="closeModal('modalAlert')">OK</button>
    </div>
  </div>
</div>

<!-- ===== MODAL: CONFIRMAÇÃO (substitui o confirm() nativo) ===== -->
<div class="modal-overlay" id="modalConfirm">
  <div class="modal-box narrow" style="max-width:380px;">
    <div class="alert-box">
      <div class="alert-icon" id="confirmIcon">❓</div>
      <div class="alert-title" id="confirmTitle">Confirmar ação</div>
      <div class="alert-message" id="confirmMessage"></div>
    </div>
    <div class="modal-footer" style="justify-content:center;">
      <button class="btn btn-outline" onclick="closeModal('modalConfirm'); confirmCallback=null;">Cancelar</button>
      <button class="btn btn-primary" style="min-width:90px;justify-content:center;" onclick="confirmAction()">OK</button>
    </div>
  </div>
</div>

<!-- TOAST -->
<div class="toast" id="toast"></div>

<script>
function openModal(id) { document.getElementById(id)?.classList.add('open'); }
function closeModal(id) { document.getElementById(id)?.classList.remove('open'); }
function applyFilters() {
  const term = (document.getElementById('searchInput')?.value || '').toLowerCase();
  document.querySelectorAll('#tableBody tr[data-name]').forEach(row => {
    row.style.display = (row.dataset.name || '').toLowerCase().includes(term) ? '' : 'none';
  });
}
document.getElementById('searchInput')?.addEventListener('input', applyFilters);
document.addEventListener('keydown', event => {
  if (event.key === 'Escape') document.querySelectorAll('.modal-overlay.open').forEach(modal => modal.classList.remove('open'));
});
</script>
</body>
</html>
