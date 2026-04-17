<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
/* ── Seguridad ───────────────────────────────────────────── */
if (session.getAttribute("userId") == null) {
    response.sendRedirect("login.jsp"); return;
}

int    prodId  = 0;
String nombre  = "";
int    precio  = 0;
int    stock   = 0;
String returnUrl = "menu.jsp";

try { prodId = Integer.parseInt(request.getParameter("prodId")); } catch (Exception e) {}
try { precio = Integer.parseInt(request.getParameter("precio")); } catch (Exception e) {}
try { stock  = Integer.parseInt(request.getParameter("stock"));  } catch (Exception e) {}
int addQty = 1;
try { addQty = Math.max(1, Integer.parseInt(request.getParameter("qty"))); } catch (Exception e) {}
nombre    = request.getParameter("nombre")    != null ? request.getParameter("nombre")    : "";
returnUrl = request.getParameter("returnUrl") != null ? request.getParameter("returnUrl") : "menu.jsp";

if (prodId > 0 && !nombre.isEmpty() && precio > 0) {
    @SuppressWarnings("unchecked")
    List<Map<String,Object>> cart =
        (List<Map<String,Object>>) session.getAttribute("cart");
    if (cart == null) {
        cart = new ArrayList<>();
        session.setAttribute("cart", cart);
    }

    /* Buscar si ya existe en el carrito */
    Map<String,Object> existing = null;
    for (Map<String,Object> item : cart) {
        if ((int)item.get("id") == prodId) { existing = item; break; }
    }

    if (existing != null) {
        int currentQty = (int) existing.get("qty");
        int newQty = currentQty + addQty;
        existing.put("qty", Math.min(newQty, stock));
    } else {
        Map<String,Object> item = new HashMap<>();
        item.put("id",     prodId);
        item.put("nombre", nombre);
        item.put("precio", precio);
        item.put("stock",  stock);
        item.put("qty",    Math.min(addQty, stock));
        cart.add(item);
    }
}

response.sendRedirect(returnUrl);
%>
