package br.com.saborearte.model;

import br.com.saborearte.model.Usuario.TipoUsuario;

public class Log {

    // ===== Atributos =====

    private int id_log;
    private int usuario;
    private String acao_log;
    private String detalhe_log;
    private String data_log;

    // ===== Campo novo (persistido — requer ALTER TABLE, ver alter_tables.sql) =====
    // Não incluído nos construtores de propósito: LogDAO.registrar(Log, String)
    // já trata a entidade como parâmetro separado, então nenhuma chamada
    // "new Log(...)" existente precisa mudar. Usar setEntidade_log() quando
    // for preencher manualmente (ex.: ao ler de volta do banco).
    private String entidade_log;

    // ===== Campos extras (NÃO existem na tabela log — não persistir) =====
    // Preenchidos via JOIN em consultas específicas (ex.: LogDAO.listarComFiltro).
    // Nunca usar esses campos em INSERT/UPDATE.

    private String nome_usuario;
    private String foto_usuario;
    private TipoUsuario tipo_usuario;

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
    public void setDetalhe_log(String detalhe_log) { this.detalhe_log = detalhe_log; }
    
    public String getData_log() { return data_log; }
    public void setData_log(String data_log) { this.data_log = data_log; }

    // ===== Getter e Setter — campo novo persistido =====

    public String getEntidade_log() { return entidade_log; }
    public void setEntidade_log(String entidade_log) { this.entidade_log = entidade_log; }

    // ===== Getters e Setters — campos extras (não persistidos) =====

    public String getNome_usuario() { return nome_usuario; }
    public void setNome_usuario(String nome_usuario) { this.nome_usuario = nome_usuario; }

    public String getFoto_usuario() { return foto_usuario; }
    public void setFoto_usuario(String foto_usuario) { this.foto_usuario = foto_usuario; }

    public TipoUsuario getTipo_usuario() { return tipo_usuario; }
    public void setTipo_usuario(TipoUsuario tipo_usuario) { this.tipo_usuario = tipo_usuario; }
}