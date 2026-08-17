package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Usuario;

/**
 * DAO responsável pela tabela usuario_seguidor (id_seguidor, id_seguido, data_seguir).
 * id_seguidor = quem está seguindo (ex: Visitante)
 * id_seguido  = quem está sendo seguido (ex: Autor)
 *
 * OBS: versão corrigida — a original engolia exceções (catch + printStackTrace
 * + retorno de valor default), o que escondia falhas de conexão/SQL do
 * Controller. Agora propaga SQLException, igual ao resto dos DAOs do projeto
 * (CategoriaDAO, FavoritoDAO, etc.), e o Controller decide o que fazer com o erro.
 */
public class SeguidorDAO {

    private final Connection conexao;

    public SeguidorDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // CONTAGENS
    // =========================================================================

    /** Quantos autores o usuário (idSeguidor) está seguindo */
    public int contarSeguindo(int idSeguidor) throws SQLException {

        String sql = "SELECT COUNT(*) AS total FROM usuario_seguidor WHERE id_seguidor = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguidor);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }

        return 0;
    }

    /** Quantos seguidores esse usuário (idSeguido) tem — útil pro perfil de Autor */
    public int contarSeguidores(int idSeguido) throws SQLException {

        String sql = "SELECT COUNT(*) AS total FROM usuario_seguidor WHERE id_seguido = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguido);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }

        return 0;
    }

    // =========================================================================
    // VERIFICAR
    // =========================================================================

    /** Verifica se idSeguidor já segue idSeguido (botão "Seguir/Deixar de seguir") */
    public boolean jaSegue(int idSeguidor, int idSeguido) throws SQLException {

        String sql = "SELECT 1 FROM usuario_seguidor WHERE id_seguidor = ? AND id_seguido = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguidor);
            ps.setInt(2, idSeguido);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // =========================================================================
    // SEGUIR / DEIXAR DE SEGUIR
    // =========================================================================

    /**
     * Marca idSeguidor como seguidor de idSeguido. Não faz nada (silenciosamente)
     * se o par já existir — evita duplicidade sem precisar de try/catch de chave
     * duplicada no Controller (mesmo padrão do FavoritoDAO.favoritar).
     */
    public void seguir(int idSeguidor, int idSeguido) throws SQLException {

        if (jaSegue(idSeguidor, idSeguido)) {
            return;
        }

        String sql = "INSERT INTO usuario_seguidor (id_seguidor, id_seguido, data_seguir) VALUES (?, ?, ?)";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguidor);
            ps.setInt(2, idSeguido);
            ps.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));
            ps.executeUpdate();
        }
    }

    public void deixarDeSeguir(int idSeguidor, int idSeguido) throws SQLException {

        String sql = "DELETE FROM usuario_seguidor WHERE id_seguidor = ? AND id_seguido = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguidor);
            ps.setInt(2, idSeguido);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // LISTAR
    // =========================================================================

    /**
     * Autores que idSeguidor está seguindo, mais recentes primeiro.
     * Usado em autores-seguidos.jsp. Traz só os campos usados no card
     * (id, nome, título profissional, foto) — se precisar de mais campos do
     * Usuario ali, amplie o SELECT e o mapeamento abaixo.
     */
    public List<Usuario> listarSeguidos(int idSeguidor) throws SQLException {

        List<Usuario> lista = new ArrayList<>();

        String sql = """
                SELECT u.id_usuario, u.nome_usuario, u.titulo_usuario, u.foto_usuario
                FROM usuario_seguidor s
                JOIN usuario u ON u.id_usuario = s.id_seguido
                WHERE s.id_seguidor = ?
                ORDER BY s.data_seguir DESC
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idSeguidor);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Usuario u = new Usuario();
                    u.setId_usuario(rs.getInt("id_usuario"));
                    u.setNome_usuario(rs.getString("nome_usuario"));
                    u.setTitulo_usuario(rs.getString("titulo_usuario"));
                    u.setFoto_usuario(rs.getString("foto_usuario"));
                    lista.add(u);
                }
            }
        }

        return lista;
    }
}