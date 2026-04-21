<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Solo admin ─────────────────────────────────────────── */
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String msg = "";

/* ── POST: cambiar estado ───────────────────────────────── */
if ("POST".equals(request.getMethod())) {
    String pidStr   = request.getParameter("pedido_id");
    String nuevoEst = request.getParameter("estado");
    try {
        int pid = Integer.parseInt(pidStr);
        if (nuevoEst != null && nuevoEst.matches("preparacion|listo|entregado")) {
            Connection con = null;
            try {
                con = Conexion.getConexion();
                PreparedStatement ps = con.prepareStatement(
                    "UPDATE pedidos SET estado = ?::estado_tipo WHERE id = ?"
                );
                ps.setString(1, nuevoEst);
                ps.setInt(2, pid);
                ps.executeUpdate();
                msg = "ok:" + pid;
            } finally {
                if (con != null) try { con.close(); } catch (Exception ignored) {}
            }
        }
    } catch (Exception ex) {
        msg = "error:" + ex.getMessage();
    }
}

/* ── Cargar pedidos con sus productos ───────────────────── */
java.util.LinkedHashMap<Integer, Object[]> pedidosMap = new java.util.LinkedHashMap<>();
java.util.HashMap<Integer, java.util.List<String>> detallesMap = new java.util.HashMap<>();

Connection con = null;
try {
    con = Conexion.getConexion();

    /* Cargar pedidos */
    PreparedStatement ps = con.prepareStatement(
        "SELECT p.id, p.estado, p.metodo_pago, p.total, p.fecha, u.usuario " +
        "FROM pedidos p JOIN usuarios u ON p.usuario_id = u.id " +
        "ORDER BY p.id DESC"
    );
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        int pid = rs.getInt("id");
        pedidosMap.put(pid, new Object[]{
            pid,
            rs.getString("estado"),
            rs.getString("metodo_pago"),
            rs.getDouble("total"),
            rs.getString("fecha"),
            rs.getString("usuario")
        });
        detallesMap.put(pid, new java.util.ArrayList<String>());
    }

    /* Cargar detalles de productos */
    PreparedStatement ps2 = con.prepareStatement(
        "SELECT pedido_id, nombre_prod, qty, subtotal FROM detalle_pedido ORDER BY pedido_id DESC"
    );
    ResultSet rs2 = ps2.executeQuery();
    while (rs2.next()) {
        int pid = rs2.getInt("pedido_id");
        if (detallesMap.containsKey(pid)) {
            String linea = rs2.getInt("qty") + "x " + rs2.getString("nombre_prod")
                         + " ($" + String.format("%.0f", rs2.getDouble("subtotal")) + ")";
            detallesMap.get(pid).add(linea);
        }
    }

} catch (Exception ex) {
    msg = "error:" + ex.getMessage();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gestión de Pedidos — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:600px;margin:24px auto;padding:0 20px;}
  .card{background:white;border-radius:16px;padding:20px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:14px;}
  .pedido-head{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px;}
  .pedido-id{font-family:'Playfair Display',serif;font-size:1.1rem;color:var(--caramel);}
  .chip{display:inline-block;padding:4px 10px;border-radius:20px;font-size:.78rem;font-weight:600;}
  .chip-prep{background:#fef3e2;color:var(--espresso);}
  .chip-listo{background:#e8ecff;color:#4a6cf7;}
  .chip-ent{background:#e8f5ee;color:var(--mint);}
  .pedido-info{font-size:.82rem;color:#7a5c3a;margin-bottom:8px;line-height:1.6;}
  .productos-lista{background:var(--foam);border-radius:10px;padding:10px 14px;margin-bottom:12px;}
  .productos-title{font-size:.75rem;font-weight:700;color:#7a5c3a;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
  .producto-item{font-size:.85rem;color:var(--espresso);padding:3px 0;border-bottom:1px solid var(--latte);}
  .producto-item:last-child{border-bottom:none;}
  .estado-btns{display:flex;gap:8px;flex-wrap:wrap;}
  .btn-est{padding:8px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.82rem;font-weight:600;cursor:pointer;background:transparent;color:var(--espresso);transition:all .2s;}
  .btn-est:hover{border-color:var(--caramel);background:var(--foam);}
  .btn-est.active-prep{background:#fef3e2;border-color:var(--caramel);color:var(--espresso);}
  .btn-est.active-listo{background:#e8ecff;border-color:#4a6cf7;color:#4a6cf7;}
  .btn-est.active-ent{background:#e8f5ee;border-color:var(--mint);color:var(--mint);}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .empty{text-align:center;padding:40px;color:#b8a88a;}
  .empty-icon{font-size:3rem;margin-bottom:8px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">Gestión de Pedidos</span>
</div>
<div class="container">

  <% if (msg.startsWith("ok:")) { %>
  <div class="alert-ok">✅ Estado del pedido #<%= msg.substring(3) %> actualizado correctamente.</div>
  <% } %>

  <% if (pedidosMap.isEmpty()) { %>
  <div class="empty">
    <div class="empty-icon">📋</div>
    <p>No hay pedidos registrados aún.</p>
  </div>
  <% } else { for (Object[] p : pedidosMap.values()) {
      int    pid     = (int)    p[0];
      String estado  = (String) p[1];
      String metodo  = (String) p[2];
      double total   = (double) p[3];
      String fecha   = (String) p[4];
      String usuario = (String) p[5];
      String numStr  = String.format("%03d", pid);
      String chipCls = "preparacion".equals(estado) ? "chip-prep" : "listo".equals(estado) ? "chip-listo" : "chip-ent";
      String estIcon = "preparacion".equals(estado) ? "🔥" : "listo".equals(estado) ? "🔔" : "✅";
      String estLabel= "preparacion".equals(estado) ? "En preparación" : "listo".equals(estado) ? "Listo para recoger" : "Entregado";
      String metIcon = "tarjeta".equals(metodo) ? "💳" : "💵";
      java.util.List<String> prods = detallesMap.get(pid);
  %>
  <div class="card">
    <div class="pedido-head">
      <span class="pedido-id">Pedido #<%= numStr %></span>
      <span class="chip <%= chipCls %>"><%= estIcon %> <%= estLabel %></span>
    </div>
    <div class="pedido-info">
      👤 <%= usuario %> &nbsp;·&nbsp;
      $<%= String.format("%.0f", total) %> &nbsp;·&nbsp;
      <%= metIcon %> <%= "tarjeta".equals(metodo) ? "Tarjeta" : "Efectivo" %><br>
      📅 <%= fecha %>
    </div>

    <!-- Productos del pedido -->
    <% if (prods != null && !prods.isEmpty()) { %>
    <div class="productos-lista">
      <div class="productos-title">🛒 Productos</div>
      <% for (String prod : prods) { %>
      <div class="producto-item"><%= prod %></div>
      <% } %>
    </div>
    <% } %>

    <div class="estado-btns">
      <form method="post" action="cambiar_estado.jsp" style="display:inline">
        <input type="hidden" name="pedido_id" value="<%= pid %>">
        <input type="hidden" name="estado" value="preparacion">
        <button type="submit" class="btn-est <%= "preparacion".equals(estado) ? "active-prep" : "" %>">🔥 En preparación</button>
      </form>
      <form method="post" action="cambiar_estado.jsp" style="display:inline">
        <input type="hidden" name="pedido_id" value="<%= pid %>">
        <input type="hidden" name="estado" value="listo">
        <button type="submit" class="btn-est <%= "listo".equals(estado) ? "active-listo" : "" %>">🔔 Listo para recoger</button>
      </form>
      <form method="post" action="cambiar_estado.jsp" style="display:inline">
        <input type="hidden" name="pedido_id" value="<%= pid %>">
        <input type="hidden" name="estado" value="entregado">
        <button type="submit" class="btn-est <%= "entregado".equals(estado) ? "active-ent" : "" %>">✅ Entregado</button>
      </form>
    </div>
  </div>
  <% } } %>

</div>
</body>
</html>
