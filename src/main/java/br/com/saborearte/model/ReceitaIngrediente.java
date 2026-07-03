package br.com.saborearte.model;

public class ReceitaIngrediente {

    // ===== Atributos =====

    private int id_receita;
    private int id_ingrediente;
    private int quantidade_receita_ingrediente;
    private String unidade_medida_receita_ingrediente;

    // ===== Construtor vazio =====

    public ReceitaIngrediente() {
    }

    // ===== Construtor completo =====

    public ReceitaIngrediente(int id_receita,
                               int id_ingrediente,
                               int quantidade_receita_ingrediente,
                               String unidade_medida_receita_ingrediente) {

        this.id_receita = id_receita;
        this.id_ingrediente = id_ingrediente;
        this.quantidade_receita_ingrediente = quantidade_receita_ingrediente;
        this.unidade_medida_receita_ingrediente = unidade_medida_receita_ingrediente;
    }

    // ===== Getters e Setters =====

    public int getId_receita() { return id_receita; }
    public void setId_receita(int id_receita) { this.id_receita = id_receita; }

    public int getId_ingrediente() { return id_ingrediente; }
    public void setId_ingrediente(int id_ingrediente) { this.id_ingrediente = id_ingrediente; }

    public int getQuantidade_receita_ingrediente() { return quantidade_receita_ingrediente; }
    public void setQuantidade_receita_ingrediente(int quantidade_receita_ingrediente) { this.quantidade_receita_ingrediente = quantidade_receita_ingrediente; }

    public String getUnidade_medida_receita_ingrediente() { return unidade_medida_receita_ingrediente; }
    public void setUnidade_medida_receita_ingrediente(String unidade_medida_receita_ingrediente) { this.unidade_medida_receita_ingrediente = unidade_medida_receita_ingrediente; }
}