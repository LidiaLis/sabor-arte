<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%--
  ============================================================================
  home.jsp — tela Início, compartilhada entre PUBLICO (ninguem logado) e
  VISITANTE (logado como leitor).
  ----------------------------------------------------------------------------
  Servida pelo HomeController via forward, tanto de
  /pages/home-publico.jsp quanto de /pages/home-visitante.jsp - por isso
  esse arquivo assume esses dois nomes (veja nota no fim do arquivo) ou pode
  substituir os dois se você preferir apontar o forward direto pra ele.

  O que muda entre público e visitante:
    - sidebar.jsp já resolve sozinho (olha a sessão) - nada a fazer aqui.
    - Os cards "Categorias principais" / "Autores em destaque" mostram um
      link "Ver todas/Ver todos" no cabeçalho SÓ pra quem está logado
      (era assim no home-visitante.html original; no home-publico.html não
      tinha esse link).

  Atributos esperados na request (setados pelo HomeController):
    - receitasDestaque   -> List<Receita>
    - categoriasPrincipais -> List<Categoria>
    - autoresDestaque    -> List<Usuario>
    - erro (opcional)    -> String, se der erro de SQL no Controller
  ============================================================================
--%>
<%!
  // Resolve o caminho de imagem vindo do banco (normalmente relativo, ex:
  // "/uploads/avatars/123.jpg") prefixando o context path da aplicação.
  // Se já for uma URL absoluta (http/https/data), devolve como está.
  // Se vier nulo/vazio, devolve null (quem chamar decide o fallback).
  private String resolveImgUrl(String ctx, String path) {
    if (path == null || path.trim().isEmpty()) return null;
    if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
      return path;
    }
    String p = path.startsWith("/") ? path : "/" + path;
    return ctx + p;
  }
%>
<%
  Usuario usuarioSessao = (Usuario) session.getAttribute("usuarioLogado");
  boolean logado = (usuarioSessao != null);
  String _ctx = request.getContextPath();

  @SuppressWarnings("unchecked")
  List<Receita> receitasDestaque = (List<Receita>) request.getAttribute("receitasDestaque");

  @SuppressWarnings("unchecked")
  List<Categoria> categoriasPrincipais = (List<Categoria>) request.getAttribute("categoriasPrincipais");

  @SuppressWarnings("unchecked")
  List<Usuario> autoresDestaque = (List<Usuario>) request.getAttribute("autoresDestaque");
  if (autoresDestaque == null) autoresDestaque = new java.util.ArrayList<Usuario>();

  String erro = (String) request.getAttribute("erro");

  request.setAttribute("currentPage", "home");
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Início</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --published:#3a7a4a;--published-bg:#e8f4eb;
    --error:#9b4444;
    --sidebar-w:260px;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  /* ===== SIDEBAR (estilos usados pelo sidebar.jsp incluído abaixo) ===== */
  .sidebar{width:var(--sidebar-w);background:var(--moss-dark);display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:100;overflow-y:auto;}
  .sidebar::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 200% 60% at 50% 0%,rgba(74,94,58,0.5) 0%,transparent 60%),radial-gradient(ellipse 100% 40% at 50% 100%,rgba(163,177,138,0.1) 0%,transparent 60%);pointer-events:none;}
  .sidebar-brand{padding:28px 24px 22px;border-bottom:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;}
  .brand-row{display:flex;align-items:center;gap:12px;}
  .brand-badge{width:38px;height:38px;background:linear-gradient(135deg,var(--moss-light),var(--sage));border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
  .brand-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--cream);display:block;line-height:1;}
  .brand-sub{font-size:10px;color:var(--sage);text-transform:uppercase;letter-spacing:1.2px;margin-top:3px;display:block;font-weight:300;}

  .sidebar-auth{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;flex-direction:column;gap:8px;position:relative;z-index:1;}
  .sidebar-auth-hint{font-size:11px;color:rgba(245,240,232,0.55);font-weight:300;margin-bottom:2px;}
  .btn-sidebar{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:9px 14px;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;text-decoration:none;transition:all 0.2s;}
  .btn-sidebar-solid{background:var(--gold);color:var(--moss-dark);}
  .btn-sidebar-solid:hover{background:var(--gold-light);}
  .btn-sidebar-outline{background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.15);color:rgba(245,240,232,0.85);}
  .btn-sidebar-outline:hover{background:rgba(255,255,255,0.12);}

  .sidebar-nav{flex:1;padding:16px 0;position:relative;z-index:1;}
  .nav-section-label{font-size:9px;text-transform:uppercase;letter-spacing:1.8px;color:rgba(163,177,138,0.5);padding:16px 24px 6px;font-weight:500;}
  .nav-item{display:flex;align-items:center;gap:12px;padding:11px 24px;color:rgba(245,240,232,0.7);text-decoration:none;font-size:14px;font-weight:400;cursor:pointer;transition:all 0.2s;border-left:3px solid transparent;}
  .nav-item:hover{color:var(--cream);background:rgba(255,255,255,0.06);border-left-color:var(--sage);}
  .nav-item.active{color:var(--cream);background:rgba(163,177,138,0.15);border-left-color:var(--sage-light);font-weight:500;}
  .nav-icon{width:22px;text-align:center;font-size:16px;flex-shrink:0;}
  .sidebar-bottom{padding:16px 24px 24px;border-top:1px solid rgba(255,255,255,0.08);position:relative;z-index:1;font-size:11px;color:rgba(245,240,232,0.45);font-weight:300;}

  .btn-logout{display:flex;align-items:center;gap:10px;width:100%;padding:10px 16px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);border-radius:2px;color:rgba(245,240,232,0.7);font-family:'DM Sans',sans-serif;font-size:13px;cursor:pointer;transition:all 0.2s;text-decoration:none;}
  .btn-logout:hover{background:rgba(155,68,68,0.2);border-color:rgba(155,68,68,0.3);color:#e8a0a0;}
  .sidebar-user{padding:18px 24px;border-bottom:1px solid rgba(255,255,255,0.07);display:flex;align-items:center;gap:12px;position:relative;z-index:1;}

  a.sidebar-user, a.sidebar-user:link, a.sidebar-user:visited, a.sidebar-user:hover, a.sidebar-user:active {
    text-decoration: none; color: inherit;
  }
  .user-avatar{width:38px;height:38px;background:linear-gradient(135deg,var(--gold),var(--gold-light));border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--moss-dark);flex-shrink:0;overflow:hidden;}
  .user-avatar img{width:100%;height:100%;object-fit:cover;border-radius:50%;}
  .user-name{font-size:13px;font-weight:600;color:var(--cream);}
  .user-role-badge{font-size:10px;color:var(--gold-light);text-transform:uppercase;letter-spacing:0.8px;font-weight:300;}

  /* ===== MAIN ===== */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:12px;}
  .topbar-search{display:flex;align-items:center;gap:8px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;padding:7px 14px;width:220px;transition:border-color 0.2s,box-shadow 0.2s;}
  .topbar-search:focus-within{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,0.08);}
  .topbar-search input{border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;flex:1;}
  .topbar-search input::placeholder{color:var(--text-light);font-weight:300;}

  .content{flex:1;padding:28px 50px 30px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:36px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}

  .error-msg{background:rgba(155,68,68,0.08);border:1px solid rgba(155,68,68,0.25);border-left:3px solid var(--error);border-radius:2px;padding:10px 14px;font-size:13px;color:var(--error);margin-bottom:22px;}
  .empty-state{padding:28px;text-align:center;color:var(--text-light);font-size:13px;}

  /* ===== RECEITAS ===== */
  .featured-section{margin-bottom:22px;}
  .sub-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;}
  .sub-title{font-size:16px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:8px;}
  .sub-link{font-size:12px;color:var(--moss-light);cursor:pointer;font-weight:500;transition:color 0.2s;text-decoration:none;}
  .sub-link:hover{color:var(--moss-dark);}

  .recipes-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;}
  .recipe-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;transition:transform 0.25s,box-shadow 0.25s;cursor:pointer;}
  .recipe-card:hover{transform:translateY(-4px);box-shadow:0 16px 40px rgba(47,61,37,0.14);}
  .recipe-img-wrap{position:relative;overflow:hidden;height:240px;background:var(--cream-dark);}
  .recipe-img-wrap img{width:100%;height:100%;object-fit:cover;display:block;transition:transform 0.4s ease;}
  .recipe-card:hover .recipe-img-wrap img{transform:scale(1.05);}
  .img-badge{position:absolute;top:9px;left:9px;display:inline-flex;align-items:center;gap:5px;padding:3px 8px;border-radius:2px;font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:0.5px;backdrop-filter:blur(6px);background:rgba(196,162,101,0.92);color:#fff;}
  .img-time{position:absolute;bottom:8px;right:9px;background:rgba(30,39,24,0.75);color:rgba(245,240,232,0.95);font-family:'Nunito',sans-serif;font-size:10px;font-weight:700;padding:2px 8px;border-radius:20px;backdrop-filter:blur(4px);}
  .recipe-body{padding:12px 14px 10px;}
  .recipe-cat{font-size:9px;text-transform:uppercase;letter-spacing:1px;color:var(--moss-light);font-weight:600;margin-bottom:4px;}
  .recipe-name{font-family:'Playfair Display',serif;font-size:14px;font-weight:700;color:var(--text-dark);line-height:1.3;margin-bottom:8px;}
  .recipe-meta{display:flex;align-items:center;justify-content:space-between;}
  .recipe-author{display:flex;align-items:center;gap:6px;}
  .author-dot{width:20px;height:20px;border-radius:50%;object-fit:cover;flex-shrink:0;background:var(--cream-dark);}
  .author-name{font-size:11px;color:var(--text-mid);font-weight:400;}
  .recipe-stars{font-size:11px;color:var(--gold);font-weight:600;}

  a.recipe-card, a.recipe-card:link, a.recipe-card:visited, a.recipe-card:hover, a.recipe-card:active {
    display: block; text-decoration: none; color: inherit;
  }

  /* ===== RODAPÉ: CATEGORIAS (esq.) + AUTORES (dir.) ===== */
  .bottom-grid{display:grid;grid-template-columns:1fr 310px;gap:24px;}
  .side-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;}
  .card-head{padding:18px 22px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .card-title-sm{font-size:14px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:8px;}
  .card-action{font-size:12px;color:var(--moss-light);cursor:pointer;font-weight:500;transition:color 0.2s;text-decoration:none;}
  .card-action:hover{color:var(--moss-dark);}

  .cat-item{display:flex;align-items:center;gap:12px;padding:9px 20px;border-bottom:1px solid var(--cream-dark);cursor:pointer;transition:background .15s;}
  .cat-item:last-child{border-bottom:none;}
  .cat-item:hover{background:var(--cream);}
  .cat-color{width:8px;height:28px;border-radius:2px;flex-shrink:0;}
  .cat-info{flex:1;}
  .cat-name{font-size:13px;font-weight:500;color:var(--text-dark);}
  .cat-count{font-family:'Nunito',sans-serif;font-size:11px;color:var(--text-light);font-weight:600;}

  .author-item{display:flex;align-items:center;gap:12px;padding:9px 20px;border-bottom:1px solid var(--cream-dark);cursor:pointer;transition:background .15s;}
  .author-item:last-child{border-bottom:none;}
  .author-item:hover{background:var(--cream);}
  .author-avatar-lg{width:34px;height:34px;border-radius:50%;object-fit:cover;flex-shrink:0;border:2px solid var(--sage-light);background:var(--cream-dark);}
  .author-info{flex:1;min-width:0;}
  .author-item-name{font-size:13px;font-weight:600;color:var(--text-dark);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
  .author-item-specialty{font-size:11px;color:var(--text-light);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
  .author-item-count{font-family:'Nunito',sans-serif;font-size:11px;color:var(--moss);font-weight:700;background:rgba(74,94,58,0.08);padding:3px 9px;border-radius:10px;flex-shrink:0;}
  .author-avatar-fallback{display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:13px;color:var(--moss-dark);background:linear-gradient(135deg,var(--gold),var(--gold-light));}
  .author-dot-fallback{display:inline-flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-weight:800;font-size:9px;color:var(--moss-dark);background:linear-gradient(135deg,var(--gold),var(--gold-light));border-radius:50%;}

  @media(max-width:1280px){.recipes-grid{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:1100px){.bottom-grid{grid-template-columns:1fr;}}
  @media(max-width:860px){.recipes-grid{grid-template-columns:1fr;}}
  @media(max-width:768px){.sidebar{display:none;} .main{margin-left:0;} .content{padding:24px 20px;} .topbar{padding:0 20px;}}
  @media(max-width:480px){.topbar-search{display:none;}}
</style>
</head>
<body>

<jsp:include page="/pages/includes/sidebar.jsp" />

<main class="main">
<div class="topbar">
  <div class="page-crumb">
      <span>Principal</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Início</span>
  </div>
</div>

  <div class="content">

    <% if (erro != null && !erro.isEmpty()) { %>
      <div class="error-msg">⚠️ <%= erro %></div>
    <% } %>

    <!-- ===== RECEITAS EM DESTAQUE ===== -->
    <div class="featured-section">
      <div class="sub-header">
        <div class="sub-title">🔥 Receitas em destaque</div>
        <a href="<%= _ctx %>/ReceitaController" class="sub-link">Ver todas →</a>
      </div>

      <div class="recipes-grid">
        <% if (receitasDestaque != null && !receitasDestaque.isEmpty()) {
             for (Receita r : receitasDestaque) {
               String imgReceita = resolveImgUrl(_ctx, r.getImagem_receita());
               String fotoAutorReceita = resolveImgUrl(_ctx, r.getFoto_usuario());
          %>

        <a href="<%= _ctx %>/ReceitaController?action=detalhe&amp;id=<%= r.getId_receita() %>" class="recipe-card">
          <div class="recipe-img-wrap">
            <% if (imgReceita != null) { %>
              <img src="<%= imgReceita %>" alt="<%= r.getTitulo_receita() %>">
            <% } else { %>
              <img src="<%= _ctx %>/assets/img/receita-placeholder.png" alt="<%= r.getTitulo_receita() %>">
            <% } %>
            <div class="img-time">⏱ <%= r.getTempo_preparo_receita() %> min</div>
          </div>
          <div class="recipe-body">
            <div class="recipe-cat"><%= r.getEmoji_categoria() %> <%= r.getNome_categoria() %></div>
            <div class="recipe-name"><%= r.getTitulo_receita() %></div>
            <div class="recipe-meta">
              <div class="recipe-author">
                <% if (fotoAutorReceita != null) { %>
                  <img class="author-dot" src="<%= fotoAutorReceita %>" alt="">
                <% } else { %>
                  <span class="author-dot author-dot-fallback"><%= r.getNome_usuario().substring(0,1).toUpperCase() %></span>
                <% } %>
                <span class="author-name"><%= r.getNome_usuario() %></span>
              </div>
              <div class="recipe-stars">★ <%= String.format("%.1f", r.getNota_media()) %></div>
            </div>
          </div>
        </a>

        <% } } else { %>
          <div class="empty-state">Ainda não há receitas em destaque.</div>
        <% } %>
      </div>
    </div>

    <!-- ===== RODAPÉ: CATEGORIAS (esquerda) + AUTORES (direita) ===== -->
    <div class="bottom-grid">

      <div class="side-card">
        <div class="card-head">
          <div class="card-title-sm">🏷️ Categorias principais</div>
          <% if (logado) { %>
            <a href="<%= _ctx %>/CategoriaController" class="card-action">Ver todas</a>
          <% } %>
        </div>
        <div id="listaCategorias">
        <% if (categoriasPrincipais != null && !categoriasPrincipais.isEmpty()) {
             for (Categoria c : categoriasPrincipais) { %>
        <div class="cat-item">
          <div class="cat-color" style="background:<%= c.getCor_categoria() %>"></div>
          <div class="cat-info"><div class="cat-name"><%= c.getEmoji_categoria() %> <%= c.getNome_categoria() %></div></div>
          <div class="cat-count"><%= c.getTotal_receitas() %> receitas</div>
        </div>
        <% } } else { %>
          <div class="empty-state">Nenhuma categoria cadastrada ainda.</div>
        <% } %>
        </div>
      </div>

      <div class="side-card">
        <div class="card-head">
          <div class="card-title-sm">👩‍🍳 Autores em destaque</div>
          <% if (logado) { %>
            <a href="<%= _ctx %>/AutorController" class="card-action">Ver todos</a>
          <% } %>
        </div>
        <div id="listaAutores">
        <% if (autoresDestaque != null && !autoresDestaque.isEmpty()) {
             for (Usuario a : autoresDestaque) {
               String fotoAutor = resolveImgUrl(_ctx, a.getFoto_usuario());
          %>
        <div class="author-item">
          <% if (fotoAutor != null) { %>
            <img class="author-avatar-lg" src="<%= fotoAutor %>" alt="<%= a.getNome_usuario() %>">
          <% } else { %>
            <div class="author-avatar-lg author-avatar-fallback"><%= a.getNome_usuario().substring(0,1).toUpperCase() %></div>
          <% } %>
          <div class="author-info">
            <div class="author-item-name"><%= a.getNome_usuario() %></div>
            <div class="author-item-specialty"><%= (a.getTitulo_usuario() != null) ? a.getTitulo_usuario() : "" %></div>
          </div>
          <div class="author-item-count"><%= a.getTotal_receitas_publicadas() %></div>
        </div>
        <% } } else { %>
          <div class="empty-state">Nenhum autor em destaque ainda.</div>
        <% } %>
        </div>
      </div>

    </div>

  </div>
</main>

</body>
</html>
	