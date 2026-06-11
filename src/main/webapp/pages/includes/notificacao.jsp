<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%
    Usuario _usuarioNotif = (Usuario) session.getAttribute("usuarioLogado");
    String  _ctxNotif     = request.getContextPath();
%>

<%-- ============================================================
     COMPONENTE: notifications.jsp
     Uso: <%@ include file="/WEB-INF/components/notifications.jsp" %>
     Coloque este include logo após o include do sidebar,
     dentro do <body>, antes de fechar o </body>.

     O botão sino que abre o painel deve ter:
         onclick="NotifPanel.toggle()"
     e o badge de contagem:
         id="notifBadge"
     ============================================================ --%>

<!-- ===== BACKDROP (fecha ao clicar fora) ===== -->
<div class="notif-backdrop" id="notifBackdrop" onclick="NotifPanel.close()"></div>

<!-- ===== PAINEL PRINCIPAL ===== -->
<aside class="notif-panel" id="notifPanel" aria-label="Painel de notificações" aria-hidden="true">

    <!-- Cabeçalho -->
    <div class="notif-panel-header">
        <div class="notif-panel-title">
            🔔 Notificações
            <span class="notif-count-pill" id="notifCountPill">0</span>
        </div>
        <div class="notif-header-actions">
            <span class="notif-link" onclick="NotifPanel.markAllRead()">Marcar todas como lidas</span>
            <button class="notif-close-btn" onclick="NotifPanel.close()" aria-label="Fechar notificações">✕</button>
        </div>
    </div>

    <!-- Abas -->
    <div class="notif-tabs" role="tablist">
        <button class="notif-tab active" role="tab" onclick="NotifPanel.switchTab(this,'all')">Todas</button>
        <button class="notif-tab" role="tab" onclick="NotifPanel.switchTab(this,'unread')">Não lidas</button>
        <button class="notif-tab" role="tab" onclick="NotifPanel.switchTab(this,'system')">Sistema</button>
    </div>

    <!-- Lista de notificações -->
    <div class="notif-list" id="notifList" role="list">

        <!-- Estado de carregamento -->
        <div class="notif-loading" id="notifLoading">
            <div class="notif-spinner"></div>
            <span>Carregando notificações…</span>
        </div>

        <!-- Estado vazio (oculto por padrão) -->
        <div class="notif-empty" id="notifEmpty" style="display:none;">
            <span class="notif-empty-icon">🎉</span>
            <div class="notif-empty-title">Tudo em dia!</div>
            <div class="notif-empty-sub">Você não tem notificações pendentes.</div>
        </div>

        <!-- Os itens são injetados via JS (NotifPanel.render) -->

    </div>

    <!-- Rodapé -->
    <div class="notif-panel-footer">
        <a href="<%= _ctxNotif %>/NotificacaoController" class="notif-see-all">
            Ver todas as notificações →
        </a>
    </div>

</aside>

<!-- ===== PAINEL DE DETALHE (slide sobre o painel principal) ===== -->
<div class="notif-detail-panel" id="notifDetailPanel" aria-hidden="true">

    <div class="notif-detail-header">
        <button class="notif-detail-back" onclick="NotifPanel.closeDetail()">← Voltar</button>
        <span class="notif-detail-title" id="notifDetailTitle">Detalhe</span>
        <button class="notif-close-btn" onclick="NotifPanel.close()" aria-label="Fechar">✕</button>
    </div>

    <div class="notif-detail-body" id="notifDetailBody">
        <!-- Conteúdo injetado dinamicamente por NotifPanel.openDetail(item) -->
    </div>

    <div class="notif-detail-footer" id="notifDetailFooter">
        <!-- Ações injetadas dinamicamente -->
    </div>

</div>

<!-- ===== ESTILOS ===== -->
<style>
/* ---------- variáveis locais (herdadas do tema global se existir) ---------- */
.notif-panel, .notif-detail-panel, .notif-backdrop {
    --np-bg:          #ffffff;
    --np-border:      #e8e8e8;
    --np-text:        #1a1a2e;
    --np-muted:       #6b7280;
    --np-hover:       #f9fafb;
    --np-unread-bg:   #f0f7ff;
    --np-unread-bar:  #3498db;
    --np-accent:      #3498db;
    --np-accent-dark: #2176ae;
    --np-pill-bg:     #3498db;
    --np-pill-text:   #ffffff;
    --np-radius:      10px;
    --np-w:           380px;
    --np-shadow:      0 8px 32px rgba(0,0,0,0.14), 0 2px 8px rgba(0,0,0,0.08);
}

/* tema escuro — herda data-tema do body (igual ao sidebar) */
[data-tema="dark"] .notif-panel,
[data-tema="dark"] .notif-detail-panel {
    --np-bg:        #1e2030;
    --np-border:    #2e3250;
    --np-text:      #e8eaf6;
    --np-muted:     #9094b0;
    --np-hover:     #252840;
    --np-unread-bg: #1a2a3a;
}

/* ---------- backdrop ---------- */
.notif-backdrop {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.35);
    z-index: 1100;
    backdrop-filter: blur(2px);
    animation: notifFadeIn .2s ease;
}
.notif-backdrop.active { display: block; }

/* ---------- painel principal ---------- */
.notif-panel {
    position: fixed;
    top: 0;
    right: 0;
    width: var(--np-w);
    height: 100vh;
    background: var(--np-bg);
    border-left: 1px solid var(--np-border);
    box-shadow: var(--np-shadow);
    z-index: 1200;
    display: flex;
    flex-direction: column;
    transform: translateX(100%);
    transition: transform .28s cubic-bezier(.25,.46,.45,.94);
    font-family: inherit;
}
.notif-panel.active {
    transform: translateX(0);
}

/* ---------- cabeçalho ---------- */
.notif-panel-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 20px 14px;
    border-bottom: 1px solid var(--np-border);
    flex-shrink: 0;
}
.notif-panel-title {
    font-size: 15px;
    font-weight: 700;
    color: var(--np-text);
    display: flex;
    align-items: center;
    gap: 8px;
}
.notif-count-pill {
    background: var(--np-pill-bg);
    color: var(--np-pill-text);
    font-size: 10px;
    font-weight: 700;
    padding: 2px 8px;
    border-radius: 20px;
    min-width: 20px;
    text-align: center;
}
.notif-header-actions {
    display: flex;
    align-items: center;
    gap: 12px;
}
.notif-link {
    font-size: 11px;
    color: var(--np-accent);
    cursor: pointer;
    font-weight: 500;
    white-space: nowrap;
    transition: color .15s;
}
.notif-link:hover { color: var(--np-accent-dark); }
.notif-close-btn {
    width: 28px;
    height: 28px;
    border: 1px solid var(--np-border);
    background: transparent;
    border-radius: 6px;
    cursor: pointer;
    font-size: 12px;
    color: var(--np-muted);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all .15s;
    flex-shrink: 0;
}
.notif-close-btn:hover {
    background: var(--np-hover);
    color: var(--np-text);
}

/* ---------- abas ---------- */
.notif-tabs {
    display: flex;
    border-bottom: 1px solid var(--np-border);
    flex-shrink: 0;
}
.notif-tab {
    flex: 1;
    padding: 10px 0;
    font-size: 12px;
    font-weight: 500;
    color: var(--np-muted);
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
    cursor: pointer;
    transition: all .18s;
    font-family: inherit;
}
.notif-tab:hover:not(.active) { color: var(--np-text); }
.notif-tab.active {
    color: var(--np-accent);
    border-bottom-color: var(--np-accent);
    font-weight: 600;
}

/* ---------- lista ---------- */
.notif-list {
    flex: 1;
    overflow-y: auto;
    padding: 4px 0;
}
.notif-list::-webkit-scrollbar { width: 4px; }
.notif-list::-webkit-scrollbar-track { background: transparent; }
.notif-list::-webkit-scrollbar-thumb { background: var(--np-border); border-radius: 2px; }

/* ---------- item ---------- */
.notif-item {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    padding: 13px 18px;
    border-bottom: 1px solid var(--np-border);
    cursor: pointer;
    transition: background .15s;
    position: relative;
    list-style: none;
}
.notif-item:hover { background: var(--np-hover); }
.notif-item.unread { background: var(--np-unread-bg); }
.notif-item.unread::before {
    content: '';
    position: absolute;
    left: 0; top: 0; bottom: 0;
    width: 3px;
    background: var(--np-unread-bar);
    border-radius: 0 2px 2px 0;
}

.notif-item-icon {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    flex-shrink: 0;
    margin-top: 1px;
}
.notif-item-icon.tipo-comentario  { background: rgba(52,152,219,.12); }
.notif-item-icon.tipo-curtida     { background: rgba(231,76,60,.1);   }
.notif-item-icon.tipo-aprovacao   { background: rgba(46,204,113,.1);  }
.notif-item-icon.tipo-seguidor    { background: rgba(155,89,182,.1);  }
.notif-item-icon.tipo-sistema     { background: rgba(243,156,18,.12); }
.notif-item-icon.tipo-devolucao   { background: rgba(52,152,219,.12); }
.notif-item-icon.tipo-atraso      { background: rgba(231,76,60,.1);   }

.notif-item-body { flex: 1; min-width: 0; }
.notif-item-msg  { font-size: 13px; color: var(--np-text); line-height: 1.45; margin-bottom: 3px; }
.notif-item-msg strong { font-weight: 600; }
.notif-item-time { font-size: 11px; color: var(--np-muted); }

/* ---------- estados especiais ---------- */
.notif-loading, .notif-empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 10px;
    padding: 48px 24px;
    color: var(--np-muted);
    font-size: 13px;
}
.notif-empty-icon { font-size: 36px; }
.notif-empty-title { font-size: 15px; font-weight: 600; color: var(--np-text); }
.notif-empty-sub { font-size: 12px; text-align: center; }
.notif-spinner {
    width: 28px; height: 28px;
    border: 3px solid var(--np-border);
    border-top-color: var(--np-accent);
    border-radius: 50%;
    animation: notifSpin .7s linear infinite;
}

/* ---------- rodapé ---------- */
.notif-panel-footer {
    padding: 14px 20px;
    border-top: 1px solid var(--np-border);
    text-align: center;
    flex-shrink: 0;
}
.notif-see-all {
    font-size: 13px;
    font-weight: 600;
    color: var(--np-accent);
    text-decoration: none;
    transition: color .15s;
}
.notif-see-all:hover { color: var(--np-accent-dark); }

/* ---------- painel de detalhe ---------- */
.notif-detail-panel {
    position: fixed;
    top: 0; right: 0;
    width: var(--np-w);
    height: 100vh;
    background: var(--np-bg);
    border-left: 1px solid var(--np-border);
    box-shadow: var(--np-shadow);
    z-index: 1300;
    display: flex;
    flex-direction: column;
    transform: translateX(100%);
    transition: transform .25s cubic-bezier(.25,.46,.45,.94);
}
.notif-detail-panel.active { transform: translateX(0); }

.notif-detail-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 20px;
    border-bottom: 1px solid var(--np-border);
    flex-shrink: 0;
}
.notif-detail-back {
    font-size: 13px;
    color: var(--np-accent);
    font-weight: 500;
    background: none;
    border: none;
    cursor: pointer;
    font-family: inherit;
    transition: color .15s;
}
.notif-detail-back:hover { color: var(--np-accent-dark); }
.notif-detail-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--np-text);
}
.notif-detail-body {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
}
.notif-detail-body::-webkit-scrollbar { width: 4px; }
.notif-detail-body::-webkit-scrollbar-thumb { background: var(--np-border); border-radius: 2px; }

.notif-detail-footer {
    padding: 14px 20px;
    border-top: 1px solid var(--np-border);
    display: flex;
    gap: 8px;
    flex-shrink: 0;
}
.notif-detail-btn {
    flex: 1;
    padding: 9px;
    border-radius: 8px;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    font-family: inherit;
    transition: all .15s;
    border: 1px solid var(--np-border);
    background: transparent;
    color: var(--np-muted);
}
.notif-detail-btn:hover { background: var(--np-hover); color: var(--np-text); }
.notif-detail-btn.primary {
    background: var(--np-accent);
    color: #fff;
    border-color: var(--np-accent);
}
.notif-detail-btn.primary:hover { background: var(--np-accent-dark); }

/* ---------- conteúdo interno do detalhe ---------- */
.nd-type-tag {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    margin-bottom: 14px;
    background: rgba(52,152,219,.1);
    color: var(--np-accent);
}
.nd-actor-row {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
}
.nd-actor-av {
    width: 42px; height: 42px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 16px; font-weight: 700; color: #fff;
    flex-shrink: 0;
}
.nd-actor-name { font-size: 14px; font-weight: 600; color: var(--np-text); }
.nd-actor-sub  { font-size: 11px; color: var(--np-muted); margin-top: 1px; }
.nd-actor-time { font-size: 11px; color: var(--np-muted); margin-left: auto; white-space: nowrap; }

.nd-box {
    background: var(--np-hover);
    border: 1px solid var(--np-border);
    border-radius: var(--np-radius);
    padding: 13px 14px;
    margin-bottom: 14px;
    font-size: 13px;
    color: var(--np-text);
    line-height: 1.6;
}
.nd-box-label {
    font-size: 10px;
    text-transform: uppercase;
    letter-spacing: .8px;
    color: var(--np-muted);
    font-weight: 600;
    margin-bottom: 6px;
}
.nd-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    text-align: center;
}
.nd-stat-val  { font-size: 20px; font-weight: 700; color: var(--np-text); }
.nd-stat-lbl  { font-size: 10px; color: var(--np-muted); margin-top: 2px; }

.nd-reply textarea {
    width: 100%;
    min-height: 80px;
    border: 1px solid var(--np-border);
    border-radius: 8px;
    padding: 10px 12px;
    font-family: inherit;
    font-size: 13px;
    color: var(--np-text);
    background: var(--np-bg);
    resize: none;
    outline: none;
    transition: border-color .2s;
    line-height: 1.6;
}
.nd-reply textarea:focus { border-color: var(--np-accent); }
.nd-reply-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 8px;
}
.nd-reply-char { font-size: 11px; color: var(--np-muted); }
.nd-reply-send {
    padding: 7px 16px;
    background: var(--np-accent);
    color: #fff;
    border: none;
    border-radius: 6px;
    font-family: inherit;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: background .15s;
}
.nd-reply-send:hover { background: var(--np-accent-dark); }

/* ---------- mobile ---------- */
@media (max-width: 480px) {
    .notif-panel, .notif-detail-panel { width: 100vw; }
}

/* ---------- animações ---------- */
@keyframes notifFadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes notifSpin   { to { transform: rotate(360deg); } }
</style>

<!-- ===== JAVASCRIPT ===== -->
<script>
const NotifPanel = (function () {

    /* ---- estado interno ---- */
    let _isOpen        = false;
    let _detailOpen    = false;
    let _currentTab    = 'all';
    let _notifications = [];        /* array de objetos carregados da API */
    let _loaded        = false;     /* lazy load: só busca na primeira abertura */

    const CTX = '<%= _ctxNotif %>';

    /* ---- elementos DOM ---- */
    const panel      = () => document.getElementById('notifPanel');
    const backdrop   = () => document.getElementById('notifBackdrop');
    const list       = () => document.getElementById('notifList');
    const loading    = () => document.getElementById('notifLoading');
    const empty      = () => document.getElementById('notifEmpty');
    const countPill  = () => document.getElementById('notifCountPill');
    const detailPanel= () => document.getElementById('notifDetailPanel');
    const detailBody = () => document.getElementById('notifDetailBody');
    const detailFoot = () => document.getElementById('notifDetailFooter');
    const detailTitle= () => document.getElementById('notifDetailTitle');

    /* ---- badge no sino (elemento fora deste componente) ---- */
    const badge      = () => document.getElementById('notifBadge');

    /* ======================================================
       API pública
       ====================================================== */

    function toggle() {
        _isOpen ? close() : open();
    }

    function open() {
        _isOpen = true;
        panel().classList.add('active');
        panel().setAttribute('aria-hidden', 'false');
        backdrop().classList.add('active');
        document.body.style.overflow = 'hidden';

        if (!_loaded) _fetchNotifications();
    }

    function close() {
        _isOpen = false;
        _detailOpen = false;
        panel().classList.remove('active');
        panel().setAttribute('aria-hidden', 'true');
        backdrop().classList.remove('active');
        detailPanel().classList.remove('active');
        detailPanel().setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    function openDetail(item) {
        /* preenche o painel de detalhe com base no tipo do item */
        detailTitle().textContent = _labelTipo(item.tipo);
        detailBody().innerHTML    = _buildDetailHTML(item);
        detailFoot().innerHTML    = _buildDetailFooter(item);
        detailPanel().classList.add('active');
        detailPanel().setAttribute('aria-hidden', 'false');
        _detailOpen = true;

        /* marca como lida */
        if (item.naoLida) {
            item.naoLida = false;
            _updateBadge();
            _render(_currentTab);
        }
    }

    function closeDetail() {
        _detailOpen = false;
        detailPanel().classList.remove('active');
        detailPanel().setAttribute('aria-hidden', 'true');
    }

    function switchTab(el, tab) {
        document.querySelectorAll('.notif-tab').forEach(t => t.classList.remove('active'));
        el.classList.add('active');
        _currentTab = tab;
        _render(tab);
    }

    function markAllRead() {
        _notifications.forEach(n => n.naoLida = false);
        _updateBadge();
        _render(_currentTab);
    }

    /* ======================================================
       Internos
       ====================================================== */

    /* Busca notificações do servlet (lazy) */
    function _fetchNotifications() {
        loading().style.display = 'flex';
        empty().style.display   = 'none';
        /* remove itens antigos */
        list().querySelectorAll('.notif-item').forEach(el => el.remove());

        fetch(CTX + '/NotificacaoController?action=listar', {
            headers: { 'X-Requested-With': 'XMLHttpRequest' }
        })
        .then(r => r.json())
        .then(data => {
            _loaded = true;
            _notifications = data;
            loading().style.display = 'none';
            _updateBadge();
            _render('all');
        })
        .catch(() => {
            /* fallback com dados de exemplo se a API ainda não existir */
            _loaded = true;
            _notifications = _mockData();
            loading().style.display = 'none';
            _updateBadge();
            _render('all');
        });
    }

    /* Renderiza os itens conforme a aba ativa */
    function _render(tab) {
        list().querySelectorAll('.notif-item').forEach(el => el.remove());

        const filtered = _notifications.filter(n => {
            if (tab === 'unread') return n.naoLida;
            if (tab === 'system') return n.tipo === 'sistema' || n.tipo === 'atraso';
            return true;
        });

        if (filtered.length === 0) {
            empty().style.display = 'flex';
            return;
        }
        empty().style.display = 'none';

        filtered.forEach(item => {
            const el = document.createElement('div');
            el.className = 'notif-item' + (item.naoLida ? ' unread' : '');
            el.setAttribute('role', 'listitem');
            el.innerHTML = `
                <div class="notif-item-icon tipo-${item.tipo}" aria-hidden="true">${_icone(item.tipo)}</div>
                <div class="notif-item-body">
                    <div class="notif-item-msg">${item.mensagem}</div>
                    <div class="notif-item-time">${item.tempo}</div>
                </div>
            `;
            el.addEventListener('click', () => openDetail(item));
            list().appendChild(el);
        });

        _updateCountPill();
    }

    function _updateBadge() {
        const nr = _notifications.filter(n => n.naoLida).length;
        /* badge no botão sino (fora deste componente) */
        const b = badge();
        if (b) {
            b.textContent = nr > 0 ? (nr > 99 ? '99+' : nr) : '';
            b.style.display = nr > 0 ? 'flex' : 'none';
        }
        _updateCountPill();
    }

    function _updateCountPill() {
        const nr = _notifications.filter(n => n.naoLida).length;
        const pill = countPill();
        if (pill) pill.textContent = nr;
    }

    /* ---- helpers de conteúdo ---- */
    function _icone(tipo) {
        const map = {
            comentario: '💬', curtida: '❤️', aprovacao: '✅',
            seguidor: '👤', sistema: '⚙️', devolucao: '📦', atraso: '⚠️'
        };
        return map[tipo] || '🔔';
    }

    function _labelTipo(tipo) {
        const map = {
            comentario: 'Comentário', curtida: 'Curtida', aprovacao: 'Aprovação',
            seguidor: 'Novo Seguidor', sistema: 'Sistema', devolucao: 'Devolução', atraso: 'Atraso'
        };
        return map[tipo] || 'Notificação';
    }

    /* Monta o HTML do detalhe com base no tipo */
    function _buildDetailHTML(item) {
        const tag = `<div class="nd-type-tag">${_icone(item.tipo)} ${_labelTipo(item.tipo)}</div>`;
        const actor = item.ator ? `
            <div class="nd-actor-row">
                <div class="nd-actor-av" style="background:${item.atorCor || '#3498db'}">${(item.ator.charAt(0)||'?').toUpperCase()}</div>
                <div>
                    <div class="nd-actor-name">${item.ator}</div>
                    <div class="nd-actor-sub">${item.atorSub || ''}</div>
                </div>
                <div class="nd-actor-time">${item.tempo}</div>
            </div>` : '';

        const mainBox = `<div class="nd-box">${item.mensagem}</div>`;

        /* campos extras opcionais: item.extra (objeto livre) */
        let extra = '';
        if (item.extra) {
            if (item.extra.tipo === 'stats') {
                extra = `<div class="nd-box">
                    <div class="nd-box-label">Estatísticas</div>
                    <div class="nd-stats">
                        ${item.extra.valores.map(v =>
                            `<div><div class="nd-stat-val">${v.valor}</div><div class="nd-stat-lbl">${v.label}</div></div>`
                        ).join('')}
                    </div>
                </div>`;
            } else if (item.extra.tipo === 'texto') {
                extra = `<div class="nd-box">${item.extra.conteudo}</div>`;
            }
        }

        const reply = (item.tipo === 'comentario') ? `
            <div style="margin-top:4px;">
                <div class="nd-box-label" style="margin-bottom:8px;">Responder</div>
                <div class="nd-reply">
                    <textarea id="ndReplyTA" placeholder="Escreva sua resposta…" maxlength="500"
                              oninput="document.getElementById('ndReplyChar').textContent=this.value.length+' / 500'"></textarea>
                    <div class="nd-reply-actions">
                        <span class="nd-reply-char" id="ndReplyChar">0 / 500</span>
                        <button class="nd-reply-send" onclick="NotifPanel._sendReply(${item.id})">Enviar</button>
                    </div>
                </div>
            </div>` : '';

        return tag + actor + mainBox + extra + reply;
    }

    function _buildDetailFooter(item) {
        const btns = {
            comentario: `<button class="notif-detail-btn">🚩 Reportar</button>
                         <button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/LivroController?id=${item.refId||''}'">Ver registro</button>`,
            curtida:    `<button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/LivroController?id=${item.refId||''}'">Ver registro</button>`,
            aprovacao:  `<button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/MovimentacaoController?id=${item.refId||''}'">Ver movimentação</button>`,
            seguidor:   `<button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/UsuarioController?id=${item.refId||''}'">Ver perfil</button>`,
            sistema:    `<button class="notif-detail-btn" onclick="NotifPanel.closeDetail()">Dispensar</button>
                         <button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/MovimentacaoController'">Ver pendências</button>`,
            devolucao:  `<button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/MovimentacaoController?id=${item.refId||''}'">Ver devolução</button>`,
            atraso:     `<button class="notif-detail-btn" onclick="NotifPanel.closeDetail()">Dispensar</button>
                         <button class="notif-detail-btn primary" onclick="window.location.href='${CTX}/MovimentacaoController?id=${item.refId||''}'">Regularizar</button>`,
        };
        return btns[item.tipo] || `<button class="notif-detail-btn primary" onclick="NotifPanel.closeDetail()">Fechar</button>`;
    }

    /* Envio de resposta a comentário */
    function _sendReply(itemId) {
        const ta  = document.getElementById('ndReplyTA');
        const txt = ta ? ta.value.trim() : '';
        if (!txt) return;

        fetch(CTX + '/NotificacaoController?action=responder', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' },
            body: 'id=' + encodeURIComponent(itemId) + '&resposta=' + encodeURIComponent(txt)
        })
        .then(() => {
            const btn = document.querySelector('.nd-reply-send');
            if (btn) { btn.textContent = '✅ Enviado!'; btn.disabled = true; }
            if (ta) ta.value = '';
        })
        .catch(() => alert('Erro ao enviar resposta. Tente novamente.'));
    }

    /* ---- dados de mock (enquanto a API não existe) ---- */
    function _mockData() {
        return [
            { id:1, tipo:'comentario', naoLida:true,  ator:'João Pedro',    atorSub:'Leitor',     atorCor:'#9b59b6', tempo:'há 5 min',   mensagem:'<strong>João Pedro</strong> comentou em <strong>"Dom Casmurro"</strong>: "Obra-prima da literatura brasileira!"', refId:10 },
            { id:2, tipo:'atraso',     naoLida:true,  ator:null,            tempo:'há 20 min',    mensagem:'<strong>3 livros</strong> com devolução atrasada aguardam regularização.' },
            { id:3, tipo:'devolucao',  naoLida:true,  ator:'Ana Lima',      atorSub:'Leitora',    atorCor:'#e67e22', tempo:'há 1h',       mensagem:'<strong>Ana Lima</strong> devolveu <strong>"O Alquimista"</strong>.', refId:22 },
            { id:4, tipo:'aprovacao',  naoLida:false, ator:'Admin Sistema',  atorSub:'Sistema',    atorCor:'#2ecc71', tempo:'há 3h',       mensagem:'Movimentação <strong>#1042</strong> foi aprovada com sucesso.', refId:1042 },
            { id:5, tipo:'sistema',    naoLida:false, ator:null,            tempo:'há 1 dia',     mensagem:'Backup automático realizado com sucesso às 03:00.' },
            { id:6, tipo:'seguidor',   naoLida:false, ator:'Carlos Mendes', atorSub:'Livreiro',   atorCor:'#3498db', tempo:'há 2 dias',   mensagem:'<strong>Carlos Mendes</strong> começou a seguir sua lista de leituras.', refId:55 }
        ];
    }

    /* expõe _sendReply para uso inline no HTML gerado */
    return { toggle, open, close, openDetail, closeDetail, switchTab, markAllRead, _sendReply };

})();
</script>
