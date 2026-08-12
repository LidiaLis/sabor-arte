package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Categoria;
import br.com.saborearte.model.Categoria.StatusCategoria;
import br.com.saborearte.model.Especialidade;

/**
 * DAO de Especialidade (tabela associativa usuario <-> categoria).
 *
 * Usada na tela autores-publico.html para:
 *  - popular as tags de especialidade no modal de cada autor
 *  - popular o <select> de filtro "Todas as especialidades" no topo
 *    (hoje fixo no HTML com valores tipo "confeitaria", "massas" —
 *    o ideal é trocar para id_categoria, igual foi feito no filtro
 *    de categorias da tela de receitas)
 */
public class EspecialidadeDAO {

    private final Connection conexao;

    public EspecialidadeDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // ESPECIALIDADES DE UM AUTOR (tags do card / modal)
    // =========================================================================

    /**
     * Lista as categorias marcadas como especialidade de um autor,
     * já com nome/emoji da categoria (join), prontas para virar
     * as .modal-tag na tela de autores.
     */
    public List<Categoria> listarEspecialidadesPorUsuario(int idUsuario) throws SQLException {

        String sql = """
                SELECT
                    c.id_categoria,
                    c.nome_categoria,
                    c.descricao_categoria,
                    c.emoji_categoria,
                    c.cor_categoria,
                    c.status_categoria
                FROM especialidade e
                JOIN categoria c ON c.id_categoria = e.id_categoria
                WHERE e.id_usuario = ?
                ORDER BY c.nome_categoria ASC
                """;

        List<Categoria> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearCategoria(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // ESPECIALIDADES DISPONÍVEIS PARA FILTRO (só categorias com pelo menos 1 autor)
    // =========================================================================

    /**
     * Lista as categorias que têm pelo menos um autor associado como
     * especialista — usada para montar o <select id="filterEspecialidade">
     * só com opções que realmente filtram algo (em vez da lista fixa
     * de 5 categorias que está hoje no HTML).
     */
    public List<Categoria> listarCategoriasComEspecialistas() throws SQLException {

        String sql = """
                SELECT DISTINCT
                    c.id_categoria,
                    c.nome_categoria,
                    c.descricao_categoria,
                    c.emoji_categoria,
                    c.cor_categoria,
                    c.status_categoria
                FROM categoria c
                JOIN especialidade e ON e.id_categoria = c.id_categoria
                WHERE c.status_categoria = ?
                ORDER BY c.nome_categoria ASC
                """;

        List<Categoria> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, StatusCategoria.ATIVA.name());

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearCategoria(rs));
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // CRUD (para a tela de perfil — aba "Especialidades")
    // =========================================================================

    public boolean especialidadeJaExiste(int idUsuario, int idCategoria) throws SQLException {

        String sql = """
                SELECT 1 FROM especialidade
                WHERE id_usuario = ? AND id_categoria = ?
                LIMIT 1
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idCategoria);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public void adicionarEspecialidade(Especialidade especialidade) throws SQLException {

        if (especialidadeJaExiste(especialidade.getId_usuario(), especialidade.getId_categoria())) {
            return; // evita duplicidade na chave composta (id_usuario, id_categoria)
        }

        String sql = "INSERT INTO especialidade (id_usuario, id_categoria) VALUES (?, ?)";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, especialidade.getId_usuario());
            ps.setInt(2, especialidade.getId_categoria());
            ps.executeUpdate();
        }
    }

    public void removerEspecialidade(int idUsuario, int idCategoria) throws SQLException {

        String sql = "DELETE FROM especialidade WHERE id_usuario = ? AND id_categoria = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.setInt(2, idCategoria);
            ps.executeUpdate();
        }
    }

    public void removerTodasEspecialidadesDoUsuario(int idUsuario) throws SQLException {

        String sql = "DELETE FROM especialidade WHERE id_usuario = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ps.executeUpdate();
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

        c.setStatus_categoria(
                StatusCategoria.valueOf(
                        rs.getString("status_categoria")
                )
        );

        return c;
    }
}