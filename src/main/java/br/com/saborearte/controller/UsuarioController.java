package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import br.com.saborearte.dao.UsuarioDAO;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.StatusUsuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;

@WebServlet("/UsuarioController")
public class UsuarioController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private Connection conexao;
    private UsuarioDAO usuarioDAO;

    @Override
    public void init() {
        try {
            conexao = Conexao.getConnection();
            usuarioDAO = new UsuarioDAO(conexao);
            System.out.println("UsuarioController iniciado com sucesso");
        } catch (Exception e) {
            throw new RuntimeException("Erro ao iniciar UsuarioController", e);
        }
    }

    // ===== GET — lista usuários (só para Admin) =====

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Segurança: só Admin acessa a listagem
        if (!isAdmin(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        // PRG: resgata mensagens da sessão e remove logo em seguida
        String sucesso = (String) session.getAttribute("sucesso");
        String erro    = (String) session.getAttribute("erro");
        if (sucesso != null) { request.setAttribute("msgSucesso", sucesso); session.removeAttribute("sucesso"); }
        if (erro    != null) { request.setAttribute("msgErro",    erro);    session.removeAttribute("erro");    }

        try {
            List<Usuario> usuarios = usuarioDAO.listarUsuarios();
            request.setAttribute("usuarios", usuarios);
            request.setAttribute("totalUsuarios", usuarios.size());
            request.getRequestDispatcher("/pages/usuarios.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao carregar usuários: " + e.getMessage());
            request.getRequestDispatcher("/pages/usuarios.jsp").forward(request, response);
        }
    }

    // ===== POST — recebe acao e direciona =====

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String acao = request.getParameter("action");

        try {
            switch (acao != null ? acao : "") {
            case "cadastrar"      -> cadastrar(request, response);       // público (tela de login)
            case "cadastrarAdmin" -> cadastrarAdmin(request, response);  // painel admin                
            case "atualizar"  -> atualizar(request, response);   // painel admin
                case "status"    -> alterarStatus(request, response);     // painel admin
                case "foto" -> salvarFoto(request, response); // painel admin
                default           -> response.sendRedirect(request.getContextPath() + "/LoginController");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.getSession().setAttribute("erro", "Erro inesperado: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/UsuarioController");
        }
    }

    // ===== AÇÃO: CADASTRAR (público — vem do modal da tela de login) =====
private void cadastrar(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

    String nome  = request.getParameter("nome");
    String email = request.getParameter("email");
    String senha = request.getParameter("senha");
    String role  = request.getParameter("role");

    String emailRegex = "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$";

    if (nome == null || nome.trim().isEmpty() ||
        email == null || email.trim().isEmpty() ||
        senha == null || senha.trim().isEmpty()) {
        request.getSession().setAttribute("erro", "Preencha todos os campos.");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    // Rota pública: só aceita AUTOR ou VISITANTE. Qualquer outro valor
    // (ou ausência dele) cai em VISITANTE — nunca deixa escolher ADMIN/EDITOR por aqui.
    TipoUsuario tipoEscolhido;
    if ("author".equalsIgnoreCase(role)) {
        tipoEscolhido = TipoUsuario.AUTOR;
    } else if ("viewer".equalsIgnoreCase(role)) {
        tipoEscolhido = TipoUsuario.VISITANTE;
    } else {
        request.getSession().setAttribute("erro", "Escolha se deseja se cadastrar como Autor ou Visitante.");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    if (!email.trim().matches(emailRegex)) {
        request.getSession().setAttribute("erro", "E-mail inválido. Use um formato válido como usuario@dominio.com");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    if (senha.length() < 8) {
        request.getSession().setAttribute("erro", "A senha deve ter no mínimo 8 caracteres.");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    if (usuarioDAO.emailJaExiste(email.trim())) {
        request.getSession().setAttribute("erro", "Este e-mail já está cadastrado.");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    Usuario novo = new Usuario();
    novo.setNome_usuario(nome.trim());
    novo.setEmail_usuario(email.trim());
    novo.setSenha_usuario(senha);
    novo.setTipo_usuario(tipoEscolhido);

    usuarioDAO.cadastrarUsuario(novo);

    HttpSession session = request.getSession(true);
    session.setAttribute("sucesso", "Conta criada! Faça login para continuar.");
    response.sendRedirect(request.getContextPath() + "/LoginController");
}    
    // ===== AÇÃO: CADASTRAR ADMIN(Painel admin) =====

private void cadastrarAdmin(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

    System.out.println("========== INICIO CADASTRAR ADMIN ==========");

    HttpSession session = request.getSession(false);
    if (!isAdmin(session)) {
        System.out.println(">>> BLOQUEADO: sessão não é admin");
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    String nome  = request.getParameter("nome");
    String email = request.getParameter("email");
    String senha = request.getParameter("senha");
    String role  = request.getParameter("role");

    System.out.println("nome=[" + nome + "] email=[" + email + "] senha=[" + senha + "] role=[" + role + "]");

    if (nome == null || nome.trim().isEmpty() ||
        email == null || email.trim().isEmpty() ||
        senha == null || senha.trim().isEmpty()) {
        System.out.println(">>> FALHOU: campo vazio");
        session.setAttribute("erro", "Preencha todos os campos.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    String emailRegex = "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$";
    if (!email.trim().matches(emailRegex)) {
        System.out.println(">>> FALHOU: e-mail não bate com regex");
        session.setAttribute("erro", "E-mail inválido.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    if (senha.length() < 8) {
        System.out.println(">>> FALHOU: senha curta, tamanho=" + senha.length());
        session.setAttribute("erro", "A senha deve ter no mínimo 8 caracteres.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    boolean existe = usuarioDAO.emailJaExiste(email.trim());
    System.out.println("emailJaExiste retornou: " + existe);

    if (existe) {
        System.out.println(">>> FALHOU: e-mail já cadastrado. Setando 'erro' na sessão e redirecionando.");
        session.setAttribute("erro", "Este e-mail já está cadastrado.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    System.out.println(">>> Passou em tudo. Chamando cadastrarUsuario...");

    Usuario novo = new Usuario();
    novo.setNome_usuario(nome.trim());
    novo.setEmail_usuario(email.trim());
    novo.setSenha_usuario(senha);
    if (role != null && !role.isEmpty()) {
        String tipoEnum = "author".equals(role) ? "AUTOR"
                        : "viewer".equals(role) ? "VISITANTE"
                        : role.toUpperCase();
        novo.setTipo_usuario(TipoUsuario.valueOf(tipoEnum));
    }

    usuarioDAO.cadastrarUsuario(novo);
    System.out.println(">>> cadastrarUsuario executado sem exceção.");

    session.setAttribute("sucesso", "Usuário criado com sucesso!");
    response.sendRedirect(request.getContextPath() + "/UsuarioController");

    System.out.println("========== FIM CADASTRAR ADMIN ==========");
}    
    // ===== AÇÃO: ATUALIZAR (painel admin) =====

private void atualizar(HttpServletRequest request, HttpServletResponse response)
        throws Exception {

    HttpSession session = request.getSession(false);
    if (!isAdmin(session)) {
        response.sendRedirect(request.getContextPath() + "/LoginController");
        return;
    }

    int    id     = Integer.parseInt(request.getParameter("id"));
    String nome   = request.getParameter("nome");
    String email  = request.getParameter("email");
    String tipo   = request.getParameter("role");
    String status = request.getParameter("status_usuario");
    String senha  = request.getParameter("novaSenha");
    String fotoBase64 = request.getParameter("fotoBase64"); // NOVO

    Usuario usuario = usuarioDAO.buscarUsuarioPorId(id);
    if (usuario == null) {
        request.getSession().setAttribute("erro", "Usuário não encontrado.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    if (usuarioDAO.emailJaExiste(email.trim(), id)) {
        request.getSession().setAttribute("erro", "Este e-mail já está em uso por outro usuário.");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
        return;
    }

    usuario.setNome_usuario(nome.trim());
    usuario.setEmail_usuario(email.trim());
    if (tipo != null && !tipo.trim().isEmpty()) {
        usuario.setTipo_usuario(TipoUsuario.valueOf(tipo.toUpperCase()));
    }
    if (status != null && !status.trim().isEmpty()) {
        usuario.setStatus_usuario(StatusUsuario.valueOf(status.toUpperCase()));
    }
    if (senha != null && !senha.trim().isEmpty()) {
        usuario.setSenha_usuario(senha);
    }

    // NOVO: processa foto se veio no request
    if (fotoBase64 != null && !fotoBase64.isEmpty()) {
        String nomeArquivo = "avatar_" + id + ".jpg";
        String pastaRelativa = "/uploads/avatares/";
        String pastaAbsoluta = getServletContext().getRealPath(pastaRelativa);

        java.io.File pasta = new java.io.File(pastaAbsoluta);
        if (!pasta.exists()) pasta.mkdirs();

        String dadosBase64 = fotoBase64.replaceAll("^data:image/[a-z]+;base64,", "");
        byte[] bytes = java.util.Base64.getDecoder().decode(dadosBase64);
        java.nio.file.Files.write(java.nio.file.Paths.get(pastaAbsoluta + nomeArquivo), bytes);

        usuario.setFoto_usuario(pastaRelativa + nomeArquivo); // confere o nome do setter no seu model
    }

    usuarioDAO.atualizarUsuario(usuario);

    // Atualiza sessão se o admin editou a própria conta
    Usuario logadoAtual = (Usuario) session.getAttribute("usuarioLogado");
    if (logadoAtual != null && logadoAtual.getId_usuario() == id) {
        session.setAttribute("usuarioLogado", usuario);
    }

    request.getSession().setAttribute("sucesso", "Usuário atualizado com sucesso!");
    response.sendRedirect(request.getContextPath() + "/UsuarioController");
}
    
    private void salvarFoto(HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        HttpSession session = request.getSession(false);
        if (!isAdmin(session)) {
            response.sendRedirect(request.getContextPath() + "/LoginController");
            return;
        }

        int id = Integer.parseInt(request.getParameter("id"));
        String base64 = request.getParameter("fotoBase64"); // vem do JS

        if (base64 == null || base64.isEmpty()) {
            session.setAttribute("erro", "Nenhuma imagem recebida.");
            response.sendRedirect(request.getContextPath() + "/UsuarioController");
            return;
        }

        // Salva o base64 direto no banco (varchar 255 é CURTO para base64!)
        // Uma imagem 96x96 já passa de 255 chars. Recomendo salvar o arquivo em disco.
        // Opção A: salvar em disco e guardar só o caminho
        String nomeArquivo = "avatar_" + id + ".jpg";
        String pastaRelativa = "/uploads/avatares/";
        String pastaAbsoluta = getServletContext().getRealPath(pastaRelativa);

        // cria a pasta se não existir
        java.io.File pasta = new java.io.File(pastaAbsoluta);
        if (!pasta.exists()) pasta.mkdirs();

        // decodifica o base64 e salva o arquivo
        String dadosBase64 = base64.replaceAll("^data:image/[a-z]+;base64,", "");
        byte[] bytes = java.util.Base64.getDecoder().decode(dadosBase64);
        java.nio.file.Files.write(
            java.nio.file.Paths.get(pastaAbsoluta + nomeArquivo),
            bytes
        );

        // salva só o caminho relativo no banco (cabe no varchar 255)
        usuarioDAO.atualizarFotoUsuario(id, pastaRelativa + nomeArquivo);

        Usuario usuarioAtualizado = usuarioDAO.buscarUsuarioPorId(id);
        Usuario logadoAtual = (Usuario) session.getAttribute("usuarioLogado");
        if (logadoAtual != null && logadoAtual.getId_usuario() == id) {
            session.setAttribute("usuarioLogado", usuarioAtualizado);
        }
        
        session.setAttribute("sucesso", "Foto atualizada com sucesso!");
        response.sendRedirect(request.getContextPath() + "/UsuarioController");
    }
    
    private void alterarStatus(HttpServletRequest request,
            HttpServletResponse response)
throws Exception {

HttpSession session = request.getSession(false);

if (!isAdmin(session)) {
response.sendRedirect(request.getContextPath() + "/LoginController");
return;
}

int id = Integer.parseInt(request.getParameter("id"));

// ← PROTEÇÃO: impede admin de se auto-desativar
Usuario logado = (Usuario) session.getAttribute("usuarioLogado");
if (logado != null && logado.getId_usuario() == id) {
    session.setAttribute("erro", "Você não pode alterar o status da sua própria conta.");
    response.sendRedirect(request.getContextPath() + "/UsuarioController");
    return;
}

String novoStatus =
request.getParameter("novoStatus");

Usuario usuario =
usuarioDAO.buscarUsuarioPorId(id);

if (usuario == null) {
session.setAttribute(
 "erro",
 "Usuário não encontrado."
);

response.sendRedirect(
 request.getContextPath()
 + "/UsuarioController"
);
return;
}

usuario.setStatus_usuario(
StatusUsuario.valueOf(
     novoStatus.toUpperCase()
)
);

usuarioDAO.atualizarUsuario(usuario);

session.setAttribute(
"sucesso",
"Status atualizado com sucesso!"
);

response.sendRedirect(
request.getContextPath()
+ "/UsuarioController"
);
}
    // ===== UTILITÁRIO: verifica se o usuário logado é Admin =====

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        Usuario u = (Usuario) session.getAttribute("usuarioLogado");
        return u != null && u.getTipo_usuario() == TipoUsuario.ADMIN;
    }
}