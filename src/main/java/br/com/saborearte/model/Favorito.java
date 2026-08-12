package br.com.saborearte.model;

import java.time.LocalDateTime;

/*CREATE TABLE receita_favorita (
    id_usuario INT NOT NULL,
    id_receita INT NOT NULL,
    data_favorito DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_usuario, id_receita),

    CONSTRAINT fk_favorita_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_favorita_receita
        FOREIGN KEY (id_receita)
        REFERENCES receita(id_receita)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);*/
public class Favorito {
	
	  private int idUsuario;
	    private int idReceita;
	    private LocalDateTime dataFavorito;

	    public Favorito() {
	    }

	    public Favorito(int idUsuario, int idReceita, LocalDateTime dataFavorito) {
	        this.idUsuario = idUsuario;
	        this.idReceita = idReceita;
	        this.dataFavorito = dataFavorito;
	    }

	    public int getIdUsuario() {
	        return idUsuario;
	    }

	    public void setIdUsuario(int idUsuario) {
	        this.idUsuario = idUsuario;
	    }

	    public int getIdReceita() {
	        return idReceita;
	    }

	    public void setIdReceita(int idReceita) {
	        this.idReceita = idReceita;
	    }

	    public LocalDateTime getDataFavorito() {
	        return dataFavorito;
	    }

	    public void setDataFavorito(LocalDateTime dataFavorito) {
	        this.dataFavorito = dataFavorito;
	    }
}
