<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="util.Conexion" %>
<%
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String msg = "";
String msgType = "";
Object[] estudiante = null;
boolean yaTomoHoy = false;
boolean esHabilBeca = false;

java.time.LocalDate hoy = java.time.LocalDate.now();
java.time.DayOfWeek diaSemana = hoy.getDayOfWeek();

// Lunes=1, Martes=2, Miércoles=3, Jueves=4
esHabilBeca = diaSemana.getValue() >= 1 && diaSemana.getValue() <= 4;

String[] diasNombre = {"", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"};
String diaHoy = diasNombre[diaSemana.getValue()];

// POST: registrar asistencia
if ("POST".equals(request.getMethod())) {
    String numCtrl = request.getParameter("numero_control");
    String accion  = request.getParameter("accion");

    if (numCtrl != null && !numCtrl.trim().isEmpty()) {
        Connection con = null;
        try {
            con = Conexion.getConexion();

            // Buscar estudiante
            PreparedStatement ps = con.prepareStatement(
                "SELECT id, nombre, numero_control, fecha_inicio, fecha_fin, activa " +
                "FROM becas WHERE numero_control = ? AND activa = true " +
                "AND fecha_inicio <= CURRENT_DATE AND fecha_fin >= CURRENT_DATE"
            );
            ps.setString(1, numCtrl.trim());
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int becaId = rs.getInt("id");
                estudiante = new Object[]{
                    becaId,
                    rs.getString("nombre"),
                    rs.getString("numero_control"),
                    rs.getString("fecha_inicio"),
                    rs.getString("fecha_fin")
                };

                // Verificar si ya tomó hoy
                PreparedStatement check = con.prepareStatement(
                    "SELECT id FROM asistencia_becas WHERE beca_id = ? AND fecha = CURRENT_DATE"
                );
                check.setInt(1, becaId);
                ResultSet rsCheck = check.executeQuery();
                yaTomoHoy = rsCheck.next();

                // Si acción es confirmar y no ha tomado hoy
                if ("confirmar".equals(accion) && !yaTomoHoy && esHabilBeca) {
                    PreparedStatement ins = con.prepareStatement(
                        "INSERT INTO asistencia_becas (beca_id, fecha, dia_semana) VALUES (?, CURRENT_DATE, ?)"
                    );
                    ins.setInt(1, becaId);
                    ins.setString(2, diaHoy);
                    ins.executeUpdate();
                    yaTomoHoy = true;
                    msg = "✅ Beca registrada para " + estudiante[1];
                    msgType = "ok";
                }
            } else {
                msg = "No se encontró estudiante con ese número de control o la beca no está activa.";
                msgType = "error";
            }
        } catch (Exception ex) {
            msg = "Error: " + ex.getMessage();
            msgType = "error";
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignored) {}
        }
    }
}

// Cargar asistencias del día
List<Object[]> asistenciasHoy = new ArrayList<>();
Connection con2 = null;
try {
    con2 = Conexion.getConexion();
    PreparedStatement ps2 = con2.prepareStatement(
        "SELECT b.nombre, b.numero_control, a.hora " +
        "FROM asistencia_becas a JOIN becas b ON a.beca_id = b.id " +
        "WHERE a.fecha = CURRENT_DATE ORDER BY a.hora DESC"
    );
    ResultSet rs2 = ps2.executeQuery();
    while (rs2.next()) {
        asistenciasHoy.add(new Object[]{
            rs2.getString("nombre"),
            rs2.getString("numero_control"),
            rs2.getString("hora")
        });
    }
} catch (Exception ex) { }
finally { if (con2 != null) try { con2.close(); } catch (Exception ignored) {} }
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Tomar Beca — Cafetería</title>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{--espresso:#2C1A0E;--caramel:#C8864A;--latte:#E8C99A;--foam:#FAF0E0;--cream:#FDF6EC;--mint:#4CAF82;--danger:#E05252;}
  *{margin:0;padding:0;box-sizing:border-box;}
  body{font-family:'DM Sans',sans-serif;background:var(--cream);color:var(--espresso);min-height:100vh;}
  .topbar{background:var(--espresso);color:var(--cream);padding:16px 24px;display:flex;align-items:center;gap:12px;position:sticky;top:0;}
  .topbar a{color:var(--latte);text-decoration:none;font-size:1.3rem;}
  .topbar-title{font-family:'Playfair Display',serif;font-size:1.2rem;}
  .container{max-width:600px;margin:24px auto;padding:0 20px;}
  .dia-badge{text-align:center;padding:10px;background:var(--espresso);color:var(--latte);border-radius:12px;margin-bottom:20px;font-size:.9rem;font-weight:600;}
  .dia-badge.no-habil{background:#b94a48;color:white;}
  .card{background:white;border-radius:16px;padding:24px;box-shadow:0 4px 20px rgba(44,26,14,.08);margin-bottom:20px;}
  .buscar-form{display:flex;gap:10px;}
  .buscar-form input{flex:1;padding:14px 16px;border:2px solid var(--latte);border-radius:11px;font-family:inherit;font-size:1rem;background:var(--foam);outline:none;}
  .buscar-form input:focus{border-color:var(--caramel);background:white;}
  .buscar-form button{padding:14px 20px;background:var(--espresso);color:white;border:none;border-radius:11px;font-family:inherit;font-weight:700;cursor:pointer;font-size:.95rem;}
  .resultado{margin-top:20px;}
  .estudiante-card{background:var(--foam);border-radius:14px;padding:20px;text-align:center;margin-bottom:16px;}
  .estudiante-nombre{font-family:'Playfair Display',serif;font-size:1.4rem;margin-bottom:4px;}
  .estudiante-ctrl{font-size:.85rem;color:#7a5c3a;margin-bottom:16px;}
  .btn-confirmar{width:100%;padding:16px;background:var(--mint);color:white;border:none;border-radius:12px;font-family:inherit;font-size:1rem;font-weight:700;cursor:pointer;transition:background .2s;}
  .btn-confirmar:hover{background:#3d9e6e;}
  .ya-tomo{background:#e8f5ee;border:2px solid var(--mint);border-radius:12px;padding:16px;text-align:center;color:#2d6a4f;font-weight:700;font-size:1rem;}
  .alert-ok{background:#e8f5ee;border:1px solid #a8d5b8;color:#2d6a4f;padding:14px;border-radius:10px;margin-bottom:16px;font-size:.95rem;font-weight:600;}
  .alert-error{background:#fdecea;border:1px solid #f5c2c2;color:#b94a48;padding:14px;border-radius:10px;margin-bottom:16px;font-size:.95rem;}
  .section-title{font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:12px;}
  .lista-hoy{background:white;border-radius:14px;padding:20px;box-shadow:0 2px 10px rgba(44,26,14,.07);}
  .lista-item{display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid var(--foam);}
  .lista-item:last-child{border-bottom:none;}
  .lista-nombre{font-weight:600;font-size:.9rem;}
  .lista-ctrl{font-size:.78rem;color:#7a5c3a;}
  .lista-hora{font-size:.78rem;color:#7a5c3a;background:var(--foam);padding:3px 8px;border-radius:6px;}
  .palomita{font-size:1.3rem;}
  .empty{text-align:center;padding:20px;color:#b8a88a;font-size:.88rem;}
  .count{font-size:.82rem;color:#7a5c3a;margin-bottom:12px;}
</style>
</head>
<body>
<div class="topbar">
  <a href="admin.jsp">←</a>
  <span class="topbar-title">✅ Tomar Beca</span>
</div>
<div class="container">

  <div class="dia-badge <%= !esHabilBeca ? "no-habil" : "" %>">
    <%= esHabilBeca ? "📅 Hoy es " + diaHoy + " — Día hábil de beca" : "⚠️ Hoy es " + diaHoy + " — No hay becas (solo Lun-Jue)" %>
  </div>

  <% if (!msg.isEmpty()) { %>
  <div class="alert-<%= msgType %>"><%= msg %></div>
  <% } %>

  <% if (esHabilBeca) { %>
  <div class="card">
    <div style="font-family:'Playfair Display',serif;font-size:1.1rem;margin-bottom:14px;">🔍 Buscar estudiante</div>
    <form method="post" class="buscar-form">
      <input type="text" name="numero_control" placeholder="Número de control..." 
             value="<%= request.getParameter("numero_control") != null ? request.getParameter("numero_control") : "" %>"
             autofocus autocomplete="off">
      <button type="submit">Buscar</button>
    </form>

    <% if (estudiante != null) { %>
    <div class="resultado">
      <div class="estudiante-card">
        <div style="font-size:2.5rem;margin-bottom:8px">👤</div>
        <div class="estudiante-nombre"><%= estudiante[1] %></div>
        <div class="estudiante-ctrl">N° Control: <%= estudiante[2] %></div>

        <% if (yaTomoHoy) { %>
        <div class="ya-tomo">✅ Ya tomó su beca hoy (<%= diaHoy %>)</div>
        <% } else { %>
        <form method="post">
          <input type="hidden" name="numero_control" value="<%= estudiante[2] %>">
          <input type="hidden" name="accion" value="confirmar">
          <button type="submit" class="btn-confirmar">✅ Confirmar — Tomó su beca hoy</button>
        </form>
        <% } %>
      </div>
    </div>
    <% } %>
  </div>
  <% } %>

  <!-- Lista de asistencias del día -->
  <div class="section-title">📋 Asistencias de hoy — <%= hoy.toString() %></div>
  <div class="lista-hoy">
    <div class="count"><%= asistenciasHoy.size() %> estudiante(s) han tomado su beca hoy</div>
    <% if (asistenciasHoy.isEmpty()) { %>
    <div class="empty">Ningún estudiante ha tomado su beca hoy.</div>
    <% } else { for (Object[] a : asistenciasHoy) {
        String horaStr = ((String)a[2]).length() > 16 ? ((String)a[2]).substring(11, 16) : (String)a[2];
    %>
    <div class="lista-item">
      <div>
        <div class="lista-nombre"><span class="palomita">✅</span> <%= a[0] %></div>
        <div class="lista-ctrl">N° <%= a[1] %></div>
      </div>
      <div class="lista-hora">🕐 <%= horaStr %></div>
    </div>
    <% } } %>
  </div>

</div>
</body>
</html>
