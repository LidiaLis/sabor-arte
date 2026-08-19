<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.ReceitaIngrediente" %>
<%@ page import="br.com.saborearte.model.Passo" %>
<%@ page import="br.com.saborearte.model.Comentario" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%--
  Contrato esperado antes do forward:
    request.setAttribute("receita", receita);             // Receita
    request.setAttribute("ingredientes", ingredientes);   // List<ReceitaIngrediente>
    request.setAttribute("passos", passos);               // List<Passo>
    request.setAttribute("comentarios", comentarios);     // List<Comentario>
    request.setAttribute("favorita", favorita);           // Boolean, quando houver usuário logado

  O ReceitaController também valida a visibilidade pelo perfil e pelo estado
  antes de encaminhar para esta JSP.
--%>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }
  private String estrelas(int nota) {
    StringBuilder s = new StringBuilder();
    for (int i = 1; i <= 5; i++) s.append(i <= nota ? "★" : "☆");
    return s.toString();
  }
%>
<%
  Receita receita = (Receita) request.getAttribute("receita");
  List<ReceitaIngrediente> ingredientes = (List<ReceitaIngrediente>) request.getAttribute("ingredientes");
  List<Passo> passos = (List<Passo>) request.getAttribute("passos");
  List<Comentario> comentarios = (List<Comentario>) request.getAttribute("comentarios");
  if (ingredientes == null) ingredientes = Collections.emptyList();
  if (passos == null) passos = Collections.emptyList();
  if (comentarios == null) comentarios = Collections.emptyList();
  Usuario usuario = (Usuario) session.getAttribute("usuarioLogado");
  boolean usuarioAutenticado = usuario != null;
  boolean favorita = Boolean.TRUE.equals(request.getAttribute("favorita"));
  String ctx = request.getContextPath();
  boolean podeEditar = Boolean.TRUE.equals(request.getAttribute("podeEditar"));
  boolean podeModerar = Boolean.TRUE.equals(request.getAttribute("podeModerar"));
  boolean podeAlterarAtividade = Boolean.TRUE.equals(request.getAttribute("podeAlterarAtividade"));
  boolean podeComentar = Boolean.TRUE.equals(request.getAttribute("podeComentar"));
  String csrfToken = request.getAttribute("csrfToken") == null ? "" : String.valueOf(request.getAttribute("csrfToken"));
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Receita</title>
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
    --sidebar-w:    260px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'DM Sans', sans-serif;
    background: var(--cream);
    color: var(--text-dark);
    min-height: 100vh;
    display: flex;
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

  .sidebar-user {
    display: flex; align-items: center; gap: 12px;
    padding: 16px 24px;
    border-top: 1px solid rgba(255,255,255,0.08);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    text-decoration: none;
    position: relative; z-index: 1;
  }
  .user-avatar {
    width: 36px; height: 36px; border-radius: 50%;
    flex-shrink: 0; position: relative; overflow: hidden;
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 13px; font-weight: 700;
  }
  .user-avatar img { width: 100%; height: 100%; object-fit: cover; display: none; }
  .user-avatar img.visible { display: block; }
  .user-info { line-height: 1.3; min-width: 0; }
  .user-name { font-size: 13px; color: var(--cream); font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .user-role-badge { font-size: 10px; color: var(--sage); letter-spacing: 0.3px; }

  .sidebar-bottom { padding: 16px 24px; position: relative; z-index: 1; margin-top: auto; }
  .btn-logout {
    display: flex; align-items: center; gap: 10px;
    color: rgba(245,240,232,0.7); text-decoration: none;
    font-size: 14px; transition: color 0.2s;
  }
  .btn-logout:hover { color: var(--cream); }

  /* ===== MAIN ===== */
  .main { margin-left: var(--sidebar-w); flex: 1; min-height: 100vh; display: flex; flex-direction: column; }

  .topbar {
    background: var(--warm-white);
    border-bottom: 1px solid var(--cream-dark);
    padding: 0 40px; height: 64px;
    display: flex; align-items: center; justify-content: space-between;
    position: sticky; top: 0; z-index: 50;
  }

  .page-crumb { font-size: 12px; color: var(--text-light); display: flex; align-items: center; gap: 6px; font-weight: 300; }
  .page-crumb a { color: var(--text-light); text-decoration: none; transition: color 0.2s; }
  .page-crumb a:hover { color: var(--moss); }
  .page-crumb .current { color: var(--moss); font-weight: 500; }

  .topbar-right { display: flex; align-items: center; gap: 16px; }

  .topbar-search {
    display: flex; align-items: center; gap: 8px;
    background: var(--cream); border: 1.5px solid var(--cream-dark);
    border-radius: 2px; padding: 7px 14px; width: 240px;
    transition: border-color 0.2s, box-shadow 0.2s;
  }
  .topbar-search:focus-within { border-color: var(--moss-light); box-shadow: 0 0 0 3px rgba(74,94,58,0.08); }
  .topbar-search input { border: none; background: none; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark); outline: none; flex: 1; }
  .topbar-search input::placeholder { color: var(--text-light); font-weight: 300; }

  .notif-btn {
    width: 36px; height: 36px; background: var(--cream);
    border: 1.5px solid var(--cream-dark); border-radius: 2px;
    display: flex; align-items: center; justify-content: center;
    cursor: pointer; font-size: 16px; position: relative; transition: all 0.2s;
  }
  .notif-btn:hover { background: var(--cream-dark); }
  .notif-dot { position: absolute; top: 4px; right: 4px; width: 8px; height: 8px; background: var(--gold); border-radius: 50%; border: 2px solid var(--warm-white); }

  /* ===== CONTEÚDO ===== */
  .content { flex: 1; padding: 0; }

  /* Hero banner */
  .recipe-hero {
    position: relative;
    height: 420px;
    overflow: hidden;
  }

  .recipe-hero img {
    width: 100%; height: 100%;
    object-fit: cover;
    display: block;
    animation: zoomIn 0.8s ease both;
  }

  @keyframes zoomIn {
    from { transform: scale(1.06); opacity: 0.7; }
    to   { transform: scale(1);    opacity: 1; }
  }

  .hero-overlay {
    position: absolute; inset: 0;
    background: linear-gradient(
      to bottom,
      rgba(30,39,24,0.1) 0%,
      rgba(30,39,24,0.15) 40%,
      rgba(30,39,24,0.72) 100%
    );
  }

  .hero-content {
    position: absolute;
    bottom: 0; left: 0; right: 0;
    padding: 32px 48px;
    animation: slideUp 0.6s 0.2s ease both;
  }

  @keyframes slideUp {
    from { opacity: 0; transform: translateY(18px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  .hero-cat {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px;
    color: var(--sage-light); font-weight: 600; margin-bottom: 10px;
  }

  .hero-title {
    font-family: 'Playfair Display', serif;
    font-size: 38px; font-weight: 700;
    color: #fff; line-height: 1.2;
    margin-bottom: 16px;
    text-shadow: 0 2px 12px rgba(0,0,0,0.25);
  }

  .hero-meta-row {
    display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
  }

  .hero-pill {
    display: inline-flex; align-items: center; gap: 6px;
    background: rgba(255,255,255,0.18);
    backdrop-filter: blur(8px);
    border: 1px solid rgba(255,255,255,0.25);
    padding: 6px 14px; border-radius: 30px;
    font-size: 13px; color: rgba(255,255,255,0.95);
    font-weight: 500;
  }

  .hero-author {
    display: flex; align-items: center; gap: 10px;
  }

  .author-ava {
    width: 32px; height: 32px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif;
    font-size: 11px; font-weight: 800;
    color: white; flex-shrink: 0;
    border: 2px solid rgba(255,255,255,0.4);
  }

  .author-info { line-height: 1; }
  .author-lbl { font-size: 10px; color: rgba(255,255,255,0.6); text-transform: uppercase; letter-spacing: 0.8px; }
  .author-nm  { font-size: 13px; color: rgba(255,255,255,0.95); font-weight: 500; }

  .hero-stars { font-size: 16px; color: var(--gold-light); letter-spacing: 0; }

  .fav-btn-hero {
    margin-left: auto;
    width: 44px; height: 44px; border-radius: 50%;
    background: rgba(255,255,255,0.18); backdrop-filter: blur(8px);
    border: 1.5px solid rgba(255,255,255,0.3);
    display: flex; align-items: center; justify-content: center;
    font-size: 20px; cursor: pointer; transition: all 0.2s;
  }
  .fav-btn-hero:hover { background: rgba(196,162,101,0.4); transform: scale(1.08); }

  /* ===== BODY LAYOUT ===== */
  .recipe-body-wrap {
    display: grid;
    grid-template-columns: 1fr 320px;
    gap: 32px;
    padding: 36px 48px;
    max-width: 1200px;
  }

  /* ===== LEFT COLUMN ===== */
  .left-col { min-width: 0; }

  /* Descrição */
  .section-block {
    margin-bottom: 36px;
    animation: fadeUp 0.5s ease both;
  }

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(12px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  .sec-title {
    font-family: 'Playfair Display', serif;
    font-size: 20px; font-weight: 700;
    color: var(--text-dark); margin-bottom: 14px;
    display: flex; align-items: center; gap: 10px;
  }
  .sec-title::after {
    content: '';
    flex: 1; height: 1px;
    background: var(--cream-dark);
  }

  .recipe-desc {
    font-size: 15px; line-height: 1.75;
    color: var(--text-mid); font-weight: 300;
  }

  /* Ingredientes */
  .ing-list {
    list-style: none;
    display: grid; grid-template-columns: 1fr 1fr; gap: 0;
  }

  .ing-item {
    display: flex; align-items: center; gap: 12px;
    padding: 11px 0;
    border-bottom: 1px solid var(--cream-dark);
    font-size: 14px;
  }

  .ing-item:last-child,
  .ing-item:nth-last-child(2):nth-child(odd) { border-bottom: none; }

  .ing-check {
    width: 20px; height: 20px; border-radius: 50%;
    border: 1.5px solid var(--sage);
    background: var(--warm-white);
    flex-shrink: 0; cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.2s;
  }
  .ing-item.checked .ing-check {
    background: var(--moss); border-color: var(--moss);
    color: white; font-size: 11px;
  }
  .ing-item.checked .ing-text { text-decoration: line-through; color: var(--text-light); }

  .ing-qty { font-weight: 600; color: var(--moss); min-width: 54px; font-size: 13px; }
  .ing-text { color: var(--text-mid); }

  /* Modo de preparo */
  .steps-list { list-style: none; counter-reset: step-counter; }

  .step-item {
    display: flex; gap: 18px;
    margin-bottom: 24px;
    counter-increment: step-counter;
    position: relative;
    animation: fadeUp 0.5s ease both;
  }

  .step-item::before {
    content: '';
    position: absolute;
    left: 22px; top: 44px;
    width: 1.5px;
    bottom: -24px;
    background: var(--cream-dark);
  }
  .step-item:last-child::before { display: none; }

  .step-num {
    width: 44px; height: 44px; border-radius: 50%;
    background: var(--moss); color: var(--cream);
    font-family: 'Nunito', sans-serif;
    font-size: 16px; font-weight: 800;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    box-shadow: 0 4px 12px rgba(47,61,37,0.2);
    position: relative; z-index: 1;
  }

  .step-content { flex: 1; padding-top: 10px; }
  .step-title { font-weight: 600; font-size: 14px; color: var(--moss); margin-bottom: 5px; }
  .step-text { font-size: 14px; line-height: 1.7; color: var(--text-mid); font-weight: 300; }

  .step-tip {
    display: flex; align-items: flex-start; gap: 8px;
    background: var(--gold-pale);
    border-left: 3px solid var(--gold);
    border-radius: 0 6px 6px 0;
    padding: 10px 14px;
    margin-top: 10px;
    font-size: 12px; color: var(--text-mid); line-height: 1.6;
  }

  /* ===== RIGHT COLUMN ===== */
  .right-col { }

  .info-card {
    background: var(--warm-white);
    border: 1px solid var(--cream-dark);
    border-radius: 8px;
    overflow: hidden;
    margin-bottom: 20px;
    position: sticky; top: 84px;
  }

  .info-card-header {
    background: var(--moss);
    padding: 16px 20px;
    font-family: 'Playfair Display', serif;
    font-size: 16px; color: var(--cream);
    display: flex; align-items: center; gap: 10px;
  }

  .info-grid {
    display: grid; grid-template-columns: 1fr 1fr;
    gap: 0;
  }

  .info-cell {
    padding: 16px 18px;
    border-bottom: 1px solid var(--cream-dark);
    border-right: 1px solid var(--cream-dark);
  }
  .info-cell:nth-child(even) { border-right: none; }
  .info-cell:nth-last-child(-n+2) { border-bottom: none; }

  .info-cell-lbl {
    font-size: 10px; text-transform: uppercase; letter-spacing: 1px;
    color: var(--text-light); font-weight: 600; margin-bottom: 4px;
  }

  .info-cell-val {
    font-family: 'Nunito', sans-serif;
    font-size: 18px; font-weight: 800;
    color: var(--moss);
  }

  .info-cell-unit {
    font-family: 'DM Sans', sans-serif;
    font-size: 11px; color: var(--text-light); font-weight: 300;
  }

  /* Relacionadas */
  .related-card {
    background: var(--warm-white);
    border: 1px solid var(--cream-dark);
    border-radius: 8px;
    overflow: hidden;
  }

  .related-header {
    padding: 14px 20px;
    border-bottom: 1px solid var(--cream-dark);
    font-family: 'Playfair Display', serif;
    font-size: 15px; color: var(--text-dark);
  }

  .related-item {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 16px;
    border-bottom: 1px solid var(--cream-dark);
    cursor: pointer; transition: background 0.15s;
    text-decoration: none;
  }
  .related-item:last-child { border-bottom: none; }
  .related-item:hover { background: var(--cream); }

  .related-thumb {
    width: 52px; height: 52px; border-radius: 6px;
    object-fit: cover; flex-shrink: 0;
  }

  .related-name {
    font-size: 13px; font-weight: 600; color: var(--text-dark);
    margin-bottom: 3px; line-height: 1.3;
  }

  .related-meta { font-size: 11px; color: var(--text-light); font-weight: 300; }

  /* ===== COMMENTS SECTION ===== */
  .comments-section {
    padding: 0 48px 48px;
    max-width: 1200px;
    border-top: 1px solid var(--cream-dark);
    padding-top: 32px;
    margin-top: 8px;
  }

  .comment-item {
    display: flex; gap: 14px;
    margin-bottom: 24px;
    animation: fadeUp 0.4s ease both;
  }

  .comment-ava {
    width: 38px; height: 38px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif;
    font-size: 12px; font-weight: 800;
    color: white; flex-shrink: 0;
  }

  .comment-bubble {
    flex: 1;
    background: var(--warm-white);
    border: 1px solid var(--cream-dark);
    border-radius: 0 8px 8px 8px;
    padding: 12px 16px;
  }

  .comment-top {
    display: flex; align-items: center; justify-content: space-between;
    margin-bottom: 7px;
  }

  .comment-name { font-size: 13px; font-weight: 600; color: var(--text-dark); }
  .comment-date { font-size: 11px; color: var(--text-light); }
  .comment-stars { font-size: 12px; color: var(--gold); letter-spacing: -1px; }
  .comment-text { font-size: 13px; line-height: 1.65; color: var(--text-mid); font-weight: 300; }

  /* Comment form */
  .comment-form {
    background: var(--warm-white);
    border: 1px solid var(--cream-dark);
    border-radius: 8px;
    padding: 20px 24px;
    margin-top: 8px;
  }

  .form-title { font-family: 'Playfair Display', serif; font-size: 17px; color: var(--text-dark); margin-bottom: 16px; }

  .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 14px; }

  .form-group { display: flex; flex-direction: column; gap: 5px; }
  .form-group label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.8px; color: var(--text-light); font-weight: 600; }
  .form-group input,
  .form-group textarea {
    padding: 9px 14px;
    border: 1.5px solid var(--cream-dark);
    border-radius: 4px;
    font-family: 'DM Sans', sans-serif;
    font-size: 13px; color: var(--text-dark);
    background: var(--cream);
    outline: none;
    transition: border-color 0.2s, box-shadow 0.2s;
    resize: none;
  }
  .form-group input:focus,
  .form-group textarea:focus {
    border-color: var(--moss-light);
    box-shadow: 0 0 0 3px rgba(74,94,58,0.08);
  }
  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:2px;color:rgba(245,240,232,0.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all 0.2s;}
  .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}

.sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;}

a.sidebar-user,
a.sidebar-user:link,
a.sidebar-user:visited,
a.sidebar-user:hover,
a.sidebar-user:active {
  text-decoration: none;
  color: inherit;
}  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,var(--gold),var(--gold-light));border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--moss-dark);flex-shrink:0;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:300;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;font-size:11px;color:rgba(245,240,232,0.45);font-weight:300;}
  .star-rating { display: flex; gap: 4px; }
  .star-rating span {
    font-size: 22px; cursor: pointer;
    color: var(--cream-dark);
    transition: color 0.15s;
  }
  .star-rating span.active { color: var(--gold); }

  .btn-comment {
    display: inline-flex; align-items: center; gap: 8px;
    background: var(--moss); color: var(--cream);
    padding: 10px 22px; border: none; border-radius: 4px;
    font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
    cursor: pointer; transition: background 0.2s;
    margin-top: 4px;
  }
  .btn-comment:hover { background: var(--moss-dark); }

  /* Scrollbar personalizada */
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: var(--cream); }
  ::-webkit-scrollbar-thumb { background: var(--sage); border-radius: 3px; }

  /* ===== RESPONSIVE ===== */
  @media (max-width: 1100px) { .recipe-body-wrap { grid-template-columns: 1fr; } .right-col { order: -1; } .info-card { position: static; } }
  @media (max-width: 768px)  { .sidebar { display: none; } .main { margin-left: 0; } .recipe-body-wrap { padding: 24px 20px; } .topbar { padding: 0 20px; } .hero-content { padding: 20px; } .hero-title { font-size: 26px; } .comments-section { padding: 24px 20px; } }
  @media (max-width: 580px)  { .ing-list { grid-template-columns: 1fr; } .form-row { grid-template-columns: 1fr; } }
</style>
</head>
<body>
<!--
  TELA DINÂMICA — receita-detalhe.php?id=<id_receita>

  Query principal (1x por carregamento):
    SELECT r.*, c.nome_categoria, c.emoji_categoria,
           u.nome_usuario, u.foto_usuario
    FROM receita r
    JOIN categoria c ON c.id_categoria = r.categoria
    JOIN usuario u   ON u.id_usuario   = r.usuario
    WHERE r.id_receita = :id AND r.status_receita = 'publicada'

  + query em receita_ingrediente JOIN ingrediente (lista de ingredientes)
  + query em passo ORDER BY ordem_passo (modo de preparo, com titulo_passo)
  + query em comentario JOIN usuario ORDER BY data_comentario DESC
  + query em receita_categoria JOIN categoria (tags/categorias extras da receita)
  + a cada acesso: INSERT em visualizacao_receita (ip, data) e
    UPDATE receita SET visualizacoes_receita = visualizacoes_receita + 1

  Alterações de schema necessárias (não existiam no DER original):
    - receita.descricao_receita TEXT
    - passo.titulo_passo VARCHAR(150)
    - tabela receita_categoria (junção N:N receita <-> categoria, pra tags)

  Removido desta tela por não ter suporte no DER: nível de dificuldade e
  card de informação nutricional.
-->

<!-- ===== SIDEBAR VISITANTE (estático) ===== -->
<%
  request.setAttribute("currentPage", "receitas");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />


<!-- MAIN -->
<main class="main">

  <!-- TOPBAR -->
  <div class="topbar">
    <div class="page-crumb">
      <a href="<%= ctx %>/ReceitaController">Receitas</a>
      <span style="color:var(--cream-dark)">/</span>
      <span><%= receita == null ? "Categoria" : h(receita.getNome_categoria()) %></span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current"><%= receita == null ? "Receita" : h(receita.getTitulo_receita()) %></span>
    </div>
  </div>

  <!-- HERO -->
  <div class="recipe-hero">
    <% if (receita != null) { %><img src="<%= receita.getImagem_receita() == null || receita.getImagem_receita().isBlank() ? ctx + "/assets/img/receita-sem-imagem.svg" : h(receita.getImagem_receita()) %>" onerror="this.onerror=null;this.src='<%= ctx %>/assets/img/receita-sem-imagem.svg'" alt="<%= h(receita.getTitulo_receita()) %>"><% } %>
    <div class="hero-overlay"></div>
    <div class="hero-content">
      <div class="hero-cat"><%= receita == null ? "" : h(receita.getEmoji_categoria()) + " " + h(receita.getNome_categoria()) %></div>
      <div class="hero-title"><%= receita == null ? "Receita não encontrada" : h(receita.getTitulo_receita()) %></div>
      <% if (receita != null) { %><div class="hero-meta-row">
        <div class="hero-author"><div class="author-ava"><%= h(receita.getNome_usuario()).isEmpty() ? "?" : h(receita.getNome_usuario()).substring(0,1).toUpperCase() %></div><div class="author-info"><div class="author-lbl">Receita por</div><div class="author-nm"><%= h(receita.getNome_usuario()) %></div></div></div>
        <span class="hero-pill">⏱ <%= receita.getTempo_preparo_receita() %> min preparo</span>
        <span class="hero-pill">👥 <%= h(receita.getRendimento_receita()) %></span>
        <div class="hero-stars"><%= estrelas((int)Math.round(receita.getNota_media())) %></div>
      </div><% } %>
    </div>
  </div>

  <!-- BODY -->
  <div class="recipe-body-wrap">

    <!-- LEFT COL -->
    <div class="left-col">

      <!-- Descrição -->
      <div class="section-block" style="animation-delay:0.05s">
        <div class="sec-title">Sobre a receita</div>
        <!-- receita.descricao_receita -->
        <p class="recipe-desc"><%= receita == null ? "" : h(receita.getDescricao_receita()) %></p>
      </div>

      <!-- Ingredientes -->
      <div class="section-block" style="animation-delay:0.1s">
        <div class="sec-title">Ingredientes</div>
        <!-- receita_ingrediente JOIN ingrediente WHERE id_receita = :id -->
        <p style="font-size:12px;color:var(--text-light);margin-bottom:14px;font-weight:300">
          Clique nos itens para marcar o que já separou 🛒
        </p>
        <ul class="ing-list" id="ingList">
          <% for (ReceitaIngrediente ingrediente : ingredientes) { %>
            <li class="ing-item" onclick="toggleIng(this)"><div class="ing-check"></div><span class="ing-qty"><%= ingrediente.getQuantidade_receita_ingrediente() %> <%= h(ingrediente.getUnidade_medida_receita_ingrediente()) %></span><span class="ing-text"><%= h(ingrediente.getNome_ingrediente()) %></span></li>
          <% } %>
          <% if (ingredientes.isEmpty()) { %><li class="ing-item"><span class="ing-text">Nenhum ingrediente cadastrado.</span></li><% } %>
        </ul>
      </div>

      <!-- Modo de preparo -->
      <div class="section-block" style="animation-delay:0.15s">
        <div class="sec-title">Modo de Preparo</div>
        <!-- SELECT * FROM passo WHERE receita = :id ORDER BY ordem_passo -->
        <ol class="steps-list">
          <% for (Passo passo : passos) { %><li class="step-item"><div class="step-num"><%= passo.getOrdem_passo() %></div><div class="step-content"><div class="step-title"><%= h(passo.getTitulo_passo()) %></div><div class="step-text"><%= h(passo.getDescricao_passo()) %></div></div></li><% } %>
          <% if (passos.isEmpty()) { %><li class="step-item"><div class="step-content"><div class="step-text">Nenhum passo cadastrado.</div></div></li><% } %>
        </ol>
      </div>

    </div><!-- /left-col -->

    <!-- RIGHT COL -->
    <div class="right-col">
      <% if (usuarioAutenticado && !podeModerar && receita != null) { %><form method="post" action="<%= ctx %>/FavoritoController"><input type="hidden" name="action" value="toggle"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><button type="submit" class="btn-fav" id="favBtn"><%= favorita ? "❤️ Favoritada" : "🤍 Favoritar" %></button></form><% } %>
      <% if (podeEditar) { %>
      <form method="get" action="<%= ctx %>/ReceitaController"><input type="hidden" name="action" value="editar"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><button type="submit" class="btn-comment">✏ Editar receita</button></form>
      <% } %>
      <% if (podeModerar) { %>
      <form method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="aprovar"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><button type="submit" class="btn-comment">✓ Aprovar</button></form>
      <form method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="rejeitar"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><textarea name="motivo" placeholder="Motivo da rejeição" required></textarea><button type="submit" class="btn-comment">✕ Rejeitar</button></form>
      <% } %>
      <% if (podeAlterarAtividade) { %>
      <form method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="alterarAtividade"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><input type="hidden" name="statusAtividade" value="<%= receita.getStatus_atividade() == Receita.StatusAtividade.ativo ? "inativo" : "ativo" %>"><button type="submit" class="btn-comment"><%= receita.getStatus_atividade() == Receita.StatusAtividade.ativo ? "Inativar" : "Ativar" %> receita</button></form>
      <% } %>
    </div><!-- /right-col -->

  </div><!-- /recipe-body-wrap -->

  <!-- COMMENTS -->
  <!-- SELECT c.*, u.nome_usuario, u.foto_usuario FROM comentario c JOIN usuario u ON u.id_usuario = c.usuario WHERE c.receita = :id ORDER BY c.data_comentario DESC -->
  <div class="comments-section">
    <div class="sec-title" style="font-family:'Playfair Display',serif;font-size:20px;font-weight:700;color:var(--text-dark);margin-bottom:24px;display:flex;align-items:center;gap:10px">
      Comentários <span id="commentCount" style="font-family:'Nunito',sans-serif;font-size:14px;font-weight:800;background:var(--moss);color:var(--cream);padding:3px 10px;border-radius:20px"><%= comentarios.size() %></span>
      <span style="flex:1;height:1px;background:var(--cream-dark)"></span>
    </div>

    <div id="commentsList">
      <% for (Comentario comentario : comentarios) { %><div class="comment-item"><div class="comment-ava"><%= h(comentario.getNome_usuario()).isEmpty() ? "?" : h(comentario.getNome_usuario()).substring(0,1).toUpperCase() %></div><div class="comment-bubble"><div class="comment-top"><div><div class="comment-name"><%= h(comentario.getNome_usuario()) %></div><div class="comment-stars"><%= estrelas(comentario.getAvaliacao_comentario()) %></div></div><div class="comment-date"><%= h(comentario.getData_criacao_comentario()) %></div></div><div class="comment-text"><%= h(comentario.getTexto_comentario()) %></div></div></div><% } %>
      <% if (comentarios.isEmpty()) { %><div class="comment-item"><div class="comment-bubble"><div class="comment-text">Nenhum comentário publicado.</div></div></div><% } %>
    </div><!-- /commentsList -->

    <!-- Formulário -->
    <% if (podeComentar) { %><form class="comment-form" method="post" action="<%= ctx %>/ComentarioController">
      <div class="form-title">✍️ Deixe seu comentário</div>
      <div id="commentErr" style="display:none;font-size:12px;color:var(--gold);background:#fdf3e3;border-left:3px solid var(--gold);padding:8px 12px;margin-bottom:14px;border-radius:0 4px 4px 0;"></div>
      <div class="form-row">
        <div class="form-group">
          <label>Avaliação</label>
          <div class="star-rating" id="starRating">
            <span onclick="setStars(1)">★</span>
            <span onclick="setStars(2)">★</span>
            <span onclick="setStars(3)">★</span>
            <span onclick="setStars(4)">★</span>
            <span onclick="setStars(5)">★</span>
          </div>
        </div>
      </div>
      <div class="form-group" style="margin-bottom:16px">
        <label>Comentário</label>
        <input type="hidden" name="action" value="comentar"><input type="hidden" name="idReceita" value="<%= receita == null ? 0 : receita.getId_receita() %>"><input type="hidden" id="avaliacaoComentario" name="avaliacao" value="1"><textarea id="commentText" name="conteudo" rows="4" placeholder="Conte como ficou, dicas que deram certo, variações…" required></textarea>
      </div>
      <button type="submit" class="btn-comment" id="btnPublicarComentario">💬 Publicar comentário</button></form><% } %>
  </div>

</main>

<script>
function toggleIng(item) {
  item.classList.toggle('checked');
  const check = item.querySelector('.ing-check');
  if (check) check.textContent = item.classList.contains('checked') ? '✓' : '';
}
function setStars(value) {
  const input = document.getElementById('avaliacaoComentario');
  if (input) input.value = value;
  document.querySelectorAll('#starRating span').forEach((star, index) => star.classList.toggle('active', index < value));
}
</script>
</body>
</html>
