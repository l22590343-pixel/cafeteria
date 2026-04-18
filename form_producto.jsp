<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="util.Conexion" %>
<%@ page import="org.apache.commons.fileupload.*" %>
<%@ page import="org.apache.commons.fileupload.disk.*" %>
<%@ page import="org.apache.commons.fileupload.servlet.*" %>
<%@ page import="java.util.List" %>
<%
/* ── Solo admin ─────────────────────────────────────────── */
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

/* ── Parámetros ─────────────────────────────────────────── */
String idParam  = request.getParameter("id");
int    editId   = 0;
try { editId = Integer.parseInt(idParam); } catch (Exception e) {}
boolean esEdicion = editId > 0;

/* ── Valores actuales si es edición ─────────────────────── */
String valNombre = "", valCat = "Bebida", valPrecio = "", valStock = "", valImg = "";
if (esEdicion) {
    Connection c = null;
    try {
        c = Conexion.getConexion();
        PreparedStatement ps = c.prepareStatement("SELECT * FROM productos WHERE id = ?");
        ps.setInt(1, editId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            valNombre = rs.getString("nombre");
            valCat    = rs.getString("cat");
            valPrecio = String.valueOf(rs.getInt("precio"));
            valStock  = String.valueOf(rs.getInt("stock"));
            valImg    = rs.getString("img_url") != null ? rs.getString("img_url") : "";
        }
    } finally { if (c != null) try { c.close(); } catch (Exception ignored) {} }
}

String errorMsg = "";

/* ── POST: guardar ─────────────────────────────────────── */
if ("POST".equals(request.getMethod())) {
    String nombre = "", cat = "Bebida", imgUrl = valImg;
    int    precio = 0, stock = 0;

    if (ServletFileUpload.isMultipartContent(request)) {
        DiskFileItemFactory factory = new DiskFileItemFactory();
        factory.setRepository(new File(System.getProperty("java.io.tmpdir")));
        ServletFileUpload upload = new ServletFileUpload(factory);
        upload.setFileSizeMax(5 * 1024 * 1024);  // 5 MB

        List<FileItem> items = upload.parseRequest(request);
        for (FileItem item : items) {
            String field = item.getFieldName();
            if (item.isFormField()) {
                String val = item.getString("UTF-8").trim();
                if ("nombre".equals(field))  nombre = val;
                if ("cat".equals(field))     cat    = val;
                if ("precio".equals(field))  try { precio = Integer.parseInt(val); } catch (Exception e) {}
                if ("stock".equals(field))   try { stock  = Integer.parseInt(val); } catch (Exception e) {}
            } else if ("imagen".equals(field) && item.getSize() > 0) {
                /* Guardar imagen en /uploads/ */
                String uploadDir = application.getRealPath("/uploads");
                new File(uploadDir).mkdirs();
                String ext = item.getName().contains(".")
                    ? item.getName().substring(item.getName().lastIndexOf('.'))
                    : ".jpg";
                String fileName = "prod_" + System.currentTimeMillis() + ext;
                item.write(new File(uploadDir + File.separator + fileName));
                imgUrl = "uploads/" + fileName;
            }
        }
    }

    if (nombre.isEmpty() || precio <= 0 || stock < 0) {
        errorMsg = "Completa todos los campos correctamente.";
    } else {
        Connection c = null;
        try {
            c = Conexion.getConexion();
            if (esEdicion) {
                PreparedStatement ps = c.prepareStatement(
                    "UPDATE productos SET nombre=?, cat=?, precio=?, stock=?, img_url=? WHERE id=?"
                );
                ps.setString(1, nombre); ps.setString(2, cat);
                ps.setInt(3, precio);   ps.setInt(4, stock);
                ps.setString(5, imgUrl.isEmpty() ? null : imgUrl);
                ps.setInt(6, editId);
                ps.executeUpdate();
            } else {
                PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO productos (nombre, cat, precio, stock, img_url) VALUES (?,?,?,?,?)"
                );
                ps.setString(1, nombre); ps.setString(2, cat);
                ps.setInt(3, precio);   ps.setInt(4, stock);
                ps.setString(5, imgUrl.isEmpty() ? null : imgUrl);
                ps.executeUpdate();
            }
            response.sendRedirect("admin.jsp?msg=producto_guardado");
            return;
        } catch (Exception ex) {
            errorMsg = "Error al guardar: " + ex.getMessage();
        } finally {
            if (c != null) try { c.close(); } catch (Exception ignored) {}
        }
    }
}
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= esEdicion ? "Editar" : "Agregar" %> Producto — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:480px;margin:24px auto;padding:0 20px;}
  .card{background:white;border-radius:20px;padding:28px;box-shadow:0 8px 32px rgba(44,26,14,.1);}
  .form-group{margin-bottom:18px;}
  .form-group label{display:block;font-size:.85rem;font-weight:600;margin-bottom:6px;color:#7a5c3a;}
  .form-group input,.form-group select{width:100%;padding:12px 14px;border:2px solid var(--latte);border-radius:10px;font-family:inherit;font-size:.95rem;background:var(--foam);outline:none;transition:border .2s;}
  .form-group input:focus,.form-group select:focus{border-color:var(--caramel);background:white;}
  .img-preview{width:100%;height:140px;object-fit:cover;border-radius:10px;display:none;margin-top:8px;}
  .img-hint{padding:30px;text-align:center;background:var(--foam);border:2px dashed var(--latte);border-radius:10px;color:#b8a88a;font-size:.85rem;cursor:pointer;}
  .btn{width:100%;padding:14px;border:none;border-radius:12px;font-family:inherit;font-size:.95rem;font-weight:600;cursor:pointer;margin-bottom:10px;transition:all .2s;}
  .btn-primary{background:var(--espresso);color:var(--cream);}
  .btn-primary:hover{background:#1a0f05;}
  .btn-ghost{background:transparent;border:2px solid var(--latte);color:var(--espresso);}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:12px;border-radius:10px;margin-bottom:16px;font-size:.88rem;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title"><%= esEdicion ? "Editar" : "Agregar" %> Producto</span>
</div>
<div class="container">
  <div class="card">
    <% if (!errorMsg.isEmpty()) { %>
    <div class="alert-error">⚠️ <%= errorMsg %></div>
    <% } %>

    <form method="post" enctype="multipart/form-data">
      <% if (esEdicion) { %><input type="hidden" name="id" value="<%= editId %>"><% } %>

      <div class="form-group">
        <label>Nombre del producto</label>
        <input type="text" name="nombre" value="<%= valNombre %>" placeholder="Ej: Café Latte" required>
      </div>
      <div class="form-group">
        <label>Categoría</label>
        <select name="cat">
          <option value="Bebida"   <%= "Bebida".equals(valCat)   ? "selected" : "" %>>☕ Bebida</option>
          <option value="Alimento" <%= "Alimento".equals(valCat) ? "selected" : "" %>>🥐 Alimento</option>
          <option value="Postre"   <%= "Postre".equals(valCat)   ? "selected" : "" %>>🍰 Postre</option>
        </select>
      </div>
      <div class="form-group">
        <label>Precio ($MXN)</label>
        <input type="number" name="precio" value="<%= valPrecio %>" min="1" placeholder="Ej: 45" required>
      </div>
      <div class="form-group">
        <label>Stock disponible</label>
        <input type="number" name="stock" value="<%= valStock %>" min="0" placeholder="Ej: 20" required>
      </div>
      <div class="form-group">
        <label>Imagen del producto</label>
        <% if (!valImg.isEmpty()) { %>
        <img src="<%= valImg %>" class="img-preview" id="img-preview" style="display:block">
        <% } else { %>
        <img class="img-preview" id="img-preview">
        <% } %>
        <div class="img-hint" id="img-hint" style="<%= !valImg.isEmpty() ? "display:none" : "" %>"
             onclick="document.getElementById('imagen').click()">
          📷 Toca para seleccionar imagen
        </div>
        <input type="file" name="imagen" id="imagen" accept="image/*" style="display:none"
               onchange="previewImg(this)">
      </div>

      <button type="submit" class="btn btn-primary">
        <%= esEdicion ? "💾 Guardar cambios" : "➕ Agregar producto" %>
      </button>
      <a href="admin.jsp" class="btn btn-ghost" style="display:block;text-align:center;text-decoration:none">Cancelar</a>
    </form>
  </div>
</div>
<script>
function previewImg(input) {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    const preview = document.getElementById('img-preview');
    preview.src = e.target.result;
    preview.style.display = 'block';
    document.getElementById('img-hint').style.display = 'none';
  };
  reader.readAsDataURL(file);
}
</script>
</body>
</html>
