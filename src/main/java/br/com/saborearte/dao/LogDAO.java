package br.com.saborearte.dao;

import br.com.saborearte.model.Log;
import br.com.saborearte.model.Usuario.TipoUsuario;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** Acesso parametrizado à auditoria. As consultas deste DAO nunca alteram logs. */
public class LogDAO {
    private final Connection conexao;
    public LogDAO(Connection conexao) { this.conexao = conexao; }

    public void registrar(Log log, String entidade) throws SQLException {
        String sql = "INSERT INTO log (usuario,acao_log,descricao_log,entidade_log,data_log) VALUES (?,?,?,?,NOW())";
        try (PreparedStatement stmt=conexao.prepareStatement(sql)) {
            stmt.setInt(1,log.getUsuario()); stmt.setString(2,log.getAcao_log());
            stmt.setString(3,log.getDetalhe_log()); stmt.setString(4,entidade); stmt.executeUpdate();
        }
    }
    public void registrar(Log log) throws SQLException { registrar(log,log.getEntidade_log()); }

    public int contarComFiltros(String busca,String acaoLog,String entidade,LocalDate inicio,LocalDate fim) throws SQLException {
        FiltroSql f=montarFiltro(busca,acaoLog,entidade,inicio,fim);
        try(PreparedStatement s=conexao.prepareStatement("SELECT COUNT(*) "+baseFrom()+f.where)) {
            aplicarParametros(s,f.params); try(ResultSet r=s.executeQuery()){return r.next()?r.getInt(1):0;}
        }
    }

    public List<Log> listarComFiltros(String busca,String acaoLog,String entidade,LocalDate inicio,LocalDate fim,int offset,int limite) throws SQLException {
        if(offset<0||limite<1) throw new IllegalArgumentException("Paginação inválida.");
        FiltroSql f=montarFiltro(busca,acaoLog,entidade,inicio,fim);
        String sql="SELECT l.id_log,l.usuario,l.acao_log,l.descricao_log,l.entidade_log,l.data_log,"+
                "u.nome_usuario,u.foto_usuario,u.tipo_usuario "+baseFrom()+f.where+
                " ORDER BY l.data_log DESC, l.id_log DESC LIMIT ? OFFSET ?";
        List<Log> logs=new ArrayList<>();
        try(PreparedStatement s=conexao.prepareStatement(sql)) {
            aplicarParametros(s,f.params); s.setInt(f.params.size()+1,limite); s.setInt(f.params.size()+2,offset);
            try(ResultSet r=s.executeQuery()){while(r.next())logs.add(mapearComAutor(r));}
        }
        return logs;
    }

    /** Compatibilidade temporária para consumidores antigos. */
    public ResultadoLogs listarComFiltro(String b,String a,String e,LocalDate i,LocalDate f,int o,int l) throws SQLException {
        return new ResultadoLogs(listarComFiltros(b,a,e,i,f,o,l),contarComFiltros(b,a,e,i,f));
    }
    public List<Log> listarTodos() throws SQLException {
        int total=contarComFiltros(null,null,null,null,null);
        return total==0?new ArrayList<>():listarComFiltros(null,null,null,null,null,0,total);
    }
    public List<Log> listarPorUsuario(int idUsuario,int limite) throws SQLException {
        String sql="SELECT id_log,usuario,acao_log,descricao_log,entidade_log,data_log FROM log WHERE usuario=? ORDER BY data_log DESC, id_log DESC LIMIT ?";
        List<Log> logs=new ArrayList<>();
        try(PreparedStatement s=conexao.prepareStatement(sql)){s.setInt(1,idUsuario);s.setInt(2,limite);try(ResultSet r=s.executeQuery()){while(r.next())logs.add(mapear(r));}}
        return logs;
    }
    public int contarLogs() throws SQLException{return contarComFiltros(null,null,null,null,null);}

    private String baseFrom(){return "FROM log l JOIN usuario u ON u.id_usuario=l.usuario ";}
    private FiltroSql montarFiltro(String busca,String acao,String entidade,LocalDate inicio,LocalDate fim){
        StringBuilder w=new StringBuilder("WHERE 1=1"); List<Object> p=new ArrayList<>();
        if(busca!=null&&!busca.isBlank()){w.append(" AND (u.nome_usuario LIKE ? OR l.descricao_log LIKE ?)");String t="%"+busca.trim()+"%";p.add(t);p.add(t);}
        if(acao!=null&&!acao.isBlank()){w.append(" AND l.acao_log=?");p.add(acao);}
        if(entidade!=null&&!entidade.isBlank()){w.append(" AND l.entidade_log=?");p.add(entidade);}
        if(inicio!=null){w.append(" AND l.data_log>=?");p.add(Date.valueOf(inicio));}
        if(fim!=null){w.append(" AND l.data_log<?");p.add(Date.valueOf(fim.plusDays(1)));}
        return new FiltroSql(w.toString(),p);
    }
    private void aplicarParametros(PreparedStatement s,List<Object> p)throws SQLException{for(int x=0;x<p.size();x++)s.setObject(x+1,p.get(x));}
    private Log mapear(ResultSet r)throws SQLException{Log l=new Log();l.setId_log(r.getInt("id_log"));l.setUsuario(r.getInt("usuario"));l.setAcao_log(r.getString("acao_log"));l.setDetalhe_log(r.getString("descricao_log"));l.setEntidade_log(r.getString("entidade_log"));Timestamp t=r.getTimestamp("data_log");l.setData_log(t==null?null:t.toString());return l;}
    private Log mapearComAutor(ResultSet r)throws SQLException{Log l=mapear(r);l.setNome_usuario(r.getString("nome_usuario"));l.setFoto_usuario(r.getString("foto_usuario"));String t=r.getString("tipo_usuario");if(t!=null)l.setTipo_usuario(TipoUsuario.valueOf(t));return l;}
    private static final class FiltroSql{final String where;final List<Object> params;FiltroSql(String w,List<Object> p){where=w;params=p;}}
    public static final class ResultadoLogs{public final List<Log> logs;public final int total;public ResultadoLogs(List<Log> l,int t){logs=l;total=t;}}
}
