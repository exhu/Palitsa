/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa.tests;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import palitsa.db.SqlParser;

/**
 *
 * @author yuryb
 */
public class ConnectionTest {

    public static void main(String[] args) throws ClassNotFoundException, SQLException, IOException {
        System.out.println("ConnectionTest...");

        Class.forName("org.h2.Driver");
        
        //final String url = "jdbc:h2:~/test";
        final String url = "jdbc:h2:mem:";
        
        
        Connection conn = DriverManager.getConnection(url, "sa", "");
        // add application code here
        
        BufferedReader reader;
        reader = new BufferedReader(new InputStreamReader(
 SqlParser.class.getClassLoader()
 .getResourceAsStream("palitsa/db/db_schema_h2.sql")));
        
        
        SqlParser parser = new SqlParser(reader);
        parser.parseStatements();
        
        for(String s : parser.getStatements()) {
            System.out.println(s);
        }
        // TODO read text
        //conn.
        System.in.read();
        
        
        conn.close();
    }
}
