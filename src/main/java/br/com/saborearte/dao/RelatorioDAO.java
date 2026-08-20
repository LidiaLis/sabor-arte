package br.com.saborearte.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class RelatorioDAO {
    private final Connection conexao;
    public RelatorioDAO(Connection conexao){this.conexao=conexao;}

    public List<UsuarioRelatorio> listarUsuarios(String status) throws SQLException {
        String sql="""
            SELECT u.nome_usuario,u.email_usuario,u.tipo_usuario,u.status_usuario,
                   COUNT(DISTINCT r.id_receita) total_receitas,
                   COUNT(DISTINCT CASE WHEN r.status_receita='publicada' THEN r.id_receita END) publicadas,
                   COALESCE(SUM(r.visualizacoes_receita),0) visualizacoes
              FROM usuario u LEFT JOIN receita r ON r.usuario=u.id_usuario
             WHERE (? IS NULL OR ?='' OR u.status_usuario=?)
             GROUP BY u.id_usuario,u.nome_usuario,u.email_usuario,u.tipo_usuario,u.status_usuario
             ORDER BY u.nome_usuario
            """;
        List<UsuarioRelatorio> lista=new ArrayList<>();
        try(PreparedStatement ps=conexao.prepareStatement(sql)){
            ps.setString(1,status);ps.setString(2,status);ps.setString(3,status);
            try(ResultSet rs=ps.executeQuery()){while(rs.next())lista.add(new UsuarioRelatorio(
                rs.getString("nome_usuario"),rs.getString("email_usuario"),rs.getString("tipo_usuario"),
                rs.getString("status_usuario"),rs.getInt("total_receitas"),rs.getInt("publicadas"),rs.getLong("visualizacoes")));
            }
        }return lista;
    }

    public List<CategoriaRelatorio> listarCategorias(String status) throws SQLException {
        String sql="""
            SELECT c.id_categoria,c.nome_categoria,c.emoji_categoria,c.status_categoria,
                   COUNT(r.id_receita) total_receitas
              FROM categoria c LEFT JOIN receita r ON r.categoria=c.id_categoria
             WHERE (? IS NULL OR ?='' OR c.status_categoria=?)
             GROUP BY c.id_categoria,c.nome_categoria,c.emoji_categoria,c.status_categoria
             ORDER BY c.nome_categoria
            """;
        List<CategoriaRelatorio> lista=new ArrayList<>();
        try(PreparedStatement ps=conexao.prepareStatement(sql)){
            ps.setString(1,status);ps.setString(2,status);ps.setString(3,status);
            try(ResultSet rs=ps.executeQuery()){while(rs.next())lista.add(new CategoriaRelatorio(
                rs.getInt("id_categoria"),rs.getString("nome_categoria"),rs.getString("emoji_categoria"),
                rs.getString("status_categoria"),rs.getInt("total_receitas")));
            }
        }return lista;
    }

    public List<ReceitaRelatorio> listarReceitas(Integer autorId,Integer categoriaId,String buscaAutor) throws SQLException {
        String sql="""
            SELECT r.id_receita,r.titulo_receita,r.status_receita,r.visualizacoes_receita,
                   c.nome_categoria,c.emoji_categoria,u.nome_usuario,
                   COUNT(cm.id_comentario) total_comentarios,
                   COALESCE(AVG(cm.avaliacao_comentario),0) avaliacao_media
              FROM receita r JOIN categoria c ON c.id_categoria=r.categoria
              JOIN usuario u ON u.id_usuario=r.usuario
              LEFT JOIN comentario cm ON cm.receita=r.id_receita AND cm.status_comentario='APROVADO'
             WHERE (? IS NULL OR r.usuario = ?)
               AND (? IS NULL OR r.categoria = ?)
               AND (? IS NULL OR ?='' OR u.nome_usuario LIKE ?)
             GROUP BY r.id_receita,r.titulo_receita,r.status_receita,r.visualizacoes_receita,
                      c.nome_categoria,c.emoji_categoria,u.nome_usuario
             ORDER BY r.visualizacoes_receita DESC,r.titulo_receita
            """;
        List<ReceitaRelatorio> lista=new ArrayList<>();
        try(PreparedStatement ps=conexao.prepareStatement(sql)){
            if(autorId==null){ps.setNull(1,java.sql.Types.INTEGER);ps.setNull(2,java.sql.Types.INTEGER);}else{ps.setInt(1,autorId);ps.setInt(2,autorId);}
            if(categoriaId==null){ps.setNull(3,java.sql.Types.INTEGER);ps.setNull(4,java.sql.Types.INTEGER);}else{ps.setInt(3,categoriaId);ps.setInt(4,categoriaId);}
            String busca=buscaAutor==null?null:"%"+buscaAutor.trim()+"%";ps.setString(5,buscaAutor);ps.setString(6,buscaAutor);ps.setString(7,busca);
            try(ResultSet rs=ps.executeQuery()){while(rs.next())lista.add(new ReceitaRelatorio(
                rs.getInt("id_receita"),rs.getString("titulo_receita"),rs.getString("nome_categoria"),
                rs.getString("emoji_categoria"),rs.getString("nome_usuario"),rs.getInt("visualizacoes_receita"),
                rs.getInt("total_comentarios"),rs.getDouble("avaliacao_media"),rs.getString("status_receita")));
            }
        }return lista;
    }

    public List<ComentarioRelatorio> listarComentarios(Integer autorId,String status,LocalDate inicio,LocalDate fim) throws SQLException {
        String sql="""
            SELECT cm.id_comentario,u.nome_usuario,r.titulo_receita,cm.avaliacao_comentario,
                   cm.data_criacao_comentario,cm.status_comentario,cm.texto_comentario
              FROM comentario cm JOIN usuario u ON u.id_usuario=cm.usuario
              JOIN receita r ON r.id_receita=cm.receita
             WHERE (? IS NULL OR r.usuario = ?)
               AND (? IS NULL OR ?='' OR cm.status_comentario=?)
               AND (? IS NULL OR cm.data_criacao_comentario>=?)
               AND (? IS NULL OR cm.data_criacao_comentario<?)
             ORDER BY cm.data_criacao_comentario DESC
            """;
        List<ComentarioRelatorio> lista=new ArrayList<>();
        try(PreparedStatement ps=conexao.prepareStatement(sql)){
            if(autorId==null){ps.setNull(1,java.sql.Types.INTEGER);ps.setNull(2,java.sql.Types.INTEGER);}else{ps.setInt(1,autorId);ps.setInt(2,autorId);}
            ps.setString(3,status);ps.setString(4,status);ps.setString(5,status);
            if(inicio==null){ps.setNull(6,java.sql.Types.DATE);ps.setNull(7,java.sql.Types.DATE);}else{ps.setDate(6,java.sql.Date.valueOf(inicio));ps.setDate(7,java.sql.Date.valueOf(inicio));}
            if(fim==null){ps.setNull(8,java.sql.Types.DATE);ps.setNull(9,java.sql.Types.DATE);}else{java.sql.Date limite=java.sql.Date.valueOf(fim.plusDays(1));ps.setDate(8,limite);ps.setDate(9,limite);}
            try(ResultSet rs=ps.executeQuery()){while(rs.next())lista.add(new ComentarioRelatorio(
                rs.getInt("id_comentario"),rs.getString("nome_usuario"),rs.getString("titulo_receita"),
                rs.getInt("avaliacao_comentario"),rs.getString("data_criacao_comentario"),
                rs.getString("status_comentario"),rs.getString("texto_comentario")));
            }
        }return lista;
    }

    public static final class UsuarioRelatorio{
        public final String nome,email,tipo,status;public final int receitas,publicadas;public final long visualizacoes;
        public UsuarioRelatorio(String n,String e,String t,String s,int r,int p,long v){nome=n;email=e;tipo=t;status=s;receitas=r;publicadas=p;visualizacoes=v;}
    }
    public static final class CategoriaRelatorio{
        public final int id,totalReceitas;public final String nome,emoji,status;
        public CategoriaRelatorio(int i,String n,String e,String s,int t){id=i;nome=n;emoji=e;status=s;totalReceitas=t;}
    }
    public static final class ReceitaRelatorio{
        public final int id,visualizacoes,comentarios;public final String titulo,categoria,emoji,autor,status;public final double avaliacao;
        public ReceitaRelatorio(int i,String t,String c,String e,String a,int v,int co,double av,String s){id=i;titulo=t;categoria=c;emoji=e;autor=a;visualizacoes=v;comentarios=co;avaliacao=av;status=s;}
    }
    public static final class ComentarioRelatorio{
        public final int id,avaliacao;public final String usuario,receita,data,status,texto;
        public ComentarioRelatorio(int i,String u,String r,int a,String d,String s,String t){id=i;usuario=u;receita=r;avaliacao=a;data=d;status=s;texto=t;}
    }
}
