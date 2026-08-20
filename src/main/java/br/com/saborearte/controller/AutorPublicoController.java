package br.com.saborearte.controller;

import javax.servlet.http.HttpServlet;

/**
 * Classe mantida apenas para compatibilidade de código-fonte.
 *
 * A rota /AutorPublicoController é atendida pelo AutorController unificado.
 * Esta classe não registra servlet para evitar duas classes disputando a
 * mesma URL durante a inicialização do Tomcat.
 */
@Deprecated
public class AutorPublicoController extends HttpServlet {

    private static final long serialVersionUID = 1L;
}
