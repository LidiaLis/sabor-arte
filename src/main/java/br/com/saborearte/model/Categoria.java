package br.com.saborearte.model;

public class Categoria {

    // ===== Atributos =====

    private int id_categoria;

    private String nome_categoria;
    private String descricao_categoria;
    private String emoji_categoria;
    private String cor_categoria;

    // ===== ENUMS =====

    public enum StatusCategoria {
        ativa,
        inativa
    }

    // DEFAULT
    private StatusCategoria status_categoria = StatusCategoria.ativa;

    // ===== Construtor vazio =====

    public Categoria() {
    }

    // ===== Construtor completo =====

    public Categoria(int id_categoria,
                     String nome_categoria,
                     String descricao_categoria,
                     String emoji_categoria,
                     String cor_categoria,
                     StatusCategoria status_categoria) {

        this.id_categoria = id_categoria;
        this.nome_categoria = nome_categoria;
        this.descricao_categoria = descricao_categoria;
        this.emoji_categoria = emoji_categoria;
        this.cor_categoria = cor_categoria;
        this.status_categoria = status_categoria;
    }

    // ===== Construtor sem ID =====

    public Categoria(String nome_categoria,
                     String descricao_categoria,
                     String emoji_categoria,
                     String cor_categoria,
                     StatusCategoria status_categoria) {

        this.nome_categoria = nome_categoria;
        this.descricao_categoria = descricao_categoria;
        this.emoji_categoria = emoji_categoria;
        this.cor_categoria = cor_categoria;
        this.status_categoria = status_categoria;
    }

    // ===== Getters e Setters =====

    public int getId_categoria() { return id_categoria; }
    public void setId_categoria(int id_categoria) { this.id_categoria = id_categoria; }

    public String getNome_categoria() { return nome_categoria; }
    public void setNome_categoria(String nome_categoria) { this.nome_categoria = nome_categoria; }

    public String getDescricao_categoria() { return descricao_categoria; }
    public void setDescricao_categoria(String descricao_categoria) { this.descricao_categoria = descricao_categoria; }

    public String getEmoji_categoria() { return emoji_categoria; }
    public void setEmoji_categoria(String emoji_categoria) { this.emoji_categoria = emoji_categoria; }

    public String getCor_categoria() { return cor_categoria; }
    public void setCor_categoria(String cor_categoria) { this.cor_categoria = cor_categoria; }

    public StatusCategoria getStatus_categoria() { return status_categoria; }
    public void setStatus_categoria(StatusCategoria status_categoria) { this.status_categoria = status_categoria; }
}
