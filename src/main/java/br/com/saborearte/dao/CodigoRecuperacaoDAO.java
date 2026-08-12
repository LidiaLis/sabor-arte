package br.com.saborearte.dao;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;

/**
 * DAO do fluxo de recuperação de senha (esqueci-senha.html -> verificar-codigo.html
 * -> nova-senha.html). Depende da tabela codigo_recuperacao (ver codigo_recuperacao.sql).
 *
 * Fluxo esperado:
 *  1) esqueci-senha.html envia o e-mail -> Servlet chama gerarCodigo(idUsuario)
 *     e dispara o e-mail com o código retornado (envio de e-mail fica fora do DAO)
 *  2) verificar-codigo.html envia os 6 dígitos -> Servlet chama validarCodigo(idUsuario, codigo)
 *  3) nova-senha.html envia a nova senha -> Servlet chama UsuarioDAO.atualizarSenha(...)
 *     (só deve ser aceito se o passo 2 retornou true na mesma sessão)
 */
public class CodigoRecuperacaoDAO {

    private static final int VALIDADE_MINUTOS = 5;

    private final Connection conexao;
    private final SecureRandom random = new SecureRandom();

    public CodigoRecuperacaoDAO(Connection conexao) {
        this.conexao = conexao;
    }

    // =========================================================================
    // GERAR CÓDIGO
    // =========================================================================

    /**
     * Invalida qualquer código anterior ainda pendente do usuário, gera um novo
     * código numérico de 6 dígitos, salva com validade de 5 minutos e retorna
     * o código gerado (para o Servlet enviar por e-mail).
     */
    public String gerarCodigo(int idUsuario) throws SQLException {

        invalidarCodigosAnteriores(idUsuario);

        String codigo = gerarNumeroAleatorio();

        LocalDateTime agora = LocalDateTime.now();
        LocalDateTime expiracao = agora.plusMinutes(VALIDADE_MINUTOS);

        String sql = """
                INSERT INTO codigo_recuperacao (usuario, codigo, data_criacao, data_expiracao, usado)
                VALUES (?, ?, ?, ?, 0)
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setString(2, codigo);
            stmt.setTimestamp(3, Timestamp.valueOf(agora));
            stmt.setTimestamp(4, Timestamp.valueOf(expiracao));
            stmt.executeUpdate();
        }

        return codigo;
    }

    // =========================================================================
    // VALIDAR CÓDIGO
    // =========================================================================

    /**
     * Verifica se o código informado é o mais recente, não expirou e ainda não
     * foi usado. Se válido, marca como usado (uso único) e retorna true.
     */
    public boolean validarCodigo(int idUsuario, String codigo) throws SQLException {

        String sql = """
                SELECT id_codigo
                FROM codigo_recuperacao
                WHERE usuario = ?
                  AND codigo = ?
                  AND usado = 0
                  AND data_expiracao > ?
                ORDER BY id_codigo DESC
                LIMIT 1
                """;

        Integer idCodigo = null;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.setString(2, codigo);
            stmt.setTimestamp(3, Timestamp.valueOf(LocalDateTime.now()));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    idCodigo = rs.getInt("id_codigo");
                }
            }
        }

        if (idCodigo == null) {
            return false;
        }

        marcarComoUsado(idCodigo);
        return true;
    }

    // =========================================================================
    // INVALIDAR / LIMPAR
    // =========================================================================

    /**
     * Marca como usado qualquer código anterior ainda pendente do usuário,
     * chamado antes de gerar um código novo (evita ter 2 códigos válidos
     * ao mesmo tempo quando o usuário clica em "Reenviar código").
     */
    public void invalidarCodigosAnteriores(int idUsuario) throws SQLException {

        String sql = """
                UPDATE codigo_recuperacao
                SET usado = 1
                WHERE usuario = ?
                  AND usado = 0
                """;

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idUsuario);
            stmt.executeUpdate();
        }
    }

    private void marcarComoUsado(int idCodigo) throws SQLException {

        String sql = "UPDATE codigo_recuperacao SET usado = 1 WHERE id_codigo = ?";

        try (PreparedStatement stmt = conexao.prepareStatement(sql)) {
            stmt.setInt(1, idCodigo);
            stmt.executeUpdate();
        }
    }

    // =========================================================================
    // GERADOR DO NÚMERO
    // =========================================================================

    private String gerarNumeroAleatorio() {
        int numero = 100000 + random.nextInt(900000); // sempre 6 dígitos (100000–999999)
        return String.valueOf(numero);
    }
}