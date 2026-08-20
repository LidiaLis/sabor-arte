<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="br.com.saborearte.model.Receita" %>
<%@ page import="br.com.saborearte.model.Comentario" %>
<%@ page import="br.com.saborearte.model.Categoria" %>
<%@ page import="br.com.saborearte.utils.ImagemUrlUtil" %>
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

  NOVO (quando temAbas=true, ou seja so AUTOR por enquanto):
    + especialidadesIds -> ids_categoria separados por vírgula (ex: "3,7"),
                            montados no JS a partir das .tag renderizadas.
                            Especialidades vem da tabela associativa
                            "especialidade" (N:N usuario<->categoria) via
                            EspecialidadeDAO, nao de uma string no Usuario.
                            Sem tempo/anos de especialidade nesta tela — so
                            marca quais categorias sao especialidade do
                            autor. O controller ja deixa prontos em request:
                              especialidadesUsuario   -> List<Categoria> (tags do autor)
                              categoriasDisponiveis   -> List<Categoria> (todas ativas, p/ o <select>)
    + instagram, youtube, pinterest -> Strings, ficam direto em
                            colunas no Usuario (getInstagram_usuario() etc.),
                            mesma ideia de telefone/localizacao.
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

  boolean temAbas = "AUTOR".equals(tipo);

  /* Regra de permissao de foto: todo mundo edita a PROPRIA foto,
     exceto o Visitante (perfil publico/sem edicao de midia).
     O Administrador tambem edita a foto de outros usuarios,
     mas isso acontece na tela de Usuarios (UsuarioController), nao aqui. */
  boolean podeEditarFoto = !"VISITANTE".equals(tipo);

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

  /* ===== Especialidades culinárias (aba "Especialidades & Redes") =====
     Vem prontas do PerfilController via EspecialidadeDAO — nao deriva mais
     de uma string separada por "|". Sem tempo/anos por especialidade: a
     tela so marca quais categorias sao especialidade do autor. */
  List<Categoria> especialidadesUsuario  = (List<Categoria>) request.getAttribute("especialidadesUsuario");
  List<Categoria> categoriasDisponiveis  = (List<Categoria>) request.getAttribute("categoriasDisponiveis");
  if (especialidadesUsuario == null) especialidadesUsuario = new java.util.ArrayList<Categoria>();
  if (categoriasDisponiveis == null) categoriasDisponiveis = new java.util.ArrayList<Categoria>();

  // ids ja usados pelo autor, pro hidden inicial do form (comparado por String)
  StringBuilder especialidadesIdsInicial = new StringBuilder();
  for (int i = 0; i < especialidadesUsuario.size(); i++) {
    if (i > 0) especialidadesIdsInicial.append(",");
    especialidadesIdsInicial.append(especialidadesUsuario.get(i).getId_categoria());
  }

  Integer qtdSeguindoAttr = (Integer) request.getAttribute("qtdSeguindo");
  int qtdSeguindo = (qtdSeguindoAttr != null) ? qtdSeguindoAttr : 0;
  String _ctx = request.getContextPath();

  // Mensagens vindas do PerfilController (PRG: sucesso/erro na sessão -> request),
  // no mesmo padrão usado pelo ConfiguracaoController na tela de Configurações.
  String sucesso = (String) request.getAttribute("sucesso");
  String erro    = (String) request.getAttribute("erro");
  // Escapa aspas/quebras de linha pra poder jogar dentro de string JS com segurança
  String sucessoJs = sucesso != null ? sucesso.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ") : null;
  String erroJs = erro != null ? erro.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ") : null;
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
.hero-stats { display:flex; align-items:center; }
.hero-following-pill { display:inline-flex; align-items:center; gap:10px; background:rgba(255,255,255,0.1); border:1px solid rgba(255,255,255,0.18); padding:8px 18px; border-radius:20px; text-decoration:none; transition:background .2s, border-color .2s; }
.hero-following-pill:hover { background:rgba(255,255,255,0.18); border-color:rgba(255,255,255,0.3); }
.hero-following-icon { font-size:17px; color:#e8a0a0; line-height:1; }
.hero-following-text { display:flex; flex-direction:column; line-height:1.15; }
.hero-following-val { font-size:15px; font-weight:700; color:white; font-family:'Nunito',sans-serif; }
.hero-following-lbl { font-size:10px; color:rgba(255,255,255,0.65); text-transform:uppercase; letter-spacing:.6px; font-weight:500; }

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
.form-input.invalid { border-color: var(--error) !important; background: var(--error-bg) !important; }
.form-input.invalid:focus { box-shadow: 0 0 0 3px rgba(155,68,68,0.12); }

/* ===== TAGS (Especialidades) ===== */
.tags-wrap { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px; min-height:36px; align-content:flex-start; }
.tag { display:inline-flex; align-items:center; gap:5px; background:rgba(74,94,58,0.1); border:1.5px solid rgba(74,94,58,0.22); padding:5px 12px; border-radius:20px; font-size:12px; color:var(--moss); font-weight:500; animation:tagIn .2s ease; }
@keyframes tagIn { from { opacity:0; transform:scale(.85); } to { opacity:1; transform:scale(1); } }
.tag .tag-remove { cursor:pointer; color:var(--moss-light); font-size:14px; line-height:1; transition:color .15s; }
.tag .tag-remove:hover { color:var(--error); }
.spec-select-wrap { display:flex; gap:8px; align-items:stretch; }
.spec-select-wrap .form-select { flex:1; }
.spec-hint { font-size:11px; margin-top:5px; font-weight:300; color:var(--error); min-height:16px; }

/* ===== BOTOES ===== */
.btn { display:inline-flex; align-items:center; gap:8px; padding:10px 20px; border:none; border-radius:2px; font-family:'DM Sans',sans-serif; font-size:13px; font-weight:500; cursor:pointer; transition:all .2s; }
.btn-primary { background:var(--moss); color:var(--cream); }
.btn-primary:hover { background:var(--moss-dark); transform:translateY(-1px); box-shadow:0 4px 14px rgba(47,61,37,0.25); }
.btn-sm { padding:7px 14px; font-size:12px; }

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
.modal-box { background: var(--warm-white); border-radius: 4px; padding: 32px 36px; text-align: center; min-width: 320px; box-shadow: 0 12px 40px rgba(0,0,0,0.2); animation: slideUp 0.3s ease; }
.modal-icon { font-size: 48px; margin-bottom: 12px; }
.modal-title { font-family: 'Playfair Display', serif; font-size: 20px; font-weight: 700; color: var(--text-dark); margin-bottom: 6px; }
.modal-msg { font-size: 13px; color: var(--text-light); margin-bottom: 22px; font-weight: 300; }
@keyframes slideUp { from { opacity: 0; transform: translateY(24px); } to { opacity: 1; transform: translateY(0); } }
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
  request.setAttribute("currentPage", "perfis");
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
      <div class="hero-avatar-big" id="heroAvatar"
           <% if (podeEditarFoto) { %>onclick="openAvatarModal()" title="Clique para alterar foto"<% } else { %>style="cursor:default" title="<%= nz(u.getNome_usuario()) %>"<% } %>>
        <% if (u.getFoto_usuario() != null && u.getFoto_usuario().length() > 0) { %>
          <img id="heroAvatarImg" src="<%= u.getFoto_usuario() %>" alt="Foto de perfil" class="visible">
        <% } else { %>
          <%= inicialNome %>
        <% } %>
      </div>
      <!-- Botao de trocar foto: visivel so para quem pode editar a propria foto (todos menos Visitante) -->
      <% if (podeEditarFoto) { %>
      <div class="avatar-upload-btn" onclick="openAvatarModal()" title="Alterar foto">📷</div>
      <% } %>
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
          <a class="hero-following-pill" href="<%= request.getContextPath() %>/SeguidorController?action=listar" title="Ver autores que você segue">
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
        <button class="tab-btn" onclick="switchTab('social', this)">🍴 Especialidades &amp; Redes</button>
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
                  <input type="text" class="form-input readonly" value="<%= nz(u.getUsername_usuario()) %>" readonly>
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
                         value="<%= nz(u.getLocalizacao_usuario()) %>" placeholder="Cidade, UF"
                         maxlength="60" oninput="formatLocation(this)">
                  <div class="field-error" id="locError"></div>
                </div>
              </div>

              <% if (temAbas) { %>
                <!-- Se a aba Biografia existir, o campo bio (hidden) acompanha o mesmo POST -->
                <input type="hidden" name="bio" id="bioHidden" value="<%= nz(u.getBio_usuario()) %>">
                <input type="hidden" name="titulo" id="tituloHidden" value="<%= nz(u.getTitulo_usuario()) %>">
                <input type="hidden" name="especialidadesIds" id="especialidadesIdsHidden" value="<%= especialidadesIdsInicial.toString() %>">
                <input type="hidden" name="instagram" id="instagramHidden" value="<%= nz(u.getInstagram_usuario()) %>">
                <input type="hidden" name="youtube" id="youtubeHidden" value="<%= nz(u.getYoutube_usuario()) %>">
                <input type="hidden" name="pinterest" id="pinterestHidden" value="<%= nz(u.getPinterest_usuario()) %>">
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
                <a href="<%= _ctx %>/receitas" style="font-size:12px;color:var(--moss-light);text-decoration:none">Ver todas</a>
              </div>
              <div class="card-body" style="padding:16px">
                <% if (receitasPublicadas != null && !receitasPublicadas.isEmpty()) { %>
                  <div class="public-grid">
                    <% int limite = Math.min(3, receitasPublicadas.size());
                       for (int i = 0; i < limite; i++) {
                         Receita r = receitasPublicadas.get(i);
                    %>
                      <div class="public-mini">
                        <img src="<%= nz(ImagemUrlUtil.resolverParaAtributoHtml(_ctx, r.getImagem_receita())) %>" alt="<%= nz(r.getTitulo_receita()) %>">
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
                        <img src="<%= nz(ImagemUrlUtil.resolverParaAtributoHtml(_ctx, r.getImagem_receita())) %>" alt="<%= nz(r.getTitulo_receita()) %>">
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
                <a href="<%= _ctx %>/comentarios-moderacao" style="font-size:12px;color:var(--moss-light);text-decoration:none">Ver tudo</a>
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
                     placeholder="Ex: Chef de Cozinha · Especialista em Culinária Italiana" maxlength="80"
                     oninput="document.getElementById('tituloHidden').value=this.value;">
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

    <!-- =========================================================
         PAINEL "ESPECIALIDADES & REDES" — so existe para AUTOR (temAbas)
         Mesmo padrao do resto: os inputs ficam FORA do formDados (que so
         existe dentro do card de Dados Gerais), entao cada mudanca sincroniza
         num hidden field do formDados via oninput/onchange. O botao que
         realmente envia o POST continua sendo "Atualizar Dados" na aba
         Dados Gerais.
         ========================================================= -->
    <% if (temAbas) { %>
      <div id="tab-social" class="tab-panel">
        <div class="cards-grid">

          <div class="card">
            <div class="card-head">
              <div class="card-head-title"><span class="card-icon">🍴</span> Especialidades Culinárias</div>
            </div>
            <div class="card-body">
              <div class="form-group">
                <label class="form-label">Suas especialidades</label>
                <div class="tags-wrap" id="tagsWrap">
                  <% for (Categoria esp : especialidadesUsuario) { %>
                    <div class="tag" data-id="<%= esp.getId_categoria() %>"><%= nz(esp.getEmoji_categoria()) %> <%= nz(esp.getNome_categoria()) %> <span class="tag-remove" onclick="removeTag(this)">×</span></div>
                  <% } %>
                </div>
              </div>
              <div class="form-group" style="margin-bottom:0">
                <label class="form-label">Adicionar especialidade</label>
                <div class="spec-select-wrap">
                  <select class="form-select" id="specSelect">
                    <option value="">Escolha uma especialidade…</option>
                    <% for (Categoria cat : categoriasDisponiveis) { %>
                      <option value="<%= cat.getId_categoria() %>"><%= nz(cat.getEmoji_categoria()) %> <%= nz(cat.getNome_categoria()) %></option>
                    <% } %>
                  </select>
                  <button type="button" class="btn btn-outline btn-sm" onclick="addSpec()">+ Adicionar</button>
                </div>
                <div class="spec-hint" id="specHint"></div>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="card-head">
              <div class="card-head-title"><span class="card-icon">🌐</span> Redes Sociais</div>
            </div>
            <div class="card-body">
              <div class="form-group">
                <label class="form-label">Instagram</label>
                <input type="text" class="form-input" id="instagramInput" placeholder="@seuinstagram"
                       value="<%= nz(u.getInstagram_usuario()) %>" maxlength="31"
                       oninput="formatInstagram(this)">
                <div class="field-error" id="instagramError"></div>
              </div>
              <div class="form-group">
                <label class="form-label">YouTube</label>
                <input type="url" class="form-input" id="youtubeInput" placeholder="https://youtube.com/@seu-canal"
                       value="<%= nz(u.getYoutube_usuario()) %>"
                       oninput="formatYoutube(this)">
                <div class="field-error" id="youtubeError"></div>
              </div>
              <div class="form-group" style="margin-bottom:0">
                <label class="form-label">Pinterest</label>
                <input type="url" class="form-input" id="pinterestInput" placeholder="https://pinterest.com/seuperfil"
                       value="<%= nz(u.getPinterest_usuario()) %>"
                       oninput="formatPinterest(this)">
                <div class="field-error" id="pinterestError"></div>
              </div>
            </div>
          </div>

        </div>
        <div class="form-hint" style="margin-top:14px">Clique em "Atualizar Dados" na aba Dados Gerais para salvar essas informações.</div>
      </div>
    <% } %>

  </div>
</main>

<!-- ===== MODAL GENÉRICO (sucesso/aviso) ===== -->
<div class="modal-overlay" id="modalOverlay">
  <div class="modal-box">
    <div class="modal-icon" id="mIcon">✅</div>
    <div class="modal-title" id="mTitle">Sucesso!</div>
    <div class="modal-msg" id="mMsg">Operação concluída.</div>
    <button class="btn btn-primary" onclick="closeModal()">OK</button>
  </div>
</div>

<!-- ===== MODAL AVATAR (estrutura visual — envio via JS/AJAX fora do escopo) ===== -->
<% if (podeEditarFoto) { %>
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
      <button class="btn btn-primary" id="avSaveBtn" disabled type="button" onclick="saveAvatar()">💾 Salvar foto</button>
    </div>
  </div>
</div>
<% } %>

<script>
/* ===== TABS ===== */
function switchTab(id, btn) {
  document.querySelectorAll('.tab-panel').forEach(function (p) { p.classList.remove('active'); });
  document.querySelectorAll('.tab-btn').forEach(function (b) { b.classList.remove('active'); });
  document.getElementById('tab-' + id).classList.add('active');
  btn.classList.add('active');
}

/* ===== ESPECIALIDADES (aba "Especialidades & Redes") =====
   Cada add/remove reconstroi o hidden "especialidadesIdsHidden" (dentro do
   formDados, aba Dados Gerais) juntando os id_categoria das tags com ",".
   O PerfilController le esse CSV e sincroniza via EspecialidadeDAO
   (apaga tudo do usuario e reinsere so o que veio marcado). */
function addSpec() {
  var sel = document.getElementById('specSelect');
  var id = sel.value;
  var label = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text : '';
  var hint = document.getElementById('specHint');
  if (!id) { hint.textContent = 'Selecione uma especialidade antes de adicionar.'; return; }
  var wrap = document.getElementById('tagsWrap');
  var existingIds = Array.prototype.map.call(wrap.querySelectorAll('.tag'), function (t) {
    return t.getAttribute('data-id');
  });
  if (existingIds.indexOf(id) !== -1) { hint.textContent = 'Essa especialidade já foi adicionada.'; return; }
  hint.textContent = '';
  var div = document.createElement('div');
  div.className = 'tag';
  div.setAttribute('data-id', id);
  div.innerHTML = label + ' <span class="tag-remove" onclick="removeTag(this)">×</span>';
  wrap.appendChild(div);
  sel.value = '';
  syncEspecialidades();
}
function removeTag(el) {
  el.parentElement.remove();
  syncEspecialidades();
}
function syncEspecialidades() {
  var wrap = document.getElementById('tagsWrap');
  var ids = Array.prototype.map.call(wrap.querySelectorAll('.tag'), function (t) {
    return t.getAttribute('data-id');
  });
  document.getElementById('especialidadesIdsHidden').value = ids.join(',');
}

/* ===== MASCARA TELEFONE ===== */
function phoneMask(input) {
  var v = input.value.replace(/\D/g, ''), f = '';
  if (v.length > 0) f = '(' + v.substring(0, 2);
  if (v.length > 2) f += ') ' + v.substring(2, 7);
  if (v.length > 7) f += '-' + v.substring(7, 11);
  input.value = f;
}

/* ===== VALIDACAO: LOCALIZACAO (Cidade, UF) — mesma regra do perfil-admin.html ===== */
var UF_LIST = ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];

function formatLocation(el) {
  var raw = el.value;
  var err = document.getElementById('locError');

  // Auto-maiuscula na sigla do estado apos a virgula, sem travar a digitacao da cidade
  var commaIdx = raw.indexOf(',');
  if (commaIdx !== -1) {
    var cidade = raw.substring(0, commaIdx);
    var uf = raw.substring(commaIdx + 1).toUpperCase().replace(/[^A-Z]/g, '').slice(0, 2);
    el.value = cidade + ', ' + uf;
  }

  if (raw.trim() === '') { el.classList.remove('invalid'); err.textContent = ''; return; }

  var pattern = /^[A-Za-zÀ-ÖØ-öø-ÿ' -]+,\s[A-Z]{2}$/;
  var match = pattern.test(el.value);
  var ufValid = match && UF_LIST.includes(el.value.split(',')[1].trim());

  if (!match) {
    el.classList.add('invalid');
    err.textContent = 'Formato: Cidade, UF (ex: Salvador, BA).';
  } else if (!ufValid) {
    el.classList.add('invalid');
    err.textContent = 'Sigla de estado inválida.';
  } else {
    el.classList.remove('invalid');
    err.textContent = '';
  }
}

/* ===== VALIDACAO: REDES SOCIAIS (mesmo padrao do campo Localizacao) =====
   Instagram: mascara em tempo real (so deixa passar caractere valido, igual
   phoneMask), sem bloquear submit — espelha a limpeza feita no server
   (sanitizarInstagram). YouTube/Pinterest: precisam ser link real do
   proprio dominio, entao validam formato completo e bloqueiam o submit se
   invalido, igual a Localizacao — os mesmos regex usados no
   PerfilController (YOUTUBE_VALIDO / PINTEREST_VALIDO). */
function formatInstagram(el) {
  var v = el.value;
  var comArroba = v.startsWith('@');
  var corpo = (comArroba ? v.substring(1) : v).replace(/[^A-Za-z0-9._]/g, '').slice(0, 30);
  el.value = comArroba ? '@' + corpo : corpo;
  document.getElementById('instagramHidden').value = el.value;
}

var YOUTUBE_VALIDO = /^https:\/\/(www\.)?(youtube\.com\/(@|channel\/|c\/|user\/)[A-Za-z0-9._-]+|youtu\.be\/[A-Za-z0-9._-]+)\/?$/i;
var PINTEREST_VALIDO = /^https:\/\/([a-z]{2,3}\.)?pinterest\.[a-z.]{2,10}\/[A-Za-z0-9._-]+\/?$/i;

function formatYoutube(el) {
  document.getElementById('youtubeHidden').value = el.value;
  var err = document.getElementById('youtubeError');
  var v = el.value.trim();
  if (v === '') { el.classList.remove('invalid'); err.textContent = ''; return; }
  if (!YOUTUBE_VALIDO.test(v)) {
    el.classList.add('invalid');
    err.textContent = 'Link deve ser um canal/vídeo do YouTube (ex: https://youtube.com/@seucanal).';
  } else {
    el.classList.remove('invalid');
    err.textContent = '';
  }
}

function formatPinterest(el) {
  document.getElementById('pinterestHidden').value = el.value;
  var err = document.getElementById('pinterestError');
  var v = el.value.trim();
  if (v === '') { el.classList.remove('invalid'); err.textContent = ''; return; }
  if (!PINTEREST_VALIDO.test(v)) {
    el.classList.add('invalid');
    err.textContent = 'Link deve ser do Pinterest (ex: https://pinterest.com/seuperfil).';
  } else {
    el.classList.remove('invalid');
    err.textContent = '';
  }
}

/* ===== TRAVA O SUBMIT SE LOCALIZACAO OU REDES SOCIAIS ESTIVEREM INVALIDAS =====
   Os campos de Bio/Titulo/Especialidades/Redes ficam fisicamente fora do
   #formDados (moram nas abas Biografia / Especialidades & Redes), entao a
   validacao roda direto nos inputs visiveis por id, e nao depende deles
   serem descendentes do <form>.

   IMPORTANTE: essa trava bloqueia o envio do formulario INTEIRO (bio,
   titulo, especialidades, etc. junto), mesmo que o usuario nao tenha
   mexido no campo invalido — por exemplo, um valor antigo de localizacao
   ou rede social que ja estava salvo num formato que nao bate mais com o
   regex atual. Sem aviso, isso parecia "clico em salvar e nao acontece
   nada" (inclusive a biografia ficava sem salvar por causa de um campo
   que nem era ela). Agora mostramos um modal deixando claro qual campo
   está impedindo o salvamento. */
document.getElementById('formDados').addEventListener('submit', function (e) {
  var loc = document.getElementById('locInput');
  formatLocation(loc);

  var yt = document.getElementById('youtubeInput');
  var pin = document.getElementById('pinterestInput');
  if (yt) formatYoutube(yt);
  if (pin) formatPinterest(pin);

  var invalidos = [loc, yt, pin].filter(function (el) {
    return el && el.classList.contains('invalid');
  });

  if (invalidos.length > 0) {
    e.preventDefault();
    var primeiro = invalidos[0];

    var nomeCampo = primeiro === loc ? 'Localização' : (primeiro === yt ? 'YouTube' : 'Pinterest');

    if (primeiro !== loc) {
      var btnSocial = document.querySelector('.tab-btn[onclick*="social"]');
      if (btnSocial) switchTab('social', btnSocial);
    }
    primeiro.focus();

    showModal('⚠️', 'Corrija antes de salvar',
      'O campo "' + nomeCampo + '" está com formato inválido e por isso NADA foi salvo ' +
      '(incluindo biografia, título e especialidades). Corrija esse campo e clique em ' +
      '"Atualizar Dados" novamente.');
  }
});

/* ===== MODAL GENÉRICO (sucesso/aviso) — mesmo padrao do perfil-admin.html ===== */
function showModal(icon, title, msg) {
  document.getElementById('mIcon').textContent = icon;
  document.getElementById('mTitle').textContent = title;
  document.getElementById('mMsg').textContent = msg;
  document.getElementById('modalOverlay').classList.add('show');
}
function closeModal() { document.getElementById('modalOverlay').classList.remove('show'); }
document.getElementById('modalOverlay').addEventListener('click', function (e) {
  if (e.target === this) closeModal();
});

/* Dispara o modal de sucesso/erro apos o PerfilController fazer o forward de
   volta pra ca (padrao PRG: sucesso/erro guardados na sessao -> request,
   igual ao ConfiguracaoController na tela de Configuracoes). */
<% if (sucessoJs != null) { %>
showModal('✅', 'Sucesso!', '<%= sucessoJs %>');
<% } %>
<% if (erroJs != null) { %>
showModal('⚠️', 'Ops!', '<%= erroJs %>');
<% } %>

/* ===== MODAL AVATAR =====
   Só existe no DOM se podeEditarFoto=true (Visitante não recebe nem
   a marcação HTML do modal — regra 6 aplicada tambem aqui). */
var avatarModalEl = document.getElementById('avatarModal');
var avSelectedBase64 = null;

function openAvatarModal() { if (avatarModalEl) avatarModalEl.classList.add('show'); }
function closeAvatarModal() { if (avatarModalEl) avatarModalEl.classList.remove('show'); }
if (avatarModalEl) {
  avatarModalEl.addEventListener('click', function (e) {
    if (e.target === this) closeAvatarModal();
  });
}

function handleAvFile(file) {
  if (!file) return;
  if (!file.type.startsWith('image/')) return;
  if (file.size > 5 * 1024 * 1024) return;
  var reader = new FileReader();
  reader.onload = function (e) {
    var img = document.getElementById('avPreviewImg');
    img.src = e.target.result;
    img.classList.add('visible');
    document.getElementById('avPreviewRing').classList.add('has-img');
    document.getElementById('avSaveBtn').disabled = false;
    avSelectedBase64 = e.target.result;
  };
  reader.readAsDataURL(file);
}
function handleAvDrop(e) {
  e.preventDefault();
  document.getElementById('avDropZone').classList.remove('drag-over');
  handleAvFile(e.dataTransfer.files[0]);
}

/* Envia a foto pro PerfilController (action=atualizarFoto).
   Sempre manda o id do proprio usuario logado — o servlet reforca
   essa regra de novo no server-side (nunca confiar so no front). */
function saveAvatar() {
  if (!avSelectedBase64) return;
  var btn = document.getElementById('avSaveBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Salvando…';

  var canvas = document.createElement('canvas');
  canvas.width = 200; canvas.height = 200;
  var ctx = canvas.getContext('2d');
  var img = new Image();
  img.onload = function () {
    ctx.drawImage(img, 0, 0, 200, 200);
    var base64Reduzido = canvas.toDataURL('image/jpeg', 0.7);

    var form = document.createElement('form');
    form.method = 'POST';
    form.action = '<%= _ctx %>/PerfilController';

    [['action', 'atualizarFoto'], ['id', <%= u.getId_usuario() %>], ['fotoBase64', base64Reduzido]]
      .forEach(function (par) {
        var input = document.createElement('input');
        input.type = 'hidden';
        input.name = par[0];
        input.value = par[1];
        form.appendChild(input);
      });

    document.body.appendChild(form);
    form.submit();
  };
  img.src = avSelectedBase64;
}
</script>

</body>
</html>
	
