package br.com.saborearte.model;

public class Receita {

    // ===== Atributos =====

    private int id_receita;
    private int categoria;
    private int usuario;

    private String titulo_receita;
    private String data_criacao_receita;
    private String data_publicacao_receita;
    private int tempo_preparo_receita;
    private String rendimento_receita;
    private String imagem_receita;
    private int visualizacoes_receita;

    // ===== ENUMS =====

    public enum StatusReceita {
        rascunho,
        aguardando_aprovacao,
        publicada,
        rejeitada,
        arquivada
    }

    // DEFAULT
    private StatusReceita status_receita = StatusReceita.rascunho;

    // ===== Construtor vazio =====

    public Receita() {
    }

    // ===== Construtor completo =====

    public Receita(int id_receita,
                   int categoria,
                   int usuario,
                   String titulo_receita,
                   String data_criacao_receita,
                   String data_publicacao_receita,
                   int tempo_preparo_receita,
                   String rendimento_receita,
                   String imagem_receita,
                   StatusReceita status_receita,
                   int visualizacoes_receita) {

        this.id_receita = id_receita;
        this.categoria = categoria;
        this.usuario = usuario;
        this.titulo_receita = titulo_receita;
        this.data_criacao_receita = data_criacao_receita;
        this.data_publicacao_receita = data_publicacao_receita;
        this.tempo_preparo_receita = tempo_preparo_receita;
        this.rendimento_receita = rendimento_receita;
        this.imagem_receita = imagem_receita;
        this.status_receita = status_receita;
        this.visualizacoes_receita = visualizacoes_receita;
    }

    // ===== Construtor sem ID =====

    public Receita(int categoria,
                   int usuario,
                   String titulo_receita,
                   String data_criacao_receita,
                   String data_publicacao_receita,
                   int tempo_preparo_receita,
                   String rendimento_receita,
                   String imagem_receita,
                   StatusReceita status_receita,
                   int visualizacoes_receita) {

        this.categoria = categoria;
        this.usuario = usuario;
        this.titulo_receita = titulo_receita;
        this.data_criacao_receita = data_criacao_receita;
        this.data_publicacao_receita = data_publicacao_receita;
        this.tempo_preparo_receita = tempo_preparo_receita;
        this.rendimento_receita = rendimento_receita;
        this.imagem_receita = imagem_receita;
        this.status_receita = status_receita;
        this.visualizacoes_receita = visualizacoes_receita;
    }

    // ===== Getters e Setters =====

    public int getId_receita() { return id_receita; }
    public void setId_receita(int id_receita) { this.id_receita = id_receita; }

    public int getCategoria() { return categoria; }
    public void setCategoria(int categoria) { this.categoria = categoria; }

    public int getUsuario() { return usuario; }
    public void setUsuario(int usuario) { this.usuario = usuario; }

    public String getTitulo_receita() { return titulo_receita; }
    public void setTitulo_receita(String titulo_receita) { this.titulo_receita = titulo_receita; }

    public String getData_criacao_receita() { return data_criacao_receita; }
    public void setData_criacao_receita(String data_criacao_receita) { this.data_criacao_receita = data_criacao_receita; }

    public String getData_publicacao_receita() { return data_publicacao_receita; }
    public void setData_publicacao_receita(String data_publicacao_receita) { this.data_publicacao_receita = data_publicacao_receita; }

    public int getTempo_preparo_receita() { return tempo_preparo_receita; }
    public void setTempo_preparo_receita(int tempo_preparo_receita) { this.tempo_preparo_receita = tempo_preparo_receita; }

    public String getRendimento_receita() { return rendimento_receita; }
    public void setRendimento_receita(String rendimento_receita) { this.rendimento_receita = rendimento_receita; }

    public String getImagem_receita() { return imagem_receita; }
    public void setImagem_receita(String imagem_receita) { this.imagem_receita = imagem_receita; }

    public StatusReceita getStatus_receita() { return status_receita; }
    public void setStatus_receita(StatusReceita status_receita) { this.status_receita = status_receita; }

    public int getVisualizacoes_receita() { return visualizacoes_receita; }
    public void setVisualizacoes_receita(int visualizacoes_receita) { this.visualizacoes_receita = visualizacoes_receita; }
}