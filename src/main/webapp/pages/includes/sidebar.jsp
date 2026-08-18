<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>

<%--
  ============================================================================
  sidebar.jsp — menu lateral UNIVERSAL (PUBLICO / ADMIN / EDITOR / AUTOR / VISITANTE)
  ----------------------------------------------------------------------------
  Como usar em qualquer tela do sistema:

    <%
      request.setAttribute("currentPage", "perfil"); // chave da tela atual
    %>
    <jsp:include page="/pages/includes/sidebar.jsp" />

  Pre-requisitos:
    - session.getAttribute("usuarioLogado")  -> objeto Usuario (sempre setado
      no login; aqui so' e' lido, nao e' buscado nada no banco). Se for null,
      trata-se de visitante PUBLICO (ninguem logado) - sidebar mostra
      "Cadastre-se / Entrar" no lugar do card de usuario e um menu proprio.
    - request.getAttribute("currentPage")    -> String opcional, usada so'
      pra destacar (.active) o item de menu correspondente. Chaves aceitas:
      "dashboard", "usuarios", "categorias", "receitas", "relatorios",
      "auditoria", "comentarios", "mensagens", "home", "autores",
      "favoritas", "perfil", "configuracoes", "sobre" (essa ultima so' no
      menu publico)

  IMPORTANTE: "VISITANTE" (tipo_usuario = VISITANTE, alguem que se cadastrou
  como leitor) e' diferente de PUBLICO (ninguem logado). O visitante logado
  ve o menu de conta normal (favoritas, perfil, sair); o publico ve o menu
  institucional com "Cadastre-se / Entrar" e sem opcao de sair.

  IMPORTANTE: o CSS das classes .sidebar, .nav-item etc. NAO esta' neste
  arquivo — continua vindo do <style> de cada pagina (design system), igual
  ja' era feito. Se varias telas passarem a incluir este sidebar.jsp, vale a
  pena no futuro mover esse bloco de CSS pra um .css compartilhado, mas isso
  fica fora do escopo desta mudanca.
  ============================================================================
--%>

<%!
  /* Retorna "nav-item active" se a chave bater com a pagina atual, senao "nav-item" */
  private String navClass(String chave, String currentPage) {
    if (chave != null && chave.equals(currentPage)) return "nav-item active";
    return "nav-item";
  }
%>

<%
  Usuario u = (Usuario) session.getAttribute("usuarioLogado");
  boolean logado = (u != null);
  if (u == null) u = new Usuario();

  // "PUBLICO" = ninguem logado. So' vira VISITANTE/AUTOR/EDITOR/ADMIN quando
  // existe usuario de fato na sessao - antes disso tudo caia no mesmo "else"
  // do VISITANTE logado, por isso o publico aparecia com o menu errado.
  String tipo = logado
      ? ((u.getTipo_usuario() != null) ? u.getTipo_usuario().toString() : "VISITANTE")
      : "PUBLICO";

  String currentPage = (String) request.getAttribute("currentPage");
  if (currentPage == null) currentPage = "";

  String _ctx = request.getContextPath();

  String inicialNome = "?";
  if (u.getNome_usuario() != null && u.getNome_usuario().length() > 0) {
    inicialNome = u.getNome_usuario().substring(0, 1).toUpperCase();
  }

  String nomeExibicao = (u.getNome_usuario() != null) ? u.getNome_usuario() : "";

  String badgeLabel;
  String badgeEmoji;
  if ("ADMIN".equals(tipo)) {
    badgeLabel = "Administrador"; badgeEmoji = "\uD83D\uDC51";
  } else if ("EDITOR".equals(tipo)) {
    badgeLabel = "Editor/Moderador"; badgeEmoji = "\uD83D\uDD11";
  } else if ("AUTOR".equals(tipo)) {
    badgeLabel = "Autor"; badgeEmoji = "\u270D\uFE0F";
  } else {
    badgeLabel = "Visitante"; badgeEmoji = "";
  }
%>

<aside class="sidebar" id="sidebar" data-role="<%= tipo.toLowerCase() %>">

  <div class="sidebar-brand">
    <div class="brand-row">
      <div class="brand-badge">🌿</div>
      <div>
        <span class="brand-title">Sabor &amp; Arte</span>
        <span class="brand-sub">Blog Editorial</span>
      </div>
    </div>
  </div>

  <% if (logado) { %>
    <a href="<%= _ctx %>/PerfilController" class="sidebar-user" title="Meu perfil">
      <div class="user-avatar" style="background:linear-gradient(135deg,#e74c3c,#c0392b);">
        <% if (u.getFoto_usuario() != null && u.getFoto_usuario().length() > 0) { %>
          <img src="<%= u.getFoto_usuario() %>" alt="<%= nomeExibicao %>">
        <% } else { %>
          <%= inicialNome %>
        <% } %>
      </div>
      <div class="user-info">
        <div class="user-name"><%= nomeExibicao %></div>
        <div class="user-role-badge"><%= badgeEmoji %> <%= badgeLabel %></div>
      </div>
    </a>
  <% } else { %>
    <div class="sidebar-auth">
      <div class="sidebar-auth-hint">Faça parte da nossa comunidade</div>
      <a href="<%= _ctx %>/modal-cadastro.jsp" class="btn-sidebar btn-sidebar-solid">Cadastre-se</a>
      <a href="<%= _ctx %>/login.jsp" class="btn-sidebar btn-sidebar-outline">Entrar</a>
    </div>
  <% } %>

  <nav class="sidebar-nav">

    <% if ("PUBLICO".equals(tipo)) { %>

      <div class="nav-section-label">Principal</div>
      <a href="<%= _ctx %>/HomeController" class="<%= navClass("home", currentPage) %>"><span class="nav-icon">🏠</span><span class="nav-label">Início</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/AutorPublicoController" class="<%= navClass("autores", currentPage) %>"><span class="nav-icon">👩‍🍳</span><span class="nav-label">Autores</span></a>

      <div class="nav-section-label">Sobre</div>
      <a href="<%= _ctx %>/pages/sobre.jsp" class="<%= navClass("sobre", currentPage) %>"><span class="nav-icon">ℹ️</span><span class="nav-label">Sobre o Sabor &amp; Arte</span></a>

    <% } else if ("ADMIN".equals(tipo)) { %>

      <div class="nav-section-label">Principal</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Gestão</div>
      <a href="<%= _ctx %>/UsuarioController" class="<%= navClass("usuarios", currentPage) %>"><span class="nav-icon">👥</span><span class="nav-label">Usuários</span></a>
      <a href="<%= _ctx %>/CategoriaController" class="<%= navClass("categorias", currentPage) %>"><span class="nav-icon">🏷️</span><span class="nav-label">Categorias</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>
      <a href="<%= _ctx %>/LogController" class="<%= navClass("auditoria", currentPage) %>"><span class="nav-icon">🔍</span><span class="nav-label">Auditoria</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/PerfilController" class="<%= navClass("perfil", currentPage) %>"><span class="nav-icon">👤</span><span class="nav-label">Meu Perfil</span></a>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else if ("EDITOR".equals(tipo)) { %>

      <div class="nav-section-label">Visão Geral</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Gestão</div>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/ComentarioController" class="<%= navClass("comentarios", currentPage) %>"><span class="nav-icon">💬</span><span class="nav-label">Comentários</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/PerfilController" class="<%= navClass("perfil", currentPage) %>"><span class="nav-icon">👤</span><span class="nav-label">Meu Perfil</span></a>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else if ("AUTOR".equals(tipo)) { %>

      <div class="nav-section-label">Visão Geral</div>
      <a href="<%= _ctx %>/DashboardController" class="<%= navClass("dashboard", currentPage) %>"><span class="nav-icon">📊</span><span class="nav-label">Dashboard</span></a>

      <div class="nav-section-label">Conteúdo</div>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📖</span><span class="nav-label">Minhas Receitas</span></a>
      <a href="<%= _ctx %>/MensagemController" class="<%= navClass("mensagens", currentPage) %>"><span class="nav-icon">💬</span><span class="nav-label">Mensagens</span></a>

      <div class="nav-section-label">Análise</div>
      <a href="<%= _ctx %>/RelatorioController" class="<%= navClass("relatorios", currentPage) %>"><span class="nav-icon">📈</span><span class="nav-label">Relatórios</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/PerfilController" class="<%= navClass("perfil", currentPage) %>"><span class="nav-icon">👤</span><span class="nav-label">Meu Perfil</span></a>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } else { %>
      <%-- VISITANTE logado (cadastrado como leitor) - PUBLICO ja' foi tratado acima --%>

      <div class="nav-section-label">Explorar</div>
      <a href="<%= _ctx %>/HomeController" class="<%= navClass("home", currentPage) %>"><span class="nav-icon">🏠</span><span class="nav-label">Home</span></a>
      <a href="<%= _ctx %>/ReceitaController" class="<%= navClass("receitas", currentPage) %>"><span class="nav-icon">📝</span><span class="nav-label">Receitas</span></a>
      <a href="<%= _ctx %>/AutorController" class="<%= navClass("autores", currentPage) %>"><span class="nav-icon">✍️</span><span class="nav-label">Autores</span></a>
      <a href="<%= _ctx %>/FavoritoController" class="<%= navClass("favoritas", currentPage) %>"><span class="nav-icon">⭐</span><span class="nav-label">Favoritas</span></a>

      <div class="nav-section-label">Conta</div>
      <a href="<%= _ctx %>/PerfilController" class="<%= navClass("perfil", currentPage) %>"><span class="nav-icon">👤</span><span class="nav-label">Meu Perfil</span></a>
      <a href="<%= _ctx %>/ConfiguracaoController" class="<%= navClass("configuracoes", currentPage) %>"><span class="nav-icon">⚙️</span><span class="nav-label">Configurações</span></a>

    <% } %>

  </nav>

  <div class="sidebar-bottom">
    <% if (logado) { %>
      <a href="<%= _ctx %>/LogoutController" class="btn-logout"><span class="nav-icon">🚪</span><span>Sair</span></a>
    <% } else { %>
      © 2026 Sabor &amp; Arte
    <% } %>
  </div>

</aside>
