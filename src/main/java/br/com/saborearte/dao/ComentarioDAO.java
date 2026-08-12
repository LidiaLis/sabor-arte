package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Comentario.StatusComentario;

/**
 * DAO de Comentario.
 *
 * OBS de nomenclatura: a coluna da tabela é "data_comentario", mas o
 * getter/setter do model é getData_criacao_comentario()/setData_criacao_comentario()
 * (assim já estava em Comentario.java) — o mapeamento abaixo lê a coluna certa
 * e guarda no campo certo do model.
 */
public class ComentarioDAO {

    private final Connection conexao;

    public ComentarioDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // LISTAR (tela de detalhe — seção "Comentários")
    // =========================================================================

    /**
     * Lista os comentários de uma receita, mais recentes primeiro, já com
     * nome e foto do autor (join usuario). Sem filtro de status_comentario
     * por enquanto — mesmo ponto em aberto já anotado no ReceitaDAO (ajustar
     * para trazer só 'aprovado' quando o fluxo de moderação estiver definido).
     */
    public List<Comentario> listarComentariosPorReceita(int idReceita) throws SQLException {

        String sql = """
                SELECT
                    c.id_comentario,
                    c.receita,
                    c.usuario,
                    c.texto_comentario,
                    c.data_comentario,
                    c.data_modera_comentario,
                    c.status_comentario,
                    c.avaliacao_comentario,
                    u.nome_usuario,
                    u.foto_usuario
                FROM comentario c
                JOIN usuario u ON u.id_usuario = c.usuario
                WHERE c.receita = ?
                ORDER BY c.data_comentario DESC
                """;

        List<Comentario> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComAutor(rs));
                }
            }
        }

        return lista;
    }

    public int contarComentariosPorReceita(int idReceita) throws SQLException {

        String sql = "SELECT COUNT(*) AS total FROM comentario WHERE receita = ?";

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
    // PUBLICAR COMENTÁRIO
    // =========================================================================

    /**
     * Publica um novo comentário com nota (1 a 5) e texto. Sempre entra como
     * status_comentario = 'pendente' (moderação decide depois). data_comentario
     * é preenchida com o momento do INSERT (NOW() no banco); data_modera_comentario
     * fica NULL até um moderador agir.
     */
    public void cadastrarComentario(Comentario comentario) throws SQLException {

        String sql = """
                INSERT INTO comentario
                    (receita, usuario, texto_comentario, avaliacao_comentario, data_comentario, status_comentario)
                VALUES (?, ?, ?, ?, NOW(), ?)
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, comentario.getReceita());
            ps.setInt(2, comentario.getUsuario());
            ps.setString(3, comentario.getTexto_comentario());
            ps.setInt(4, comentario.getAvaliacao_comentario());
            ps.setString(5, StatusComentario.pendente.name());
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Comentario mapearComAutor(ResultSet rs) throws SQLException {

        Comentario c = new Comentario();

        c.setId_comentario(rs.getInt("id_comentario"));
        c.setReceita(rs.getInt("receita"));
        c.setUsuario(rs.getInt("usuario"));
        c.setTexto_comentario(rs.getString("texto_comentario"));
        c.setData_criacao_comentario(rs.getString("data_comentario"));
        c.setData_modera_comentario(rs.getString("data_modera_comentario"));
        c.setAvaliacao_comentario(rs.getInt("avaliacao_comentario"));

        c.setStatus_comentario(
                StatusComentario.valueOf(
                        rs.getString("status_comentario")
                )
        );

        // ===== Campos extras (não persistidos) =====
        c.setNome_usuario(rs.getString("nome_usuario"));
        c.setFoto_usuario(rs.getString("foto_usuario"));

        return c;
    }
}