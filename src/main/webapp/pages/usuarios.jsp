<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="br.com.saborearte.model.Usuario" %>
<%@ page import="java.util.List" %>
<%@ page import=" java.time.LocalDate" %>

<%--
    SERVLET RESPONSÁVEL: UsuarioController
    O servlet deve:
      1. Buscar lista de usuários:  List<Usuario> lista = usuarioDAO.listarTodos();
      2. Fazer:                     request.setAttribute("usuarios", lista);
      3. Fazer:                     request.setAttribute("currentPage", "usuarios");
      4. Fazer:                     request.getRequestDispatcher("/WEB-INF/views/usuarios.jsp").forward(request, response);

    PARÂMETROS DE ACTION QUE O SERVLET PRECISA TRATAR:
      action=adicionar   → salva novo usuário
      action=editar      → atualiza usuário existente
      action=status      → alterna ativo/inativo (NUNCA deleta)
--%>
<%
    /* ── Dados vindos do servlet ── */
    List<Usuario> usuarios = (List<Usuario>) request.getAttribute("usuarios");
    if (usuarios == null) usuarios = new java.util.ArrayList<>();

    /* ── Contagens para os cards de stats ── */
    long totalUsuarios = usuarios.size();
    long totalAtivos = usuarios.stream()
            .filter(u -> "ativo".equalsIgnoreCase(u.getStatus_usuario().toString()))
            .count();
    long totalInativos = totalUsuarios - totalAtivos;

    /* ── Usuário logado (para o topbar) ── */
    Usuario logado = (Usuario) session.getAttribute("usuarioLogado");
    String  nomeLogado = (logado != null) ? logado.getNome_usuario() : "Admin";
    String  iniLogado  = nomeLogado.substring(0, 1).toUpperCase();

    /* ── Mensagem de feedback vinda do servlet após POST ── */
    String msgSucesso = (String) request.getAttribute("msgSucesso");
    String msgErro    = (String) request.getAttribute("msgErro");

    String _ctx = request.getContextPath();
    long novosEsteMes = usuarios.stream()
    	    .filter(u -> u.getData_criacao_usuario() != null &&
    	        u.getData_criacao_usuario().getMonthValue() == java.time.LocalDate.now().getMonthValue() &&
    	        u.getData_criacao_usuario().getYear()        == java.time.LocalDate.now().getYear())
    	    .count();
    	request.setAttribute("novosEsteMes", novosEsteMes);
%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sabor &amp; Arte — Usuários</title>
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

  /* SIDEBAR — estilos vêm do include sidebar-editor-admin.jsp */

  /* MAIN */
  .main{margin-left:var(--sidebar-w);flex:1;min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--warm-white);border-bottom:1px solid var(--cream-dark);padding:0 40px;height:64px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:50;}
  .page-crumb{font-size:12px;color:var(--text-light);display:flex;align-items:center;gap:6px;font-weight:300;}
  .page-crumb .current{color:var(--moss);font-weight:500;}
  .topbar-right{display:flex;align-items:center;gap:16px;}
  .notif-btn{width:36px;height:36px;background:var(--cream);border:1.5px solid var(--cream-dark);border-radius:2px;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;position:relative;transition:all .2s;}
  .notif-btn:hover{background:var(--cream-dark);}
  .notif-dot{position:absolute;top:4px;right:4px;width:8px;height:8px;background:var(--gold);border-radius:50%;border:2px solid var(--warm-white);}

  .content{flex:1;padding:36px 40px;}
  .section-header{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:28px;}
  .section-title{font-family:'Playfair Display',serif;font-size:28px;font-weight:500;color:var(--text-dark);line-height:1;}
  .section-title em{font-style:italic;color:var(--moss);}
  .section-date{font-size:12px;color:var(--text-light);font-weight:300;margin-top:4px;}
  .btn-primary{display:flex;align-items:center;gap:8px;background:var(--moss);color:var(--cream);padding:10px 20px;border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;cursor:pointer;transition:background .2s,transform .15s;}
  .btn-primary:hover{background:var(--moss-dark);transform:translateY(-1px);}

  /* STATS */
  .stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin-bottom:30px;}
  .stat-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;padding:22px 20px;position:relative;overflow:hidden;transition:transform .2s,box-shadow .2s;}
  .stat-card:hover{transform:translateY(-2px);box-shadow:0 8px 24px rgba(47,61,37,.1);}
  .stat-card::before{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
  .stat-card.moss::before{background:linear-gradient(90deg,var(--moss),var(--sage));}
  .stat-card.green::before{background:linear-gradient(90deg,var(--published),#5ab870);}
  .stat-card.pending::before{background:linear-gradient(90deg,var(--pending),#e8a84a);}
  .stat-card.blue::before{background:linear-gradient(90deg,#2a72a8,#5aa0d8);}
  .stat-icon{width:38px;height:38px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:17px;margin-bottom:14px;}
  .stat-card.moss .stat-icon{background:rgba(74,94,58,.1);}
  .stat-card.green .stat-icon{background:rgba(58,122,74,.1);}
  .stat-card.pending .stat-icon{background:rgba(196,131,42,.12);}
  .stat-card.blue .stat-icon{background:rgba(42,114,168,.1);}
  .stat-value{font-family:'Nunito',sans-serif;font-size:38px;font-weight:800;color:var(--text-dark);line-height:1;margin-bottom:4px;letter-spacing:-1px;}
  .stat-label{font-size:12px;color:var(--text-light);text-transform:uppercase;letter-spacing:.8px;font-weight:500;}
  .stat-delta{position:absolute;top:20px;right:16px;font-family:'Nunito',sans-serif;font-size:12px;font-weight:700;}
  .stat-delta.up{color:var(--published);}
  .stat-delta.down{color:#9b4444;}

  /* TOOLBAR */
  .toolbar{display:flex;align-items:center;gap:12px;margin-bottom:20px;flex-wrap:wrap;}
  .filter-select{background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;padding:8px 12px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);cursor:pointer;outline:none;transition:border-color .2s;}
  .filter-select:focus{border-color:var(--moss-light);}
  .search-bar{display:flex;align-items:center;gap:8px;background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;padding:8px 14px;flex:1;max-width:320px;}
  .search-bar:focus-within{border-color:var(--moss-light);}
  .search-bar input{border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;flex:1;}
  .search-bar input::placeholder{color:var(--text-light);}
  .toolbar-spacer{flex:1;}

  /* TABLE */
  .table-card{background:var(--warm-white);border:1px solid var(--cream-dark);border-radius:2px;overflow:hidden;}
  .table-head{padding:16px 24px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .table-title{font-size:14px;font-weight:600;color:var(--text-dark);}
  .table-count{font-family:'Nunito',sans-serif;font-size:12px;color:var(--text-light);font-weight:600;}
  table{width:100%;border-collapse:collapse;}
  thead tr{background:var(--cream);}
  thead th{padding:11px 20px;text-align:left;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.8px;color:var(--text-light);border-bottom:1px solid var(--cream-dark);white-space:nowrap;}
  thead th.sort{cursor:pointer;}
  thead th.sort:hover{color:var(--moss);}
  tbody tr{border-bottom:1px solid var(--cream-dark);transition:background .15s;}
  tbody tr:last-child{border-bottom:none;}
  tbody tr:hover{background:rgba(245,240,232,.5);}
  tbody tr.row-inactive{opacity:.6;}
  td{padding:14px 20px;font-size:13px;color:var(--text-dark);vertical-align:middle;}
  .user-cell{display:flex;align-items:center;gap:12px;}
  .u-avatar{width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:12px;font-weight:800;color:#fff;flex-shrink:0;}
  .u-name{font-size:13px;font-weight:500;color:var(--text-dark);}
  .u-email{font-size:11px;color:var(--text-light);font-weight:300;}
  .role-badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:2px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;}
  .role-admin{background:rgba(74,94,58,.12);color:var(--moss);}
  .role-editor{background:rgba(196,162,101,.15);color:#8a6030;}
  .role-author{background:var(--draft-bg);color:var(--draft);}
  .role-viewer{background:rgba(163,177,138,.2);color:var(--moss-light);}
  .status-dot{display:inline-flex;align-items:center;gap:6px;font-size:12px;}
  .dot{width:7px;height:7px;border-radius:50%;flex-shrink:0;}
  .dot.active{background:var(--published);}
  .dot.inactive{background:var(--text-light);}
  .recipes-count{font-family:'Nunito',sans-serif;font-size:14px;font-weight:700;color:var(--text-dark);}
  .recipes-count span{font-size:11px;font-weight:400;color:var(--text-light);}
  .action-group{display:flex;align-items:center;gap:6px;}
  .act-btn{width:30px;height:30px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:13px;cursor:pointer;transition:all .15s;}
  .act-btn:hover{border-color:var(--moss);background:rgba(74,94,58,.05);}
  .act-btn.danger:hover{border-color:var(--danger);background:var(--danger-bg);}
  .act-btn.reactivate:hover{border-color:var(--published);background:var(--published-bg);}

  /* PAGINATION */
  .pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--cream-dark);}
  .pag-info{font-size:12px;color:var(--text-light);font-weight:300;}
  .pag-btns{display:flex;gap:4px;}
  .pag-btn{width:32px;height:32px;border:1.5px solid var(--cream-dark);background:var(--warm-white);border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:12px;cursor:pointer;color:var(--text-mid);font-family:'Nunito',sans-serif;font-weight:700;transition:all .15s;}
  .pag-btn:hover{border-color:var(--moss);color:var(--moss);}
  .pag-btn.active{background:var(--moss);border-color:var(--moss);color:var(--cream);}

  /* FEEDBACK TOAST */
  .toast{position:fixed;bottom:28px;left:50%;transform:translateX(-50%) translateY(8px);background:var(--moss-dark);color:var(--cream);padding:11px 22px;border-radius:3px;font-size:13px;font-weight:500;opacity:0;visibility:hidden;transition:all .25s;z-index:2000;display:flex;align-items:center;gap:8px;}
  .toast.show{opacity:1;visibility:visible;transform:translateX(-50%) translateY(0);}
  .toast.error{background:var(--danger);}

  /* MODAIS */
  .avatar-modal-box {
  background: var(--warm-white); border-radius: 6px;
  width: 100%; max-width: 480px;
  box-shadow: 0 12px 48px rgba(0,0,0,0.25);
  animation: slideUp .22s ease;
  overflow: hidden; text-align: left; padding: 0; z-index: 2000; 
}
.avatar-modal-header {
  background: linear-gradient(135deg, var(--moss-dark), var(--moss));
  padding: 18px 24px; display: flex; align-items: center; justify-content: space-between;
}
.avatar-modal-title { color: white; font-size: 15px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
.avatar-modal-close {
  background: rgba(255,255,255,0.15); border: none; border-radius: 50%;
  width: 30px; height: 30px; color: white; font-size: 18px; cursor: pointer;
  display: flex; align-items: center; justify-content: center; transition: background .2s;
}
.avatar-modal-close:hover { background: rgba(255,255,255,0.28); }
.avatar-modal-body { padding: 24px; }
.avatar-modal-footer { padding: 16px 24px; border-top: 1px solid var(--cream-dark); display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.avatar-preview-area { display: flex; flex-direction: column; align-items: center; gap: 10px; margin-bottom: 20px; }
.avatar-preview-ring {
  width: 96px; height: 96px; border-radius: 50%;
  background: linear-gradient(135deg, var(--gold), var(--gold-light));
  display: flex; align-items: center; justify-content: center;
  font-family: 'Nunito', sans-serif; font-size: 36px; font-weight: 800; color: var(--moss-dark);
  border: 4px solid var(--sage-light); overflow: hidden; position: relative; transition: border-color .25s;
}
.avatar-preview-ring.has-img { border-color: var(--moss); }
.avatar-preview-ring img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; display: none; }
.avatar-preview-ring img.visible { display: block; }
.avatar-preview-lbl { font-size: 12px; color: var(--text-light); }
.drop-zone {
  border: 2px dashed var(--cream-dark); border-radius: 6px;
  padding: 24px 20px; text-align: center; cursor: pointer;
  background: var(--cream); position: relative; transition: all .2s;
}
.drop-zone:hover, .drop-zone.drag-over { border-color: var(--moss); background: rgba(74,94,58,0.04); }
.drop-zone input[type="file"] { position: absolute; inset: 0; opacity: 0; cursor: pointer; }
.drop-icon { font-size: 28px; margin-bottom: 8px; display: block; }
.drop-title { font-size: 14px; font-weight: 600; color: var(--text-dark); margin-bottom: 4px; }
.drop-sub { font-size: 12px; color: var(--text-light); }
.drop-sub span { color: var(--moss); font-weight: 500; cursor: pointer; }
.file-info-bar {
  display: none; background: rgba(74,94,58,.08); border: 1.5px solid rgba(74,94,58,.22);
  border-radius: 4px; padding: 10px 14px; margin-top: 10px; align-items: center; gap: 10px;
}
.file-info-bar.show { display: flex; }
.file-info-name { font-size: 13px; color: var(--moss); font-weight: 500; flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.file-info-size { font-size: 11px; color: var(--text-light); flex-shrink: 0; }
.file-info-rm { background: none; border: none; color: var(--danger); font-size: 18px; cursor: pointer; }
.av-error { display: none; font-size: 12px; color: var(--danger); margin-top: 8px; }
.av-error.show { display: block; }
.av-success {
  display: none; background: var(--published-bg); border: 1.5px solid #7fc98a;
  border-radius: 4px; padding: 10px 14px; font-size: 13px; color: var(--published);
  font-weight: 500; align-items: center; gap: 8px; margin-bottom: 14px;
}
.av-success.show { display: flex; }
  
  .modal-overlay{position:fixed;inset:0;background:rgba(30,39,24,.55);backdrop-filter:blur(3px);display:none;align-items:center;justify-content:center;z-index:1000;padding:24px;animation:fadeIn .18s ease;}
  .modal-overlay.open{display:flex;}
  #avatarModal { z-index: 2000; }
  
  @keyframes fadeIn{from{opacity:0}to{opacity:1}}
  @keyframes slideUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
  .modal-box{background:var(--warm-white);border-radius:2px;width:100%;max-width:500px;max-height:90vh;overflow-y:auto;box-shadow:0 24px 64px rgba(30,39,24,.28),0 4px 16px rgba(30,39,24,.1);animation:slideUp .22s ease;border:1px solid var(--cream-dark);}
  .modal-header{padding:22px 26px 18px;border-bottom:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:space-between;}
  .modal-header-left{display:flex;align-items:center;gap:14px;}
  .modal-header-icon{width:42px;height:42px;border-radius:2px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;}
  .modal-header-icon.add-icon{background:rgba(74,94,58,.1);}
  .modal-header-icon.edit-icon{background:rgba(196,162,101,.12);}
  .modal-header-icon.deactivate-icon{background:rgba(155,68,68,.1);}
  .modal-header-icon.reactivate-icon{background:rgba(58,122,74,.1);}
  .modal-title{font-family:'Playfair Display',serif;font-size:18px;font-weight:500;color:var(--text-dark);line-height:1.2;}
  .modal-subtitle{font-size:12px;color:var(--text-light);font-weight:300;margin-top:3px;}
  .modal-close{width:32px;height:32px;border:1.5px solid var(--cream-dark);background:none;border-radius:2px;cursor:pointer;font-size:16px;color:var(--text-light);display:flex;align-items:center;justify-content:center;transition:all .15s;flex-shrink:0;}
  .modal-close:hover{border-color:var(--danger);color:var(--danger);background:var(--danger-bg);}
  .modal-body{padding:22px 26px;}
  .modal-footer{padding:16px 26px 22px;border-top:1px solid var(--cream-dark);display:flex;align-items:center;justify-content:flex-end;gap:10px;}
  .form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px;}
  .field{margin-bottom:14px;}
  .field:last-child{margin-bottom:0;}
  .field label{display:block;margin-bottom:6px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.7px;color:var(--text-mid);}
  .field label .req{color:var(--moss);margin-left:2px;}
  .field input,.field select,.field textarea{width:100%;padding:9px 12px;border:1.5px solid var(--cream-dark);border-radius:2px;background:var(--cream);font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-dark);outline:none;transition:border-color .2s,box-shadow .2s;}
  .field input:focus,.field select:focus,.field textarea:focus{border-color:var(--moss-light);box-shadow:0 0 0 3px rgba(74,94,58,.08);background:var(--warm-white);}
  .field input::placeholder{color:var(--text-light);}
  .field-hint{font-size:11px;color:var(--text-light);margin-top:4px;font-weight:300;}
  .field-error{font-size:11px;color:var(--danger);margin-top:4px;font-weight:500;display:none;}
  .roles-label{font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:1.2px;color:var(--text-light);margin-bottom:10px;}
  .roles-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:14px;}
  .role-card{border:1.5px solid var(--cream-dark);border-radius:2px;padding:12px 14px;cursor:pointer;transition:all .18s;background:var(--warm-white);}
  .role-card:hover{border-color:var(--sage);background:rgba(163,177,138,.06);}
  .role-card.selected{border-color:var(--moss);background:rgba(74,94,58,.06);}
  .role-card-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:3px;}
  .role-name-row{display:flex;align-items:center;gap:7px;}
  .role-pip{width:7px;height:7px;border-radius:50%;background:var(--cream-dark);transition:background .18s;flex-shrink:0;}
  .role-card.selected .role-pip{background:var(--moss);}
  .role-card-name{font-size:13px;font-weight:600;color:var(--text-dark);}
  .role-check{font-size:13px;color:var(--moss);opacity:0;transition:opacity .18s;}
  .role-card.selected .role-check{opacity:1;}
  .role-card-desc{font-size:11px;color:var(--text-light);font-weight:300;}
  .btn-modal-cancel{padding:9px 18px;background:none;border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;color:var(--text-mid);cursor:pointer;transition:all .15s;}
  .btn-modal-cancel:hover{border-color:var(--text-mid);}
  .btn-modal-primary{display:flex;align-items:center;gap:7px;padding:9px 20px;background:var(--moss);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;color:var(--cream);cursor:pointer;transition:background .15s,transform .1s;}
  .btn-modal-primary:hover{background:var(--moss-dark);transform:translateY(-1px);}
  .btn-modal-danger{display:flex;align-items:center;gap:7px;padding:9px 20px;background:var(--danger);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;color:#fff;cursor:pointer;transition:background .15s;}
  .btn-modal-danger:hover{background:#7a3030;}
  .btn-modal-success{display:flex;align-items:center;gap:7px;padding:9px 20px;background:var(--published);border:none;border-radius:2px;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:500;color:#fff;cursor:pointer;transition:background .15s;}
  .btn-modal-success:hover{background:#2a5a38;}
  .modal-tabs{display:flex;border-bottom:1px solid var(--cream-dark);margin-bottom:20px;}
  .modal-tab{padding:10px 18px;border:none;background:none;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:400;color:var(--text-light);cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-1px;transition:all .15s;}
  .modal-tab.active{color:var(--moss);border-bottom-color:var(--moss);font-weight:600;}
  .tab-pane{display:none;}
  .tab-pane.active{display:block;}
  .avatar-row{display:flex;align-items:center;gap:14px;background:var(--cream);border:1px solid var(--cream-dark);border-radius:2px;padding:14px 16px;margin-bottom:20px;}
  .modal-avatar{width:46px;height:46px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:15px;font-weight:800;color:#fff;flex-shrink:0;}
  .avatar-info{flex:1;}
  .avatar-info-title{font-size:13px;font-weight:500;color:var(--text-dark);}
  .avatar-info-sub{font-size:11px;color:var(--text-light);font-weight:300;margin-top:2px;}
  .btn-change-photo{padding:7px 14px;background:var(--warm-white);border:1.5px solid var(--cream-dark);border-radius:2px;font-family:'DM Sans',sans-serif;font-size:12px;font-weight:500;color:var(--text-mid);cursor:pointer;transition:all .15s;white-space:nowrap;}
  .btn-change-photo:hover{border-color:var(--moss);color:var(--moss);}
  .danger-zone-row{display:flex;align-items:center;justify-content:space-between;border:1.5px solid rgba(155,68,68,.2);border-radius:2px;padding:12px 14px;margin-top:8px;cursor:pointer;transition:all .15s;background:rgba(253,240,240,.4);}
  .danger-zone-row:hover{background:var(--danger-bg);border-color:rgba(155,68,68,.4);}
  .danger-zone-left{display:flex;align-items:center;gap:10px;}
  .danger-zone-title{font-size:13px;font-weight:600;color:var(--danger);}
  .danger-zone-sub{font-size:11px;color:var(--text-light);font-weight:300;margin-top:2px;}
  .user-preview-card{display:flex;align-items:center;gap:14px;background:var(--cream);border:1px solid var(--cream-dark);border-radius:2px;padding:14px 16px;margin-bottom:16px;}
  .preview-avatar{width:44px;height:44px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-family:'Nunito',sans-serif;font-size:14px;font-weight:800;color:#fff;flex-shrink:0;}
  .preview-name{font-size:14px;font-weight:600;color:var(--text-dark);}
  .preview-email{font-size:12px;color:var(--text-light);font-weight:300;margin-top:1px;}
  .preview-meta{display:flex;align-items:center;gap:8px;margin-top:5px;}
  .preview-role{font-size:11px;color:var(--text-light);}
  .preview-status{display:inline-flex;align-items:center;gap:5px;font-size:12px;font-weight:500;}
  .consequences-box{border-radius:2px;padding:14px 16px;margin-bottom:16px;border:1px solid;}
  .consequences-box.warn{background:var(--pending-bg);border-color:rgba(196,131,42,.3);}
  .consequences-box.good{background:var(--published-bg);border-color:rgba(58,122,74,.25);}
  .consequences-title{font-size:12px;font-weight:600;margin-bottom:8px;display:flex;align-items:center;gap:6px;}
  .consequences-box.warn .consequences-title{color:var(--pending);}
  .consequences-box.good .consequences-title{color:var(--published);}
  .consequences-list{list-style:none;padding:0;}
  .consequences-list li{font-size:12px;font-weight:300;padding:3px 0;display:flex;align-items:flex-start;gap:7px;}
  .consequences-box.warn .consequences-list li{color:#7a4a10;}
  .consequences-box.good .consequences-list li{color:#1e5a2e;}
  .consequences-list li::before{content:'·';font-weight:700;flex-shrink:0;}
  .confirm-sentence{font-size:13px;color:var(--text-mid);line-height:1.6;font-weight:300;}
  .confirm-sentence strong{font-weight:600;color:var(--text-dark);}
  .badge-inline{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;border-radius:2px;font-size:11px;font-weight:600;}
  .badge-inline.inactive{background:rgba(106,122,138,.15);color:var(--draft);}
  .badge-inline.active-badge{background:var(--published-bg);color:var(--published);}

  @media(max-width:1100px){.stats-row{grid-template-columns:repeat(2,1fr);}}
  @media(max-width:768px){.main{margin-left:0;}.content{padding:24px 16px;}.topbar{padding:0 20px;}.form-row{grid-template-columns:1fr;}}
  @media(max-width:480px){.stats-row{grid-template-columns:1fr;}}
</style>
</head>
<body>
<jsp:include page="/pages/includes/sidebar-editor-admin.jsp" />
<!-- ======= MAIN ======= -->
<main class="main">
  <div class="topbar">
    <div class="page-crumb">
      <span>Gestão</span>
      <span style="color:var(--cream-dark)">/</span>
      <span class="current">Usuários</span>
    </div>
    <div class="topbar-right">
      <%-- O sino de notificação pode vir do notifications.jsp include --%>
      <div class="notif-btn" onclick="NotifPanel && NotifPanel.toggle()">
        🔔<div class="notif-dot"></div>
      </div>
    </div>
  </div>

  <div class="content">

    <%-- ===== FEEDBACK DO SERVLET ===== --%>
    <%-- O servlet pode setar request.setAttribute("msgSucesso","Usuário criado!") --%>
    <% if (msgSucesso != null) { %>
      <div id="serverToast" class="toast show"><%= msgSucesso %></div>
    <% } %>
    <% if (msgErro != null) { %>
      <div id="serverToast" class="toast error show"><%= msgErro %></div>
    <% } %>

    <div class="section-header">
      <div>
        <div class="section-title">Gestão de <em>Usuários</em></div>
      </div>
      <button class="btn-primary" onclick="openModal('modalAdd')">✚ Novo Usuário</button>
    </div>

    <%-- ===== CARDS DE STATS ===== --%>
    <div class="stats-row">
      <div class="stat-card moss">
        <div class="stat-icon">👥</div>
        <%-- Valor dinâmico vindo do Java --%>
        <div class="stat-value"><%= totalUsuarios %></div>
        <div class="stat-label">Total de Usuários</div>
      </div>
      <div class="stat-card green">
        <div class="stat-icon">✅</div>
        <div class="stat-value"><%= totalAtivos %></div>
        <div class="stat-label">Ativos</div>
      </div>
      <div class="stat-card pending">
        <div class="stat-icon">⏸️</div>
        <div class="stat-value"><%= totalInativos %></div>
        <div class="stat-label">Inativos</div>
      </div>
      <div class="stat-card blue">
        <div class="stat-icon">✨</div>
        <%-- Idealmente vindo do servlet: request.getAttribute("novosEsteMes") --%>
		<div class="stat-value">
		  <%= request.getAttribute("novosEsteMes") != null ? request.getAttribute("novosEsteMes") : 0 %>
		</div>        
		<div class="stat-label">Novos este Mês</div>
      </div>
    </div>

    <div class="toolbar">
      <div class="search-bar">
        <span style="font-size:14px;color:var(--text-light)">🔍</span>
        <input type="text" id="searchInput" placeholder="Nome, e-mail ou função…" oninput="filterTable()">
      </div>
      <select class="filter-select" id="filterRole" onchange="filterTable()">
        <option value="">Todas as funções</option>
        <option value="admin">Administrador</option>
        <option value="editor">Editor</option>
        <option value="author">Autor</option>
        <option value="viewer">Visitante</option>
      </select>
      <select class="filter-select" id="filterStatus" onchange="filterTable()">
        <option value="">Todos os status</option>
        <option value="ativo" selected>Ativo</option>
        <option value="inativo">Inativo</option>
      </select>
      <div class="toolbar-spacer"></div>
    </div>

    <div class="table-card">
      <div class="table-head">
        <div class="table-title">👥 Lista de Usuários</div>
      
      </div>
      <table>
        <thead>
          <tr>
            <th>Usuário</th>
            <th>Função</th>
            <th>Status</th>
            <th>Membro desde</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody id="usersBody">
          <%--
              ═══════════════════════════════════════════════════════
              AQUI ESTÁ A MAGIA DO JSP:
              O Java itera a lista que o servlet colocou no request.
              Cada <tr> é gerado pelo servidor antes de chegar no browser.
              O JavaScript só lida com os modais, não com os dados.
              ═══════════════════════════════════════════════════════
          --%>
          <% if (usuarios.isEmpty()) { %>
            <tr>
              <td colspan="5" style="text-align:center;padding:40px;color:var(--text-light);font-size:13px;font-weight:300;">
                Nenhum usuário encontrado.
              </td>
            </tr>
          <% } else {
               for (Usuario u : usuarios) {
            	   String dataCadastro = "—";
            	   if (u.getData_criacao_usuario() != null) {
            	       dataCadastro = u.getData_criacao_usuario()
            	           .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
            	   }
                 String nomeFull   = u.getNome_usuario();
                 String email      = u.getEmail_usuario();
                 String tipoStr = u.getTipo_usuario() != null
                		 ? u.getTipo_usuario().toString().toLowerCase()
                		 : "visitante";

                		 //Mapeia enum → nome usado no front
                		 String role = "autor".equals(tipoStr)     ? "author"
                		         : "visitante".equals(tipoStr) ? "viewer"
                		         : tipoStr; // admin e editor já batem

                	String status = u.getStatus_usuario() != null
                	        ? u.getStatus_usuario().toString().toLowerCase()
                	        : "inativo";
                 boolean isAtivo   = "ativo".equals(status);
                 String ini        = nomeFull.length() >= 2
                                   ? nomeFull.substring(0,1).toUpperCase() + nomeFull.split(" ")[nomeFull.split(" ").length-1].substring(0,1).toUpperCase()
                                   : nomeFull.substring(0,1).toUpperCase();

                 /* ─ badge de role ─ */
                 String roleLabel = "admin".equals(role) ? "👑 Admin"
                                  : "editor".equals(role) ? "✍️ Editor"
                                  : "author".equals(role) ? "🖊️ Autor"
                                  : "👁 Visitante";
                 String roleCss   = "admin".equals(role)  ? "role-admin"
                                  : "editor".equals(role) ? "role-editor"
                                  : "author".equals(role) ? "role-author"
                                  : "role-viewer";

                 /* ─ cor do avatar por função ─ */
                 String avatarBg  = "admin".equals(role)  ? "linear-gradient(135deg,#c4a265,#dfc094)"
                                  : "editor".equals(role) ? "linear-gradient(135deg,#4a5e3a,#6b7f59)"
                                  : "author".equals(role) ? "linear-gradient(135deg,#5a8a6a,#7ab890)"
                                  : "linear-gradient(135deg,#7a6aa0,#9a8ac0)";
                 String avatarClr = "admin".equals(role) ? "var(--moss-dark)" : "#fff";
                 
                 String fotoUrl = (u.getFoto_usuario() != null && !u.getFoto_usuario().isEmpty())
                     ? _ctx + u.getFoto_usuario()
                     : null;
          %>
            <tr class="<%= isAtivo ? "" : "row-inactive" %>"
                data-name="<%= nomeFull.toLowerCase() %>"
                data-email="<%= email.toLowerCase() %>"
                data-role="<%= role %>"
                data-status="<%= status %>">

              <td>
                <div class="user-cell">

					<div class="u-avatar" style="background:<%= avatarBg %>;color:<%= avatarClr %>;overflow:hidden;padding:0;">
					  <% if (fotoUrl != null) { %>
					    <img src="<%= fotoUrl %>" style="width:100%;height:100%;object-fit:cover;" alt="<%= ini %>">
					  <% } else { %>
					    <%= ini %>
					  <% } %>
					</div>
                  <div>
                    <div class="u-name"><%= nomeFull %></div>
                    <div class="u-email"><%= email %></div>
                  </div>
                </div>
              </td>

              <td>
                <span class="role-badge <%= roleCss %>"><%= roleLabel %></span>
              </td>

              <td>
                <span class="status-dot">
                  <span class="dot <%= isAtivo ? "active" : "inactive" %>"></span>
                  <%= isAtivo ? "Ativo" : "Inativo" %>
                </span>
              </td>


				<td style="color:var(--text-light);font-size:12px;">
				    <%= dataCadastro %>
				</td>
				<%
				  Usuario logadoSessao = (Usuario) session.getAttribute("usuarioLogado");
				  boolean isSelf = logadoSessao != null && logadoSessao.getId_usuario() == u.getId_usuario();
				%>
				<td>
				  <div class="action-group">
				    <button class="act-btn" title="Ver perfil"
				            onclick="window.location.href='<%= _ctx %>/UsuarioController?action=ver&id=<%= u.getId_usuario() %>'">
				      👁
				    </button>
				
						<button class="act-btn" title="Editar"
						        onclick="openEditModal(<%= u.getId_usuario() %>,'<%= nomeFull %>','<%= email %>','<%= role %>','<%= status %>','<%= ini %>','<%= avatarBg %>','<%= avatarClr %>','<%= fotoUrl != null ? fotoUrl : "" %>')">
						  ✏️
						</button>
				
				    <% if (isSelf) { %>
				      <button class="act-btn" title="Você não pode desativar sua própria conta"
				              disabled style="opacity:.35;cursor:not-allowed;">
				        🔒
				      </button>
				    <% } else if (isAtivo) { %>
				      <button class="act-btn danger" title="Desativar"
				              onclick="openStatusModal(<%= u.getId_usuario() %>,'<%= nomeFull %>','<%= email %>','<%= roleLabel %>','<%= ini %>','<%= avatarBg %>','<%= avatarClr %>',true)">
				        🚫
				      </button>
				    <% } else { %>
				      <button class="act-btn reactivate" title="Reativar"
				              onclick="openStatusModal(<%= u.getId_usuario() %>,'<%= nomeFull %>','<%= email %>','<%= roleLabel %>','<%= ini %>','<%= avatarBg %>','<%= avatarClr %>',false)">
				        🔄
				      </button>
				    <% } %>
				  </div>
				</td>
            </tr>
          <%
               } // fim for
             } // fim else
          %>
        </tbody>
      </table>

      <div class="pagination">
        <div class="pag-btns">
          <button class="pag-btn">‹</button>
          <button class="pag-btn active">1</button>
          <button class="pag-btn">2</button>
          <button class="pag-btn">›</button>
        </div>
      </div>
    </div>
  </div>
</main>

<!-- ======================================================= -->
<!-- MODAL: AVATAR                                           -->
<!-- ======================================================= -->
<div class="modal-overlay" id="avatarModal" onclick="if(event.target===this)closeAvatarModal()">
  <div class="avatar-modal-box">
    <div class="avatar-modal-header">
      <div class="avatar-modal-title">📷 Alterar foto de perfil</div>
      <button class="avatar-modal-close" onclick="closeAvatarModal()">×</button>
    </div>
    <div class="avatar-modal-body">
      <div class="av-success" id="avSuccess">✅ Foto atualizada com sucesso!</div>
      <div class="avatar-preview-area">
        <div class="avatar-preview-ring" id="avPreviewRing">
          <span id="avPreviewIni">?</span>
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
      <div class="av-error" id="avError"></div>
      <div class="file-info-bar" id="avFileInfo">
        <span>📎</span>
        <span class="file-info-name" id="avFileName"></span>
        <span class="file-info-size" id="avFileSize"></span>
        <button class="file-info-rm" onclick="clearAvPreview()">×</button>
      </div>
    </div>
    <div class="avatar-modal-footer">
      <button class="btn-modal-cancel" onclick="closeAvatarModal()">Cancelar</button>
      <button class="btn-modal-primary" id="avSaveBtn" disabled onclick="saveAvatar()">💾 Salvar foto</button>
    </div>
  </div>
</div>

<!-- ======================================================= -->
<!-- MODAL: ADICIONAR NOVO USUÁRIO                           -->
<!-- ======================================================= -->
<div class="modal-overlay" id="modalAdd" onclick="outsideClose(event,'modalAdd')">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-header-icon add-icon">👤</div>
        <div>
          <div class="modal-title">Novo Usuário</div>
          <div class="modal-subtitle">Preencha os dados para criar a conta</div>
        </div>
      </div>
      <button class="modal-close" onclick="closeModal('modalAdd')">✕</button>
    </div>

    <%--
        O form envia para o servlet via POST.
        O servlet lê os parâmetros com request.getParameter("nome"), etc.
        e redireciona de volta com uma mensagem de sucesso ou erro.
    --%>
    <form method="POST" action="<%= _ctx %>/UsuarioController" onsubmit="return validarAdd()">
      <input type="hidden" name="action" value="cadastrar">

      <div class="modal-body">
        <div class="form-row">
          <div class="field">
            <label>Nome completo <span class="req">*</span></label>
            <input type="text" name="nome" id="addNome" placeholder="Ex: Ana Beatriz" required>
          </div>
          <div class="field">
            <label>E-mail <span class="req">*</span></label>
				<input type="email" name="email" id="addEmail" 
				       placeholder="usuario@dominio.com" 
				       pattern="[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"
				       title="Digite um e-mail válido"
				       required>
                 </div>
        </div>
        <div class="form-row">
          <div class="field">
            <label>Senha <span class="req">*</span></label>
            <input type="password" name="senha" id="addSenha" placeholder="Mín. 8 caracteres" required>
          </div>
          <div class="field">
            <label>Confirmar Senha <span class="req">*</span></label>
            <input type="password" id="addConfirm" placeholder="Repita a senha">
            <div class="field-error" id="errSenha">As senhas não coincidem</div>
          </div>
        </div>

        <div class="roles-label">Função no sistema</div>
        <div class="roles-grid" id="rolesGrid">
          <div class="role-card" data-role="admin" onclick="pickRole(this)">
            <div class="role-card-top">
              <div class="role-name-row"><span class="role-pip"></span><span class="role-card-name">Administrador</span></div>
              <span class="role-check">✓</span>
            </div>
            <div class="role-card-desc">Acesso total ao sistema</div>
          </div>
          <div class="role-card" data-role="editor" onclick="pickRole(this)">
            <div class="role-card-top">
              <div class="role-name-row"><span class="role-pip"></span><span class="role-card-name">Editor</span></div>
              <span class="role-check">✓</span>
            </div>
            <div class="role-card-desc">Edita e publica receitas</div>
          </div>
          <div class="role-card selected" data-role="author" onclick="pickRole(this)">
            <div class="role-card-top">
              <div class="role-name-row"><span class="role-pip"></span><span class="role-card-name">Autor</span></div>
              <span class="role-check">✓</span>
            </div>
            <div class="role-card-desc">Cria e submete receitas</div>
          </div>
          <div class="role-card" data-role="viewer" onclick="pickRole(this)">
            <div class="role-card-top">
              <div class="role-name-row"><span class="role-pip"></span><span class="role-card-name">Visitante</span></div>
              <span class="role-check">✓</span>
            </div>
            <div class="role-card-desc">Somente leitura</div>
          </div>
        </div>
        <%-- hidden enviado ao servlet --%>
        <input type="hidden" name="role" id="addRole" value="author">
      </div>

      <div class="modal-footer">
        <button type="button" class="btn-modal-cancel" onclick="closeModal('modalAdd')">Cancelar</button>
        <button type="submit" class="btn-modal-primary">✚ Criar Usuário</button>
      </div>
    </form>
  </div>
</div>

<!-- ======================================================= -->
<!-- MODAL: EDITAR USUÁRIO                                   -->
<!-- ======================================================= -->
<div class="modal-overlay" id="modalEdit" onclick="outsideClose(event,'modalEdit')">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-header-icon edit-icon">🖊️</div>
        <div>
          <div class="modal-title">Editar Usuário</div>
          <div class="modal-subtitle" id="editSubtitle">—</div>
        </div>
      </div>
      <button class="modal-close" onclick="closeModal('modalEdit')">✕</button>
    </div>

    <form method="POST" action="<%= _ctx %>/UsuarioController">
      <input type="hidden" name="action" value="atualizar">
      <input type="hidden" name="id"     id="editId">

      <div class="modal-body">
        <div class="avatar-row">
          <div class="modal-avatar" id="editAvatar">?</div>
          <div class="avatar-info">
            <div class="avatar-info-title" id="editAvatarName">—</div>
          </div>
			<button type="button" class="btn-change-photo"
			        onclick="openAvatarModal(window._editId, window._editIni, window._editBg)">
			  📷 Alterar foto
			</button>
        </div>

        <div class="modal-tabs">
          <button type="button" class="modal-tab active" onclick="switchTab(event,'tabDados')">Dados pessoais</button>
          <button type="button" class="modal-tab" onclick="switchTab(event,'tabAcesso')">Acesso &amp; Permissões</button>
        </div>

        <div class="tab-pane active" id="tabDados">
          <div class="field">
            <label>Nome completo <span class="req">*</span></label>
            <input type="text" name="nome" id="editNome" required>
          </div>
          <div class="field">
            <label>E-mail <span class="req">*</span></label>
            <input type="email" name="email" id="editEmail" required>
          </div>
          <div class="field">
            <label>Telefone</label>
            <input type="tel" name="telefone" id="editTel" placeholder="(00) 00000-0000" oninput="phoneMask(this)">
          </div>
          <div style="margin-top:8px;">
            <div class="roles-label">Zona de dados</div>
            <div class="danger-zone-row" onclick="alert('Funcionalidade em desenvolvimento')">
              <div class="danger-zone-left">
                <span style="font-size:16px">🗑️</span>
                <div>
                  <div class="danger-zone-title">Limpar informações pessoais</div>
                  <div class="danger-zone-sub">Remove bio, preferências e redes sociais</div>
                </div>
              </div>
              <span style="color:var(--text-light);font-size:16px">›</span>
            </div>
          </div>
        </div>

        <div class="tab-pane" id="tabAcesso">
          <div class="field">
            <label>Função</label>
            <select name="role" id="editRole">
              <option value="admin">Administrador</option>
              <option value="editor">Editor</option>
              <option value="author">Autor</option>
              <option value="viewer">Visitante</option>
            </select>
          </div>
          <div class="field">
            <label>Alterar Senha <span style="font-weight:300;text-transform:none;">(opcional)</span></label>
            <input type="password" name="novaSenha" id="editSenha" placeholder="Deixe vazio para manter a atual">
            <div class="field-hint">Mínimo 8 caracteres se preenchida</div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn-modal-cancel" onclick="closeModal('modalEdit')">Cancelar</button>
        <button type="submit" class="btn-modal-primary">💾 Salvar Alterações</button>
      </div>
    </form>
  </div>
</div>

<!-- ======================================================= -->
<!-- MODAL: STATUS (DESATIVAR / REATIVAR)                    -->
<!-- ======================================================= -->
<div class="modal-overlay" id="modalStatus" onclick="outsideClose(event,'modalStatus')">
  <div class="modal-box" style="max-width:440px;">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-header-icon" id="statusModalIcon">🚫</div>
        <div>
          <div class="modal-title" id="statusModalTitle">Desativar Usuário</div>
          <div class="modal-subtitle">Esta ação pode ser revertida</div>
        </div>
      </div>
      <button class="modal-close" onclick="closeModal('modalStatus')">✕</button>
    </div>

    <form method="POST" action="<%= _ctx %>/UsuarioController">
      <input type="hidden" name="action" value="status">
      <input type="hidden" name="id" id="statusId">
      <input type="hidden" name="novoStatus" id="statusNovoValor">

      <div class="modal-body">
        <div class="user-preview-card">
          <div class="preview-avatar" id="statusAvatar">?</div>
          <div>
            <div class="preview-name"  id="statusName">—</div>
            <div class="preview-email" id="statusEmail">—</div>
            <div class="preview-meta">
              <span class="preview-role"   id="statusRole">—</span>
              <span class="preview-status" id="statusBadge">
                <span class="dot active"></span> Ativo
              </span>
            </div>
          </div>
        </div>

        <div class="consequences-box warn" id="statusConseqBox">
          <div class="consequences-title" id="statusConseqTitle">⚠️ O que acontece ao desativar:</div>
          <ul class="consequences-list" id="statusConseqList"></ul>
        </div>

        <p class="confirm-sentence" id="statusConfirmSentence"></p>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn-modal-cancel" onclick="closeModal('modalStatus')">Cancelar</button>
        <button type="submit" class="btn-modal-danger" id="statusActionBtn">🚫 Desativar usuário</button>
      </div>
    </form>
  </div>
</div>

<!-- Toast de feedback client-side -->
<div class="toast" id="toast"></div>

<%--
    ===== INCLUDE DO NOTIFICATIONS PANEL =====
    Descomente quando tiver o arquivo criado:
    <%@ include file="/WEB-INF/components/notifications.jsp" %>
--%>

<script>
/* ─────────────────────────────────────────
   FILTRO CLIENT-SIDE (filtra as <tr> já
   renderizadas pelo servidor sem recarregar)
───────────────────────────────────────── */
function filterTable() {
  var s   = document.getElementById('searchInput').value.toLowerCase();
  var r   = document.getElementById('filterRole').value;
  var st  = document.getElementById('filterStatus').value;
  var rows = document.querySelectorAll('#usersBody tr[data-name]');
  var vis  = 0;

  rows.forEach(function(row) {
    var txt    = (row.dataset.name + ' ' + row.dataset.email + ' ' + row.dataset.role).toLowerCase();
    var matchS = !s  || txt.includes(s);
    var matchR = !r  || row.dataset.role   === r;
    var matchT = !st || row.dataset.status === st;
    var show   = matchS && matchR && matchT;
    row.style.display = show ? '' : 'none';
    if (show) vis++;
  });
}

/* ─────────────────────────────────────────
   MODAIS: abrir / fechar
───────────────────────────────────────── */
function openModal(id)             { document.getElementById(id).classList.add('open'); }
function closeModal(id)            { document.getElementById(id).classList.remove('open'); }
function outsideClose(e, id)       { if (e.target.id === id) closeModal(id); }

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape')
    ['modalAdd','modalEdit','modalStatus'].forEach(closeModal);
});

/* ─────────────────────────────────────────
   MODAL ADICIONAR
───────────────────────────────────────── */
function pickRole(card) {
  document.querySelectorAll('#rolesGrid .role-card').forEach(function(c) { c.classList.remove('selected'); });
  card.classList.add('selected');
  document.getElementById('addRole').value = card.dataset.role;
}

function validarAdd() {
	  var s1    = document.getElementById('addSenha').value;
	  var s2    = document.getElementById('addConfirm').value;
	  var email = document.getElementById('addEmail').value;
	  var err   = document.getElementById('errSenha');

	  // valida senhas
	  if (s1 !== s2) {
	    err.style.display = 'block';
	    return false;
	  }
	  err.style.display = 'none';

	  // valida email — TLD mínimo 2 letras E domínio conhecido
	  var emailRegex = /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/;
	  if (!emailRegex.test(email)) {
	    alert('Digite um e-mail válido.');
	    return false;
	  }

	  // bloqueia TLDs de 1-2 letras suspeitos (opcional)
	  var tld = email.split('.').pop();
	  if (tld.length < 2) {
	    alert('Domínio de e-mail inválido.');
	    return false;
	  }

	  return true;
	}

/* ─────────────────────────────────────────
   ;~~~~EDITAR
   (recebe dados via parâmetros do onclick
    que o JSP gerou com os valores do Java)
───────────────────────────────────────── */
function openEditModal(id, nome, email, role, status, ini, bg, clr, fotoUrl) {
	  document.getElementById('editId').value    = id;
	  document.getElementById('editNome').value  = nome;
	  document.getElementById('editEmail').value = email;
	  document.getElementById('editRole').value  = role;
	  document.getElementById('editSenha').value = '';
	  document.getElementById('editTel').value   = '';
	  document.getElementById('editSubtitle').textContent   = nome;
	  document.getElementById('editAvatarName').textContent = nome;

	  window._editIni  = ini;
	  window._editBg   = bg;
	  window._editId   = id;

	  var av = document.getElementById('editAvatar');

	  // ← aplica foto se existir, senão mostra iniciais
	  if (fotoUrl && fotoUrl !== '') {
	    av.textContent   = '';
	    av.style.background = 'none';
	    av.style.padding    = '0';
	    av.style.overflow   = 'hidden';
	    av.innerHTML = '<img src="' + fotoUrl + '" style="width:100%;height:100%;object-fit:cover;border-radius:50%;" alt="' + ini + '">';
	  } else {
	    av.innerHTML        = ini;
	    av.style.background = bg;
	    av.style.color      = clr;
	    av.style.padding    = '';
	  }

	  document.querySelectorAll('#modalEdit .modal-tab').forEach(function(t, i) { t.classList.toggle('active', i === 0); });
	  document.querySelectorAll('#modalEdit .tab-pane').forEach(function(p, i)  { p.classList.toggle('active', i === 0); });

	  openModal('modalEdit');
	}

/* ─────────────────────────────────────────
   MODAL STATUS (desativar / reativar)
───────────────────────────────────────── */
function openStatusModal(id, nome, email, roleLabel, ini, bg, clr, isAtivo) {
  document.getElementById('statusId').value = id;
  document.getElementById('statusNovoValor').value = isAtivo ? 'inativo' : 'ativo';

  /* ícone e título */
  document.getElementById('statusModalIcon').textContent  = isAtivo ? '🚫' : '✅';
  document.getElementById('statusModalIcon').className    = 'modal-header-icon ' + (isAtivo ? 'deactivate-icon' : 'reactivate-icon');
  document.getElementById('statusModalTitle').textContent = isAtivo ? 'Desativar Usuário' : 'Reativar Usuário';

  /* prévia */
  var av = document.getElementById('statusAvatar');
  av.textContent      = ini;
  av.style.background = bg;
  av.style.color      = clr;
  document.getElementById('statusName').textContent  = nome;
  document.getElementById('statusEmail').textContent = email;
  document.getElementById('statusRole').textContent  = roleLabel + ' ·';
  document.getElementById('statusBadge').innerHTML   = isAtivo
    ? '<span class="dot active"></span> Ativo'
    : '<span class="dot inactive"></span> Inativo';

  /* consequências */
  var box   = document.getElementById('statusConseqBox');
  var title = document.getElementById('statusConseqTitle');
  var list  = document.getElementById('statusConseqList');
  if (isAtivo) {
    box.className   = 'consequences-box warn';
    title.textContent = '⚠️ O que acontece ao desativar:';
    list.innerHTML  = '<li>O usuário não poderá mais fazer login</li>' +
                      '<li>As receitas publicadas permanecem no ar</li>' +
                      '<li>O acesso pode ser restaurado a qualquer momento</li>';
  } else {
    box.className   = 'consequences-box good';
    title.textContent = '✅ O que acontece ao reativar:';
    list.innerHTML  = '<li>O usuário poderá fazer login normalmente</li>' +
                      '<li>Todas as permissões anteriores são restauradas</li>' +
                      '<li>O histórico de atividades é mantido</li>';
  }

  /* frase e botão */
  document.getElementById('statusConfirmSentence').innerHTML = isAtivo
    ? 'Deseja desativar <strong>' + nome + '</strong>? O status será alterado para <span class="badge-inline inactive">Inativo</span> imediatamente.'
    : 'Deseja reativar <strong>' + nome + '</strong>? O status será alterado para <span class="badge-inline active-badge">✅ Ativo</span> imediatamente.';

  var btn = document.getElementById('statusActionBtn');
  btn.className   = isAtivo ? 'btn-modal-danger' : 'btn-modal-success';
  btn.textContent = isAtivo ? '🚫 Desativar usuário' : '✅ Reativar usuário';

  openModal('modalStatus');
}



/* ─────────────────────────────────────────
   TABS
───────────────────────────────────────── */
function switchTab(e, tabId) {
  document.querySelectorAll('#modalEdit .modal-tab').forEach(function(t)  { t.classList.remove('active'); });
  document.querySelectorAll('#modalEdit .tab-pane').forEach(function(p)   { p.classList.remove('active'); });
  e.target.classList.add('active');
  document.getElementById(tabId).classList.add('active');
}

/* ─────────────────────────────────────────
   MÁSCARA TELEFONE
───────────────────────────────────────── */
function phoneMask(input) {
  var v = input.value.replace(/\D/g, ''), f = '';
  if (v.length > 0) f = '(' + v.substring(0, 2);
  if (v.length > 2) f += ') ' + v.substring(2, 7);
  if (v.length > 7) f += '-' + v.substring(7, 11);
  input.value = f;
}

/* ─────────────────────────────────────────
   TOAST DE FEEDBACK DO SERVIDOR
   (some automaticamente após 3s)
───────────────────────────────────────── */
(function() {
  var t = document.getElementById('serverToast');
  if (t) setTimeout(function() { t.classList.remove('show'); }, 3000);
})();

//no final do <script>, após todas as funções
document.addEventListener('DOMContentLoaded', function() {
  filterTable();
});

/* ── MODAL AVATAR ── */
var avSelectedUrl  = null;
var avUsuarioId    = null;  // id do usuário sendo editado

function openAvatarModal(userId, ini, bg) {
  avUsuarioId = userId;
  avSelectedUrl = null;

  // reseta tudo
  document.getElementById('avSuccess').classList.remove('show');
  document.getElementById('avError').classList.remove('show');
  document.getElementById('avFileInfo').classList.remove('show');
  document.getElementById('avFileInput').value = '';
  document.getElementById('avSaveBtn').disabled = true;

  // mostra as iniciais do usuário no preview
  var ring = document.getElementById('avPreviewRing');
  var img  = document.getElementById('avPreviewImg');
  img.src = '';
  img.classList.remove('visible');
  ring.classList.remove('has-img');
  ring.style.background = bg;
  document.getElementById('avPreviewIni').textContent = ini;

  openModal('avatarModal');
}

function closeAvatarModal() { closeModal('avatarModal'); }

function setAvPreview(src) {
  var img = document.getElementById('avPreviewImg');
  img.src = src;
  img.classList.add('visible');
  document.getElementById('avPreviewRing').classList.add('has-img');
  document.getElementById('avPreviewIni').textContent = '';
  document.getElementById('avSaveBtn').disabled = false;
  document.getElementById('avError').classList.remove('show');
  avSelectedUrl = src;
}

function clearAvPreview() {
  var img = document.getElementById('avPreviewImg');
  img.src = '';
  img.classList.remove('visible');
  document.getElementById('avPreviewRing').classList.remove('has-img');
  document.getElementById('avSaveBtn').disabled = true;
  document.getElementById('avFileInfo').classList.remove('show');
  document.getElementById('avFileInput').value = '';
  avSelectedUrl = null;
}

function handleAvFile(file) {
  if (!file) return;
  var err = document.getElementById('avError');
  if (!file.type.startsWith('image/')) {
    err.textContent = 'Arquivo inválido. Use JPG, PNG ou WEBP.';
    err.classList.add('show'); return;
  }
  if (file.size > 5 * 1024 * 1024) {
    err.textContent = 'O arquivo excede 5 MB.';
    err.classList.add('show'); return;
  }
  err.classList.remove('show');
  var reader = new FileReader();
  reader.onload = function(e) {
    setAvPreview(e.target.result);
    document.getElementById('avFileName').textContent = file.name;
    var kb = file.size / 1024;
    document.getElementById('avFileSize').textContent = kb > 1024 ? (kb/1024).toFixed(1)+' MB' : Math.round(kb)+' KB';
    document.getElementById('avFileInfo').classList.add('show');
  };
  reader.readAsDataURL(file);
}

function handleAvDrop(e) {
  e.preventDefault();
  document.getElementById('avDropZone').classList.remove('drag-over');
  handleAvFile(e.dataTransfer.files[0]);
}
	function saveAvatar() {
		  if (!avSelectedUrl || !avUsuarioId) return;
		  var btn = document.getElementById('avSaveBtn');
		  btn.disabled = true;
		  btn.textContent = '⏳ Salvando…';

		  // redimensiona para 200x200 antes de enviar
		  var canvas = document.createElement('canvas');
		  canvas.width = 200; canvas.height = 200;
		  var ctx = canvas.getContext('2d');
		  var img = new Image();
		  img.onload = function() {
		    ctx.drawImage(img, 0, 0, 200, 200);
		    var base64Reduzido = canvas.toDataURL('image/jpeg', 0.7); // qualidade 70%

		    var form = document.createElement('form');
		    form.method = 'POST';
		    form.action = '<%= _ctx %>/UsuarioController';

		    [['action','foto'],['id', avUsuarioId],['fotoBase64', base64Reduzido]]
		      .forEach(function(par) {
		        var input = document.createElement('input');
		        input.type = 'hidden';
		        input.name = par[0];
		        input.value = par[1];
		        form.appendChild(input);
		      });

		    document.body.appendChild(form);
		    form.submit();
		  };
		  img.src = avSelectedUrl;
		}
</script>
</body>
</html>
