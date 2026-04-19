<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Si ya está logueado, redirigir ────────────────────── */
if (session.getAttribute("userId") != null) {
    String rolSesion = (String) session.getAttribute("rol");
    response.sendRedirect("admin".equals(rolSesion) ? "admin.jsp" : "menu.jsp");
    return;
}

String error = "";

/* ── POST: validar credenciales en PostgreSQL ──────────── */
if ("POST".equals(request.getMethod())) {
    String user = request.getParameter("usuario") != null
                  ? request.getParameter("usuario").trim() : "";
    String pass = request.getParameter("pass")    != null
                  ? request.getParameter("pass")           : "";

    if (user.isEmpty() || pass.isEmpty()) {
        error = "Completa todos los campos.";
    } else {
        Connection con = null;
        try {
            con = Conexion.getConexion();
            PreparedStatement ps = con.prepareStatement(
                "SELECT id, nombre, rol FROM usuarios WHERE usuario = ? AND pass = ?"
            );
            ps.setString(1, user);
            ps.setString(2, pass);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                session.setAttribute("userId",   rs.getInt("id"));
                session.setAttribute("username", user);
                session.setAttribute("nombre",   rs.getString("nombre"));
                session.setAttribute("rol",      rs.getString("rol"));

                String destino = "admin".equals(rs.getString("rol")) ? "admin.jsp" : "menu.jsp";
                response.sendRedirect(destino);
                return;
            } else {
                error = "Usuario o contraseña incorrectos.";
            }
        } catch (SQLException ex) {
            error = "Error de base de datos: " + ex.getMessage();
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }
    }
}

/* Mensaje de registro exitoso */
String regMsg = "ok".equals(request.getParameter("registro"))
                ? "✅ Registro exitoso. Ahora inicia sesión." : "";

/* Error de Google */
String googleError = request.getParameter("error") != null
                ? "⚠️ " + request.getParameter("error") : "";

/* URL de Google OAuth */
String clientId = System.getenv("GOOGLE_CLIENT_ID");
String googleUrl = "https://accounts.google.com/o/oauth2/v2/auth"
    + "?client_id=" + clientId
    + "&redirect_uri=https://cafeteria-production-d4cf.up.railway.app/cafeteria/callback.jsp"
    + "&response_type=code"
    + "&scope=openid%20email%20profile"
    + "&prompt=select_account";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cafetería — Iniciar sesión</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{
    font-family:'DM Sans',sans-serif;
    background:var(--cream);
    color:var(--espresso);min-height:100vh;
    display:flex;flex-direction:column;
    align-items:center;justify-content:center;
    padding:32px 20px;
    position:relative;
  }
  body::before{
    content:'';position:absolute;inset:0;
    background:rgba(20,10,5,.55);
    pointer-events:none;
  }
  .login-logo{text-align:center;margin-bottom:32px;position:relative;z-index:1;}
  .login-logo h1{font-family:'Playfair Display',serif;font-size:3rem;color:var(--cream);letter-spacing:2px;}
  .login-logo p{color:var(--latte);font-size:.9rem;margin-top:4px;}
  .login-card{background:white;border-radius:24px;padding:36px 32px;width:100%;max-width:400px;box-shadow:0 20px 60px rgba(44,26,14,.3);position:relative;z-index:1;}
  .login-card h2{font-family:'Playfair Display',serif;font-size:1.5rem;margin-bottom:24px;color:var(--espresso);}
  .form-group{margin-bottom:16px;}
  .form-group label{display:block;font-size:.85rem;font-weight:600;margin-bottom:6px;color:#7a5c3a;}
  .form-group input{width:100%;padding:12px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.95rem;background:var(--foam);outline:none;transition:border .2s;}
  .form-group input:focus{border-color:var(--caramel);background:white;}
  .btn{width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;margin-bottom:10px;transition:all .2s;display:block;text-align:center;text-decoration:none;}
  .btn-primary{background:var(--espresso);color:var(--cream);}
  .btn-primary:hover{background:#1a0f05;transform:translateY(-1px);}
  .btn-secondary{background:var(--latte);color:var(--espresso);}
  .btn-secondary:hover{background:#d4b07a;}
  .btn-google{
    background:white;color:#3c4043;
    border:2px solid #dadce0;
    display:flex;align-items:center;justify-content:center;gap:10px;
    font-size:.95rem;font-weight:600;
    border-radius:12px;padding:12px;
    cursor:pointer;width:100%;margin-bottom:10px;
    transition:all .2s;text-decoration:none;
  }
  .btn-google:hover{background:#f8f9fa;border-color:#c1c7cd;box-shadow:0 2px 8px rgba(0,0,0,.1);}
  .btn-google img{width:20px;height:20px;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px 14px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px 14px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .divider{display:flex;align-items:center;gap:10px;margin:16px 0;}
  .divider span{font-size:.8rem;color:#b8a88a;white-space:nowrap;}
  .divider::before,.divider::after{content:'';flex:1;height:1px;background:var(--latte);}
</style>
</head>
<body>
<div class="login-logo">
  <h1>☕ CAFETERÍA</h1>
  <p>Bienvenido, ¿qué deseas hoy?</p>
</div>
<div class="login-card">
  <h2>Iniciar sesión</h2>

  <% if (!error.isEmpty()) { %>
  <div class="alert-error">⚠️ <%= error %></div>
  <% } %>
  <% if (!regMsg.isEmpty()) { %>
  <div class="alert-ok"><%= regMsg %></div>
  <% } %>
  <% if (!googleError.isEmpty()) { %>
  <div class="alert-error"><%= googleError %></div>
  <% } %>

  <!-- Botón Google -->
  <a href="<%= googleUrl %>" class="btn-google">
    <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" alt="Google">
    Continuar con Google
  </a>

  <div class="divider"><span>o inicia con tu cuenta</span></div>

  <form method="post" action="login.jsp">
    <div class="form-group">
      <label>Usuario</label>
      <input type="text" name="usuario" placeholder="Tu usuario..." required autocomplete="username">
    </div>
    <div class="form-group">
      <label>Contraseña</label>
      <input type="password" name="pass" placeholder="••••••••" required autocomplete="current-password">
    </div>
    <button type="submit" class="btn btn-primary">Iniciar sesión</button>
  </form>

  <a href="registro.jsp" class="btn btn-secondary">Registrarse</a>
</div>
</body>
</html>
