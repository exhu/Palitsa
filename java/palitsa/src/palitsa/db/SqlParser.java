/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa.db;

import java.io.Reader;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 *
 * @author yur
 */
public class SqlParser {
    Reader reader;
    List<String> statements;
    StringBuilder curStatement;
    
    public SqlParser(Reader reader) {
        this.reader = reader;
    }
    
    public void parseStatements() {
        statements = new ArrayList<String>();
        curStatement = new StringBuilder();
        
        Scanner sc = new Scanner(reader);
        try {
            while(sc.hasNextLine()) {
                processLine(sc.nextLine());
            }
        }
        finally {
            sc.close();
            curStatement = null;
        }
    }
    
    
    public List<String> getStatements() {
        return statements;
    }
    
    
    void appendStatement() {
        statements.add(curStatement.toString());
        curStatement.setLength(0);
    }
    
    void processLine(String s) {
        // strip comments '--'
        int commentStart = s.indexOf("--");
        if (commentStart >= 0)
        {
            s = s.substring(0, commentStart);
        }
        
        // merge into statement until ';' is found
        while(s.length() > 0) {
            int endStmt = s.indexOf(';');
            if (endStmt >= 0) {
                curStatement.append(s.substring(0, endStmt));
                appendStatement();
                
                s = s.substring(endStmt+1);
            }
            else {
                curStatement.append(s);
                break;
            }
        } // end while
    }
    
}
