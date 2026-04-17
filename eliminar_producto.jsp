<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="util.Conexion" %>
<%
/* ── Solo admin ─────────────────────────────────────────── */
String rol = (String) session.getAttribute("rol");
if (!"admin".equals(rol)) { response.sendRedirect("login.jsp"); return; }

String idParam = request.getParameter("id");
int prodId = 0;
try { prodId = Integer.parseInt(idParam); } catch (Exception e) {}

if (prodId > 0) {
    Connection con = null;
    try {
        con = Conexion.getConnection();
        /* Marcar como inactivo en lugar de borrar para no romper historial de pedidos */
        PreparedStatement ps = con.prepareStatement(
            "UPDATE productos SET activo = FALSE WHERE id = ?"
        );
        ps.setInt(1, prodId);
        ps.executeUpdate();
    } catch (Exception ex) {
        ex.printStackTrace();
    } finally {
        if (con != null) try { con.close(); } catch (Exception ignored) {}
    }
}

response.sendRedirect("admin.jsp?msg=producto_eliminado");
%>
