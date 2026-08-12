package br.com.saborearte.dao;

import br.com.saborearte.model.Fluxo;
import br.com.saborearte.model.Fluxo.StatusFluxo;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO de Fluxo (histórico de moderação editorial: pendente -> aprovado /
 * rejeitado / em_revisao). Usado pelo relatório "⚙️ Fluxo Editorial" em
 * relatorio-admin.html.
 *
 * OBS: o FluxoDAO.java anterior era uma cópia colada do model Fluxo.java
 * (mesmos atributos, sem Connection nem SQL) — não fazia nada de banco.
 * Reescrito do zero seguindo o padrão do ComentarioDAO/FavoritoDAO.
 */
public class FluxoDAO {

    private final Connection conexao;

    public FluxoDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // REGISTRAR TRANSIÇÃO DE FLUXO
    // =========================================================================

    /**
     * Registra uma transição de status no fluxo editorial de uma receita
     * (ex.: autor envia pra revisão, admin aprova/rejeita). data_fluxo
     * preenchida com NOW() no INSERT.
     */
    public void registrarFluxo(Fluxo fluxo) throws SQLException {

        String sql = """
                INSERT INTO fluxo (receita, usuario, status_fluxo, observacao_fluxo, data_fluxo)
                VALUES (?, ?, ?, ?, NOW())
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, fluxo.getReceita());
            stmt.setInt(2, fluxo.getUsuario());
            stmt.setString(3, fluxo.getStatus_fluxo().name());
            stmt.setString(4, fluxo.getObservacao_fluxo());
            stmt.executeUpdate();
        }
    }

    // =========================================================================
    // HISTÓRICO DE UMA RECEITA (linha do tempo de moderação)
    // =========================================================================

    public List<Fluxo> listarPorReceita(int idReceita) throws SQLException {

        String sql = """
                SELECT id_fluxo, receita, usuario, status_fluxo, observacao_fluxo, data_fluxo
                FROM fluxo
                WHERE receita = ?
                ORDER BY data_fluxo ASC
                """;

        List<Fluxo> lista = new ArrayList<>();

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idReceita);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // RELATÓRIO — relatorio-admin.html ("⚙️ Fluxo Editorial")
    // =========================================================================

    /**
     * Lista o histórico de fluxo já com título da receita e nome do
     * responsável (JOIN), filtrando por status e/ou período — direto pras
     * colunas Receita / Ação / Responsável / De / Para / Data da tela.
     *
     * OBS sobre "De" / "Para": o model Fluxo só guarda o status_fluxo do
     * registro atual (o "Para"), não o status anterior ("De"). A tela mockada
     * mostra os dois porque no mock os dados já vêm prontos. Pra calcular o
     * "De" de verdade eu preciso olhar o status_fluxo do registro anterior da
     * mesma receita (LAG por data_fluxo) — deixei isso resolvido abaixo com
     * uma subquery correlacionada; funciona, mas em volumes grandes de fluxo
     * por receita pode valer trocar por window function (LAG) se seu MySQL for 8+.
     */
    public List<FluxoRelatorio> listarRelatorio(StatusFluxo status,
                                                 java.time.LocalDate dataInicio,
                                                 java.time.LocalDate dataFim) throws SQLException {

        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (status != null) {
            where.append(" AND f.status_fluxo = ? ");
            params.add(status.name());
        }
        if (dataInicio != null) {
            where.append(" AND f.data_fluxo >= ? ");
            params.add(java.sql.Date.valueOf(dataInicio));
        }
        if (dataFim != null) {
            where.append(" AND f.data_fluxo <= ? ");
            params.add(java.sql.Date.valueOf(dataFim.plusDays(1)));
        }

        String sql = """
                SELECT
                    f.id_fluxo,
                    f.status_fluxo,
                    f.observacao_fluxo,
                    f.data_fluxo,
                    r.titulo_receita,
                    u.nome_usuario AS responsavel,
                    (SELECT f2.status_fluxo
                       FROM fluxo f2
                      WHERE f2.receita = f.receita
                        AND f2.data_fluxo < f.data_fluxo
                      ORDER BY f2.data_fluxo DESC
                      LIMIT 1) AS status_anterior
                FROM fluxo f
                JOIN receita r ON r.id_receita = f.receita
                JOIN usuario u ON u.id_usuario = f.usuario
                """ + where + " ORDER BY f.data_fluxo DESC ";

        List<FluxoRelatorio> lista = new ArrayList<>();

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                stmt.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    FluxoRelatorio fr = new FluxoRelatorio();
                    fr.idFluxo = rs.getInt("id_fluxo");
                    fr.tituloReceita = rs.getString("titulo_receita");
                    fr.responsavel = rs.getString("responsavel");
                    fr.statusPara = rs.getString("status_fluxo");
                    fr.statusDe = rs.getString("status_anterior"); // pode vir null (1ª transição da receita)
                    fr.observacao = rs.getString("observacao_fluxo");
                    fr.dataFluxo = rs.getString("data_fluxo");
                    lista.add(fr);
                }
            }
        }

        return lista;
    }

    /** DTO simples pra alimentar a tabela do relatório sem forçar campos extras no model Fluxo. */
    public static class FluxoRelatorio {
        public int idFluxo;
        public String tituloReceita;
        public String responsavel;
        public String statusDe;   // pode ser null (primeira transição da receita)
        public String statusPara;
        public String observacao;
        public String dataFluxo;
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Fluxo mapear(ResultSet rs) throws SQLException {

        Fluxo f = new Fluxo();

        f.setId_fluxo(rs.getInt("id_fluxo"));
        f.setReceita(rs.getInt("receita"));
        f.setUsuario(rs.getInt("usuario"));
        f.setObservacao_fluxo(rs.getString("observacao_fluxo"));
        f.setData_fluxo(rs.getString("data_fluxo"));

        f.setStatus_fluxo(
                StatusFluxo.valueOf(
                        rs.getString("status_fluxo")
                )
        );

        return f;
    }
}