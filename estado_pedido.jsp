<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) { response.sendRedirect("login.jsp"); return; }

String idParam = request.getParameter("id");
int pedidoId   = 0;
try { pedidoId = Integer.parseInt(idParam); } catch (Exception e) {
    response.sendRedirect("menu.jsp"); return;
}

/* ── Consultar pedido en BD ─────────────────────────────── */
String  estado      = null;
String  metodoPago  = null;
double  total       = 0;
String  fecha       = null;
String  numStr      = null;
String  errorMsg    = null;

java.util.List<String[]> items = new java.util.ArrayList<>();

Connection con = null;
try {
    con = Conexion.getConexion();

    /* Solo puede ver sus propios pedidos (o admin ve todos) */
    String rol = (String) session.getAttribute("rol");
    String sql = "admin".equals(rol)
        ? "SELECT p.*, u.usuario FROM pedidos p JOIN usuarios u ON p.usuario_id = u.id WHERE p.id = ?"
        : "SELECT p.*, u.usuario FROM pedidos p JOIN usuarios u ON p.usuario_id = u.id WHERE p.id = ? AND p.usuario_id = ?";

    PreparedStatement ps = con.prepareStatement(sql);
    ps.setInt(1, pedidoId);
    if (!"admin".equals(rol)) ps.setInt(2, userId);
    ResultSet rs = ps.executeQuery();

    if (!rs.next()) {
        response.sendRedirect("menu.jsp?msg=pedido_no_encontrado"); return;
    }
    estado     = rs.getString("estado");
    metodoPago = rs.getString("metodo_pago");
    total      = rs.getDouble("total");
    fecha      = rs.getString("fecha");
    numStr     = String.format("%03d", rs.getInt("id"));

    /* Detalles del pedido */
    PreparedStatement det = con.prepareStatement(
        "SELECT nombre_prod, qty, precio_unit, subtotal FROM detalle_pedido WHERE pedido_id = ?"
    );
    det.setInt(1, pedidoId);
    ResultSet rd = det.executeQuery();
    while (rd.next()) {
        items.add(new String[]{
            rd.getString("nombre_prod"),
            rd.getString("qty"),
            String.format("$%.0f", rd.getDouble("precio_unit")),
            String.format("$%.0f", rd.getDouble("subtotal"))
        });
    }
} catch (Exception ex) {
    errorMsg = ex.getMessage();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

/* ── Iconos / etiquetas de estado ───────────────────────── */
String estIcon  = "🔥"; String estLabel = "En preparación"; String estColor = "#2C1A0E";
if ("listo".equals(estado))     { estIcon = "🔔"; estLabel = "Listo para recoger"; estColor = "#4a6cf7"; }
if ("entregado".equals(estado)) { estIcon = "✅"; estLabel = "Entregado";            estColor = "#4CAF82"; }

String metLabel = "tarjeta".equals(metodoPago) ? "💳 Pago con tarjeta" : "💵 Pago en efectivo";

/* Auto-refresh cada 15 s si no está entregado */
boolean autoRefresh = !"entregado".equals(estado);
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Estado Pedido #<%= numStr %> — Cafetería</title>
<% if (autoRefresh) { %><meta http-equiv="refresh" content="15"><% } %>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:480px;margin:24px auto;padding:0 20px;}
  .card{background:white;border-radius:18px;padding:24px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:16px;}
  .pedido-num{font-family:'Playfair Display',serif;font-size:2rem;color:var(--caramel);}
  .metodo-badge{background:var(--foam);border-radius:8px;padding:6px 12px;font-size:.85rem;font-weight:600;color:var(--espresso);display:inline-block;margin-top:8px;}
  .estado-bloque{text-align:center;padding:28px;}
  .estado-icon{font-size:3.5rem;margin-bottom:12px;display:block;}
  .estado-titulo{font-family:'Playfair Display',serif;font-size:1.3rem;margin-bottom:6px;}
  .estado-sub{color:#7a5c3a;font-size:.88rem;}
  .progress{height:6px;background:var(--foam);border-radius:3px;overflow:hidden;margin-top:16px;}
  .progress-bar{height:100%;width:50%;background:var(--caramel);border-radius:3px;animation:prog 2s ease-in-out infinite alternate;}
  @keyframes prog{from{width:30%}to{width:75%}}
  @keyframes pulse{0%,100%{transform:scale(1)}50%{transform:scale(1.08)}}
  table{width:100%;border-collapse:collapse;font-size:.88rem;}
  th{text-align:left;padding:6px 0;color:#7a5c3a;font-weight:600;border-bottom:1px solid var(--latte);}
  td{padding:8px 0;border-bottom:1px solid var(--foam);}
  td:last-child{text-align:right;font-weight:600;}
  .total-row td{font-size:1rem;font-weight:700;color:var(--caramel);padding-top:12px;}
  .btn{display:block;width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;text-decoration:none;text-align:center;margin-bottom:10px;transition:all .2s;}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .refresh-note{text-align:center;font-size:.78rem;color:#b8a88a;margin-bottom:16px;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:16px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="menu.jsp">←</a>
  <span class="topbar-title">Estado del Pedido</span>
</div>
<div class="container">

  <% if (errorMsg != null) { %>
  <div class="alert-error">⚠️ Error: <%= errorMsg %></div>
  <% } %>

  <!-- Número + método de pago -->
  <div class="card">
    <p style="font-size:.82rem;color:#7a5c3a;margin-bottom:4px">Pedido</p>
    <div class="pedido-num">#<%= numStr %></div>
    <div class="metodo-badge"><%= metLabel %></div>
    <div style="font-size:.78rem;color:#b8a88a;margin-top:6px"><%= fecha != null ? fecha : "" %></div>
  </div>

  <!-- Estado -->
  <div class="card estado-bloque">
    <%
      String animStyle = "preparacion".equals(estado) ? "pulse 1.5s infinite" : "none";
    %>
    <span class="estado-icon" style="animation:<%= animStyle %>">
      <%= estIcon %>
    </span>
    <div class="estado-titulo" style="color:<%= estColor %>"><%= estLabel %></div>
    <% if ("preparacion".equals(estado)) { %>
    <p class="estado-sub">Estamos preparando tu orden con cuidado &#9749;</p>
    <div class="progress"><div class="progress-bar"></div></div>
    <% } else if ("listo".equals(estado)) { %>
    <p class="estado-sub">Tu pedido está listo. ¡Pasa a recogerlo! 😊</p>
    <% } else { %>
    <p class="estado-sub">Tu pedido fue entregado. ¡Disfrútalo! 🎉</p>
    <% } %>
  </div>

  <!-- Detalle de items -->
  <% if (!items.isEmpty()) { %>
  <div class="card">
    <p style="font-weight:600;margin-bottom:12px">🧾 Detalle del pedido</p>
    <table>
      <tr><th>Producto</th><th>Cant.</th><th>P.Unit</th><th>Subtotal</th></tr>
      <% for (String[] it : items) { %>
      <tr>
        <td><%= it[0] %></td>
        <td><%= it[1] %></td>
        <td><%= it[2] %></td>
        <td><%= it[3] %></td>
      </tr>
      <% } %>
      <tr class="total-row">
        <td colspan="3">Total</td>
        <td>$<%= String.format("%.0f", total) %></td>
      </tr>
    </table>
  </div>
  <% } %>

  <% if (autoRefresh) { %>
  <p class="refresh-note">🔄 Esta página se actualiza automáticamente cada 15 segundos</p>
  <% } %>

  <a href="estado_pedido.jsp?id=<%= pedidoId %>" class="btn btn-caramel">🔄 Actualizar ahora</a>
  <a href="menu.jsp" class="btn btn-ghost">← Volver al menú</a>
</div>
</body>
</html>
