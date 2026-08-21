package br.com.saborearte.controller;

import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.model.Log;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;
import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/** Controller exclusivo da consulta administrativa de auditoria. */
@WebServlet("/LogController")
public class LogController extends HttpServlet {
    private static final long serialVersionUID=1L;
    private static final int TAMANHO_PADRAO=20,TAMANHO_MAXIMO=100;
    /** Teto de segurança: máximo de registros carregados de uma vez para a tela (paginação é client-side). */
    private static final int LIMITE_TOTAL_LOGS=2000;
    private static final Set<String> ACOES=Set.of("CRIAR_RASCUNHO","ENVIAR_REVISAO","APROVAR_RECEITA","REJEITAR_RECEITA","ALTERAR_ATIVIDADE","COMENTAR","RESPONDER_COMENTARIO","MODERAR_COMENTARIO","LOGIN");
    private static final Set<String> ENTIDADES=Set.of("RECEITA","COMENTARIO","USUARIO","RELATORIO","SESSAO");
    private static final Set<String> EXPORTACOES=Set.of("pdf","excel","print");

    @Override protected void doGet(HttpServletRequest request,HttpServletResponse response)throws ServletException,IOException{
        request.setCharacterEncoding("UTF-8");response.setCharacterEncoding("UTF-8");
        HttpSession session=request.getSession(false);
        if(session==null||session.getAttribute("usuarioLogado")==null){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
        Usuario usuario=(Usuario)session.getAttribute("usuarioLogado");
        if(usuario.getTipo_usuario()!=TipoUsuario.ADMIN){response.sendError(HttpServletResponse.SC_FORBIDDEN);return;}
        try{
            Filtros f=lerFiltros(request);
            request.setAttribute("logs",Collections.emptyList());request.setAttribute("totalLogs",Integer.valueOf(0));
            request.setAttribute("page",Integer.valueOf(f.page));request.setAttribute("size",Integer.valueOf(f.size));request.setAttribute("totalPages",Integer.valueOf(1));
            request.setAttribute("busca",f.busca);request.setAttribute("acaoLog",f.acaoLog);request.setAttribute("entidade",f.entidade);request.setAttribute("periodo",f.periodo);
            request.setAttribute("dataInicio",f.inicio==null?"":f.inicio.toString());request.setAttribute("dataFim",f.fim==null?"":f.fim.toString());request.setAttribute("exportTipo",f.exportTipo);
            try(Connection conexao=Conexao.getConnection()){
                LogDAO dao=new LogDAO(conexao);
                int total=dao.contarComFiltros(f.busca,f.acaoLog,f.entidade,f.inicio,f.fim);
                // A paginação (8 por página) agora é feita em client-side pelo log-admin.jsp,
                // então aqui trazemos TODOS os registros que batem com o filtro, sem LIMIT/OFFSET.
                // Aplicamos apenas um teto de segurança (LIMITE_TOTAL_LOGS) para não estourar
                // memória caso a tabela de auditoria fique muito grande.
                int totalCarregado=Math.min(total,LIMITE_TOTAL_LOGS);
                List<Log> logs=totalCarregado==0?Collections.emptyList():dao.listarComFiltros(f.busca,f.acaoLog,f.entidade,f.inicio,f.fim,0,totalCarregado);
                request.setAttribute("logs",logs);request.setAttribute("totalLogs",Integer.valueOf(total));
                request.setAttribute("page",Integer.valueOf(1));request.setAttribute("totalPages",Integer.valueOf(1));
                if(f.exportTipo!=null){List<Log> logsExportacao=total==0?Collections.emptyList():dao.listarComFiltros(f.busca,f.acaoLog,f.entidade,f.inicio,f.fim,0,total);request.setAttribute("logsExportacao",logsExportacao);}
            }
            request.getRequestDispatcher("/pages/log-admin.jsp").forward(request,response);
        }catch(IllegalArgumentException e){response.sendError(HttpServletResponse.SC_BAD_REQUEST,e.getMessage());}
        catch(Exception e){getServletContext().log("Falha ao consultar auditoria",e);request.setAttribute("erro","Não foi possível carregar a auditoria.");request.getRequestDispatcher("/pages/log-admin.jsp").forward(request,response);}
    }

    @Override protected void doPost(HttpServletRequest request,HttpServletResponse response)throws IOException{response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);}

    private Filtros lerFiltros(HttpServletRequest r){
        String busca=texto(r.getParameter("busca"),100),acao=texto(r.getParameter("acaoLog"),50),entidade=texto(r.getParameter("entidade"),30),periodo=texto(r.getParameter("periodo"),20),exportar=texto(r.getParameter("export"),10);
        if(acao!=null&&!ACOES.contains(acao))throw new IllegalArgumentException("Ação de auditoria inválida.");
        if(entidade!=null&&!ENTIDADES.contains(entidade))throw new IllegalArgumentException("Entidade de auditoria inválida.");
        if(exportar!=null&&!EXPORTACOES.contains(exportar))throw new IllegalArgumentException("Formato de exportação inválido.");
        int page=inteiro(r.getParameter("page"),1,1,Integer.MAX_VALUE),size=inteiro(r.getParameter("size"),TAMANHO_PADRAO,1,TAMANHO_MAXIMO);
        LocalDate inicio=null,fim=null,hoje=LocalDate.now();
        if(periodo!=null)switch(periodo){case "hoje"->{inicio=hoje;fim=hoje;}case "7dias"->{inicio=hoje.minusDays(6);fim=hoje;}case "30dias"->{inicio=hoje.minusDays(29);fim=hoje;}case "personalizado"->{inicio=data(r.getParameter("dataInicio"),"dataInicio");fim=data(r.getParameter("dataFim"),"dataFim");}default->throw new IllegalArgumentException("Período inválido.");}
        else if(r.getParameter("dataInicio")!=null||r.getParameter("dataFim")!=null){inicio=dataOpcional(r.getParameter("dataInicio"),"dataInicio");fim=dataOpcional(r.getParameter("dataFim"),"dataFim");}
        if(inicio!=null&&fim!=null&&inicio.isAfter(fim))throw new IllegalArgumentException("Data inicial posterior à final.");
        return new Filtros(busca,acao,entidade,periodo,inicio,fim,page,size,exportar);
    }
    private String texto(String v,int max){if(v==null||v.trim().isEmpty())return null;String t=v.trim();if(t.length()>max)throw new IllegalArgumentException("Filtro excede o tamanho permitido.");return t;}
    private int inteiro(String v,int padrao,int min,int max){if(v==null||v.isBlank())return padrao;try{int n=Integer.parseInt(v);if(n<min||n>max)throw new NumberFormatException();return n;}catch(NumberFormatException e){throw new IllegalArgumentException("Paginação inválida.");}}
    private LocalDate data(String v,String nome){if(v==null||v.isBlank())throw new IllegalArgumentException(nome+" é obrigatória.");return dataOpcional(v,nome);}
    private LocalDate dataOpcional(String v,String nome){if(v==null||v.isBlank())return null;try{return LocalDate.parse(v);}catch(DateTimeParseException e){throw new IllegalArgumentException(nome+" inválida.");}}
    private static final class Filtros{final String busca,acaoLog,entidade,periodo,exportTipo;final LocalDate inicio,fim;final int page,size;Filtros(String b,String a,String e,String p,LocalDate i,LocalDate f,int pg,int s,String x){busca=b;acaoLog=a;entidade=e;periodo=p;inicio=i;fim=f;page=pg;size=s;exportTipo=x;}}
}