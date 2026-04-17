<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) { response.sendRedirect("login.jsp"); return; }

/* ── Carrito ─────────────────────────────────────────────── */
List cart = (List) session.getAttribute("cart");
if (cart == null || cart.isEmpty()) {
    response.sendRedirect("carrito.jsp"); return;
}

double total = 0;
for (int i = 0; i < cart.size(); i++) {
    Map item = (Map) cart.get(i);
    total += (Integer) item.get("qty") * (Integer) item.get("precio");
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pago con Tarjeta — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}

  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 4px 12px rgba(0,0,0,.2);}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;padding:4px 8px;border-radius:6px;}
  .topbar a:hover{background:rgba(255,255,255,.1);}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}

  .container{max-width:480px;margin:0 auto;padding:24px 20px;}

  /* Tarjeta visual */
  .card-visual{
    background: linear-gradient(135deg, #2C1A0E 0%, #C8864A 100%);
    border-radius:18px;padding:28px 24px;color:white;
    box-shadow:0 12px 40px rgba(44,26,14,.35);
    margin-bottom:28px;position:relative;overflow:hidden;
  }
  .card-visual::before{
    content:'';position:absolute;top:-30px;right:-30px;
    width:140px;height:140px;border-radius:50%;
    background:rgba(255,255,255,.08);
  }
  .card-visual::after{
    content:'';position:absolute;bottom:-40px;right:40px;
    width:100px;height:100px;border-radius:50%;
    background:rgba(255,255,255,.05);
  }
  .card-chip{width:42px;height:32px;background:linear-gradient(135deg,#E8C99A,#c8a870);border-radius:6px;margin-bottom:20px;position:relative;z-index:1;}
  .card-num-display{font-size:1.2rem;letter-spacing:3px;margin-bottom:18px;font-weight:600;position:relative;z-index:1;font-family:monospace;}
  .card-bottom{display:flex;justify-content:space-between;align-items:flex-end;position:relative;z-index:1;}
  .card-holder{font-size:.75rem;text-transform:uppercase;letter-spacing:1px;opacity:.8;margin-bottom:2px;}
  .card-name-display{font-size:.95rem;font-weight:600;text-transform:uppercase;letter-spacing:.5px;}
  .card-exp-label{font-size:.65rem;opacity:.7;text-transform:uppercase;letter-spacing:.8px;margin-bottom:2px;}
  .card-exp-display{font-size:.9rem;font-weight:600;}
  .card-brand{font-size:1.5rem;opacity:.9;}

  /* Resumen */
  .resumen{background:white;border-radius:14px;padding:16px 18px;margin-bottom:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);display:flex;justify-content:space-between;align-items:center;}
  .resumen-label{font-size:.85rem;color:#7a5c3a;}
  .resumen-total{font-family:'Playfair Display',serif;font-size:1.4rem;color:var(--caramel);font-weight:700;}

  /* Formulario */
  .card-form{background:white;border-radius:18px;padding:24px;box-shadow:0 4px 20px rgba(44,26,14,.08);}
  .form-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:18px;color:var(--espresso);}
  .form-group{margin-bottom:16px;}
  .form-group label{display:block;font-size:.8rem;font-weight:600;margin-bottom:5px;color:#7a5c3a;text-transform:uppercase;letter-spacing:.4px;}
  .form-group input{
    width:100%;padding:12px 14px;
    border:2px solid var(--latte);border-radius:10px;
    font-family:inherit;font-size:.95rem;
    background:var(--foam);outline:none;transition:border .2s;
  }
  .form-group input:focus{border-color:var(--caramel);background:white;}
  .row2{display:grid;grid-template-columns:1fr 1fr;gap:12px;}

  /* Seguridad */
  .seguridad{display:flex;align-items:center;gap:8px;font-size:.78rem;color:#b8a88a;margin:14px 0;justify-content:center;}
  .seguridad span{font-size:1rem;}

  /* Botones */
  .btn{display:block;width:100%;padding:15px;border:none;border-radius:12px;font-family:inherit;font-size:1rem;font-weight:600;cursor:pointer;text-align:center;text-decoration:none;margin-bottom:10px;transition:all .2s;}
  .btn-mint{background:var(--mint);color:white;}
  .btn-mint:hover{background:#3d9e6e;transform:translateY(-1px);box-shadow:0 6px 20px rgba(76,175,130,.3);}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .btn-ghost:hover{background:var(--foam);}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:14px;font-size:.88rem;display:none;}
</style>
</head>
<body>

<div class="topbar">
  <a href="carrito.jsp">&#8592;</a>
  <span class="topbar-title">Pago con Tarjeta</span>
</div>

<div class="container">

  <!-- Tarjeta visual animada -->
  <div class="card-visual">
    <div class="card-chip"></div>
    <div class="card-num-display" id="vis-num">•••• •••• •••• ••••</div>
    <div class="card-bottom">
      <div>
        <div class="card-holder">Titular</div>
        <div class="card-name-display" id="vis-name">NOMBRE APELLIDO</div>
      </div>
      <div style="text-align:right">
        <div class="card-exp-label">Vence</div>
        <div class="card-exp-display" id="vis-exp">MM/AA</div>
      </div>
    </div>
  </div>

  <!-- Total a pagar -->
  <div class="resumen">
    <div>
      <div class="resumen-label">Total a cobrar</div>
      <div style="font-size:.75rem;color:#b8a88a">Pago seguro con tarjeta</div>
    </div>
    <div class="resumen-total">$<%= (int) total %> MXN</div>
  </div>

  <!-- Formulario -->
  <div class="card-form">
    <div class="form-title">&#128274; Datos de la tarjeta</div>

    <div id="error-tarjeta" class="alert-error"></div>

    <div class="form-group">
      <label>Número de tarjeta</label>
      <input type="text" id="card-num" placeholder="1234 5678 9012 3456"
             maxlength="19" oninput="formatCard(this)" autocomplete="cc-number">
    </div>
    <div class="form-group">
      <label>Nombre del titular</label>
      <input type="text" id="card-name" placeholder="Como aparece en la tarjeta"
             oninput="updateVis()" autocomplete="cc-name">
    </div>
    <div class="row2">
      <div class="form-group">
        <label>Vencimiento</label>
        <input type="text" id="card-exp" placeholder="MM/AA" maxlength="5"
               oninput="formatExp(this)" autocomplete="cc-exp">
      </div>
      <div class="form-group">
        <label>CVV</label>
        <input type="password" id="card-cvv" placeholder="•••" maxlength="4"
               autocomplete="cc-csc">
      </div>
    </div>

    <!-- Indicador de seguridad -->
    <div class="seguridad">
      <span>&#128274;</span> Conexión segura — tus datos están protegidos
    </div>

    <button class="btn btn-mint" onclick="confirmarTarjeta()">
      &#10003; Pagar $<%= (int) total %> MXN
    </button>

    <!-- Formulario oculto que envía a confirmar_compra.jsp -->
    <form id="form-pago" method="post" action="confirmar_compra.jsp" style="display:none">
      <input type="hidden" name="metodo" value="tarjeta">
    </form>

    <a href="carrito.jsp" class="btn btn-ghost">&#8592; Volver al carrito</a>
  </div>

</div>

<script>
/* ── Actualizar tarjeta visual en tiempo real ── */
function formatCard(input) {
  var v = input.value.replace(/\D/g, '').substring(0, 16);
  var r = '';
  for (var i = 0; i < v.length; i++) {
    if (i > 0 && i % 4 === 0) r += ' ';
    r += v[i];
  }
  input.value = r;
  var display = r.length > 0 ? r : '';
  var pad = '•••• •••• •••• ••••';
  // Mostrar dígitos y relleno con puntos
  var shown = '';
  var digits = v;
  for (var j = 0; j < 16; j++) {
    if (j > 0 && j % 4 === 0) shown += ' ';
    shown += (j < digits.length) ? digits[j] : '•';
  }
  document.getElementById('vis-num').textContent = shown;
}

function updateVis() {
  var name = document.getElementById('card-name').value.trim().toUpperCase();
  document.getElementById('vis-name').textContent = name || 'NOMBRE APELLIDO';
}

function formatExp(input) {
  var v = input.value.replace(/\D/g, '');
  if (v.length >= 2) v = v.substring(0, 2) + '/' + v.substring(2, 4);
  input.value = v;
  document.getElementById('vis-exp').textContent = v || 'MM/AA';
}

/* ── Validar y enviar ── */
function confirmarTarjeta() {
  var num  = document.getElementById('card-num').value.replace(/\s/g, '');
  var name = document.getElementById('card-name').value.trim();
  var exp  = document.getElementById('card-exp').value.trim();
  var cvv  = document.getElementById('card-cvv').value.trim();
  var err  = document.getElementById('error-tarjeta');

  err.style.display = 'none';

  if (num.length < 16) {
    err.textContent = '&#9888; Ingresa un número de tarjeta válido (16 dígitos).';
    err.style.display = 'block'; return;
  }
  if (name.length < 3) {
    err.textContent = '&#9888; Ingresa el nombre del titular.';
    err.style.display = 'block'; return;
  }
  if (exp.length < 5) {
    err.textContent = '&#9888; Ingresa la fecha de vencimiento (MM/AA).';
    err.style.display = 'block'; return;
  }
  if (cvv.length < 3) {
    err.textContent = '&#9888; Ingresa el CVV (3 o 4 dígitos).';
    err.style.display = 'block'; return;
  }

  /* Validar que no esté vencida */
  var parts = exp.split('/');
  var mes = parseInt(parts[0]);
  var anio = parseInt('20' + parts[1]);
  var hoy = new Date();
  if (mes < 1 || mes > 12 || anio < hoy.getFullYear() ||
      (anio === hoy.getFullYear() && mes < (hoy.getMonth() + 1))) {
    err.textContent = '&#9888; La tarjeta está vencida.';
    err.style.display = 'block'; return;
  }

  /* Todo OK — enviar a confirmar_compra.jsp */
  document.getElementById('form-pago').submit();
}

/* Evento Enter en inputs */
document.addEventListener('keydown', function(e) {
  if (e.key === 'Enter') confirmarTarjeta();
});
</script>
</body>
</html>
