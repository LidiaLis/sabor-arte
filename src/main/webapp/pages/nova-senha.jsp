<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8"%>
<%
    // Guarda o fluxo: só chega aqui quem já teve o código validado em
    // verificar-codigo.jsp (Controller grava "recuperacaoValidado=true" na
    // sessão em verificarCodigo()). Sem isso, dá pra abrir esta tela direto
    // e trocar a senha de outra pessoa sem nunca ter provado o e-mail.
    Object idUsuario = session.getAttribute("recuperacaoIdUsuario");
    Boolean validado = (Boolean) session.getAttribute("recuperacaoValidado");

    if (idUsuario == null || validado == null || !validado) {
        response.sendRedirect(request.getContextPath() + "/pages/esqueci-senha.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp Arte — Nova senha</title>
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

  .card-title { font-family: 'Playfair Display', serif; font-size: 28px; font-weight: 500; color: var(--text-dark); line-height: 1.2; animation: fadeUp 0.6s 0.22s both; }
  .card-title em { font-style: italic; color: var(--moss); }
  .card-subtitle { font-size: 14px; color: var(--text-light); margin-top: 8px; font-weight: 300; line-height: 1.5; animation: fadeUp 0.6s 0.28s both; }

  .card-body { padding: 36px 48px 44px; display: flex; flex-direction: column; flex: 1; }

  .form-group { margin-bottom: 22px; animation: fadeUp 0.6s both; }
  .form-group:nth-child(1) { animation-delay: 0.32s; }
  .form-group:nth-child(2) { animation-delay: 0.38s; }

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

  /* ── FORÇA DA SENHA ── */
  .strength-row { display: flex; gap: 6px; margin-top: 10px; margin-bottom: 6px; }
  .strength-bar { flex: 1; height: 4px; border-radius: 2px; background: var(--cream-dark); }
  .strength-bar.filled-weak   { background: var(--error); }
  .strength-bar.filled-medium { background: var(--gold); }
  .strength-bar.filled-good   { background: var(--sage); }
  .strength-bar.filled-strong { background: var(--moss); }
  .strength-label { font-size: 11px; color: var(--text-light); }
  .strength-label strong { color: var(--text-mid); font-weight: 500; }

  .req-list { list-style: none; margin-top: 12px; display: flex; flex-direction: column; gap: 6px; }
  .req-list li { font-size: 12px; color: var(--text-light); display: flex; align-items: center; gap: 7px; }
  .req-list li .req-icon { font-size: 12px; }
  .req-list li.req-ok { color: var(--moss); }

  .form-footer-note { font-size: 12px; color: var(--text-light); margin-bottom: 24px; animation: fadeUp 0.6s 0.44s both; line-height: 1.5; }

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
  .btn-login:disabled { opacity: 0.7; cursor: default; }

  .version-tag { text-align: center; margin-top: auto; padding-top: 20px; animation: fadeUp 0.6s 0.56s both; }
  .version-tag span { font-size: 11px; color: var(--text-light); font-weight: 300; letter-spacing: 0.5px; }
  .version-tag strong { font-size: 11px; color: var(--moss-light); font-weight: 500; }

  .error-msg { background: rgba(155,68,68,0.08); border: 1px solid rgba(155,68,68,0.25); border-left: 3px solid var(--error); border-radius: 2px; padding: 10px 14px; font-size: 13px; color: var(--error); margin-bottom: 18px; }

  .success-msg {
    background: rgba(74,94,58,0.08);
    border: 1px solid rgba(74,94,58,0.25);
    border-left: 3px solid #4a5e3a;
    border-radius: 2px;
    padding: 10px 14px;
    font-size: 13px;
    color: #2f3d25;
    margin-bottom: 18px;
  }

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

<!-- ── NOVA SENHA CARD ── -->
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
    <div class="card-title">Crie uma <em>nova senha</em></div>
    <div class="card-subtitle">Escolha uma senha forte que você ainda não tenha usado neste site.</div>
  </div>

  <div class="card-body">

    <div class="error-msg" id="errMsg" style="display:none;"></div>
    <div class="success-msg" id="sucMsg" style="display:none;"></div>

    <form id="formNovaSenha" action="#" method="post">

      <div class="form-group">
        <label class="form-label">Nova senha</label>
        <div class="input-wrapper">
          <span class="input-icon">🔒</span>
          <input type="password" class="form-input" id="novaSenha" name="novaSenha" placeholder="Mín. 8 caracteres" autocomplete="new-password" oninput="atualizarForca()" required>
          <button class="toggle-pass" type="button" onclick="toggleSenha('novaSenha', this)" title="Mostrar senha">👁</button>
        </div>

        <div class="strength-row">
          <div class="strength-bar" id="bar1"></div>
          <div class="strength-bar" id="bar2"></div>
          <div class="strength-bar" id="bar3"></div>
          <div class="strength-bar" id="bar4"></div>
        </div>
        <div class="strength-label">Força da senha: <strong id="forcaLabel">—</strong></div>

        <ul class="req-list">
          <li id="reqTamanho"><span class="req-icon">○</span> Mínimo de 8 caracteres</li>
          <li id="reqNumero"><span class="req-icon">○</span> Pelo menos 1 número</li>
          <li id="reqMaiuscula"><span class="req-icon">○</span> Pelo menos 1 letra maiúscula</li>
          <li id="reqEspecial"><span class="req-icon">○</span> Pelo menos 1 caractere especial (!@#$…)</li>
        </ul>
      </div>

      <div class="form-group">
        <label class="form-label">Confirmar nova senha</label>
        <div class="input-wrapper">
          <span class="input-icon">🔒</span>
          <input type="password" class="form-input" id="confirmSenha" name="confirmSenha" placeholder="Repita a senha" autocomplete="new-password" required>
          <button class="toggle-pass" type="button" onclick="toggleSenha('confirmSenha', this)" title="Mostrar senha">👁</button>
        </div>
      </div>

      <div class="form-footer-note">
        Após redefinir, você precisará entrar novamente com a nova senha.
      </div>

      <button type="submit" class="btn-login" id="btnRedefinir">
        Redefinir senha <span class="btn-arrow">→</span>
      </button>

    </form>

    <div class="version-tag">
      <span>Sabor &amp; Arte v1.0 · </span><strong>Painel Editorial</strong>
    </div>
  </div>
</div>

<script>
  var contextPath = '<%= request.getContextPath() %>';

  function toggleSenha(id, btn) {
    var inp = document.getElementById(id);
    inp.type = inp.type === 'password' ? 'text' : 'password';
  }

  // ── Força da senha ──
  function atualizarForca() {
    var v = document.getElementById('novaSenha').value;

    var temTamanho   = v.length >= 8;
    var temNumero    = /[0-9]/.test(v);
    var temMaiuscula = /[A-Z]/.test(v);
    var temEspecial  = /[^A-Za-z0-9]/.test(v);

    var s = 0;
    if (temTamanho)   s++;
    if (temMaiuscula) s++;
    if (temNumero)    s++;
    if (temEspecial)  s++;

    var classes = ['', 'filled-weak', 'filled-medium', 'filled-good', 'filled-strong'];
    var labels  = ['—', 'Fraca', 'Média', 'Boa', 'Forte'];
    var cores   = ['var(--text-light)', 'var(--error)', 'var(--gold)', 'var(--sage)', 'var(--moss)'];

    for (var i = 1; i <= 4; i++) {
      var bar = document.getElementById('bar' + i);
      bar.className = 'strength-bar' + (i <= s ? ' ' + classes[s] : '');
    }

    var label = document.getElementById('forcaLabel');
    label.textContent = v.length === 0 ? '—' : labels[s];
    label.style.color = v.length === 0 ? 'var(--text-light)' : cores[s];

    marcarRequisito('reqTamanho', temTamanho);
    marcarRequisito('reqNumero', temNumero);
    marcarRequisito('reqMaiuscula', temMaiuscula);
    marcarRequisito('reqEspecial', temEspecial);
  }

  function marcarRequisito(id, ok) {
    var li   = document.getElementById(id);
    var icon = li.querySelector('.req-icon');
    li.classList.toggle('req-ok', ok);
    icon.textContent = ok ? '✓' : '○';
  }

  // ── Envio do formulário ──
  var form   = document.getElementById('formNovaSenha');
  var errMsg = document.getElementById('errMsg');
  var sucMsg = document.getElementById('sucMsg');
  var btn    = document.getElementById('btnRedefinir');

  form.addEventListener('submit', function(e) {
    e.preventDefault();
    errMsg.style.display = 'none';
    sucMsg.style.display = 'none';

    var senha   = document.getElementById('novaSenha').value;
    var confirm = document.getElementById('confirmSenha').value;

    if (senha.length < 8) {
      errMsg.textContent = '⚠️ A senha deve ter no mínimo 8 caracteres.';
      errMsg.style.display = 'block';
      return;
    }

    if (senha !== confirm) {
      errMsg.textContent = '⚠️ As senhas não coincidem.';
      errMsg.style.display = 'block';
      return;
    }

    btn.disabled = true;

    fetch(contextPath + '/RecuperacaoSenhaController', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=redefinirSenha'
        + '&novaSenha=' + encodeURIComponent(senha)
        + '&confirmSenha=' + encodeURIComponent(confirm)
    })
    .then(function(resp) {
      return resp.text().then(function(texto) {
        return { ok: resp.ok, texto: texto };
      });
    })
    .then(function(res) {
      if (!res.ok) {
        errMsg.textContent = '⚠️ ' + res.texto;
        errMsg.style.display = 'block';
        btn.disabled = false;
        return;
      }

      sucMsg.textContent = '✅ Senha redefinida com sucesso. Você já pode entrar.';
      sucMsg.style.display = 'block';

      btn.style.cursor = 'default';
      btn.innerHTML = 'Redirecionando…';

      setTimeout(function() {
        window.location.href = contextPath + '/LoginController';
      }, 1600);
    })
    .catch(function() {
      errMsg.textContent = '⚠️ Não foi possível conectar ao servidor. Tente novamente.';
      errMsg.style.display = 'block';
      btn.disabled = false;
    });
  });

  // Inicializa o estado da barra ao carregar
  atualizarForca();
</script>
</body>
</html>
