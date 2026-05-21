<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

// Actualizar vigencia automáticamente
Connection con = null;
try {
    con = Conexion.getConexion();
    PreparedStatement upd = con.prepareStatement(
        "UPDATE becas SET activa = false WHERE fecha_fin < CURRENT_DATE AND activa = true"
    );
    upd.executeUpdate();
} catch (Exception ex) {}

List<Object[]> activas = new ArrayList<>();
List<Object[]> vencidas = new ArrayList<>();

try {
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, nombre, numero_control, fecha_inicio, fecha_fin, monto, saldo_restante, activa, " +
        "(fecha_fin - CURRENT_DATE) as dias_restantes " +
        "FROM becas ORDER BY activa DESC, fecha_fin ASC"
    );
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        Object[] row = new Object[]{
            rs.getInt("id"),
            rs.getString("nombre"),
            rs.getString("numero_control"),
            rs.getString("fecha_inicio"),
            rs.getString("fecha_fin"),
            rs.getDouble("monto"),
            rs.getDouble("saldo_restante"),
            rs.getBoolean("activa"),
            rs.getInt("dias_restantes")
        };
        if (rs.getBoolean("activa")) activas.add(row);
        else vencidas.add(row);
    }
} catch (Exception ex) {
    out.println("Error: " + ex.getMessage());
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Vigencia de Becas — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:650px;margin:24px auto;padding:0 20px;}
  .stats-row{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-bottom:20px;}
  .stat-card{background:white;border-radius:14px;padding:16px;box-shadow:0 2px 10px rgba(44,26,14,.07);text-align:center;}
  .stat-num{font-family:'Playfair Display',serif;font-size:2rem;}
  .stat-num.green{color:var(--mint);}
  .stat-num.red{color:var(--danger);}
  .stat-num.orange{color:var(--caramel);}
  .stat-label{font-size:.75rem;color:#7a5c3a;margin-top:4px;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:12px;}
  .beca-row{background:white;border-radius:12px;padding:14px 18px;margin-bottom:8px;box-shadow:0 2px 8px rgba(44,26,14,.06);display:flex;justify-content:space-between;align-items:center;}
  .beca-row.por-vencer{border-left:4px solid var(--caramel);}
  .beca-row.vencida{border-left:4px solid #ddd;opacity:.65;}
  .beca-info .nombre{font-weight:700;font-size:.92rem;}
  .beca-info .ctrl{font-size:.78rem;color:#7a5c3a;}
  .beca-info .fechas{font-size:.78rem;color:#7a5c3a;margin-top:4px;}
  .dias-badge{padding:4px 12px;border-radius:20px;font-size:.78rem;font-weight:700;text-align:center;}
  .dias-ok{background:#e8f5ee;color:var(--mint);}
  .dias-warn{background:#fff3e0;color:#e65100;}
  .dias-vencida{background:#f5f5f5;color:#999;}
  .separador{height:1px;background:var(--latte);margin:20px 0;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">📋 Vigencia de Becas</span>
</div>
<div class="container">

  <div class="stats-row">
    <div class="stat-card">
      <div class="stat-num green"><%= activas.size() %></div>
      <div class="stat-label">Becas activas</div>
    </div>
    <div class="stat-card">
      <div class="stat-num red"><%= vencidas.size() %></div>
      <div class="stat-label">Becas vencidas</div>
    </div>
    <div class="stat-card">
      <div class="stat-num orange"><%= activas.size() + vencidas.size() %></div>
      <div class="stat-label">Total becas</div>
    </div>
  </div>

  <!-- Becas activas -->
  <div class="section-title">✅ Becas activas (<%= activas.size() %>)</div>
  <% if (activas.isEmpty()) { %>
  <p style="color:#b8a88a;margin-bottom:20px;">No hay becas activas.</p>
  <% } else { for (Object[] b : activas) {
      int diasRestantes = (int) b[8];
      boolean porVencer = diasRestantes <= 2;
  %>
  <div class="beca-row <%= porVencer ? "por-vencer" : "" %>">
    <div class="beca-info">
      <div class="nombre">👤 <%= b[1] %></div>
      <div class="ctrl">N° Control: <%= b[2] %></div>
      <div class="fechas">📅 <%= b[3] %> al <%= b[4] %> &nbsp;·&nbsp; Saldo: $<%= String.format("%.2f", b[6]) %></div>
    </div>
    <div class="dias-badge <%= porVencer ? "dias-warn" : "dias-ok" %>">
      <%= diasRestantes <= 0 ? "Hoy vence" : diasRestantes + " días" %>
    </div>
  </div>
  <% } } %>

  <div class="separador"></div>

  <!-- Becas vencidas -->
  <div class="section-title">❌ Becas vencidas (<%= vencidas.size() %>)</div>
  <% if (vencidas.isEmpty()) { %>
  <p style="color:#b8a88a;">No hay becas vencidas.</p>
  <% } else { for (Object[] b : vencidas) { %>
  <div class="beca-row vencida">
    <div class="beca-info">
      <div class="nombre">👤 <%= b[1] %></div>
      <div class="ctrl">N° Control: <%= b[2] %></div>
      <div class="fechas">📅 <%= b[3] %> al <%= b[4] %> &nbsp;·&nbsp; Saldo usado: $<%= String.format("%.2f", (double)b[5] - (double)b[6]) %></div>
    </div>
    <div class="dias-badge dias-vencida">Vencida</div>
  </div>
  <% } } %>

</div>
</body>
</html>
