package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.CategoriaCor;
import br.com.saborearte.model.CategoriaEmoji;

public class CategoriaDAO {

    private final Connection conexao;

    public CategoriaDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // CATEGORIA — CRUD PRINCIPAL
    // =========================================================================

    public List<Categoria> listarCategorias() throws SQLException {
        String sql = """
                SELECT
                    id_categoria,
                    nome_categoria,
                    descricao_categoria,
                    emoji_categoria,
                    cor_categoria,
                    status_categoria
                FROM categoria
                ORDER BY nome_categoria ASC
                """;

        List<Categoria> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapearCategoria(rs));
            }
        }

        return lista;
    }

    public Categoria buscarCategoriaPorId(int id) throws SQLException {
        String sql = """
                SELECT
                    id_categoria,
                    nome_categoria,
                    descricao_categoria,
                    emoji_categoria,
                    cor_categoria,
                    status_categoria
                FROM categoria
                WHERE id_categoria = ?
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapearCategoria(rs);
                }
            }
        }

        return null;
    }

    public void cadastrarCategoria(Categoria categoria) throws SQLException {
        String sql = """
                INSERT INTO categoria
                    (nome_categoria, descricao_categoria, emoji_categoria, cor_categoria, status_categoria)
                VALUES (?, ?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, categoria.getNome_categoria());
            ps.setString(2, categoria.getDescricao_categoria());
            ps.setString(3, categoria.getEmoji_categoria());
            ps.setString(4, categoria.getCor_categoria());
            ps.setString(5, categoria.getStatus_categoria().name());
            ps.executeUpdate();
        }
    }

    public void atualizarCategoria(Categoria categoria) throws SQLException {
        String sql = """
                UPDATE categoria
                SET
                    nome_categoria       = ?,
                    descricao_categoria  = ?,
                    emoji_categoria      = ?,
                    cor_categoria        = ?,
                    status_categoria     = ?
                WHERE id_categoria = ?
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, categoria.getNome_categoria());
            ps.setString(2, categoria.getDescricao_categoria());
            ps.setString(3, categoria.getEmoji_categoria());
            ps.setString(4, categoria.getCor_categoria());
            ps.setString(5, categoria.getStatus_categoria().name());
            ps.setInt(6, categoria.getId_categoria());
            ps.executeUpdate();
        }
    }

    public void excluirCategoria(int id) throws SQLException {
        String sql = "DELETE FROM categoria WHERE id_categoria = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // CATEGORIA — VALIDAÇÕES
    // =========================================================================

    public boolean nomeJaExiste(String nome) throws SQLException {
        String sql = "SELECT 1 FROM categoria WHERE LOWER(nome_categoria) = LOWER(?) LIMIT 1";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, nome.trim());

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean nomeJaExiste(String nome, int idExcluir) throws SQLException {
        String sql = """
                SELECT 1 FROM categoria
                WHERE LOWER(nome_categoria) = LOWER(?)
                  AND id_categoria <> ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, nome.trim());
            ps.setInt(2, idExcluir);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // =========================================================================
    // PALETA DE EMOJIS (tabela categoria_emoji)
    // =========================================================================

    public List<CategoriaEmoji> listarEmojis() throws SQLException {
        String sql = "SELECT id_emoji, unicode_emoji FROM categoria_emoji ORDER BY id_emoji ASC";

        List<CategoriaEmoji> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                CategoriaEmoji e = new CategoriaEmoji();
                e.setId_emoji(rs.getInt("id_emoji"));
                e.setUnicode_emoji(rs.getString("unicode_emoji"));
                lista.add(e);
            }
        }

        return lista;
    }

    public CategoriaEmoji buscarEmojiPorUnicode(String unicode) throws SQLException {
        String sql = "SELECT id_emoji, unicode_emoji FROM categoria_emoji WHERE unicode_emoji = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, unicode);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    CategoriaEmoji e = new CategoriaEmoji();
                    e.setId_emoji(rs.getInt("id_emoji"));
                    e.setUnicode_emoji(rs.getString("unicode_emoji"));
                    return e;
                }
            }
        }

        return null;
    }

    // =========================================================================
    // PALETA DE CORES (tabela categoria_cor)
    // =========================================================================

    public List<CategoriaCor> listarCores() throws SQLException {
        String sql = "SELECT id_cor, unicode_cor FROM categoria_cor ORDER BY id_cor ASC";

        List<CategoriaCor> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                CategoriaCor c = new CategoriaCor();
                c.setId_cor(rs.getInt("id_cor"));
                c.setUnicode_cor(rs.getString("unicode_cor"));
                lista.add(c);
            }
        }

        return lista;
    }

    public CategoriaCor buscarCorPorUnicode(String unicode) throws SQLException {
        String sql = "SELECT id_cor, unicode_cor FROM categoria_cor WHERE unicode_cor = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, unicode);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    CategoriaCor c = new CategoriaCor();
                    c.setId_cor(rs.getInt("id_cor"));
                    c.setUnicode_cor(rs.getString("unicode_cor"));
                    return c;
                }
            }
        }

        return null;
    }
    
    public void cadastrarEmoji(String unicode) throws SQLException {

        String sql = "INSERT INTO categoria_emoji(unicode_emoji) VALUES (?)";

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, unicode);

            int linhas = stmt.executeUpdate();

            System.out.println("Emoji cadastrado: " + unicode + " | linhas=" + linhas);

        }

    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Categoria mapearCategoria(ResultSet rs) throws SQLException {
        Categoria c = new Categoria();
        c.setId_categoria(rs.getInt("id_categoria"));
        c.setNome_categoria(rs.getString("nome_categoria"));
        c.setDescricao_categoria(rs.getString("descricao_categoria"));
        c.setEmoji_categoria(rs.getString("emoji_categoria"));
        c.setCor_categoria(rs.getString("cor_categoria"));
        c.setStatus_categoria(Categoria.StatusCategoria.valueOf(rs.getString("status_categoria")));
        return c;
    }

}