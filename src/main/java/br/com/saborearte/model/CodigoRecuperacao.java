package br.com.saborearte.model;

import java.time.LocalDateTime;

public class CodigoRecuperacao {

    // ===== Atributos =====

    private int id_codigo;
    private int usuario;
    private String codigo;
    private LocalDateTime data_criacao;
    private LocalDateTime data_expiracao;
    private boolean usado;

    // ===== Construtor vazio =====

    public CodigoRecuperacao() {
    }

    // ===== Construtor completo =====

    public CodigoRecuperacao(int id_codigo,
                             int usuario,
                             String codigo,
                             LocalDateTime data_criacao,
                             LocalDateTime data_expiracao,
                             boolean usado) {

        this.id_codigo = id_codigo;
        this.usuario = usuario;
        this.codigo = codigo;
        this.data_criacao = data_criacao;
        this.data_expiracao = data_expiracao;
        this.usado = usado;
    }

    // ===== Getters e Setters =====

    public int getId_codigo() { return id_codigo; }
    public void setId_codigo(int id_codigo) { this.id_codigo = id_codigo; }

    public int getUsuario() { return usuario; }
    public void setUsuario(int usuario) { this.usuario = usuario; }

    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public LocalDateTime getData_criacao() { return data_criacao; }
    public void setData_criacao(LocalDateTime data_criacao) { this.data_criacao = data_criacao; }

    public LocalDateTime getData_expiracao() { return data_expiracao; }
    public void setData_expiracao(LocalDateTime data_expiracao) { this.data_expiracao = data_expiracao; }

    public boolean isUsado() { return usado; }
    public void setUsado(boolean usado) { this.usado = usado; }
}