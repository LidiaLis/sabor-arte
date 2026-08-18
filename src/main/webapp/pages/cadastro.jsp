<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%--
  ============================================================================
  cadastro.jsp — tela própria de "Criar conta"
  ----------------------------------------------------------------------------
  Antes era um fragmento (modal-cadastro.jsp) carregado via fetch() dentro
  de login.jsp. Agora é uma página completa e independente, no mesmo padrão
  visual do login.jsp (mesmo card, mesmo fundo, mesmas animações).

  Form envia POST para UsuarioController (action=cadastrar), igual antes.

  Espera-se que o UsuarioController, ao terminar de processar o cadastro:
    - em caso de ERRO  -> session.setAttribute("erro", "mensagem...")
                           depois response.sendRedirect(.../cadastro.jsp)
    - em caso de SUCESSO -> session.setAttribute("sucesso", "mensagem...")
                             depois redireciona para login.jsp (ou já loga
                             o usuário e manda para o dashboard — a decidir).
  (mesmo padrão de erro/sucesso via sessão já usado no login.jsp)
  ============================================================================
--%>
<%
    // Se já está logado, não faz sentido mostrar cadastro — manda pro dashboard
    Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
    if (usuarioLogado != null) {
        response.sendRedirect(request.getContextPath() + "/pages/HTML/dashboard.html");
        return;
    }

    // Erro/sucesso vindos do UsuarioController (padrão idêntico ao login.jsp)
    String erro = (String) session.getAttribute("erro");
    if (erro != null) {
        session.removeAttribute("erro");
    }

    String sucesso = (String) session.getAttribute("sucesso");
    if (sucesso != null) {
        session.removeAttribute("sucesso");
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Criar conta</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:        #4a5e3a;
    --moss-dark:   #2f3d25;
    --moss-light:  #6b7f59;
    --sage:        #a3b18a;
    --cream:       #f5f0e8;
    --cream-dark:  #e8e0d0;
    --warm-white:  #faf8f4;
    --text-dark:   #1e2718;
    --text-mid:    #4a5240;
    --text-light:  #8a9480;
    --gold:        #c4a265;
    --error:       #9b4444;
    --danger:      #9b4444;
    --pending:     #c4832a;
    --published:   #3a7a4a;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'DM Sans', sans-serif;
    min-height: 100vh;
    background-color: var(--moss-dark);
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow-x: hidden;
  }

  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background:
      radial-gradient(ellipse 80% 60% at 15% 20%, rgba(74,94,58,0.6) 0%, transparent 60%),
      radial-gradient(ellipse 60% 80% at 85% 80%, rgba(163,177,138,0.2) 0%, transparent 50%),
      radial-gradient(ellipse 40% 40% at 50% 50%, rgba(47,61,37,0.8) 0%, transparent 70%);
    background-color: var(--moss-dark);
    z-index: 0;
  }

  .bg-leaf { position: fixed; opacity: 0.06; pointer-events: none; z-index: 0; }
  .bg-leaf-1 { top: -80px; right: -80px; width: 500px; height: 500px; background: radial-gradient(ellipse, var(--sage) 0%, transparent 70%); border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%; }
  .bg-leaf-2 { bottom: -120px; left: -60px; width: 400px; height: 400px; background: radial-gradient(ellipse, var(--gold) 0%, transparent 70%); border-radius: 70% 30% 30% 70% / 70% 70% 30% 30%; opacity: 0.04; }

  .bg-grid {
    position: fixed; inset: 0;
    background-image:
      linear-gradient(rgba(163,177,138,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(163,177,138,0.04) 1px, transparent 1px);
    background-size: 48px 48px;
    z-index: 0;
  }

  .signup-card {
    position: relative; z-index: 1;
    width: 100%; max-width: 480px; margin: 24px;
    background: var(--warm-white);
    border-radius: 2px; overflow: hidden;
    box-shadow: 0 0 0 1px rgba(74,94,58,0.15), 0 40px 80px rgba(0,0,0,0.4), 0 8px 20px rgba(0,0,0,0.2);
    animation: cardReveal 0.5s cubic-bezier(0.16,1,0.3,1) both;
    display: flex; flex-direction: column;
  }

  @keyframes cardReveal {
    from { opacity: 0; transform: translateY(32px) scale(0.97); }
    to   { opacity: 1; transform: translateY(0) scale(1); }
  }

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(14px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  .card-bar { height: 4px; background: linear-gradient(90deg, var(--gold), var(--sage), var(--moss), var(--moss-dark)); }
  .card-header { padding: 24px 40px 18px; background: var(--warm-white); border-bottom: 1px solid var(--cream-dark); }

  .brand-mark { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; animation: fadeUp 0.6s 0.1s both; }
  .brand-icon { width: 36px; height: 36px; background: var(--moss); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 22px; flex-shrink: 0; position: relative; }
  .brand-icon::after { content: ''; position: absolute; inset: 3px; border: 1px solid rgba(255,255,255,0.2); border-radius: 1px; }
  .brand-text { line-height: 1; }
  .brand-name { font-family: 'Playfair Display', serif; font-size: 22px; font-weight: 700; color: var(--moss-dark); letter-spacing: -0.3px; display: block; }
  .brand-tagline { font-size: 11px; color: var(--text-light); text-transform: uppercase; letter-spacing: 1.2px; margin-top: 2px; display: block; }

  .card-title { font-family: 'Playfair Display', serif; font-size: 30px; font-weight: 500; color: var(--text-dark); line-height: 1.15; animation: fadeUp 0.6s 0.16s both; }
  .card-title em { font-style: italic; color: var(--moss); }
  .card-subtitle { font-size: 14px; color: var(--text-light); margin-top: 4px; font-weight: 300; animation: fadeUp 0.6s 0.2s both; }

  .card-body { padding: 20px 40px 26px; display: flex; flex-direction: column; flex: 1; }

  .error-msg { background: rgba(155,68,68,0.08); border: 1px solid rgba(155,68,68,0.25); border-left: 3px solid var(--error); border-radius: 2px; padding: 8px 12px; font-size: 12px; color: var(--error); margin-bottom: 14px; animation: fadeUp 0.5s both; }
  .success-msg { background: rgba(74,94,58,0.08); border: 1px solid rgba(74,94,58,0.25); border-left: 3px solid var(--moss); border-radius: 2px; padding: 8px 12px; font-size: 12px; color: var(--moss-dark); margin-bottom: 14px; animation: fadeUp 0.5s both; }

  .field { margin-bottom: 13px; animation: fadeUp 0.6s both; }
  .field label { display: block; font-size: 11px; font-weight: 500; color: var(--text-mid); text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 5px; }
  .field .req { color: var(--error); }
  .field input {
    width: 100%; padding: 10px 14px; border: 1.5px solid var(--cream-dark); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; color: var(--text-dark);
    background: var(--cream); outline: none;
    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
  }
  .field input:focus { border-color: var(--moss); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }
  .field input::placeholder { color: var(--text-light); font-weight: 300; }
  .field-hint { font-size: 10px; color: var(--text-light); margin-top: 3px; }

  .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

  /* ── SELETOR DE TIPO DE CONTA ── */
  .role-group { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  .role-option {
    display: flex; flex-direction: column; align-items: flex-start; gap: 1px;
    padding: 10px 14px; border: 1.5px solid var(--cream-dark); border-radius: 2px;
    background: var(--cream); cursor: pointer; text-align: left;
    font-family: 'DM Sans', sans-serif; transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
  }
  .role-option-icon { font-size: 18px; margin-bottom: 2px; }
  .role-option-title { font-size: 15px; font-weight: 500; color: var(--text-dark); }
  .role-option-desc { font-size: 12px; color: var(--text-light); font-weight: 300; line-height: 1.25; }
  .role-option:hover { border-color: var(--moss-light); }
  .role-option.selected { border-color: var(--moss); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }
  .role-option.selected .role-option-title { color: var(--moss-dark); }

  /* ── VALIDAÇÃO INLINE ── */
  .field-error { font-size: 11px; color: var(--danger); margin-top: 4px; font-weight: 500; display: none; }
  .field-error.show { display: block; }

  /* ── SENHA: olho de mostrar/ocultar + medidor de força ── */
  .pw-wrap { position: relative; }
  .pw-wrap input { padding-right: 44px; }
  .pw-eye { position: absolute; right: 12px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; font-size: 15px; color: var(--text-light); transition: color 0.2s; }
  .pw-eye:hover { color: var(--moss); }
  .pw-wrap input[type="password"]::-ms-reveal,
  .pw-wrap input[type="password"]::-ms-clear { display: none; }
  .pw-wrap input::-webkit-credentials-auto-fill-button,
  .pw-wrap input::-webkit-strong-password-auto-fill-button,
  .pw-wrap input::-webkit-contacts-auto-fill-button {
    display: none !important; visibility: hidden; pointer-events: none; position: absolute; right: 0;
  }

  .pw-strength { margin: 6px 0 1px; }
  .pw-strength-bars { display: flex; gap: 4px; margin-bottom: 4px; }
  .pw-bar { flex: 1; height: 3px; border-radius: 2px; background: var(--cream-dark); transition: background 0.3s; }
  .pw-bar.active-1 { background: var(--danger); }
  .pw-bar.active-2 { background: var(--pending); }
  .pw-bar.active-3 { background: var(--gold); }
  .pw-bar.active-4 { background: var(--published); }
  .pw-strength-label { font-size: 10px; font-weight: 600; }

  .btn-signup {
    width: 100%; padding: 12px; background: var(--moss); color: var(--cream);
    border: none; border-radius: 2px; margin-top: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500; letter-spacing: 0.5px;
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    animation: fadeUp 0.6s both; position: relative; overflow: hidden;
    transition: background 0.25s, transform 0.15s, box-shadow 0.25s;
  }
  .btn-signup::before { content: ''; position: absolute; inset: 0; background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, transparent 50%); }
  .btn-signup:hover { background: var(--moss-dark); transform: translateY(-1px); box-shadow: 0 8px 24px rgba(47,61,37,0.4); }
  .btn-signup:active { transform: translateY(0); }

  .divider { display: flex; align-items: center; gap: 12px; margin: 14px 0; animation: fadeUp 0.6s both; }
  .divider-line { flex: 1; height: 1px; background: var(--cream-dark); }
  .divider-text { font-size: 10px; color: var(--text-light); text-transform: uppercase; letter-spacing: 1px; }

  .btn-login-link {
    width: 100%; padding: 11px; background: transparent;
    border: 1.5px solid var(--sage); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500; color: var(--moss);
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    text-decoration: none; animation: fadeUp 0.6s both; transition: background 0.2s, border-color 0.2s;
  }
  .btn-login-link:hover { background: rgba(74,94,58,0.06); border-color: var(--moss-light); }

  .version-tag { text-align: center; margin-top: 14px; animation: fadeUp 0.6s both; }
  .version-tag span { font-size: 10px; color: var(--text-light); font-weight: 300; letter-spacing: 0.5px; }
  .version-tag strong { font-size: 10px; color: var(--moss-light); font-weight: 500; }

  @media (max-width: 560px) {
    .card-header, .card-body { padding-left: 26px; padding-right: 26px; }
    .form-row, .role-group { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>

<div class="bg-leaf bg-leaf-1"></div>
<div class="bg-leaf bg-leaf-2"></div>
<div class="bg-grid"></div>

<!-- ── CARD DE CADASTRO ── -->
<div class="signup-card">
  <div class="card-bar"></div>

  <div class="card-header">
    <div class="brand-mark">
      <div class="brand-icon">🌿</div>
      <div class="brand-text">
        <span class="brand-name">Sabor &amp; Arte</span>
        <span class="brand-tagline">Blog Culinário Editorial</span>
      </div>
    </div>
    <div class="card-title">Criar <em>conta</em></div>
    <div class="card-subtitle">Preencha os dados para se cadastrar</div>
  </div>

  <div class="card-body">

    <%-- ① ERRO / SUCESSO VINDOS DO SERVIDOR (UsuarioController) --%>
    <% if (erro != null && !erro.isEmpty()) { %>
      <div class="error-msg">⚠️ <%= erro %></div>
    <% } %>

    <% if (sucesso != null && !sucesso.isEmpty()) { %>
      <div class="success-msg">✅ <%= sucesso %></div>
    <% } %>

    <%-- ② FORM que envia para o UsuarioController via POST --%>
    <form id="formCadastro" action="<%= request.getContextPath() %>/UsuarioController" method="post">
      <input type="hidden" name="action" value="cadastrar">

      <div class="field">
        <label>Como você quer participar? <span class="req">*</span></label>
        <%-- name="role" — UsuarioController lerá com getParameter("role") --%>
        <input type="hidden" name="role" id="addRole" value="">
        <div class="role-group">
          <button type="button" class="role-option" id="roleAutor" onclick="selecionarRole('author')">
            <span class="role-option-icon">✍️</span>
            <span class="role-option-title">Autor</span>
            <span class="role-option-desc">Publica receitas e artigos</span>
          </button>
          <button type="button" class="role-option" id="roleVisitante" onclick="selecionarRole('viewer')">
            <span class="role-option-icon">👀</span>
            <span class="role-option-title">Visitante</span>
            <span class="role-option-desc">Lê, curte e comenta</span>
          </button>
        </div>
        <div class="field-error" id="errRole">Escolha como você quer participar</div>
      </div>

      <div class="field">
        <label>Nome completo <span class="req">*</span></label>
        <%-- name="nome" — UsuarioController lerá com getParameter("nome") --%>
        <input type="text" name="nome" id="addNome" placeholder="Ex: Ana Beatriz" autocomplete="name"
               oninput="validarNomeLive()">
        <div class="field-error" id="errNome">Digite o nome completo</div>
      </div>

      <div class="field">
        <label>E-mail <span class="req">*</span></label>
        <input type="email" name="email" id="addEmail" placeholder="usuario@saborarte.com.br" autocomplete="email"
               pattern="[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"
               title="Digite um e-mail válido"
               oninput="validarEmailLive()">
        <div class="field-hint">Será usado para login e notificações</div>
        <div class="field-error" id="errEmail">Digite um e-mail válido (ex: usuario@dominio.com)</div>
      </div>

      <div class="form-row">
        <div class="field">
          <label>Senha <span class="req">*</span></label>
          <div class="pw-wrap">
            <input type="password" name="senha" id="addSenha" placeholder="Mín. 8 caracteres" autocomplete="new-password"
                   oninput="validarSenhaLive(); updateStrength(this.value, 'add')">
            <button type="button" class="pw-eye" onclick="togglePw('addSenha')">👁</button>
          </div>
          <div class="pw-strength">
            <div class="pw-strength-bars">
              <div class="pw-bar" id="add-pwb1"></div>
              <div class="pw-bar" id="add-pwb2"></div>
              <div class="pw-bar" id="add-pwb3"></div>
              <div class="pw-bar" id="add-pwb4"></div>
            </div>
            <span class="pw-strength-label" id="add-pw-label" style="color:var(--text-light)">Digite uma senha</span>
          </div>
          <div class="field-error" id="errSenhaCurta">A senha precisa ter no mínimo 8 caracteres</div>
        </div>
        <div class="field">
          <label>Confirmar senha <span class="req">*</span></label>
          <%-- Confirmação só é validada no JS; não precisa de name --%>
          <div class="pw-wrap">
            <input type="password" id="addConfirm" placeholder="Repita a senha" autocomplete="new-password"
                   oninput="validarSenhaLive()">
            <button type="button" class="pw-eye" onclick="togglePw('addConfirm')">👁</button>
          </div>
          <div class="field-error" id="errSenha">As senhas não coincidem</div>
        </div>
      </div>

      <button type="button" class="btn-signup" onclick="doRegister()">
        ✚ Criar conta
      </button>
    </form>

    <div class="divider">
      <div class="divider-line"></div>
      <span class="divider-text">Já tem conta?</span>
      <div class="divider-line"></div>
    </div>

    <a class="btn-login-link" href="<%= request.getContextPath() %>/login.jsp">
      ← Entrar
    </a>

    <div class="version-tag">
      <span>Sabor &amp; Arte v1.0 · </span><strong>Painel Editorial</strong>
    </div>
  </div>
</div>

<script>
  var contextPath = "<%= request.getContextPath() %>";

  function togglePw(id) {
    var i = document.getElementById(id);
    i.type = i.type === 'password' ? 'text' : 'password';
  }

  /* ── Medidor de força de senha (mesmo critério do login/modal originais) ── */
  function updateStrength(v, prefixo) {
    var s = 0;
    if (v.length >= 8) s++;
    if (/[A-Z]/.test(v)) s++;
    if (/[0-9]/.test(v)) s++;
    if (/[^A-Za-z0-9]/.test(v)) s++;

    var cls = ['', 'active-1', 'active-2', 'active-3', 'active-4'];
    var lbs = ['', 'Fraca', 'Média', 'Boa', 'Forte'];
    var tc  = ['var(--text-light)', 'var(--danger)', 'var(--pending)', 'var(--gold)', 'var(--published)'];

    [1, 2, 3, 4].forEach(function(i) {
      var el = document.getElementById(prefixo + '-pwb' + i);
      if (el) el.className = 'pw-bar' + (i <= s ? ' ' + cls[s] : '');
    });

    var label = document.getElementById(prefixo + '-pw-label');
    if (label) {
      label.textContent = v.length === 0 ? 'Digite uma senha' : lbs[s];
      label.style.color = v.length === 0 ? 'var(--text-light)' : tc[s];
    }
  }

  function selecionarRole(role) {
    document.getElementById('addRole').value = role;
    document.getElementById('roleAutor').classList.toggle('selected', role === 'author');
    document.getElementById('roleVisitante').classList.toggle('selected', role === 'viewer');
    var errRole = document.getElementById('errRole');
    if (errRole) errRole.classList.remove('show');
  }

  /* ── Validações ao vivo, iguais ao formulário original ── */
  function validarNomeLive() {
    var nome = document.getElementById('addNome').value.trim();
    var err  = document.getElementById('errNome');
    var ok   = nome.length >= 2;
    err.classList.toggle('show', nome.length > 0 && !ok);
    return ok;
  }

  function validarEmailLive() {
    var email = document.getElementById('addEmail').value.trim();
    var err   = document.getElementById('errEmail');
    var emailRegex = /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$/;
    var ok = emailRegex.test(email);
    err.classList.toggle('show', email.length > 0 && !ok);
    return ok;
  }

  function validarSenhaLive() {
    var s1 = document.getElementById('addSenha').value;
    var s2 = document.getElementById('addConfirm').value;
    var errCurta = document.getElementById('errSenhaCurta');
    var errMatch = document.getElementById('errSenha');

    var senhaOk = s1.length >= 8;
    errCurta.classList.toggle('show', s1.length > 0 && !senhaOk);

    errMatch.classList.toggle('show', s2.length > 0 && s1 !== s2);

    return senhaOk && (s2.length > 0 && s1 === s2);
  }

  function doRegister() {
    var role = document.getElementById('addRole').value;

    var nomeOk  = validarNomeLive();
    var emailOk = validarEmailLive();
    var senhaOk = validarSenhaLive();

    var errRole = document.getElementById('errRole');
    errRole.classList.toggle('show', !role);

    if (!role) {
      document.getElementById('roleAutor').focus();
      return;
    }
    if (!nomeOk) {
      document.getElementById('addNome').focus();
      return;
    }
    if (!emailOk) {
      document.getElementById('addEmail').focus();
      return;
    }
    if (!senhaOk) {
      document.getElementById('addSenha').focus();
      return;
    }

    // Tudo ok — envia o form para o UsuarioController
    document.getElementById('formCadastro').submit();
  }
</script>
</body>
</html>
