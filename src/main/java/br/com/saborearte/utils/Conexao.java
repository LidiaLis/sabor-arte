package br.com.saborearte.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Classe utilitária para gerenciar conexões com o banco de dados
 */
public class Conexao {
    
    // Configurações do banco de dados - AJUSTE CONFORME SEU AMBIENTE
    private static final String URL = "jdbc:mysql://localhost:3306/blog_culinario";
    private static final String USER = "root";
    private static final String PASSWORD = "Juninsql@1";
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";
    
    // Carrega o driver JDBC
    static {
        try {
            Class.forName(DRIVER);
            System.out.println("Driver MySQL carregado com sucesso!");
        } catch (ClassNotFoundException e) {
            System.err.println("Erro ao carregar driver MySQL: " + e.getMessage());
            throw new RuntimeException("Driver MySQL não encontrado!", e);
        }
    }
    
    /**
     * Obtém uma conexão com o banco de dados
     * @return Connection
     * @throws SQLException
     */
    public static Connection getConnection() throws SQLException {
        try {
            Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("Conexão estabelecida com sucesso!");
            return conn;
        } catch (SQLException e) {
            System.err.println("Erro ao conectar ao banco de dados: " + e.getMessage());
            throw e;
        }
    }
    
    /**
     * Fecha a conexão com o banco de dados
     * @param conn Conexão a ser fechada
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
                System.out.println("Conexão fechada com sucesso!");
            } catch (SQLException e) {
                System.err.println("Erro ao fechar conexão: " + e.getMessage());
            }
        }
    }
    
    /**
     * Fecha PreparedStatement
     * @param stmt PreparedStatement a ser fechado
     */
    public static void closeStatement(PreparedStatement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                System.err.println("Erro ao fechar statement: " + e.getMessage());
            }
        }
    }
    
    /**
     * Fecha ResultSet
     * @param rs ResultSet a ser fechado
     */
    public static void closeResultSet(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                System.err.println("Erro ao fechar result set: " + e.getMessage());
            }
        }
    }
    
    /**
     * Fecha todos os recursos de uma vez
     * @param conn Conexão
     * @param stmt PreparedStatement
     * @param rs ResultSet
     */
    public static void closeResources(Connection conn, PreparedStatement stmt, ResultSet rs) {
        closeResultSet(rs);
        closeStatement(stmt);
        closeConnection(conn);
    }
    
    /**
     * Testa a conexão com o banco de dados
     * @return true se conectou com sucesso, false caso contrário
     */
    public static boolean testarConexao() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            System.err.println("Falha ao testar conexão: " + e.getMessage());
            return false;
        }
    }
}
