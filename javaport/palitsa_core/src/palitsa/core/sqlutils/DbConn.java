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
    private static final Logger logger = Logger.getLogger(DbConn.class.getName());

    public static DbConn openFile(String fn) {
        DbConn cn = null;
        try {
            cn = new DbConn(fn);
        } catch (Exception e) {
            logger.log(Level.SEVERE, null, e);
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
            logger.log(Level.SEVERE, null, ex);
        }
    }

    public void runTransaction(TransactionBody b) {
        runTransaction(b, false);
    }
    //@SuppressWarnings("unchecked")
    public void runTransaction(TransactionBody b, boolean forceRollback) {
        if (inTransaction)
            throw new MultiTransactionError();
        
        try {
            inTransaction = true;
            b.run();
            if (!forceRollback)
                conn.commit();
            else
                conn.rollback();
        }
        catch(Exception e) {
            inTransaction = false;
            try {
                conn.rollback();
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, null, ex);
            }

            RuntimeException re = (RuntimeException)e;
            if (re != null) {
                throw re;
            }
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
            logger.log(Level.SEVERE, null, ex);
        }
    }
}
