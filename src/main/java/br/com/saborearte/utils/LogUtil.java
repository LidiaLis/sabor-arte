package br.com.saborearte.utils;

import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.model.Log;
import br.com.saborearte.model.Usuario;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Locale;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/** Interface única de escrita da auditoria; nunca abre outra conexão. */
public final class LogUtil {
    public static final String CRIAR_RASCUNHO="CRIAR_RASCUNHO",ENVIAR_REVISAO="ENVIAR_REVISAO",APROVAR_RECEITA="APROVAR_RECEITA",REJEITAR_RECEITA="REJEITAR_RECEITA",ALTERAR_ATIVIDADE="ALTERAR_ATIVIDADE",COMENTAR="COMENTAR",RESPONDER_COMENTARIO="RESPONDER_COMENTARIO",MODERAR_COMENTARIO="MODERAR_COMENTARIO",LOGIN="LOGIN";
    public static final String RECEITA="RECEITA",COMENTARIO="COMENTARIO",USUARIO="USUARIO",RELATORIO="RELATORIO",SESSAO="SESSAO";
    private LogUtil(){}

    /** Usa a transação do chamador e propaga falhas sem fazer commit ou rollback. */
    public static void registrar(Connection conexao,HttpServletRequest request,String acao,String entidade,String detalhes)throws SQLException{
        if(conexao==null)throw new SQLException("Conexão obrigatória para auditoria.");
        if(request==null)throw new SQLException("Requisição obrigatória para auditoria.");
        HttpSession sessao=request.getSession(false);Usuario usuario=sessao==null?null:(Usuario)sessao.getAttribute("usuarioLogado");
        if(usuario==null)throw new SQLException("Usuário autenticado obrigatório para auditoria.");
        Log log=new Log();log.setUsuario(usuario.getId_usuario());log.setEntidade_log(normalizarEntidade(entidade));log.setAcao_log(normalizarAcao(acao,log.getEntidade_log(),detalhes));log.setDetalhe_log(detalhes==null?"":detalhes.trim());
        if(!java.util.Set.of(RECEITA,COMENTARIO,USUARIO,RELATORIO,SESSAO).contains(log.getEntidade_log()))throw new SQLException("Entidade de auditoria inválida.");
        if(!java.util.Set.of(CRIAR_RASCUNHO,ENVIAR_REVISAO,APROVAR_RECEITA,REJEITAR_RECEITA,ALTERAR_ATIVIDADE,COMENTAR,RESPONDER_COMENTARIO,MODERAR_COMENTARIO,LOGIN).contains(log.getAcao_log()))throw new SQLException("Ação de auditoria inválida.");
        new LogDAO(conexao).registrar(log,log.getEntidade_log());
    }
    public static String normalizarAcao(String valor){String v=chave(valor);return switch(v){case "CRIACAO"->CRIAR_RASCUNHO;case "EDICAO","ALTERACAO"->ALTERAR_ATIVIDADE;case "APROVACAO","PUBLICACAO"->APROVAR_RECEITA;case "REJEICAO"->REJEITAR_RECEITA;case "RESPOSTA"->RESPONDER_COMENTARIO;case "DENUNCIA","EXCLUSAO"->MODERAR_COMENTARIO;default->v;};}
    private static String normalizarAcao(String valor,String entidade,String detalhes){String v=chave(valor),d=chave(detalhes);if(COMENTARIO.equals(entidade)){return switch(v){case "CRIACAO"->COMENTAR;case "RESPOSTA"->RESPONDER_COMENTARIO;case "APROVACAO","REJEICAO","DENUNCIA","EXCLUSAO"->MODERAR_COMENTARIO;default->normalizarAcao(v);};}if(RECEITA.equals(entidade)){if(("CRIACAO".equals(v)||"EDICAO".equals(v))&&d.contains("REVISAO"))return ENVIAR_REVISAO;return normalizarAcao(v);}if(USUARIO.equals(entidade)&&java.util.Set.of("CRIACAO","EDICAO","ALTERACAO").contains(v))return ALTERAR_ATIVIDADE;return normalizarAcao(v);}
    public static String normalizarEntidade(String valor){String v=chave(valor);return switch(v){case "RECEITA"->RECEITA;case "COMENTARIO"->COMENTARIO;case "USUARIO","PERFIL","CONFIGURACAO"->USUARIO;case "RELATORIO"->RELATORIO;case "SISTEMA","SESSAO"->SESSAO;default->v;};}
    private static String chave(String valor){if(valor==null||valor.isBlank())return "";return java.text.Normalizer.normalize(valor.trim(),java.text.Normalizer.Form.NFD).replaceAll("\\p{M}","").replace(' ','_').toUpperCase(Locale.ROOT);}
}
