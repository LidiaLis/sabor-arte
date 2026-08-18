<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8"%>
<%
    // Guarda o fluxo: só chega aqui quem já pediu o código em esqueci-senha.jsp
    // (o Controller grava "recuperacaoIdUsuario" na sessão em enviarCodigo()).
    // Sem isso, dá pra abrir esta tela direto e tentar validar código de outra
    // conta - por isso a checagem no servidor, e não só no HTML.
    if (session.getAttribute("recuperacaoIdUsuario") == null) {
        response.sendRedirect(request.getContextPath() + "/pages/esqueci-senha.jsp");
        return;
    }

    String emailSessao = (String) session.getAttribute("recuperacaoEmail");
    if (emailSessao == null) {
        emailSessao = "seu e-mail";
    }
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp Arte — Verificar código</title>
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
  .card-subtitle strong { color: var(--text-mid); font-weight: 500; }

  .card-body { padding: 36px 48px 44px; display: flex; flex-direction: column; flex: 1; }

  .form-group { margin-bottom: 22px; animation: fadeUp 0.6s 0.34s both; }

  .form-label { display: block; font-size: 11px; font-weight: 500; color: var(--text-mid); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; text-align: center; }

  /* ── INPUT DE CÓDIGO (6 dígitos) ── */
  .code-inputs { display: flex; gap: 10px; justify-content: center; margin-bottom: 8px; }
  .code-box {
    width: 48px; height: 56px;
    border: 1.5px solid var(--cream-dark); border-radius: 2px;
    background: var(--cream);
    font-family: 'DM Sans', sans-serif; font-size: 22px; font-weight: 500; text-align: center;
    color: var(--text-dark); outline: none;
    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
  }
  .code-box:focus { border-color: var(--moss); background: var(--warm-white); box-shadow: 0 0 0 3px rgba(74,94,58,0.1); }

  .resend-row { text-align: center; margin-bottom: 28px; animation: fadeUp 0.6s 0.4s both; min-height: 18px; }
  .resend-text { font-size: 13px; color: var(--text-light); }
  .resend-link { font-size: 13px; color: var(--moss-light); text-decoration: none; font-weight: 500; background: none; border: none; cursor: pointer; font-family: 'DM Sans', sans-serif; padding: 0; }
  .resend-link:hover { color: var(--moss-dark); text-decoration: underline; }
  .resend-link:disabled { color: var(--text-light); cursor: default; text-decoration: none; }
  .resend-timer { font-size: 13px; color: var(--text-light); font-weight: 500; }

  .btn-login {
    width: 100%; padding: 15px; background: var(--moss); color: var(--cream);
    border: none; border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 500; letter-spacing: 0.5px;
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    animation: fadeUp 0.6s 0.46s both; position: relative; overflow: hidden;
    transition: background 0.25s, transform 0.15s, box-shadow 0.25s;
  }
  .btn-login::before { content: ''; position: absolute; inset: 0; background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, transparent 50%); }
  .btn-login:hover { background: var(--moss-dark); transform: translateY(-1px); box-shadow: 0 8px 24px rgba(47,61,37,0.4); }
  .btn-login:active { transform: translateY(0); }
  .btn-login .btn-arrow { font-size: 18px; transition: transform 0.2s; }
  .btn-login:hover .btn-arrow { transform: translateX(3px); }
  .btn-login:disabled { opacity: 0.7; cursor: default; }

  .divider { display: flex; align-items: center; gap: 14px; margin: 24px 0; animation: fadeUp 0.6s 0.5s both; }
  .divider-line { flex: 1; height: 1px; background: var(--cream-dark); }
  .divider-text { font-size: 11px; color: var(--text-light); text-transform: uppercase; letter-spacing: 1px; }

  .btn-voltar {
    width: 100%; padding: 14px; background: transparent;
    border: 1.5px solid var(--sage); border-radius: 2px;
    font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 500; color: var(--moss);
    cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px;
    text-decoration: none;
    animation: fadeUp 0.6s 0.54s both; transition: background 0.2s, border-color 0.2s;
  }
  .btn-voltar:hover { background: rgba(74,94,58,0.06); border-color: var(--moss-light); }

  .version-tag { text-align: center; margin-top: auto; padding-top: 20px; animation: fadeUp 0.6s 0.6s both; }
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
    .code-box { width: 42px; height: 50px; font-size: 20px; }
  }
</style>
</head>
<body>

<div class="bg-leaf bg-leaf-1"></div>
<div class="bg-leaf bg-leaf-2"></div>
<div class="bg-grid"></div>

<!-- ── VERIFICAR CÓDIGO CARD ── -->
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
    <div class="card-title">Verifique seu <em>e-mail</em></div>
    <div class="card-subtitle">Enviamos um código de 6 dígitos para <strong id="emailDestino"><%= emailSessao %></strong>. Digite abaixo para continuar.</div>
  </div>

  <div class="card-body">

    <div class="error-msg" id="errMsg" style="display:none;"></div>
    <div class="success-msg" id="sucMsg" style="display:none;"></div>

    <form id="formCodigo" action="#" method="post">

      <div class="form-group">
        <label class="form-label">Código de verificação</label>
        <div class="code-inputs">
          <input type="text" class="code-box" name="codigo1" maxlength="1" inputmode="numeric" autofocus>
          <input type="text" class="code-box" name="codigo2" maxlength="1" inputmode="numeric">
          <input type="text" class="code-box" name="codigo3" maxlength="1" inputmode="numeric">
          <input type="text" class="code-box" name="codigo4" maxlength="1" inputmode="numeric">
          <input type="text" class="code-box" name="codigo5" maxlength="1" inputmode="numeric">
          <input type="text" class="code-box" name="codigo6" maxlength="1" inputmode="numeric">
        </div>
      </div>

      <!-- ── TEMPORIZADOR / REENVIO ── -->
      <div class="resend-row" id="resendRow">
        <span class="resend-timer" id="resendTimer">Reenviar código em 4:59</span>
        <span id="resendLinkWrap" style="display:none;">
          <span class="resend-text">Não recebeu? </span><button type="button" class="resend-link" id="btnReenviar">Reenviar código</button>
        </span>
      </div>

      <button type="submit" class="btn-login" id="btnVerificar">
        Verificar código <span class="btn-arrow">→</span>
      </button>

    </form>

    <div class="divider">
      <div class="divider-line"></div>
      <span class="divider-text">Errou o e-mail?</span>
      <div class="divider-line"></div>
    </div>

    <a class="btn-voltar" href="${pageContext.request.contextPath}/pages/esqueci-senha.jsp">
      ← Voltar e digitar outro e-mail
    </a>

    <div class="version-tag">
      <span>Sabor &amp; Arte v1.0 · </span><strong>Painel Editorial</strong>
    </div>
  </div>
</div>

<script>
  var contextPath = '<%= request.getContextPath() %>';

  // Navegação automática entre as caixas do código
  var boxes = document.querySelectorAll('.code-box');
  boxes.forEach(function(box, index) {
    box.addEventListener('input', function() {
      box.value = box.value.replace(/[^0-9]/g, '');
      if (box.value.length === 1 && index < boxes.length - 1) {
        boxes[index + 1].focus();
      }
    });
    box.addEventListener('keydown', function(e) {
      if (e.key === 'Backspace' && box.value === '' && index > 0) {
        boxes[index - 1].focus();
      }
    });
  });

  // ── LÓGICA DO CRONÔMETRO E REENVIO ──
  var TEMPO_INICIAL = 299; // segundos
  var segundosRestantes = TEMPO_INICIAL;
  var intervaloId = null;

  var timerEl      = document.getElementById('resendTimer');
  var linkWrapEl   = document.getElementById('resendLinkWrap');
  var btnReenviarEl = document.getElementById('btnReenviar');

  var errMsg = document.getElementById('errMsg');
  var sucMsg = document.getElementById('sucMsg');

  function formatarTempo(s) {
    var min = Math.floor(s / 60);
    var seg = s % 60;
    return String(min).padStart(2, '0') + ':' + String(seg).padStart(2, '0');
  }

  function iniciarCronometro() {
    segundosRestantes = TEMPO_INICIAL;
    timerEl.textContent = 'Reenviar código em ' + formatarTempo(segundosRestantes);
    timerEl.style.display = 'inline';
    linkWrapEl.style.display = 'none';

    clearInterval(intervaloId);
    intervaloId = setInterval(function () {
      segundosRestantes--;

      if (segundosRestantes <= 0) {
        clearInterval(intervaloId);
        timerEl.style.display = 'none';
        linkWrapEl.style.display = 'inline';
      } else {
        timerEl.textContent = 'Reenviar código em ' + formatarTempo(segundosRestantes);
      }
    }, 1000);
  }

  btnReenviarEl.addEventListener('click', function () {
    errMsg.style.display = 'none';
    btnReenviarEl.disabled = true;

    fetch(contextPath + '/RecuperacaoSenhaController', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=reenviarCodigo'
    })
    .then(function(resp) {
      return resp.text().then(function(texto) {
        return { ok: resp.ok, texto: texto };
      });
    })
    .then(function(res) {
      btnReenviarEl.disabled = false;

      if (!res.ok) {
        errMsg.textContent = '⚠️ ' + res.texto;
        errMsg.style.display = 'block';
        return;
      }

      sucMsg.textContent = '✅ Enviamos um novo código para <%= emailSessao %>.';
      sucMsg.style.display = 'block';

      boxes.forEach(function (box) { box.value = ''; });
      boxes[0].focus();

      iniciarCronometro();
    })
    .catch(function() {
      btnReenviarEl.disabled = false;
      errMsg.textContent = '⚠️ Não foi possível conectar ao servidor. Tente novamente.';
      errMsg.style.display = 'block';
    });
  });

  // Inicia o cronômetro assim que a tela carrega
  iniciarCronometro();

  var form = document.getElementById('formCodigo');
  var btn  = document.getElementById('btnVerificar');

  form.addEventListener('submit', function(e) {
    e.preventDefault();
    errMsg.style.display = 'none';
    sucMsg.style.display = 'none';

    var codigo = '';
    boxes.forEach(function(box) { codigo += box.value; });

    if (codigo.length < 6) {
      errMsg.textContent = '⚠️ Preencha os 6 dígitos do código.';
      errMsg.style.display = 'block';
      return;
    }

    btn.disabled = true;

    fetch(contextPath + '/RecuperacaoSenhaController', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=verificarCodigo&codigo=' + encodeURIComponent(codigo)
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

      sucMsg.textContent = '✅ Código verificado com sucesso.';
      sucMsg.style.display = 'block';

      btn.style.cursor = 'default';
      btn.innerHTML = 'Redirecionando…';

      setTimeout(function() {
        window.location.href = contextPath + '/pages/nova-senha.jsp';
      }, 1400);
    })
    .catch(function() {
      errMsg.textContent = '⚠️ Não foi possível conectar ao servidor. Tente novamente.';
      errMsg.style.display = 'block';
      btn.disabled = false;
    });
  });
</script>
</body>
</html>
