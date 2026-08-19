<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%
    // Usuário logado (ajuste o nome do atributo de sessão se for diferente no seu projeto)
    Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
    if (usuarioLogado == null) {
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    // Sidebar unificado (o mesmo /pages/includes/sidebar.jsp usado nas
    // demais telas do sistema, ex: home.jsp) - ele já resolve sozinho o
    // menu certo pra cada perfil (ADMIN/EDITOR/AUTOR/VISITANTE) olhando a
    // sessão, entao nao precisamos mais escolher entre varios arquivos de
    // sidebar separados aqui. Isso evita depender de fragmentos antigos
    // (sidebar-editor-admin.jsp, sidebar-editor.html, sidebar-visitante.html)
    // que podiam estar ausentes/desatualizados e derrubar a tela.
    request.setAttribute("currentPage", "configuracoes");
    
    // Iniciais do avatar (ex: "Maria Andrade" -> "MA")
    String nome = usuarioLogado.getNome_usuario() != null ? usuarioLogado.getNome_usuario() : "";
    String[] partes = nome.trim().split("\\s+");
    String iniciais = "";
    if (partes.length > 0 && partes[0].length() > 0) iniciais += partes[0].charAt(0);
    if (partes.length > 1 && partes[partes.length - 1].length() > 0) iniciais += partes[partes.length - 1].charAt(0);
    iniciais = iniciais.toUpperCase();

    // Aba a exibir ao carregar (o Controller manda via request.setAttribute("aba", ...))
    String abaAtiva = request.getAttribute("aba") != null ? (String) request.getAttribute("aba") : "seguranca";
    request.setAttribute("abaAtiva", abaAtiva);
    
    // Mensagens vindas do ConfiguracaoController (PRG: sucesso/erro na sessão -> request)
    String sucesso = (String) request.getAttribute("sucesso");
    String erro    = (String) request.getAttribute("erro");

    String temaAtual = usuarioLogado.getTema() != null ? usuarioLogado.getTema().name() : "LIGHT"; // LIGHT | DARK | HIGH_CONTRAST
    request.setAttribute("temaAtual", temaAtual);
    // Escapa aspas/quebras de linha pra poder jogar dentro de string JS com segurança
    String sucessoJs = sucesso != null ? sucesso.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ") : null;
    String erroJs = erro != null ? erro.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ") : null;
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor & Arte — Configurações</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,400;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800;900&display=swap" rel="stylesheet">
<style>
  :root{--moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;--sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;--warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;--gold:#c4a265;--gold-light:#dfc094;--published:#3a7a4a;--published-bg:#e8f4eb;--pending:#c4832a;--pending-bg:#fdf2e3;--error:#9b4444;--error-bg:#fdf0f0;--error-border:rgba(155,68,68,0.25);--sidebar-w:260px;}

  /* ===== TEMA NOTURNO ===== */
  body.dark-mode{
    --cream:#1a1f16;--cream-dark:#252c1f;--warm-white:#1f2619;
    --text-dark:#dde8d0;--text-mid:#a8b89a;--text-light:#6a7d5e;
    --moss:#6b9c55;--moss-dark:#4a7a38;--moss-light:#88b870;
    --sage:#4a5e3a;--sage-light:#5a7048;
    --gold:#c4a265;--gold-light:#dfc094;
  }
  body.dark-mode .sidebar{background:#111810;}
  body.dark-mode .sidebar .brand-title{color:#dde8d0;}
  body.dark-mode .sidebar .brand-sub{color:#6b9c55;}
  body.dark-mode .sidebar .user-name{color:#dde8d0;}
  body.dark-mode .sidebar .user-role-badge{color:#88b870;}
  body.dark-mode .sidebar .nav-section-label{color:rgba(107,156,85,0.45);}
  body.dark-mode .sidebar .nav-item{color:rgba(221,232,208,0.6);}
  body.dark-mode .sidebar .nav-item:hover{color:#dde8d0;background:rgba(255,255,255,0.05);}
  body.dark-mode .sidebar .nav-item.active{color:#dde8d0;background:rgba(107,156,85,0.14);}
  body.dark-mode .sidebar .btn-logout{color:rgba(221,232,208,0.6);border-color:rgba(221,232,208,0.12);background:rgba(255,255,255,0.04);}
  body.dark-mode .sidebar .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}
  body.dark-mode .topbar{background:#1f2619;border-bottom-color:#252c1f;}
  body.dark-mode .card{background:#1f2619;border-color:#252c1f;}
  body.dark-mode .card-hd{border-bottom-color:#252c1f;}
  body.dark-mode .tab-nav{background:#252c1f;}
  body.dark-mode .tab-btn.active{background:#1f2619;}
  body.dark-mode .fi,body.dark-mode .fs,body.dark-mode .fta{background:#252c1f;border-color:#2e3828;color:var(--text-dark);}
  body.dark-mode .fi:focus,body.dark-mode .fs:focus{background:#1a1f16;}
  body.dark-mode .theme-card{background:#252c1f;border-color:#2e3828;color:var(--text-light);}
  body.dark-mode .theme-card.selected{background:rgba(107,156,85,0.15);border-color:var(--moss);color:var(--moss);}
  body.dark-mode .modal-box{background:#1f2619;}
  body.dark-mode .tgl-slider{background:#2e3828;}
  body.dark-mode .pw-bar{background:#2e3828;}

  /* ===== TEMA ALTO CONTRASTE ===== */
  body.high-contrast{
    --cream:#000000;--cream-dark:#111111;--warm-white:#0a0a0a;
    --text-dark:#FFFF00;--text-mid:#FFFF00;--text-light:#cccc00;
    --moss:#FFFF00;--moss-dark:#cccc00;--moss-light:#FFFF00;
    --sage:#888800;--sage-light:#aaaa00;
    --gold:#FFFF00;--gold-light:#FFFF00;
    --published:#FFFF00;--published-bg:#111100;
    --pending:#FFFF00;--pending-bg:#111100;
    --error:#ff4444;--error-bg:#110000;--error-border:#ff4444;
  }
  body.high-contrast .sidebar{background:#000;border-right:3px solid #FFFF00;}
  body.high-contrast .sidebar .brand-title{color:#FFFF00;}
  body.high-contrast .sidebar .brand-sub{color:#888800;}
  body.high-contrast .sidebar .user-name{color:#FFFF00;}
  body.high-contrast .sidebar .user-role-badge{color:#aaaa00;}
  body.high-contrast .sidebar .user-avatar{background:#FFFF00;color:#000;}
  body.high-contrast .sidebar .nav-section-label{color:#555500;}
  body.high-contrast .sidebar .nav-item{color:rgba(255,255,0,0.7);border-left-color:transparent;}
  body.high-contrast .sidebar .nav-item:hover{background:rgba(255,255,0,0.1);color:#FFFF00;border-left-color:#FFFF00;}
  body.high-contrast .sidebar .nav-item.active{background:rgba(255,255,0,0.15);color:#FFFF00;border-left-color:#FFFF00;}
  body.high-contrast .sidebar .btn-logout{color:rgba(255,255,0,0.7);border-color:rgba(255,255,0,0.3);background:rgba(255,255,0,0.05);}
  body.high-contrast .sidebar .btn-logout:hover{background:rgba(255,68,68,0.2);border-color:#ff4444;color:#ff8888;}
  body.high-contrast .topbar{background:#000;border-bottom:3px solid #FFFF00;}
  body.high-contrast .card{background:#0a0a0a;border:2px solid #FFFF00;}
  body.high-contrast .card-hd{border-bottom:2px solid #FFFF00;}
  body.high-contrast .tab-nav{background:#111;}
  body.high-contrast .tab-btn{color:#FFFF00;}
  body.high-contrast .tab-btn.active{background:#FFFF00;color:#000;}
  body.high-contrast .fi,body.high-contrast .fs,body.high-contrast .fta{background:#000;border:2px solid #FFFF00;color:#FFFF00;}
  body.high-contrast .fi::placeholder,body.high-contrast .fs::placeholder{color:#888800;}
  body.high-contrast .fi:focus,body.high-contrast .fs:focus{box-shadow:0 0 0 3px rgba(255,255,0,0.3);}
  body.high-contrast .btn-primary{background:#FFFF00;color:#000;border:2px solid #FFFF00;}
  body.high-contrast .btn-ghost,body.high-contrast .btn-outline{color:#FFFF00;border-color:#FFFF00;}
  body.high-contrast .btn-ghost:hover,body.high-contrast .btn-outline:hover{background:#FFFF00;color:#000;}
  body.high-contrast .theme-card{background:#000;border:2px solid #FFFF00;color:#FFFF00;}
  body.high-contrast .theme-card.selected{background:#FFFF00;color:#000;}
  body.high-contrast .modal-box{background:#0a0a0a;border:3px solid #FFFF00;}
  body.high-contrast .tgl-slider{background:#333;}
  body.high-contrast .tgl input:checked+.tgl-slider{background:#FFFF00;}
  body.high-contrast .tgl-slider::before{background:#FFFF00;}
  body.high-contrast .tgl input:checked+.tgl-slider::before{background:#000;}
  body.high-contrast .section-sep{border-bottom-color:#FFFF00;color:#FFFF00;}
  body.high-contrast .toggle-row{border-bottom-color:#333;}
  body.high-contrast .pw-bar{background:#333;}

  *{margin:0;padding:0;box-sizing:border-box;}html,body{overflow-x:hidden;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;transition:background 0.3s,color 0.3s;}

  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .topbar-left{display:flex;align-items:center;gap:14px;}
  .menu-toggle{display:none;background:none;border:none;font-size:22px;cursor:pointer;color:var(--text-dark);padding:4px;}
  .crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;}
  .crumb .cur{color:var(--moss);font-weight:500;}

  .btn{display:inline-flex;align-items:center;gap:8px;padding:9px 18px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:all 0.2s;white-space:nowrap;}
  .btn-primary{background:var(--moss);color:var(--cream);}
  .btn-primary:hover{background:var(--moss-dark);}
  .btn-outline{background:none;color:var(--moss);border:1.5px solid var(--moss);}
  .btn-outline:hover{background:rgba(74,94,58,0.07);}
  .btn-ghost{background:none;color:var(--text-mid);border:1.5px solid var(--cream-dark);}
  .btn-ghost:hover{border-color:var(--moss-light);color:var(--moss);}
  .btn-xs{padding:5px 10px;font-size:11px;font-weight:600;}

  .content{flex:1;padding:32px 40px;}
  .page-hd{margin-bottom:24px;}
  .page-hd h1{font-family:'Playfair Display',serif;font-size:27px;font-weight:500;color:var(--text-dark);line-height:1;}
  .page-hd h1 em{font-style:italic;color:var(--moss);}
  .page-hd p{font-size:13px;color:var(--text-light);font-weight:300;margin-top:5px;}

  .tab-nav{display:flex;gap:2px;background:var(--cream-dark);padding:4px;border-radius:4px;margin-bottom:28px;width:fit-content;flex-wrap:wrap;}
  .tab-btn{padding:9px 18px;border:none;border-radius:2px;background:none;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;color:var(--text-light);cursor:pointer;transition:all 0.2s;display:flex;align-items:center;gap:7px;white-space:nowrap;}
  .tab-btn:hover{color:var(--text-dark);}
  .tab-btn.active{background:var(--warm-white);color:var(--moss);box-shadow:0 1px 4px rgba(0,0,0,0.08);}

  .tab-panel{display:none;}
  .tab-panel.active{display:flex;flex-direction:column;gap:20px;}

  .card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .card-hd{padding:16px 22px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .card-hd-title{font-size:14px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:9px;}
  .card-hd-sub{font-size:12px;color:var(--text-light);font-weight:300;margin-top:2px;}
  .card-body{padding:22px 24px;}

  .form-row{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
  .fg{display:flex;flex-direction:column;gap:0;margin-bottom:18px;}
  .fg:last-child{margin-bottom:0;}
  .fl{display:block;font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1px;margin-bottom:7px;}
  .fi,.fs,.fta{width:100%;padding:10px 13px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:14px;color:var(--text-dark);background:var(--cream);transition:border-color 0.2s,box-shadow 0.2s;outline:none;}
  .fi:focus,.fs:focus,.fta:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.09);}
  .fhint{font-size:11px;color:var(--text-light);margin-top:6px;font-weight:300;line-height:1.5;}

  .pw-wrap{position:relative;}
  .pw-wrap .fi{padding-right:44px;}
  .pw-eye{position:absolute;right:12px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;font-size:15px;color:var(--text-light);transition:color 0.2s;}
  .pw-eye:hover{color:var(--moss);}
  .pw-wrap input[type="password"]::-ms-reveal,
  .pw-wrap input[type="password"]::-ms-clear{display:none;}
  .pw-wrap input::-webkit-credentials-auto-fill-button,
  .pw-wrap input::-webkit-strong-password-auto-fill-button{display:none !important;visibility:hidden;pointer-events:none;position:absolute;right:0;}

  .toggle-row{display:flex;align-items:flex-start;justify-content:space-between;padding:14px 0;border-bottom:1px solid var(--cream-dark);gap:16px;}
  .toggle-row:first-child{padding-top:0;}
  .toggle-row:last-child{border-bottom:none;padding-bottom:0;}
  .toggle-info strong{font-size:13px;font-weight:500;color:var(--text-dark);display:block;line-height:1.3;}
  .toggle-info span{font-size:12px;color:var(--text-light);font-weight:300;margin-top:2px;display:block;line-height:1.5;}
  .tgl{position:relative;display:inline-block;width:42px;height:24px;flex-shrink:0;margin-top:2px;}
  .tgl input{opacity:0;width:0;height:0;}
  .tgl-slider{position:absolute;cursor:pointer;inset:0;background:var(--cream-dark);border-radius:24px;transition:background 0.25s;}
  .tgl-slider::before{content:'';position:absolute;height:18px;width:18px;left:3px;top:3px;background:white;border-radius:50%;transition:transform 0.25s;box-shadow:0 1px 4px rgba(0,0,0,0.18);}
  .tgl input:checked+.tgl-slider{background:var(--moss);}
  .tgl input:checked+.tgl-slider::before{transform:translateX(18px);}

  .pw-strength{margin:10px 0 6px;}
  .pw-strength-bars{display:flex;gap:4px;margin-bottom:5px;}
  .pw-bar{flex:1;height:4px;border-radius:2px;background:var(--cream-dark);transition:background 0.3s;}
  .pw-bar.active-1{background:var(--error);}
  .pw-bar.active-2{background:var(--pending);}
  .pw-bar.active-3{background:var(--gold);}
  .pw-bar.active-4{background:var(--published);}
  .pw-strength-label{font-size:11px;font-weight:600;}

  .theme-cards{display:flex;gap:10px;margin-bottom:8px;}
  .theme-card{flex:1;padding:18px 10px;border-radius:6px;border:2px solid var(--cream-dark);cursor:pointer;text-align:center;font-size:12px;font-weight:600;transition:all 0.2s;color:var(--text-light);background:var(--cream);}
  .theme-card:hover{border-color:var(--moss-light);color:var(--text-mid);}
  .theme-card.selected{border-color:var(--moss);background:rgba(74,94,58,0.07);color:var(--moss);}
  .theme-card-icon{font-size:24px;margin-bottom:8px;display:block;}

  .section-sep{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:1.2px;color:var(--text-light);margin:22px 0 14px;padding-bottom:8px;border-bottom:1px solid var(--cream-dark);}

  .modal-ov{display:none;position:fixed;inset:0;background:rgba(0,0,0,0.48);z-index:500;align-items:center;justify-content:center;}
  .modal-ov.show{display:flex;}
  .modal-box{background:var(--warm-white);border-radius:4px;padding:36px 40px;text-align:center;min-width:340px;max-width:480px;box-shadow:0 20px 60px rgba(0,0,0,0.22);}
  .modal-icon{font-size:52px;margin-bottom:14px;}
  .modal-title{font-family:'Playfair Display',serif;font-size:21px;font-weight:700;color:var(--text-dark);margin-bottom:8px;}
  .modal-msg{font-size:13px;color:var(--text-light);margin-bottom:24px;font-weight:300;line-height:1.6;}
  .modal-actions{display:flex;gap:10px;justify-content:center;}

  @media(max-width:768px){
    .main{margin-left:0;}.content{padding:20px;}.topbar{padding:0 20px;}
    .menu-toggle{display:block;}
    .form-row{grid-template-columns:1fr;}
    .tab-nav{overflow-x:auto;}
    .theme-cards{flex-wrap:wrap;}
  }
  @media(max-width:480px){.modal-box{margin:20px;padding:28px 24px;}}
</style>
</head>
<body class="${temaAtual == 'DARK' ? 'dark-mode' : (temaAtual == 'HIGH_CONTRAST' ? 'high-contrast' : '')}">


<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
  <div class="topbar">
    <div class="topbar-left">
      <button class="menu-toggle" onclick="toggleSidebar()">☰</button>
      <div class="crumb">
        <span>Análise</span>
        <span style="color:var(--cream-dark)">/</span>
        <span class="cur">Configurações</span>
      </div>
    </div>
  </div>

  <div class="content">
    <div class="page-hd">
      <h1>⚙️ <em>Configurações</em></h1>
      <p>Gerencie sua conta, preferências de tema e segurança</p>
    </div>

    <div class="tab-nav">
      <!-- <button class="tab-btn ${abaAtiva == 'conta' ? 'active' : ''}" onclick="switchTab('conta',this)">⚙️ Conta</button>-->
      <button class="tab-btn ${abaAtiva == 'seguranca' ? 'active' : ''}" onclick="switchTab('seguranca',this)">🔒 Segurança</button>
    </div>

<%--
    <!-- ===== CONTA ===== -->
    <div id="tab-conta" class="tab-panel ${abaAtiva == 'conta' ? 'active' : ''}">
      <form action="${pageContext.request.contextPath}/ConfiguracaoController" method="post">
        <input type="hidden" name="action" value="tema">
        <input type="hidden" name="tema" id="temaInput" value="${temaAtual}">
        <div class="card">
          <div class="card-hd">
            <div>
              <div class="card-hd-title">⚙️ Preferências da Conta</div>
              <div class="card-hd-sub">Aparência e comportamento geral do sistema</div>
            </div>
          </div>
          <div class="card-body">
            <div class="section-sep">Aparência</div>

            <div class="fg">
              <label class="fl">Tema Visual</label>
              <div class="theme-cards">
                <div class="theme-card ${temaAtual == 'LIGHT' ? 'selected' : ''}" id="tc-light" onclick="selectTheme('LIGHT')">
                  <span class="theme-card-icon">☀️</span>
                  Claro
                </div>
                <div class="theme-card ${temaAtual == 'DARK' ? 'selected' : ''}" id="tc-dark" onclick="selectTheme('DARK')">
                  <span class="theme-card-icon">🌙</span>
                  Noturno
                </div>
                <div class="theme-card ${temaAtual == 'HIGH_CONTRAST' ? 'selected' : ''}" id="tc-high-contrast" onclick="selectTheme('HIGH_CONTRAST')">
                  <span class="theme-card-icon">⚡</span>
                  Alto Contraste
                </div>
              </div>
              <div class="fhint">Define o esquema de cores de toda a interface</div>
            </div>

            <button type="submit" class="btn btn-primary" style="margin-top:6px">💾 Salvar Preferências</button>
          </div>
        </div>
      </form>
    </div> 
--%>
    <!-- ===== SEGURANÇA ===== -->
    <div id="tab-seguranca" class="tab-panel ${abaAtiva == 'seguranca' ? 'active' : ''}">
      <form action="${pageContext.request.contextPath}/ConfiguracaoController" method="post" onsubmit="return validarFormSenha()">
        <input type="hidden" name="action" value="senha">
        <div class="card">
          <div class="card-hd">
            <div>
              <div class="card-hd-title">🔑 Alterar Senha</div>
              <div class="card-hd-sub">Use uma senha forte com letras, números e símbolos</div>
            </div>
          </div>
          <div class="card-body">
            <div class="form-row">
              <div class="fg">
                <label class="fl">Nova Senha</label>
                <div class="pw-wrap">
                  <input type="password" class="fi" id="pw1" name="novaSenha" placeholder="Mínimo 8 caracteres" oninput="updateStrength(this.value)" required minlength="8">
                  <button type="button" class="pw-eye" onclick="togglePw('pw1')">👁</button>
                </div>
                <div class="pw-strength">
                  <div class="pw-strength-bars">
                    <div class="pw-bar" id="pwb1"></div>
                    <div class="pw-bar" id="pwb2"></div>
                    <div class="pw-bar" id="pwb3"></div>
                    <div class="pw-bar" id="pwb4"></div>
                  </div>
                  <span class="pw-strength-label" id="pw-label" style="color:var(--text-light)">Digite uma senha</span>
                </div>
              </div>
              <div class="fg">
                <label class="fl">Confirmar Nova Senha</label>
                <div class="pw-wrap">
                  <input type="password" class="fi" id="pw2" name="confirmarSenha" placeholder="••••••••" required>
                  <button type="button" class="pw-eye" onclick="togglePw('pw2')">👁</button>
                </div>
              </div>
            </div>
            <button type="submit" class="btn btn-primary">🔒 Alterar Senha</button>
          </div>
        </div>
      </form>
    </div>

  </div>
</main>

<div class="modal-ov" id="modalOv">
  <div class="modal-box">
    <div class="modal-icon" id="mIcon">✅</div>
    <div class="modal-title" id="mTitle">Sucesso!</div>
    <div class="modal-msg" id="mMsg">Operação concluída com sucesso.</div>
    <div class="modal-actions">
      <button class="btn btn-ghost" onclick="closeModal()">Fechar</button>
      <button class="btn btn-primary" onclick="closeModal()">OK</button>
    </div>
  </div>
</div>

<script>
  function switchTab(id,btn){
    document.querySelectorAll('.tab-panel').forEach(p=>p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
    document.getElementById('tab-'+id).classList.add('active');
    btn.classList.add('active');
  }
  function togglePw(id){var i=document.getElementById(id);i.type=i.type==='password'?'text':'password';}
  function updateStrength(v){
    var s=0;
    if(v.length>=8)s++;
    if(/[A-Z]/.test(v))s++;
    if(/[0-9]/.test(v))s++;
    if(/[^A-Za-z0-9]/.test(v))s++;
    var cls=['','active-1','active-2','active-3','active-4'];
    var lbs=['','Fraca','Média','Boa','Forte'];
    var tc=['var(--text-light)','var(--error)','var(--pending)','var(--gold)','var(--published)'];
    ['pwb1','pwb2','pwb3','pwb4'].forEach(function(id,i){
      var el=document.getElementById(id);
      el.className='pw-bar'+(i<s?' '+cls[s]:'');
    });
    var l=document.getElementById('pw-label');
    l.textContent=v.length===0?'Digite uma senha':lbs[s];
    l.style.color=v.length===0?'var(--text-light)':tc[s];
  }
  function validarFormSenha(){
    var nova=document.getElementById('pw1').value;
    var conf=document.getElementById('pw2').value;
    if(nova!==conf){
      alert('A nova senha e a confirmação não conferem.');
      return false;
    }
    return true;
  }

  // Pré-visualização do tema (a persistência real acontece no submit do form)
  function selectTheme(tema){
    ['light','dark','high-contrast'].forEach(function(t){
      var idTema = t.replace('-', '_').toUpperCase();
      document.getElementById('tc-'+t).classList.toggle('selected', idTema===tema);
    });
    document.body.classList.remove('dark-mode','high-contrast');
    if(tema==='DARK') document.body.classList.add('dark-mode');
    else if(tema==='HIGH_CONTRAST') document.body.classList.add('high-contrast');
    document.getElementById('temaInput').value = tema;
  }

  function showModal(icon,title,msg){
    document.getElementById('mIcon').textContent=icon;
    document.getElementById('mTitle').textContent=title;
    document.getElementById('mMsg').textContent=msg;
    document.getElementById('modalOv').classList.add('show');
  }
  function closeModal(){document.getElementById('modalOv').classList.remove('show');}
  document.getElementById('modalOv').addEventListener('click',function(e){if(e.target===this)closeModal();});

  <% if (sucessoJs != null) { %>
  showModal('✅', 'Sucesso!', '<%= sucessoJs %>');
  <% } %>
  <% if (erroJs != null) { %>
  showModal('⚠️', 'Ops!', '<%= erroJs %>');
  <% } %>
</script>
</body>
</html>
