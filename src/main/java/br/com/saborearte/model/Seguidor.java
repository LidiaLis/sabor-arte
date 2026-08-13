package br.com.saborearte.model;

import java.time.LocalDateTime;

/*CREATE TABLE usuario_seguidor (
    id_seguidor INT NOT NULL,
    id_seguido INT NOT NULL,
    data_seguir DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_seguidor, id_seguido),

    CONSTRAINT fk_usuario_seguidor
        FOREIGN KEY (id_seguidor)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_usuario_seguido
        FOREIGN KEY (id_seguido)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_usuario_diferente
        CHECK (id_seguidor <> id_seguido)
);*/
public class Seguidor {

    private int idSeguidor;
    private int idSeguido;
    private LocalDateTime dataSeguir;

    public Seguidor() {
    }

    public Seguidor(int idSeguidor, int idSeguido, LocalDateTime dataSeguir) {
        this.idSeguidor = idSeguidor;
        this.idSeguido = idSeguido;
        this.dataSeguir = dataSeguir;
    }

    public int getIdSeguidor() {
        return idSeguidor;
    }

    public void setIdSeguidor(int idSeguidor) {
        this.idSeguidor = idSeguidor;
    }

    public int getIdSeguido() {
        return idSeguido;
    }

    public void setIdSeguido(int idSeguido) {
        this.idSeguido = idSeguido;
    }

    public LocalDateTime getDataSeguir() {
        return dataSeguir;
    }

    public void setDataSeguir(LocalDateTime dataSeguir) {
        this.dataSeguir = dataSeguir;
    }
}

