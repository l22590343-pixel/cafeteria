<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
Integer userId = (Integer) session.getAttribute("userId");
String  rol    = (String)  session.getAttribute("rol");
if (userId == null) { response.sendRedirect("login.jsp"); return; }
if ("admin".equals(rol)) { response.sendRedirect("admin.jsp"); return; }

String nombre   = (String) session.getAttribute("nombre");
String busqueda = request.getParameter("q") != null ? request.getParameter("q").trim() : "";

/* ── Cargar productos de PostgreSQL ─────────────────────── */
List<Map<String,Object>> productos = new ArrayList<>();
Connection con = null;
try {
    con = Conexion.getConexion();
    String sql = busqueda.isEmpty()
        ? "SELECT id, nombre, cat, precio, stock, img_url FROM productos WHERE activo = TRUE ORDER BY cat, nombre"
        : "SELECT id, nombre, cat, precio, stock, img_url FROM productos WHERE activo = TRUE AND LOWER(nombre) LIKE LOWER(?) ORDER BY cat, nombre";
    PreparedStatement ps = con.prepareStatement(sql);
    if (!busqueda.isEmpty()) ps.setString(1, "%" + busqueda + "%");
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> p = new HashMap<>();
        p.put("id",      rs.getInt("id"));
        p.put("nombre",  rs.getString("nombre"));
        p.put("cat",     rs.getString("cat"));
        p.put("precio",  rs.getInt("precio"));
        p.put("stock",   rs.getInt("stock"));
        p.put("imgUrl",  rs.getString("img_url") != null ? rs.getString("img_url") : "");
        productos.add(p);
    }
} catch (Exception ex) {
    ex.printStackTrace();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

/* ── Carrito de sesión ──────────────────────────────────── */
@SuppressWarnings("unchecked")
List<Map<String,Object>> cart =
    (List<Map<String,Object>>) session.getAttribute("cart");
if (cart == null) { cart = new ArrayList<>(); session.setAttribute("cart", cart); }
// Sin lambda - compatible con Java 7
int cartCount = 0;
for (Map<String,Object> cartItem : cart) {
    cartCount += (Integer) cartItem.get("qty");
}

/* ── Mis pedidos (para mostrar en menú) ─────────────────── */
List<Map<String,Object>> misPedidos = new ArrayList<>();
try {
    con = Conexion.getConexion();
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, total, estado, metodo_pago, fecha FROM pedidos " +
        "WHERE usuario_id = ? AND estado != 'entregado' ORDER BY id DESC LIMIT 5"
    );
    ps.setInt(1, userId);
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> p = new HashMap<>();
        p.put("id",     rs.getInt("id"));
        p.put("total",  rs.getDouble("total"));
        p.put("estado", rs.getString("estado"));
        p.put("metodo", rs.getString("metodo_pago"));
        p.put("fecha",  rs.getString("fecha"));
        misPedidos.add(p);
    }
} catch (Exception ex) {
    ex.printStackTrace();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

String msgError = request.getParameter("error") != null ? request.getParameter("error") : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Menú — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;box-shadow:0 4px 12px rgba(0,0,0,.2);}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .cart-btn{position:relative;background:var(--caramel);border:none;color:white;width:42px;height:42px;border-radius:50%;font-size:1.1rem;cursor:pointer;}
  .cart-badge{position:absolute;top:-4px;right:-4px;background:var(--danger);color:white;font-size:.65rem;font-weight:700;width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;}

  .search-bar{padding:16px 20px;}
  .search-bar input{width:100%;padding:12px 16px;border:2px solid var(--latte);border-radius:12px;font-family:inherit;font-size:.9rem;background:var(--foam);outline:none;}
  .search-bar input:focus{border-color:var(--caramel);}
  .seccion{padding:0 20px 20px;}
  .seccion-title{font-size:.8rem;font-weight:700;color:#b8a88a;letter-spacing:1px;text-transform:uppercase;margin:16px 0 10px;}
  .productos-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:12px;}
  .prod-card{background:white;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(44,26,14,.07);cursor:pointer;transition:transform .2s,box-shadow .2s;}
  .prod-card:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(44,26,14,.12);}
  .prod-card.agotado{opacity:.55;cursor:not-allowed;}
  .prod-img{width:100%;height:100px;object-fit:cover;background:var(--foam);}
  .prod-img-placeholder{width:100%;height:100px;background:linear-gradient(135deg,var(--foam),var(--latte));display:flex;align-items:center;justify-content:center;color:#b8a88a;font-size:2rem;}
  .prod-info{padding:10px 12px 12px;}
  .prod-nombre{font-weight:600;font-size:.88rem;margin-bottom:2px;}
  .prod-precio{color:var(--caramel);font-weight:700;font-size:.95rem;}
  .prod-stock{font-size:.72rem;color:#b8a88a;}
  .btn-add{padding:7px 10px;border:none;border-radius:8px;background:var(--espresso);color:white;font-family:inherit;font-size:.82rem;font-weight:600;cursor:pointer;transition:background .2s;}
  .btn-add:hover{background:#1a0f05;}
  .btn-add:disabled{background:#ccc;cursor:not-allowed;}
  .btn-ver{padding:7px 10px;border:2px solid var(--latte);border-radius:8px;background:white;color:var(--espresso);font-family:inherit;font-size:.82rem;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block;transition:all .2s;white-space:nowrap;}
  .btn-ver:hover{border-color:var(--caramel);background:var(--foam);}
  /* Mis pedidos */
  .mis-pedidos{padding:0 20px 24px;}
  .pedido-card{background:white;border-radius:12px;padding:14px 16px;margin-bottom:10px;display:flex;justify-content:space-between;align-items:center;box-shadow:0 2px 8px rgba(44,26,14,.06);cursor:pointer;text-decoration:none;color:inherit;}
  .pedido-card:hover{background:var(--foam);}
  .chip{display:inline-block;padding:3px 10px;border-radius:20px;font-size:.75rem;font-weight:600;}
  .chip-prep{background:#fef3e2;color:var(--espresso);}
  .chip-listo{background:#e8ecff;color:#4a6cf7;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin:0 20px 16px;font-size:.88rem;}
  .logout-btn{background:none;border:none;color:var(--latte);font-size:.8rem;cursor:pointer;padding:4px 8px;}
</style>
</head>
<body>
<div class="topbar">
  <span class="topbar-title">☕ Menú</span>
  <div style="display:flex;align-items:center;gap:10px">
    <a href="carrito.jsp" style="position:relative;display:inline-block;">
      <button class="cart-btn">🛒
        <% if (cartCount > 0) { %>
        <span class="cart-badge"><%= cartCount %></span>
        <% } %>
      </button>
    </a>
    <form method="post" action="logout.jsp" style="margin:0">
      <button type="submit" class="logout-btn">Salir</button>
    </form>
  </div>
</div>



<% if (!msgError.isEmpty()) { %>
<div class="alert-error">⚠️ <%= msgError %></div>
<% } %>

<div class="search-bar">
  <form method="get" action="menu.jsp">
    <input type="text" name="q" value="<%= busqueda %>" placeholder="🔍 Buscar producto...">
  </form>
</div>

<div class="seccion">
  <div class="seccion-title">Productos disponibles</div>
  <% if (productos.isEmpty()) { %>
  <p style="text-align:center;color:#b8a88a;padding:40px 0">
    <%= busqueda.isEmpty() ? "No hay productos disponibles." : "No se encontraron resultados para \"" + busqueda + "\"." %>
  </p>
  <% } else { %>
  <div class="productos-grid">
    <% for (Map<String,Object> p : productos) {
       int    stock   = (int) p.get("stock");
       boolean agotado = stock == 0;
       String imgUrl  = (String) p.get("imgUrl");
    %>
    <div class="prod-card <%= agotado ? "agotado" : "" %>">
      <% if (imgUrl != null && !imgUrl.isEmpty()) { %>
      <img class="prod-img" src="<%= imgUrl %>" alt="<%= p.get("nombre") %>">
      <% } else { %>
      <div class="prod-img-placeholder">☕</div>
      <% } %>
      <div class="prod-info">
        <div class="prod-nombre"><%= p.get("nombre") %></div>
        <div class="prod-precio">$<%= p.get("precio") %></div>
        <div class="prod-stock"><%= agotado ? "❌ Agotado" : "Stock: " + stock %></div>
        <div style="display:flex;gap:6px;margin-top:6px">
          <a href="detalle_producto.jsp?id=<%= p.get("id") %>" class="btn-ver">👁 Ver</a>
          <% if (!agotado) { %>
          <form method="post" action="agregar_carrito.jsp" style="flex:1">
            <input type="hidden" name="prodId"    value="<%= p.get("id") %>">
            <input type="hidden" name="nombre"    value="<%= p.get("nombre") %>">
            <input type="hidden" name="precio"    value="<%= p.get("precio") %>">
            <input type="hidden" name="stock"     value="<%= stock %>">
            <input type="hidden" name="returnUrl" value="menu.jsp">
            <button type="submit" class="btn-add" style="width:100%">＋</button>
          </form>
          <% } else { %>
          <button class="btn-add" disabled style="flex:1">Agotado</button>
          <% } %>
        </div>
      </div>
    </div>
    <% } %>
  </div>
  <% } %>
</div>

<% if (!misPedidos.isEmpty()) { %>
<div class="mis-pedidos">
  <div class="seccion-title">Mis pedidos activos</div>
  <% for (Map<String,Object> p : misPedidos) {
     String est = (String) p.get("estado");
     String chipCls = "listo".equals(est) ? "chip-listo" : "chip-prep";
     String estLabel = "listo".equals(est) ? "🔔 Listo para recoger" : "🔥 En preparación";
     String metIcon  = "tarjeta".equals(p.get("metodo")) ? "💳" : "💵";
  %>
  <a class="pedido-card" href="estado_pedido.jsp?id=<%= p.get("id") %>">
    <div>
      <strong>Pedido #<%= String.format("%03d", (int)p.get("id")) %></strong><br>
      <small style="color:#7a5c3a">$<%= String.format("%.0f", (double)p.get("total")) %> &nbsp;·&nbsp; <%= metIcon %></small>
    </div>
    <span class="chip <%= chipCls %>"><%= estLabel %></span>
  </a>
  <% } %>
</div>
<% } %>

</body>
</html>
