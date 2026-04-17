<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Solo admin ─────────────────────────────────────────── */
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

/* ── Cargar productos con stock ─────────────────────────── */
List<Map<String,Object>> productos = new ArrayList<Map<String,Object>>();
int totalStock    = 0;
int agotados      = 0;
int stockBajo     = 0;
Connection con    = null;

try {
    con = Conexion.getConnection();
    PreparedStatement ps = con.prepareStatement(
        "SELECT id, nombre, cat, precio, stock FROM productos WHERE activo = TRUE ORDER BY stock ASC, nombre ASC"
    );
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> p = new HashMap<String,Object>();
        int stock = rs.getInt("stock");
        p.put("id",     rs.getInt("id"));
        p.put("nombre", rs.getString("nombre"));
        p.put("cat",    rs.getString("cat"));
        p.put("precio", rs.getInt("precio"));
        p.put("stock",  stock);
        productos.add(p);
        totalStock += stock;
        if (stock == 0)     agotados++;
        else if (stock <= 5) stockBajo++;
    }
} catch (Exception ex) {
    ex.printStackTrace();
} finally {
    if (con != null) try { con.close(); } catch (Exception ignored) {}
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Inventario — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:14px 20px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:100;box-shadow:0 4px 12px rgba(0,0,0,.2);}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;padding:4px 8px;border-radius:6px;}
  .topbar a:hover{background:rgba(255,255,255,.1);}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{padding:20px;max-width:700px;margin:0 auto;}

  /* Resumen stats */
  .stats{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:24px;}
  .stat-card{background:white;border-radius:14px;padding:16px;text-align:center;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .stat-num{font-family:'Playfair Display',serif;font-size:1.8rem;font-weight:700;}
  .stat-label{font-size:.75rem;color:#7a5c3a;margin-top:3px;text-transform:uppercase;letter-spacing:.5px;}
  .num-ok{color:var(--mint);}
  .num-bajo{color:#f57c00;}
  .num-agotado{color:var(--danger);}
  .num-total{color:var(--caramel);}

  /* Filtros */
  .filtros{display:flex;gap:8px;margin-bottom:16px;flex-wrap:wrap;}
  .filtro-btn{padding:7px 14px;border:2px solid var(--latte);border-radius:20px;background:white;font-family:inherit;font-size:.82rem;font-weight:600;cursor:pointer;color:var(--espresso);transition:all .2s;}
  .filtro-btn:hover,.filtro-btn.active{border-color:var(--caramel);background:var(--foam);}

  /* Tabla */
  .tabla-wrapper{background:white;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(44,26,14,.08);}
  table{width:100%;border-collapse:collapse;}
  th{background:var(--espresso);color:var(--cream);padding:12px 16px;text-align:left;font-size:.8rem;font-weight:600;letter-spacing:.3px;}
  td{padding:12px 16px;border-bottom:1px solid var(--foam);font-size:.88rem;vertical-align:middle;}
  tr:last-child td{border-bottom:none;}
  tr:hover td{background:var(--foam);}

  /* Badges stock */
  .badge{display:inline-block;padding:4px 10px;border-radius:20px;font-size:.75rem;font-weight:700;}
  .badge-ok{background:#e8f5ee;color:#2d6a4f;}
  .badge-bajo{background:#fff3e0;color:#e65100;}
  .badge-agotado{background:#fdecea;color:var(--danger);}

  /* Barra de stock visual */
  .stock-bar-wrap{width:80px;height:6px;background:var(--foam);border-radius:3px;overflow:hidden;display:inline-block;vertical-align:middle;margin-left:8px;}
  .stock-bar{height:100%;border-radius:3px;transition:width .3s;}

  /* Botones */
  .btn{display:inline-block;padding:10px 18px;border:none;border-radius:10px;font-family:inherit;font-size:.88rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s;margin-right:8px;margin-bottom:8px;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .btn-ghost:hover{background:var(--foam);}
  .btn-caramel{background:var(--caramel);color:white;}
  .btn-caramel:hover{background:#b8733a;}

  .empty{text-align:center;padding:40px;color:#b8a88a;}
  .seccion-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;}
  .alert-bajo{background:#fff3e0;border:1px solid #ffcc80;border-radius:12px;padding:12px 16px;margin-bottom:16px;font-size:.88rem;color:#e65100;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">📦 Inventario</span>
</div>

<div class="container">

  <!-- Resumen -->
  <div class="stats">
    <div class="stat-card">
      <div class="stat-num num-total"><%= totalStock %></div>
      <div class="stat-label">Unidades totales</div>
    </div>
    <div class="stat-card">
      <div class="stat-num num-bajo"><%= stockBajo %></div>
      <div class="stat-label">Stock bajo</div>
    </div>
    <div class="stat-card">
      <div class="stat-num num-agotado"><%= agotados %></div>
      <div class="stat-label">Agotados</div>
    </div>
  </div>

  <!-- Alerta si hay productos críticos -->
  <% if (agotados > 0 || stockBajo > 0) { %>
  <div class="alert-bajo">
    ⚠️
    <% if (agotados > 0) { %><strong><%= agotados %> producto(s) agotado(s)</strong><% } %>
    <% if (agotados > 0 && stockBajo > 0) { %> y <% } %>
    <% if (stockBajo > 0) { %><strong><%= stockBajo %> producto(s) con stock bajo</strong><% } %>
    — considera reabastecer el inventario.
  </div>
  <% } %>

  <!-- Acciones -->
  <div style="margin-bottom:16px">
    <a href="form_producto.jsp" class="btn btn-caramel">➕ Agregar producto</a>
    <a href="admin.jsp"         class="btn btn-ghost">← Panel admin</a>
  </div>

  <div class="seccion-title">Estado del inventario</div>

  <!-- Tabla de inventario -->
  <div class="tabla-wrapper">
    <% if (productos.isEmpty()) { %>
    <div class="empty">
      <p style="font-size:2.5rem;margin-bottom:8px">📦</p>
      <p>No hay productos en el inventario.</p>
    </div>
    <% } else { %>
    <table>
      <thead>
        <tr>
          <th>Producto</th>
          <th>Categoría</th>
          <th>Precio</th>
          <th>Stock</th>
          <th>Estado</th>
          <th>Acción</th>
        </tr>
      </thead>
      <tbody>
        <%
        int maxStock = 0;
        for (Map<String,Object> p : productos) {
            int s = (int) p.get("stock");
            if (s > maxStock) maxStock = s;
        }
        for (Map<String,Object> p : productos) {
            int stock = (int) p.get("stock");
            String badgeCls, badgeTxt, barColor;
            if (stock == 0) {
                badgeCls = "badge-agotado"; badgeTxt = "Agotado"; barColor = "#E05252";
            } else if (stock <= 5) {
                badgeCls = "badge-bajo"; badgeTxt = "Bajo";    barColor = "#f57c00";
            } else {
                badgeCls = "badge-ok";   badgeTxt = "OK";       barColor = "#4CAF82";
            }
            int barPct = maxStock > 0 ? (int)((stock * 100.0) / maxStock) : 0;
        %>
        <tr>
          <td><strong><%= p.get("nombre") %></strong></td>
          <td style="color:#7a5c3a"><%= p.get("cat") %></td>
          <td style="color:var(--caramel);font-weight:700">$<%= p.get("precio") %></td>
          <td>
            <strong><%= stock %></strong>
            <span class="stock-bar-wrap">
              <span class="stock-bar" style="width:<%= barPct %>%;background:<%= barColor %>"></span>
            </span>
          </td>
          <td><span class="badge <%= badgeCls %>"><%= badgeTxt %></span></td>
          <td>
            <a href="form_producto.jsp?id=<%= p.get("id") %>" style="color:var(--caramel);text-decoration:none;font-size:1rem;" title="Editar stock">✏️</a>
          </td>
        </tr>
        <% } %>
      </tbody>
    </table>
    <% } %>
  </div>

</div>
</body>
</html>
