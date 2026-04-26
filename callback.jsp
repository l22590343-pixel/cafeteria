<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.io.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Recibir código de Google ─────────────────────────── */
String code  = request.getParameter("code");
String error = request.getParameter("error");

if (error != null || code == null) {
    response.sendRedirect("login.jsp?error=google_cancelado");
    return;
}

String clientId     = System.getenv("GOOGLE_CLIENT_ID");
String clientSecret = System.getenv("GOOGLE_CLIENT_SECRET");
String redirectUri  = "https://cafeteria-production-d4cf.up.railway.app/cafeteria/callback.jsp";

/* ── 1) Intercambiar código por access token ─────────── */
String tokenResponse = "";
try {
    URL url = new URL("https://oauth2.googleapis.com/token");
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setDoOutput(true);
    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

    String params = "code=" + URLEncoder.encode(code, "UTF-8")
        + "&client_id=" + URLEncoder.encode(clientId, "UTF-8")
        + "&client_secret=" + URLEncoder.encode(clientSecret, "UTF-8")
        + "&redirect_uri=" + URLEncoder.encode(redirectUri, "UTF-8")
        + "&grant_type=authorization_code";

    OutputStream os = conn.getOutputStream();
    os.write(params.getBytes("UTF-8"));
    os.close();

    BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = br.readLine()) != null) sb.append(line);
    tokenResponse = sb.toString();
} catch (Exception ex) {
    response.sendRedirect("login.jsp?error=" + URLEncoder.encode("Error token: " + ex.getMessage(), "UTF-8"));
    return;
}

/* ── 2) Extraer access_token del JSON ────────────────── */
String accessToken = "";
if (tokenResponse.contains("\"access_token\"")) {
    int start = tokenResponse.indexOf("\"access_token\"") + 16;
    int end   = tokenResponse.indexOf("\"", start);
    accessToken = tokenResponse.substring(start, end);
}

if (accessToken.isEmpty()) {
    response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode("token_vacio: " + tokenResponse, "UTF-8"));
    return;
}

/* ── 3) Obtener info del usuario de Google ───────────── */
String userInfo = "";
try {
    URL url = new URL("https://www.googleapis.com/oauth2/v2/userinfo");
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestProperty("Authorization", "Bearer " + accessToken);
    BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = br.readLine()) != null) sb.append(line);
    userInfo = sb.toString();
} catch (Exception ex) {
    response.sendRedirect("login.jsp?error=userinfo_error");
    return;
}

/* ── 4) Extraer datos del JSON ───────────────────────── */
String googleId = "";
String email    = "";
String nombre   = "";

if (userInfo.contains("\"id\"")) {
    int s = userInfo.indexOf("\"id\"") + 6;
    int e = userInfo.indexOf("\"", s);
    googleId = userInfo.substring(s, e);
}
if (userInfo.contains("\"email\"")) {
    int s = userInfo.indexOf("\"email\"") + 9;
    int e = userInfo.indexOf("\"", s);
    email = userInfo.substring(s, e);
}
if (userInfo.contains("\"name\"")) {
    int s = userInfo.indexOf("\"name\"") + 8;
    int e = userInfo.indexOf("\"", s);
    nombre = userInfo.substring(s, e);
}

/* ── 5) Buscar o crear usuario en BD ─────────────────── */
Connection con = null;
try {
    con = Conexion.getConexion();

    /* Buscar por google_id */
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, nombre, usuario, rol FROM usuarios WHERE google_id = ?"
    );
    ps.setString(1, googleId);
    ResultSet rs = ps.executeQuery();

    if (rs.next()) {
        /* Usuario ya existe → iniciar sesión */
        session.setAttribute("userId",   rs.getInt("id"));
        session.setAttribute("username", rs.getString("usuario"));
        session.setAttribute("nombre",   rs.getString("nombre"));
        session.setAttribute("rol",      rs.getString("rol"));
    } else {
        /* Usuario nuevo → crear cuenta */
        String usuario = email.contains("@") ? email.substring(0, email.indexOf("@")) : email;

        /* Verificar que el usuario no exista */
        PreparedStatement check = con.prepareStatement(
            "SELECT id FROM usuarios WHERE usuario = ?"
        );
        check.setString(1, usuario);
        ResultSet rsCheck = check.executeQuery();
        if (rsCheck.next()) {
            usuario = usuario + "_g";
        }

        PreparedStatement ins = con.prepareStatement(
            "INSERT INTO usuarios (nombre, usuario, correo, google_id, rol) VALUES (?, ?, ?, ?, 'cliente'::rol_tipo)",
            Statement.RETURN_GENERATED_KEYS
        );
        ins.setString(1, nombre);
        ins.setString(2, usuario);
        ins.setString(3, email);
        ins.setString(4, googleId);
        ins.executeUpdate();

        ResultSet keys = ins.getGeneratedKeys();
        if (keys.next()) {
            session.setAttribute("userId",   keys.getInt(1));
            session.setAttribute("username", usuario);
            session.setAttribute("nombre",   nombre);
            session.setAttribute("rol",      "cliente");
        }
    }

    response.sendRedirect("menu.jsp");

} catch (Exception ex) {
    response.sendRedirect("login.jsp?error=" + URLEncoder.encode("Error BD: " + ex.getMessage(), "UTF-8"));
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
