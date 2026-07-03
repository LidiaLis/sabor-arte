package br.com.saborearte.model;

public class Ingrediente {

    // ===== Atributos =====

    private int id_ingrediente;
    private String nome_ingrediente;

    // ===== Construtor vazio =====

    public Ingrediente() {
    }

    // ===== Construtor completo =====

    public Ingrediente(int id_ingrediente,
                       String nome_ingrediente) {

        this.id_ingrediente = id_ingrediente;
        this.nome_ingrediente = nome_ingrediente;
    }

    // ===== Construtor sem ID =====

    public Ingrediente(String nome_ingrediente) {
        this.nome_ingrediente = nome_ingrediente;
    }

    // ===== Getters e Setters =====

    public int getId_ingrediente() { return id_ingrediente; }
    public void setId_ingrediente(int id_ingrediente) { this.id_ingrediente = id_ingrediente; }

    public String getNome_ingrediente() { return nome_ingrediente; }
    public void setNome_ingrediente(String nome_ingrediente) { this.nome_ingrediente = nome_ingrediente; }
}