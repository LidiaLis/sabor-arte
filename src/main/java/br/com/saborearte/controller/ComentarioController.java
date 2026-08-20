package br.com.saborearte.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import br.com.saborearte.dao.ComentarioDAO;
import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Comentario.StatusComentario;
import br.com.saborearte.model.Usuario;
import br.com.saborearte.model.Usuario.StatusUsuario;
import br.com.saborearte.model.Usuario.TipoUsuario;
import br.com.saborearte.utils.Conexao;
import br.com.saborearte.utils.LogUtil;

/** Porta única de comentários. Cada requisição possui sua própria conexão. */
@WebServlet(urlPatterns = {"/ComentarioController", "/comentarios-moderacao", "/mensagens-autor", "/comentarios"})
public class ComentarioController extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final String MODERACAO = "moderacao";
    private static final String MENSAGENS = "mensagens";
    private static final String ROTA_MODERACAO = "/ComentarioController?view=moderacao";
    private static final String ROTA_MENSAGENS = "/ComentarioController?view=mensagens";

    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Usuario usuario = usuarioLogado(session);
        if (!sessaoAtiva(usuario)) { login(request, response); return; }
        transferirFlash(session, request);
        try (Connection conexao = abrirConexao()) {
            ComentarioDAO dao = new ComentarioDAO(conexao);
            if (!dao.usuarioAtivoNoPerfil(usuario.getId_usuario())) {
                session.removeAttribute("usuarioLogado"); login(request, response); return;
            }
            String view = resolverView(request, usuario);
            if (MENSAGENS.equals(view)) {
                if (!dao.usuarioAtivoNoPerfil(usuario.getId_usuario(), TipoUsuario.AUTOR.name())) { negar(response); return; }
                carregarMensagens(request, response, usuario.getId_usuario(), dao);
            } else if (MODERACAO.equals(view)) {
                if (!dao.usuarioAtivoNoPerfil(usuario.getId_usuario(), TipoUsuario.EDITOR.name(), TipoUsuario.ADMIN.name())) { negar(response); return; }
                carregarModeracao(request, response, dao);
            } else response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Visão inválida.");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (Exception e) { throw new ServletException("Erro ao carregar comentários.", e); }
    }

    private String resolverView(HttpServletRequest request, Usuario usuario) {
        String view = normalizar(request.getParameter("view"));
        if (view != null) return view;
        String uri = request.getRequestURI();
        if (uri != null && uri.endsWith("/mensagens-autor")) return MENSAGENS;
        if (uri != null && (uri.endsWith("/comentarios-moderacao") || uri.endsWith("/comentarios"))) return MODERACAO;
        return usuario.getTipo_usuario() == TipoUsuario.AUTOR ? MENSAGENS : MODERACAO;
    }

    private void carregarMensagens(HttpServletRequest request, HttpServletResponse response, int autorId,
            ComentarioDAO dao) throws Exception {
        String busca = normalizar(request.getParameter("busca"));
        String statusResposta = normalizarStatusResposta(request.getParameter("statusResposta"));
        int size = limitar(request.getParameter("size"), 10, 1, 100);
        int page = limitar(request.getParameter("page"), 1, 1, Integer.MAX_VALUE);
        int total = dao.contarComentariosPorAutor(autorId, busca, statusResposta);
        int totalPages = Math.max(1, (total + size - 1) / size);
        page = Math.min(page, totalPages);
        int offset = (page - 1) * size;
        List<Comentario> comentarios = dao.listarComentariosPorAutor(autorId, busca, statusResposta, size, offset);
        request.setAttribute("comentarios", comentarios);
        request.setAttribute("page", Integer.valueOf(page)); request.setAttribute("size", Integer.valueOf(size));
        request.setAttribute("total", Integer.valueOf(total)); request.setAttribute("totalPages", Integer.valueOf(totalPages));
        request.setAttribute("totalRecebidos", Integer.valueOf(dao.contarComentariosPorAutor(autorId, null, null)));
        request.setAttribute("totalPendentesResposta", Integer.valueOf(dao.contarRespostasPorAutor(autorId, false)));
        request.setAttribute("totalRespondidos", Integer.valueOf(dao.contarRespostasPorAutor(autorId, true)));
        request.setAttribute("avaliacaoMedia", Double.valueOf(dao.calcularAvaliacaoMediaPorAutor(autorId)));
        request.setAttribute("busca", busca); request.setAttribute("statusResposta", statusResposta);
        request.getRequestDispatcher("/pages/mensagens-autor.jsp").forward(request, response);
    }

    private void carregarModeracao(HttpServletRequest request, HttpServletResponse response, ComentarioDAO dao)
            throws Exception {
        String filtro = normalizar(request.getParameter("filtro"));
        String statusFiltro = normalizarStatusComentario(request.getParameter("statusFiltro"));
        String dataFiltro = normalizarData(request.getParameter("dataFiltro"));
        int size = limitar(request.getParameter("size"), 10, 1, 100);
        int page = limitar(request.getParameter("page"), 1, 1, Integer.MAX_VALUE);
        int total = dao.contarComentariosModeracao(filtro, statusFiltro, dataFiltro);
        int totalPages = Math.max(1, (total + size - 1) / size);
        page = Math.min(page, totalPages);
        int offset = (page - 1) * size;
        request.setAttribute("comentarios", dao.listarComentariosModeracao(filtro, statusFiltro, dataFiltro, size, offset));
        request.setAttribute("page", Integer.valueOf(page)); request.setAttribute("size", Integer.valueOf(size));
        request.setAttribute("total", Integer.valueOf(total)); request.setAttribute("totalPages", Integer.valueOf(totalPages));
        request.setAttribute("totalPendentes", Integer.valueOf(dao.contarPorStatus(StatusComentario.PENDENTE)));
        request.setAttribute("totalAprovados", Integer.valueOf(dao.contarPorStatus(StatusComentario.APROVADO)));
        request.setAttribute("totalRejeitados", Integer.valueOf(dao.contarPorStatus(StatusComentario.REJEITADO)));
        request.setAttribute("totalComentarios", Integer.valueOf(dao.contarComentarios()));
        request.setAttribute("filtro", filtro); request.setAttribute("statusFiltro", statusFiltro);
        request.setAttribute("dataFiltro", dataFiltro);
        request.getRequestDispatcher("/pages/comentarios.jsp").forward(request, response);
    }

    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        Usuario usuario = usuarioLogado(session);
        if (!sessaoAtiva(usuario)) { login(request, response); return; }
        String action = normalizar(request.getParameter("action"));
        try (Connection conexao = abrirConexao()) {
            ComentarioDAO dao = new ComentarioDAO(conexao);
            if (!dao.usuarioAtivoNoPerfil(usuario.getId_usuario())) {
                session.removeAttribute("usuarioLogado"); login(request, response); return;
            }
            String[] perfis = perfisDaAcao(action);
            if (!dao.usuarioAtivoNoPerfil(usuario.getId_usuario(), perfis)) { negar(response); return; }
            conexao.setAutoCommit(false);
            try {
                ResultadoMutacao resultado = executarMutacao(request, usuario, action, dao);
                registrarAuditoriaObrigatoria(conexao, request, resultado.acaoLog, resultado.entidadeLog, resultado.detalhesLog);
                conexao.commit();
                flash(request, "sucesso", resultado.mensagem);
                response.sendRedirect(request.getContextPath() + resultado.rota);
            } catch (IllegalArgumentException e) {
                conexao.rollback(); flash(request, "erro", e.getMessage());
                redirecionarFalha(request, response, action);
            } catch (Exception e) {
                conexao.rollback(); throw e;
            } finally { conexao.setAutoCommit(true); }
        } catch (IllegalArgumentException e) {
            flash(request, "erro", e.getMessage()); redirecionarFalha(request, response, action);
        } catch (Exception e) { throw new ServletException("Erro ao processar comentário.", e); }
    }

    private String[] perfisDaAcao(String action) {
        if ("comentar".equals(action)) return new String[] {TipoUsuario.VISITANTE.name()};
        if ("responder".equals(action) || "denunciar".equals(action)) return new String[] {TipoUsuario.AUTOR.name()};
        if ("manter".equals(action) || "aprovar".equals(action) || "rejeitar".equals(action)
                || "remover".equals(action) || "inativarUsuario".equals(action))
            return new String[] {TipoUsuario.EDITOR.name(), TipoUsuario.ADMIN.name()};
        throw new IllegalArgumentException("Ação inválida.");
    }

    private ResultadoMutacao executarMutacao(HttpServletRequest request, Usuario usuario, String action,
            ComentarioDAO dao) throws Exception {
        if ("comentar".equals(action)) {
            int idReceita = inteiroObrigatorio(request.getParameter("idReceita"), "Receita inválida.");
            String conteudo = textoObrigatorio(request.getParameter("conteudo"), "O comentário não pode ficar vazio.", 2000);
            int avaliacao = inteiroObrigatorio(request.getParameter("avaliacao"), "Avaliação inválida.");
            if (avaliacao < 1 || avaliacao > 5) throw new IllegalArgumentException("A avaliação deve estar entre 1 e 5.");
            Comentario c = new Comentario(); c.setReceita(idReceita); c.setUsuario(usuario.getId_usuario());
            c.setTexto_comentario(conteudo); c.setAvaliacao_comentario(avaliacao); c.setStatus_comentario(StatusComentario.PENDENTE);
            if (!dao.cadastrarEmReceitaPublicadaAtiva(c))
                throw new IllegalArgumentException("Comentários são permitidos somente em receitas publicadas e ativas.");
            return new ResultadoMutacao("Comentário enviado para moderação.",
                    "/ReceitaController?action=detalhar&idReceita=" + idReceita,
                    "COMENTAR", "COMENTARIO", "Comentário criado na receita #" + idReceita);
        }
        int idComentario = inteiroObrigatorio(request.getParameter("idComentario"), "Comentário inválido.");
        if ("responder".equals(action)) {
            String resposta = textoObrigatorio(request.getParameter("resposta"), "A resposta não pode ficar vazia.", 2000);
            if (!dao.responderComentarioDoAutor(idComentario, usuario.getId_usuario(), resposta))
                throw new IllegalArgumentException("Comentário inexistente ou pertencente a outra autoria.");
            return new ResultadoMutacao("Resposta publicada.", ROTA_MENSAGENS,
                    "RESPONDER_COMENTARIO", "COMENTARIO", "Resposta no comentário #" + idComentario);
        }
        if ("denunciar".equals(action)) {
            if (!dao.denunciarComentarioDoAutor(idComentario, usuario.getId_usuario()))
                throw new IllegalArgumentException("Comentário inexistente ou pertencente a outra autoria.");
            return new ResultadoMutacao("Comentário enviado para moderação.", ROTA_MENSAGENS,
                    "MODERAR_COMENTARIO", "COMENTARIO", "Comentário #" + idComentario + " denunciado");
        }
        boolean alterado;
        if ("manter".equals(action) || "aprovar".equals(action))
            alterado = dao.moderarComentario(idComentario, usuario.getId_usuario(), StatusComentario.APROVADO);
        else if ("rejeitar".equals(action))
            alterado = dao.moderarComentario(idComentario, usuario.getId_usuario(), StatusComentario.REJEITADO);
        else if ("remover".equals(action))
            alterado = dao.moderarComentario(idComentario, usuario.getId_usuario(), StatusComentario.REMOVIDO);
        else alterado = dao.inativarUsuarioPorComentario(idComentario, usuario.getId_usuario());
        if (!alterado) throw new IllegalArgumentException("Comentário inexistente ou ação não permitida.");
        return new ResultadoMutacao("Moderação registrada.", ROTA_MODERACAO,
                "MODERAR_COMENTARIO", "COMENTARIO", "Ação " + action + " no comentário #" + idComentario);
    }

    private void registrarAuditoriaObrigatoria(Connection conexao, HttpServletRequest request,
            String acao, String entidade, String detalhes) throws Exception {
        Usuario usuario = usuarioLogado(request.getSession(false));
        if (usuario == null) throw new IllegalStateException("Sessão ausente durante auditoria.");
        int antes = contarAuditoria(conexao, usuario.getId_usuario(), acao, entidade, detalhes);
        registrarLog(conexao, request, acao, entidade, detalhes);
        int depois = contarAuditoria(conexao, usuario.getId_usuario(), acao, entidade, detalhes);
        if (depois != antes + 1) throw new IllegalStateException("Falha ao registrar auditoria.");
    }

    protected void registrarLog(Connection conexao, HttpServletRequest request,
            String acao, String entidade, String detalhes) throws SQLException {
        LogUtil.registrar(conexao, request, acao, entidade, detalhes);
    }

    private int contarAuditoria(Connection conexao, int usuario, String acao, String entidade, String detalhes)
            throws Exception {
        String sql = "SELECT COUNT(*) FROM log WHERE usuario=? AND acao_log=? AND entidade_log=? AND descricao_log=?";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, usuario); ps.setString(2, acao); ps.setString(3, entidade); ps.setString(4, detalhes);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }

    private void redirecionarFalha(HttpServletRequest request, HttpServletResponse response, String action) throws IOException {
        if ("comentar".equals(action)) {
            int id = limitar(request.getParameter("idReceita"), 0, 0, Integer.MAX_VALUE);
            response.sendRedirect(request.getContextPath() + (id > 0
                    ? "/ReceitaController?action=detalhar&idReceita=" + id : "/ReceitaController"));
        } else if ("responder".equals(action) || "denunciar".equals(action))
            response.sendRedirect(request.getContextPath() + ROTA_MENSAGENS);
        else response.sendRedirect(request.getContextPath() + ROTA_MODERACAO);
    }

    private void transferirFlash(HttpSession s, HttpServletRequest r) {
        if (s == null) return; for (String n : new String[] {"sucesso", "erro"}) {
            Object v=s.getAttribute(n); if(v!=null){r.setAttribute(n,v);s.removeAttribute(n);} }
    }
    protected Connection abrirConexao() throws Exception { return Conexao.getConnection(); }
    private void flash(HttpServletRequest r,String n,String m){r.getSession(true).setAttribute(n,m);}
    private Usuario usuarioLogado(HttpSession s){return s==null?null:(Usuario)s.getAttribute("usuarioLogado");}
    private boolean sessaoAtiva(Usuario u){return u!=null&&u.getStatus_usuario()==StatusUsuario.ATIVO;}
    private void login(HttpServletRequest r,HttpServletResponse p)throws IOException{p.sendRedirect(r.getContextPath()+"/LoginController");}
    private void negar(HttpServletResponse p)throws IOException{p.sendError(HttpServletResponse.SC_FORBIDDEN,"Perfil sem permissão.");}
    private String normalizar(String v){return v==null||v.isBlank()?null:v.trim();}
    private String normalizarStatusResposta(String v){String n=normalizar(v);if(n==null||"todos".equalsIgnoreCase(n))return null;
        if("pendente".equalsIgnoreCase(n)||"respondido".equalsIgnoreCase(n))return n.toLowerCase();throw new IllegalArgumentException("Filtro de resposta inválido.");}
    private String normalizarStatusComentario(String v){String n=normalizar(v);if(n==null||"todos".equalsIgnoreCase(n))return null;
        try{return StatusComentario.valueOf(n.toUpperCase()).name();}catch(Exception e){throw new IllegalArgumentException("Status inválido.");}}
    private String normalizarData(String v){String n=normalizar(v);if(n==null)return null;try{return LocalDate.parse(n).toString();}
        catch(DateTimeParseException e){throw new IllegalArgumentException("Data inválida.");}}
    private String textoObrigatorio(String v,String msg,int max){String n=normalizar(v);if(n==null)throw new IllegalArgumentException(msg);
        if(n.length()>max)throw new IllegalArgumentException("Texto excede "+max+" caracteres.");return n;}
    private int inteiroObrigatorio(String v,String msg){int n=limitar(v,-1,Integer.MIN_VALUE,Integer.MAX_VALUE);
        if(n<1)throw new IllegalArgumentException(msg);return n;}
    private int limitar(String v,int padrao,int min,int max){try{return Math.max(min,Math.min(max,Integer.parseInt(v)));}catch(Exception e){return padrao;}}

    private static final class ResultadoMutacao {
        final String mensagem, rota, acaoLog, entidadeLog, detalhesLog;
        ResultadoMutacao(String m,String r,String a,String e,String d){mensagem=m;rota=r;acaoLog=a;entidadeLog=e;detalhesLog=d;}
    }
}
