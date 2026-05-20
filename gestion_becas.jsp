<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String msg = "";
String msgType = "";

// POST: agregar nueva beca
if ("POST".equals(request.getMethod())) {
    String nombre    = request.getParameter("nombre");
    String numCtrl   = request.getParameter("numero_control");
    String semIni    = request.getParameter("semana_inicio");
    String semFin    = request.getParameter("semana_fin");
    String montoStr  = request.getParameter("monto");

    try {
        double monto = Double.parseDouble(montoStr);
        Connection con = Conexion.getConexion();
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO becas (nombre, numero_control, semana_inicio, semana_fin, monto, saldo_restante) " +
            "VALUES (?, ?, ?, ?, ?, ?)"
        );
        ps.setString(1, nombre);
        ps.setString(2, numCtrl);
        ps.setDate(3, java.sql.Date.valueOf(semIni));
        ps.setDate(4, java.sql.Date.valueOf(semFin));
        ps.setDouble(5, monto);
        ps.setDouble(6, monto);
        ps.executeUpdate();
        con.close();
        msg = "Beca asignada correctamente a " + nombre;
        msgType = "ok";
    } catch (Exception ex) {
        msg = "Error: " + ex.getMessage();
        msgType = "error";
    }
}

// Cargar becas
List<Object[]> becas = new ArrayList<>();
Connection con = null;
try {
    con = Conexion.getConexion();
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, nombre, numero_control, semana_inicio, semana_fin, monto, saldo_restante, activa " +
        "FROM becas ORDER BY id DESC"
    );
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        becas.add(new Object[]{
            rs.getInt("id"),
            rs.getString("nombre"),
            rs.getString("numero_control"),
            rs.getString("semana_inicio"),
            rs.getString("semana_fin"),
            rs.getDouble("monto"),
            rs.getDouble("saldo_restante"),
            rs.getBoolean("activa")
        });
    }
} catch (Exception ex) {
    msg = "Error cargando becas: " + ex.getMessage();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gestión de Becas — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:650px;margin:24px auto;padding:0 20px;}
  .card{background:white;border-radius:16px;padding:24px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:16px;}
  .card h3{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:16px;}
  .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
  .form-group{margin-bottom:12px;}
  .form-group.full{grid-column:1/-1;}
  .form-group label{display:block;font-size:.8rem;font-weight:600;margin-bottom:5px;color:#7a5c3a;text-transform:uppercase;}
  .form-group input{width:100%;padding:10px 12px;border:2px solid var(--latte);border-radius:8px;font-family:inherit;font-size:.9rem;background:var(--foam);}
  .form-group input:focus{border-color:var(--caramel);background:white;outline:none;}
  .btn-submit{width:100%;padding:13px;background:var(--espresso);color:var(--cream);border:none;border-radius:10px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;margin-top:4px;}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .beca-card{background:white;border-radius:14px;padding:16px 20px;box-shadow:0 2px 10px rgba(44,26,14,.07);margin-bottom:10px;border-left:4px solid var(--caramel);}
  .beca-card.inactiva{border-left-color:#ccc;opacity:.7;}
  .beca-head{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px;}
  .beca-nombre{font-weight:700;font-size:.95rem;}
  .beca-ctrl{font-size:.78rem;color:#7a5c3a;margin-top:2px;}
  .chip-activa{background:#e8f5ee;color:var(--mint);padding:3px 10px;border-radius:20px;font-size:.75rem;font-weight:600;}
  .chip-vencida{background:#f5f5f5;color:#999;padding:3px 10px;border-radius:20px;font-size:.75rem;font-weight:600;}
  .beca-info{display:flex;gap:16px;font-size:.82rem;color:#7a5c3a;margin-bottom:8px;}
  .saldo-bar-container{background:var(--foam);border-radius:6px;height:8px;overflow:hidden;}
  .saldo-bar{height:100%;background:var(--mint);border-radius:6px;}
  .saldo-texto{display:flex;justify-content:space-between;font-size:.78rem;margin-top:4px;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">🎓 Gestión de Becas</span>
</div>
<div class="container">

  <% if (!msg.isEmpty()) { %>
  <div class="alert-<%= msgType %>"><%= "ok".equals(msgType) ? "✅" : "⚠️" %> <%= msg %></div>
  <% } %>

  <!-- Formulario nueva beca -->
  <div class="card">
    <h3>➕ Asignar nueva beca</h3>
    <form method="post">
      <div class="form-grid">
        <div class="form-group full">
          <label>Nombre del estudiante</label>
          <input type="text" name="nombre" placeholder="Nombre completo" required>
        </div>
        <div class="form-group">
          <label>Número de control</label>
          <input type="text" name="numero_control" placeholder="Ej. 22590343" required>
        </div>
        <div class="form-group">
          <label>Monto de beca ($)</label>
          <input type="number" name="monto" placeholder="500.00" step="0.01" value="500" required>
        </div>
        <div class="form-group">
          <label>Inicio de semana</label>
          <input type="date" name="semana_inicio" required>
        </div>
        <div class="form-group">
          <label>Fin de semana</label>
          <input type="date" name="semana_fin" required>
        </div>
      </div>
      <button type="submit" class="btn-submit">✅ Asignar beca</button>
    </form>
  </div>

  <!-- Lista de becas -->
  <div class="section-title">Becas registradas</div>

  <% if (becas.isEmpty()) { %>
  <div style="text-align:center;padding:30px;color:#b8a88a;">No hay becas registradas aún.</div>
  <% } else { for (Object[] b : becas) {
      int id = (int) b[0];
      String nombre = (String) b[1];
      String ctrl = (String) b[2];
      String ini = (String) b[3];
      String fin = (String) b[4];
      double monto = (double) b[5];
      double saldo = (double) b[6];
      boolean activa = (boolean) b[7];
      int pct = monto > 0 ? (int)(saldo * 100 / monto) : 0;
  %>
  <div class="beca-card <%= !activa ? "inactiva" : "" %>">
    <div class="beca-head">
      <div>
        <div class="beca-nombre">👤 <%= nombre %></div>
        <div class="beca-ctrl">N° Control: <%= ctrl %></div>
      </div>
      <span class="<%= activa ? "chip-activa" : "chip-vencida" %>">
        <%= activa ? "Activa" : "Vencida" %>
      </span>
    </div>
    <div class="beca-info">
      <span>📅 <%= ini %> al <%= fin %></span>
      <span>💰 Monto: $<%= String.format("%.2f", monto) %></span>
    </div>
    <div class="saldo-bar-container">
      <div class="saldo-bar" style="width:<%= pct %>%"></div>
    </div>
    <div class="saldo-texto">
      <span>Saldo restante: $<%= String.format("%.2f", saldo) %></span>
      <span><%= pct %>%</span>
    </div>
  </div>
  <% } } %>

</div>
</body>
</html>
