package br.com.saborearte.model;

import java.math.BigDecimal;

public class ConfiguracaoSistema {

    private int        id;
    private String     nomeInstituicao;
    private int        limiteLivrosUsuario;
    private BigDecimal acrescimoRestauracao;
    private BigDecimal descontoMovimentacao; //ADCIONADO A PEDIDO DE EDUARDO

    // ===== Getters e Setters =====

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNomeInstituicao() {
        return nomeInstituicao;
    }

    public void setNomeInstituicao(String nomeInstituicao) {
        this.nomeInstituicao = nomeInstituicao;
    }

    public int getLimiteLivrosUsuario() {
        return limiteLivrosUsuario;
    }

    public void setLimiteLivrosUsuario(int limiteLivrosUsuario) {
        this.limiteLivrosUsuario = limiteLivrosUsuario;
    }

    public BigDecimal getAcrescimoRestauracao() {
        return acrescimoRestauracao;
    }

    public void setAcrescimoRestauracao(BigDecimal acrescimoRestauracao) {
        this.acrescimoRestauracao = acrescimoRestauracao;
    }

    public BigDecimal getDescontoMovimentacao() {
        return descontoMovimentacao;
    }

    public void setDescontoMovimentacao(BigDecimal descontoMovimentacao) {
        this.descontoMovimentacao = descontoMovimentacao;
    }
}