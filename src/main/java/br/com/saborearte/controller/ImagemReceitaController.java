package br.com.saborearte.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import br.com.saborearte.service.ImagemReceitaStorage;

/** Entrega imagens persistidas fora do diretório de publicação do Tomcat. */
@WebServlet("/uploads/receitas/*")
public class ImagemReceitaController extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private transient ImagemReceitaStorage storage;

    @Override
    public void init() throws ServletException {
        try {
            storage = new ImagemReceitaStorage();
            Files.createDirectories(storage.getRaiz());
        } catch (IOException | RuntimeException e) {
            throw new ServletException("Não foi possível preparar o diretório de imagens de receitas.", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String caminho = request.getPathInfo();
        if (caminho == null || caminho.length() < 2 || caminho.indexOf('/', 1) >= 0) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Imagem inválida.");
            return;
        }

        final Path arquivo;
        final String nome = caminho.substring(1);
        try {
            arquivo = storage.localizar(nome);
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Imagem inválida.");
            return;
        }
        if (!Files.isRegularFile(arquivo)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Imagem não encontrada.");
            return;
        }

        response.setContentType(storage.contentType(nome));
        response.setContentLengthLong(Files.size(arquivo));
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Cache-Control", "private, max-age=86400");
        Files.copy(arquivo, response.getOutputStream());
    }
}
