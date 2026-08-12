package br.com.saborearte.model;

public class Passo {

    // ===== Atributos =====

    private int id_passo;
    private int receita;
    private int ordem_passo;
    private String titulo_passo;
    private String descricao_passo;

    // ===== Construtor vazio =====

    public Passo() {
    }

    // ===== Construtor completo =====

    public Passo(int id_passo,
                 int receita,
                 int ordem_passo,
                 String titulo_passo,
                 String descricao_passo) {

        this.id_passo = id_passo;
        this.receita = receita;
        this.ordem_passo = ordem_passo;
        this.titulo_passo = titulo_passo;
        this.descricao_passo = descricao_passo;
    }

    // ===== Construtor sem ID =====

    public Passo(int receita,
                 int ordem_passo,
                 String titulo_passo,
                 String descricao_passo) {

        this.receita = receita;
        this.ordem_passo = ordem_passo;
        this.titulo_passo = titulo_passo;
        this.descricao_passo = descricao_passo;
    }

    // ===== Getters e Setters =====

    public int getId_passo() { return id_passo; }
    public void setId_passo(int id_passo) { this.id_passo = id_passo; }

    public int getReceita() { return receita; }
    public void setReceita(int receita) { this.receita = receita; }

    public int getOrdem_passo() { return ordem_passo; }
    public void setOrdem_passo(int ordem_passo) { this.ordem_passo = ordem_passo; }

    public String getTitulo_passo() { return titulo_passo; }
    public void setTitulo_passo(String titulo_passo) { this.titulo_passo = titulo_passo; }

    public String getDescricao_passo() { return descricao_passo; }
    public void setDescricao_passo(String descricao_passo) { this.descricao_passo = descricao_passo; }
}