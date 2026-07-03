package br.com.saborearte.model;

public class CategoriaCor {

    // ===== Atributos =====

    private int id_cor;
    private String unicode_cor;

    // ===== Construtor vazio =====

    public CategoriaCor() {
    }

    // ===== Construtor completo =====

    public CategoriaCor(int id_cor, String unicode_cor) {
        this.id_cor = id_cor;
        this.unicode_cor = unicode_cor;
    }

    // ===== Construtor sem ID =====

    public CategoriaCor(String unicode_cor) {
        this.unicode_cor = unicode_cor;
    }

    // ===== Getters e Setters =====

    public int getId_cor() { return id_cor; }
    public void setId_cor(int id_cor) { this.id_cor = id_cor; }

    public String getUnicode_cor() { return unicode_cor; }
    public void setUnicode_cor(String unicode_cor) { this.unicode_cor = unicode_cor; }
}