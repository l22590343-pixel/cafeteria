<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String fecha = request.getParameter("fecha");
if (fecha == null || fecha.isEmpty()) fecha = java.time.LocalDate.now().toString();

List<Object[]> movimientos = new ArrayList<>();
Connection con = null;
try {
    con = Conexion.getConexion();
    PreparedStatement ps = con.prepareStatement(
        "SELECT p.id, p.fecha, p.estado, p.total, p.metodo_pago, u.usuario, " +
        "string_agg(d.nombre_prod || ' x' || d.qty, ', ') as productos " +
        "FROM pedidos p " +
        "JOIN usuarios u ON p.usuario_id = u.id " +
        "LEFT JOIN detalle_pedido d ON d.pedido_id = p.id " +
        "WHERE DATE(p.fecha) = ? " +
        "GROUP BY p.id, p.fecha, p.estado, p.total, p.metodo_pago, u.usuario " +
        "ORDER BY p.fecha DESC"
    );
    ps.setString(1, fecha);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        movimientos.add(new Object[]{
            rs.getInt("id"),
            rs.getString("fecha"),
            rs.getString("estado"),
            rs.getDouble("total"),
            rs.getString("metodo_pago"),
            rs.getString("usuario"),
            rs.getString("productos")
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
<title>Movimientos — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:680px;margin:24px auto;padding:0 20px;}
  .fecha-form{background:white;border-radius:14px;padding:14px 20px;margin-bottom:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);display:flex;gap:12px;align-items:center;}
  .fecha-form input{flex:1;padding:9px 12px;border:2px solid var(--latte);border-radius:8px;font-family:inherit;}
  .fecha-form button{padding:9px 18px;background:var(--caramel);color:white;border:none;border-radius:8px;font-family:inherit;font-weight:600;cursor:pointer;}
  .mov-card{background:white;border-radius:12px;padding:14px 18px;margin-bottom:8px;box-shadow:0 2px 8px rgba(44,26,14,.06);}
  .mov-head{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:6px;}
  .mov-id{font-weight:700;color:var(--caramel);font-size:.92rem;}
  .mov-hora{font-size:.78rem;color:#7a5c3a;}
  .mov-productos{font-size:.83rem;color:#5a3e2a;margin-bottom:6px;line-height:1.5;}
  .mov-footer{display:flex;gap:12px;font-size:.8rem;color:#7a5c3a;}
  .chip{padding:2px 8px;border-radius:6px;font-size:.75rem;font-weight:600;}
  .chip-prep{background:#fef3e2;color:#c8864a;}
  .chip-listo{background:#e8ecff;color:#4a6cf7;}
  .chip-ent{background:#e8f5ee;color:#4caf82;}
  .total-badge{font-weight:700;color:var(--espresso);}
  .empty{text-align:center;padding:40px;color:#b8a88a;}
  .count-badge{background:var(--foam);border-radius:8px;padding:6px 14px;font-size:.85rem;margin-bottom:14px;display:inline-block;}
  @media print{.topbar,.fecha-form{display:none;}}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">📦 Registro de Movimientos</span>
</div>
<div class="container">

  <form class="fecha-form" method="get">
    <input type="date" name="fecha" value="<%= fecha %>">
    <button type="submit">Ver</button>
  </form>

  <div class="count-badge"><%= movimientos.size() %> movimientos del <%= fecha %></div>

  <% if (movimientos.isEmpty()) { %>
  <div class="empty">
    <div style="font-size:2.5rem;margin-bottom:8px">📋</div>
    <p>No hay movimientos para esta fecha.</p>
  </div>
  <% } else { for (Object[] m : movimientos) {
      int pid = (int) m[0];
      String fechaHora = (String) m[1];
      String estado = (String) m[2];
      double total = (double) m[3];
      String metodo = (String) m[4];
      String usuario = (String) m[5];
      String productos = m[6] != null ? (String) m[6] : "Sin detalle";
      String chipCls = "preparacion".equals(estado) ? "chip-prep" : "listo".equals(estado) ? "chip-listo" : "chip-ent";
      String estLabel = "preparacion".equals(estado) ? "En prep." : "listo".equals(estado) ? "Listo" : "Entregado";
      String hora = fechaHora.length() > 10 ? fechaHora.substring(11, 16) : fechaHora;
  %>
  <div class="mov-card">
    <div class="mov-head">
      <span class="mov-id">Pedido #<%= String.format("%03d", pid) %></span>
      <span class="mov-hora">🕐 <%= hora %></span>
    </div>
    <div class="mov-productos">🛒 <%= productos %></div>
    <div class="mov-footer">
      <span>👤 <%= usuario %></span>
      <span><%= "tarjeta".equals(metodo) ? "💳" : "💵" %> <%= "tarjeta".equals(metodo) ? "Tarjeta" : "Efectivo" %></span>
      <span class="chip <%= chipCls %>"><%= estLabel %></span>
      <span class="total-badge">$<%= String.format("%.2f", total) %></span>
    </div>
  </div>
  <% } } %>

</div>
</body>
</html>
