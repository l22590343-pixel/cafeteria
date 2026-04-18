<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Solo admin ─────────────────────────────────────────── */
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String busqueda = request.getParameter("q") != null ? request.getParameter("q").trim() : "";
String msgOk    = request.getParameter("msg") != null ? request.getParameter("msg") : "";

/* ── Cargar productos de PostgreSQL ─────────────────────── */
List<Map<String,Object>> productos = new ArrayList<>();
Connection con = null;
try {
    con = Conexion.getConexion();
    String sql = busqueda.isEmpty()
        ? "SELECT id, nombre, cat, precio, stock, img_url FROM productos WHERE activo = TRUE ORDER BY id"
        : "SELECT id, nombre, cat, precio, stock, img_url FROM productos WHERE activo = TRUE AND LOWER(nombre) LIKE LOWER(?) ORDER BY id";
    PreparedStatement ps = con.prepareStatement(sql);
    if (!busqueda.isEmpty()) ps.setString(1, "%" + busqueda + "%");
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> p = new HashMap<>();
        p.put("id",     rs.getInt("id"));
        p.put("nombre", rs.getString("nombre"));
        p.put("cat",    rs.getString("cat"));
        p.put("precio", rs.getInt("precio"));
        p.put("stock",  rs.getInt("stock"));
        p.put("imgUrl", rs.getString("img_url") != null ? rs.getString("img_url") : "");
        productos.add(p);
    }
} catch (Exception ex) {
    ex.printStackTrace();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

/* ── Conteo de pedidos activos ──────────────────────────── */
int pedidosActivos = 0;
try {
    con = Conexion.getConexion()
    PreparedStatement ps = con.prepareStatement(
        "SELECT COUNT(*) FROM pedidos WHERE estado != 'entregado'"
    );
    ResultSet rs = ps.executeQuery();
    if (rs.next()) pedidosActivos = rs.getInt(1);
} catch (Exception ex) { /* ignorar */ }
finally { if (con != null) try { con.close(); } catch (Exception ignored) {} }
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Panel Admin — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .logout-btn{background:none;border:none;color:var(--latte);font-size:.8rem;cursor:pointer;padding:4px 8px;}
  .container{padding:20px;}
  .stats-row{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:20px;}
  .stat-card{background:white;border-radius:14px;padding:16px;text-align:center;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .stat-num{font-family:'Playfair Display',serif;font-size:1.8rem;color:var(--caramel);}
  .stat-label{font-size:.78rem;color:#7a5c3a;margin-top:2px;}
  .btn{display:block;width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;text-align:center;text-decoration:none;margin-bottom:10px;transition:all .2s;}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-caramel:hover{background:#b8733a;}
  .btn-mint{background:var(--mint);color:white;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .search-bar{margin-bottom:16px;}
  .search-bar form{display:flex;gap:8px;}
  .search-bar input{flex:1;padding:10px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.9rem;background:var(--foam);outline:none;}
  .search-bar input:focus{border-color:var(--caramel);}
  .search-bar button{padding:10px 16px;border:none;border-radius:10px;background:var(--espresso);color:white;cursor:pointer;font-size:.9rem;}
  table{width:100%;border-collapse:collapse;background:white;border-radius:14px;overflow:hidden;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  th{background:var(--espresso);color:var(--cream);padding:12px 10px;text-align:left;font-size:.8rem;font-weight:600;}
  td{padding:10px;border-bottom:1px solid var(--foam);font-size:.85rem;vertical-align:middle;}
  tr:last-child td{border-bottom:none;}
  .stock-ok{background:#e8f5ee;color:var(--mint);padding:3px 8px;border-radius:6px;font-size:.75rem;font-weight:600;}
  .stock-low{background:#fff3e0;color:#f57c00;padding:3px 8px;border-radius:6px;font-size:.75rem;font-weight:600;}
  .stock-out{background:#fdecea;color:var(--danger);padding:3px 8px;border-radius:6px;font-size:.75rem;font-weight:600;}
  .icon-btn{background:none;border:none;cursor:pointer;font-size:1rem;padding:4px;border-radius:6px;}
  .icon-btn:hover{background:var(--foam);}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:12px;}
</style>
</head>
<body>
<div class="topbar">
  <span class="topbar-title">⚙️ Panel Admin</span>
  <form method="post" action="logout.jsp" style="margin:0">
    <button type="submit" class="logout-btn">Salir</button>
  </form>
</div>

<div class="container">

  <% if ("producto_guardado".equals(msgOk)) { %>
  <div class="alert-ok">✅ Producto guardado correctamente en la base de datos.</div>
  <% } else if ("producto_eliminado".equals(msgOk)) { %>
  <div class="alert-ok" style="background:#fdecea;border-color:#f5c2c2;color:#b94a48">🗑️ Producto eliminado del sistema.</div>
  <% } %>

  <!-- Estadísticas -->
  <div class="stats-row">
    <div class="stat-card">
      <div class="stat-num"><%= productos.size() %></div>
      <div class="stat-label">Productos</div>
    </div>
    <div class="stat-card">
      <div class="stat-num"><%= pedidosActivos %></div>
      <div class="stat-label">Pedidos activos</div>
    </div>
  </div>

  <!-- Acciones rápidas -->
  <a href="cambiar_estado.jsp" class="btn btn-caramel">📋 Gestionar Pedidos</a>
  <a href="form_producto.jsp"  class="btn btn-mint">➕ Agregar Producto</a>
  <a href="inventario.jsp"     class="btn btn-ghost">📦 Ver Inventario</a>

  <div class="section-title" style="margin-top:20px">Productos</div>

  <!-- Buscador -->
  <div class="search-bar">
    <form method="get" action="admin.jsp">
      <input type="text" name="q" value="<%= busqueda %>" placeholder="🔍 Buscar producto...">
      <button type="submit">Buscar</button>
    </form>
  </div>

  <!-- Tabla productos -->
  <table>
    <thead>
      <tr>
        <th>ID</th><th>Nombre</th><th>Cat.</th>
        <th>Precio</th><th>Stock</th><th>Acciones</th>
      </tr>
    </thead>
    <tbody>
      <% if (productos.isEmpty()) { %>
      <tr><td colspan="6" style="text-align:center;padding:30px;color:#b8a88a">
        <%= busqueda.isEmpty() ? "No hay productos." : "Sin resultados para \"" + busqueda + "\"." %>
      </td></tr>
      <% } else { for (Map<String,Object> p : productos) {
           int stock = (int) p.get("stock");
           String badgeCls  = stock == 0 ? "stock-out" : stock <= 5 ? "stock-low" : "stock-ok";
           String badgeText = stock == 0 ? "Agotado"   : stock <= 5 ? "Bajo"      : "OK";
      %>
      <tr>
        <td><%= p.get("id") %></td>
        <td><%= p.get("nombre") %></td>
        <td><%= p.get("cat") %></td>
        <td style="color:var(--caramel);font-weight:700">$<%= p.get("precio") %></td>
        <td><span class="<%= badgeCls %>"><%= stock %> — <%= badgeText %></span></td>
        <td>
          <a href="form_producto.jsp?id=<%= p.get("id") %>" class="icon-btn" title="Editar">✏️</a>
          <a href="eliminar_producto.jsp?id=<%= p.get("id") %>" class="icon-btn" title="Eliminar"
             onclick="return confirm('¿Eliminar este producto?')">🗑️</a>
        </td>
      </tr>
      <% } } %>
    </tbody>
  </table>

</div>
</body>
</html>
