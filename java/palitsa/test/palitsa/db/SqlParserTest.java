/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa.db;

import java.io.StringReader;
import java.util.List;
import static org.junit.Assert.*;

/**
 *
 * @author yur
 */
public class SqlParserTest {
    
    public SqlParserTest() {
    }

    @org.junit.BeforeClass
    public static void setUpClass() throws Exception {
    }

    @org.junit.AfterClass
    public static void tearDownClass() throws Exception {
    }

    @org.junit.Before
    public void setUp() throws Exception {
    }

    @org.junit.After
    public void tearDown() throws Exception {
    }


    /**
     * Test of parseStatements method, of class SqlParser.
     */
    @org.junit.Test
    public void testParseStatements() {
        System.out.println("parseStatements");
        SqlParser instance = new SqlParser(new StringReader("abc = a; aa -- ddd"));
        instance.parseStatements();
        // TODO review the generated test code and remove the default call to fail.
        System.out.println(instance.getStatements().get(0));
        System.out.println(instance.getStatements().get(1));
        fail("The test case is a prototype.");
    }

    /**
     * Test of getStatements method, of class SqlParser.
     */
    @org.junit.Test
    public void testGetStatements() {
        System.out.println("getStatements");
        SqlParser instance = null;
        List expResult = null;
        List result = instance.getStatements();
        assertEquals(expResult, result);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }

    /**
     * Test of processLine method, of class SqlParser.
     */
    @org.junit.Test
    public void testProcessLine() {
        System.out.println("processLine");
        String s = "";
        SqlParser instance = null;
        instance.processLine(s);
        // TODO review the generated test code and remove the default call to fail.
        fail("The test case is a prototype.");
    }
}
