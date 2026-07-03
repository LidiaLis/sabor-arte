package br.com.saborearte.model;

public class Fluxo {

    // ===== Atributos =====

    private int id_fluxo;
    private int receita;
    private int usuario;

    private String data_fluxo;
    private String observacao_fluxo;

    // ===== ENUMS =====

    public enum StatusFluxo {
        pendente,
        aprovado,
        rejeitado,
        em_revisao
    }

    // DEFAULT
    private StatusFluxo status_fluxo = StatusFluxo.pendente;

    // ===== Construtor vazio =====

    public Fluxo() {
    }

    // ===== Construtor completo =====

    public Fluxo(int id_fluxo,
                 int receita,
                 int usuario,
                 StatusFluxo status_fluxo,
                 String data_fluxo,
                 String observacao_fluxo) {

        this.id_fluxo = id_fluxo;
        this.receita = receita;
        this.usuario = usuario;
        this.status_fluxo = status_fluxo;
        this.data_fluxo = data_fluxo;
        this.observacao_fluxo = observacao_fluxo;
    }

    // ===== Construtor sem ID =====

    public Fluxo(int receita,
                 int usuario,
                 StatusFluxo status_fluxo,
                 String data_fluxo,
                 String observacao_fluxo) {

        this.receita = receita;
        this.usuario = usuario;
        this.status_fluxo = status_fluxo;
        this.data_fluxo = data_fluxo;
        this.observacao_fluxo = observacao_fluxo;
    }

    // ===== Getters e Setters =====

    public int getId_fluxo() { return id_fluxo; }
    public void setId_fluxo(int id_fluxo) { this.id_fluxo = id_fluxo; }

    public int getReceita() { return receita; }
    public void setReceita(int receita) { this.receita = receita; }

    public int getUsuario() { return usuario; }
    public void setUsuario(int usuario) { this.usuario = usuario; }

    public StatusFluxo getStatus_fluxo() { return status_fluxo; }
    public void setStatus_fluxo(StatusFluxo status_fluxo) { this.status_fluxo = status_fluxo; }

    public String getData_fluxo() { return data_fluxo; }
    public void setData_fluxo(String data_fluxo) { this.data_fluxo = data_fluxo; }

    public String getObservacao_fluxo() { return observacao_fluxo; }
    public void setObservacao_fluxo(String observacao_fluxo) { this.observacao_fluxo = observacao_fluxo; }
}