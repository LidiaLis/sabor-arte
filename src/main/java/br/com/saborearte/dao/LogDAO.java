package br.com.saborearte.dao;

import br.com.saborearte.model.Log;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LogDAO {

    private Connection conexao;

    public LogDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // ===== Registra log =====

    public void registrar(Log log) throws Exception {
        String sql = "INSERT INTO log (usuario_id, acao, detalhes, data_hora) " +
                     "VALUES (?, ?, ?, ?)";

        PreparedStatement stmt = conexao.prepareStatement(sql);
        stmt.setInt(1, log.getUsuario());
        stmt.setString(2, log.getAcao_log());
        stmt.setString(3, log.getDetalhe_log());
        stmt.setString(4, log.getData_log());
        stmt.executeUpdate();
        stmt.close();
    }

    // ===== Lista todos os logs =====

    public List<Log> listarTodos() throws Exception {
        return listarComFiltro(null, null);
    }

    // ===== Lista com filtro opcional de ação e limite =====

    public List<Log> listarComFiltro(String acao, Integer limite) throws Exception {
        List<Log> lista = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
            "SELECT id_log, usuario_id, acao, detalhes, data_hora " +
            "FROM log WHERE 1=1 "
        );

        if (acao != null) sql.append("AND acao = ? ");
        sql.append("ORDER BY data_hora DESC ");
        if (limite != null) sql.append("LIMIT " + limite);

        PreparedStatement stmt = conexao.prepareStatement(sql.toString());

        if (acao != null) stmt.setString(1, acao);

        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            lista.add(montarLog(rs));
        }

        rs.close();
        stmt.close();
        return lista;
    }

    // ===== Remove todos os logs =====

    public void limparTodos() throws Exception {
        String sql = "DELETE FROM log";
        PreparedStatement stmt = conexao.prepareStatement(sql);
        stmt.executeUpdate();
        stmt.close();
    }

    // ===== Conta total de logs =====

    public int contarLogs() throws Exception {
        String sql = "SELECT COUNT(*) FROM log";
        PreparedStatement stmt = conexao.prepareStatement(sql);
        ResultSet rs = stmt.executeQuery();
        int total = 0;
        if (rs.next()) total = rs.getInt(1);
        rs.close();
        stmt.close();
        return total;
    }

    // ===== Monta objeto Log a partir do ResultSet =====

    private Log montarLog(ResultSet rs) throws Exception {
        Log log = new Log();
        log.setId_log(rs.getInt("id_log"));
        log.setUsuario(rs.getInt("usuario_id"));
        log.setAcao_log(rs.getString("acao"));
        log.setDetalhe_log(rs.getString("detalhes"));
        log.setData_log(rs.getString("data_hora"));
        return log;
    }
}