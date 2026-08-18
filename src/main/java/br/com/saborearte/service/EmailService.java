package br.com.saborearte.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

/**
 * Serviço de envio de e-mails do Sabor & Arte.
 *
 * Usa javax.mail (não jakarta.mail) — mesmo motivo do resto do projeto:
 * Tomcat 9 / Servlet API 4 está na geração javax.*.
 *
 * DEPENDÊNCIAS (jars manuais em WEB-INF/lib):
 *   - javax.mail-1.6.2.jar
 *   - activation-1.1.1.jar   (JavaBeans Activation Framework — javax.mail exige)
 *
 * CONFIGURAÇÃO:
 * As credenciais SMTP são lidas de um arquivo mail.properties no classpath
 * (WEB-INF/classes/mail.properties). Não tem nada hardcoded aqui — assim
 * dá pra trocar de Mailtrap (teste) pra um SMTP de produção só editando
 * o arquivo, sem recompilar nada.
 *
 * Formato esperado do mail.properties (exemplo com Gmail SMTP):
 *   mail.smtp.host=smtp.gmail.com
 *   mail.smtp.port=587
 *   mail.smtp.user=seuemail@gmail.com
 *   mail.smtp.pass=SENHA_DE_APP_16_CARACTERES
 *   mail.remetente.email=seuemail@gmail.com   (opcional — se omitido, usa mail.smtp.user)
 *   mail.remetente.nome=Sabor & Arte          (opcional — nome de exibição do remetente)
 *
 * OBS: o Gmail exige que "mail.remetente.email" seja a própria conta
 * autenticada (ou um alias configurado em "Enviar como" nas configurações
 * do Gmail) — não dá pra mandar como um domínio qualquer sem isso.
 *
 * IMPORTANTE: mail.properties tem credencial dentro — não versiona ele no
 * Git (adiciona no .gitignore). Se o projeto já tem outros arquivos de
 * config sensíveis (ex.: senha do banco), segue o mesmo padrão que vocês
 * já usam pra isso.
 */
public class EmailService {

    private static final String ARQUIVO_CONFIG = "mail.properties";

    private final String remetente;
    private final String remetenteNome;
    private final Session session;

    public EmailService() {
        Properties config = carregarConfig();

        String host = config.getProperty("mail.smtp.host");
        String port = config.getProperty("mail.smtp.port", "587");
        String user = config.getProperty("mail.smtp.user");
        String pass = config.getProperty("mail.smtp.pass");

        if (isBlank(host) || isBlank(user) || isBlank(pass)) {
            throw new IllegalStateException(
                "mail.properties não encontrado ou incompleto. Ele precisa estar em "
              + "WEB-INF/classes com mail.smtp.host, mail.smtp.user e mail.smtp.pass preenchidos."
            );
        }

        // Remetente: se não configurado explicitamente, usa o próprio "user"
        // do SMTP — é o comportamento certo pro Gmail, que exige que o
        // campo "De" bata com a conta autenticada (ou um alias dela).
        this.remetente     = config.getProperty("mail.remetente.email", user);
        this.remetenteNome = config.getProperty("mail.remetente.nome", "Sabor & Arte");

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", host);
        props.put("mail.smtp.port", port);
        props.put("mail.smtp.ssl.trust", "smtp.gmail.com");

        this.session = Session.getInstance(props, new javax.mail.Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(user, pass);
            }
        });
    }

    /**
     * Lê o mail.properties do classpath (WEB-INF/classes). Se não achar,
     * devolve Properties vazio — o construtor detecta isso e falha com
     * uma mensagem clara em vez de um NullPointerException confuso.
     */
    private Properties carregarConfig() {
        Properties props = new Properties();
        try (InputStream in = getClass().getClassLoader().getResourceAsStream(ARQUIVO_CONFIG)) {
            if (in != null) {
                props.load(in);
            }
        } catch (IOException e) {
            throw new IllegalStateException("Erro ao ler " + ARQUIVO_CONFIG, e);
        }
        return props;
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    /**
     * Envia o e-mail com o código de recuperação de senha.
     *
     * @param destinatario e-mail de quem vai receber
     * @param nomeUsuario  nome pra personalizar a saudação
     * @param codigo       código de 6 dígitos já gerado (CodigoRecuperacaoDAO)
     * @param minutosValidade quantos minutos o código vale (hoje: 5)
     */
    public void enviarCodigoRecuperacao(String destinatario, String nomeUsuario, String codigo, int minutosValidade)
            throws MessagingException, UnsupportedEncodingException {

        String assunto = "Sabor & Arte — Código de recuperação de senha";
        String corpo   = montarCorpoHtml(nomeUsuario, codigo, minutosValidade);
        enviar(destinatario, assunto, corpo);
    }

    private void enviar(String destinatario, String assunto, String corpoHtml)
            throws MessagingException, UnsupportedEncodingException {

        MimeMessage mensagem = new MimeMessage(session);
        mensagem.setFrom(new InternetAddress(remetente, remetenteNome, "UTF-8"));
        mensagem.setRecipients(Message.RecipientType.TO, InternetAddress.parse(destinatario));
        mensagem.setSubject(assunto, "UTF-8");
        mensagem.setContent(corpoHtml, "text/html; charset=UTF-8");

        Transport.send(mensagem);
    }

    private String montarCorpoHtml(String nomeUsuario, String codigo, int minutosValidade) {
        String nome = (nomeUsuario == null || nomeUsuario.isBlank()) ? "" : nomeUsuario;

        return "<div style=\"font-family:'DM Sans',Arial,sans-serif;max-width:480px;margin:0 auto;"
             + "background:#faf8f4;border:1px solid #e8e0d0;border-radius:4px;overflow:hidden;\">"
             + "  <div style=\"height:5px;background:linear-gradient(90deg,#2f3d25,#4a5e3a,#a3b18a,#c4a265);\"></div>"
             + "  <div style=\"padding:32px;\">"
             + "    <h2 style=\"color:#1e2718;margin:0 0 12px;\">🌿 Sabor &amp; Arte</h2>"
             + "    <p style=\"color:#4a5240;font-size:15px;line-height:1.5;\">Olá" + (nome.isEmpty() ? "" : ", " + nome) + "!</p>"
             + "    <p style=\"color:#4a5240;font-size:15px;line-height:1.5;\">"
             +          "Use o código abaixo para redefinir sua senha:</p>"
             + "    <div style=\"text-align:center;margin:24px 0;\">"
             + "      <span style=\"display:inline-block;padding:14px 28px;background:#4a5e3a;color:#f5f0e8;"
             +               "font-size:28px;font-weight:700;letter-spacing:8px;border-radius:4px;\">" + codigo + "</span>"
             + "    </div>"
             + "    <p style=\"color:#8a9480;font-size:13px;line-height:1.5;\">"
             +          "Esse código expira em " + minutosValidade + " minutos. Se você não pediu essa recuperação de senha, "
             +          "pode ignorar este e-mail com segurança.</p>"
             + "  </div>"
             + "</div>";
    }
}