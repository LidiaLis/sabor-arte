package br.com.saborearte.dao;

import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.StatusUsuario;
import br.com.saborearte.model.Usuario.TemaUsuario;
import br.com.saborearte.model.Usuario.TipoUsuario;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;

public class UsuarioDAO {

    private Connection conexao;

    public UsuarioDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // ===== MAPEAR =====

    private Usuario mapear(ResultSet rs) throws SQLException {

        Usuario u = new Usuario();

        u.setId_usuario(rs.getInt("id_usuario"));

        u.setNome_usuario(rs.getString("nome_usuario"));
        u.setEmail_usuario(rs.getString("email_usuario"));
        u.setSenha_usuario(rs.getString("senha_usuario"));

        // ===== ENUMS =====

        u.setTipo_usuario(
                TipoUsuario.valueOf(
                        rs.getString("tipo_usuario")
                )
        );

        u.setStatus_usuario(
                StatusUsuario.valueOf(
                        rs.getString("status_usuario")
                )
        );

        u.setTema(
                TemaUsuario.valueOf(
                        rs.getString("tema")
                )
        );

        // ===== Outros campos =====

        u.setUsername_usuario(rs.getString("username_usuario"));
        u.setTelefone_usuario(rs.getString("telefone_usuario"));
        u.setLocalizacao_usuario(rs.getString("localizacao_usuario"));
        u.setFoto_usuario(rs.getString("foto_usuario"));
        u.setTitulo_usuario(rs.getString("titulo_usuario"));

        u.setInstagram_usuario(rs.getString("instagram_usuario"));
        u.setYoutube_usuario(rs.getString("youtube_usuario"));
        u.setPinterest_usuario(rs.getString("pinterest_usuario"));

        u.setData_criacao_usuario(
        	    rs.getTimestamp("data_criacao_usuario") != null 
        	        ? rs.getTimestamp("data_criacao_usuario").toLocalDateTime() 
        	        : null
        	);
        return u;
    }

    // ===== LOGIN =====

    public Usuario login(String email, String senha) throws Exception {

        String sql = """
                SELECT *
                FROM usuario
                WHERE email_usuario = ?
                AND senha_usuario = ?
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        stmt.setString(1, email);
        stmt.setString(2, senha);

        ResultSet rs = stmt.executeQuery();

        Usuario usuario = null;

        if (rs.next()) {
            usuario = mapear(rs);
        }

        rs.close();
        stmt.close();

        return usuario;
    }

 // ===== CADASTRO INICIAL (só os campos obrigatórios) =====

    public void cadastrarUsuario(Usuario usuario) throws Exception {

        // Normaliza o nome e gera username antes de inserir
        String nomeNormalizado = normalizarNome(usuario.getNome_usuario());
        usuario.setNome_usuario(nomeNormalizado);
        usuario.setUsername_usuario(gerarUsername(nomeNormalizado));

        String sql = """
                INSERT INTO usuario (
                    nome_usuario,
                    email_usuario,
                    senha_usuario,
                    username_usuario,
                    tipo_usuario,
                    status_usuario
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, usuario.getNome_usuario());
            stmt.setString(2, usuario.getEmail_usuario());
            stmt.setString(3, usuario.getSenha_usuario());
            stmt.setString(4, usuario.getUsername_usuario());
            stmt.setString(5, usuario.getTipo_usuario().name());   // VISITANTE
            stmt.setString(6, usuario.getStatus_usuario().name()); // ATIVO
            stmt.executeUpdate();
        }
    }

    // ===== LISTAR TODOS =====

    public List<Usuario> listarUsuarios() throws Exception {

        List<Usuario> lista = new ArrayList<>();

        String sql = """
                SELECT *
                FROM usuario
                ORDER BY id_usuario
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        ResultSet rs = stmt.executeQuery();

        while (rs.next()) {
            lista.add(mapear(rs));
        }

        rs.close();
        stmt.close();

        return lista;
    }

    // ===== BUSCAR POR ID =====

    public Usuario buscarUsuarioPorId(int id) throws Exception {

        String sql = """
                SELECT *
                FROM usuario
                WHERE id_usuario = ?
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        stmt.setInt(1, id);

        ResultSet rs = stmt.executeQuery();

        Usuario usuario = null;

        if (rs.next()) {
            usuario = mapear(rs);
        }

        rs.close();
        stmt.close();

        return usuario;
    }

    // ===== ATUALIZAR =====

    public boolean atualizarUsuario(Usuario usuario) {

        String sql = """
                UPDATE usuario
                SET
                    nome_usuario = ?,
                    email_usuario = ?,
                    senha_usuario = ?,
                    tipo_usuario = ?,
                    status_usuario = ?,
                    tema = ?,
                    username_usuario = ?,
                    telefone_usuario = ?,
                    localizacao_usuario = ?,
                    foto_usuario = ?,
                    titulo_usuario = ?,
                    instagram_usuario = ?,
                    youtube_usuario = ?,
                    pinterest_usuario = ?
                WHERE id_usuario = ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, usuario.getNome_usuario());
            stmt.setString(2, usuario.getEmail_usuario());
            stmt.setString(3, usuario.getSenha_usuario());

            stmt.setString(4, usuario.getTipo_usuario().name());
            stmt.setString(5, usuario.getStatus_usuario().name());
            stmt.setString(6, usuario.getTema().name());

            stmt.setString(7, usuario.getUsername_usuario());
            stmt.setString(8, usuario.getTelefone_usuario());
            stmt.setString(9, usuario.getLocalizacao_usuario());
            stmt.setString(10, usuario.getFoto_usuario());
            stmt.setString(11, usuario.getTitulo_usuario());

            stmt.setString(12, usuario.getInstagram_usuario());
            stmt.setString(13, usuario.getYoutube_usuario());
            stmt.setString(14, usuario.getPinterest_usuario());

            stmt.setInt(15, usuario.getId_usuario());

            stmt.executeUpdate();

            return true;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ===== ATUALIZAR TEMA =====

    public boolean atualizarTema(int idUsuario, TemaUsuario tema) {

        String sql = """
                UPDATE usuario
                SET tema = ?
                WHERE id_usuario = ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, tema.name());
            stmt.setInt(2, idUsuario);

            stmt.executeUpdate();

            return true;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ===== DELETAR =====

    public void deletarUsuario(int id_usuario) throws Exception {

        String sql = """
                DELETE FROM usuario
                WHERE id_usuario = ?
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        stmt.setInt(1, id_usuario);

        stmt.executeUpdate();

        stmt.close();
    }

    // ===== EMAIL JÁ EXISTE =====

    public boolean emailJaExiste(String email) throws Exception {

        String sql = """
                SELECT COUNT(*)
                FROM usuario
                WHERE email_usuario = ?
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        stmt.setString(1, email);

        ResultSet rs = stmt.executeQuery();

        boolean existe = rs.next() && rs.getInt(1) > 0;

        rs.close();
        stmt.close();

        return existe;
    }

    // ===== EMAIL JÁ EXISTE IGNORANDO ID =====

    public boolean emailJaExiste(String email, int idExcluir) throws Exception {

        String sql = """
                SELECT COUNT(*)
                FROM usuario
                WHERE email_usuario = ?
                AND id_usuario != ?
                """;

        PreparedStatement stmt = conexao.prepareStatement(sql);

        stmt.setString(1, email);
        stmt.setInt(2, idExcluir);

        ResultSet rs = stmt.executeQuery();

        boolean existe = rs.next() && rs.getInt(1) > 0;

        rs.close();
        stmt.close();

        return existe;
    }

    // ===== LISTAR POR TIPO =====

    public List<Usuario> listarPorTipo(TipoUsuario tipo) throws SQLException {

        List<Usuario> lista = new ArrayList<>();

        String sql = """
                SELECT *
                FROM usuario
                WHERE tipo_usuario = ?
                AND status_usuario = 'ATIVO'
                ORDER BY nome_usuario
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, tipo.name());

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }

        return lista;
    }

    // ===== BUSCAR COM FILTROS =====

    public List<Usuario> buscarUsuarios(String termoBusca,
                                        TipoUsuario tipo,
                                        StatusUsuario status) throws Exception {

        List<Usuario> lista = new ArrayList<>();

        StringBuilder sql = new StringBuilder("""
                SELECT *
                FROM usuario
                WHERE 1=1
                """);

        if (termoBusca != null && !termoBusca.trim().isEmpty()) {

            sql.append("""
                     AND (
                        nome_usuario LIKE ?
                        OR email_usuario LIKE ?
                        OR telefone_usuario LIKE ?
                     )
                    """);
        }

        if (tipo != null) {
            sql.append(" AND tipo_usuario = ?");
        }

        if (status != null) {
            sql.append(" AND status_usuario = ?");
        }

        sql.append(" ORDER BY id_usuario");

        PreparedStatement stmt =
                conexao.prepareStatement(sql.toString());

        int index = 1;

        if (termoBusca != null && !termoBusca.trim().isEmpty()) {

            String busca = "%" + termoBusca + "%";

            stmt.setString(index++, busca);
            stmt.setString(index++, busca);
            stmt.setString(index++, busca);
        }

        if (tipo != null) {
            stmt.setString(index++, tipo.name());
        }

        if (status != null) {
            stmt.setString(index++, status.name());
        }

        ResultSet rs = stmt.executeQuery();

        while (rs.next()) {
            lista.add(mapear(rs));
        }

        rs.close();
        stmt.close();

        return lista;
    }
    
 // ===== UTILITÁRIOS PRIVADOS =====

    /**
     * Normaliza o nome: primeira letra de cada palavra maiúscula, resto minúsculo.
     * "ANA BEATRIZ" ou "ana beatriz" → "Ana Beatriz"
     */
    private String normalizarNome(String nome) {
        if (nome == null || nome.trim().isEmpty()) return nome;

        String[] palavras = nome.trim().toLowerCase().split("\\s+");
        StringBuilder resultado = new StringBuilder();

        for (String palavra : palavras) {
            if (!palavra.isEmpty()) {
                resultado.append(Character.toUpperCase(palavra.charAt(0)))
                         .append(palavra.substring(1))
                         .append(" ");
            }
        }

        return resultado.toString().trim();
    }

    /**
     * Gera username no padrão @primeira.segunda a partir do nome.
     * "Ana Beatriz Silva" → "@ana.beatriz.silva"
     *
     * Remove acentos, caracteres especiais e espaços extras.
     * Se o username já existir no banco, adiciona um número: @ana.beatriz2, @ana.beatriz3 ...
     */
    private String gerarUsername(String nome) throws Exception {

        // 1. Remove acentos via normalização Unicode
        String semAcento = java.text.Normalizer
                .normalize(nome.trim(), java.text.Normalizer.Form.NFD)
                .replaceAll("[^\\p{ASCII}]", "");

        // 2. Minúsculo, substitui espaços por ponto, remove o que não for letra/ponto
        String base = semAcento.toLowerCase()
                                .trim()
                                .replaceAll("\\s+", ".")
                                .replaceAll("[^a-z.]", "");

        // 3. Remove pontos duplos ou pontos nas bordas
        base = base.replaceAll("\\.{2,}", ".").replaceAll("^\\.|\\.$", "");

        String candidato = "@" + base;

        // 4. Verifica unicidade; se existir, incrementa sufixo numérico
        if (!usernameJaExiste(candidato)) {
            return candidato;
        }

        int sufixo = 2;
        while (true) {
            String tentativa = "@" + base + sufixo;
            if (!usernameJaExiste(tentativa)) {
                return tentativa;
            }
            sufixo++;
        }
    }

    /**
     * Verifica se um username já está cadastrado no banco.
     */
    private boolean usernameJaExiste(String username) throws Exception {

        String sql = """
                SELECT COUNT(*)
                FROM usuario
                WHERE username_usuario = ?
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setString(1, username);
            ResultSet rs = stmt.executeQuery();
            boolean existe = rs.next() && rs.getInt(1) > 0;
            rs.close();
            return existe;
        }
    }

    // ===== CADASTRAR COM NOME NORMALIZADO E USERNAME AUTOMÁTICO =====

    /**
     * Versão do cadastrarUsuario que aplica automaticamente:
     * - Normalização do nome (Ana Beatriz)
     * - Geração do username (@ana.beatriz)
     *
     * Use este método no CadastroController no lugar do cadastrarUsuario original.
     */
    public void cadastrarUsuarioNovo(Usuario usuario) throws Exception {

        // Normaliza o nome antes de salvar
        String nomeNormalizado = normalizarNome(usuario.getNome_usuario());
        usuario.setNome_usuario(nomeNormalizado);

        // Gera e atribui o username automático
        String username = gerarUsername(nomeNormalizado);
        usuario.setUsername_usuario(username);

        // Chama o cadastro normal (já existente no DAO)
        cadastrarUsuario(usuario);
    }
    public void atualizarFotoUsuario(int id, String caminhoFoto) throws SQLException {
        String sql = "UPDATE usuario SET foto_usuario = ? WHERE id_usuario = ?";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, caminhoFoto);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }
    
    
}