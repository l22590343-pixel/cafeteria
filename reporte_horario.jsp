<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String fecha = request.getParameter("fecha");
if (fecha == null || fecha.isEmpty()) fecha = java.time.LocalDate.now().toString();

// Ventas por hora
List<Object[]> porHora = new ArrayList<>();
double totalManana = 0, totalTarde = 0;
int pedidosManana = 0, pedidosTarde = 0;

Connection con = null;
try {
    con = Conexion.getConexion();
    PreparedStatement ps = con.prepareStatement(
        "SELECT EXTRACT(HOUR FROM fecha) as hora, COUNT(*) as num, SUM(total) as suma " +
        "FROM pedidos WHERE DATE(fecha) = ?::date " +
        "AND EXTRACT(HOUR FROM fecha) >= 7 AND EXTRACT(HOUR FROM fecha) < 19 " +
        "GROUP BY hora ORDER BY hora"
    );
    ps.setString(1, fecha);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        int hora = rs.getInt("hora");
        int num = rs.getInt("num");
        double suma = rs.getDouble("suma");
        porHora.add(new Object[]{hora, num, suma});
        if (hora < 13) { totalManana += suma; pedidosManana += num; }
        else { totalTarde += suma; pedidosTarde += num; }
    }
} catch (Exception ex) {
    out.println("Error: " + ex.getMessage());
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

double maxVenta = 0;
for (Object[] h : porHora) {
    if ((double)h[2] > maxVenta) maxVenta = (double)h[2];
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reporte por Horario — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:600px;margin:24px auto;padding:0 20px;}
  .fecha-form{background:white;border-radius:14px;padding:16px 20px;margin-bottom:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);display:flex;gap:12px;align-items:center;}
  .fecha-form input{flex:1;padding:10px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;}
  .fecha-form button{padding:10px 20px;background:var(--caramel);color:white;border:none;border-radius:10px;font-family:inherit;font-weight:600;cursor:pointer;}
  .turnos{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:20px;}
  .turno-card{background:white;border-radius:14px;padding:18px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .turno-titulo{font-weight:700;font-size:.9rem;margin-bottom:4px;}
  .turno-horario{font-size:.78rem;color:#7a5c3a;margin-bottom:10px;}
  .turno-total{font-family:'Playfair Display',serif;font-size:1.5rem;color:var(--caramel);}
  .turno-pedidos{font-size:.8rem;color:#7a5c3a;margin-top:4px;}
  .tabla{background:white;border-radius:14px;padding:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;}
  .hora-row{display:flex;align-items:center;gap:12px;padding:8px 0;border-bottom:1px solid var(--foam);}
  .hora-row:last-child{border-bottom:none;}
  .hora-label{width:80px;font-size:.85rem;font-weight:600;color:#7a5c3a;}
  .hora-bar-container{flex:1;background:var(--foam);border-radius:6px;height:20px;overflow:hidden;}
  .hora-bar{height:100%;background:var(--caramel);border-radius:6px;transition:width .3s;}
  .hora-bar.manana{background:var(--caramel);}
  .hora-bar.tarde{background:var(--mint);}
  .hora-valor{width:80px;text-align:right;font-size:.85rem;font-weight:600;}
  .hora-num{width:30px;text-align:center;font-size:.75rem;background:var(--foam);border-radius:4px;padding:2px 4px;}
  .empty{text-align:center;padding:30px;color:#b8a88a;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">⏰ Reporte por Horario</span>
</div>
<div class="container">

  <form class="fecha-form" method="get">
    <input type="date" name="fecha" value="<%= fecha %>">
    <button type="submit">Ver</button>
  </form>

  <div class="turnos">
    <div class="turno-card">
      <div class="turno-titulo">☀️ Turno Mañana</div>
      <div class="turno-horario">7:00 AM — 1:00 PM</div>
      <div class="turno-total">$<%= String.format("%.2f", totalManana) %></div>
      <div class="turno-pedidos"><%= pedidosManana %> pedidos</div>
    </div>
    <div class="turno-card">
      <div class="turno-titulo">🌤️ Turno Tarde</div>
      <div class="turno-horario">1:00 PM — 7:00 PM</div>
      <div class="turno-total">$<%= String.format("%.2f", totalTarde) %></div>
      <div class="turno-pedidos"><%= pedidosTarde %> pedidos</div>
    </div>
  </div>

  <div class="tabla">
    <div class="section-title">Ventas por hora</div>
    <% if (porHora.isEmpty()) { %>
    <div class="empty">Sin ventas registradas para esta fecha</div>
    <% } else { for (Object[] h : porHora) {
        int hora = ((Number)h[0]).intValue();
        int num = ((Number)h[1]).intValue();
        double suma = (double)h[2];
        int pct = maxVenta > 0 ? (int)(suma * 100 / maxVenta) : 0;
        boolean esManana = hora < 13;
        String horaStr = hora + ":00 " + (hora < 12 ? "AM" : "PM");
    %>
    <div class="hora-row">
      <div class="hora-label"><%= horaStr %></div>
      <div class="hora-bar-container">
        <div class="hora-bar <%= esManana ? "manana" : "tarde" %>" style="width:<%= pct %>%"></div>
      </div>
      <div class="hora-num"><%= num %></div>
      <div class="hora-valor">$<%= String.format("%.0f", suma) %></div>
    </div>
    <% } } %>
  </div>

</div>
</body>
</html>
