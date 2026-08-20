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
int total=request.getAttribute("totalLogs")instanceof Integer?(Integer)request.getAttribute("totalLogs"):logs.size();
String busca=h(request.getAttribute("busca")),acao=h(request.getAttribute("acaoLog")),entidade=h(request.getAttribute("entidade")),periodo=h(request.getAttribute("periodo"));
String dataInicio=h(request.getAttribute("dataInicio")),dataFim=h(request.getAttribute("dataFim")),exportTipo=h(request.getAttribute("exportTipo")),erro=h(request.getAttribute("erro"));
String filtros="&busca="+enc(request.getAttribute("busca"))+"&acaoLog="+enc(request.getAttribute("acaoLog"))+"&entidade="+enc(request.getAttribute("entidade"))+"&periodo="+enc(request.getAttribute("periodo"))+"&dataInicio="+enc(request.getAttribute("dataInicio"))+"&dataFim="+enc(request.getAttribute("dataFim"));

// Marca o item do sidebar como ativo (mesmo padrão usado em usuarios.jsp)
request.setAttribute("currentPage","auditoria");

boolean temFiltroAtivo = !busca.isEmpty() || !acao.isEmpty() || !entidade.isEmpty() || !periodo.isEmpty();
String emitidoEm=new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date());
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Logs de Auditoria</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,500&family=DM+Sans:wght@300;400;500;600&family=Nunito:wght@600;700;800&display=swap" rel="stylesheet">
<style>
  :root {
    --moss:#4a5e3a;--moss-dark:#2f3d25;--moss-light:#6b7f59;--sage:#a3b18a;--sage-light:#c8d5b9;
    --cream:#f5f0e8;--cream-dark:#e6dece;--warm-white:#faf8f4;
    --text-dark:#1e2718;--text-mid:#4a5240;--text-light:#8a9480;
    --gold:#c4a265;--gold-light:#dfc094;
    --published:#3a7a4a;--published-bg:#e8f4eb;
    --pending:#c4832a;--pending-bg:#fdf2e3;
    --draft:#6a7a8a;--draft-bg:#eef1f4;
    --error:#9b4444;--error-bg:#fdf0f0;
    --sidebar-w:260px;
  }
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--text-dark);min-height:100vh;display:flex;}

  /* SIDEBAR — estilos vêm do include sidebar.jsp */

  /* MAIN */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .topbar-left{display:flex;align-items:center;gap:14px;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:10px;}

  .btn{display:inline-flex;align-items:center;gap:7px;padding:8px 16px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;cursor:pointer;transition:all 0.2s;white-space:nowrap;text-decoration:none;}
  .btn:hover{transform:translateY(-1px);box-shadow:0 3px 10px rgba(0,0,0,0.12);}
  .btn-pdf{background:#fdeaea;color:var(--error);}
  .btn-excel{background:var(--published-bg);color:var(--published);}
  .btn-print{background:var(--draft-bg);color:var(--draft);}

  .content{flex:1;padding:32px 40px;}
  .page-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:24px;flex-wrap:wrap;gap:14px;}
  .page-title-main{font-family:'Playfair Display',serif;font-size:26px;font-weight:500;color:var(--text-dark);line-height:1;}
  .page-title-main em{font-style:italic;color:var(--moss);}
  .page-subtitle{font-size:13px;color:var(--text-light);font-weight:300;margin-top:5px;}

  /* ALERTA DE ERRO */
  .feedback-bar{display:flex;align-items:center;gap:8px;background:var(--error-bg);border:1.5px solid rgba(155,68,68,.3);color:var(--error);border-radius:2px;padding:12px 16px;font-size:13px;font-weight:600;margin-bottom:18px;}

  /* LAYOUT AUDITORIA */
  .audit-layout{display:grid;grid-template-columns:240px 1fr;gap:18px;align-items:start;}
  .left-panel{position:sticky;top:80px;}
  .panel-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .panel-head{padding:13px 18px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:1.2px;}
  .filters-badge{font-family:'Nunito',sans-serif;font-size:9px;font-weight:800;color:var(--moss);background:rgba(74,94,58,.12);padding:2px 8px;border-radius:10px;letter-spacing:.4px;text-transform:none;}
  .panel-body{padding:14px 16px;}
  .fgroup{margin-bottom:11px;}
  .fgroup:last-child{margin-bottom:0;}
  .flabel{display:block;font-size:10px;font-weight:700;color:var(--text-light);text-transform:uppercase;letter-spacing:0.9px;margin-bottom:5px;}
  .finput,.fselect{width:100%;padding:8px 10px;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;color:var(--text-dark);background:var(--cream);outline:none;transition:border-color 0.18s,box-shadow 0.18s;}
  .finput:focus,.fselect:focus{border-color:var(--moss);background:var(--warm-white);box-shadow:0 0 0 3px rgba(74,94,58,0.07);}
  .search-wrap{position:relative;}
  .search-wrap .search-icon{position:absolute;left:9px;top:50%;transform:translateY(-50%);color:var(--text-light);font-size:13px;pointer-events:none;}
  .search-wrap .finput{padding-left:29px;}
  .btn-apply{width:100%;padding:9px 10px;background:var(--moss);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;font-weight:600;color:var(--cream);cursor:pointer;margin-top:2px;transition:all 0.15s;}
  .btn-apply:hover{background:var(--moss-dark);}
  .btn-clear{width:100%;padding:8px 10px;background:var(--cream-dark);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:11px;font-weight:600;color:var(--text-mid);cursor:pointer;margin-top:8px;transition:all 0.15s;text-align:center;display:block;text-decoration:none;}
  .btn-clear:hover{background:var(--sage-light);color:var(--moss-dark);}

  .right-panel{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:4px;overflow:hidden;}
  .result-head{padding:14px 20px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
  .result-title{font-size:15px;font-weight:600;color:var(--text-dark);display:flex;align-items:center;gap:8px;}
  .row-count-badge{font-family:'Nunito',sans-serif;font-size:11px;font-weight:700;background:var(--cream-dark);color:var(--text-light);padding:2px 10px;border-radius:10px;}

  .table-wrap{overflow-x:auto;}
  .log-table{width:100%;border-collapse:collapse;font-size:12px;}
  .log-table thead th{padding:10px 14px;text-align:left;background:var(--cream);border-bottom:2px solid var(--cream-dark);font-size:9px;text-transform:uppercase;letter-spacing:1.1px;color:var(--text-light);font-weight:700;white-space:nowrap;}
  .log-table tbody tr{border-bottom:1px solid var(--cream-dark);transition:background 0.1s;}
  .log-table tbody tr:last-child{border-bottom:none;}
  .log-table tbody tr:hover{background:rgba(245,240,232,0.7);}
  .log-table td{padding:12px 14px;vertical-align:middle;color:var(--text-mid);}

  .user-cell{display:flex;align-items:center;gap:9px;}
  .user-av{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:10px;font-weight:800;flex-shrink:0;}
  .av-green{background:rgba(74,94,58,0.15);color:var(--moss);}
  .av-gold{background:rgba(196,162,101,0.2);color:#8a6030;}
  .av-blue{background:rgba(59,107,200,0.12);color:#2a5ab8;}
  .av-pink{background:rgba(180,60,120,0.12);color:#a03070;}
  .av-teal{background:rgba(30,140,110,0.12);color:#1a7a62;}
  .user-nm{font-size:12px;font-weight:600;color:var(--text-dark);line-height:1.2;}
  .user-role-sm{font-size:10px;color:var(--text-light);font-weight:300;}

  .pill{display:inline-flex;align-items:center;gap:5px;padding:3px 9px;border-radius:2px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.4px;white-space:nowrap;}
  .pill-dot{width:5px;height:5px;border-radius:50%;background:currentColor;flex-shrink:0;}
  .pill.criacao{background:rgba(74,94,58,0.1);color:var(--moss);}
  .pill.edicao{background:var(--draft-bg);color:var(--draft);}
  .pill.exclusao{background:var(--error-bg);color:var(--error);}
  .pill.login{background:var(--pending-bg);color:var(--pending);}
  .pill.aprovado{background:var(--published-bg);color:var(--published);}
  .pill.entidade{background:#f5f0e8;color:#8a7a6a;font-size:9px;border:1px solid #e6dece;}

  .detail-text{font-size:11px;color:var(--text-mid);line-height:1.4;}
  .time-cell{display:flex;flex-direction:column;gap:2px;}
  .time-date{font-size:11px;font-weight:600;color:var(--text-dark);white-space:nowrap;}
  .time-hour{font-size:10px;color:var(--text-light);font-weight:300;white-space:nowrap;}

  .empty-row td{text-align:center;padding:50px 20px;color:var(--text-light);font-size:13px;font-style:italic;}

  /* PAGINAÇÃO — mesmo padrão de usuarios.jsp (client-side, 8 por página) */
  .pagination{display:flex;align-items:center;justify-content:space-between;padding:12px 20px;border-top:1px solid var(--cream-dark);flex-wrap:wrap;gap:10px;}
  .pag-info{font-size:12px;color:var(--text-light);font-weight:300;}
  .pag-btns{display:flex;gap:4px;flex-wrap:wrap;}
  .pag-btn{min-width:32px;height:32px;padding:0 8px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:12px;cursor:pointer;color:var(--text-mid);font-family:'Nunito',sans-serif;font-weight:700;transition:all .15s;}
  .pag-btn:hover:not(:disabled){border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}
  .pag-btn:disabled{opacity:.4;cursor:not-allowed;}

  .export-table{display:none;}

  @media(max-width:1000px){.audit-layout{grid-template-columns:1fr;}.left-panel{position:static;}}
  @media(max-width:768px){.main{margin-left:0;}.content{padding:20px 16px;}.topbar{padding:0 20px;flex-wrap:wrap;height:auto;padding-top:10px;padding-bottom:10px;}.pagination{flex-direction:column;align-items:flex-start;}}

  /* ---- Impressão (mesmo padrão visual do PDF) ---- */
  .print-header{display:none;}
  @media print{
    .main{margin-left:0;}
    .topbar,.audit-layout .left-panel,.pagination,.feedback-bar{display:none!important;}
    .right-panel{border:none;}
    .print-header{display:block;margin-bottom:10px;}
    .print-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:700;color:var(--moss-dark);}
    .print-subtitle{font-family:'DM Sans',sans-serif;font-size:11px;color:var(--text-mid);margin-top:2px;}
    .print-meta{font-family:'DM Sans',sans-serif;font-size:9px;color:var(--text-light);margin-top:2px;margin-bottom:14px;}
    .table-card{border:none;}
    .export-table{display:table;width:100%;border-collapse:collapse;font-size:10px;font-family:'DM Sans',sans-serif;}
    .export-table th{background:var(--moss-dark);color:#fff;text-align:left;padding:7px 8px;font-size:9px;text-transform:uppercase;letter-spacing:0.6px;font-weight:700;border:1px solid var(--moss-dark);}
    .export-table td{padding:6px 8px;border:1px solid #ddd;color:var(--text-dark);vertical-align:top;}
    .export-table tbody tr:nth-child(even){background:#f5f0e8;}
    .log-table{display:none;}
  }
</style>
</head>
<body>
<%@ include file="includes/sidebar.jsp" %>
<!-- ======= MAIN ======= -->
<main class="main">
  <div class="topbar">
    <div class="topbar-left">
      <div class="page-crumb">
        <span>Análise</span>
        <span style="color:var(--cream-dark)">/</span>
        <span class="current">Logs de Auditoria</span>
      </div>
    </div>
    <div class="topbar-right">
      <a class="btn btn-pdf" href="<%=ctx%>/LogController?export=pdf<%=filtros%>">⬇ PDF</a>
      <a class="btn btn-excel" href="<%=ctx%>/LogController?export=excel<%=filtros%>">⬇ Excel</a>
      <a class="btn btn-print" href="<%=ctx%>/LogController?export=print<%=filtros%>">🖨 Imprimir</a>
    </div>
  </div>

  <div class="content">

    <div class="page-header">
      <div>
        <div class="page-title-main">Logs de <em>Auditoria</em></div>
        <div class="page-subtitle">Rastreamento completo de todas as ações realizadas no sistema editorial</div>
      </div>
    </div>

    <% if (!erro.isEmpty()) { %>
      <div class="feedback-bar">⚠️ <%=erro%></div>
    <% } %>

    <div class="audit-layout">

      <%-- ===== FILTROS ===== --%>
      <div class="left-panel">
        <form method="get" action="<%=ctx%>/LogController">
          <div class="panel-card">
            <div class="panel-head">
              Filtros
              <% if (temFiltroAtivo) { %><span class="filters-badge">ativos</span><% } %>
            </div>
            <div class="panel-body">
              <div class="fgroup">
                <label class="flabel">Buscar usuário ou detalhe</label>
                <div class="search-wrap">
                  <span class="search-icon">🔍</span>
                  <input type="text" class="finput" name="busca" maxlength="100" value="<%=busca%>" placeholder="Nome, palavra-chave…">
                </div>
              </div>
              <div class="fgroup">
                <label class="flabel">Ação</label>
                <select class="fselect" name="acaoLog">
                  <option value="">Todas</option>
                  <% String[] as={"CRIAR_RASCUNHO","ENVIAR_REVISAO","APROVAR_RECEITA","REJEITAR_RECEITA","ALTERAR_ATIVIDADE","COMENTAR","RESPONDER_COMENTARIO","MODERAR_COMENTARIO","LOGIN"};
                     for (String a : as) { %>
                    <option value="<%=a%>" <%=a.equals(acao)?"selected":""%>><%=a%></option>
                  <% } %>
                </select>
              </div>
              <div class="fgroup">
                <label class="flabel">Entidade</label>
                <select class="fselect" name="entidade">
                  <option value="">Todas</option>
                  <% String[] es={"RECEITA","COMENTARIO","USUARIO","RELATORIO","SESSAO"};
                     for (String e : es) { %>
                    <option value="<%=e%>" <%=e.equals(entidade)?"selected":""%>><%=e%></option>
                  <% } %>
                </select>
              </div>
              <div class="fgroup">
                <label class="flabel">Período</label>
                <select class="fselect" name="periodo">
                  <option value="">Todos os períodos</option>
                  <option value="hoje" <%="hoje".equals(periodo)?"selected":""%>>Hoje</option>
                  <option value="7dias" <%="7dias".equals(periodo)?"selected":""%>>Últimos 7 dias</option>
                  <option value="30dias" <%="30dias".equals(periodo)?"selected":""%>>Último mês</option>
                  <option value="personalizado" <%="personalizado".equals(periodo)?"selected":""%>>Personalizado</option>
                </select>
              </div>
              <div class="fgroup">
                <label class="flabel">Início</label>
                <input type="date" class="finput" name="dataInicio" value="<%=dataInicio%>">
              </div>
              <div class="fgroup">
                <label class="flabel">Fim</label>
                <input type="date" class="finput" name="dataFim" value="<%=dataFim%>">
              </div>
              <div class="fgroup">
                <button class="btn-apply" type="submit">Aplicar filtros</button>
                <a class="btn-clear" href="<%=ctx%>/LogController">Limpar filtros</a>
              </div>
            </div>
          </div>
        </form>
      </div>

      <%-- ===== TABELA ===== --%>
      <div class="right-panel">
        <div class="result-head">
          <div class="result-title">
            Registro de Ações
            <span class="row-count-badge" id="rowCount"><%=total%></span>
          </div>
        </div>

        <div class="print-header">
          <div class="print-title">Sabor &amp; Arte — Blog Editorial</div>
          <div class="print-subtitle">Logs de Auditoria do Sistema</div>
          <div class="print-meta">Emitido em: <%=emitidoEm%> · <%=total%> registro(s) filtrado(s)</div>
        </div>

        <div class="table-wrap">
          <table class="log-table">
            <thead>
              <tr>
                <th>Usuário</th>
                <th>Ação</th>
                <th>Entidade</th>
                <th>Detalhe</th>
                <th>Data / Hora</th>
              </tr>
            </thead>
            <tbody id="logsBody">
              <% if (logs.isEmpty()) { %>
                <tr class="empty-row"><td colspan="5">Nenhum registro encontrado para os filtros aplicados.</td></tr>
              <% } else {
                   for (Log l : logs) {
                     String nome = l.getNome_usuario()==null? "" : String.valueOf(l.getNome_usuario());
                     String tipoUsr = l.getTipo_usuario() == null ? "" : String.valueOf(l.getTipo_usuario());
                     String[] dh = dataHora(l.getData_log()==null?"":String.valueOf(l.getData_log()));
              %>
                <tr>
                  <td>
                    <div class="user-cell">
                      <div class="user-av <%=avatarClasse(tipoUsr)%>"><%=h(iniciais(nome))%></div>
                      <div>
                        <div class="user-nm"><%=h(nome)%></div>
                        <div class="user-role-sm"><%=h(tipoUsr)%></div>
                      </div>
                    </div>
                  </td>
                  <td><span class="pill <%=pillAcao(String.valueOf(l.getAcao_log()))%>"><span class="pill-dot"></span><%=h(l.getAcao_log())%></span></td>
                  <td><span class="pill entidade"><%=h(l.getEntidade_log())%></span></td>
                  <td><div class="detail-text"><%=h(l.getDetalhe_log())%></div></td>
                  <td>
                    <div class="time-cell">
                      <span class="time-date"><%=h(dh[0])%></span>
                      <% if (!dh[1].isEmpty()) { %><span class="time-hour"><%=h(dh[1])%></span><% } %>
                    </div>
                  </td>
                </tr>
              <%   }
                 } %>
            </tbody>
          </table>
        </div>

        <div class="pagination" id="pagination">
          <div class="pag-info" id="pagInfo">—</div>
          <div class="pag-btns" id="pagBtns"></div>
        </div>
      </div>

    </div>
  </div>
</main>

<table id="exportData" class="export-table">
  <thead>
    <tr><th>Usuário</th><th>Perfil</th><th>Ação</th><th>Entidade</th><th>Detalhe</th><th>Data</th></tr>
  </thead>
  <tbody>
    <% for (Log l : exportLogs) { %>
      <tr>
        <td><%=h(l.getNome_usuario())%></td>
        <td><%=h(l.getTipo_usuario())%></td>
        <td><%=h(l.getAcao_log())%></td>
        <td><%=h(l.getEntidade_log())%></td>
        <td><%=h(l.getDetalhe_log())%></td>
        <td><%=h(l.getData_log())%></td>
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

<script>
/* ─────────────────────────────────────────
   PAGINAÇÃO CLIENT-SIDE (mesmo padrão de usuarios.jsp)
   Fatiar as <tr> já renderizadas pelo servidor,
   8 registros por página, sem recarregar a página.
───────────────────────────────────────── */
var PAGE_SIZE = 8;      // registros por página
var paginaAtual = 1;
var todasLinhasLog = Array.from(document.querySelectorAll('#logsBody tr')).filter(function(row){
  return !row.classList.contains('empty-row');
});

function renderPaginaLog() {
  var total = todasLinhasLog.length;
  var totalPaginas = Math.max(1, Math.ceil(total / PAGE_SIZE));

  if (paginaAtual > totalPaginas) paginaAtual = totalPaginas;
  if (paginaAtual < 1) paginaAtual = 1;

  // esconde todas, mostra só a "fatia" da página atual
  todasLinhasLog.forEach(function(row) { row.style.display = 'none'; });

  var inicio = (paginaAtual - 1) * PAGE_SIZE;
  var fim = inicio + PAGE_SIZE;
  todasLinhasLog.slice(inicio, fim).forEach(function(row) { row.style.display = ''; });

  var rowCount = document.getElementById('rowCount');
  if (rowCount) rowCount.textContent = total;

  renderInfoLog(total, inicio, fim);
  renderBotoesLog(totalPaginas);
}

function renderInfoLog(total, inicio, fim) {
  var info = document.getElementById('pagInfo');
  if (total === 0) {
    info.textContent = 'Nenhum registro encontrado';
    return;
  }
  var mostrandoAte = Math.min(fim, total);
  info.textContent = 'Mostrando ' + (inicio + 1) + '–' + mostrandoAte + ' de ' + total;
}

function renderBotoesLog(totalPaginas) {
  var wrap = document.getElementById('pagBtns');
  wrap.innerHTML = '';

  function criarBtn(label, page, opts) {
    opts = opts || {};
    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'pag-btn' + (opts.active ? ' active' : '');
    b.textContent = label;
    if (opts.disabled) b.disabled = true;
    b.addEventListener('click', function() {
      paginaAtual = page;
      renderPaginaLog();
    });
    wrap.appendChild(b);
  }

  criarBtn('‹', paginaAtual - 1, { disabled: paginaAtual === 1 });

  for (var p = 1; p <= totalPaginas; p++) {
    criarBtn(String(p), p, { active: p === paginaAtual });
  }

  criarBtn('›', paginaAtual + 1, { disabled: paginaAtual === totalPaginas });
}

document.addEventListener('DOMContentLoaded', function() {
  renderPaginaLog();
});
</script>
</body>
</html>
