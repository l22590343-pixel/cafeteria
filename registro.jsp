<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Procesar POST ─────────────────────────────────────── */
String error   = "";
String success = "";

if ("POST".equals(request.getMethod())) {
    String nombre = request.getParameter("nombre") != null ? request.getParameter("nombre").trim() : "";
    String user   = request.getParameter("usuario") != null ? request.getParameter("usuario").trim() : "";
    String pass   = request.getParameter("pass")    != null ? request.getParameter("pass")           : "";
    String pass2  = request.getParameter("pass2")   != null ? request.getParameter("pass2")          : "";

    /* Validaciones */
    if (nombre.isEmpty() || user.isEmpty() || pass.isEmpty()) {
        error = "Completa todos los campos.";
    } else if (!pass.equals(pass2)) {
        error = "Las contraseñas no coinciden.";
    } else if (pass.length() < 8
               || !pass.matches(".*[A-Z].*")
               || !pass.matches(".*[a-z].*")
               || !pass.matches(".*[0-9].*")
               || !pass.matches(".*[^A-Za-z0-9].*")) {
        error = "La contraseña debe tener mínimo 8 caracteres, una mayúscula, una minúscula, un número y un símbolo.";
    } else {
        Connection con = null;
        try {
            con = Conexion.getConexion();
            /* Verificar si el usuario ya existe */
            PreparedStatement check = con.prepareStatement("SELECT id FROM usuarios WHERE usuario = ?");
            check.setString(1, user);
            ResultSet rs = check.executeQuery();
            if (rs.next()) {
                error = "Ese nombre de usuario ya está en uso.";
            } else {
                /* Insertar nuevo usuario */
                PreparedStatement ins = con.prepareStatement(
                    "INSERT INTO usuarios (nombre, usuario, pass, rol) VALUES (?, ?, ?, 'cliente')"
                );
                ins.setString(1, nombre);
                ins.setString(2, user);
                ins.setString(3, pass);   /* En producción usar BCrypt */
                ins.executeUpdate();
                success = "ok";
            }
        } catch (Exception ex) {
            error = "Error de base de datos: " + ex.getMessage();
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }
    }

    if ("ok".equals(success)) {
        response.sendRedirect("login.jsp?registro=ok");
        return;
    }
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Registro — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;display:flex;flex-direction:column;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:480px;margin:32px auto;padding:0 20px;width:100%;}
  .card{background:white;border-radius:20px;padding:32px;box-shadow:0 8px 32px rgba(44,26,14,.1);}
  .card h2{font-family:'Playfair Display',serif;font-size:1.4rem;margin-bottom:24px;color:var(--espresso);}
  .form-group{margin-bottom:18px;}
  .form-group label{display:block;font-size:.85rem;font-weight:600;margin-bottom:6px;color:#7a5c3a;}
  .form-group input{width:100%;padding:12px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.95rem;background:var(--foam);outline:none;transition:border .2s;}
  .form-group input:focus{border-color:var(--caramel);background:white;}
  .pass-rules{margin-top:6px;font-size:.8rem;line-height:1.7;}
  .rule{display:block;} .rule.ok{color:var(--mint);} .rule.no{color:var(--danger);}
  .btn{width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;transition:all .2s;margin-bottom:10px;}
  .btn-primary{background:var(--espresso);color:var(--cream);}
  .btn-primary:hover{background:#1a0f05;transform:translateY(-1px);}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px 14px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .link{color:var(--caramel);cursor:pointer;text-decoration:none;font-weight:600;}
  .text-center{text-align:center;font-size:.9rem;margin-top:8px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="login.jsp">←</a>
  <span class="topbar-title">Registro de Usuario</span>
</div>
<div class="container">
  <div class="card">
    <h2>Crear cuenta</h2>

    <% if (!error.isEmpty()) { %>
    <div class="alert-error">⚠️ <%= error %></div>
    <% } %>

    <form method="post" action="registro.jsp">
      <div class="form-group">
        <label>Nombre completo</label>
        <input type="text" name="nombre" placeholder="Tu nombre..." required>
      </div>
      <div class="form-group">
        <label>Usuario</label>
        <input type="text" name="usuario" placeholder="Nombre de usuario..." required autocomplete="username">
      </div>
      <div class="form-group">
        <label>Contraseña</label>
        <input type="password" name="pass" id="pass" placeholder="Mín. 8 caracteres" required
               oninput="checkPass(this.value)" autocomplete="new-password">
        <div class="pass-rules" id="pass-rules">
          <span class="rule no" id="r-len">✘ 8 caracteres mínimo</span>
          <span class="rule no" id="r-may">✘ Una mayúscula</span>
          <span class="rule no" id="r-min">✘ Una minúscula</span>
          <span class="rule no" id="r-num">✘ Un número</span>
          <span class="rule no" id="r-sim">✘ Un símbolo (!@#$...)</span>
        </div>
      </div>
      <div class="form-group">
        <label>Confirmar contraseña</label>
        <input type="password" name="pass2" placeholder="Repite la contraseña" required autocomplete="new-password">
      </div>
      <button type="submit" class="btn btn-primary">Registrarse</button>
    </form>
    <p class="text-center">¿Ya tienes cuenta? <a class="link" href="login.jsp">Iniciar sesión</a></p>
  </div>
</div>
<script>
function checkPass(v) {
  const set = (id, ok, si, no) => {
    const el = document.getElementById(id);
    el.textContent = (ok ? '✔ ' : '✘ ') + (ok ? si : no);
    el.className = 'rule ' + (ok ? 'ok' : 'no');
  };
  set('r-len', v.length >= 8,          '8 caracteres mínimo',   '8 caracteres mínimo');
  set('r-may', /[A-Z]/.test(v),        'Una mayúscula',          'Una mayúscula');
  set('r-min', /[a-z]/.test(v),        'Una minúscula',          'Una minúscula');
  set('r-num', /[0-9]/.test(v),        'Un número',              'Un número');
  set('r-sim', /[^A-Za-z0-9]/.test(v), 'Un símbolo (!@#$...)',   'Un símbolo (!@#$...)');
}
</script>
</body>
</html>
