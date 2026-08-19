package br.com.saborearte.dao;

import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Comentario.StatusComentario;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;

/**
 * DAO de Comentario.
 *
 * OBS: o enum StatusComentario é PENDENTE / APROVADO / REJEITADO / REMOVIDO.
 * Não existe um valor "DENUNCIADO" — por decisão do projeto, PENDENTE
 * representa um comentário aguardando moderação (ou seja, denunciado/reportado).
 *
 * ADICIONADO (metodos que o ComentarioController precisa e ainda nao existiam):
 *   listarComentariosPorAutor    -> mensagens-autor.jsp
 *   salvarResposta               -> mensagens-autor.jsp (ASSUME colunas
 *                                    resposta_comentario / data_resposta_comentario
 *                                    na tabela comentario - NAO CONFIRMADO,
 *                                    ver aviso no metodo)
 *   listarComentariosModeracao   -> comentarios-moderacao.jsp (substitui o
 *                                    "listarDenunciados" que o controller
 *                                    antigo chamava; renomeado porque o
 *                                    conceito de "denunciado" nao existe
 *                                    como status proprio, e sim como
 *                                    PENDENTE — ver comentario da classe)
 *   contarComentariosModeracao   -> total pra paginacao da tela acima
 *   removerComentario            -> exclui o comentario (acao "remover")
 *   atualizarStatusComentario    -> muda status_comentario (acao "manter"/"denunciar")
 */
public class ComentarioDAO {

    private Connection conexao;

    public ComentarioDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // ===== MAPEAR =====

    private Comentario mapear(ResultSet rs) throws SQLException {

        Comentario c = new Comentario();

        c.setId_comentario(rs.getInt("id_comentario"));
        c.setReceita(rs.getInt("receita"));
        c.setUsuario(rs.getInt("usuario"));

        c.setTexto_comentario(rs.getString("texto_comentario"));
        c.setData_criacao_comentario(rs.getString("data_criacao_comentario"));
        c.setData_modera_comentario(rs.getString("data_modera_comentario"));
        c.setResposta_comentario(rs.getString("resposta_comentario"));
        c.setData_resposta_comentario(rs.getString("data_resposta_comentario"));
        c.setAvaliacao_comentario(rs.getInt("avaliacao_comentario"));

        c.setStatus_comentario(
                StatusComentario.valueOf(
                        rs.getString("status_comentario")
                )
        );

        return c;
    }

    // ===== CONTAR COMENTARIOS (Dashboard Admin) =====

    public int contarComentarios() throws SQLException {

        String sql = "SELECT COUNT(*) AS total FROM comentario";

        try (PreparedStatement stmt = conexao.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            return rs.next() ? rs.getInt("total") : 0;
        }
    }

    // ===== LISTAR COMENTARIOS DENUNCIADOS (Perfil — Editor/Admin) =====

    /**
     * Retorna os comentários PENDENTE (aguardando moderação = denunciado)
     * mais recentes primeiro, ordenado por data_criacao_comentario — não
     * por data_modera_comentario, que fica vazio enquanto o comentário
     * não é moderado. Usado no card simples "Comentários Denunciados" da
     * tela de Perfil — texto tipo "@usuario teve seu comentário denunciado
     * há X horas", montado na JSP a partir de nome_usuario + data_criacao_comentario.
     */
    public List<Comentario> listarComentariosDenunciados(int limite) throws SQLException {

        List<Comentario> lista = new ArrayList<>();

        String sql = """
                SELECT c.*, u.nome_usuario, u.foto_usuario
                FROM comentario c
                JOIN usuario u ON u.id_usuario = c.usuario
                WHERE c.status_comentario = ?
                ORDER BY c.data_criacao_comentario DESC
                LIMIT ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, StatusComentario.PENDENTE.name());
            stmt.setInt(2, limite);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {

                Comentario c = mapear(rs);
                c.setNome_usuario(rs.getString("nome_usuario"));
                c.setFoto_usuario(rs.getString("foto_usuario"));

                lista.add(c);
            }

            rs.close();
        }

        return lista;
    }

    public int contarPorStatus(StatusComentario status) throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM comentario WHERE status_comentario = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, status.name());
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    public void cadastrarComentario(Comentario comentario) throws SQLException {
        String sql = """
                INSERT INTO comentario
                    (receita, usuario, texto_comentario, data_criacao_comentario,
                     data_modera_comentario, status_comentario, avaliacao_comentario)
                VALUES (?, ?, ?, NOW(), NULL, ?, ?)
                """;
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, comentario.getReceita());
            stmt.setInt(2, comentario.getUsuario());
            stmt.setString(3, comentario.getTexto_comentario());
            stmt.setString(4, comentario.getStatus_comentario().name());
            stmt.setInt(5, comentario.getAvaliacao_comentario());
            stmt.executeUpdate();
        }
    }

    public List<Comentario> listarComentariosPorReceita(int receitaId) throws SQLException {
        String sql = """
                SELECT c.*, u.nome_usuario, u.foto_usuario
                  FROM comentario c
                  JOIN usuario u ON u.id_usuario = c.usuario
                 WHERE c.receita = ? AND c.status_comentario = ?
                 ORDER BY c.data_criacao_comentario DESC
                """;
        List<Comentario> lista = new ArrayList<>();
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, receitaId);
            stmt.setString(2, StatusComentario.APROVADO.name());
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Comentario c = mapear(rs);
                    c.setNome_usuario(rs.getString("nome_usuario"));
                    c.setFoto_usuario(rs.getString("foto_usuario"));
                    lista.add(c);
                }
            }
        }
        return lista;
    }

    // =========================================================================
    // ADICIONADO — AUTOR: mensagens-autor.jsp
    // =========================================================================

    /**
     * Lista comentarios feitos nas receitas do autor logado, com paginacao e
     * filtro de texto (busca no texto do comentario ou no nome de quem
     * comentou). JOIN com receita pra escopar por autor (ASSUME que a
     * tabela receita tem uma coluna "autor" — mesma convencao de nomes
     * curtos usada em fluxo.receita/fluxo.usuario. Se a coluna real for
     * outro nome, so trocar "r.autor" abaixo).
     */
    public List<Comentario> listarComentariosPorAutor(int autorId, String busca, String statusResposta,
                                                       int page, int size) throws SQLException {
        List<Comentario> lista = new ArrayList<>();
        boolean temBusca = busca != null && !busca.isBlank();
        boolean respondidos = "respondido".equalsIgnoreCase(statusResposta);
        boolean pendentes = "pendente".equalsIgnoreCase(statusResposta);
        int offset = Math.max(0, (page - 1) * size);

        String sql = """
                SELECT c.*, u.nome_usuario, u.foto_usuario, r.titulo_receita
                FROM comentario c
                JOIN usuario u ON u.id_usuario = c.usuario
                JOIN receita r ON r.id_receita = c.receita
                WHERE r.usuario = ?
                """
                + (temBusca ? " AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?) " : "")
                + (respondidos ? " AND c.resposta_comentario IS NOT NULL AND TRIM(c.resposta_comentario) <> '' " : "")
                + (pendentes ? " AND (c.resposta_comentario IS NULL OR TRIM(c.resposta_comentario) = '') " : "")
                + " ORDER BY c.data_criacao_comentario DESC LIMIT ? OFFSET ? ";

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            int i = 1;
            stmt.setInt(i++, autorId);
            if (temBusca) {
                String like = "%" + busca.trim() + "%";
                stmt.setString(i++, like);
                stmt.setString(i++, like);
                stmt.setString(i++, like);
            }
            stmt.setInt(i++, size);
            stmt.setInt(i, offset);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Comentario c = mapear(rs);
                    c.setNome_usuario(rs.getString("nome_usuario"));
                    c.setFoto_usuario(rs.getString("foto_usuario"));
                    c.setTitulo_receita(rs.getString("titulo_receita"));
                    lista.add(c);
                }
            }
        }
        return lista;
    }

    public int contarComentariosPorAutor(int autorId, String busca, String statusResposta) throws SQLException {
        boolean temBusca = busca != null && !busca.isBlank();
        boolean respondidos = "respondido".equalsIgnoreCase(statusResposta);
        boolean pendentes = "pendente".equalsIgnoreCase(statusResposta);
        String sql = "SELECT COUNT(*) AS total FROM comentario c "
                + "JOIN usuario u ON u.id_usuario = c.usuario "
                + "JOIN receita r ON r.id_receita = c.receita WHERE r.usuario = ? "
                + (temBusca ? "AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?) " : "")
                + (respondidos ? "AND c.resposta_comentario IS NOT NULL AND TRIM(c.resposta_comentario) <> '' " : "")
                + (pendentes ? "AND (c.resposta_comentario IS NULL OR TRIM(c.resposta_comentario) = '') " : "");
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            int i = 1;
            stmt.setInt(i++, autorId);
            if (temBusca) {
                String like = "%" + busca.trim() + "%";
                stmt.setString(i++, like);
                stmt.setString(i++, like);
                stmt.setString(i, like);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    public int contarRespostasPorAutor(int autorId, boolean respondidas) throws SQLException {
        String condicao = respondidas
                ? "c.resposta_comentario IS NOT NULL AND TRIM(c.resposta_comentario) <> ''"
                : "c.resposta_comentario IS NULL OR TRIM(c.resposta_comentario) = ''";
        String sql = "SELECT COUNT(*) AS total FROM comentario c JOIN receita r ON r.id_receita = c.receita "
                + "WHERE r.usuario = ? AND (" + condicao + ")";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, autorId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    public double calcularAvaliacaoMediaPorAutor(int autorId) throws SQLException {
        String sql = "SELECT COALESCE(AVG(c.avaliacao_comentario), 0) AS media FROM comentario c "
                + "JOIN receita r ON r.id_receita = c.receita WHERE r.usuario = ? AND c.avaliacao_comentario > 0";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, autorId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getDouble("media") : 0;
            }
        }
    }

    /**
     * Salva a resposta do autor a um comentario.
     *
     * ATENCAO — NAO CONFIRMADO: assume que a tabela comentario tem as
     * colunas "resposta_comentario" e "data_resposta_comentario". O
     * mapear() atual desta classe nao le nenhuma coluna de resposta, entao
     * essas colunas podem nao existir ainda. Se nao existirem, e preciso
     * criar (ALTER TABLE) ou guardar a resposta em outro lugar (ex.: o
     * proprio comentario original + um novo registro na mesma tabela,
     * se o modelo permitir comentario-resposta encadeado).
     */
    public void salvarResposta(int comentarioId, int autorId, String texto) throws SQLException {

        String sql = """
                UPDATE comentario c
                JOIN receita r ON r.id_receita = c.receita
                   SET c.resposta_comentario = ?,
                       c.data_resposta_comentario = NOW()
                 WHERE c.id_comentario = ?
                   AND r.usuario = ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, texto);
            stmt.setInt(2, comentarioId);
            stmt.setInt(3, autorId);
            if (stmt.executeUpdate() == 0) {
                throw new SQLException("Comentario inexistente ou nao pertence ao autor logado.");
            }
        }
    }

    public void denunciarComentarioDoAutor(int comentarioId, int autorId) throws SQLException {
        String sql = """
                UPDATE comentario c
                JOIN receita r ON r.id_receita = c.receita
                   SET c.status_comentario = ?,
                       c.data_modera_comentario = NULL
                 WHERE c.id_comentario = ?
                   AND r.usuario = ?
                """;
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, StatusComentario.PENDENTE.name());
            stmt.setInt(2, comentarioId);
            stmt.setInt(3, autorId);
            if (stmt.executeUpdate() == 0) {
                throw new SQLException("Comentario inexistente ou nao pertence ao autor logado.");
            }
        }
    }

    // =========================================================================
    // ADICIONADO — EDITOR/ADMIN: comentarios-moderacao.jsp
    // =========================================================================

    /**
     * Lista comentarios pra fila de moderacao, com filtro de texto/usuario,
     * status (PENDENTE/APROVADO/REJEITADO/REMOVIDO, ou null = todos) e data
     * minima (data_criacao_comentario >= data), paginado.
     */
    public List<Comentario> listarComentariosModeracao(String filtro, String status, String data,
                                                         int page, int size) throws SQLException {

        List<Comentario> lista = new ArrayList<>();
        boolean temFiltro = filtro != null && !filtro.isBlank();
        boolean temStatus = status != null && !status.isBlank();
        boolean temData = data != null && !data.isBlank();
        int offset = Math.max(0, (page - 1) * size);

        StringBuilder sql = new StringBuilder("""
                SELECT c.*, u.nome_usuario, u.foto_usuario, r.titulo_receita
                FROM comentario c
                JOIN usuario u ON u.id_usuario = c.usuario
                JOIN receita r ON r.id_receita = c.receita
                WHERE 1=1
                """);
        if (temFiltro) sql.append(" AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?) ");
        if (temStatus) sql.append(" AND c.status_comentario = ? ");
        if (temData)   sql.append(" AND c.data_criacao_comentario >= ? ");
        sql.append(" ORDER BY c.data_criacao_comentario DESC LIMIT ? OFFSET ? ");

        try (PreparedStatement stmt = conexao.prepareStatement(sql.toString())) {
            int i = 1;
            if (temFiltro) {
                String like = "%" + filtro.trim() + "%";
                stmt.setString(i++, like);
                stmt.setString(i++, like);
                stmt.setString(i++, like);
            }
            if (temStatus) stmt.setString(i++, status);
            if (temData)   stmt.setString(i++, data);
            stmt.setInt(i++, size);
            stmt.setInt(i, offset);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Comentario c = mapear(rs);
                    c.setNome_usuario(rs.getString("nome_usuario"));
                    c.setFoto_usuario(rs.getString("foto_usuario"));
                    c.setTitulo_receita(rs.getString("titulo_receita"));
                    lista.add(c);
                }
            }
        }

        return lista;
    }

    /** Total pra paginacao da fila de moderacao, mesmos filtros de listarComentariosModeracao. */
    public int contarComentariosModeracao(String filtro, String status, String data) throws SQLException {

        boolean temFiltro = filtro != null && !filtro.isBlank();
        boolean temStatus = status != null && !status.isBlank();
        boolean temData = data != null && !data.isBlank();

        StringBuilder sql = new StringBuilder("""
                SELECT COUNT(*) AS total
                FROM comentario c
                JOIN usuario u ON u.id_usuario = c.usuario
                JOIN receita r ON r.id_receita = c.receita
                WHERE 1=1
                """);
        if (temFiltro) sql.append(" AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?) ");
        if (temStatus) sql.append(" AND c.status_comentario = ? ");
        if (temData)   sql.append(" AND c.data_criacao_comentario >= ? ");

        try (PreparedStatement stmt = conexao.prepareStatement(sql.toString())) {
            int i = 1;
            if (temFiltro) {
                String like = "%" + filtro.trim() + "%";
                stmt.setString(i++, like);
                stmt.setString(i++, like);
                stmt.setString(i++, like);
            }
            if (temStatus) stmt.setString(i++, status);
            if (temData)   stmt.setString(i, data);

            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    /** Preserva o histórico marcando o comentário como removido. */
    public void removerComentario(int comentarioId) throws SQLException {
        atualizarStatusComentario(comentarioId, StatusComentario.REMOVIDO);
    }

    /**
     * Atualiza o status do comentario (usado em "manter" -> APROVADO e em
     * "denunciar" -> PENDENTE). Atualiza data_modera_comentario junto,
     * exceto quando o novo status e PENDENTE (denuncia acabou de entrar,
     * ainda nao foi moderada de verdade).
     */
    public void atualizarStatusComentario(int comentarioId, StatusComentario novoStatus) throws SQLException {

        String sql = (novoStatus == StatusComentario.PENDENTE)
                ? "UPDATE comentario SET status_comentario = ? WHERE id_comentario = ?"
                : "UPDATE comentario SET status_comentario = ?, data_modera_comentario = NOW() WHERE id_comentario = ?";

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, novoStatus.name());
            stmt.setInt(2, comentarioId);
            stmt.executeUpdate();
        }
    }
}


