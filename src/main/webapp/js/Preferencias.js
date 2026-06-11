/**
 * MindRead — Engine Central de Preferências
 * ==========================================
 * Inclua este arquivo (depois de i18n.js) em TODAS as telas:
 *
 *   <script src="${pageContext.request.contextPath}/js/i18n.js"></script>
 *   <script src="${pageContext.request.contextPath}/js/preferencias.js"></script>
 *
 * No <body> de cada JSP injete os dados da sessão:
 *
 *   <body data-tema="<%= usuarioLogado.getTema() %>"
 *         data-idioma="<%= usuarioLogado.getIdioma() %>">
 *
 * Nas telas onde usuarioLogado não está disponível diretamente (ex: login),
 * omita os atributos — o sistema usa 'light' e 'pt-BR' como fallback.
 *
 * Para traduzir um elemento basta adicionar data-i18n="chave":
 *   <span data-i18n="btnSalvar"></span>
 *   <button data-i18n="btnCancelar"></button>
 *   <label data-i18n="labelNome"></label>
 *   <th data-i18n="cfgLogsColData"></th>
 *   <option data-i18n="statusAtivo"></option>
 *   <title data-i18n="usuarioTitle"></title>   ← funciona também
 *
 * Para traduzir placeholder:
 *   <input data-i18n-placeholder="labelBuscar">
 *
 * Para traduzir title (tooltip):
 *   <button data-i18n-title="btnEditar">
 *
 * Para traduzir em JavaScript use a função global t():
 *   showModal('✅', t('msgSucesso'), t('usuarioCadSucesso'));
 *   confirm(t('msgConfirmDelete'));
 */

// Namespace global do MindRead
window.MR = window.MR || {};

(function () {
    'use strict';

    // ─── 1. Lê preferências do <body data-tema data-idioma> ──────────────────
    function lerPreferencias() {
        var body   = document.body;
        var tema   = (body && body.dataset.tema)   || localStorage.getItem('theme')    || 'light';
        var idioma = (body && body.dataset.idioma) || localStorage.getItem('language') || 'pt-BR';

        // Garante valores válidos
        if (!['light','dark','high-contrast'].includes(tema))   tema   = 'light';
        if (!['pt-BR','en'].includes(idioma))                   idioma = 'pt-BR';

        MR.tema   = tema;
        MR.idioma = idioma;
    }

    // ─── 2. Aplica tema via classes no <body> ────────────────────────────────
    function aplicarTema(tema) {
        document.body.classList.remove('dark-mode', 'high-contrast');
        if (tema === 'dark')               document.body.classList.add('dark-mode');
        else if (tema === 'high-contrast') document.body.classList.add('high-contrast');
        MR.tema = tema;
        localStorage.setItem('theme', tema);
    }

    // ─── 3. Aplica traduções em TODOS os elementos data-i18n da página ───────
    function aplicarTraducoes(idioma) {
        idioma = idioma || MR.idioma || 'pt-BR';
        MR.idioma = idioma;
        localStorage.setItem('language', idioma);

        // data-i18n → textContent
        document.querySelectorAll('[data-i18n]').forEach(function (el) {
            var chave = el.getAttribute('data-i18n');
            var texto = t(chave, idioma);
            if (el.tagName === 'TITLE') {
                document.title = texto;
            } else {
                el.textContent = texto;
            }
        });

        // data-i18n-placeholder → placeholder
        document.querySelectorAll('[data-i18n-placeholder]').forEach(function (el) {
            el.placeholder = t(el.getAttribute('data-i18n-placeholder'), idioma);
        });

        // data-i18n-title → title (tooltip)
        document.querySelectorAll('[data-i18n-title]').forEach(function (el) {
            el.title = t(el.getAttribute('data-i18n-title'), idioma);
        });

        // <html lang>
        document.documentElement.lang = idioma === 'en' ? 'en' : 'pt-BR';

        // Dispara evento para que telas específicas possam reagir se necessário
        document.dispatchEvent(new CustomEvent('mr:idioma-alterado', { detail: { idioma: idioma } }));
    }

    // ─── 4. Init automático no DOMContentLoaded ──────────────────────────────
    document.addEventListener('DOMContentLoaded', function () {
        lerPreferencias();
        aplicarTema(MR.tema);
        aplicarTraducoes(MR.idioma);
    });

    // ─── 5. Expõe API pública ────────────────────────────────────────────────
    MR.aplicarTema      = aplicarTema;
    MR.aplicarTraducoes = aplicarTraducoes;
    MR.lerPreferencias  = lerPreferencias;

})();/**
 * 
 */