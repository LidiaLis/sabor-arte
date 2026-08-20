package br.com.saborearte.service;

import java.io.ByteArrayInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Base64;

public final class ImagemReceitaStorageTest {

    private int executados;

    public static void main(String[] args) throws Exception {
        ImagemReceitaStorageTest teste = new ImagemReceitaStorageTest();
        teste.salvaPngRealComNomeSeguroERotaPublica();
        teste.detectaJpegEWebpPelaAssinatura();
        teste.rejeitaMimeQueNaoCorrespondeAoConteudo();
        teste.rejeitaArquivoMaiorQueCincoMib();
        teste.rejeitaConteudoQueNaoEhImagem();
        teste.rejeitaPrefixosValidosComEstruturaCorrompida();
        teste.impedeAcessoForaDaPastaDeUploads();
        System.out.println("ImagemReceitaStorageTest: " + teste.executados + " testes aprovados");
    }

    private void salvaPngRealComNomeSeguroERotaPublica() throws Exception {
        Path raiz = Files.createTempDirectory("sabor-arte-png-");
        ImagemReceitaStorage storage = new ImagemReceitaStorage(raiz);
        byte[] png = bytesPng();

        String rota = storage.salvar(new ByteArrayInputStream(png), "image/png", png.length);

        assertTrue(rota.matches("/uploads/receitas/[0-9a-f-]{36}\\.png"), "rota PNG segura");
        String nome = rota.substring(rota.lastIndexOf('/') + 1);
        assertArrayEquals(png, Files.readAllBytes(storage.localizar(nome)), "conteúdo PNG persistido");
        assertEquals("image/png", storage.contentType(nome), "content type PNG");
        executados++;
    }

    private void detectaJpegEWebpPelaAssinatura() throws Exception {
        Path raiz = Files.createTempDirectory("sabor-arte-formatos-");
        ImagemReceitaStorage storage = new ImagemReceitaStorage(raiz);
        byte[] jpeg = bytesJpeg();
        byte[] webp = bytesWebp();

        String rotaJpeg = storage.salvar(new ByteArrayInputStream(jpeg), "image/jpeg", jpeg.length);
        String rotaWebp = storage.salvar(new ByteArrayInputStream(webp), "image/webp", webp.length);

        assertTrue(rotaJpeg.endsWith(".jpg"), "extensão JPG derivada do conteúdo");
        assertTrue(rotaWebp.endsWith(".webp"), "extensão WebP derivada do conteúdo");
        executados++;
    }

    private void rejeitaMimeQueNaoCorrespondeAoConteudo() throws Exception {
        ImagemReceitaStorage storage = new ImagemReceitaStorage(Files.createTempDirectory("sabor-arte-mime-"));
        assertThrows(() -> storage.salvar(new ByteArrayInputStream(bytesPng()), "image/jpeg", bytesPng().length),
                "Tipo do arquivo não corresponde ao conteúdo da imagem.");
        executados++;
    }

    private void rejeitaArquivoMaiorQueCincoMib() throws Exception {
        ImagemReceitaStorage storage = new ImagemReceitaStorage(Files.createTempDirectory("sabor-arte-limite-"));
        assertThrows(() -> storage.salvar(new ByteArrayInputStream(bytesPng()), "image/png",
                ImagemReceitaStorage.TAMANHO_MAXIMO + 1), "A imagem deve ter no máximo 5 MB.");
        executados++;
    }

    private void rejeitaConteudoQueNaoEhImagem() throws Exception {
        ImagemReceitaStorage storage = new ImagemReceitaStorage(Files.createTempDirectory("sabor-arte-falso-"));
        byte[] texto = "isto nao e uma imagem".getBytes(java.nio.charset.StandardCharsets.UTF_8);
        assertThrows(() -> storage.salvar(new ByteArrayInputStream(texto), "image/png", texto.length),
                "O arquivo enviado não é uma imagem JPG, PNG ou WebP válida.");
        executados++;
    }

    private void rejeitaPrefixosValidosComEstruturaCorrompida() throws Exception {
        ImagemReceitaStorage storage = new ImagemReceitaStorage(Files.createTempDirectory("sabor-arte-corrompida-"));
        byte[] pngTruncado = Arrays.copyOf(bytesPng(), 12);
        byte[] jpegFalso = new byte[] {(byte) 0xff, (byte) 0xd8, (byte) 0xff, 1, 2, 3, 4};
        byte[] webpFalso = new byte[] {'R','I','F','F',4,0,0,0,'W','E','B','P','V','P','8',' '};
        String mensagem = "O arquivo enviado não é uma imagem JPG, PNG ou WebP válida.";

        assertThrows(() -> storage.salvar(new ByteArrayInputStream(pngTruncado), "image/png", pngTruncado.length), mensagem);
        assertThrows(() -> storage.salvar(new ByteArrayInputStream(jpegFalso), "image/jpeg", jpegFalso.length), mensagem);
        assertThrows(() -> storage.salvar(new ByteArrayInputStream(webpFalso), "image/webp", webpFalso.length), mensagem);
        executados++;
    }

    private void impedeAcessoForaDaPastaDeUploads() throws Exception {
        ImagemReceitaStorage storage = new ImagemReceitaStorage(Files.createTempDirectory("sabor-arte-path-"));
        assertThrows(() -> storage.localizar("../segredo.txt"), "Nome de imagem inválido.");
        executados++;
    }

    private static byte[] bytesPng() {
        return Base64.getDecoder().decode(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");
    }

    private static byte[] bytesJpeg() throws Exception {
        java.awt.image.BufferedImage imagem = new java.awt.image.BufferedImage(1, 1,
                java.awt.image.BufferedImage.TYPE_INT_RGB);
        java.io.ByteArrayOutputStream saida = new java.io.ByteArrayOutputStream();
        if (!javax.imageio.ImageIO.write(imagem, "jpeg", saida)) {
            throw new AssertionError("JDK sem gravador JPEG");
        }
        return saida.toByteArray();
    }

    private static byte[] bytesWebp() {
        return Base64.getDecoder().decode(
                "UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA");
    }

    private static void assertEquals(Object esperado, Object atual, String mensagem) {
        if (!java.util.Objects.equals(esperado, atual)) {
            throw new AssertionError(mensagem + ": esperado=" + esperado + ", atual=" + atual);
        }
    }

    private static void assertArrayEquals(byte[] esperado, byte[] atual, String mensagem) {
        if (!Arrays.equals(esperado, atual)) throw new AssertionError(mensagem);
    }

    private static void assertTrue(boolean condicao, String mensagem) {
        if (!condicao) throw new AssertionError(mensagem);
    }

    private static void assertThrows(ThrowingRunnable acao, String mensagemEsperada) throws Exception {
        try {
            acao.run();
            throw new AssertionError("Era esperada IllegalArgumentException: " + mensagemEsperada);
        } catch (IllegalArgumentException e) {
            assertEquals(mensagemEsperada, e.getMessage(), "mensagem de validação");
        }
    }

    @FunctionalInterface
    private interface ThrowingRunnable {
        void run() throws Exception;
    }
}
