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

    // registra log
    public void registrar(Log log) throws Exception {
        String sql = "INSERT INTO log " +
                     "(usuario_id, usuario_nome, acao, entidade, entidade_id, detalhes) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";

        PreparedStatement stmt = conexao.prepareStatement(sql);

        if (log.getUsuarioId() != null) {
            stmt.setInt(1, log.getUsuarioId());
        } else {
            stmt.setNull(1, java.sql.Types.INTEGER);
        }

        stmt.setString(2, log.getUsuarioNome());
        stmt.setString(3, log.getAcao());
        stmt.setString(4, log.getEntidade());

        if (log.getEntidadeId() != null) {
            stmt.setInt(5, log.getEntidadeId());
        } else {
            stmt.setNull(5, Types.INTEGER);
        }

        stmt.setString(6, log.getDetalhes());

        stmt.executeUpdate();
        stmt.close();
    }

    // lista todos os logs
    public List<Log> listarTodos() throws Exception {
        return listarComFiltro(null, null, null);
    }

    // filtra o log
    public List<Log> listarComFiltro(String acao, String entidade, Integer limite) throws Exception {
        List<Log> lista = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
            "SELECT id_log, usuario_id, usuario_nome, acao, entidade, " +
            "entidade_id, detalhes, data_hora " +
            "FROM log WHERE 1=1 "
        );

        if (acao     != null) sql.append("AND acao = ? ");
        if (entidade != null) sql.append("AND entidade = ? ");
        sql.append("ORDER BY data_hora DESC ");
        if (limite   != null) sql.append("LIMIT " + limite);

        PreparedStatement stmt = conexao.prepareStatement(sql.toString());

        int idx = 1;
        if (acao     != null) stmt.setString(idx++, acao);
        if (entidade != null) stmt.setString(idx,   entidade);

        ResultSet rs = stmt.executeQuery();

        while (rs.next()) {
            lista.add(montarLog(rs));
        }

        rs.close();
        stmt.close();
        return lista;
    }

    // limpar todos os logs
    public void limparTodos() throws Exception {
        String sql = "DELETE FROM log";
        PreparedStatement stmt = conexao.prepareStatement(sql);
        stmt.executeUpdate();
        stmt.close();
    }

    // conta tudo
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

    // monta o log com as entidades e ações padrão
    private Log montarLog(ResultSet rs) throws Exception {
        Log log = new Log();

        log.setId_log(rs.getInt("id_log"));

        int uid = rs.getInt("usuario_id");
        log.setUsuarioId(rs.wasNull() ? null : uid);

        log.setUsuarioNome(rs.getString("usuario_nome"));
        log.setAcao(rs.getString("acao"));
        log.setEntidade(rs.getString("entidade"));

        int eid = rs.getInt("entidade_id");
        log.setEntidadeId(rs.wasNull() ? null : eid);

        log.setDetalhes(rs.getString("detalhes"));
        log.setDataHora(rs.getTimestamp("data_hora"));

        return log;
    }
}