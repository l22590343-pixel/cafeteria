<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) { response.sendRedirect("login.jsp"); return; }

/* ── Carrito de sesión ──────────────────────────────────── */
List cart = (List) session.getAttribute("cart");
if (cart == null) { cart = new ArrayList(); session.setAttribute("cart", cart); }

/* ── Calcular total ─────────────────────────────────────── */
double total = 0;
for (int i = 0; i < cart.size(); i++) {
    Map item = (Map) cart.get(i);
    int qty    = (Integer) item.get("qty");
    int precio = (Integer) item.get("precio");
    total += qty * precio;
}

/* ── Eliminar item del carrito ──────────────────────────── */
String eliminarIdx = request.getParameter("eliminar");
if (eliminarIdx != null) {
    try {
        int idx = Integer.parseInt(eliminarIdx);
        if (idx >= 0 && idx < cart.size()) {
            cart.remove(idx);
        }
    } catch (Exception e) { /* ignorar */ }
    response.sendRedirect("carrito.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Carrito — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 4px 12px rgba(0,0,0,.2);}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:500px;margin:0 auto;padding:20px;}
  .card{background:white;border-radius:18px;padding:20px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:16px;}
  .item-row{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid var(--foam);}
  .item-row:last-child{border-bottom:none;}
  .item-nombre{font-weight:600;font-size:.92rem;margin-bottom:2px;}
  .item-precio{color:#7a5c3a;font-size:.82rem;}
  .item-qty{background:var(--foam);border-radius:8px;padding:4px 10px;font-weight:700;font-size:.9rem;color:var(--espresso);}
  .item-subtotal{font-weight:700;color:var(--caramel);font-size:.95rem;margin-right:8px;}
  .btn-del{background:none;border:none;color:#ccc;cursor:pointer;font-size:1.1rem;padding:4px;border-radius:6px;transition:color .2s;}
  .btn-del:hover{color:var(--danger);}
  .total-row{display:flex;justify-content:space-between;align-items:center;padding-top:14px;margin-top:4px;border-top:2px solid var(--latte);}
  .total-label{font-family:'Playfair Display',serif;font-size:1.1rem;}
  .total-monto{font-family:'Playfair Display',serif;font-size:1.5rem;color:var(--caramel);font-weight:700;}
  .empty-carrito{text-align:center;padding:50px 20px;}
  .empty-icon{font-size:3.5rem;margin-bottom:12px;}
  .empty-txt{color:#b8a88a;font-size:.95rem;margin-bottom:24px;}
  /* Métodos de pago */
  .metodo-title{font-weight:600;font-size:.9rem;color:#7a5c3a;margin-bottom:12px;}
  .metodo-options{display:flex;flex-direction:column;gap:10px;}
  .metodo-option{display:flex;align-items:center;gap:14px;padding:14px 16px;background:var(--foam);border-radius:12px;border:2px solid transparent;cursor:pointer;transition:all .2s;}
  .metodo-option:hover{border-color:var(--caramel);}
  .metodo-option.selected{border-color:var(--caramel);background:white;box-shadow:0 2px 10px rgba(200,134,74,.15);}
  .metodo-option input[type=radio]{accent-color:var(--caramel);width:18px;height:18px;flex-shrink:0;}
  .metodo-icon{font-size:1.5rem;}
  .metodo-label{font-weight:600;font-size:.93rem;}
  .metodo-sub{font-size:.78rem;color:#7a5c3a;margin-top:1px;}
  /* Botones */
  .btn{display:block;width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;text-align:center;text-decoration:none;margin-bottom:10px;transition:all .2s;}
  .btn-primary{background:var(--espresso);color:var(--cream);}
  .btn-primary:hover{background:#1a0f05;transform:translateY(-1px);}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-caramel:hover{background:#b8733a;transform:translateY(-1px);}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .btn-ghost:hover{background:var(--foam);}
  /* Formulario tarjeta */
  .form-group{margin-bottom:14px;}
  .form-group label{display:block;font-size:.82rem;font-weight:600;margin-bottom:5px;color:#7a5c3a;}
  .form-group input{width:100%;padding:11px 13px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.9rem;background:var(--foam);outline:none;transition:border .2s;}
  .form-group input:focus{border-color:var(--caramel);background:white;}
  .row2{display:grid;grid-template-columns:1fr 1fr;gap:10px;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;color:var(--espresso);}
  #form-tarjeta{display:none;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:14px;font-size:.88rem;display:none;}
</style>
</head>
<body>
<div class="topbar">
  <a href="menu.jsp">←</a>
  <span class="topbar-title">🛒 Carrito</span>
</div>

<div class="container">

<% if (cart.isEmpty()) { %>
  <!-- Carrito vacío -->
  <div class="empty-carrito">
    <div class="empty-icon">🛒</div>
    <p class="empty-txt">Tu carrito está vacío.<br>Agrega productos desde el menú.</p>
    <a href="menu.jsp" class="btn btn-caramel">☕ Ver menú</a>
  </div>

<% } else { %>

  <!-- Lista de productos -->
  <div class="card">
    <div class="section-title">Productos</div>
    <% for (int i = 0; i < cart.size(); i++) {
       Map item    = (Map) cart.get(i);
       String nom  = (String) item.get("nombre");
       int qty     = (Integer) item.get("qty");
       int precio  = (Integer) item.get("precio");
       int subt    = qty * precio;
    %>
    <div class="item-row">
      <div>
        <div class="item-nombre"><%= nom %></div>
        <div class="item-precio">$<%= precio %> c/u</div>
      </div>
      <div style="display:flex;align-items:center;gap:8px">
        <span class="item-qty">x<%= qty %></span>
        <span class="item-subtotal">$<%= subt %></span>
        <a href="carrito.jsp?eliminar=<%= i %>" class="btn-del" title="Eliminar"
           onclick="return confirm('¿Quitar este producto del carrito?')">✕</a>
      </div>
    </div>
    <% } %>

    <!-- Total -->
    <div class="total-row">
      <span class="total-label">Total</span>
      <span class="total-monto">$<%= (int) total %></span>
    </div>
  </div>

  <!-- Método de pago -->
  <div class="card">
    <div class="section-title">Método de pago</div>
    <div id="error-pago" class="alert-error">⚠️ Selecciona un método de pago.</div>

    <div class="metodo-options">
      <label class="metodo-option" id="opt-efectivo" onclick="selectMetodo('efectivo')">
        <input type="radio" name="metodo" value="efectivo" id="radio-efectivo">
        <span class="metodo-icon">💵</span>
        <div>
          <div class="metodo-label">Efectivo</div>
          <div class="metodo-sub">Paga al recoger tu pedido</div>
        </div>
      </label>
      <label class="metodo-option" id="opt-tarjeta" onclick="selectMetodo('tarjeta')">
        <input type="radio" name="metodo" value="tarjeta" id="radio-tarjeta">
        <span class="metodo-icon">💳</span>
        <div>
          <div class="metodo-label">Tarjeta de crédito/débito</div>
          <div class="metodo-sub">Pago seguro en línea</div>
        </div>
      </label>
    </div>

    <!-- Tarjeta: se muestra info de redirección -->
    <div id="form-tarjeta" style="margin-top:18px;display:none">
      <div style="height:1px;background:var(--latte);margin-bottom:16px;opacity:.5"></div>
      <div style="background:var(--foam);border-radius:12px;padding:14px;text-align:center;font-size:.88rem;color:#7a5c3a">
        &#128274; Serás redirigido a la pantalla de pago con tarjeta
      </div>
    </div>
  </div>

  <!-- Botones -->
  <button class="btn btn-caramel" onclick="procederPago()">
    ✅ Confirmar pedido — $<%= (int) total %>
  </button>
  <a href="menu.jsp" class="btn btn-ghost">← Seguir comprando</a>

  <!-- Formulario efectivo -> confirmar directo -->
  <form id="form-efectivo" method="post" action="confirmar_compra.jsp" style="display:none">
    <input type="hidden" name="metodo" value="efectivo">
  </form>
  <!-- Formulario tarjeta -> pantalla de tarjeta -->
  <form id="form-tarjeta-redir" method="get" action="pago_tarjeta.jsp" style="display:none">
  </form>

<% } %>

</div>

<script>
var metodoPago = null;

function selectMetodo(m) {
  metodoPago = m;
  document.getElementById('opt-efectivo').classList.toggle('selected', m === 'efectivo');
  document.getElementById('opt-tarjeta').classList.toggle('selected',  m === 'tarjeta');
  document.getElementById('radio-efectivo').checked = (m === 'efectivo');
  document.getElementById('radio-tarjeta').checked  = (m === 'tarjeta');
  document.getElementById('form-tarjeta').style.display = (m === 'tarjeta') ? 'block' : 'none';
  document.getElementById('error-pago').style.display = 'none';
}

function formatCard(input) {
  var v = input.value.replace(/\D/g,'').substring(0,16);
  var r = '';
  for (var i = 0; i < v.length; i++) {
    if (i > 0 && i % 4 === 0) r += ' ';
    r += v[i];
  }
  input.value = r;
}

function formatExp(input) {
  var v = input.value.replace(/\D/g,'');
  if (v.length >= 2) v = v.substring(0,2) + '/' + v.substring(2,4);
  input.value = v;
}

function procederPago() {
  if (!metodoPago) {
    document.getElementById('error-pago').style.display = 'block';
    document.getElementById('error-pago').scrollIntoView({behavior:'smooth'});
    return;
  }

  // Validar datos de tarjeta si eligió tarjeta
  if (metodoPago === 'tarjeta') {
    var num  = document.getElementById('card-num').value.replace(/\s/g,'');
    var name = document.getElementById('card-name').value.trim();
    var exp  = document.getElementById('card-exp').value.trim();
    var cvv  = document.getElementById('card-cvv').value.trim();
    if (num.length < 16 || name === '' || exp.length < 5 || cvv.length < 3) {
      alert('⚠️ Completa todos los datos de la tarjeta.');
      return;
    }
  }

  if (metodoPago === 'efectivo') {
    document.getElementById('form-efectivo').submit();
  } else {
    document.getElementById('form-tarjeta-redir').submit();
  }
}
</script>
</body>
</html>
