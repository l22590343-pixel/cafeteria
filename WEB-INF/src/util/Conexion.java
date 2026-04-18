package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Conexion {

    private static final String URL = "jdbc:postgresql://roundhouse.proxy.rlwy.net:55009/railway";
    private static final String user = "postgres";
    private static final String password = "nTfRMgXhodgPzxVctaoiGnmFVofFUoCJ";

    public static Connection getConexion() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
            return DriverManager.getConnection(URL, user, password);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver PostgreSQL no encontrado.", e);
        }
    }
}