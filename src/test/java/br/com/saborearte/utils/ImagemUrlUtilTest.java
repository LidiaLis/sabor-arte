package br.com.saborearte.utils;

public final class ImagemUrlUtilTest {

    public static void main(String[] args) {
        assertEquals("https://img.exemplo/bolo.jpg",
                ImagemUrlUtil.resolver("/saborearte", "https://img.exemplo/bolo.jpg"));
        assertEquals("data:image/png;base64,AA==",
                ImagemUrlUtil.resolver("/saborearte", "data:image/png;base64,AA=="));
        assertEquals("/saborearte/uploads/receitas/abc.png",
                ImagemUrlUtil.resolver("/saborearte", "/uploads/receitas/abc.png"));
        assertEquals("/saborearte/uploads/receitas/abc.png",
                ImagemUrlUtil.resolver("/saborearte", "uploads/receitas/abc.png"));
        assertEquals("/saborearte/uploads/receitas/abc.png",
                ImagemUrlUtil.resolver("/saborearte", "/saborearte/uploads/receitas/abc.png"));
        assertEquals(null, ImagemUrlUtil.resolver("/saborearte", "  "));
        assertEquals("https://img.exemplo/a.jpg&quot; onerror=&quot;alert(1)",
                ImagemUrlUtil.resolverParaAtributoHtml("/saborearte",
                        "https://img.exemplo/a.jpg\" onerror=\"alert(1)"));
        System.out.println("ImagemUrlUtilTest: 7 testes aprovados");
    }

    private static void assertEquals(Object esperado, Object atual) {
        if (!java.util.Objects.equals(esperado, atual)) {
            throw new AssertionError("esperado=" + esperado + ", atual=" + atual);
        }
    }
}
