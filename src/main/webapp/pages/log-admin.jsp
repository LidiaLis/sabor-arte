<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Collections,java.net.URLEncoder,java.nio.charset.StandardCharsets,java.text.SimpleDateFormat,java.util.Date,br.com.saborearte.model.Log" %>
<%!
private String h(Object v){if(v==null)return "";return String.valueOf(v).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
private String enc(Object v){return URLEncoder.encode(v==null?"":String.valueOf(v),StandardCharsets.UTF_8);}

/* Iniciais para o avatar do usuário (ex.: "Ana Silva" -> "AS") */
private String iniciais(String nome){
  if(nome==null||nome.trim().isEmpty())return "?";
  String[] partes=nome.trim().split("\\s+");
  StringBuilder sb=new StringBuilder();
  sb.append(Character.toUpperCase(partes[0].charAt(0)));
  if(partes.length>1)sb.append(Character.toUpperCase(partes[partes.length-1].charAt(0)));
  return sb.toString();
}

/* Classe de cor do avatar, coerente com o perfil do usuário */
private String avatarClasse(String tipoUsuario){
  String t=tipoUsuario==null?"":tipoUsuario.toLowerCase();
  if("admin".equals(t))return "av-green";
  if("editor".equals(t))return "av-pink";
  if("autor".equals(t))return "av-gold";
  return "av-blue";
}

/* Classe do "pill" de ação, coerente com o padrão visual (criacao/edicao/exclusao/login/aprovado) */
private String pillAcao(String acao){
  String a=acao==null?"":acao.toUpperCase();
  if(a.contains("APROVAR"))return "aprovado";
  if(a.contains("REJEITAR")||a.contains("EXCLUIR")||a.contains("REMOVER"))return "exclusao";
  if(a.contains("LOGIN"))return "login";
  if(a.contains("CRIAR"))return "criacao";
  return "edicao";
}

/* Separa "data hora" (quando vierem juntos no mesmo campo) para exibição em duas linhas */
private String[] dataHora(String dataLog){
  if(dataLog==null)return new String[]{"",""};
  String s=dataLog.trim();
  int idx=s.indexOf(' ');
  if(idx<0)return new String[]{s,""};
  return new String[]{s.substring(0,idx),s.substring(idx+1)};
}
%>
<%--
    SERVLET RESPONSÁVEL: LogController
    A partir de agora a PAGINAÇÃO é feita em client-side (mesmo padrão usado
    em usuarios.jsp: 8 registros por página, navegação sem reload).
    Por isso o servlet deve trazer em "logs" TODOS os registros que batem
    com os filtros aplicados (busca/acaoLog/entidade/periodo/dataInicio/dataFim),
    sem fatiar por página/offset — a divisão em páginas de 8 é feita pelo JS
    no final do arquivo.
--%>
<%
String ctx=request.getContextPath();
List<Log> logs=(List<Log>)request.getAttribute("logs");if(logs==null)logs=Collections.emptyList();
List<Log> exportLogs=(List<Log>)request.getAttribute("logsExportacao");if(exportLogs==null)exportLogs=Collections.emptyList();
int pageAtual=request.getAttribute("page")instanceof Integer?(Integer)request.getAttribute("page"):1;
int size=request.getAttribute("size")instanceof Integer?(Integer)request.getAttribute("size"):10;
int totalPages=request.getAttribute("totalPages")instanceof Integer?(Integer)request.getAttribute("totalPages"):1;
int total=request.getAttribute("totalLogs")instanceof Integer?(Integer)request.getAttribute("totalLogs"):0;
String busca=h(request.getAttribute("busca")),acao=h(request.getAttribute("acaoLog")),entidade=h(request.getAttribute("entidade")),periodo=h(request.getAttribute("periodo"));
String dataInicio=h(request.getAttribute("dataInicio")),dataFim=h(request.getAttribute("dataFim")),exportTipo=h(request.getAttribute("exportTipo")),erro=h(request.getAttribute("erro"));
String filtros="&size="+size+"&busca="+enc(request.getAttribute("busca"))+"&acaoLog="+enc(request.getAttribute("acaoLog"))+"&entidade="+enc(request.getAttribute("entidade"))+"&periodo="+enc(request.getAttribute("periodo"))+"&dataInicio="+enc(request.getAttribute("dataInicio"))+"&dataFim="+enc(request.getAttribute("dataFim"));

// Marca o item do sidebar como ativo (mesmo padrão usado em usuarios.jsp)
request.setAttribute("currentPage","auditoria");

boolean temFiltroAtivo = !busca.isEmpty() || !acao.isEmpty() || !entidade.isEmpty() || !periodo.isEmpty();
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Auditoria</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-mid:#3d5030;--moss-light:#6b7f59;
    --sage:#a3b18a;--sage-light:#c8d5b9;--cream:#f5f0e8;--cream-dark:#e6dece;
    --warm-white:#faf8f4;--text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;--gold-pale:#f5ead6;
    --pending:#c4832a;--pending-bg:#fdf2e3;--published:#3a7a4a;--published-bg:#e8f4eb;
    --draft:#6a7a8a;--draft-bg:#eef1f4;--sidebar-w:260px;
    --danger:#9b4444;--danger-bg:#fdf0f0;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  /* SIDEBAR — estilos vêm do include sidebar.jsp */

  /* MAIN */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:16px;}

  .content{flex:1;padding:36px 40px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:28px;flex-wrap:wrap;gap:14px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}
  .header-actions{display:flex;align-items:center;gap:10px;flex-wrap:wrap;}

  .btn-primary{display:flex;align-items:center;gap:8px;background:var(--moss);color:var(--cream);padding:10px 20px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s,transform .15s;}
  .btn-primary:hover{background:var(--moss-dark);transform:translateY(-1px);}
  .btn-secondary{display:flex;align-items:center;gap:7px;padding:9px 16px;background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;color:var(--text-mid);cursor:pointer;text-decoration:none;transition:all .15s;}
  .btn-secondary:hover{border-color:var(--moss);color:var(--moss);background:rgba(74,94,58,.05);}

  /* ALERTA DE ERRO */
  .alert-error{display:flex;align-items:center;gap:10px;background:var(--danger-bg);border:1.5px solid rgba(155,68,68,.3);color:var(--danger);border-radius:2px;padding:12px 16px;font-size:13px;font-weight:500;margin-bottom:20px;}

  /* FILTROS */
  .filters-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;margin-bottom:18px;overflow:hidden;}
  .filters-head{padding:9px 18px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .filters-title{font-size:12px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:6px;}
  .filters-badge{font-family:'Nunito',sans-serif;font-size:10px;font-weight:700;color:var(--moss);background:rgba(74,94,58,.1);padding:1px 8px;border-radius:10px;}
  .filters-body{padding:12px 18px;}
  .filters-grid{display:grid;grid-template-columns:2fr repeat(3,1fr);gap:10px;margin-bottom:8px;}
  .filters-grid-dates{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
  .field{margin-bottom:0;}
  .field label{display:block;margin-bottom:3px;font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.6px;color:var(--text-mid);}
  .field input,.field select{width:100%;padding:6px 10px;border:1.5px solid var(--cream-dark);border-radius:2px;background:var(--cream);font-family:'DM Sans',sans-serif;font-size:12px;color:var(--text-dark);outline:none;transition:border-color .2s,box-shadow .2s;}
  .field input:focus,.field select:focus{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,.08);background:var(--warm-white);}
  .field input::placeholder{color:var(--text-light);}
  .filters-footer{padding:10px 18px;border-top:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .filters-actions{display:flex;align-items:center;gap:10px;}
  .export-actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap;}

  /* TABLE */
  .table-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;overflow:hidden;}
  .table-head{padding:16px 24px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .table-title{font-size:14px;font-weight:600;color:var(--text-dark);}
  .table-count{font-family:'Nunito',sans-serif;font-size:12px;color:var(--text-light);font-weight:600;}
  table{width:100%;border-collapse:collapse;}
  thead tr{background:var(--cream);}
  thead th{padding:11px 20px;text-align:left;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);border-bottom:1px solid var(--cream-dark);white-space:nowrap;}
  tbody tr{border-bottom:1px solid var(--cream-dark);transition:background .15s;}
  tbody tr:last-child{border-bottom:none;}
  tbody tr:hover{background:rgba(245,240,232,.5);}
  td{padding:14px 20px;font-size:13px;color:var(--text-dark);vertical-align:middle;}
  td.col-data{font-family:'Nunito',sans-serif;font-size:12px;color:var(--text-mid);font-weight:600;white-space:nowrap;}
  td.col-user{font-weight:500;}
  td.col-desc{color:var(--text-mid);font-weight:300;}
  .role-badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:2px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;}
  .role-admin{background:rgba(74,94,58,.12);color:var(--moss);}
  .role-editor{background:rgba(196,162,101,.15);color:#8a6030;}
  .role-author{background:var(--draft-bg);color:var(--draft);}
  .role-viewer{background:rgba(163,177,138,.2);color:var(--moss-light);}
  .action-badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:2px;font-size:11px;font-weight:600;letter-spacing:.3px;white-space:nowrap;background:var(--draft-bg);color:var(--draft);}
  .action-badge.good{background:var(--published-bg);color:var(--published);}
  .action-badge.warn{background:var(--pending-bg);color:var(--pending);}
  .action-badge.bad{background:var(--danger-bg);color:var(--danger);}
  .action-badge.info{background:rgba(42,114,168,.1);color:#2a72a8;}
  .empty-row td{text-align:center;padding:44px;color:var(--text-light);font-size:13px;font-weight:300;}

  /* PAGINATION */
  .pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--cream-dark);flex-wrap:wrap;gap:10px;}
  .pag-info{font-size:12px;color:var(--text-light);font-weight:300;}
  .pag-btns{display:flex;gap:4px;align-items:center;}
  .pag-btn,.pag-dots{min-width:32px;height:32px;padding:0 8px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:12px;color:var(--text-mid);font-family:'Nunito',sans-serif;font-weight:700;transition:all .15s;text-decoration:none;}
  .pag-btn:hover{border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}
  .pag-dots{border:none;background:none;color:var(--text-light);font-weight:400;}

  .export-table{display:none;}

  @media(max-width:1100px){.filters-grid{grid-template-columns:1fr 1fr;}}
  @media(max-width:768px){.main{margin-left:0;}.content{padding:24px 16px;}.topbar{padding:0 20px;}.filters-grid,.filters-grid-dates{grid-template-columns:1fr;}.pagination{flex-direction:column;align-items:flex-start;}}

  @media print{
    .main{margin-left:0;}
    .topbar,.filters-card,.header-actions,.pagination,.export-actions{display:none!important;}
    .table-card{border:none;}
    .export-table{display:table;}
    .table-card table.screen-table{display:none;}
  }
</style>
</head>
<body>
<%@ include file="includes/sidebar.jsp" %>
<!-- ======= MAIN ======= -->
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Administração</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Auditoria</span>
    </div>
    <div class="topbar-right"></div>
  </div>

  <div class="content">

    <% if (!erro.isEmpty()) { %>
      <div class="alert-error">⚠️ <%=erro%></div>
    <% } %>

    <div class="section-header">
      <div>
        <div class="section-title">Log de <em>Auditoria</em></div>
        <div class="section-date">Consulta administrativa, paginada e somente leitura</div>
      </div>
      <div class="header-actions">
        <a class="btn-secondary" href="<%=ctx%>/LogController?export=pdf<%=filtros%>">📄 Exportar PDF</a>
        <a class="btn-secondary" href="<%=ctx%>/LogController?export=excel<%=filtros%>">📊 Exportar Excel</a>
        <a class="btn-secondary" href="<%=ctx%>/LogController?export=print<%=filtros%>">🖨️ Imprimir</a>
      </div>
    </div>

    <%-- ===== FILTROS ===== --%>
    <section class="filters-card">
      <form method="get" action="<%=ctx%>/LogController">
        <div class="filters-head">
          <div class="filters-title">🔍 Filtros
            <% if (temFiltroAtivo) { %><span class="filters-badge">ativos</span><% } %>
          </div>
        </div>
        <div class="filters-body">
          <div class="filters-grid">
            <div class="field">
              <label>Pesquisar</label>
              <input type="text" name="busca" maxlength="100" value="<%=busca%>" placeholder="Usuário ou descrição">
            </div>
            <div class="field">
              <label>Ação</label>
              <select name="acaoLog">
                <option value="">Todas</option>
                <% String[] as={"CRIAR_RASCUNHO","ENVIAR_REVISAO","APROVAR_RECEITA","REJEITAR_RECEITA","ALTERAR_ATIVIDADE","COMENTAR","RESPONDER_COMENTARIO","MODERAR_COMENTARIO","LOGIN"};
                   for (String a : as) { %>
                  <option value="<%=a%>" <%=a.equals(acao)?"selected":""%>><%=a%></option>
                <% } %>
              </select>
            </div>
            <div class="field">
              <label>Entidade</label>
              <select name="entidade">
                <option value="">Todas</option>
                <% String[] es={"RECEITA","COMENTARIO","USUARIO","RELATORIO","SESSAO"};
                   for (String e : es) { %>
                  <option value="<%=e%>" <%=e.equals(entidade)?"selected":""%>><%=e%></option>
                <% } %>
              </select>
            </div>
            <div class="field">
              <label>Período</label>
              <select name="periodo">
                <option value="">Todos</option>
                <option value="hoje" <%="hoje".equals(periodo)?"selected":""%>>Hoje</option>
                <option value="7dias" <%="7dias".equals(periodo)?"selected":""%>>7 dias</option>
                <option value="30dias" <%="30dias".equals(periodo)?"selected":""%>>30 dias</option>
                <option value="personalizado" <%="personalizado".equals(periodo)?"selected":""%>>Personalizado</option>
              </select>
            </div>
          </div>
          <div class="filters-grid-dates">
            <div class="field">
              <label>Início</label>
              <input type="date" name="dataInicio" value="<%=dataInicio%>">
            </div>
            <div class="field">
              <label>Fim</label>
              <input type="date" name="dataFim" value="<%=dataFim%>">
            </div>
          </div>
        </div>
        <div class="filters-footer">
          <div class="filters-actions">
            <button class="btn-primary" type="submit">🔍 Aplicar filtros</button>
            <a class="btn-secondary" href="<%=ctx%>/LogController">Limpar</a>
          </div>
        </div>
      </form>
    </section>

    <%-- ===== TABELA ===== --%>
    <div class="table-card">
      <div class="table-head">
        <div class="table-title">📋 Registros de Auditoria</div>
        <div class="table-count"><%=total%> registro(s)</div>
      </div>

      <table class="screen-table">
        <thead>
          <tr>
            <th>Data</th>
            <th>Usuário</th>
            <th>Perfil</th>
            <th>Ação</th>
            <th>Entidade</th>
            <th>Descrição</th>
          </tr>
        </thead>
        <tbody>
          <% if (logs.isEmpty()) { %>
            <tr class="empty-row"><td colspan="6">Nenhum registro encontrado.</td></tr>
          <% } else {
               for (Log l : logs) {
                 String tipoUsr = l.getTipo_usuario() == null ? "" : String.valueOf(l.getTipo_usuario()).toLowerCase();
                 String perfilCss = "admin".equals(tipoUsr) ? "role-admin"
                                   : "editor".equals(tipoUsr) ? "role-editor"
                                   : "autor".equals(tipoUsr)  ? "role-author"
                                   : "role-viewer";

                 String acaoLogStr = l.getAcao_log() == null ? "" : String.valueOf(l.getAcao_log());
                 String acaoCss = acaoLogStr.contains("APROVAR") ? "good"
                                 : acaoLogStr.contains("REJEITAR") ? "bad"
                                 : acaoLogStr.contains("LOGIN") ? "info"
                                 : (acaoLogStr.contains("REVISAO") || acaoLogStr.contains("MODERAR")) ? "warn"
                                 : "";
          %>
            <tr>
              <td class="col-data"><%=h(l.getData_log())%></td>
              <td class="col-user"><%=h(l.getNome_usuario())%></td>
              <td><span class="role-badge <%=perfilCss%>"><%=h(l.getTipo_usuario())%></span></td>
              <td><span class="action-badge <%=acaoCss%>"><%=h(l.getAcao_log())%></span></td>
              <td><%=h(l.getEntidade_log())%></td>
              <td class="col-desc"><%=h(l.getDetalhe_log())%></td>
            </tr>
          <%   }
             } %>
        </tbody>
      </table>

      <div class="pagination">
        <span class="pag-info"><%=total%> registro(s) · página <%=pageAtual%> de <%=totalPages%></span>
        <div class="pag-btns">
          <% if (pageAtual > 1) { %>
            <a class="pag-btn" href="<%=ctx%>/LogController?page=<%=pageAtual-1%><%=filtros%>">‹</a>
          <% }
             int pi = Math.max(1, pageAtual - 2), pf = Math.min(totalPages, pageAtual + 2);
             if (pi > 1) { %>
            <a class="pag-btn" href="<%=ctx%>/LogController?page=1<%=filtros%>">1</a>
            <span class="pag-dots">…</span>
          <% }
             for (int p = pi; p <= pf; p++) {
               if (p == pageAtual) { %>
                 <span class="pag-btn active"><%=p%></span>
          <%   } else { %>
                 <a class="pag-btn" href="<%=ctx%>/LogController?page=<%=p%><%=filtros%>"><%=p%></a>
          <%   }
             }
             if (pf < totalPages) { %>
            <span class="pag-dots">…</span>
            <a class="pag-btn" href="<%=ctx%>/LogController?page=<%=totalPages%><%=filtros%>"><%=totalPages%></a>
          <% }
             if (pageAtual < totalPages) { %>
            <a class="pag-btn" href="<%=ctx%>/LogController?page=<%=pageAtual+1%><%=filtros%>">›</a>
          <% } %>
        </div>
      </div>
    </div>

  </div>
</main>

<table id="exportData" class="export-table">
  <thead>
    <tr><th>Data</th><th>Usuário</th><th>Perfil</th><th>Ação</th><th>Entidade</th><th>Descrição</th></tr>
  </thead>
  <tbody>
    <% for (Log l : exportLogs) { %>
      <tr>
        <td><%=h(l.getData_log())%></td>
        <td><%=h(l.getNome_usuario())%></td>
        <td><%=h(l.getTipo_usuario())%></td>
        <td><%=h(l.getAcao_log())%></td>
        <td><%=h(l.getEntidade_log())%></td>
        <td><%=h(l.getDetalhe_log())%></td>
      </tr>
    <% } %>
  </tbody>
</table>

<script>
const exportType = '<%=exportTipo%>';
if (exportType === 'print') window.print();
if (exportType === 'excel') {
  const safe = v => /^[=+\-@]/.test(v) ? "'" + v : v;
  const rows = [...document.querySelectorAll('#exportData tr')]
    .map(r => [...r.cells].map(c => '"' + safe(c.innerText).replaceAll('"', '""') + '"').join(';'))
    .join('\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob(['\ufeff' + rows], { type: 'text/csv' }));
  a.download = 'auditoria.csv';
  a.click();
}
if (exportType === 'pdf') window.print();
</script>
</body>
</html>
