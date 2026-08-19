package br.com.saborearte.dao;

import br.com.saborearte.model.Comentario;
import br.com.saborearte.model.Comentario.StatusComentario;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.util.ArrayList;
import java.util.List;

/** Persistência de comentários com escopo explícito de receita e autoria. */
public class ComentarioDAO {
    private final Connection conexao;
    public ComentarioDAO(Connection conexao) { this.conexao = conexao; }

    private Comentario mapear(ResultSet rs) throws SQLException {
        Comentario c = new Comentario();
        c.setId_comentario(rs.getInt("id_comentario"));
        c.setReceita(rs.getInt("receita")); c.setUsuario(rs.getInt("usuario"));
        c.setTexto_comentario(rs.getString("texto_comentario"));
        c.setResposta_comentario(rs.getString("resposta_comentario"));
        c.setData_resposta_comentario(rs.getString("data_resposta_comentario"));
        c.setData_criacao_comentario(rs.getString("data_criacao_comentario"));
        c.setData_modera_comentario(rs.getString("data_modera_comentario"));
        c.setStatus_comentario(StatusComentario.valueOf(rs.getString("status_comentario")));
        c.setAvaliacao_comentario(rs.getInt("avaliacao_comentario"));
        return c;
    }

    private Comentario mapearComContexto(ResultSet rs) throws SQLException {
        Comentario c = mapear(rs);
        c.setNome_usuario(rs.getString("nome_usuario"));
        c.setFoto_usuario(rs.getString("foto_usuario"));
        c.setTitulo_receita(rs.getString("titulo_receita"));
        return c;
    }

    public int contarComentarios() throws SQLException {
        try (PreparedStatement ps = conexao.prepareStatement("SELECT COUNT(*) FROM comentario");
             ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
    }

    public int contarPorStatus(StatusComentario status) throws SQLException {
        try (PreparedStatement ps = conexao.prepareStatement(
                "SELECT COUNT(*) FROM comentario WHERE status_comentario=?")) {
            ps.setString(1, status.name());
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }

    public boolean usuarioAtivoNoPerfil(int idUsuario, String... perfis) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM usuario WHERE id_usuario=? AND status_usuario='ATIVO'");
        if (perfis != null && perfis.length > 0) {
            sql.append(" AND tipo_usuario IN (");
            for (int i = 0; i < perfis.length; i++) sql.append(i == 0 ? "?" : ",?");
            sql.append(")");
        }
        try (PreparedStatement ps = conexao.prepareStatement(sql.toString())) {
            ps.setInt(1, idUsuario);
            if (perfis != null) for (int i = 0; i < perfis.length; i++) ps.setString(i + 2, perfis[i]);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() && rs.getInt(1) == 1; }
        }
    }

    /** Compatibilidade com Dashboard/Perfil. */
    public List<Comentario> listarComentariosDenunciados(int limite) throws SQLException {
        String sql = "SELECT c.*,u.nome_usuario,u.foto_usuario,r.titulo_receita FROM comentario c "
                + "JOIN usuario u ON u.id_usuario=c.usuario JOIN receita r ON r.id_receita=c.receita "
                + "WHERE c.status_comentario='PENDENTE' ORDER BY c.data_criacao_comentario DESC LIMIT ?";
        List<Comentario> lista = new ArrayList<>();
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) lista.add(mapearComContexto(rs)); }
        }
        return lista;
    }

    /** Compatibilidade com consumidores existentes; o controller novo usa a operação condicionada abaixo. */
    public void cadastrarComentario(Comentario comentario) throws SQLException {
        String sql = "INSERT INTO comentario(receita,usuario,texto_comentario,data_criacao_comentario,"
                + "status_comentario,avaliacao_comentario) VALUES(?,?,?,NOW(),?,?)";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, comentario.getReceita()); ps.setInt(2, comentario.getUsuario());
            ps.setString(3, comentario.getTexto_comentario());
            ps.setString(4, comentario.getStatus_comentario().name());
            ps.setInt(5, comentario.getAvaliacao_comentario()); ps.executeUpdate();
        }
    }

    /** INSERT...SELECT elimina a janela entre conferir a receita e gravar o comentário. */
    public boolean cadastrarEmReceitaPublicadaAtiva(Comentario comentario) throws SQLException {
        String sql = "INSERT INTO comentario(receita,usuario,texto_comentario,data_criacao_comentario,"
                + "status_comentario,avaliacao_comentario) "
                + "SELECT r.id_receita,u.id_usuario,?,NOW(),'PENDENTE',? FROM receita r "
                + "JOIN usuario u ON u.id_usuario=? AND u.status_usuario='ATIVO' AND u.tipo_usuario='VISITANTE' "
                + "WHERE r.id_receita=? AND r.status_receita='publicada' AND r.status_atividade='ativo'";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, comentario.getTexto_comentario()); ps.setInt(2, comentario.getAvaliacao_comentario());
            ps.setInt(3, comentario.getUsuario()); ps.setInt(4, comentario.getReceita());
            return ps.executeUpdate() == 1;
        }
    }

    public List<Comentario> listarComentariosPorReceita(int idReceita) throws SQLException {
        String sql = "SELECT c.*,u.nome_usuario,u.foto_usuario,r.titulo_receita FROM comentario c "
                + "JOIN usuario u ON u.id_usuario=c.usuario JOIN receita r ON r.id_receita=c.receita "
                + "WHERE c.receita=? AND c.status_comentario='APROVADO' "
                + "ORDER BY c.data_criacao_comentario DESC";
        List<Comentario> lista = new ArrayList<>();
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idReceita);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) lista.add(mapearComContexto(rs)); }
        }
        return lista;
    }

    public List<Comentario> listarComentariosPorAutor(int autorId, String busca, String statusResposta,
            int limite, int offset) throws SQLException {
        FiltroAutor filtro = new FiltroAutor(busca, statusResposta);
        String sql = "SELECT c.*,u.nome_usuario,u.foto_usuario,r.titulo_receita FROM comentario c "
                + "JOIN usuario u ON u.id_usuario=c.usuario JOIN receita r ON r.id_receita=c.receita "
                + "WHERE r.usuario=?" + filtro.sql + " ORDER BY c.data_criacao_comentario DESC LIMIT ? OFFSET ?";
        List<Comentario> lista = new ArrayList<>();
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            int i = filtro.preparar(ps, 1, autorId);
            ps.setInt(i++, limite); ps.setInt(i, offset);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) lista.add(mapearComContexto(rs)); }
        }
        return lista;
    }

    public int contarComentariosPorAutor(int autorId, String busca, String statusResposta) throws SQLException {
        FiltroAutor filtro = new FiltroAutor(busca, statusResposta);
        String sql = "SELECT COUNT(*) FROM comentario c JOIN usuario u ON u.id_usuario=c.usuario "
                + "JOIN receita r ON r.id_receita=c.receita WHERE r.usuario=?" + filtro.sql;
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            filtro.preparar(ps, 1, autorId);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }

    public int contarRespostasPorAutor(int autorId, boolean respondidas) throws SQLException {
        String condicao = respondidas
                ? "c.resposta_comentario IS NOT NULL AND TRIM(c.resposta_comentario)<>''"
                : "c.resposta_comentario IS NULL OR TRIM(c.resposta_comentario)=''";
        String sql = "SELECT COUNT(*) FROM comentario c JOIN receita r ON r.id_receita=c.receita "
                + "WHERE r.usuario=? AND (" + condicao + ")";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, autorId); try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }

    public double calcularAvaliacaoMediaPorAutor(int autorId) throws SQLException {
        String sql = "SELECT COALESCE(AVG(c.avaliacao_comentario),0) FROM comentario c "
                + "JOIN receita r ON r.id_receita=c.receita WHERE r.usuario=? AND c.avaliacao_comentario BETWEEN 1 AND 5";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, autorId); try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getDouble(1) : 0; }
        }
    }

    public boolean responderComentarioDoAutor(int idComentario, int autorId, String resposta) throws SQLException {
        String sql = "UPDATE comentario c JOIN receita r ON r.id_receita=c.receita "
                + "JOIN usuario a ON a.id_usuario=r.usuario AND a.status_usuario='ATIVO' AND a.tipo_usuario='AUTOR' "
                + "SET c.resposta_comentario=?,c.data_resposta_comentario=NOW() "
                + "WHERE c.id_comentario=? AND r.usuario=? AND c.status_comentario<>'REMOVIDO'";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, resposta); ps.setInt(2, idComentario); ps.setInt(3, autorId);
            return ps.executeUpdate() == 1;
        }
    }

    public boolean denunciarComentarioDoAutor(int idComentario, int autorId) throws SQLException {
        String sql = "UPDATE comentario c JOIN receita r ON r.id_receita=c.receita "
                + "JOIN usuario a ON a.id_usuario=r.usuario AND a.status_usuario='ATIVO' AND a.tipo_usuario='AUTOR' "
                + "SET c.status_comentario='PENDENTE',c.data_modera_comentario=NULL "
                + "WHERE c.id_comentario=? AND r.usuario=? AND c.status_comentario<>'REMOVIDO'";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, idComentario); ps.setInt(2, autorId); return ps.executeUpdate() == 1;
        }
    }

    public List<Comentario> listarComentariosModeracao(String filtro, String status, String dataFiltro,
            int limite, int offset) throws SQLException {
        FiltroModeracao f = new FiltroModeracao(filtro, status, dataFiltro);
        String sql = "SELECT c.*,u.nome_usuario,u.foto_usuario,r.titulo_receita FROM comentario c "
                + "JOIN usuario u ON u.id_usuario=c.usuario JOIN receita r ON r.id_receita=c.receita "
                + "WHERE 1=1" + f.sql + " ORDER BY c.data_criacao_comentario DESC LIMIT ? OFFSET ?";
        List<Comentario> lista = new ArrayList<>();
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            int i = f.preparar(ps, 1); ps.setInt(i++, limite); ps.setInt(i, offset);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) lista.add(mapearComContexto(rs)); }
        }
        return lista;
    }

    public int contarComentariosModeracao(String filtro, String status, String dataFiltro) throws SQLException {
        FiltroModeracao f = new FiltroModeracao(filtro, status, dataFiltro);
        String sql = "SELECT COUNT(*) FROM comentario c JOIN usuario u ON u.id_usuario=c.usuario "
                + "JOIN receita r ON r.id_receita=c.receita WHERE 1=1" + f.sql;
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            f.preparar(ps, 1); try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }

    public boolean atualizarStatusComentario(int idComentario, StatusComentario status) throws SQLException {
        String sql = "UPDATE comentario SET status_comentario=?,data_modera_comentario=NOW() WHERE id_comentario=?";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setString(1, status.name()); ps.setInt(2, idComentario); return ps.executeUpdate() == 1;
        }
    }

    public boolean moderarComentario(int idComentario, int moderadorId, StatusComentario status) throws SQLException {
        String sql = "UPDATE comentario c JOIN usuario m ON m.id_usuario=? "
                + "AND m.status_usuario='ATIVO' AND m.tipo_usuario IN ('EDITOR','ADMIN') "
                + "SET c.status_comentario=?,c.data_modera_comentario=NOW() WHERE c.id_comentario=?";
        try (PreparedStatement ps = conexao.prepareStatement(sql)) {
            ps.setInt(1, moderadorId); ps.setString(2, status.name()); ps.setInt(3, idComentario);
            return ps.executeUpdate() == 1;
        }
    }

    public void removerComentario(int idComentario) throws SQLException {
        atualizarStatusComentario(idComentario, StatusComentario.REMOVIDO);
    }

    /** Comentário e usuário são alterados atomicamente; o usuário deriva do comentário. */
    public boolean inativarUsuarioPorComentario(int idComentario, int moderadorId) throws SQLException {
        boolean autoCommitOriginal = conexao.getAutoCommit();
        Savepoint savepoint = null;
        try {
            if (autoCommitOriginal) conexao.setAutoCommit(false); else savepoint = conexao.setSavepoint();
            Integer usuario = usuarioDoComentarioBloqueado(idComentario, moderadorId);
            if (usuario == null || usuario.intValue() == moderadorId) {
                desfazer(autoCommitOriginal, savepoint); return false;
            }
            try (PreparedStatement comentario = conexao.prepareStatement(
                    "UPDATE comentario SET status_comentario='REMOVIDO',data_modera_comentario=NOW() WHERE id_comentario=?");
                 PreparedStatement conta = conexao.prepareStatement(
                    "UPDATE usuario SET status_usuario='INATIVO' WHERE id_usuario=?")) {
                comentario.setInt(1, idComentario); comentario.executeUpdate();
                conta.setInt(1, usuario.intValue()); conta.executeUpdate();
            }
            if (autoCommitOriginal) conexao.commit();
            return true;
        } catch (SQLException e) {
            desfazer(autoCommitOriginal, savepoint); throw e;
        } finally {
            if (autoCommitOriginal) conexao.setAutoCommit(true);
        }
    }

    private Integer usuarioDoComentarioBloqueado(int idComentario, int moderadorId) throws SQLException {
        try (PreparedStatement ps = conexao.prepareStatement(
                "SELECT c.usuario FROM comentario c JOIN usuario u ON u.id_usuario=c.usuario "
                + "JOIN usuario m ON m.id_usuario=? AND m.status_usuario='ATIVO' AND m.tipo_usuario IN ('EDITOR','ADMIN') "
                + "WHERE c.id_comentario=? AND c.usuario<>m.id_usuario FOR UPDATE")) {
            ps.setInt(1, moderadorId); ps.setInt(2, idComentario);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? Integer.valueOf(rs.getInt(1)) : null; }
        }
    }

    private void desfazer(boolean autoCommitOriginal, Savepoint savepoint) throws SQLException {
        if (autoCommitOriginal) conexao.rollback(); else if (savepoint != null) conexao.rollback(savepoint);
    }

    private static final class FiltroAutor {
        final String busca; final String status; final String sql;
        FiltroAutor(String busca, String status) {
            this.busca = busca == null || busca.isBlank() ? null : busca.trim();
            this.status = status == null || status.isBlank() ? null : status;
            StringBuilder s = new StringBuilder();
            if (this.busca != null) s.append(" AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?)");
            if ("respondido".equalsIgnoreCase(this.status)) s.append(" AND c.resposta_comentario IS NOT NULL AND TRIM(c.resposta_comentario)<>''");
            if ("pendente".equalsIgnoreCase(this.status)) s.append(" AND (c.resposta_comentario IS NULL OR TRIM(c.resposta_comentario)='')");
            sql = s.toString();
        }
        int preparar(PreparedStatement ps, int i, int autorId) throws SQLException {
            ps.setInt(i++, autorId);
            if (busca != null) { String like="%"+busca+"%"; ps.setString(i++,like); ps.setString(i++,like); ps.setString(i++,like); }
            return i;
        }
    }

    private static final class FiltroModeracao {
        final String filtro; final String status; final String data; final String sql;
        FiltroModeracao(String filtro, String status, String data) {
            this.filtro=filtro==null||filtro.isBlank()?null:filtro.trim(); this.status=status; this.data=data;
            StringBuilder s=new StringBuilder();
            if(this.filtro!=null)s.append(" AND (c.texto_comentario LIKE ? OR u.nome_usuario LIKE ? OR r.titulo_receita LIKE ?)");
            if(status!=null&&!status.isBlank())s.append(" AND c.status_comentario=?");
            if(data!=null&&!data.isBlank())s.append(" AND DATE(c.data_criacao_comentario)>=?"); sql=s.toString();
        }
        int preparar(PreparedStatement ps,int i)throws SQLException{
            if(filtro!=null){String like="%"+filtro+"%";ps.setString(i++,like);ps.setString(i++,like);ps.setString(i++,like);}
            if(status!=null&&!status.isBlank())ps.setString(i++,status);
            if(data!=null&&!data.isBlank())ps.setString(i++,data); return i;
        }
    }
}
