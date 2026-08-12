package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import br.com.saborearte.model.Ingrediente;
import br.com.saborearte.model.ReceitaIngrediente;

/**
 * DAO de Ingrediente + tabela associativa receita_ingrediente.
 * (o projeto não tem um ReceitaIngredienteDAO separado, então os métodos
 * de junção com receita ficam aqui mesmo, junto do catálogo de ingredientes)
 */
public class IngredienteDAO {

    private final Connection conexao;

    public IngredienteDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // INGREDIENTES DE UMA RECEITA (tela de detalhe)
    // =========================================================================

    /**
     * Lista os ingredientes de uma receita (quantidade, unidade e nome),
     * já prontos para a seção "Ingredientes" de receita-detalhe-publico.html.
     * Ordenados por id_ingrediente só para manter uma ordem estável — se no
     * futuro existir uma coluna de ordem própria em receita_ingrediente,
     * trocar aqui.
     */
    public List<ReceitaIngrediente> listarIngredientesPorReceita(int idReceita) throws SQLException {

        String sql = """
                SELECT
                    ri.id_receita,
                    ri.id_ingrediente,
                    ri.quantidade_receita_ingrediente,
                    ri.unidade_medida_receita_ingrediente,
                    i.nome_ingrediente
                FROM receita_ingrediente ri
                JOIN ingrediente i ON i.id_ingrediente = ri.id_ingrediente
                WHERE ri.id_receita = ?
                ORDER BY ri.id_ingrediente ASC
                """;

        List<ReceitaIngrediente> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    ReceitaIngrediente ri = new ReceitaIngrediente();
                    ri.setId_receita(rs.getInt("id_receita"));
                    ri.setId_ingrediente(rs.getInt("id_ingrediente"));
                    ri.setQuantidade_receita_ingrediente(rs.getInt("quantidade_receita_ingrediente"));
                    ri.setUnidade_medida_receita_ingrediente(rs.getString("unidade_medida_receita_ingrediente"));

                    // ===== Campo extra (não persistido) =====
                    ri.setNome_ingrediente(rs.getString("nome_ingrediente"));

                    lista.add(ri);
                }
            }
        }

        return lista;
    }

    // =========================================================================
    // GESTÃO DA RECEITA_INGREDIENTE (para a tela de cadastro/edição de receita)
    // =========================================================================

    public void adicionarIngredienteNaReceita(ReceitaIngrediente ri) throws SQLException {

        String sql = """
                INSERT INTO receita_ingrediente
                    (id_receita, id_ingrediente, quantidade_receita_ingrediente, unidade_medida_receita_ingrediente)
                VALUES (?, ?, ?, ?)
                """;

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, ri.getId_receita());
            ps.setInt(2, ri.getId_ingrediente());
            ps.setInt(3, ri.getQuantidade_receita_ingrediente());
            ps.setString(4, ri.getUnidade_medida_receita_ingrediente());
            ps.executeUpdate();
        }
    }

    public void removerIngredientesDaReceita(int idReceita) throws SQLException {

        String sql = "DELETE FROM receita_ingrediente WHERE id_receita = ?";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);
            ps.executeUpdate();
        }
    }

    // =========================================================================
    // CATÁLOGO DE INGREDIENTES (tabela ingrediente)
    // =========================================================================

    public List<Ingrediente> listarIngredientes() throws SQLException {

        String sql = "SELECT id_ingrediente, nome_ingrediente FROM ingrediente ORDER BY nome_ingrediente ASC";

        List<Ingrediente> lista = new ArrayList<>();

        try (PreparedStatement ps = conexao.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapearIngrediente(rs));
            }
        }

        return lista;
    }

    public Ingrediente buscarPorNome(String nome) throws SQLException {

        String sql = "SELECT id_ingrediente, nome_ingrediente FROM ingrediente WHERE LOWER(nome_ingrediente) = LOWER(?) LIMIT 1";

        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, nome.trim());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapearIngrediente(rs);
                }
            }
        }

        return null;
    }

    public void cadastrarIngrediente(Ingrediente ingrediente) throws SQLException {

        String sql = "INSERT INTO ingrediente (nome_ingrediente) VALUES (?)";

        try (PreparedStatement ps = conexao.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, ingrediente.getNome_ingrediente().trim());
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    ingrediente.setId_ingrediente(rs.getInt(1));
                }
            }
        }
    }

    /**
     * Busca um ingrediente pelo nome; se não existir, cadastra e retorna o
     * novo. Útil para a tela de cadastro de receita, onde o usuário pode
     * digitar um ingrediente que ainda não está no catálogo.
     */
    public Ingrediente buscarOuCriar(String nome) throws SQLException {

        Ingrediente existente = buscarPorNome(nome);
        if (existente != null) {
            return existente;
        }

        Ingrediente novo = new Ingrediente(nome.trim());
        cadastrarIngrediente(novo);
        return novo;
    }

    // =========================================================================
    // MAPEAMENTO INTERNO
    // =========================================================================

    private Ingrediente mapearIngrediente(ResultSet rs) throws SQLException {

        Ingrediente i = new Ingrediente();
        i.setId_ingrediente(rs.getInt("id_ingrediente"));
        i.setNome_ingrediente(rs.getString("nome_ingrediente"));
        return i;
    }
}