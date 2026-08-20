package br.com.saborearte.utils;

/** Resolve imagens externas e caminhos locais armazenados no banco. */
public final class ImagemUrlUtil {

    private ImagemUrlUtil() {
    }

    public static String resolver(String contextPath, String valor) {
        if (valor == null || valor.isBlank()) return null;
        String imagem = valor.trim();
        if (imagem.startsWith("http://") || imagem.startsWith("https://") || imagem.startsWith("data:")) {
            return imagem;
        }

        String contexto = contextPath == null ? "" : contextPath.trim();
        if ("/".equals(contexto)) contexto = "";
        if (!contexto.isEmpty() && !contexto.startsWith("/")) contexto = "/" + contexto;
        if (contexto.endsWith("/")) contexto = contexto.substring(0, contexto.length() - 1);

        if (!contexto.isEmpty() && (imagem.equals(contexto) || imagem.startsWith(contexto + "/"))) {
            return imagem;
        }
        return contexto + (imagem.startsWith("/") ? imagem : "/" + imagem);
    }

    public static String resolverParaAtributoHtml(String contextPath, String valor) {
        String resolvida = resolver(contextPath, valor);
        if (resolvida == null) return null;
        return resolvida.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
