package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Passo;

public class PassoDAO {

    private final Connection conexao;

    public PassoDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // LISTAR (tela de detalhe — "Modo de Preparo")
    // =========================================================================

    public List<Passo> listarPassosPorReceita(int idReceita) throws SQLException {

        String sql = """
                SELECT id_passo, receita, ordem_passo, titulo_passo, descricao_passo
                FROM passo
                WHERE receita = ?
                ORDER BY ordem_passo ASC
                """;

        List<Passo> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // CRUD (para a futura tela de cadastro/edição de receita)
    // =========================================================================

    public void cadastrarPasso(Passo passo) throws SQLException {

        String sql = """
                INSERT INTO passo (receita, ordem_passo, titulo_passo, descricao_passo)
                VALUES (?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, passo.getReceita());
            ps.setInt(2, passo.getOrdem_passo());
            ps.setString(3, passo.getTitulo_passo());
            ps.setString(4, passo.getDescricao_passo());
            ps.executeUpdate();
        }
    }

    public void atualizarPasso(Passo passo) throws SQLException {

        String sql = """
                UPDATE passo
                SET ordem_passo = ?, titulo_passo = ?, descricao_passo = ?
                WHERE id_passo = ?
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, passo.getOrdem_passo());
            ps.setString(2, passo.getTitulo_passo());
            ps.setString(3, passo.getDescricao_passo());
            ps.setInt(4, passo.getId_passo());
            ps.executeUpdate();
        }
    }

    public void excluirPasso(int idPasso) throws SQLException {

        String sql = "DELETE FROM passo WHERE id_passo = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idPasso);
            ps.executeUpdate();
        }
    }

    /**
     * Remove todos os passos de uma receita de uma vez — útil quando a
     * tela de edição salva o modo de preparo inteiro de novo (apaga tudo
     * e recadastra na ordem atual), em vez de tentar dar match passo a passo.
     */
    public void excluirPassosDaReceita(int idReceita) throws SQLException {

        String sql = "DELETE FROM passo WHERE receita = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Passo mapear(ResultSet rs) throws SQLException {

        Passo p = new Passo();
        p.setId_passo(rs.getInt("id_passo"));
        p.setReceita(rs.getInt("receita"));
        p.setOrdem_passo(rs.getInt("ordem_passo"));
        p.setTitulo_passo(rs.getString("titulo_passo"));
        p.setDescricao_passo(rs.getString("descricao_passo"));
        return p;
    }
}