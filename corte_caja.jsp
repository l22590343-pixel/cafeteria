<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

// Fecha seleccionada (hoy por defecto)
String fecha = request.getParameter("fecha");
if (fecha == null || fecha.isEmpty()) {
    java.time.LocalDate hoy = java.time.LocalDate.now();
    fecha = hoy.toString();
}

double totalEfectivo = 0, totalTarjeta = 0, totalBeca = 0, totalGeneral = 0;
int numPedidos = 0, numEntregados = 0;

Connection con = null;
try {
    con = Conexion.getConexion();

    // Total por método de pago (7am - 7pm)
    PreparedStatement ps = con.prepareStatement(
        "SELECT metodo_pago, COUNT(*) as num, SUM(total) as suma " +
        "FROM pedidos " +
        "WHERE DATE(fecha) = ?::date " +
        "AND EXTRACT(HOUR FROM fecha) >= 7 AND EXTRACT(HOUR FROM fecha) < 19 " +
        "GROUP BY metodo_pago"
    );
    ps.setString(1, fecha);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        String metodo = rs.getString("metodo_pago");
        double suma = rs.getDouble("suma");
        int num = rs.getInt("num");
        numPedidos += num;
        if ("efectivo".equals(metodo)) { totalEfectivo = suma; }
        else if ("tarjeta".equals(metodo)) { totalTarjeta = suma; }
        else if ("beca".equals(metodo)) { totalBeca = suma; }
    }
    totalGeneral = totalEfectivo + totalTarjeta + totalBeca;

    // Pedidos entregados
    PreparedStatement ps2 = con.prepareStatement(
        "SELECT COUNT(*) FROM pedidos WHERE DATE(fecha) = ?::date AND estado = 'entregado'::estado_tipo"
    );
    ps2.setString(1, fecha);
    ResultSet rs2 = ps2.executeQuery();
    if (rs2.next()) numEntregados = rs2.getInt(1);

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
<title>Corte de Caja — Cafetería</title>
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
  .fecha-form input{flex:1;padding:10px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.95rem;}
  .fecha-form button{padding:10px 20px;background:var(--caramel);color:white;border:none;border-radius:10px;font-family:inherit;font-weight:600;cursor:pointer;}
  .resumen-titulo{font-family:'Playfair Display',serif;font-size:1.3rem;margin-bottom:16px;}
  .turno-badge{background:var(--foam);border-radius:10px;padding:8px 16px;font-size:.85rem;color:#7a5c3a;margin-bottom:20px;display:inline-block;}
  .cards-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:20px;}
  .stat-card{background:white;border-radius:14px;padding:18px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .stat-label{font-size:.78rem;color:#7a5c3a;font-weight:600;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
  .stat-value{font-family:'Playfair Display',serif;font-size:1.6rem;color:var(--caramel);}
  .stat-value.green{color:var(--mint);}
  .total-card{background:var(--espresso);color:var(--cream);border-radius:16px;padding:24px;margin-bottom:20px;text-align:center;}
  .total-label{font-size:.9rem;opacity:.7;margin-bottom:8px;}
  .total-amount{font-family:'Playfair Display',serif;font-size:2.5rem;color:var(--latte);}
  .desglose{background:white;border-radius:14px;padding:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .desglose h3{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;}
  .desglose-row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--foam);font-size:.92rem;}
  .desglose-row:last-child{border-bottom:none;font-weight:700;font-size:1rem;}
  .btn-print{width:100%;padding:14px;background:var(--caramel);color:white;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;margin-top:16px;}
  @media print{.topbar,.fecha-form,.btn-print{display:none;}}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">💰 Corte de Caja</span>
</div>
<div class="container">

  <form class="fecha-form" method="get">
    <input type="date" name="fecha" value="<%= fecha %>">
    <button type="submit">Ver corte</button>
  </form>

  <div class="resumen-titulo">Corte del <%= fecha %></div>
  <div class="turno-badge">🕐 Turno: 7:00 AM — 7:00 PM</div>

  <div class="total-card">
    <div class="total-label">TOTAL DEL DÍA</div>
    <div class="total-amount">$<%= String.format("%.2f", totalGeneral) %></div>
  </div>

  <div class="cards-grid">
    <div class="stat-card">
      <div class="stat-label">Total pedidos</div>
      <div class="stat-value"><%= numPedidos %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Entregados</div>
      <div class="stat-value green"><%= numEntregados %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Efectivo</div>
      <div class="stat-value">$<%= String.format("%.2f", totalEfectivo) %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Tarjeta</div>
      <div class="stat-value">$<%= String.format("%.2f", totalTarjeta) %></div>
    </div>
  </div>

  <div class="desglose">
    <h3>Desglose</h3>
    <div class="desglose-row"><span>💵 Efectivo</span><span>$<%= String.format("%.2f", totalEfectivo) %></span></div>
    <div class="desglose-row"><span>💳 Tarjeta</span><span>$<%= String.format("%.2f", totalTarjeta) %></span></div>
    <div class="desglose-row"><span>🎓 Becas</span><span>$<%= String.format("%.2f", totalBeca) %></span></div>
    <div class="desglose-row"><span>TOTAL</span><span>$<%= String.format("%.2f", totalGeneral) %></span></div>
  </div>

  <button class="btn-print" onclick="window.print()">🖨️ Imprimir corte</button>
</div>
</body>
</html>
