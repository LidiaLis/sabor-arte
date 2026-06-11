package br.com.saborearte.model;

import java.sql.Timestamp;

public class Log {
    
	private int       id_log;
    private Integer   usuarioId;
    private String    usuarioNome;
    private String    acao;
    private String    entidade;
    private Integer   entidadeId;
    private String    detalhes;
    private Timestamp dataHora;

    //Constantes --------------
    
    //Ações padrão
    public static final String ACAO_LOGIN             = "LOGIN";
    public static final String ACAO_LOGOUT            = "LOGOUT";
    public static final String ACAO_CRIAR             = "CRIAR";
    public static final String ACAO_EDITAR            = "EDITAR";
    public static final String ACAO_DELETAR           = "DELETAR";
    public static final String ACAO_EMPRESTAR         = "EMPRESTAR";
    public static final String ACAO_DEVOLVER          = "DEVOLVER";
    public static final String ACAO_RESTAURACAO       = "RESTAURACAO";
    public static final String ACAO_ATUALIZAR_PERFIL  = "ATUALIZAR_PERFIL";
    public static final String ACAO_LIMPAR_LOGS       = "LIMPAR_LOGS";
    public static final String ACAO_BACKUP            = "BACKUP";
    public static final String ACAO_EXPORTAR = "EXPORTAR";
    
    //Entidades padrão
    public static final String ENT_USUARIO      = "Usuario";
    public static final String ENT_LIVRO        = "Livro";
    public static final String ENT_MOVIMENTACAO = "Movimentacao";
    public static final String ENT_RESTAURACAO  = "Restauracao";
    public static final String ENT_SISTEMA      = "Sistema";
    public static final String ENT_LOG          = "Log";
    public static final String ENT_RELATORIO = "Relatorio";
    
    //Construtores ---------------
    
    // Construtor vazio
    public Log() {}

    // Construtor COM ID
    public Log(int id_log, Integer usuarioId, String usuarioNome,
            String acao, String entidade,
            Integer entidadeId, String detalhes) {
    	this.usuarioId   = usuarioId;
    	this.usuarioNome = usuarioNome;
    	this.acao        = acao;
    	this.entidade    = entidade;
    	this.entidadeId  = entidadeId;
		this.detalhes    = detalhes;
    }

    // Construtor SEM ID
    public Log(Integer usuarioId, String usuarioNome,
            String acao, String entidade,
            Integer entidadeId, String detalhes) {
    	this.usuarioId   = usuarioId;
    	this.usuarioNome = usuarioNome;
    	this.acao        = acao;
    	this.entidade    = entidade;
    	this.entidadeId  = entidadeId;
		this.detalhes    = detalhes;
    }

    // GETTERS E SETTERS
    public int getId_log() {
        return id_log;
    }
    public void setId_log(int id_log) {
        this.id_log = id_log;
    }

    public Integer getUsuarioId() {
        return usuarioId;
    }
    public void setUsuarioId(Integer usuarioId) {
        this.usuarioId = usuarioId;
    }

    public String getUsuarioNome() {
        return usuarioNome;
    }
    public void setUsuarioNome(String usuarioNome) {
        this.usuarioNome = usuarioNome;
    }

    public String getAcao() {
        return acao;
    }
    public void setAcao(String acao) {
        this.acao = acao;
    }

    public String getEntidade() {
        return entidade;
    }
    public void setEntidade(String entidade) {
        this.entidade = entidade;
    }

    public Integer getEntidadeId() {
        return entidadeId;
    }
    public void setEntidadeId(Integer entidadeId) {
        this.entidadeId = entidadeId;
    }

    public String getDetalhes() {
        return detalhes;
    }
    public void setDetalhes(String detalhes) {
        this.detalhes = detalhes;
    }

    public Timestamp getDataHora() {
        return dataHora;
    }
    public void setDataHora(Timestamp dataHora) {
        this.dataHora = dataHora;
    }
}