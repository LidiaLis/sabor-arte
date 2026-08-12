package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Favorito;
import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Receita.StatusReceita;

/**
 * DAO de Favorito.
 *
 * Tabela conforme o DER: favorito (id_usuario, id_receita, data_favorito),
 * chave primária composta (id_usuario, id_receita).
 *
 * OBS: o comentário de CREATE TABLE em Favorito.java está como
 * "receita_favorita" — se o banco real usar esse nome em vez de "favorito",
 * é só trocar a constante TABELA abaixo.
 */
public class FavoritoDAO {

    private static final String TABELA = "favorito";

    private final Connection conexao;

    public FavoritoDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // FAVORITAR
    // =========================================================================

    /**
     * Marca uma receita como favorita para o usuário. Não faz nada (silenciosamente)
     * se já existir o par (id_usuario, id_receita) — evita duplicidade sem precisar
     * de try/catch de chave duplicada no Controller.
     */
    public void favoritar(int idUsuario, int idReceita) throws SQLException {

        if (isFavorito(idUsuario, idReceita)) {
            return;
        }

        String sql = """
                INSERT INTO %s (id_usuario, id_receita, data_favorito)
                VALUES (?, ?, NOW())
                """.formatted(TABELA);

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idReceita);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // DESFAVORITAR
    // =========================================================================

    public void desfavoritar(int idUsuario, int idReceita) throws SQLException {

        String sql = """
                DELETE FROM %s
                WHERE id_usuario = ? AND id_receita = ?
                """.formatted(TABELA);

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idReceita);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // TOGGLE (usado pelo botão ☆/★ Favoritar das telas de visitante)
    // =========================================================================

    /**
     * Alterna o estado de favorito. Retorna o novo estado:
     * true  -> acabou de favoritar
     * false -> acabou de desfavoritar
     */
    public boolean toggleFavorito(int idUsuario, int idReceita) throws SQLException {

        if (isFavorito(idUsuario, idReceita)) {
            desfavoritar(idUsuario, idReceita);
            return false;
        } else {
            favoritar(idUsuario, idReceita);
            return true;
        }
    }

    // =========================================================================
    // VERIFICAR SE JÁ É FAVORITO
    // =========================================================================

    public boolean isFavorito(int idUsuario, int idReceita) throws SQLException {

        String sql = """
                SELECT 1
                FROM %s
                WHERE id_usuario = ? AND id_receita = ?
                """.formatted(TABELA);

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idReceita);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // =========================================================================
    // LISTAR IDS DE RECEITAS FAVORITAS DE UM USUÁRIO
    // =========================================================================

    /**
     * Retorna só os ids das receitas favoritadas pelo usuário — útil na tela
     * de listagem (receitas-visitante.html) pra marcar em lote quais cards já
     * devem nascer com o botão "★ Favoritado" sem precisar de N consultas.
     */
    public List<Integer> listarIdsReceitasFavoritas(int idUsuario) throws SQLException {

        String sql = """
                SELECT id_receita
                FROM %s
                WHERE id_usuario = ?
                """.formatted(TABELA);

        List<Integer> ids = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getInt("id_receita"));
                }
            }
        }

        return ids;
    }

    // =========================================================================
    // LISTAR FAVORITOS COMPLETOS (para a tela receitas-favoritas.html)
    // =========================================================================

    /**
     * Traz as receitas favoritas do usuário já com dados de categoria e autor,
     * pra popular os cards de receitas-favoritas.html direto, sem tela ficar
     * fazendo N+1 consultas em ReceitaDAO.
     */
    public List<Favorito> listarFavoritosPorUsuario(int idUsuario) throws SQLException {

        String sql = """
                SELECT id_usuario, id_receita, data_favorito
                FROM %s
                WHERE id_usuario = ?
                ORDER BY data_favorito DESC
                """.formatted(TABELA);

        List<Favorito> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapear(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // LISTAR RECEITAS FAVORITAS COM DETALHES (categoria via JOIN)
    // =========================================================================

    /**
     * Traz as receitas favoritadas pelo usuário já com nome/emoji da categoria,
     * prontas pra montar os cards direto (imagem, título, categoria) sem o
     * Controller precisar ficar chamando ReceitaDAO receita a receita.
     *
     * Usos:
     *  - perfil-visitante.html: listarReceitasFavoritasDetalhado(idUsuario, 3)
     *    → mini grid "Minhas Receitas Favoritadas" (só as 3 mais recentes)
     *  - receitas-favoritas.html: listarReceitasFavoritasDetalhado(idUsuario, null)
     *    → lista completa, sem limite
     *
     * Só traz receitas com status_receita = 'publicada' — evita mostrar no
     * perfil uma receita que o autor arquivou/despublicou depois de favoritada.
     */
    public List<Receita> listarReceitasFavoritasDetalhado(int idUsuario, Integer limite) throws SQLException {

        StringBuilder sql = new StringBuilder("""
                SELECT
                    r.id_receita,
                    r.categoria,
                    r.usuario,
                    r.titulo_receita,
                    r.descricao_receita,
                    r.data_criacao_receita,
                    r.data_publicacao_receita,
                    r.tempo_preparo_receita,
                    r.rendimento_receita,
                    r.imagem_receita,
                    r.status_receita,
                    r.visualizacoes_receita,
                    c.nome_categoria,
                    c.emoji_categoria
                FROM %s f
                JOIN receita r   ON r.id_receita = f.id_receita
                JOIN categoria c ON c.id_categoria = r.categoria
                WHERE f.id_usuario = ?
                  AND r.status_receita = 'publicada'
                ORDER BY f.data_favorito DESC
                """.formatted(TABELA));

        if (limite != null) {
            sql.append(" LIMIT ?");
        }

        List<Receita> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql.toString())) {
            ps.setInt(1, idUsuario);

            if (limite != null) {
                ps.setInt(2, limite);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearReceitaComCategoria(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // CONTAR FAVORITOS DE UMA RECEITA (opcional — estatística)
    // =========================================================================

    public int contarFavoritosPorReceita(int idReceita) throws SQLException {

        String sql = """
                SELECT COUNT(*) AS total
                FROM %s
                WHERE id_receita = ?
                """.formatted(TABELA);

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }

        return 0;
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Receita mapearReceitaComCategoria(ResultSet rs) throws SQLException {

        Receita r = new Receita();

        r.setId_receita(rs.getInt("id_receita"));
        r.setCategoria(rs.getInt("categoria"));
        r.setUsuario(rs.getInt("usuario"));
        r.setTitulo_receita(rs.getString("titulo_receita"));
        r.setDescricao_receita(rs.getString("descricao_receita"));
        r.setData_criacao_receita(rs.getString("data_criacao_receita"));
        r.setData_publicacao_receita(rs.getString("data_publicacao_receita"));
        r.setTempo_preparo_receita(rs.getInt("tempo_preparo_receita"));
        r.setRendimento_receita(rs.getString("rendimento_receita"));
        r.setImagem_receita(rs.getString("imagem_receita"));
        r.setVisualizacoes_receita(rs.getInt("visualizacoes_receita"));

        r.setStatus_receita(
                StatusReceita.valueOf(
                        rs.getString("status_receita")
                )
        );

        // ===== Campos extras (não persistidos) =====
        r.setNome_categoria(rs.getString("nome_categoria"));
        r.setEmoji_categoria(rs.getString("emoji_categoria"));

        return r;
    }

    private Favorito mapear(ResultSet rs) throws SQLException {

        Favorito f = new Favorito();

        f.setIdUsuario(rs.getInt("id_usuario"));
        f.setIdReceita(rs.getInt("id_receita"));

        Timestamp ts = rs.getTimestamp("data_favorito");
        f.setDataFavorito(ts != null ? ts.toLocalDateTime() : null);

        return f;
    }
}