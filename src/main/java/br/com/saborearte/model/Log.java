package br.com.saborearte.model;

public class Log {

    // ===== Atributos =====

    private int id_log;
    private int usuario;
    private String acao_log;
    private String detalhe_log;
    private String data_log;

    // ===== Construtor vazio =====

    public Log() {
    }

    // ===== Construtor completo =====

    public Log(int id_log,
               int usuario,
               String acao_log,
               String detalhe_log,
               String data_log) {

        this.id_log = id_log;
        this.usuario = usuario;
        this.acao_log = acao_log;
        this.detalhe_log = detalhe_log;
        this.data_log = data_log;
    }

    // ===== Construtor sem ID =====

    public Log(int usuario,
               String acao_log,
               String detalhe_log,
               String data_log) {

        this.usuario = usuario;
        this.acao_log = acao_log;
        this.detalhe_log = detalhe_log;
        this.data_log = data_log;
    }

    // ===== Getters e Setters =====

    public int getId_log() { return id_log; }
    public void setId_log(int id_log) { this.id_log = id_log; }

    public int getUsuario() { return usuario; }
    public void setUsuario(int usuario) { this.usuario = usuario; }

    public String getAcao_log() { return acao_log; }
    public void setAcao_log(String acao_log) { this.acao_log = acao_log; }

    public String getDetalhe_log() { return detalhe_log; }
    public void setDetalhe_log(String data_log) { this.detalhe_log = data_log; }
    
    public String getData_log() { return data_log; }
    public void setData_log(String data_log) { this.data_log = data_log; }
}