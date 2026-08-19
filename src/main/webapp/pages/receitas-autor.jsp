<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.ReceitaIngrediente" %>
<%@ page import="br.com.saborearte.model.Passo" %>
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
  Receita receitaEdicao = (Receita) request.getAttribute("receitaEdicao");
  boolean modoEdicao = receitaEdicao != null;
  List<ReceitaIngrediente> ingredientesEdicao = (List<ReceitaIngrediente>) request.getAttribute("ingredientesEdicao");
  if (ingredientesEdicao == null) ingredientesEdicao = Collections.emptyList();
  List<Passo> passosEdicao = (List<Passo>) request.getAttribute("passosEdicao");
  if (passosEdicao == null) passosEdicao = Collections.emptyList();
  boolean abrirFormularioReceita = Boolean.TRUE.equals(request.getAttribute("abrirFormularioReceita"));
  String csrfToken = request.getAttribute("csrfToken") == null ? "" : String.valueOf(request.getAttribute("csrfToken"));
  Usuario usuario = (Usuario) session.getAttribute("usuarioLogado");
  boolean usuarioAutenticado = usuario != null;
  String ctx = request.getContextPath();
  String mensagemErro = request.getAttribute("erro") == null ? null : String.valueOf(request.getAttribute("erro"));
  String mensagemSucesso = request.getAttribute("sucesso") == null ? null : String.valueOf(request.getAttribute("sucesso"));
  int totalReceitas = receitas.size();
  int totalPublicadas = 0;
  int totalRascunhos = 0;
  for (Receita item : receitas) {
    if (item.getStatus_receita() == Receita.StatusReceita.publicada) totalPublicadas++;
    if (item.getStatus_receita() == Receita.StatusReceita.rascunho) totalRascunhos++;
  }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Autor</title>
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
    --pending:      #c4832a;
    --pending-bg:   #fdf2e3;
    --published:    #3a7a4a;
    --published-bg: #e8f4eb;
    --draft:        #6a7a8a;
    --draft-bg:     #eef1f4;
    --archived:     #8a7a6a;
    --archived-bg:  #f4f0ec;
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
  .sidebar-user {
    padding: 18px 24px;
    border-bottom: 1px solid rgba(255,255,255,0.07);
    display: flex; align-items: center; gap: 12px;
    position: relative; z-index: 1;
  }
  .user-avatar {
    width: 38px; height: 38px;
    background: linear-gradient(135deg, var(--gold), var(--gold-light));
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif;
    font-weight: 800; font-size: 13px;
    color: var(--moss-dark); flex-shrink: 0;
  }
  .user-name { font-size: 13px; font-weight: 600; color: var(--cream); }
  .user-role-badge { font-size: 10px; color: var(--gold-light); text-transform: uppercase; letter-spacing: 0.8px; font-weight: 300; }
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
  .nav-badge {
    margin-left: auto;
    background: var(--gold); color: var(--moss-dark);
    font-family: 'Nunito', sans-serif;
    font-size: 10px; font-weight: 800;
    padding: 2px 7px; border-radius: 10px;
  }
  .sidebar-bottom {
    padding: 16px 24px 24px;
    border-top: 1px solid rgba(255,255,255,0.08);
    position: relative; z-index: 1;
  }
  .btn-logout {
    display: flex; align-items: center; gap: 10px;
    width: 100%; padding: 10px 16px;
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.1); border-radius: 2px;
    color: rgba(245,240,232,0.7);
    font-family: 'DM Sans', sans-serif; font-size: 13px;
    cursor: pointer; transition: all 0.2s;
  }
  .btn-logout:hover { background: rgba(155,68,68,0.2); border-color: rgba(155,68,68,0.3); color: #e8a0a0; }

  /* ===== MAIN ===== */
  .main { margin-left: var(--sidebar-w); flex: 1; min-height: 100vh; display: flex; flex-direction: column; }
  .topbar {
    background: var(--warm-white); border-bottom: 1px solid var(--cream-dark);
    padding: 0 40px; height: 64px;
    display: flex; align-items: center; justify-content: space-between;
    position: sticky; top: 0; z-index: 50;
  }
  .page-crumb { font-size: 12px; color: var(--text-light); display: flex; align-items: center; gap: 6px; font-weight: 300; }
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

  /* ===== CONTENT ===== */
  .content { flex: 1; padding: 36px 40px; }
  .section-header { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 28px; }
  .section-title { font-family: 'Playfair Display', serif; font-size: 28px; font-weight: 500; color: var(--text-dark); line-height: 1; }
  .section-title em { font-style: italic; color: var(--moss); }
  .section-sub { font-size: 12px; color: var(--text-light); font-weight: 300; margin-top: 4px; }
  .btn-primary {
    display: flex; align-items: center; gap: 8px;
    background: var(--moss); color: var(--cream);
    padding: 10px 20px; border: none; border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
    cursor: pointer; transition: background 0.2s, transform 0.15s;
  }
  .btn-primary:hover { background: var(--moss-dark); transform: translateY(-1px); }

  /* ===== FILTER BAR ===== */
  .filter-bar { display: flex; align-items: center; gap: 12px; margin-bottom: 28px; flex-wrap: wrap; }
  .filter-label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: var(--text-light); font-weight: 500; margin-right: 4px; }
  .filter-chips { display: flex; gap: 8px; flex-wrap: wrap; flex: 1; }
  .chip {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 7px 16px; border-radius: 40px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid var(--cream-dark);
    background: var(--warm-white); color: var(--text-mid);
    cursor: pointer; transition: all 0.18s; user-select: none;
  }
  .chip:hover { border-color: var(--moss-light); color: var(--moss); }
  .chip.active { background: var(--moss); border-color: var(--moss); color: #fff; }
  .chip.active.publicado { background: var(--published); border-color: var(--published); }
  .chip.active.rascunho  { background: var(--draft);     border-color: var(--draft); }
  .chip.active.arquivado { background: var(--archived);  border-color: var(--archived); }
  .chip-count {
    font-family: 'Nunito', sans-serif; font-size: 10px; font-weight: 800;
    background: rgba(255,255,255,0.25); padding: 1px 7px; border-radius: 10px; min-width: 22px; text-align: center;
  }
  .chip:not(.active) .chip-count { background: var(--cream-dark); color: var(--text-mid); }
  .filter-right { display: flex; align-items: center; gap: 10px; }
  .sort-select {
    padding: 7px 14px; border: 1.5px solid var(--cream-dark);
    border-radius: 2px; background: var(--warm-white);
    font-family: 'DM Sans', sans-serif; font-size: 12px;
    color: var(--text-mid); cursor: pointer; outline: none;
  }
  .sort-select:focus { border-color: var(--moss-light); }

  /* ===== GRID ===== */
  .results-info { font-size: 12px; color: var(--text-light); margin-bottom: 20px; }
  .results-info strong { color: var(--text-mid); font-weight: 600; }
  .recipes-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 22px; }
  @media (max-width: 1400px) { .recipes-grid { grid-template-columns: repeat(3, 1fr); } }
  @media (max-width: 1100px) { .recipes-grid { grid-template-columns: repeat(2, 1fr); } }

  /* ===== CARD ===== */
  .recipe-card {
    background: var(--warm-white); border: 1px solid var(--cream-dark);
    border-radius: 6px; overflow: hidden;
    transition: transform 0.25s, box-shadow 0.25s; cursor: pointer;
    animation: fadeUp 0.35s ease both;
  }
  .recipe-card:hover { transform: translateY(-5px); box-shadow: 0 20px 48px rgba(47,61,37,0.16); }
  @keyframes fadeUp { from { opacity: 0; transform: translateY(14px); } to { opacity: 1; transform: translateY(0); } }
  .recipe-img-wrap { position: relative; overflow: hidden; height: 180px; }
  .recipe-img-wrap img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.45s ease; }
  .recipe-card:hover .recipe-img-wrap img { transform: scale(1.07); }
  .recipe-img-wrap::after {
    content: ''; position: absolute; inset: 0;
    background: linear-gradient(to bottom, transparent 50%, rgba(30,39,24,0.35) 100%);
    pointer-events: none;
  }
  .img-badge {
    position: absolute; top: 12px; left: 12px; z-index: 2;
    display: inline-flex; align-items: center; gap: 5px;
    padding: 4px 10px; border-radius: 20px;
    font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.5px;
  }
  .img-badge.publicado { background: rgba(58,122,74,0.92);  color: #fff; }
  .img-badge.rascunho  { background: rgba(80,90,100,0.88);  color: #fff; }
  .img-badge.arquivado { background: rgba(100,85,75,0.88);  color: #fff; }
  .img-time {
    position: absolute; bottom: 10px; right: 10px; z-index: 2;
    background: rgba(30,39,24,0.72); color: rgba(245,240,232,0.95);
    font-family: 'Nunito', sans-serif; font-size: 11px; font-weight: 700;
    padding: 3px 9px; border-radius: 20px;
  }
  .img-fav {
    position: absolute; top: 10px; right: 10px; z-index: 2;
    width: 28px; height: 28px; border-radius: 50%;
    background: rgba(255,255,255,0.88);
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; cursor: pointer; transition: transform 0.2s;
  }
  .img-fav:hover { transform: scale(1.15); }
  .recipe-body { padding: 14px 16px 10px; }
  .recipe-cat { font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: var(--moss-light); font-weight: 600; margin-bottom: 5px; }
  .recipe-name { font-family: 'Playfair Display', serif; font-size: 15px; font-weight: 700; color: var(--text-dark); line-height: 1.35; margin-bottom: 10px; }
  .recipe-tags { display: flex; gap: 5px; flex-wrap: wrap; margin-bottom: 10px; }
  .tag { font-size: 10px; padding: 2px 8px; border-radius: 20px; background: var(--cream); border: 1px solid var(--cream-dark); color: var(--text-mid); font-weight: 500; }
  .recipe-meta { display: flex; align-items: center; justify-content: space-between; }
  .recipe-author { display: flex; align-items: center; gap: 7px; }
  .author-dot { width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-family: 'Nunito', sans-serif; font-size: 9px; font-weight: 800; color: white; flex-shrink: 0; }
  .author-name { font-size: 12px; color: var(--text-mid); }
  .recipe-stars { font-size: 12px; color: var(--gold); letter-spacing: -1px; }
  .recipe-footer {
    display: flex; align-items: center; gap: 6px;
    padding: 10px 12px;
    border-top: 1px solid var(--cream-dark);
    background: var(--cream);
  }
  .footer-btn {
    flex: 1; padding: 7px 4px; border: 1.5px solid var(--cream-dark);
    background: var(--warm-white); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500;
    color: var(--text-mid); cursor: pointer; transition: all 0.15s;
    display: flex; align-items: center; justify-content: center; gap: 4px;
  }
  .footer-btn:hover { border-color: var(--moss); color: var(--moss); background: rgba(74,94,58,0.05); }
  .footer-btn.submit { border-color: var(--pending); color: var(--pending); }
  .footer-btn.submit:hover { background: var(--pending-bg); }

  /* ===== EMPTY STATE ===== */
  .empty-state { display: none; text-align: center; padding: 80px 20px; grid-column: 1 / -1; }
  .empty-state.show { display: block; }
  .empty-icon { font-size: 52px; margin-bottom: 16px; }
  .empty-title { font-family: 'Playfair Display', serif; font-size: 20px; color: var(--text-mid); margin-bottom: 8px; }
  .empty-sub { font-size: 13px; color: var(--text-light); font-weight: 300; }

  /* ===== PAGINATION ===== */
  .pagination { display: flex; align-items: center; justify-content: center; gap: 6px; margin-top: 40px; }
  .pg-btn {
    width: 36px; height: 36px; border-radius: 2px;
    border: 1.5px solid var(--cream-dark); background: var(--warm-white);
    font-family: 'Nunito', sans-serif; font-size: 13px; font-weight: 700;
    color: var(--text-mid); cursor: pointer; transition: all 0.15s;
    display: flex; align-items: center; justify-content: center;
  }
  .pg-btn:hover { border-color: var(--moss-light); color: var(--moss); }
  .pg-btn.active { background: var(--moss); border-color: var(--moss); color: #fff; }
  .pg-btn.prev-next { width: auto; padding: 0 14px; font-size: 12px; }

  /* ===================== MODAL OVERLAY ===================== */
  .modal-overlay {
    display: none; position: fixed; inset: 0; z-index: 200;
    background: rgba(30,39,24,0.55);
    align-items: flex-start; justify-content: center;
    overflow-y: auto; padding: 32px 20px;
  }
  .modal-overlay.open { display: flex; animation: fadeOverlay 0.25s ease; }
  @keyframes fadeOverlay { from { opacity: 0; } to { opacity: 1; } }

  .modal {
    background: var(--warm-white);
    border-radius: 10px;
    width: 100%; max-width: 860px;
    box-shadow: 0 32px 80px rgba(30,39,24,0.28);
    animation: slideModal 0.3s cubic-bezier(0.34,1.56,0.64,1);
    overflow: hidden;
  }
  @keyframes slideModal { from { opacity: 0; transform: translateY(40px) scale(0.97); } to { opacity: 1; transform: none; } }

  .modal-header {
    background: var(--moss-dark);
    padding: 24px 32px;
    display: flex; align-items: center; justify-content: space-between;
    position: relative; overflow: hidden;
  }
  .modal-header::before {
    content: '';
    position: absolute; inset: 0;
    background: radial-gradient(ellipse 200% 80% at 30% 50%, rgba(74,94,58,0.5) 0%, transparent 70%);
    pointer-events: none;
  }
  .modal-header-left { position: relative; z-index: 1; }
  .modal-header-label {
    font-size: 10px; text-transform: uppercase; letter-spacing: 2px;
    color: var(--sage); font-weight: 500; margin-bottom: 4px;
  }
  .modal-header-title {
    font-family: 'Playfair Display', serif;
    font-size: 22px; font-weight: 700; color: var(--cream);
  }
  .modal-close {
    position: relative; z-index: 1;
    width: 36px; height: 36px;
    background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.15);
    border-radius: 50%; color: var(--cream);
    font-size: 18px; cursor: pointer; transition: all 0.2s;
    display: flex; align-items: center; justify-content: center;
  }
  .modal-close:hover { background: rgba(155,68,68,0.3); }

  .modal-body { padding: 32px; }

  /* progress steps */
  .form-steps {
    display: flex; align-items: center; gap: 0;
    margin-bottom: 32px;
  }
  .step-item {
    display: flex; align-items: center; gap: 8px;
    flex: 1; position: relative;
  }
  .step-item:not(:last-child)::after {
    content: '';
    position: absolute; top: 14px; left: calc(28px + 8px);
    right: 0; height: 2px;
    background: var(--cream-dark);
    z-index: 0;
  }
  .step-item.done:not(:last-child)::after { background: var(--moss-light); }
  .step-num {
    width: 28px; height: 28px; border-radius: 50%;
    background: var(--cream-dark); border: 2px solid var(--cream-dark);
    display: flex; align-items: center; justify-content: center;
    font-family: 'Nunito', sans-serif; font-size: 12px; font-weight: 800;
    color: var(--text-light); position: relative; z-index: 1;
    transition: all 0.3s; flex-shrink: 0;
  }
  .step-item.active .step-num { background: var(--moss); border-color: var(--moss); color: #fff; }
  .step-item.done .step-num { background: var(--published); border-color: var(--published); color: #fff; }
  .step-label { font-size: 11px; color: var(--text-light); font-weight: 500; white-space: nowrap; position: relative; z-index: 2; background: var(--warm-white); padding: 0 3px; }
  .step-item.active .step-label { color: var(--moss); font-weight: 600; }
  .step-item.done .step-label { color: var(--published); }

  /* section panels */
  .form-panel { display: none; }
  .form-panel.active { display: block; animation: fadeUp 0.3s ease; }

  .form-section-title {
    font-family: 'Playfair Display', serif;
    font-size: 16px; font-weight: 600; color: var(--text-dark);
    margin-bottom: 20px; padding-bottom: 10px;
    border-bottom: 1.5px solid var(--cream-dark);
    display: flex; align-items: center; gap: 8px;
  }

  .form-row { display: grid; gap: 16px; margin-bottom: 16px; }
  .form-row.cols-2 { grid-template-columns: 1fr 1fr; }
  .form-row.cols-3 { grid-template-columns: 1fr 1fr 1fr; }

  .form-group { display: flex; flex-direction: column; gap: 6px; }
  .form-label {
    font-size: 11px; font-weight: 600; text-transform: uppercase;
    letter-spacing: 0.8px; color: var(--text-mid);
  }
  .form-label span { color: #c44; font-weight: 400; margin-left: 2px; }
  .form-input, .form-select, .form-textarea {
    padding: 10px 14px;
    border: 1.5px solid var(--cream-dark);
    border-radius: 4px; background: var(--cream);
    font-family: 'DM Sans', sans-serif; font-size: 13px;
    color: var(--text-dark); outline: none;
    transition: border-color 0.2s, box-shadow 0.2s;
  }
  .form-input:focus, .form-select:focus, .form-textarea:focus {
    border-color: var(--moss-light);
    box-shadow: 0 0 0 3px rgba(74,94,58,0.08);
    background: var(--warm-white);
  }
  .form-textarea { resize: vertical; min-height: 80px; line-height: 1.5; }
  .form-select { cursor: pointer; }
  .form-hint { font-size: 11px; color: var(--text-light); font-weight: 300; }

  /* image upload */
  .upload-zone {
    display: block; width: 100%; box-sizing: border-box;
    border: 2px dashed var(--cream-dark);
    border-radius: 6px; padding: 28px;
    text-align: center; cursor: pointer;
    transition: all 0.2s; background: var(--cream);
  }
  .upload-zone:hover { border-color: var(--moss-light); background: rgba(74,94,58,0.04); }
  .upload-icon { font-size: 32px; margin-bottom: 8px; }
  .upload-text { font-size: 13px; color: var(--text-mid); font-weight: 500; }
  .upload-sub { font-size: 11px; color: var(--text-light); margin-top: 4px; }

  /* tags input */
  .tags-input-wrap {
    border: 1.5px solid var(--cream-dark); border-radius: 4px;
    background: var(--cream); padding: 6px 10px;
    display: flex; flex-wrap: wrap; gap: 6px; align-items: center;
    cursor: text; transition: border-color 0.2s;
    min-height: 44px;
  }
  .tags-input-wrap:focus-within { border-color: var(--moss-light); box-shadow: 0 0 0 3px rgba(74,94,58,0.08); background: var(--warm-white); }
  .tag-pill {
    display: inline-flex; align-items: center; gap: 4px;
    background: var(--moss); color: #fff;
    padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600;
  }
  .tag-remove { cursor: pointer; opacity: 0.7; font-size: 13px; line-height: 1; }
  .tag-remove:hover { opacity: 1; }
  .tags-real-input { border: none; background: none; outline: none; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--text-dark); min-width: 120px; flex: 1; }

  /* ===== INGREDIENTES ===== */
  .ing-list { display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px; }
  .ing-row {
    display: grid; grid-template-columns: 1fr 90px 120px 36px;
    gap: 8px; align-items: center;
    animation: fadeUp 0.25s ease;
  }
  .ing-remove {
    width: 32px; height: 32px; border-radius: 4px;
    border: 1.5px solid #e8b0b0; background: #fff5f5;
    color: #c44; cursor: pointer; font-size: 14px;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.15s;
  }
  .ing-remove:hover { background: #fee; border-color: #c44; }
  .btn-add-row {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 8px 14px; border-radius: 4px;
    border: 1.5px dashed var(--moss-light);
    background: rgba(74,94,58,0.04);
    color: var(--moss); font-family: 'DM Sans', sans-serif;
    font-size: 12px; font-weight: 600; cursor: pointer;
    transition: all 0.2s;
  }
  .btn-add-row:hover { background: rgba(74,94,58,0.1); border-style: solid; }

  /* ===== PASSOS ===== */
  .steps-list { display: flex; flex-direction: column; gap: 12px; margin-bottom: 12px; }
  .passo-block {
    border: 1.5px solid var(--cream-dark);
    border-radius: 8px; overflow: hidden;
    animation: fadeUp 0.3s ease;
  }
  .passo-header {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 16px;
    background: var(--cream);
    cursor: pointer;
    user-select: none;
    transition: background 0.15s;
  }
  .passo-header:hover { background: var(--cream-dark); }
  .passo-num-badge {
    width: 26px; height: 26px; border-radius: 50%;
    background: var(--moss); color: #fff;
    font-family: 'Nunito', sans-serif; font-size: 11px; font-weight: 800;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .passo-title-text { font-size: 13px; font-weight: 600; color: var(--text-dark); flex: 1; }
  .passo-title-input {
    flex: 1; min-width: 0; border: 0; border-bottom: 1px solid var(--cream-dark);
    background: transparent; padding: 6px 4px; color: var(--text-dark);
    font: 600 13px 'Nunito', sans-serif; outline: none;
  }
  .passo-title-input:focus { border-bottom-color: var(--moss); }
  .passo-status-text { font-size: 11px; color: var(--text-light); }
  .passo-chevron {
    font-size: 12px; color: var(--text-light);
    transition: transform 0.2s;
  }
  .passo-block.open .passo-chevron { transform: rotate(180deg); }
  .passo-remove-btn {
    padding: 3px 8px; border-radius: 3px;
    border: 1px solid #e8b0b0; background: #fff5f5;
    color: #c44; font-size: 11px; cursor: pointer;
    display: none;
  }
  .passo-block:hover .passo-remove-btn { display: block; }
  .passo-body {
    padding: 0 16px; max-height: 0; overflow: hidden;
    transition: max-height 0.35s ease, padding 0.2s;
  }
  .passo-block.open .passo-body {
    max-height: 400px; padding: 16px;
  }

  /* modal footer */
  .modal-footer {
    padding: 20px 32px;
    border-top: 1px solid var(--cream-dark);
    background: var(--cream);
    display: flex; align-items: center; justify-content: space-between;
  }
  .btn-secondary {
    display: flex; align-items: center; gap: 6px;
    padding: 10px 20px; border-radius: 2px;
    border: 1.5px solid var(--cream-dark);
    background: var(--warm-white);
    font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
    color: var(--text-mid); cursor: pointer; transition: all 0.15s;
  }
  .btn-secondary:hover { border-color: var(--moss-light); color: var(--moss); }
  .modal-footer-right { display: flex; gap: 10px; }
  .btn-save-draft {
    display: flex; align-items: center; gap: 6px;
    padding: 10px 20px; border-radius: 2px;
    border: 1.5px solid var(--draft); background: var(--draft-bg);
    font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
    color: var(--draft); cursor: pointer; transition: all 0.15s;
  }
  .btn-save-draft:hover { background: #dde3ea; }
  .btn-submit-review {
    display: flex; align-items: center; gap: 6px;
    padding: 10px 20px; border-radius: 2px;
    border: none; background: var(--moss); color: var(--cream);
    font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
    cursor: pointer; transition: all 0.2s;
  }
  .btn-submit-review:hover { background: var(--moss-dark); transform: translateY(-1px); }

  /* toast */
  .toast {
    position: fixed; bottom: 32px; right: 32px; z-index: 999;
    background: var(--moss-dark); color: var(--cream);
    padding: 14px 20px; border-radius: 6px;
    font-size: 13px; font-weight: 500;
    box-shadow: 0 8px 32px rgba(30,39,24,0.3);
    display: flex; align-items: center; gap: 10px;
    transform: translateY(80px); opacity: 0;
    transition: all 0.35s cubic-bezier(0.34,1.56,0.64,1);
  }
  .toast.show { transform: none; opacity: 1; }
  .feedback {
    margin-bottom: 18px; padding: 12px 16px; border-radius: 4px;
    font-size: 13px; line-height: 1.45;
  }
  .feedback.error { color: #8d3535; background: #fff0f0; border: 1px solid #e8b0b0; }
  .feedback.success { color: #315f3b; background: #edf7ef; border: 1px solid #b9d9c0; }
</style>
</head>
<body>

<%
  request.setAttribute("currentPage", "receitas");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />


<!-- MAIN -->
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Painel</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Minhas Receitas</span>
    </div>
  </div>

  <div class="content">
    <% if (mensagemErro != null) { %><div class="feedback error" role="alert"><%= h(mensagemErro) %></div><% } %>
    <% if (mensagemSucesso != null) { %><div class="feedback success" role="status"><%= h(mensagemSucesso) %></div><% } %>
    <div class="section-header">
      <div>
        <div class="section-title">Minhas <em>Receitas</em> 📖</div>
        <div class="section-sub">Crie, edite e publique suas receitas</div>
      </div>
      <button class="btn-primary" onclick="openModal()">✚ Nova Receita</button>
    </div>

    <!-- FILTER BAR -->
    <div class="filter-bar">
      <div class="topbar-search" style="width:220px">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" placeholder="Buscar receitas…" id="searchInput" oninput="scheduleFilters()">
      </div>
      <span class="filter-label">Filtrar:</span>
      <div class="filter-chips">
        <button class="chip active" data-filter="todos" onclick="setFilter(this)">🍴 Todas <span class="chip-count"><%= totalReceitas %></span></button>
        <button class="chip publicado" data-filter="publicada" onclick="setFilter(this)">✅ Publicadas <span class="chip-count"><%= totalPublicadas %></span></button>
        <button class="chip rascunho" data-filter="rascunho" onclick="setFilter(this)">📝 Rascunhos <span class="chip-count"><%= totalRascunhos %></span></button>
      </div>
      <div class="filter-right">
        <select class="sort-select" onchange="applyFilters()">
          <option>Mais recentes</option>
          <option>Mais antigos</option>
          <option>A–Z</option>
          <option>Melhor avaliação</option>
        </select>
      </div>
    </div>

    <div class="results-info" id="resultsInfo">Nenhuma receita carregada</div>

    <div class="recipes-grid" id="recipesGrid">
      <% for (Receita receita : receitas) { %>
        <% boolean editavel = receita.getStatus_receita() == Receita.StatusReceita.rascunho
            || receita.getStatus_receita() == Receita.StatusReceita.rejeitada; %>
        <article class="recipe-card" data-id="<%= receita.getId_receita() %>" data-status="<%= h(receita.getStatus_receita()).toLowerCase() %>" data-name="<%= h(receita.getTitulo_receita()) %>">
          <div class="recipe-img-wrap"><img loading="lazy" decoding="async" src="<%= receita.getImagem_receita() == null || receita.getImagem_receita().isBlank() ? ctx + "/assets/img/receita-sem-imagem.svg" : h(receita.getImagem_receita()) %>" onerror="this.onerror=null;this.src='<%= ctx %>/assets/img/receita-sem-imagem.svg'" alt="<%= h(receita.getTitulo_receita()) %>"></div>
          <div class="recipe-body"><div class="recipe-cat"><%= h(receita.getEmoji_categoria()) %> <%= h(receita.getNome_categoria()) %></div><div class="recipe-name"><%= h(receita.getTitulo_receita()) %></div></div>
          <div class="recipe-footer">
            <a class="footer-btn" href="<%= ctx %>/ReceitaController?action=detalhar&amp;idReceita=<%= receita.getId_receita() %>">👁 Ver</a>
            <% if (editavel) { %><a class="footer-btn" href="<%= ctx %>/ReceitaController?action=editar&amp;idReceita=<%= receita.getId_receita() %>">✏️ Editar</a>
            <form method="post" action="<%= ctx %>/ReceitaController"><input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>"><input type="hidden" name="action" value="enviarRevisao"><input type="hidden" name="idReceita" value="<%= receita.getId_receita() %>"><button class="footer-btn submit" type="submit">📤 Enviar</button></form><% } %>
          </div>
        </article>
      <% } %>
      <% if (receitas.isEmpty()) { %><div class="empty-state show" id="emptyState"><div class="empty-icon">🍽️</div><h3>Nenhuma receita encontrada</h3></div><% } %>
    </div>

    <div class="pagination">
      <button class="pg-btn prev-next">← Anterior</button>
      <button class="pg-btn active">1</button>
      <button class="pg-btn prev-next">Próxima →</button>
    </div>
  </div>
</main>

<!-- ===================== MODAL NOVA RECEITA ===================== -->
<div class="modal-overlay" id="modalOverlay" onclick="handleOverlayClick(event)">
  <div class="modal" id="modal">
    <form id="receitaForm" method="post" action="<%= ctx %>/ReceitaController" style="display:contents">
    <input type="hidden" name="csrfToken" value="<%= h(csrfToken) %>">
    <input type="hidden" name="action" id="formAction" value="salvarRascunho">
    <% if (modoEdicao) { %><input type="hidden" name="idReceita" value="<%= receitaEdicao.getId_receita() %>"><% } %>
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-header-label"><%= modoEdicao ? "✏️ Edição de Receita" : "✚ Criação de Receita" %></div>
        <div class="modal-header-title"><%= modoEdicao ? "Editar Receita" : "Nova Receita" %></div>
      </div>
      <button class="modal-close" type="button" onclick="closeModal()">✕</button>
    </div>

    <div class="modal-body">
      <!-- steps indicator -->
      <div class="form-steps">
        <div class="step-item active" id="step-ind-1">
          <div class="step-num">1</div>
          <span class="step-label">Informações</span>
        </div>
        <div class="step-item" id="step-ind-2">
          <div class="step-num">2</div>
          <span class="step-label">Ingredientes</span>
        </div>
        <div class="step-item" id="step-ind-3">
          <div class="step-num">3</div>
          <span class="step-label">Modo de Preparo</span>
        </div>
        <div class="step-item" id="step-ind-4">
          <div class="step-num">4</div>
          <span class="step-label">Imagem & Revisão</span>
        </div>
      </div>

      <!-- PANEL 1: Informações básicas -->
      <div class="form-panel active" id="panel-1">
        <div class="form-section-title">📋 Informações Básicas</div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Título da Receita <span>*</span></label>
            <input class="form-input" type="text" placeholder="Título da receita" id="f-titulo" name="titulo" value="<%= modoEdicao ? h(receitaEdicao.getTitulo_receita()) : "" %>" required>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Descrição</label>
            <textarea class="form-textarea" id="f-descricao" name="descricao" placeholder="Apresente brevemente a receita"><%= modoEdicao ? h(receitaEdicao.getDescricao_receita()) : "" %></textarea>
          </div>
        </div>
        <div class="form-row cols-2">
          <div class="form-group">
            <label class="form-label">Categoria <span>*</span></label>
            <select class="form-select" id="f-categoria" name="idCategoria" required><option value="">Selecionar categoria…</option><% for (Categoria categoria : categorias) { %><option value="<%= categoria.getId_categoria() %>" <%= modoEdicao && receitaEdicao.getCategoria() == categoria.getId_categoria() ? "selected" : "" %>><%= h(categoria.getNome_categoria()) %></option><% } %></select>
          </div>
          <div class="form-group">
            <label class="form-label">Tempo de Preparo (minutos) <span>*</span></label>
            <input class="form-input" type="number" placeholder="Ex: 45" min="1" id="f-tempo" name="tempoPreparo" value="<%= modoEdicao ? receitaEdicao.getTempo_preparo_receita() : "" %>" required>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Rendimento (porções) <span>*</span></label>
            <input class="form-input" type="text" placeholder="Ex: 8 porções" maxlength="50" id="f-rendimento" name="rendimento" value="<%= modoEdicao ? h(receitaEdicao.getRendimento_receita()) : "" %>" required>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Tags / Palavras-chave</label>
            <div class="tags-input-wrap" id="tagsWrap" onclick="document.getElementById('tagInput').focus()">
              <input class="tags-real-input" id="tagInput" type="text" placeholder="Digite e pressione Enter ou vírgula…" onkeydown="handleTagInput(event)">
            </div>
            <span class="form-hint">Ex: Vegano, Sem Glúten, Fácil, Italiano…</span>
          </div>
        </div>
      </div>

      <!-- PANEL 2: Ingredientes -->
      <div class="form-panel" id="panel-2">
        <div class="form-section-title">🥕 Ingredientes</div>
        <div style="display:grid;grid-template-columns:1fr 90px 120px 36px;gap:8px;margin-bottom:6px;padding:0 2px">
          <span style="font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:0.8px;color:var(--text-light)">Ingrediente</span>
          <span style="font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:0.8px;color:var(--text-light)">Quantidade</span>
          <span style="font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:0.8px;color:var(--text-light)">Unidade</span>
          <span></span>
        </div>
        <div class="ing-list" id="ingList">
          <% for (ReceitaIngrediente item : ingredientesEdicao) { %>
          <div class="ing-row">
            <input class="form-input" name="ingredienteNome" placeholder="Ingrediente" value="<%= h(item.getNome_ingrediente()) %>" required>
            <input class="form-input" type="number" min="0.01" step="0.01" name="ingredienteQuantidade" placeholder="Quantidade" value="<%= item.getQuantidade_receita_ingrediente() %>" required>
            <select class="form-select" name="ingredienteUnidade" required>
              <option value="">Unidade</option>
              <% String[] unidadesEdicao = {"g","kg","ml","l","unidade","xícara","colher de sopa","colher de chá","pitada","a gosto"};
                 for (String unidade : unidadesEdicao) { %>
              <option value="<%= h(unidade) %>" <%= unidade.equals(item.getUnidade_medida_receita_ingrediente()) ? "selected" : "" %>><%= h(unidade) %></option>
              <% } %>
            </select>
            <button type="button" class="ing-remove" onclick="this.parentElement.remove()">✕</button>
          </div>
          <% } %>
        </div>
        <button class="btn-add-row" type="button" onclick="addIngrediente()">＋ Adicionar Ingrediente</button>
      </div>

      <!-- PANEL 3: Passos -->
      <div class="form-panel" id="panel-3">
        <div class="form-section-title">👨‍🍳 Modo de Preparo</div>
        <div class="steps-list" id="stepsList">
          <% for (Passo passo : passosEdicao) { %>
          <div class="passo-block open">
            <div class="passo-header"><span class="passo-num-badge"><%= passo.getOrdem_passo() %></span>
              <input class="passo-title-input" name="passoTitulo" placeholder="Título do passo (opcional)" value="<%= h(passo.getTitulo_passo()) %>">
              <button type="button" class="passo-remove-btn" onclick="removerPasso(this)">Remover</button>
            </div>
            <div class="passo-body"><textarea class="form-textarea" name="passoDescricao" placeholder="Descreva o passo" required><%= h(passo.getDescricao_passo()) %></textarea></div>
          </div>
          <% } %>
        </div>
        <button class="btn-add-row" id="btnAddPasso" type="button" onclick="addPasso()">＋ Adicionar Passo</button>
      </div>

      <!-- PANEL 4: Imagem & Revisão -->
      <div class="form-panel" id="panel-4">
        <div class="form-section-title">🖼️ Imagem de Capa</div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">URL da Imagem</label>
            <input class="form-input" type="url" placeholder="https://…" id="f-imagem" name="imagemUrl" value="<%= modoEdicao ? h(receitaEdicao.getImagem_receita()) : "" %>" oninput="schedulePreviewImagemUrl()">
            <span class="form-hint">Cole o link que será salvo com a receita ou escolha um arquivo para pré-visualizar.</span>
          </div>
        </div>
        <input type="file" id="imagemArquivo" accept="image/jpeg,image/png,image/webp" hidden onchange="previewImagemArquivo(event)">
        <label class="upload-zone" for="imagemArquivo">
          <img id="imagemPreview" src="<%= modoEdicao && receitaEdicao.getImagem_receita() != null && !receitaEdicao.getImagem_receita().isBlank() ? h(receitaEdicao.getImagem_receita()) : ctx + "/assets/img/receita-sem-imagem.svg" %>" onerror="this.onerror=null;this.src='<%= ctx %>/assets/img/receita-sem-imagem.svg'" alt="Pré-visualização da capa" style="<%= modoEdicao ? "display:block;" : "display:none;" %>max-width:100%;max-height:220px;margin:0 auto 12px;border-radius:6px;object-fit:contain">
          <div class="upload-icon" id="uploadIcon" style="<%= modoEdicao ? "display:none" : "" %>">📸</div>
          <div class="upload-text">Clique para escolher uma imagem</div>
          <div class="upload-sub">Pré-visualização local — somente a URL informada acima será salva</div>
        </label>
        <div class="form-section-title" style="margin-top:24px">✅ Resumo da Receita</div>
        <div id="reviewSummary" style="background:var(--cream);border-radius:6px;padding:16px;font-size:13px;color:var(--text-mid);line-height:1.8;">
          Preencha os campos anteriores para ver o resumo aqui.
        </div>
      </div>

    </div><!-- end modal-body -->

    <div class="modal-footer">
      <button class="btn-secondary" type="button" id="btnBack" onclick="changePanel(-1)" style="display:none">← Voltar</button>
      <div style="font-size:12px;color:var(--text-light)" id="stepCounter">Etapa 1 de 4</div>
      <div class="modal-footer-right">
        <button class="btn-save-draft" type="button" onclick="saveAction('rascunho')">💾 Salvar Rascunho</button>
        <button class="btn-submit-review" type="button" id="btnNext" onclick="handleNext()">Próximo →</button>
      </div>
    </div>
    </form>
  </div>
</div>

<!-- TOAST -->
<div class="toast" id="toast"></div>

<script>
let currentPanel = 1;
const totalPanels = 4;
let currentFilter = 'todos';
let filterTimer = null;
let previewTimer = null;
let imagemPreviewObjectUrl = null;
const modoEdicao = <%= modoEdicao %>;
const imagemPadrao = '<%= ctx %>/assets/img/receita-sem-imagem.svg';

function openModal() {
  document.getElementById('modalOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
  if (!document.querySelector('#ingList .ing-row')) addIngrediente();
  if (!document.querySelector('#stepsList .passo-block')) addPasso();
}
function closeModal() {
  document.getElementById('modalOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
function handleOverlayClick(event) { if (event.target.id === 'modalOverlay') closeModal(); }
function applyFilters() {
  const term = (document.getElementById('searchInput')?.value || '').toLowerCase();
  const cards = document.querySelectorAll('#recipesGrid .recipe-card');
  let visible = 0;
  cards.forEach(card => {
    const matchesText = (card.dataset.name || '').toLowerCase().includes(term);
    const matchesStatus = currentFilter === 'todos' || card.dataset.status === currentFilter;
    const show = matchesText && matchesStatus;
    card.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  const info = document.getElementById('resultsInfo');
  if (info) info.textContent = visible + ' receita(s)';
}
function scheduleFilters() {
  clearTimeout(filterTimer);
  filterTimer = setTimeout(applyFilters, 180);
}
function setFilter(button) {
  currentFilter = button.dataset.filter || 'todos';
  document.querySelectorAll('.filter-chips .chip').forEach(chip => chip.classList.remove('active'));
  button.classList.add('active');
  applyFilters();
}
function showPanel(panelNumber) {
  if (panelNumber < 1 || panelNumber > totalPanels) return;
  document.getElementById('panel-' + currentPanel)?.classList.remove('active');
  currentPanel = panelNumber;
  document.getElementById('panel-' + currentPanel)?.classList.add('active');
  document.getElementById('btnBack').style.display = currentPanel > 1 ? 'flex' : 'none';
  document.getElementById('stepCounter').textContent = 'Etapa ' + currentPanel + ' de ' + totalPanels;
  document.querySelectorAll('.form-steps .step-item').forEach((item, index) => {
    item.classList.toggle('active', index + 1 === currentPanel);
    item.classList.toggle('done', index + 1 < currentPanel);
  });
  const btnNext = document.getElementById('btnNext');
  btnNext.textContent = currentPanel === totalPanels ? 'Enviar para revisão' : 'Próximo →';
  if (currentPanel === totalPanels) updateReviewSummary();
}
function changePanel(direction) {
  const next = currentPanel + direction;
  if (next < 1 || next > totalPanels) return;
  showPanel(next);
}
function validarFormulario() {
  const form = document.getElementById('receitaForm');
  if (form.checkValidity()) return true;
  const invalid = form.querySelector(':invalid');
  const panel = invalid?.closest('.form-panel');
  if (panel) showPanel(Number(panel.id.replace('panel-', '')));
  invalid?.reportValidity();
  showToast('Revise os campos obrigatórios antes de continuar.');
  return false;
}
function handleNext() {
  if (currentPanel < totalPanels) {
    const panel = document.getElementById('panel-' + currentPanel);
    const invalid = panel?.querySelector(':invalid');
    if (invalid) {
      invalid.reportValidity();
      return;
    }
    changePanel(1);
    return;
  }
  if (!validarFormulario()) return;
  const formAction = document.getElementById('formAction');
  formAction.value = modoEdicao ? "atualizarEnviarRevisao" : "enviarRevisao";
  setSubmitting(true, 'Enviando…');
  document.getElementById('receitaForm').requestSubmit();
}
function addIngrediente() {
  const row = document.createElement('div');
  row.className = 'ing-row';
  row.innerHTML = '<input class="form-input" name="ingredienteNome" placeholder="Ingrediente" required>' +
    '<input class="form-input" type="number" min="0.01" step="0.01" name="ingredienteQuantidade" placeholder="Quantidade" required>' +
    '<select class="form-select" name="ingredienteUnidade" required><option value="">Unidade</option>' +
    '<option value="g">g</option><option value="kg">kg</option><option value="ml">ml</option>' +
    '<option value="l">l</option><option value="unidade">unidade</option><option value="xícara">xícara</option>' +
    '<option value="colher de sopa">colher de sopa</option><option value="colher de chá">colher de chá</option>' +
    '<option value="pitada">pitada</option><option value="a gosto">a gosto</option></select>' +
    '<button type="button" class="ing-remove" onclick="this.parentElement.remove()">✕</button>';
  document.getElementById('ingList')?.appendChild(row);
}
function addPasso() {
  const row = document.createElement('div');
  row.className = 'passo-block open';
  row.innerHTML = '<div class="passo-header"><span class="passo-num-badge"></span>' +
    '<input class="passo-title-input" name="passoTitulo" placeholder="Título do passo (opcional)">' +
    '<button type="button" class="passo-remove-btn" onclick="removerPasso(this)">Remover</button></div>' +
    '<div class="passo-body"><textarea class="form-textarea" name="passoDescricao" placeholder="Descreva o passo" required></textarea></div>';
  document.getElementById('stepsList')?.appendChild(row);
  renumerarPassos();
}
function removerPasso(button) {
  button.closest('.passo-block')?.remove();
  renumerarPassos();
}
function renumerarPassos() {
  document.querySelectorAll('#stepsList .passo-block').forEach((item, index) => {
    item.querySelector('.passo-num-badge').textContent = index + 1;
  });
}
function previewImagemArquivo(event) {
  const arquivo = event.target.files?.[0];
  if (!arquivo) return;
  if (arquivo.size && arquivo.size > 5 * 1024 * 1024) {
    event.target.value = '';
    showToast('Escolha uma imagem de até 5 MB para a pré-visualização.');
    return;
  }
  if (imagemPreviewObjectUrl) URL.revokeObjectURL(imagemPreviewObjectUrl);
  imagemPreviewObjectUrl = URL.createObjectURL(arquivo);
  const preview = document.getElementById('imagemPreview');
  preview.onerror = null;
  preview.src = imagemPreviewObjectUrl;
  preview.style.display = 'block';
  document.getElementById('uploadIcon').style.display = 'none';
}
function previewImagemUrl() {
  const url = document.getElementById('f-imagem').value.trim();
  const preview = document.getElementById('imagemPreview');
  if (!url) {
    if (!imagemPreviewObjectUrl) {
      preview.removeAttribute('src');
      preview.style.display = 'none';
      document.getElementById('uploadIcon').style.display = '';
    }
    return;
  }
  preview.onerror = () => {
    preview.onerror = null;
    preview.src = imagemPadrao;
  };
  preview.src = url;
  preview.style.display = 'block';
  document.getElementById('uploadIcon').style.display = 'none';
}
function schedulePreviewImagemUrl() {
  clearTimeout(previewTimer);
  previewTimer = setTimeout(previewImagemUrl, 350);
}
function handleTagInput(event) {
  if (event.key !== 'Enter' && event.key !== ',') return;
  event.preventDefault();
  const value = event.target.value.trim().replace(/,$/, '');
  if (!value) return;
  const pill = document.createElement('span');
  pill.className = 'tag-pill';
  pill.textContent = value;
  event.target.parentElement.insertBefore(pill, event.target);
  event.target.value = '';
}
function updateReviewSummary() {
  const categoria = document.getElementById('f-categoria');
  const ingredientes = document.querySelectorAll('#ingList .ing-row').length;
  const passos = document.querySelectorAll('#stepsList .passo-block').length;
  const summary = document.getElementById('reviewSummary');
  summary.textContent = [
    'Título: ' + (document.getElementById('f-titulo').value || 'Não informado'),
    'Categoria: ' + (categoria.options[categoria.selectedIndex]?.text || 'Não informada'),
    'Tempo: ' + (document.getElementById('f-tempo').value || '0') + ' minutos',
    'Ingredientes: ' + ingredientes,
    'Passos: ' + passos
  ].join(' · ');
}
function saveAction(status) {
  if (!validarFormulario()) return;
  const formAction = document.getElementById('formAction');
  formAction.value = modoEdicao ? "atualizarRascunho" : "salvarRascunho";
  setSubmitting(true, 'Salvando…');
  document.getElementById('receitaForm').requestSubmit();
}
function setSubmitting(submitting, label) {
  document.querySelectorAll('#receitaForm button').forEach(button => {
    button.disabled = submitting;
  });
  const btnNext = document.getElementById('btnNext');
  if (submitting && btnNext) btnNext.textContent = label;
}
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2800);
}
document.addEventListener('keydown', event => {
  if (event.key === 'Escape') closeModal();
});
applyFilters();
<% if (abrirFormularioReceita) { %>openModal();<% } %>
</script>
</body>
</html>
