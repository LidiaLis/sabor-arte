<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%
    // Se já está logado, redireciona direto
    Usuario usuarioLogado = (Usuario) session.getAttribute("usuarioLogado");
    if (usuarioLogado != null) {
        response.sendRedirect(request.getContextPath() + "/pages/HTML/dashboard.html");
        return;
    }

    // Pega mensagem de erro da sessão (vinda do LoginController)
    String erro = (String) session.getAttribute("erro");
    if (erro != null) {
        session.removeAttribute("erro"); // consome o erro — não repete no reload
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
<title>Sabor &amp Arte — Entrar</title>
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
    overflow: hidden;
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

	.login-card {
	  position: relative; z-index: 1;
	  width: 100%; max-width: 480px; min-height: 750px; margin: 24px;
	  background: var(--warm-white);
	  border-radius: 2px; overflow: hidden;
	  box-shadow: 0 0 0 1px rgba(74,94,58,0.15), 0 40px 80px rgba(0,0,0,0.4), 0 8px 20px rgba(0,0,0,0.2);
	  animation: cardReveal 0.8s cubic-bezier(0.16,1,0.3,1) both;
	  display: flex; flex-direction: column;
	}

  @keyframes cardReveal {
    from { opacity: 0; transform: translateY(32px) scale(0.97); }
    to   { opacity: 1; transform: translateY(0) scale(1); }
  }

  .card-bar { height: 5px; background: linear-gradient(90deg, var(--moss-dark), var(--moss), var(--sage), var(--gold)); }
  .card-header { padding: 44px 48px 36px; background: var(--warm-white); border-bottom: 1px solid var(--cream-dark); }

  .brand-mark { display: flex; align-items: center; gap: 14px; margin-bottom: 28px; animation: fadeUp 0.6s 0.15s both; }
  .brand-icon { width: 44px; height: 44px; background: var(--moss); border-radius: 2px; display: flex; align-items: center; justify-content: center; font-size: 22px; flex-shrink: 0; position: relative; }
  .brand-icon::after { content: ''; position: absolute; inset: 3px; border: 1px solid rgba(255,255,255,0.2); border-radius: 1px; }
  .brand-text { line-height: 1; }
  .brand-name { font-family: 'Playfair Display', serif; font-size: 22px; font-weight: 700; color: var(--moss-dark); letter-spacing: -0.3px; display: block; }
  .brand-tagline { font-size: 11px; color: var(--text-light); text-transform: uppercase; letter-spacing: 1.5px; margin-top: 3px; display: block; }

  .card-title { font-family: 'Playfair Display', serif; font-size: 30px; font-weight: 500; color: var(--text-dark); line-height: 1.2; animation: fadeUp 0.6s 0.22s both; }
  .card-title em { font-style: italic; color: var(--moss); }
  .card-subtitle { font-size: 14px; color: var(--text-light); margin-top: 6px; font-weight: 300; animation: fadeUp 0.6s 0.28s both; }

  .card-body { padding: 36px 48px 44px; display: flex; flex-direction: column; flex: 1; }

  .form-group { margin-bottom: 22px; animation: fadeUp 0.6s both; }
  .form-group:nth-child(2) { animation-delay: 0.32s; }
  .form-group:nth-child(3) { animation-delay: 0.38s; }

  .form-label { display: block; font-size: 11px; font-weight: 500; color: var(--text-mid); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }

  .input-wrapper { position: relative; }
  .input-icon { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); font-size: 15px; opacity: 0.45; pointer-events: none; }

  .form-input {
    width: 100%; padding: 13px 16px 13px 44px;
    border: 1.5px solid var(--cream-dark); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; color: var(--text-dark);
    background: var(--cream); outline: none;
    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
  }
  .form-input:focus { border-color: var(--moss); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }
  .form-input::placeholder { color: var(--text-light); font-weight: 300; }

  .toggle-pass { position: absolute; right: 14px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; font-size: 15px; color: var(--text-light); padding: 4px; transition: color 0.2s; }
  .toggle-pass:hover { color: var(--moss); }

  .form-footer { display: flex; align-items: center; justify-content: space-between; margin-bottom: 28px; animation: fadeUp 0.6s 0.44s both; }
  .remember-label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text-mid); cursor: pointer; user-select: none; }
  .remember-check { width: 16px; height: 16px; cursor: pointer; accent-color: var(--moss); }
  .forgot-link { font-size: 13px; color: var(--moss-light); text-decoration: none; font-weight: 500; transition: color 0.2s; }
  .forgot-link:hover { color: var(--moss-dark); text-decoration: underline; }

  .btn-login {
    width: 100%; padding: 15px; background: var(--moss); color: var(--cream);
    border: none; border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 500; letter-spacing: 0.5px;
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    animation: fadeUp 0.6s 0.5s both; position: relative; overflow: hidden;
    transition: background 0.25s, transform 0.15s, box-shadow 0.25s;
  }
  .btn-login::before { content: ''; position: absolute; inset: 0; background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, transparent 50%); }
  .btn-login:hover { background: var(--moss-dark); transform: translateY(-1px); box-shadow: 0 8px 24px rgba(47,61,37,0.4); }
  .btn-login:active { transform: translateY(0); }
  .btn-login .btn-arrow { font-size: 18px; transition: transform 0.2s; }
  .btn-login:hover .btn-arrow { transform: translateX(3px); }

  .divider { display: flex; align-items: center; gap: 14px; margin: 24px 0; animation: fadeUp 0.6s 0.54s both; }
  .divider-line { flex: 1; height: 1px; background: var(--cream-dark); }
  .divider-text { font-size: 11px; color: var(--text-light); text-transform: uppercase; letter-spacing: 1px; }

  .btn-register { width: 100%; padding: 14px; background: transparent;
    border: 1.5px solid var(--sage); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 500; color: var(--moss);
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    text-decoration: none;
    animation: fadeUp 0.6s 0.57s both; transition: background 0.2s, border-color 0.2s;
  }
  .btn-register:hover { background: rgba(74,94,58,0.06); border-color: var(--moss-light); }

  .version-tag { text-align: center; margin-top: auto; padding-top: 20px; animation: fadeUp 0.6s 0.6s both; }  .version-tag span { font-size: 11px; color: var(--text-light); font-weight: 300; letter-spacing: 0.5px; }
  .version-tag strong { font-size: 11px; color: var(--moss-light); font-weight: 500; }

  .error-msg { background: rgba(155,68,68,0.08); border: 1px solid rgba(155,68,68,0.25); border-left: 3px solid var(--error); border-radius: 2px; padding: 10px 14px; font-size: 13px; color: var(--error); margin-bottom: 18px; }
  .error-msg-hidden { display: none; }
  
  .success-msg {
    background: rgba(74,94,58,0.08);
    border: 1px solid rgba(74,94,58,0.25);
    border-left: 3px solid #4a5e3a;
    border-radius: 2px;
    padding: 10px 14px;
    font-size: 13px;
    color: #2f3d25;
    margin-bottom: 18px;}

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(14px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  @media (max-width: 520px) {
    .card-header, .card-body { padding-left: 28px; padding-right: 28px; }
  }
</style>
</head>
<body>

<div class="bg-leaf bg-leaf-1"></div>
<div class="bg-leaf bg-leaf-2"></div>
<div class="bg-grid"></div>

<!-- ── LOGIN CARD ── -->
<div class="login-card">
  <div class="card-bar"></div>

  <div class="card-header">
    <div class="brand-mark">
      <div class="brand-icon">🌿</div>
      <div class="brand-text">
        <span class="brand-name">Sabor &amp; Arte</span>
        <span class="brand-tagline">Blog Culinário Editorial</span>
      </div>
    </div>
    <div class="card-title">Bem-vindo</div>
    <div class="card-subtitle">Acesse sua conta para continuar</div>
  </div>

  <div class="card-body">

    <%-- ① ERRO VINDO DO SERVIDOR (LoginController) --%>
    <% if (erro != null && !erro.isEmpty()) { %>
      <div class="error-msg">⚠️ <%= erro %></div>
    <% } %>

	<% if (sucesso != null && !sucesso.isEmpty()) { %>
	    <div class="success-msg">✅ <%= sucesso %></div>
	<% } %>
	
    <%-- ② FORM que envia para o LoginController via POST --%>
    <form action="<%= request.getContextPath() %>/LoginController" method="post">

      <div class="form-group">
        <label class="form-label">E-mail</label>
        <div class="input-wrapper">
          <span class="input-icon">✉️</span>
          <%-- name="email" — mesmo nome que o controller lê com getParameter("email") --%>
          <input type="email" class="form-input" name="email" placeholder="seu@email.com" autocomplete="email" required>
        </div>
      </div>

      <div class="form-group">
        <label class="form-label">Senha</label>
        <div class="input-wrapper">
          <span class="input-icon">🔒</span>
          <%-- name="senha" — mesmo nome que o controller lê com getParameter("senha") --%>
          <input type="password" class="form-input" id="passwordField" name="senha" placeholder="••••••••" autocomplete="current-password" required>
          <button class="toggle-pass" type="button" onclick="toggleSenha()" title="Mostrar senha">👁</button>
        </div>
      </div>

	    <div class="form-footer">
			<a href="<%= request.getContextPath() %>/pages/esqueci-senha.jsp" class="forgot-link">Esqueceu a senha?</a>	    </div>

      <button type="submit" class="btn-login">
        Entrar <span class="btn-arrow">→</span>
      </button>

    </form>

    <div class="divider">
      <div class="divider-line"></div>
      <span class="divider-text">Novo por aqui?</span>
      <div class="divider-line"></div>
    </div>

    <a class="btn-register" href="<%= request.getContextPath() %>/pages/cadastro.jsp">
      ✦ Criar minha conta
    </a>

    <div class="version-tag">
      <span>Sabor &amp; Arte v1.0 · </span><strong>Painel Editorial</strong>
    </div>
  </div>
</div>

<script>
  var contextPath = "<%= request.getContextPath() %>";

  function toggleSenha() {
    var inp = document.getElementById('passwordField');
    inp.type = inp.type === 'password' ? 'text' : 'password';
  }
</script>
</body>
</html>
