<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) { response.sendRedirect("login.jsp"); return; }

/* ── Obtener producto de PostgreSQL ─────────────────────── */
String idParam = request.getParameter("id");
int prodId = 0;
try { prodId = Integer.parseInt(idParam); } catch (Exception e) {}
if (prodId == 0) { response.sendRedirect("menu.jsp"); return; }

String  nombre  = "";
String  cat     = "";
int     precio  = 0;
int     stock   = 0;
String  imgUrl  = "";
String  errorMsg = "";

Connection con = null;
try {
    con = Conexion.getConnection();
    PreparedStatement ps = con.prepareStatement(
        "SELECT nombre, cat, precio, stock, img_url FROM productos WHERE id = ? AND activo = TRUE"
    );
    ps.setInt(1, prodId);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
        nombre = rs.getString("nombre");
        cat    = rs.getString("cat");
        precio = rs.getInt("precio");
        stock  = rs.getInt("stock");
        imgUrl = rs.getString("img_url") != null ? rs.getString("img_url") : "";
    } else {
        response.sendRedirect("menu.jsp"); return;
    }
} catch (Exception ex) {
    errorMsg = ex.getMessage();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

/* ── Carrito count ──────────────────────────────────────── */
List cart = (List) session.getAttribute("cart");
if (cart == null) { cart = new ArrayList(); session.setAttribute("cart", cart); }
int cartCount = 0;
for (int i = 0; i < cart.size(); i++) {
    Map item = (Map) cart.get(i);
    cartCount += (Integer) item.get("qty");
}

boolean agotado = stock == 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= nombre %> — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}

  /* Topbar */
  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;box-shadow:0 4px 12px rgba(0,0,0,.2);}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.4rem;padding:4px 8px;border-radius:8px;}
  .topbar a:hover{background:rgba(255,255,255,.1);}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.15rem;letter-spacing:.3px;}
  .cart-btn{position:relative;background:var(--caramel);border:none;color:white;width:42px;height:42px;border-radius:50%;font-size:1.1rem;cursor:pointer;text-decoration:none;display:flex;align-items:center;justify-content:center;}
  .cart-badge{position:absolute;top:-4px;right:-4px;background:var(--danger);color:white;font-size:.62rem;font-weight:700;width:18px;height:18px;border-radius:50%;display:flex;align-items:center;justify-content:center;}

  /* Imagen del producto */
  .prod-imagen{width:100%;height:260px;object-fit:cover;background:linear-gradient(135deg,var(--foam),var(--latte));}
  .prod-imagen-placeholder{width:100%;height:260px;background:linear-gradient(135deg,var(--foam),var(--latte));display:flex;align-items:center;justify-content:center;font-size:5rem;color:var(--caramel);}

  /* Contenido */
  .container{padding:24px 20px;max-width:500px;margin:0 auto;}
  .prod-nombre{font-family:'Playfair Display',serif;font-size:1.7rem;margin-bottom:4px;}
  .prod-cat{font-size:.82rem;color:#b8a88a;text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;}
  .prod-precio{font-family:'Playfair Display',serif;font-size:1.8rem;color:var(--caramel);font-weight:700;margin-bottom:6px;}
  .prod-stock{font-size:.82rem;margin-bottom:24px;}
  .stock-ok{color:var(--mint);}
  .stock-bajo{color:#f57c00;}
  .stock-no{color:var(--danger);}
  .divider{height:1px;background:var(--latte);opacity:.5;margin-bottom:24px;}

  /* Selector de cantidad */
  .qty-label{font-size:.85rem;font-weight:600;color:#7a5c3a;margin-bottom:10px;}
  .qty-control{display:flex;align-items:center;gap:0;margin-bottom:28px;width:fit-content;}
  .qty-btn{width:44px;height:44px;border-radius:50%;border:2px solid var(--latte);background:white;font-size:1.3rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s;color:var(--espresso);font-weight:700;}
  .qty-btn:hover:not(:disabled){border-color:var(--caramel);background:var(--foam);}
  .qty-btn:disabled{opacity:.35;cursor:not-allowed;}
  .qty-num{width:54px;text-align:center;font-family:'Playfair Display',serif;font-size:1.4rem;font-weight:700;color:var(--espresso);}

  /* Botones */
  .btn{display:block;width:100%;padding:15px;border:none;border-radius:14px;font-family:inherit;font-size:1rem;font-weight:600;cursor:pointer;text-align:center;text-decoration:none;margin-bottom:12px;transition:all .2s;}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-caramel:hover:not(:disabled){background:#b8733a;transform:translateY(-1px);box-shadow:0 6px 20px rgba(200,134,74,.3);}
  .btn-caramel:disabled{background:#ccc;cursor:not-allowed;transform:none;box-shadow:none;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .btn-ghost:hover{background:var(--foam);}
  .agotado-badge{background:#fdecea;color:var(--danger);border-radius:10px;padding:12px;text-align:center;font-weight:600;font-size:.9rem;margin-bottom:12px;}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:12px;border-radius:10px;margin-bottom:14px;font-size:.88rem;display:none;}
</style>
</head>
<body>

<div class="topbar">
  <a href="menu.jsp" title="Volver">←</a>
  <span class="topbar-title">Detalle del Producto</span>
  <a href="carrito.jsp" class="cart-btn">🛒
    <% if (cartCount > 0) { %>
    <span class="cart-badge"><%= cartCount %></span>
    <% } %>
  </a>
</div>

<!-- Imagen -->
<% if (!imgUrl.isEmpty()) { %>
<img class="prod-imagen" src="<%= imgUrl %>" alt="<%= nombre %>">
<% } else { %>
<div class="prod-imagen-placeholder">☕</div>
<% } %>

<div class="container">

  <!-- Info del producto -->
  <p class="prod-cat"><%= cat %></p>
  <h1 class="prod-nombre"><%= nombre %></h1>
  <div class="prod-precio">$<%= precio %></div>

  <div class="prod-stock">
    <% if (agotado) { %>
    <span class="stock-no">❌ Sin stock disponible</span>
    <% } else if (stock <= 5) { %>
    <span class="stock-bajo">⚠️ Pocas unidades — solo <%= stock %> disponibles</span>
    <% } else { %>
    <span class="stock-ok">✅ Disponible — <%= stock %> en stock</span>
    <% } %>
  </div>

  <div class="divider"></div>

  <!-- Mensaje de éxito -->
  <div id="msg-ok" class="alert-ok">✅ Producto agregado al carrito.</div>

  <% if (!agotado) { %>

  <!-- Selector de cantidad -->
  <p class="qty-label">Cantidad</p>
  <div class="qty-control">
    <button class="qty-btn" id="btn-menos" onclick="cambiarQty(-1)" disabled>−</button>
    <span class="qty-num" id="qty-display">1</span>
    <button class="qty-btn" id="btn-mas"   onclick="cambiarQty(1)">+</button>
  </div>

  <!-- Formulario para agregar al carrito -->
  <form id="form-agregar" method="post" action="agregar_carrito.jsp">
    <input type="hidden" name="prodId"    value="<%= prodId %>">
    <input type="hidden" name="nombre"    value="<%= nombre %>">
    <input type="hidden" name="precio"    value="<%= precio %>">
    <input type="hidden" name="stock"     value="<%= stock %>">
    <input type="hidden" name="qty"       id="qty-input" value="1">
    <input type="hidden" name="returnUrl" value="detalle_producto.jsp?id=<%= prodId %>">
    <button type="submit" class="btn btn-caramel">
      🛒 Agregar al carrito
    </button>
  </form>

  <% } else { %>
  <div class="agotado-badge">😔 Este producto está agotado por el momento</div>
  <% } %>

  <a href="menu.jsp" class="btn btn-ghost">← Volver al menú</a>

</div>

<script>
var qty = 1;
var maxStock = <%= stock %>;

function cambiarQty(d) {
  qty = Math.max(1, Math.min(maxStock, qty + d));
  document.getElementById('qty-display').textContent = qty;
  document.getElementById('qty-input').value = qty;
  document.getElementById('btn-menos').disabled = (qty <= 1);
  document.getElementById('btn-mas').disabled   = (qty >= maxStock);
}
</script>
</body>
</html>
