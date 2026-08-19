package br.com.saborearte.model;

public class Especialidade {

    // ===== Atributos =====

    private int id_usuario;
    private int id_categoria;
    private int tempo_especialidade;

    // ===== Construtor vazio =====

    public Especialidade() {
    }

    // ===== Construtor completo =====

    public Especialidade(int id_usuario, int id_categoria, int tempo_especialidade) {

        this.id_usuario = id_usuario;
        this.id_categoria = id_categoria;
        this.tempo_especialidade = tempo_especialidade;
    }

    // ===== Getters e Setters =====

    public int getId_usuario() {
        return id_usuario;
    }

    public void setId_usuario(int id_usuario) {
        this.id_usuario = id_usuario;
    }

    public int getId_categoria() {
        return id_categoria;
    }

    public void setId_categoria(int id_categoria) {
        this.id_categoria = id_categoria;
    }

    public int getTempo_especialidade() {
        return tempo_especialidade;
    }

    public void setTempo_especialidade(int tempo_especialidade) {
        this.tempo_especialidade = tempo_especialidade;
    }
}