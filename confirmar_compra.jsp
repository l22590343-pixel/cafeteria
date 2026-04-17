<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Seguridad: debe estar logueado ─────────────────────── */
Integer userId   = (Integer) session.getAttribute("userId");
String  username = (String)  session.getAttribute("username");
if (userId == null) { response.sendRedirect("login.jsp"); return; }

/* ── Leer carrito de sesión ─────────────────────────────── */
@SuppressWarnings("unchecked")
List<Map<String,Object>> cart =
    (List<Map<String,Object>>) session.getAttribute("cart");

String metodoPago = request.getParameter("metodo");   // "efectivo" o "tarjeta"
if (cart == null || cart.isEmpty()) {
    response.sendRedirect("menu.jsp?msg=carrito_vacio");
    return;
}
if (metodoPago == null || (!metodoPago.equals("efectivo") && !metodoPago.equals("tarjeta"))) {
    metodoPago = "efectivo";
}

double total = 0;
for (Map<String,Object> item : cart) {
    int qty    = (int) item.get("qty");
    double pre = ((Number) item.get("precio")).doubleValue();
    total += qty * pre;
}

int numeroPedido = 0;
String errorMsg  = null;
Connection con   = null;

try {
    con = Conexion.getConnection();
    con.setAutoCommit(false);   // Transacción

    /* 1) Crear pedido */
    PreparedStatement insPedido = con.prepareStatement(
        "INSERT INTO pedidos (usuario_id, total, estado, metodo_pago) VALUES (?, ?, 'preparacion', ?)",
        Statement.RETURN_GENERATED_KEYS
    );
    insPedido.setInt(1, userId);
    insPedido.setDouble(2, total);
    insPedido.setString(3, metodoPago);
    insPedido.executeUpdate();

    ResultSet keys = insPedido.getGeneratedKeys();
    if (keys.next()) numeroPedido = keys.getInt(1);

    /* 2) Insertar detalles y descontar stock */
    PreparedStatement insDetalle = con.prepareStatement(
        "INSERT INTO detalle_pedido (pedido_id, producto_id, nombre_prod, qty, precio_unit, subtotal) VALUES (?,?,?,?,?,?)"
    );
    PreparedStatement updStock = con.prepareStatement(
        "UPDATE productos SET stock = GREATEST(0, stock - ?) WHERE id = ? AND stock >= ?"
    );

    for (Map<String,Object> item : cart) {
        int    prodId  = (int)    item.get("id");
        String nombre  = (String) item.get("nombre");
        int    qty     = (int)    item.get("qty");
        double precio  = ((Number) item.get("precio")).doubleValue();
        double sub     = qty * precio;

        insDetalle.setInt(1, numeroPedido);
        insDetalle.setInt(2, prodId);
        insDetalle.setString(3, nombre);
        insDetalle.setInt(4, qty);
        insDetalle.setDouble(5, precio);
        insDetalle.setDouble(6, sub);
        insDetalle.addBatch();

        updStock.setInt(1, qty);
        updStock.setInt(2, prodId);
        updStock.setInt(3, qty);   // solo si hay suficiente stock
        updStock.addBatch();
    }
    insDetalle.executeBatch();
    updStock.executeBatch();

    con.commit();   // Todo OK → confirmar

    /* Limpiar carrito */
    session.removeAttribute("cart");
    session.setAttribute("ultimoPedido",   numeroPedido);
    session.setAttribute("ultimoMetodo",   metodoPago);

} catch (Exception ex) {
    if (con != null) try { con.rollback(); } catch (Exception ignored) {}
    errorMsg = "Error al procesar la compra: " + ex.getMessage();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}

if (errorMsg != null) {
    response.sendRedirect("menu.jsp?error=" + java.net.URLEncoder.encode(errorMsg, "UTF-8"));
    return;
}

String numStr = String.format("%03d", numeroPedido);
String metodoLabel = "tarjeta".equals(metodoPago) ? "💳 Tarjeta" : "💵 Efectivo";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>¡Pedido confirmado! — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;}
  .card{background:white;border-radius:24px;padding:40px 32px;max-width:420px;width:100%;text-align:center;box-shadow:0 20px 60px rgba(44,26,14,.15);}
  .icon{font-size:4rem;margin-bottom:16px;}
  h2{font-family:'Playfair Display',serif;font-size:1.6rem;margin-bottom:8px;}
  p{color:#7a5c3a;font-size:.95rem;line-height:1.5;margin-bottom:6px;}
  .pedido-num{background:var(--foam);border-radius:14px;padding:16px;margin:20px 0;}
  .pedido-num span{font-size:.8rem;color:#7a5c3a;display:block;margin-bottom:4px;}
  .pedido-num strong{font-family:'Playfair Display',serif;font-size:2rem;color:var(--caramel);}
  .metodo-badge{display:inline-block;background:var(--foam);border-radius:8px;padding:6px 14px;font-size:.9rem;font-weight:600;color:var(--espresso);margin-bottom:20px;}
  .btn{display:block;width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;text-decoration:none;text-align:center;margin-bottom:10px;transition:all .2s;}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-caramel:hover{background:#b8733a;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
</style>
</head>
<body>
<div class="card">
  <div class="icon">✅</div>
  <h2>¡Pedido realizado con éxito!</h2>
  <p>Tu pedido está siendo preparado con todo el cariño.</p>
  <div class="pedido-num">
    <span>Número de pedido</span>
    <strong>#<%= numStr %></strong>
  </div>
  <div class="metodo-badge"><%= metodoLabel %></div>
  <p style="font-size:1.3rem;margin-bottom:24px">Gracias por su compra ☕</p>
  <a href="estado_pedido.jsp?id=<%= numeroPedido %>" class="btn btn-caramel">📦 Ver estado del pedido</a>
  <a href="menu.jsp" class="btn btn-ghost">← Volver al menú</a>
</div>
</body>
</html>
