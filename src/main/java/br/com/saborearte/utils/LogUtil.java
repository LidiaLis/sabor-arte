package br.com.saborearte.utils;

import java.sql.Connection;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import br.com.saborearte.dao.LogDAO;
import br.com.saborearte.model.Log;
import br.com.saborearte.model.Usuario;

/** Registra auditoria sem interromper o fluxo principal em caso de falha. */
public final class LogUtil {
    private LogUtil() { }

    public static void registrar(Connection conexao, HttpServletRequest request,
                                 String acao, String entidade, String detalhes) {
        if (conexao == null || request == null) return;
        try {
            HttpSession session = request.getSession(false);
            Usuario usuario = session == null ? null : (Usuario) session.getAttribute("usuarioLogado");
            if (usuario == null) return;
            Log log = new Log();
            log.setUsuario(usuario.getId_usuario());
            log.setAcao_log(acao);
            log.setDetalhe_log(detalhes);
            log.setEntidade_log(entidade);
            new LogDAO(conexao).registrar(log, entidade);
        } catch (Exception e) {
            System.err.println("[LogUtil] Falha ao registrar auditoria: " + e.getMessage());
        }
    }
}


