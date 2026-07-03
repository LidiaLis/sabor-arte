package br.com.saborearte.model;

public class VisualizacaoReceita {

    // ===== Atributos =====

    private int id_visualizacao;
    private int id_receita;
    private String ip_visualizacao;
    private String data_visualizacao;

    // ===== Construtor vazio =====

    public VisualizacaoReceita() {
    }

    // ===== Construtor completo =====

    public VisualizacaoReceita(int id_visualizacao,
                                int id_receita,
                                String ip_visualizacao,
                                String data_visualizacao) {

        this.id_visualizacao = id_visualizacao;
        this.id_receita = id_receita;
        this.ip_visualizacao = ip_visualizacao;
        this.data_visualizacao = data_visualizacao;
    }

    // ===== Construtor sem ID =====

    public VisualizacaoReceita(int id_receita,
                                String ip_visualizacao,
                                String data_visualizacao) {

        this.id_receita = id_receita;
        this.ip_visualizacao = ip_visualizacao;
        this.data_visualizacao = data_visualizacao;
    }

    // ===== Getters e Setters =====

    public int getId_visualizacao() { return id_visualizacao; }
    public void setId_visualizacao(int id_visualizacao) { this.id_visualizacao = id_visualizacao; }

    public int getId_receita() { return id_receita; }
    public void setId_receita(int id_receita) { this.id_receita = id_receita; }

    public String getIp_visualizacao() { return ip_visualizacao; }
    public void setIp_visualizacao(String ip_visualizacao) { this.ip_visualizacao = ip_visualizacao; }

    public String getData_visualizacao() { return data_visualizacao; }
    public void setData_visualizacao(String data_visualizacao) { this.data_visualizacao = data_visualizacao; }
}