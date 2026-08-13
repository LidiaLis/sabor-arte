<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Comentario" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.Duration" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Locale" %>

<%--
  ============================================================================
  SERVLET RESPONSAVEL: PerfilController
  ----------------------------------------------------------------------------
  O controller ja deve deixar prontos, antes do forward pra esta JSP:

    session.setAttribute("usuarioLogado", usuario);   -> objeto Usuario (sempre)

    Conforme usuario.getTipo_usuario(), UM destes vem em request:
      AUTOR      -> request.setAttribute("receitasPublicadas", lista);      List<Receita>
      VISITANTE  -> request.setAttribute("receitasFavoritas", lista);       List<Receita>
      EDITOR/ADM -> request.setAttribute("comentariosDenunciados", lista);  List<Comentario>

  ATENCAO (tipos assumidos p/ os campos de data, sem eles o JSP nao compila):
    Usuario.getData_criacao_usuario()        -> java.time.LocalDate
    Comentario.getData_criacao_comentario()  -> String (o metodo parseData()
                                                 tenta os formatos mais comuns;
                                                 se nenhum bater, mostra a
                                                 string crua como fallback)
  Se no seu model os tipos forem outros, ajuste o bloco de scriptlet abaixo.

  ACTION DO BOTAO "Atualizar Dados" (form POST -> PerfilController):
    action=atualizarPerfil, id, telefone, localizacao, (+ bio, quando a aba
    Biografia existir e estiver preenchida)
  ============================================================================
--%>

<%!
  /* Formatos aceitos ao converter a String vinda do banco/model para LocalDateTime */
  private static final DateTimeFormatter[] FORMATOS_DATA = new DateTimeFormatter[] {
    DateTimeFormatter.ISO_LOCAL_DATE_TIME,                       // 2024-01-15T18:42:00
    DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),          // 2024-01-15 18:42:00
    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"),        // 2024-01-15T18:42:00
    DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"),          // 15/01/2024 18:42:00
    DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")              // 15/01/2024 18:42
  };

  /* Converte a String de data_criacao_comentario para LocalDateTime, tentando alguns formatos comuns */
  private LocalDateTime parseData(String dataStr) {
    if (dataStr == null || dataStr.trim().length() == 0) return null;
    String v = dataStr.trim();
    for (DateTimeFormatter f : FORMATOS_DATA) {
      try {
        return LocalDateTime.parse(v, f);
      } catch (Exception ignore) { /* tenta o proximo formato */ }
    }
    return null;
  }

  /* Calcula "ha X horas/dias" a partir da data de criacao do comentario (vinda como String) */
  private String tempoRelativo(String dataStr) {
    LocalDateTime data = parseData(dataStr);
    if (data == null) return (dataStr == null) ? "" : dataStr; // fallback: mostra a string crua se nao conseguir parsear
    Duration d = Duration.between(data, LocalDateTime.now());
    long horas = d.toHours();
    if (horas < 1) return "menos de 1 hora";
    if (horas < 24) return horas + (horas == 1 ? " hora" : " horas");
    long dias = d.toDays();
    return dias + (dias == 1 ? " dia" : " dias");
  }

  /* Evita NullPointerException ao jogar valores direto no atributo value="" */
  private String nz(String s) {
    return (s == null) ? "" : s;
  }
  
%>

<%
  /* ================= DADOS VINDOS DO SERVLET ================= */
  Usuario u = (Usuario) session.getAttribute("usuarioLogado");
  if (u == null) u = new Usuario();

  String tipo = (u.getTipo_usuario() != null) ? u.getTipo_usuario().toString() : "VISITANTE";

  /* Rotulo amigavel + emoji do cargo (regra 4) */
  String cargoLabel;
  String cargoEmoji;
  if ("ADMIN".equals(tipo)) {
    cargoLabel = "Administrador(a)"; cargoEmoji = "\uD83D\uDC51";
  } else if ("EDITOR".equals(tipo)) {
    cargoLabel = "Editor/Moderador"; cargoEmoji = "\uD83D\uDD11";
  } else if ("AUTOR".equals(tipo)) {
    cargoLabel = "Autor"; cargoEmoji = "\u270D\uFE0F";
  } else {
    cargoLabel = "Visitante"; cargoEmoji = "\uD83D\uDC64";
  }

  boolean temAbas = "AUTOR".equals(tipo) || "EDITOR".equals(tipo);

  /* Inicial do nome, usada como fallback de avatar */
  String inicialNome = "?";
  if (u.getNome_usuario() != null && u.getNome_usuario().length() > 0) {
    inicialNome = u.getNome_usuario().substring(0, 1).toUpperCase();
  }

  /* "Membro desde" -> "Janeiro de 2024" (regra 4) */
  String membroDesde = "-";
  if (u.getData_criacao_usuario() != null) {
    DateTimeFormatter fmtMes = DateTimeFormatter.ofPattern("MMMM", new Locale("pt", "BR"));
    String mes = u.getData_criacao_usuario().format(fmtMes);
    mes = mes.substring(0, 1).toUpperCase() + mes.substring(1);
    membroDesde = mes + " de " + u.getData_criacao_usuario().getYear();
  }

  List<Receita> receitasPublicadas   = (List<Receita>) request.getAttribute("receitasPublicadas");
  List<Receita> receitasFavoritas    = (List<Receita>) request.getAttribute("receitasFavoritas");
  List<Comentario> comentariosDenunciados = (List<Comentario>) request.getAttribute("comentariosDenunciados");
  
  Integer qtdSeguindoAttr = (Integer) request.getAttribute("qtdSeguindo");
  int qtdSeguindo = (qtdSeguindoAttr != null) ? qtdSeguindoAttr : 0;
  String _ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Meu Perfil</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
:root {
  --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;
  --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
  --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
  --gold:#c4a265;--gold-light:#dfc094;
  --published:#3a7a4a;--published-bg:#e8f4eb;
  --error:#9b4444;--error-bg:#fdf0f0;
  --sidebar-w:260px;
}
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:'DM Sans',sans-serif; background:var(--cream); color:var(--text-dark); min-height:100vh; display:flex; }

/* ===== SIDEBAR ===== */
.sidebar-overlay { display:none; position:fixed; inset:0; background:rgba(30,39,24,.45); z-index:99; backdrop-filter:blur(2px); }
.sidebar-overlay.active { display:block; }
.sidebar { width:var(--sidebar-w); background:var(--moss-dark); display:flex; flex-direction:column; position:fixed; top:0; left:0; bottom:0; z-index:100; overflow-y:auto; transition:transform .28s cubic-bezier(.25,.46,.45,.94); }
.sidebar::before { content:''; position:absolute; inset:0; background:radial-gradient(ellipse 200% 60% at 50% 0%, rgba(74,94,58,0.5) 0%, transparent 60%), radial-gradient(ellipse 100% 40% at 50% 100%, rgba(163,177,138,0.1) 0%, transparent 60%); pointer-events:none; }
.sidebar-brand { padding:28px 24px 22px; border-bottom:1px solid rgba(255,255,255,0.08); position:relative; z-index:1; }
.brand-row { display:flex; align-items:center; gap:12px; }
.brand-badge { width:38px; height:38px; background:linear-gradient(135deg,var(--moss-light),var(--sage)); border-radius:2px; display:flex; align-items:center; justify-content:center; font-size:18px; flex-shrink:0; }
.brand-title { font-family:'Playfair Display',serif; font-size:18px; font-weight:700; color:var(--cream); display:block; line-height:1; }
.brand-sub { font-size:10px; color:var(--sage); text-transform:uppercase; letter-spacing:1.2px; margin-top:3px; display:block; font-weight:300; }
.sidebar-user { padding:16px 24px; border-bottom:1px solid rgba(255,255,255,0.07); display:flex; align-items:center; gap:12px; position:relative; z-index:1; text-decoration:none; transition:background .2s; }
.sidebar-user:hover { background:rgba(255,255,255,0.04); }
.user-avatar { width:38px; height:38px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-family:'Nunito',sans-serif; font-weight:800; font-size:14px; color:white; flex-shrink:0; overflow:hidden; }
.user-avatar img { width:100%; height:100%; object-fit:cover; border-radius:50%; }
.user-info { flex:1; min-width:0; }
.user-name { font-size:13px; font-weight:600; color:var(--cream); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.user-role-badge { font-size:10px; color:var(--sage-light); text-transform:uppercase; letter-spacing:.8px; font-weight:300; }
.sidebar-nav { flex:1; padding:16px 0; position:relative; z-index:1; }
.nav-section-label { font-size:9px; text-transform:uppercase; letter-spacing:1.8px; color:rgba(163,177,138,0.5); padding:16px 24px 6px; font-weight:500; }
.nav-item { display:flex; align-items:center; gap:12px; padding:11px 24px; color:rgba(245,240,232,0.7); text-decoration:none; font-size:14px; font-weight:400; cursor:pointer; transition:all .2s; border-left:3px solid transparent; }
.nav-item:hover { color:var(--cream); background:rgba(255,255,255,0.06); border-left-color:var(--sage); }
.nav-item.active { color:var(--cream); background:rgba(163,177,138,0.15); border-left-color:var(--sage-light); font-weight:500; }
.nav-icon { width:22px; text-align:center; font-size:16px; flex-shrink:0; }
.nav-label { flex:1; }
.sidebar-bottom { padding:16px 24px 24px; border-top:1px solid rgba(255,255,255,0.08); position:relative; z-index:1; }
.btn-logout { display:flex; align-items:center; gap:10px; width:100%; padding:10px 16px; background:rgba(255,255,255,0.06); border:1px solid rgba(255,255,255,0.1); border-radius:2px; color:rgba(245,240,232,0.7); font-family:'DM Sans',sans-serif; font-size:13px; cursor:pointer; text-decoration:none; transition:all .2s; }
.btn-logout:hover { background:rgba(155,68,68,0.2); border-color:rgba(155,68,68,0.3); color:#e8a0a0; }
@media (max-width:768px) { .sidebar { transform:translateX(-100%); } .sidebar.active { transform:translateX(0); } }

/* ===== MAIN / TOPBAR ===== */
.main { margin-left:var(--sidebar-w); flex:1; min-height:100vh; display:flex; flex-direction:column; }
.topbar { background:var(--warm-white); border-bottom:1px solid var(--cream-dark); padding:0 40px; height:64px; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:50; }
.page-crumb { font-size:12px; color:var(--text-light); display:flex; align-items:center; gap:6px; }
.page-crumb .current { color:var(--moss); font-weight:500; }
.content { flex:1; padding:36px 40px; }

/* ===== HERO ===== */
.perfil-hero { background:linear-gradient(135deg,var(--moss-dark) 0%,var(--moss) 60%,var(--moss-light) 100%); border-radius:4px; padding:0; margin-bottom:32px; box-shadow:0 8px 32px rgba(47,61,37,0.25); position:relative; overflow:hidden; }
.perfil-hero::before { content:''; position:absolute; top:-80px; right:-80px; width:320px; height:320px; border-radius:50%; background:rgba(163,177,138,0.12); }
.perfil-hero::after { content:''; position:absolute; bottom:-40px; left:30%; width:200px; height:200px; border-radius:50%; background:rgba(196,162,101,0.08); }
.hero-inner { padding:36px 44px; display:flex; align-items:center; gap:32px; position:relative; z-index:1; }
.avatar-upload-wrap { position:relative; flex-shrink:0; }
.hero-avatar-big { width:96px; height:96px; border-radius:50%; background:linear-gradient(135deg,var(--gold),var(--gold-light)); display:flex; align-items:center; justify-content:center; font-family:'Nunito',sans-serif; font-size:36px; font-weight:800; color:var(--moss-dark); border:4px solid rgba(255,255,255,0.25); cursor:pointer; transition:filter .2s; overflow:hidden; position:relative; }
.hero-avatar-big:hover { filter:brightness(.85); }
.hero-avatar-big img { position:absolute; inset:0; width:100%; height:100%; object-fit:cover; }
.avatar-upload-btn { position:absolute; bottom:2px; right:2px; width:26px; height:26px; background:var(--gold); border:2px solid var(--warm-white); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; cursor:pointer; transition:background .2s; }
.avatar-upload-btn:hover { background:var(--gold-light); }
.hero-text { flex:1; display:flex; align-items:center; justify-content:space-between; gap:20px; flex-wrap:wrap; }
.hero-text-main { min-width:0; }
.hero-name { font-family:'Playfair Display',serif; font-size:30px; font-weight:700; color:white; margin-bottom:6px; line-height:1.1; }
.hero-role-pill { display:inline-flex; align-items:center; gap:6px; background:rgba(255,255,255,0.15); padding:5px 16px; border-radius:20px; font-size:13px; color:rgba(255,255,255,0.9); font-weight:500; margin-bottom:8px; }
.hero-email { font-size:14px; color:rgba(255,255,255,0.6); font-weight:300; }

/* ===== TABS ===== */
.tab-nav { display:flex; gap:2px; background:var(--cream-dark); padding:4px; border-radius:4px; margin-bottom:28px; width:fit-content; }
.tab-btn { padding:9px 20px; border:none; border-radius:2px; background:none; font-family:'DM Sans',sans-serif; font-size:13px; font-weight:500; color:var(--text-light); cursor:pointer; transition:all .2s; display:flex; align-items:center; gap:7px; }
.tab-btn:hover { color:var(--text-dark); }
.tab-btn.active { background:var(--warm-white); color:var(--moss); box-shadow:0 1px 4px rgba(0,0,0,0.08); }
.tab-panel { display:none; }
.tab-panel.active { display:block; }

/* ===== GRID / CARD ===== */
.cards-grid { display:grid; grid-template-columns:1fr 1fr; gap:22px; }
.card { background:var(--warm-white); border:1px solid var(--cream-dark); border-radius:4px; overflow:hidden; }
.card-head { padding:18px 24px; border-bottom:1px solid var(--cream-dark); display:flex; align-items:center; justify-content:space-between; }
.card-head-title { font-size:14px; font-weight:600; color:var(--text-dark); display:flex; align-items:center; gap:9px; }
.card-head-title .card-icon { font-size:16px; }
.card-body { padding:22px 24px; }

/* ===== FORM ===== */
.form-row { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
.form-group { margin-bottom:18px; }
.form-group:last-child { margin-bottom:0; }
.form-label { display:block; font-size:11px; font-weight:600; color:var(--text-light); text-transform:uppercase; letter-spacing:1px; margin-bottom:7px; }
.form-input, .form-select, .form-textarea { width:100%; padding:11px 14px; border:1.5px solid var(--cream-dark); border-radius:2px; font-family:'DM Sans',sans-serif; font-size:14px; color:var(--text-dark); background:var(--cream); transition:border-color .2s, box-shadow .2s; outline:none; }
.form-textarea { resize:vertical; min-height:100px; line-height:1.6; }
.form-input:focus, .form-textarea:focus { border-color:var(--moss); background:var(--warm-white); box-shadow:0 0 0 3px rgba(74,94,58,0.1); }
.form-input.readonly { background:var(--cream-dark) !important; color:var(--text-light) !important; cursor:not-allowed; }
.form-hint { font-size:11px; color:var(--text-light); margin-top:5px; font-weight:300; }
.field-error { font-size:10px; color:var(--error); margin-top:4px; font-weight:500; min-height:13px; }

/* ===== BOTOES ===== */
.btn { display:inline-flex; align-items:center; gap:8px; padding:10px 20px; border:none; border-radius:2px; font-family:'DM Sans',sans-serif; font-size:13px; font-weight:500; cursor:pointer; transition:all .2s; }
.btn-primary { background:var(--moss); color:var(--cream); }
.btn-primary:hover { background:var(--moss-dark); transform:translateY(-1px); box-shadow:0 4px 14px rgba(47,61,37,0.25); }

/* ===== ROLE BADGE ===== */
.role-badge { display:inline-flex; align-items:center; gap:7px; background:rgba(74,94,58,0.1); border:1.5px solid rgba(74,94,58,0.2); padding:8px 16px; border-radius:2px; font-size:13px; font-weight:600; color:var(--moss); }

/* ===== RECEITAS (Autor / Visitante) ===== */
.public-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:12px; }
.public-mini { border-radius:4px; overflow:hidden; border:1px solid var(--cream-dark); cursor:pointer; transition:transform .2s, box-shadow .2s; }
.public-mini:hover { transform:translateY(-3px); box-shadow:0 8px 20px rgba(47,61,37,0.12); }
.public-mini img { width:100%; height:90px; object-fit:cover; display:block; }
.public-mini-body { padding:8px 10px; background:var(--warm-white); }
.public-mini-title { font-size:11px; font-weight:600; color:var(--text-dark); line-height:1.3; margin-bottom:2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.public-mini-cat { font-size:10px; color:var(--text-light); }
.empty-state { font-size:12px; color:var(--text-light); padding:8px 4px; }

/* ===== LISTA SIMPLES (Comentarios Denunciados — Editor/Admin) ===== */
.log-list { display:flex; flex-direction:column; }
.log-item { display:flex; align-items:flex-start; gap:12px; padding:11px 0; border-bottom:1px solid var(--cream-dark); }
.log-item:last-child { border-bottom:none; padding-bottom:0; }
.log-item:first-child { padding-top:0; }
.log-dot { width:9px; height:9px; border-radius:50%; margin-top:5px; flex-shrink:0; background:var(--error); }
.log-text { font-size:13px; color:var(--text-dark); line-height:1.4; }
.log-text b { font-weight:600; }

/* ===== MODAL AVATAR (estrutura visual, sem envio) ===== */
.modal-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.5); z-index:500; align-items:center; justify-content:center; }
.modal-overlay.show { display:flex; }
.avatar-modal-box { background:var(--warm-white); border-radius:6px; width:100%; max-width:480px; box-shadow:0 12px 48px rgba(0,0,0,0.25); overflow:hidden; text-align:left; }
.avatar-modal-header { background:linear-gradient(135deg,var(--moss-dark),var(--moss)); padding:18px 24px; display:flex; align-items:center; justify-content:space-between; }
.avatar-modal-title { color:white; font-size:15px; font-weight:600; display:flex; align-items:center; gap:8px; }
.avatar-modal-close { background:rgba(255,255,255,0.15); border:none; border-radius:50%; width:30px; height:30px; color:white; font-size:18px; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:background .2s; line-height:1; }
.avatar-modal-close:hover { background:rgba(255,255,255,0.28); }
.avatar-modal-body { padding:24px; }
.avatar-modal-footer { padding:16px 24px; border-top:1px solid var(--cream-dark); display:flex; align-items:center; justify-content:flex-end; gap:10px; }
.avatar-preview-area { display:flex; flex-direction:column; align-items:center; gap:10px; margin-bottom:20px; }
.avatar-preview-ring { width:96px; height:96px; border-radius:50%; background:linear-gradient(135deg,var(--gold),var(--gold-light)); display:flex; align-items:center; justify-content:center; font-family:'Nunito',sans-serif; font-size:36px; font-weight:800; color:var(--moss-dark); border:4px solid var(--sage-light); overflow:hidden; position:relative; }
.avatar-preview-ring img { position:absolute; inset:0; width:100%; height:100%; object-fit:cover; display:none; }
.avatar-preview-ring img.visible { display:block; }
.avatar-preview-lbl { font-size:12px; color:var(--text-light); }
.drop-zone { border:2px dashed var(--cream-dark); border-radius:6px; padding:24px 20px; text-align:center; cursor:pointer; background:var(--cream); position:relative; transition:all .2s; }
.drop-zone:hover, .drop-zone.drag-over { border-color:var(--moss); background:rgba(74,94,58,0.04); }
.drop-zone input[type="file"] { position:absolute; inset:0; opacity:0; cursor:pointer; }
.drop-icon { font-size:28px; margin-bottom:8px; display:block; }
.drop-title { font-size:14px; font-weight:600; color:var(--text-dark); margin-bottom:4px; }
.drop-sub { font-size:12px; color:var(--text-light); }
.drop-sub span { color:var(--moss); font-weight:500; cursor:pointer; }
.btn-outline { background:none; color:var(--moss); border:1.5px solid var(--moss); }
.btn-outline:hover { background:rgba(74,94,58,0.06); }

/* ===== RESPONSIVE ===== */
@media (max-width:1100px) { .cards-grid { grid-template-columns:1fr; } .form-row { grid-template-columns:1fr; } }
@media (max-width:768px) { .main { margin-left:0; } .content { padding:24px 16px; } .topbar { padding:0 20px; } }
@media (max-width:480px) { .hero-inner { flex-direction:column; text-align:center; } .tab-nav { overflow-x:auto; } .public-grid { grid-template-columns:1fr 1fr; } }
</style>
</head>
<body>

<%
  /* Define a chave da tela atual, usada pelo sidebar.jsp pra destacar o item de menu */
  request.setAttribute("currentPage", "perfil");
%>
<jsp:include page="/pages/includes/sidebar.jsp" />

<!-- ======= MAIN ======= -->
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Painel</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Meu Perfil</span>
    </div>
  </div>

  <div class="content">

<!-- ===== HEADER: igual pros 4 perfis (regra 1) ===== -->
<div class="perfil-hero">
  <div class="hero-inner">
    <div class="avatar-upload-wrap">
      <div class="hero-avatar-big" id="heroAvatar" onclick="openAvatarModal()" title="Clique para alterar foto">
        <% if (u.getFoto_usuario() != null && u.getFoto_usuario().length() > 0) { %>
          <img id="heroAvatarImg" src="<%= u.getFoto_usuario() %>" alt="Foto de perfil" class="visible">
        <% } else { %>
          <%= inicialNome %>
        <% } %>
      </div>
      <!-- Botao de trocar foto: so a estrutura visual (regra 6) -->
      <div class="avatar-upload-btn" onclick="openAvatarModal()" title="Alterar foto">📷</div>
    </div>

    <div class="hero-text">
      <div class="hero-text-main">
        <div class="hero-role-pill"><%= cargoEmoji %> <%= cargoLabel %></div>
        <div class="hero-name"><%= nz(u.getNome_usuario()) %></div>
        <div class="hero-email"><%= nz(u.getEmail_usuario()) %></div>
      </div>

      <!-- Só o Visitante tem a contagem de autores seguidos -->
      <% if ("Visitante".equalsIgnoreCase(cargoLabel)) { %>
        <div class="hero-stats">
          <a class="hero-following-pill" href="<%= request.getContextPath() %>/AutoresSeguidosController" title="Ver autores que você segue">
            <div class="hero-following-icon">♥</div>
            <div class="hero-following-text">
              <div class="hero-following-val" id="followingCountVal"><%= qtdSeguindo %></div>
              <div class="hero-following-lbl">Seguindo</div>
            </div>
          </a>
        </div>
      <% } %>
    </div>
  </div>
</div>
    <!-- ===== ABAS: so existem para AUTOR / EDITOR (regra 2) ===== -->
    <% if (temAbas) { %>
      <div class="tab-nav">
        <button class="tab-btn active" onclick="switchTab('geral', this)">👤 Dados Gerais</button>
        <button class="tab-btn" onclick="switchTab('bio', this)">✍️ Biografia</button>
      </div>
    <% } %>

    <!-- =========================================================
         PAINEL "DADOS GERAIS" — sempre visivel (aba, se existir,
         ou card direto para VISITANTE/ADMIN)
         ========================================================= -->
    <div id="tab-geral" class="tab-panel active">
      <div class="cards-grid">

        <!-- ===== Card: Informacoes Basicas (regra 3) ===== -->
        <div class="card">
          <div class="card-head">
            <div class="card-head-title"><span class="card-icon">📋</span> Informações Básicas</div>
          </div>
          <div class="card-body">
            <form method="POST" action="<%= _ctx %>/PerfilController" id="formDados">
              <input type="hidden" name="action" value="atualizarPerfil">
              <input type="hidden" name="id" value="<%= u.getId_usuario() %>">

              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Nome de Exibição</label>
                  <input type="text" class="form-input readonly" value="<%= nz(u.getNome_usuario()) %>" readonly>
                </div>
                <div class="form-group">
                  <label class="form-label">Nome de Usuário</label>
                  <input type="text" class="form-input readonly" value="@<%= nz(u.getUsername_usuario()) %>" readonly>
                  <div class="form-hint">O nome de usuário não pode ser alterado.</div>
                </div>
              </div>

              <div class="form-group">
                <label class="form-label">E-mail de Acesso</label>
                <input type="email" class="form-input readonly" value="<%= nz(u.getEmail_usuario()) %>" readonly>
                <div class="form-hint">O e-mail não pode ser alterado. Entre em contato com o administrador.</div>
              </div>

              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Telefone</label>
                  <input type="tel" class="form-input" name="telefone" id="telInput"
                         value="<%= nz(u.getTelefone_usuario()) %>" placeholder="(71) 9 0000-0000"
                         inputmode="numeric" maxlength="16" oninput="phoneMask(this)">
                  <div class="field-error" id="telError"></div>
                </div>
                <div class="form-group">
                  <label class="form-label">Localização</label>
                  <input type="text" class="form-input" name="localizacao" id="locInput"
                         value="<%= nz(u.getLocalizacao_usuario()) %>" placeholder="Cidade, UF">
                  <div class="field-error" id="locError"></div>
                </div>
              </div>

              <% if (temAbas) { %>
                <!-- Se a aba Biografia existir, o campo bio (hidden) acompanha o mesmo POST -->
                <input type="hidden" name="bio" id="bioHidden" value="<%= nz(u.getBio_usuario()) %>">
              <% } %>

              <button type="submit" class="btn btn-primary">💾 Atualizar Dados</button>
            </form>
          </div>
        </div>

        <div style="display:flex;flex-direction:column;gap:22px">

          <!-- ===== Card: Cargo & Permissao (regra 4, igual pros 4 perfis) ===== -->
          <div class="card">
            <div class="card-head">
              <div class="card-head-title"><span class="card-icon">🔑</span> Cargo &amp; Permissão</div>
            </div>
            <div class="card-body">
              <div class="form-row">
                <div class="form-group">
                  <label class="form-label">Nível de Acesso</label>
                  <div class="role-badge"><%= cargoEmoji %> <%= cargoLabel %></div>
                </div>
                <div class="form-group">
                  <label class="form-label">Membro desde</label>
                  <input class="form-input readonly" value="<%= membroDesde %>" readonly>
                </div>
              </div>
            </div>
          </div>

          <!-- =====================================================
               Card variavel (regra 5): Autor / Visitante / Editor-Admin
               ===================================================== -->
          <% if ("AUTOR".equals(tipo)) { %>

            <!-- ---------- AUTOR: Minhas Receitas Publicadas ---------- -->
            <div class="card">
              <div class="card-head">
                <div class="card-head-title"><span class="card-icon">📊</span> Minhas Receitas Publicadas</div>
                <a href="<%= _ctx %>/ReceitaController" style="font-size:12px;color:var(--moss-light);text-decoration:none">Ver todas</a>
              </div>
              <div class="card-body" style="padding:16px">
                <% if (receitasPublicadas != null && !receitasPublicadas.isEmpty()) { %>
                  <div class="public-grid">
                    <% int limite = Math.min(3, receitasPublicadas.size());
                       for (int i = 0; i < limite; i++) {
                         Receita r = receitasPublicadas.get(i);
                    %>
                      <div class="public-mini">
                        <img src="<%= nz(r.getImagem_receita()) %>" alt="<%= nz(r.getTitulo_receita()) %>">
                        <div class="public-mini-body">
                          <div class="public-mini-title"><%= nz(r.getTitulo_receita()) %></div>
                          <div class="public-mini-cat"><%= nz(r.getEmoji_categoria()) %> <%= nz(r.getNome_categoria()) %></div>
                        </div>
                      </div>
                    <% } %>
                  </div>
                <% } else { %>
                  <div class="empty-state">Você ainda não publicou nenhuma receita.</div>
                <% } %>
              </div>
            </div>

          <% } else if ("VISITANTE".equals(tipo)) { %>

            <!-- ---------- VISITANTE: Minhas Receitas Favoritas ---------- -->
            <div class="card">
              <div class="card-head">
                <div class="card-head-title"><span class="card-icon">❤️</span> Minhas Receitas Favoritas</div>
                <a href="<%= _ctx %>/FavoritoController" style="font-size:12px;color:var(--moss-light);text-decoration:none">Ver todas</a>
              </div>
              <div class="card-body" style="padding:16px">
                <% if (receitasFavoritas != null && !receitasFavoritas.isEmpty()) { %>
                  <div class="public-grid">
                    <% int limite = Math.min(3, receitasFavoritas.size());
                       for (int i = 0; i < limite; i++) {
                         Receita r = receitasFavoritas.get(i);
                    %>
                      <div class="public-mini">
                        <img src="<%= nz(r.getImagem_receita()) %>" alt="<%= nz(r.getTitulo_receita()) %>">
                        <div class="public-mini-body">
                          <div class="public-mini-title"><%= nz(r.getTitulo_receita()) %></div>
                          <div class="public-mini-cat"><%= nz(r.getEmoji_categoria()) %> <%= nz(r.getNome_categoria()) %></div>
                        </div>
                      </div>
                    <% } %>
                  </div>
                <% } else { %>
                  <div class="empty-state">Você ainda não favoritou nenhuma receita.</div>
                <% } %>
              </div>
            </div>

          <% } else { %>

            <!-- ---------- EDITOR / ADMIN: Comentarios Denunciados (lista de texto simples) ---------- -->
            <div class="card">
              <div class="card-head">
                <div class="card-head-title"><span class="card-icon">🚩</span> Comentários Denunciados</div>
                <a href="<%= _ctx %>/ComentarioController" style="font-size:12px;color:var(--moss-light);text-decoration:none">Ver tudo</a>
              </div>
              <div class="card-body" style="padding-top:14px;padding-bottom:14px">
                <% if (comentariosDenunciados != null && !comentariosDenunciados.isEmpty()) { %>
                  <div class="log-list">
                    <% for (Comentario c : comentariosDenunciados) { %>
                      <div class="log-item">
                        <span class="log-dot"></span>
                        <div class="log-text">@<%= nz(c.getNome_usuario()) %> teve seu comentário denunciado há <%= tempoRelativo(c.getData_criacao_comentario()) %></div>
                      </div>
                    <% } %>
                  </div>
                <% } else { %>
                  <div class="empty-state">Nenhum comentário denunciado no momento.</div>
                <% } %>
              </div>
            </div>

          <% } %>

        </div>
      </div>
    </div>

    <!-- =========================================================
         PAINEL "BIOGRAFIA" — so existe para AUTOR / EDITOR (regra 2)
         ========================================================= -->
    <% if (temAbas) { %>
      <div id="tab-bio" class="tab-panel">
        <div class="card">
          <div class="card-head">
            <div class="card-head-title"><span class="card-icon">✍️</span> Sobre Você</div>
          </div>
          <div class="card-body">
            <div class="form-group">
              <label class="form-label">Título Profissional</label>
              <input type="text" class="form-input" id="tituloInput" value="<%= nz(u.getTitulo_usuario()) %>"
                     placeholder="Ex: Chef de Cozinha · Especialista em Culinária Italiana">
            </div>
            <div class="form-group" style="margin-bottom:0">
              <label class="form-label">Biografia (visível no perfil público)</label>
              <textarea class="form-textarea" id="bioInput" rows="4"
                        oninput="document.getElementById('bioHidden').value=this.value;"><%= nz(u.getBio_usuario()) %></textarea>
              <div class="form-hint">Esta descrição aparece na sua página pública de autor. Clique em "Atualizar Dados" na aba Dados Gerais para salvar.</div>
            </div>
          </div>
        </div>
      </div>
    <% } %>

  </div>
</main>

<!-- ===== MODAL AVATAR (estrutura visual — envio via JS/AJAX fora do escopo) ===== -->
<div class="modal-overlay" id="avatarModal">
  <div class="avatar-modal-box">
    <div class="avatar-modal-header">
      <div class="avatar-modal-title">📷 Alterar foto de perfil</div>
      <button class="avatar-modal-close" type="button" onclick="closeAvatarModal()">×</button>
    </div>
    <div class="avatar-modal-body">
      <div class="avatar-preview-area">
        <div class="avatar-preview-ring" id="avPreviewRing">
          <%= inicialNome %>
          <img id="avPreviewImg" alt="Preview">
        </div>
        <span class="avatar-preview-lbl">Pré-visualização</span>
      </div>
      <div class="drop-zone" id="avDropZone"
           ondragover="event.preventDefault();this.classList.add('drag-over')"
           ondragleave="this.classList.remove('drag-over')"
           ondrop="handleAvDrop(event)">
        <input type="file" id="avFileInput" accept="image/*" onchange="handleAvFile(this.files[0])">
        <span class="drop-icon">🖼️</span>
        <div class="drop-title">Arraste sua foto aqui</div>
        <div class="drop-sub">ou <span onclick="document.getElementById('avFileInput').click()">clique para selecionar</span></div>
        <div class="drop-sub" style="margin-top:4px">JPG, PNG, WEBP — máx. 5 MB</div>
      </div>
    </div>
    <div class="avatar-modal-footer">
      <button class="btn btn-outline" type="button" onclick="closeAvatarModal()">Cancelar</button>
      <button class="btn btn-primary" id="avSaveBtn" disabled type="button">💾 Salvar foto</button>
    </div>
  </div>
</div>

<script>
/* ===== TABS ===== */
function switchTab(id, btn) {
  document.querySelectorAll('.tab-panel').forEach(function (p) { p.classList.remove('active'); });
  document.querySelectorAll('.tab-btn').forEach(function (b) { b.classList.remove('active'); });
  document.getElementById('tab-' + id).classList.add('active');
  btn.classList.add('active');
}

/* ===== MASCARA TELEFONE ===== */
function phoneMask(input) {
  var v = input.value.replace(/\D/g, ''), f = '';
  if (v.length > 0) f = '(' + v.substring(0, 2);
  if (v.length > 2) f += ') ' + v.substring(2, 7);
  if (v.length > 7) f += '-' + v.substring(7, 11);
  input.value = f;
}

/* ===== MODAL AVATAR (so estrutura/preview — sem envio real) ===== */
function openAvatarModal() { document.getElementById('avatarModal').classList.add('show'); }
function closeAvatarModal() { document.getElementById('avatarModal').classList.remove('show'); }
document.getElementById('avatarModal').addEventListener('click', function (e) {
  if (e.target === this) closeAvatarModal();
});

function handleAvFile(file) {
  if (!file) return;
  var reader = new FileReader();
  reader.onload = function (e) {
    var img = document.getElementById('avPreviewImg');
    img.src = e.target.result;
    img.classList.add('visible');
    document.getElementById('avPreviewRing').classList.add('has-img');
    document.getElementById('avSaveBtn').disabled = false;
  };
  reader.readAsDataURL(file);
}
function handleAvDrop(e) {
  e.preventDefault();
  document.getElementById('avDropZone').classList.remove('drag-over');
  handleAvFile(e.dataTransfer.files[0]);
}
</script>

</body>
</html>
