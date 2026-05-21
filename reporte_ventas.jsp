<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String periodo = request.getParameter("periodo");
if (periodo == null) periodo = "dia";

String fechaInicio = request.getParameter("inicio");
String fechaFin    = request.getParameter("fin");

java.time.LocalDate hoy = java.time.LocalDate.now();
if (fechaInicio == null || fechaInicio.isEmpty()) {
    if ("semana".equals(periodo)) {
        fechaInicio = hoy.minusDays(6).toString();
    } else if ("mes".equals(periodo)) {
        fechaInicio = hoy.withDayOfMonth(1).toString();
    } else {
        fechaInicio = hoy.toString();
    }
}
if (fechaFin == null || fechaFin.isEmpty()) fechaFin = hoy.toString();

List<Object[]> ventas = new ArrayList<>();
double totalVentas = 0;
int totalPedidos = 0;
List<Object[]> topProductos = new ArrayList<>();

Connection con = null;
try {
    con = Conexion.getConexion();

    // Ventas por día en el periodo
    PreparedStatement ps = con.prepareStatement(
        "SELECT DATE(fecha) as dia, COUNT(*) as num, SUM(total) as suma " +
        "FROM pedidos WHERE DATE(fecha) BETWEEN ?::date AND ?::date " +
        "GROUP BY DATE(fecha) ORDER BY dia DESC"
    );
    ps.setString(1, fechaInicio);
    ps.setString(2, fechaFin);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        ventas.add(new Object[]{
            rs.getString("dia"),
            rs.getInt("num"),
            rs.getDouble("suma")
        });
        totalVentas += rs.getDouble("suma");
        totalPedidos += rs.getInt("num");
    }

    // Top productos
    PreparedStatement ps2 = con.prepareStatement(
        "SELECT d.nombre_prod, SUM(d.qty) as total_qty, SUM(d.subtotal) as total_venta " +
        "FROM detalle_pedido d " +
        "JOIN pedidos p ON d.pedido_id = p.id " +
        "WHERE DATE(p.fecha) BETWEEN ?::date AND ?::date " +
        "GROUP BY d.nombre_prod ORDER BY total_qty DESC LIMIT 5"
    );
    ps2.setString(1, fechaInicio);
    ps2.setString(2, fechaFin);
    ResultSet rs2 = ps2.executeQuery();
    while (rs2.next()) {
        topProductos.add(new Object[]{
            rs2.getString("nombre_prod"),
            rs2.getInt("total_qty"),
            rs2.getDouble("total_venta")
        });
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
<title>Reporte de Ventas — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:650px;margin:24px auto;padding:0 20px;}
  .filtros{background:white;border-radius:14px;padding:16px 20px;margin-bottom:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .filtros-btns{display:flex;gap:8px;margin-bottom:12px;}
  .btn-periodo{padding:8px 16px;border:2px solid var(--latte);border-radius:8px;font-family:inherit;font-size:.85rem;font-weight:600;cursor:pointer;background:transparent;color:var(--espresso);}
  .btn-periodo.active{background:var(--espresso);color:var(--cream);border-color:var(--espresso);}
  .fecha-row{display:flex;gap:10px;align-items:center;}
  .fecha-row input{flex:1;padding:9px 12px;border:2px solid var(--latte);border-radius:8px;font-family:inherit;}
  .fecha-row button{padding:9px 18px;background:var(--caramel);color:white;border:none;border-radius:8px;font-family:inherit;font-weight:600;cursor:pointer;}
  .stats-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:20px;}
  .stat-card{background:white;border-radius:14px;padding:18px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .stat-label{font-size:.78rem;color:#7a5c3a;font-weight:600;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
  .stat-value{font-family:'Playfair Display',serif;font-size:1.8rem;color:var(--caramel);}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:12px;}
  .tabla{background:white;border-radius:14px;padding:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);margin-bottom:20px;}
  table{width:100%;border-collapse:collapse;}
  th{text-align:left;font-size:.78rem;color:#7a5c3a;text-transform:uppercase;letter-spacing:.5px;padding:8px 0;border-bottom:2px solid var(--latte);}
  td{padding:10px 0;border-bottom:1px solid var(--foam);font-size:.9rem;}
  tr:last-child td{border-bottom:none;}
  .badge-num{background:var(--foam);border-radius:6px;padding:2px 8px;font-size:.8rem;font-weight:600;}
  .top-bar{height:8px;background:var(--caramel);border-radius:4px;margin-top:4px;}
  @media print{.topbar,.filtros{display:none;}}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">📊 Reporte de Ventas</span>
</div>
<div class="container">

  <div class="filtros">
    <div class="filtros-btns">
      <a href="reporte_ventas.jsp?periodo=dia"><button class="btn-periodo <%= "dia".equals(periodo) ? "active" : "" %>">Hoy</button></a>
      <a href="reporte_ventas.jsp?periodo=semana"><button class="btn-periodo <%= "semana".equals(periodo) ? "active" : "" %>">Semana</button></a>
      <a href="reporte_ventas.jsp?periodo=mes"><button class="btn-periodo <%= "mes".equals(periodo) ? "active" : "" %>">Mes</button></a>
    </div>
    <form method="get" class="fecha-row">
      <input type="hidden" name="periodo" value="custom">
      <input type="date" name="inicio" value="<%= fechaInicio %>">
      <span>a</span>
      <input type="date" name="fin" value="<%= fechaFin %>">
      <button type="submit">Ver</button>
    </form>
  </div>

  <div class="stats-row">
    <div class="stat-card">
      <div class="stat-label">Total ventas</div>
      <div class="stat-value">$<%= String.format("%.0f", totalVentas) %></div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Pedidos</div>
      <div class="stat-value"><%= totalPedidos %></div>
    </div>
  </div>

  <div class="tabla">
    <div class="section-title">Ventas por día</div>
    <table>
      <tr><th>Fecha</th><th>Pedidos</th><th>Total</th></tr>
      <% if (ventas.isEmpty()) { %>
      <tr><td colspan="3" style="text-align:center;color:#b8a88a;padding:20px">Sin ventas en este periodo</td></tr>
      <% } else { for (Object[] v : ventas) { %>
      <tr>
        <td><%= v[0] %></td>
        <td><span class="badge-num"><%= v[1] %></span></td>
        <td><strong>$<%= String.format("%.2f", v[2]) %></strong></td>
      </tr>
      <% } } %>
    </table>
  </div>

  <% if (!topProductos.isEmpty()) { %>
  <div class="tabla">
    <div class="section-title">🏆 Top productos</div>
    <table>
      <tr><th>Producto</th><th>Vendidos</th><th>Total</th></tr>
      <% int maxQty = topProductos.isEmpty() ? 1 : (int)topProductos.get(0)[1];
         for (Object[] p : topProductos) { %>
      <tr>
        <td><%= p[0] %></td>
        <td><span class="badge-num"><%= p[1] %></span></td>
        <td>$<%= String.format("%.2f", p[2]) %></td>
      </tr>
      <% } %>
    </table>
  </div>
  <% } %>

</div>
</body>
</html>
