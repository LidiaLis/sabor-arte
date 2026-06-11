package br.com.saborearte.model;

import java.time.LocalDateTime;

public class Usuario {

    // ===== Atributos =====

    private int id_usuario;

    private String nome_usuario;
    private String email_usuario;
    private String senha_usuario;
    
    private String username_usuario;
    private String telefone_usuario;
    private String localizacao_usuario;
    private String foto_usuario;
    private String titulo_usuario;

    private String instagram_usuario;
    private String youtube_usuario;
    private String pinterest_usuario;

    private LocalDateTime data_criacao_usuario;
	
    // ===== ENUMS =====

    public enum TipoUsuario {
        AUTOR,
        EDITOR,
        ADMIN,
        VISITANTE
    }

    public enum StatusUsuario {
        ATIVO,
        INATIVO
    }

    public enum TemaUsuario {
        LIGHT,
        DARK,
        HIGH_CONTRAST
    }

    // DEFAULTS
    private TipoUsuario tipo_usuario = TipoUsuario.VISITANTE;

    private StatusUsuario status_usuario = StatusUsuario.ATIVO;

    private TemaUsuario tema = TemaUsuario.LIGHT;



    // ===== Construtor vazio =====

    public Usuario() {
    }

    // ===== Construtor completo =====

    public Usuario(int id_usuario,
                   String nome_usuario,
                   String email_usuario,
                   String senha_usuario,
                   TipoUsuario tipo_usuario,
                   StatusUsuario status_usuario,
                   TemaUsuario tema,
                   String username_usuario,
                   String telefone_usuario,
                   String localizacao_usuario,
                   String foto_usuario,
                   String titulo_usuario,
                   String instagram_usuario,
                   String youtube_usuario,
                   String pinterest_usuario,
                   LocalDateTime data_criacao_usuario) {

        this.id_usuario = id_usuario;
        this.nome_usuario = nome_usuario;
        this.email_usuario = email_usuario;
        this.senha_usuario = senha_usuario;
        this.tipo_usuario = tipo_usuario;
        this.status_usuario = status_usuario;
        this.tema = tema;
        this.username_usuario = username_usuario;
        this.telefone_usuario = telefone_usuario;
        this.localizacao_usuario = localizacao_usuario;
        this.foto_usuario = foto_usuario;
        this.titulo_usuario = titulo_usuario;
        this.instagram_usuario = instagram_usuario;
        this.youtube_usuario = youtube_usuario;
        this.pinterest_usuario = pinterest_usuario;
        this.data_criacao_usuario = data_criacao_usuario;
    }

    // ===== Construtor sem ID =====

    public Usuario(String nome_usuario,
                   String email_usuario,
                   String senha_usuario,
                   TipoUsuario tipo_usuario,
                   StatusUsuario status_usuario,
                   TemaUsuario tema,
                   String username_usuario,
                   String telefone_usuario,
                   String localizacao_usuario,
                   String foto_usuario,
                   String titulo_usuario,
                   String instagram_usuario,
                   String youtube_usuario,
                   String pinterest_usuario,
                   LocalDateTime data_criacao_usuario) {

        this.nome_usuario = nome_usuario;
        this.email_usuario = email_usuario;
        this.senha_usuario = senha_usuario;
        this.tipo_usuario = tipo_usuario;
        this.status_usuario = status_usuario;
        this.tema = tema;
        this.username_usuario = username_usuario;
        this.telefone_usuario = telefone_usuario;
        this.localizacao_usuario = localizacao_usuario;
        this.foto_usuario = foto_usuario;
        this.titulo_usuario = titulo_usuario;
        this.instagram_usuario = instagram_usuario;
        this.youtube_usuario = youtube_usuario;
        this.pinterest_usuario = pinterest_usuario;
        this.data_criacao_usuario = data_criacao_usuario;
    }

    // ===== Getters e Setters =====

    public int getId_usuario() {
        return id_usuario;
    }

    public void setId_usuario(int id_usuario) {
        this.id_usuario = id_usuario;
    }

    public String getNome_usuario() {
        return nome_usuario;
    }

    public void setNome_usuario(String nome_usuario) {
        this.nome_usuario = nome_usuario;
    }

    public String getEmail_usuario() {
        return email_usuario;
    }

    public void setEmail_usuario(String email_usuario) {
        this.email_usuario = email_usuario;
    }

    public String getSenha_usuario() {
        return senha_usuario;
    }

    public void setSenha_usuario(String senha_usuario) {
        this.senha_usuario = senha_usuario;
    }

    public TipoUsuario getTipo_usuario() {
        return tipo_usuario;
    }

    public void setTipo_usuario(TipoUsuario tipo_usuario) {
        this.tipo_usuario = tipo_usuario;
    }

    public StatusUsuario getStatus_usuario() {
        return status_usuario;
    }

    public void setStatus_usuario(StatusUsuario status_usuario) {
        this.status_usuario = status_usuario;
    }

    public TemaUsuario getTema() {
        return tema;
    }

    public void setTema(TemaUsuario tema) {
        this.tema = tema;
    }

    public String getUsername_usuario() {
        return username_usuario;
    }

    public void setUsername_usuario(String username_usuario) {
        this.username_usuario = username_usuario;
    }

    public String getTelefone_usuario() {
        return telefone_usuario;
    }

    public void setTelefone_usuario(String telefone_usuario) {
        this.telefone_usuario = telefone_usuario;
    }

    public String getLocalizacao_usuario() {
        return localizacao_usuario;
    }

    public void setLocalizacao_usuario(String localizacao_usuario) {
        this.localizacao_usuario = localizacao_usuario;
    }

    public String getFoto_usuario() {
        return foto_usuario;
    }

    public void setFoto_usuario(String foto_usuario) {
        this.foto_usuario = foto_usuario;
    }

    public String getTitulo_usuario() {
        return titulo_usuario;
    }

    public void setTitulo_usuario(String titulo_usuario) {
        this.titulo_usuario = titulo_usuario;
    }

    public String getInstagram_usuario() {
        return instagram_usuario;
    }

    public void setInstagram_usuario(String instagram_usuario) {
        this.instagram_usuario = instagram_usuario;
    }

    public String getYoutube_usuario() {
        return youtube_usuario;
    }

    public void setYoutube_usuario(String youtube_usuario) {
        this.youtube_usuario = youtube_usuario;
    }

    public String getPinterest_usuario() {
        return pinterest_usuario;
    }

    public void setPinterest_usuario(String pinterest_usuario) {
        this.pinterest_usuario = pinterest_usuario;
    }

    public LocalDateTime getData_criacao_usuario() {
        return data_criacao_usuario;
    }

    public void setData_criacao_usuario(LocalDateTime data_criacao_usuario) {
        this.data_criacao_usuario = data_criacao_usuario;
    }
}