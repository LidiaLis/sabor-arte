package br.com.saborearte.model;

public class Comentario {

    // ===== Atributos =====

    private int id_comentario;
    private int receita;
    private int usuario;

    private String texto_comentario;
    private String data_criacao_comentario;
    private String data_modera_comentario;
    private int avaliacao_comentario;

    // ===== ENUMS =====

    public enum StatusComentario {
        PENDENTE,
        APROVADO,
        REJEITADO,
        REMOVIDO
    }

    // DEFAULT
    private StatusComentario status_comentario = StatusComentario.PENDENTE;

    // ===== Campos extras (NÃO existem na tabela comentario — não persistir) =====
    // Preenchidos via JOIN em listarComentariosPorReceita (ComentarioDAO).
    // Nunca usar esses campos em INSERT/UPDATE.

    private String nome_usuario;
    private String foto_usuario;

    // ===== Construtor vazio =====

    public Comentario() {
    }

    // ===== Construtor completo =====
    // OBS: corrigido aqui — antes essa sobrecarga jogava data_criacao_comentario
    // dentro de data_modera_comentario por engano (bug de copiar/colar).

    public Comentario(int id_comentario,
                      int receita,
                      int usuario,
                      String texto_comentario,
                      String data_criacao_comentario,
                      String data_modera_comentario,
                      StatusComentario status_comentario,
                      int avaliacao_comentario) {

        this.id_comentario = id_comentario;
        this.receita = receita;
        this.usuario = usuario;
        this.texto_comentario = texto_comentario;
        this.data_criacao_comentario = data_criacao_comentario;
        this.data_modera_comentario = data_modera_comentario;
        this.status_comentario = status_comentario;
        this.avaliacao_comentario = avaliacao_comentario;
    }

    // ===== Construtor sem ID =====
    // OBS: mesma correção do construtor completo.

    public Comentario(int receita,
                      int usuario,
                      String texto_comentario,
                      String data_criacao_comentario,
                      String data_modera_comentario,
                      StatusComentario status_comentario,
                      int avaliacao_comentario) {

        this.receita = receita;
        this.usuario = usuario;
        this.texto_comentario = texto_comentario;
        this.data_criacao_comentario = data_criacao_comentario;
        this.data_modera_comentario = data_modera_comentario;
        this.status_comentario = status_comentario;
        this.avaliacao_comentario = avaliacao_comentario;
    }

    // ===== Getters e Setters =====

    public int getId_comentario() { return id_comentario; }
    public void setId_comentario(int id_comentario) { this.id_comentario = id_comentario; }

    public int getReceita() { return receita; }
    public void setReceita(int receita) { this.receita = receita; }

    public int getUsuario() { return usuario; }
    public void setUsuario(int usuario) { this.usuario = usuario; }

    public String getTexto_comentario() { return texto_comentario; }
    public void setTexto_comentario(String texto_comentario) { this.texto_comentario = texto_comentario; }

    public String getData_criacao_comentario() { return data_criacao_comentario; }
    public void setData_criacao_comentario(String data_criacao_comentario) { this.data_criacao_comentario = data_criacao_comentario; }
    
    public String getData_modera_comentario() { return data_modera_comentario; }
    public void setData_modera_comentario(String data_modera_comentario) { this.data_modera_comentario = data_modera_comentario; }

    public StatusComentario getStatus_comentario() { return status_comentario; }
    public void setStatus_comentario(StatusComentario status_comentario) { this.status_comentario = status_comentario; }

    public int getAvaliacao_comentario() { return avaliacao_comentario; }
    public void setAvaliacao_comentario(int avaliacao_comentario) { this.avaliacao_comentario = avaliacao_comentario; }

    // ===== Getters e Setters — campos extras (não persistidos) =====

    public String getNome_usuario() { return nome_usuario; }
    public void setNome_usuario(String nome_usuario) { this.nome_usuario = nome_usuario; }

    public String getFoto_usuario() { return foto_usuario; }
    public void setFoto_usuario(String foto_usuario) { this.foto_usuario = foto_usuario; }
}