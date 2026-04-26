<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="util.Conexion" %>
<%
/* ── Recibir token de Google Sign-In ─────────────────────── */
String credential = request.getParameter("credential");

if (credential == null || credential.isEmpty()) {
    response.sendRedirect("login.jsp?error=sin_token");
    return;
}

/* ── Decodificar el JWT (payload en base64) ──────────────── */
String email  = "";
String nombre = "";
String googleId = "";

try {
    String[] parts = credential.split("\\.");
    if (parts.length < 2) throw new Exception("JWT invalido");

    // Decodificar el payload (segunda parte del JWT)
    String payload = parts[1];
    // Agregar padding si es necesario
    int pad = payload.length() % 4;
    if (pad == 2) payload += "==";
    else if (pad == 3) payload += "=";

    byte[] decoded = Base64.getUrlDecoder().decode(payload);
    String json = new String(decoded, "UTF-8");

    // Extraer campos del JSON
    if (json.contains("\"sub\"")) {
        int s = json.indexOf("\"sub\"") + 7;
        int e = json.indexOf("\"", s);
        googleId = json.substring(s, e);
    }
    if (json.contains("\"email\"")) {
        int s = json.indexOf("\"email\"") + 9;
        int e = json.indexOf("\"", s);
        email = json.substring(s, e);
    }
    if (json.contains("\"name\"")) {
        int s = json.indexOf("\"name\"") + 8;
        int e = json.indexOf("\"", s);
        nombre = json.substring(s, e);
    }

} catch (Exception ex) {
    response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode("jwt_error: " + ex.getMessage(), "UTF-8"));
    return;
}

if (googleId.isEmpty() || email.isEmpty()) {
    response.sendRedirect("login.jsp?error=datos_google_invalidos");
    return;
}

/* ── Buscar o crear usuario en BD ────────────────────────── */
Connection con = null;
try {
    con = Conexion.getConexion();

    // Buscar por google_id
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, nombre, usuario, rol FROM usuarios WHERE google_id = ?"
    );
    ps.setString(1, googleId);
    ResultSet rs = ps.executeQuery();

    if (rs.next()) {
        // Usuario ya existe → iniciar sesión
        session.setAttribute("userId",   rs.getInt("id"));
        session.setAttribute("username", rs.getString("usuario"));
        session.setAttribute("nombre",   rs.getString("nombre"));
        session.setAttribute("rol",      rs.getString("rol"));
        response.sendRedirect("menu.jsp");
    } else {
        // Buscar por correo
        PreparedStatement ps2 = con.prepareStatement(
            "SELECT id, nombre, usuario, rol FROM usuarios WHERE correo = ?"
        );
        ps2.setString(1, email);
        ResultSet rs2 = ps2.executeQuery();

        if (rs2.next()) {
            // Vincular google_id a cuenta existente
            PreparedStatement upd = con.prepareStatement(
                "UPDATE usuarios SET google_id = ? WHERE id = ?"
            );
            upd.setString(1, googleId);
            upd.setInt(2, rs2.getInt("id"));
            upd.executeUpdate();

            session.setAttribute("userId",   rs2.getInt("id"));
            session.setAttribute("username", rs2.getString("usuario"));
            session.setAttribute("nombre",   rs2.getString("nombre"));
            session.setAttribute("rol",      rs2.getString("rol"));
            response.sendRedirect("menu.jsp");
        } else {
            // Crear nuevo usuario
            String usuario = email.contains("@") ? email.substring(0, email.indexOf("@")) : email;

            // Verificar que el usuario no exista
            PreparedStatement check = con.prepareStatement(
                "SELECT id FROM usuarios WHERE usuario = ?"
            );
            check.setString(1, usuario);
            ResultSet rsCheck = check.executeQuery();
            if (rsCheck.next()) usuario = usuario + "_g";

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
            response.sendRedirect("menu.jsp");
        }
    }
} catch (Exception ex) {
    response.sendRedirect("login.jsp?error=" + java.net.URLEncoder.encode("BD: " + ex.getMessage(), "UTF-8"));
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
