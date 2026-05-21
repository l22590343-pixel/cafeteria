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
    String nombre  = request.getParameter("nombre");
    String numCtrl = request.getParameter("numero_control");
    String inicio  = request.getParameter("fecha_inicio");
    String fin     = request.getParameter("fecha_fin");

    try {
        Connection con = Conexion.getConexion();
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO becas (nombre, numero_control, fecha_inicio, fecha_fin) VALUES (?, ?, ?, ?)"
        );
        ps.setString(1, nombre.trim());
        ps.setString(2, numCtrl.trim());
        ps.setDate(3, java.sql.Date.valueOf(inicio));
        ps.setDate(4, java.sql.Date.valueOf(fin));
        ps.executeUpdate();
        con.close();
        msg = "Beca asignada a " + nombre;
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
        "SELECT b.id, b.nombre, b.numero_control, b.fecha_inicio, b.fecha_fin, b.activa, " +
        "COUNT(a.id) as dias_tomados " +
        "FROM becas b LEFT JOIN asistencia_becas a ON a.beca_id = b.id " +
        "GROUP BY b.id, b.nombre, b.numero_control, b.fecha_inicio, b.fecha_fin, b.activa " +
        "ORDER BY b.activa DESC, b.nombre ASC"
    );
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        becas.add(new Object[]{
            rs.getInt("id"),
            rs.getString("nombre"),
            rs.getString("numero_control"),
            rs.getString("fecha_inicio"),
            rs.getString("fecha_fin"),
            rs.getBoolean("activa"),
            rs.getInt("dias_tomados")
        });
    }
} catch (Exception ex) {
    msg = "Error cargando becas: " + ex.getMessage();
    msgType = "error";
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

// Calcular fecha fin por defecto (6 meses desde hoy)
java.time.LocalDate hoy = java.time.LocalDate.now();
String fechaInicioDefault = hoy.toString();
String fechaFinDefault = hoy.plusMonths(6).toString();
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
  .container{max-width:680px;margin:24px auto;padding:0 20px;}
  .card{background:white;border-radius:16px;padding:24px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:20px;}
  .card h3{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:16px;color:var(--espresso);}
  .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
  .form-group{margin-bottom:4px;}
  .form-group.full{grid-column:1/-1;}
  .form-group label{display:block;font-size:.78rem;font-weight:700;margin-bottom:5px;color:#7a5c3a;text-transform:uppercase;letter-spacing:.4px;}
  .form-group input{width:100%;padding:11px 13px;border:2px solid var(--latte);border-radius:9px;font-family:inherit;font-size:.92rem;background:var(--foam);outline:none;transition:border .2s;}
  .form-group input:focus{border-color:var(--caramel);background:white;}
  .btn-submit{width:100%;padding:14px;background:var(--espresso);color:var(--cream);border:none;border-radius:11px;font-family:inherit;font-size:.95rem;font-weight:700;cursor:pointer;margin-top:8px;transition:background .2s;}
  .btn-submit:hover{background:#1a0f05;}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;}
  .search-bar{display:flex;gap:10px;margin-bottom:16px;}
  .search-bar input{flex:1;padding:10px 14px;border:2px solid var(--latte);border-radius:9px;font-family:inherit;font-size:.9rem;background:var(--foam);outline:none;}
  .search-bar input:focus{border-color:var(--caramel);}
  table{width:100%;border-collapse:collapse;background:white;border-radius:14px;overflow:hidden;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  th{background:var(--espresso);color:var(--cream);padding:11px 12px;text-align:left;font-size:.78rem;font-weight:600;text-transform:uppercase;letter-spacing:.3px;}
  td{padding:11px 12px;border-bottom:1px solid var(--foam);font-size:.85rem;vertical-align:middle;}
  tr:last-child td{border-bottom:none;}
  tr:hover td{background:var(--foam);}
  .chip-activa{background:#e8f5ee;color:var(--mint);padding:3px 10px;border-radius:20px;font-size:.75rem;font-weight:700;}
  .chip-vencida{background:#f5f5f5;color:#999;padding:3px 10px;border-radius:20px;font-size:.75rem;font-weight:700;}
  .dias-badge{background:var(--foam);border-radius:6px;padding:2px 8px;font-size:.8rem;font-weight:700;color:var(--espresso);}
  .btn-eliminar{background:none;border:none;cursor:pointer;color:#ccc;font-size:1rem;padding:4px;border-radius:6px;}
  .btn-eliminar:hover{color:var(--danger);background:#fdecea;}
  .empty{text-align:center;padding:30px;color:#b8a88a;font-size:.9rem;}
  .stats-mini{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:20px;}
  .stat-mini{background:white;border-radius:12px;padding:14px;text-align:center;box-shadow:0 2px 8px rgba(44,26,14,.07);}
  .stat-mini-num{font-family:'Playfair Display',serif;font-size:1.6rem;color:var(--caramel);}
  .stat-mini-label{font-size:.72rem;color:#7a5c3a;margin-top:2px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">🎓 Gestión de Becas</span>
</div>
<div class="container">

  <% if (!msg.isEmpty()) { %>
  <div class="alert-<%= msgType %>">
    <%= "ok".equals(msgType) ? "✅" : "⚠️" %> <%= msg %>
  </div>
  <% } %>

  <%
  int totalActivas = 0, totalVencidas = 0, totalDias = 0;
  for (Object[] b : becas) {
      if ((boolean)b[5]) totalActivas++; else totalVencidas++;
      totalDias += (int)b[6];
  }
  %>
  <div class="stats-mini">
    <div class="stat-mini">
      <div class="stat-mini-num"><%= totalActivas %></div>
      <div class="stat-mini-label">Becas activas</div>
    </div>
    <div class="stat-mini">
      <div class="stat-mini-num"><%= totalVencidas %></div>
      <div class="stat-mini-label">Vencidas</div>
    </div>
    <div class="stat-mini">
      <div class="stat-mini-num"><%= totalDias %></div>
      <div class="stat-mini-label">Días tomados</div>
    </div>
  </div>

  <!-- Formulario -->
  <div class="card">
    <h3>➕ Dar de alta nuevo estudiante</h3>
    <form method="post">
      <div class="form-grid">
        <div class="form-group full">
          <label>Nombre completo del estudiante</label>
          <input type="text" name="nombre" placeholder="Ej. Juan García López" required>
        </div>
        <div class="form-group">
          <label>Número de control</label>
          <input type="text" name="numero_control" placeholder="Ej. 22590343" required>
        </div>
        <div class="form-group">
          <label>Inicio del semestre</label>
          <input type="date" name="fecha_inicio" value="<%= fechaInicioDefault %>" required>
        </div>
        <div class="form-group">
          <label>Fin del semestre</label>
          <input type="date" name="fecha_fin" value="<%= fechaFinDefault %>" required>
        </div>
      </div>
      <button type="submit" class="btn-submit">✅ Dar de alta</button>
    </form>
  </div>

  <!-- Tabla de estudiantes -->
  <div class="section-title">📋 Estudiantes con beca (<%= becas.size() %>)</div>

  <% if (becas.isEmpty()) { %>
  <div class="empty">No hay estudiantes registrados aún.</div>
  <% } else { %>
  <table>
    <thead>
      <tr>
        <th>Nombre</th>
        <th>N° Control</th>
        <th>Vigencia</th>
        <th>Días tomados</th>
        <th>Estado</th>
      </tr>
    </thead>
    <tbody>
      <% for (Object[] b : becas) { %>
      <tr>
        <td><strong><%= b[1] %></strong></td>
        <td style="font-family:monospace;font-size:.88rem"><%= b[2] %></td>
        <td style="font-size:.78rem;color:#7a5c3a"><%= b[3] %><br>al <%= b[4] %></td>
        <td><span class="dias-badge"><%= b[6] %> días</span></td>
        <td><span class="<%= (boolean)b[5] ? "chip-activa" : "chip-vencida" %>">
          <%= (boolean)b[5] ? "Activa" : "Vencida" %>
        </span></td>
      </tr>
      <% } %>
    </tbody>
  </table>
  <% } %>

</div>
</body>
</html>
