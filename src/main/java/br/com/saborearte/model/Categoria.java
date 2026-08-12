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
        ATIVA,
        INATIVA
    }

    // DEFAULT
    private StatusCategoria status_categoria = StatusCategoria.ATIVA;

    // ===== Campo extra (NÃO existe na tabela categoria — não persistir) =====
    // Preenchido via JOIN em consultas específicas (ex.: listarCategoriasComContagem).
    // Nunca usar esse campo em INSERT/UPDATE.

    private int total_receitas;

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

    // ===== Getter e Setter — campo extra (não persistido) =====

    public int getTotal_receitas() { return total_receitas; }
    public void setTotal_receitas(int total_receitas) { this.total_receitas = total_receitas; }
 
    
    // ===== Campos extras (NÃO existem na tabela usuario — não persistir) =====
    // Adicionar este bloco dentro da classe Usuario já existente, junto
    // com os outros atributos. Preenchidos via JOIN em consultas específicas
    // (ex.: listarAutoresDestaque). Nunca usar em INSERT/UPDATE.

    private String nome_categoria_especialidade;
    private String emoji_categoria_especialidade;
    private int total_receitas_destaque;

    // ===== Getters e Setters — campos extras (não persistidos) =====
    // Adicionar junto com os outros getters/setters da classe Usuario.

    public String getNome_categoria_especialidade() { return nome_categoria_especialidade; }
    public void setNome_categoria_especialidade(String nome_categoria_especialidade) { this.nome_categoria_especialidade = nome_categoria_especialidade; }

    public String getEmoji_categoria_especialidade() { return emoji_categoria_especialidade; }
    public void setEmoji_categoria_especialidade(String emoji_categoria_especialidade) { this.emoji_categoria_especialidade = emoji_categoria_especialidade; }

    public int getTotal_receitas_destaque() { return total_receitas_destaque; }
    public void setTotal_receitas_destaque(int total_receitas_destaque) { this.total_receitas_destaque = total_receitas_destaque; }

}