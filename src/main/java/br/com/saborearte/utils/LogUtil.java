package br.com.saborearte.utils;

import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.model.Log;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.utils.LogUtil;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.sql.Connection;

// Utilitário estático para registrar logs de qualquer Controller.
 
public class LogUtil {
/*

	
    public static void registrar(Connection conexao,
                                  HttpServletRequest request,
                                  String acao,
                                  String entidade,
                                  Integer entidadeId,
                                  String detalhes) {
        try {
            HttpSession session    = request.getSession(false);
            Integer     usuarioId  = null;
            String      usuarioNome = "Sistema";

            if (session != null) {
            	Object usuarioObj = session.getAttribute("usuarioLogado");

            	if (usuarioObj != null) {
            	    Usuario usuario = (Usuario) usuarioObj;
            	    usuarioId = usuario.getId_usuario();
            	    usuarioNome = usuario.getNome_usuario();
            	}
            }

            Log log = new Log(
                usuarioId, usuarioNome,
                acao, entidade, entidadeId, detalhes
            );

            new LogDAO(conexao).registrar(log);

        } catch (Exception e) {
            // Log nunca deve quebrar o fluxo principal
            System.err.println("[LogUtil] Erro ao registrar log: " + e.getMessage());
        }
    }

    //Sobrecarga sem entidadeId (para ações gerais como LOGIN, BACKUP etc.)
    public static void registrar(Connection conexao,
                                  HttpServletRequest request,
                                  String acao,
                                  String entidade,
                                  String detalhes) {
        registrar(conexao, request, acao, entidade, null, detalhes);
    }*/
}