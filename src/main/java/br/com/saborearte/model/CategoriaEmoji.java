package br.com.saborearte.model;

public class CategoriaEmoji {

    // ===== Atributos =====

    private int id_emoji;
    private String unicode_emoji;

    // ===== Construtor vazio =====

    public CategoriaEmoji() {
    }

    // ===== Construtor completo =====

    public CategoriaEmoji(int id_emoji, String unicode_emoji) {
        this.id_emoji = id_emoji;
        this.unicode_emoji = unicode_emoji;
    }

    // ===== Construtor sem ID =====

    public CategoriaEmoji(String unicode_emoji) {
        this.unicode_emoji = unicode_emoji;
    }

    // ===== Getters e Setters =====

    public int getId_emoji() { return id_emoji; }
    public void setId_emoji(int id_emoji) { this.id_emoji = id_emoji; }

    public String getUnicode_emoji() { return unicode_emoji; }
    public void setUnicode_emoji(String unicode_emoji) { this.unicode_emoji = unicode_emoji; }
}