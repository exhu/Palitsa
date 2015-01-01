/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa.core.sqlutils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Inteface to a database file.
 *
 * @author yur
 */
public final class DbConn {

    public static DbConn openFile(String fn) {
        DbConn cn = null;
        try {
            cn = new DbConn(fn);
        } catch (Exception e) {
            Logger.getLogger(DbConn.class.getName()).log(Level.SEVERE, null, e);
        }

        return cn;
    }

    public void close() {
        try {
            stmt.close();
            stmt = null;
            conn.close();
            conn = null;
        } catch (SQLException ex) {
            Logger.getLogger(DbConn.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    protected DbConn(String fn) throws SQLException {
        conn = DriverManager.getConnection("jdbc:sqlite:" + fn);
        conn.setAutoCommit(false);
        stmt = conn.createStatement();
        stmt.setQueryTimeout(30); // set tout to 30 secs
        inTransaction = false;
    }

    private Connection conn;
    private Statement stmt;
    private boolean inTransaction;

    static {
        try {
            Class.forName("org.sqlite.JDBC");
        } catch (ClassNotFoundException ex) {
            Logger.getLogger(DbConn.class.getName()).log(Level.SEVERE, null, ex);
        }
    }
}
