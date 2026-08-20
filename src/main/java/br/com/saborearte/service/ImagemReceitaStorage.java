package br.com.saborearte.service;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

/** Armazena imagens de receitas fora da pasta temporária do Tomcat. */
public final class ImagemReceitaStorage {

    public static final long TAMANHO_MAXIMO = 5L * 1024L * 1024L;
    private static final long PIXELS_MAXIMOS = 25_000_000L;
    private static final String PROPRIEDADE_DIRETORIO = "saborearte.upload.dir";
    private static final String ROTA_PUBLICA = "/uploads/receitas/";
    private static final Pattern NOME_SEGURO = Pattern.compile(
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(jpg|png|webp)");

    private final Path raiz;

    public ImagemReceitaStorage() {
        this(diretorioPadrao());
    }

    public ImagemReceitaStorage(Path raiz) {
        if (raiz == null) throw new IllegalArgumentException("Diretório de imagens obrigatório.");
        this.raiz = raiz.toAbsolutePath().normalize();
    }

    public String salvar(InputStream conteudo, String contentTypeDeclarado, long tamanhoDeclarado)
            throws IOException {
        if (conteudo == null) throw new IllegalArgumentException("Nenhuma imagem foi enviada.");
        if (tamanhoDeclarado > TAMANHO_MAXIMO) {
            throw new IllegalArgumentException("A imagem deve ter no máximo 5 MB.");
        }

        byte[] bytes = conteudo.readNBytes((int) TAMANHO_MAXIMO + 1);
        if (bytes.length > TAMANHO_MAXIMO) {
            throw new IllegalArgumentException("A imagem deve ter no máximo 5 MB.");
        }

        Formato formato = Formato.detectar(bytes);
        if (formato == null || !formato.validarEstrutura(bytes)) {
            throw new IllegalArgumentException("O arquivo enviado não é uma imagem JPG, PNG ou WebP válida.");
        }
        if (!formato.aceitaMime(contentTypeDeclarado)) {
            throw new IllegalArgumentException("Tipo do arquivo não corresponde ao conteúdo da imagem.");
        }

        Files.createDirectories(raiz);
        String nome = UUID.randomUUID() + "." + formato.extensao;
        Files.write(raiz.resolve(nome), bytes, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
        return ROTA_PUBLICA + nome;
    }

    public Path localizar(String nome) {
        if (nome == null || !NOME_SEGURO.matcher(nome).matches()) {
            throw new IllegalArgumentException("Nome de imagem inválido.");
        }
        Path arquivo = raiz.resolve(nome).normalize();
        if (!arquivo.startsWith(raiz)) {
            throw new IllegalArgumentException("Nome de imagem inválido.");
        }
        return arquivo;
    }

    public String contentType(String nome) {
        localizar(nome);
        if (nome.endsWith(".jpg")) return "image/jpeg";
        if (nome.endsWith(".png")) return "image/png";
        return "image/webp";
    }

    public Path getRaiz() {
        return raiz;
    }

    private static Path diretorioPadrao() {
        String configurado = System.getProperty(PROPRIEDADE_DIRETORIO);
        if (configurado != null && !configurado.isBlank()) return Path.of(configurado);
        return Path.of(System.getProperty("user.home"), ".sabor-arte", "uploads", "receitas");
    }

    private enum Formato {
        JPEG("jpg", "image/jpeg", "image/jpg"),
        PNG("png", "image/png"),
        WEBP("webp", "image/webp");

        private final String extensao;
        private final String[] mimes;

        Formato(String extensao, String... mimes) {
            this.extensao = extensao;
            this.mimes = mimes;
        }

        private boolean aceitaMime(String declarado) {
            if (declarado == null) return false;
            String mime = declarado.split(";", 2)[0].trim().toLowerCase(Locale.ROOT);
            for (String permitido : mimes) if (permitido.equals(mime)) return true;
            return false;
        }

        private static Formato detectar(byte[] b) {
            if (b.length >= 8
                    && (b[0] & 0xff) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G'
                    && b[4] == 13 && b[5] == 10 && b[6] == 26 && b[7] == 10) return PNG;
            if (b.length >= 3
                    && (b[0] & 0xff) == 0xff && (b[1] & 0xff) == 0xd8 && (b[2] & 0xff) == 0xff) return JPEG;
            if (b.length >= 12
                    && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                    && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return WEBP;
            return null;
        }

        private boolean validarEstrutura(byte[] bytes) {
            return this == WEBP ? webpEstruturalmenteValido(bytes) : imagemDecodificavel(bytes);
        }

        private static boolean imagemDecodificavel(byte[] bytes) {
            try (ImageInputStream entrada = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
                if (entrada == null) return false;
                java.util.Iterator<ImageReader> leitores = ImageIO.getImageReaders(entrada);
                if (!leitores.hasNext()) return false;
                ImageReader leitor = leitores.next();
                try {
                    leitor.setInput(entrada, true, true);
                    int largura = leitor.getWidth(0);
                    int altura = leitor.getHeight(0);
                    if (largura <= 0 || altura <= 0 || (long) largura * altura > PIXELS_MAXIMOS) return false;
                    return leitor.read(0) != null;
                } finally {
                    leitor.dispose();
                }
            } catch (IOException | RuntimeException e) {
                return false;
            }
        }

        private static boolean webpEstruturalmenteValido(byte[] b) {
            if (b.length < 30 || lerUInt32LE(b, 4) != b.length - 8L) return false;
            int offset = 12;
            boolean quadroEncontrado = false;
            while (offset + 8 <= b.length) {
                String tipo = new String(b, offset, 4, java.nio.charset.StandardCharsets.US_ASCII);
                long tamanho = lerUInt32LE(b, offset + 4);
                long inicioDados = offset + 8L;
                long fimDados = inicioDados + tamanho;
                if (fimDados > b.length || fimDados > Integer.MAX_VALUE) return false;
                int dados = (int) inicioDados;
                if ("VP8 ".equals(tipo)) {
                    if (tamanho < 10 || dados + 6 > b.length
                            || (b[dados + 3] & 0xff) != 0x9d
                            || (b[dados + 4] & 0xff) != 0x01
                            || (b[dados + 5] & 0xff) != 0x2a) return false;
                    quadroEncontrado = true;
                } else if ("VP8L".equals(tipo)) {
                    if (tamanho < 5 || dados >= b.length || (b[dados] & 0xff) != 0x2f) return false;
                    quadroEncontrado = true;
                } else if ("VP8X".equals(tipo) && tamanho != 10) {
                    return false;
                }
                offset = (int) fimDados + ((tamanho & 1L) == 1L ? 1 : 0);
                if (offset > b.length) return false;
            }
            return offset == b.length && quadroEncontrado;
        }

        private static long lerUInt32LE(byte[] b, int offset) {
            if (offset < 0 || offset + 4 > b.length) return -1;
            return (b[offset] & 0xffL)
                    | ((b[offset + 1] & 0xffL) << 8)
                    | ((b[offset + 2] & 0xffL) << 16)
                    | ((b[offset + 3] & 0xffL) << 24);
        }
    }
}
