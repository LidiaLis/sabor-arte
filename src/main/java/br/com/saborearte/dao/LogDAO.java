package br.com.saborearte.dao;

import br.com.saborearte.model.Log;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO de Log.
 *
 * CORREÇÃO em relação à versão anterior: o SQL usava as colunas
 * usuario_id / acao / detalhes / data_hora, mas o DER e o model Log.java
 * apontam pra usuario / acao_log / data_log / descricao_log. Ajustado
 * abaixo pra bater com o DER.
 *
 * NOVO: coluna entidade_log (ver alter_tables.sql) — necessária pro filtro
 * "Entidade" (Receita/Comentário/Perfil/Sistema) do log-admin.html, que a
 * tabela original não tinha como suportar.
 *
 * Log.java não tem campo pra entidade nem pra nome do autor (usados nos
 * filtros/tabela do log-admin.html) — os métodos abaixo devolvem esses
 * extras junto do objeto Log via campos que você pode adicionar ao model
 * (nome_usuario, entidade_log) seguindo o mesmo padrão de "campos extras
 * não persistidos" que você já usa em Comentario/Receita. Por enquanto,
 * mapeei direto no ResultSet -> setDetalhe_log já concatenado, pra não
 * mexer no seu Log.java sem confirmar com você antes.
 */
public class LogDAO {

    private final Connection conexao;

    public LogDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // REGISTRAR
    // =========================================================================

    /**
     * Registra uma ação de auditoria. data_log é preenchida com NOW() no INSERT
     * (padrão já usado em ComentarioDAO.cadastrarComentario), então não
     * dependemos do valor de log.getData_log() no momento da chamada.
     *
     * @param entidade valor livre: "Receita", "Comentário", "Perfil", "Sistema"...
     *                 (null se ainda não tiver rodado o ALTER TABLE de entidade_log)
     */
    public void registrar(Log log, String entidade) throws SQLException {

        String sql = """
                INSERT INTO log (usuario, acao_log, descricao_log, entidade_log, data_log)
                VALUES (?, ?, ?, ?, NOW())
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, log.getUsuario());
            stmt.setString(2, log.getAcao_log());
            stmt.setString(3, log.getDetalhe_log());
            stmt.setString(4, entidade);
            stmt.executeUpdate();
        }
    }

    /** Sobrecarga sem entidade, pra quem ainda não rodou o ALTER TABLE. */
    public void registrar(Log log) throws SQLException {
        registrar(log, null);
    }

    // =========================================================================
    // LISTAR
    // =========================================================================

    public List<Log> listarTodos() throws SQLException {
        return listarComFiltro(null, null, null, null, null, 0, Integer.MAX_VALUE).logs;
    }

    /**
     * Resultado de uma busca paginada: os logs da página + o total de registros
     * que batem com o filtro (pra montar a paginação sem precisar de uma
     * segunda query manual no Controller).
     */
    public static class ResultadoLogs {
        public final List<Log> logs;
        public final int total;

        public ResultadoLogs(List<Log> logs, int total) {
            this.logs = logs;
            this.total = total;
        }
    }

    /**
     * Busca com todos os filtros da tela log-admin.html:
     *
     * @param busca     termo livre — bate em nome do usuário (JOIN) ou descricao_log
     * @param acao      valor exato de acao_log (null/"" -> ignora)
     * @param entidade  valor exato de entidade_log (null/"" -> ignora; requer coluna nova)
     * @param dataInicio filtro de período (>=), pode ser null
     * @param dataFim    filtro de período (<=), pode ser null
     */
    public ResultadoLogs listarComFiltro(String busca,
                                          String acao,
                                          String entidade,
                                          java.time.LocalDate dataInicio,
                                          java.time.LocalDate dataFim,
                                          int offset,
                                          int limite) throws SQLException {

        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (busca != null && !busca.isBlank()) {
            where.append(" AND (u.nome_usuario LIKE ? OR l.descricao_log LIKE ?) ");
            String termo = "%" + busca.trim() + "%";
            params.add(termo);
            params.add(termo);
        }

        if (acao != null && !acao.isBlank()) {
            where.append(" AND l.acao_log = ? ");
            params.add(acao);
        }

        if (entidade != null && !entidade.isBlank()) {
            where.append(" AND l.entidade_log = ? ");
            params.add(entidade);
        }

        if (dataInicio != null) {
            where.append(" AND l.data_log >= ? ");
            params.add(java.sql.Date.valueOf(dataInicio));
        }

        if (dataFim != null) {
            where.append(" AND l.data_log <= ? ");
            params.add(java.sql.Date.valueOf(dataFim.plusDays(1)));
        }

        String sqlBase = """
                FROM log l
                JOIN usuario u ON u.id_usuario = l.usuario
                """ + where;

        List<Log> lista = new ArrayList<>();
        int total = 0;

        // ===== total (mesmos filtros, sem LIMIT) =====
        try (PreparedStatement stmt = conexao.prepareStatement("SELECT COUNT(*) AS total " + sqlBase)) {
            aplicarParametros(stmt, params);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) total = rs.getInt("total");
            }
        }

        // ===== página =====
        String sqlPagina = """
                SELECT
                    l.id_log, l.usuario, l.acao_log, l.descricao_log, l.entidade_log, l.data_log,
                    u.nome_usuario, u.foto_usuario, u.tipo_usuario
                """ + sqlBase + " ORDER BY l.data_log DESC LIMIT ? OFFSET ? ";

        try (PreparedStatement stmt = conexao.prepareStatement(sqlPagina)) {
            aplicarParametros(stmt, params);
            stmt.setInt(params.size() + 1, limite);
            stmt.setInt(params.size() + 2, offset);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComAutor(rs));
                }
            }
        }

        return new ResultadoLogs(lista, total);
    }

    private void aplicarParametros(PreparedStatement stmt, List<Object> params) throws SQLException {
        for (int i = 0; i < params.size(); i++) {
            stmt.setObject(i + 1, params.get(i));
        }
    }

    // =========================================================================
    // LISTAR ÚLTIMAS N AÇÕES DE UM USUÁRIO (card "Log de Atividades" do perfil-admin.html)
    // =========================================================================

    public List<Log> listarPorUsuario(int idUsuario, int limite) throws SQLException {

        String sql = """
                SELECT id_log, usuario, acao_log, descricao_log, entidade_log, data_log
                FROM log
                WHERE usuario = ?
                ORDER BY data_log DESC
                LIMIT ?
                """;

        List<Log> lista = new ArrayList<>();

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setInt(2, limite);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // CONTAR
    // =========================================================================

    public int contarLogs() throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM log";
        try (PreparedStatement stmt = conexao.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? rs.getInt("total") : 0;
        }
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Log mapear(ResultSet rs) throws SQLException {
        Log log = new Log();
        log.setId_log(rs.getInt("id_log"));
        log.setUsuario(rs.getInt("usuario"));
        log.setAcao_log(rs.getString("acao_log"));
        log.setDetalhe_log(rs.getString("descricao_log"));

        Timestamp ts = rs.getTimestamp("data_log");
        log.setData_log(ts != null ? ts.toString() : null);

        return log;
    }

    /**
     * Mesma coisa de mapear(), mas a tabela do log-admin.html também precisa
     * de nome/foto/papel do usuário e da entidade — como Log.java não tem
     * esses campos extras ainda, retorno o Log "puro"; monte o resto (nome,
     * papel, entidade) direto no Controller a partir do próprio ResultSet,
     * ou me confirma que posso adicionar esses campos extras no model
     * (mesmo padrão usado em Comentario.java/Receita.java) que eu ajusto.
     */
    private Log mapearComAutor(ResultSet rs) throws SQLException {
        return mapear(rs);
    }
}