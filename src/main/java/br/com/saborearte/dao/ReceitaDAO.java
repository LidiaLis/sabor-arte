package br.com.saborearte.dao;

import br.com.saborearte.model.Receita;
import br.com.saborearte.model.Receita.StatusAtividade;
import br.com.saborearte.model.Receita.StatusReceita;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.List;

/**
 * DAO de Receita.
 *
 * Contém:
 *  - listarReceitasDestaque   -> Home Pública
 *  - listarReceitasPublicadas -> Tela pública de listagem (receitas-publico.html)
 *  - contarReceitasPublicadas -> paginação da mesma tela
 *  - buscarReceitaPorId       -> Tela de detalhe (receita-detalhe-publico.html)
 *  - listarReceitasAdmin / contarReceitasAdmin / atualizarStatusAtividade
 *    -> Tela receita-admin.html (grid com filtro Ativo/Inativo + categoria + busca)
 *
 * OBS IMPORTANTE: os métodos *Admin abaixo dependem da coluna nova
 * receita.status_atividade (ENUM('ativo','inativo')) — ver alter_tables.sql.
 * Sem essa coluna, o botão "🚫 Inativar / 🔄 Ativar" do receita-admin.html
 * não tem onde persistir.
 *
 * CRUD administrativo de cadastro/edição/exclusão entra conforme as
 * próximas telas (formulário de nova receita, etc.) forem mapeadas.
 */
public class ReceitaDAO {

    private Connection conexao;

    public ReceitaDAO(Connection conexao) {
        this.conexao = conexao;
    }

    /** Insere a receita e devolve a chave gerada para ingredientes e passos. */
    public int cadastrarReceita(Receita receita) throws SQLException {
        String sql = """
                INSERT INTO receita
                    (categoria, usuario, titulo_receita, descricao_receita,
                     data_criacao_receita, data_publicacao_receita,
                     tempo_preparo_receita, rendimento_receita, imagem_receita,
                     status_receita, status_atividade, visualizacoes_receita)
                VALUES (?, ?, ?, ?, NOW(), NULL, ?, ?, ?, ?, ?, 0)
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, receita.getCategoria());
            stmt.setInt(2, receita.getUsuario());
            stmt.setString(3, receita.getTitulo_receita());
            stmt.setString(4, receita.getDescricao_receita());
            stmt.setInt(5, receita.getTempo_preparo_receita());
            stmt.setString(6, receita.getRendimento_receita());
            stmt.setString(7, receita.getImagem_receita());
            stmt.setString(8, receita.getStatus_receita().name());
            stmt.setString(9, receita.getStatus_atividade().name());
            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Não foi possível obter o ID da receita cadastrada.");
    }

    public void atualizarStatusReceita(int idReceita, StatusReceita status) throws SQLException {
        String sql = "UPDATE receita SET status_receita = ?, "
                   + "data_publicacao_receita = CASE WHEN ? = 'publicada' THEN NOW() ELSE data_publicacao_receita END "
                   + "WHERE id_receita = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, status.name());
            stmt.setString(2, status.name());
            stmt.setInt(3, idReceita);
            if (stmt.executeUpdate() == 0) throw new SQLException("Receita não encontrada: id=" + idReceita);
        }
    }

    public void atualizarReceita(Receita receita) throws SQLException {
        String sql = """
                UPDATE receita
                   SET categoria = ?, titulo_receita = ?, descricao_receita = ?,
                       tempo_preparo_receita = ?, rendimento_receita = ?, imagem_receita = ?
                 WHERE id_receita = ? AND usuario = ?
                """;
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, receita.getCategoria());
            stmt.setString(2, receita.getTitulo_receita());
            stmt.setString(3, receita.getDescricao_receita());
            stmt.setInt(4, receita.getTempo_preparo_receita());
            stmt.setString(5, receita.getRendimento_receita());
            stmt.setString(6, receita.getImagem_receita());
            stmt.setInt(7, receita.getId_receita());
            stmt.setInt(8, receita.getUsuario());
            if (stmt.executeUpdate() == 0) {
                throw new SQLException("Receita não encontrada ou não pertence ao autor.");
            }
        }
    }

    public List<Receita> listarReceitasPorAutor(int idUsuario) throws SQLException {
        String sql = """
                SELECT r.*, c.nome_categoria, c.emoji_categoria, u.nome_usuario,
                       u.foto_usuario, COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                  FROM receita r
                  JOIN categoria c ON c.id_categoria = r.categoria
                  JOIN usuario u ON u.id_usuario = r.usuario
                  LEFT JOIN comentario cm ON cm.receita = r.id_receita
                 WHERE r.usuario = ?
                 GROUP BY r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                          r.descricao_receita, r.data_criacao_receita, r.data_publicacao_receita,
                          r.tempo_preparo_receita, r.rendimento_receita, r.imagem_receita,
                          r.status_receita, r.status_atividade, r.visualizacoes_receita,
                          c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                 ORDER BY r.data_criacao_receita DESC
                """;
        List<Receita> lista = new ArrayList<>();
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) lista.add(mapearComExtras(rs));
            }
        }
        return lista;
    }

    // ===== MAPEAR (campos da própria tabela receita) =====

    private Receita mapear(ResultSet rs) throws SQLException {

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

        // status_atividade é coluna nova (ver alter_tables.sql). Se a migração
        // ainda não rodou no seu banco, comente a linha abaixo temporariamente.
        r.setStatus_atividade(
                StatusAtividade.valueOf(
                        rs.getString("status_atividade")
                )
        );

        return r;
    }

    // ===== MAPEAR + campos extras (categoria/autor/nota) — usado nas consultas com JOIN =====

    private Receita mapearComExtras(ResultSet rs) throws SQLException {

        Receita r = mapear(rs);

        r.setNome_categoria(rs.getString("nome_categoria"));
        r.setEmoji_categoria(rs.getString("emoji_categoria"));
        r.setNome_usuario(rs.getString("nome_usuario"));
        r.setFoto_usuario(rs.getString("foto_usuario"));
        r.setNota_media(rs.getDouble("nota_media"));

        return r;
    }

    // ===== LISTAR RECEITAS EM DESTAQUE (Home Pública) =====

    public List<Receita> listarReceitasDestaque(int limite) throws SQLException {

        List<Receita> lista = new ArrayList<>();

        String sql = """
                SELECT
                    r.*,
                    c.nome_categoria,
                    c.emoji_categoria,
                    u.nome_usuario,
                    u.foto_usuario,
                    COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                FROM receita r
                JOIN categoria c ON c.id_categoria = r.categoria
                JOIN usuario u ON u.id_usuario = r.usuario
                LEFT JOIN comentario cm ON cm.receita = r.id_receita
                WHERE r.status_receita = ?
                GROUP BY
                    r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                    r.data_criacao_receita, r.data_publicacao_receita, r.tempo_preparo_receita,
                    r.rendimento_receita, r.imagem_receita, r.status_receita, r.status_atividade,
                    r.visualizacoes_receita, c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                ORDER BY nota_media DESC, r.visualizacoes_receita DESC
                LIMIT ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, StatusReceita.publicada.name());
            stmt.setInt(2, limite);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComExtras(rs));
                }
            }
        }

        return lista;
    }

    // ===== LISTAR RECEITAS PUBLICADAS (Tela pública de listagem) =====

    public List<Receita> listarReceitasPublicadas(String busca, Integer idCategoria, int limite, int offset) throws SQLException {

        List<Receita> lista = new ArrayList<>();

        String sql = """
                SELECT
                    r.*,
                    c.nome_categoria,
                    c.emoji_categoria,
                    u.nome_usuario,
                    u.foto_usuario,
                    COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                FROM receita r
                JOIN categoria c ON c.id_categoria = r.categoria
                JOIN usuario u ON u.id_usuario = r.usuario
                LEFT JOIN comentario cm ON cm.receita = r.id_receita
                WHERE r.status_receita = ?
                  AND (? IS NULL OR r.categoria = ?)
                  AND (? IS NULL OR r.titulo_receita LIKE ?)
                GROUP BY
                    r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                    r.data_criacao_receita, r.data_publicacao_receita, r.tempo_preparo_receita,
                    r.rendimento_receita, r.imagem_receita, r.status_receita, r.status_atividade,
                    r.visualizacoes_receita, c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                ORDER BY r.data_publicacao_receita DESC
                LIMIT ? OFFSET ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            String termo = (busca == null || busca.isBlank()) ? null : "%" + busca.trim() + "%";

            stmt.setString(1, StatusReceita.publicada.name());

            if (idCategoria == null) {
                stmt.setNull(2, java.sql.Types.INTEGER);
                stmt.setNull(3, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(2, idCategoria);
                stmt.setInt(3, idCategoria);
            }

            if (termo == null) {
                stmt.setNull(4, java.sql.Types.VARCHAR);
                stmt.setNull(5, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(4, termo);
                stmt.setString(5, termo);
            }

            stmt.setInt(6, limite);
            stmt.setInt(7, offset);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComExtras(rs));
                }
            }
        }

        return lista;
    }

    // ===== CONTAR RECEITAS PUBLICADAS (para a paginação) =====

    public int contarReceitasPublicadas(String busca, Integer idCategoria) throws SQLException {

        String sql = """
                SELECT COUNT(*) AS total
                FROM receita r
                WHERE r.status_receita = ?
                  AND (? IS NULL OR r.categoria = ?)
                  AND (? IS NULL OR r.titulo_receita LIKE ?)
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            String termo = (busca == null || busca.isBlank()) ? null : "%" + busca.trim() + "%";

            stmt.setString(1, StatusReceita.publicada.name());

            if (idCategoria == null) {
                stmt.setNull(2, java.sql.Types.INTEGER);
                stmt.setNull(3, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(2, idCategoria);
                stmt.setInt(3, idCategoria);
            }

            if (termo == null) {
                stmt.setNull(4, java.sql.Types.VARCHAR);
                stmt.setNull(5, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(4, termo);
                stmt.setString(5, termo);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }

        return 0;
    }

    // ===== BUSCAR RECEITA POR ID (Tela de detalhe) =====

    public Receita buscarReceitaPorId(int idReceita) throws SQLException {

        String sql = """
                SELECT
                    r.*,
                    c.nome_categoria,
                    c.emoji_categoria,
                    u.nome_usuario,
                    u.foto_usuario,
                    COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                FROM receita r
                JOIN categoria c ON c.id_categoria = r.categoria
                JOIN usuario u ON u.id_usuario = r.usuario
                LEFT JOIN comentario cm ON cm.receita = r.id_receita
                WHERE r.id_receita = ?
                  AND r.status_receita = ?
                GROUP BY
                    r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                    r.data_criacao_receita, r.data_publicacao_receita, r.tempo_preparo_receita,
                    r.rendimento_receita, r.imagem_receita, r.status_receita, r.status_atividade,
                    r.visualizacoes_receita, c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, idReceita);
            stmt.setString(2, StatusReceita.publicada.name());

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapearComExtras(rs);
                }
            }
        }

        return null;
    }

    public List<Receita> listarReceitasPublicadasPorAutor(int idUsuario, int limite) throws SQLException {

        List<Receita> lista = new ArrayList<>();

        String sql = """
                SELECT
                    r.*,
                    c.nome_categoria,
                    c.emoji_categoria,
                    u.nome_usuario,
                    u.foto_usuario,
                    COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                FROM receita r
                JOIN categoria c ON c.id_categoria = r.categoria
                JOIN usuario u ON u.id_usuario = r.usuario
                LEFT JOIN comentario cm ON cm.receita = r.id_receita
                WHERE r.usuario = ?
                  AND r.status_receita = ?
                GROUP BY
                    r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                    r.data_criacao_receita, r.data_publicacao_receita, r.tempo_preparo_receita,
                    r.rendimento_receita, r.imagem_receita, r.status_receita, r.status_atividade,
                    r.visualizacoes_receita, c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                ORDER BY r.data_publicacao_receita DESC
                LIMIT ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, idUsuario);
            stmt.setString(2, StatusReceita.publicada.name());
            stmt.setInt(3, limite);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComExtras(rs));
                }
            }
        }

        return lista;
    }

    // ===== INCREMENTAR VISUALIZAÇÃO =====

    public void incrementarVisualizacao(int idReceita) throws SQLException {

        String sql = "UPDATE receita SET visualizacoes_receita = visualizacoes_receita + 1 WHERE id_receita = ?";

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idReceita);
            stmt.executeUpdate();
        }
    }

    // =========================================================================
    // ===== NOVO — receita-admin.html =====
    // =========================================================================

    /**
     * Lista receitas para o painel admin, com busca por título + filtro de
     * status_atividade (ativo/inativo/todos) + filtro de categoria, já com
     * categoria e autor via JOIN (pros campos recipe-cat / author-name do card).
     *
     * Sem filtro de status_receita — o admin precisa ver rascunho, pendente,
     * publicada, etc., diferente da listagem pública.
     *
     * @param busca            termo no título (null/vazio -> ignora)
     * @param statusAtividade  null -> traz ativos e inativos ("Todos os status" do <select>)
     * @param idCategoria      null -> ignora filtro de categoria
     */
    public List<Receita> listarReceitasAdmin(String busca,
                                              StatusAtividade statusAtividade,
                                              Integer idCategoria,
                                              int limite,
                                              int offset) throws SQLException {

        List<Receita> lista = new ArrayList<>();

        String sql = """
                SELECT
                    r.*,
                    c.nome_categoria,
                    c.emoji_categoria,
                    u.nome_usuario,
                    u.foto_usuario,
                    COALESCE(AVG(cm.avaliacao_comentario), 0) AS nota_media
                FROM receita r
                JOIN categoria c ON c.id_categoria = r.categoria
                JOIN usuario u ON u.id_usuario = r.usuario
                LEFT JOIN comentario cm ON cm.receita = r.id_receita
                WHERE (? IS NULL OR r.status_atividade = ?)
                  AND (? IS NULL OR r.categoria = ?)
                  AND (? IS NULL OR r.titulo_receita LIKE ?)
                GROUP BY
                    r.id_receita, r.categoria, r.usuario, r.titulo_receita,
                    r.data_criacao_receita, r.data_publicacao_receita, r.tempo_preparo_receita,
                    r.rendimento_receita, r.imagem_receita, r.status_receita, r.status_atividade,
                    r.visualizacoes_receita, c.nome_categoria, c.emoji_categoria, u.nome_usuario, u.foto_usuario
                ORDER BY r.data_criacao_receita DESC
                LIMIT ? OFFSET ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            String termo = (busca == null || busca.isBlank()) ? null : "%" + busca.trim() + "%";
            String statusStr = (statusAtividade == null) ? null : statusAtividade.name();

            if (statusStr == null) {
                stmt.setNull(1, java.sql.Types.VARCHAR);
                stmt.setNull(2, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(1, statusStr);
                stmt.setString(2, statusStr);
            }

            if (idCategoria == null) {
                stmt.setNull(3, java.sql.Types.INTEGER);
                stmt.setNull(4, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(3, idCategoria);
                stmt.setInt(4, idCategoria);
            }

            if (termo == null) {
                stmt.setNull(5, java.sql.Types.VARCHAR);
                stmt.setNull(6, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(5, termo);
                stmt.setString(6, termo);
            }

            stmt.setInt(7, limite);
            stmt.setInt(8, offset);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(mapearComExtras(rs));
                }
            }
        }

        return lista;
    }

    /** Mesmos filtros de listarReceitasAdmin, só que devolvendo o total (paginação). */
    public int contarReceitasAdmin(String busca, StatusAtividade statusAtividade, Integer idCategoria) throws SQLException {

        String sql = """
                SELECT COUNT(*) AS total
                FROM receita r
                WHERE (? IS NULL OR r.status_atividade = ?)
                  AND (? IS NULL OR r.categoria = ?)
                  AND (? IS NULL OR r.titulo_receita LIKE ?)
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            String termo = (busca == null || busca.isBlank()) ? null : "%" + busca.trim() + "%";
            String statusStr = (statusAtividade == null) ? null : statusAtividade.name();

            if (statusStr == null) {
                stmt.setNull(1, java.sql.Types.VARCHAR);
                stmt.setNull(2, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(1, statusStr);
                stmt.setString(2, statusStr);
            }

            if (idCategoria == null) {
                stmt.setNull(3, java.sql.Types.INTEGER);
                stmt.setNull(4, java.sql.Types.INTEGER);
            } else {
                stmt.setInt(3, idCategoria);
                stmt.setInt(4, idCategoria);
            }

            if (termo == null) {
                stmt.setNull(5, java.sql.Types.VARCHAR);
                stmt.setNull(6, java.sql.Types.VARCHAR);
            } else {
                stmt.setString(5, termo);
                stmt.setString(6, termo);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        }

        return 0;
    }

    /**
     * Alterna ativo <-> inativo. Retorna o novo status, pra você já devolver
     * pro JS trocar o texto do botão ("🚫 Inativar" / "🔄 Ativar") sem
     * precisar de uma segunda consulta.
     */
    public StatusAtividade toggleStatusAtividade(int idReceita) throws SQLException {

        String sqlAtual = "SELECT status_atividade FROM receita WHERE id_receita = ?";
        StatusAtividade atual;

        try (PreparedStatement stmt = conexao.prepareStatement(sqlAtual)) {
            stmt.setInt(1, idReceita);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Receita não encontrada: id=" + idReceita);
                }
                atual = StatusAtividade.valueOf(rs.getString("status_atividade"));
            }
        }

        StatusAtividade novo = (atual == StatusAtividade.ativo) ? StatusAtividade.inativo : StatusAtividade.ativo;

        String sqlUpdate = "UPDATE receita SET status_atividade = ? WHERE id_receita = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sqlUpdate)) {
            stmt.setString(1, novo.name());
            stmt.setInt(2, idReceita);
            stmt.executeUpdate();
        }

        return novo;
    }

    // =========================================================================
    // ===== NOVO — dashboard-admin.html / relatorio-admin.html (agregações) =====
    // =========================================================================

    public int contarTotalReceitas() throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM receita";
        try (PreparedStatement stmt = conexao.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? rs.getInt("total") : 0;
        }
    }

    /**
     * Cadastros de receita por mês, últimos N meses (gráfico "Cadastros por Mês"
     * do dashboard-admin.html). Retorna 12 posições fixas por padrão: mês (1–12)
     * e total; quem não tiver receita naquele mês simplesmente não aparece no
     * ResultSet, então preencha os buracos com 0 na hora de montar o array pro Chart.js.
     */
    public java.util.Map<Integer, Integer> contarReceitasPorMes(int meses) throws SQLException {

        String sql = """
                SELECT MONTH(data_criacao_receita) AS mes, COUNT(*) AS total
                FROM receita
                WHERE data_criacao_receita >= DATE_SUB(CURDATE(), INTERVAL ? MONTH)
                GROUP BY MONTH(data_criacao_receita)
                ORDER BY mes
                """;

        java.util.Map<Integer, Integer> resultado = new java.util.LinkedHashMap<>();

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, meses);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    resultado.put(rs.getInt("mes"), rs.getInt("total"));
                }
            }
        }

        return resultado;
    }
    public int contarPorStatusEAutor(int idUsuario, StatusReceita status) throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM receita WHERE usuario = ? AND status_receita = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setString(2, status.name());
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    public long somarVisualizacoesPorAutor(int idUsuario) throws SQLException {
        String sql = "SELECT COALESCE(SUM(visualizacoes_receita),0) AS total FROM receita WHERE usuario = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getLong("total") : 0L;
            }
        }
    }

    public java.util.Map<Integer, Integer> contarPublicadasPorMesEAutor(int idUsuario, int meses) throws SQLException {
        String sql = """
                SELECT MONTH(data_publicacao_receita) AS mes, COUNT(*) AS total
                FROM receita
                WHERE usuario = ?
                  AND status_receita = ?
                  AND data_publicacao_receita >= DATE_SUB(CURDATE(), INTERVAL ? MONTH)
                GROUP BY MONTH(data_publicacao_receita)
                ORDER BY mes
                """;
        java.util.Map<Integer, Integer> resultado = new java.util.LinkedHashMap<>();
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setString(2, StatusReceita.publicada.name());
            stmt.setInt(3, meses);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) resultado.put(rs.getInt("mes"), rs.getInt("total"));
            }
        }
        return resultado;
    }

    public java.util.Map<Integer, Long> somarVisualizacoesPorMesEAutor(int idUsuario, int meses) throws SQLException {
        String sql = """
                SELECT MONTH(data_publicacao_receita) AS mes, COALESCE(SUM(visualizacoes_receita),0) AS total
                FROM receita
                WHERE usuario = ?
                  AND status_receita = ?
                  AND data_publicacao_receita >= DATE_SUB(CURDATE(), INTERVAL ? MONTH)
                GROUP BY MONTH(data_publicacao_receita)
                ORDER BY mes
                """;
        java.util.Map<Integer, Long> resultado = new java.util.LinkedHashMap<>();
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setString(2, StatusReceita.publicada.name());
            stmt.setInt(3, meses);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) resultado.put(rs.getInt("mes"), rs.getLong("total"));
            }
        }
        return resultado;
    }

    public int contarPorStatus(StatusReceita status) throws SQLException {
        String sql = "SELECT COUNT(*) AS total FROM receita WHERE status_receita = ?";
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, status.name());
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }

    /**
     * "Agendadas": receitas ja aprovadas (status publicada) mas com
     * data_publicacao_receita ainda no futuro.
     * AJUSTE: StatusReceita nao tem um valor "agendada" proprio — se existir
     * outra forma de marcar isso no banco, troque essa condicao.
     */
    public int contarAgendadas() throws SQLException {
        String sql = """
                SELECT COUNT(*) AS total
                FROM receita
                WHERE status_receita = ?
                  AND data_publicacao_receita > NOW()
                """;
        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, StatusReceita.publicada.name());
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt("total") : 0;
            }
        }
    }
}
