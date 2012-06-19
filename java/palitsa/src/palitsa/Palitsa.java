/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa;

import java.io.File;
import palitsa.dirscan.DirScanner;
import palitsa.dirscan.DirScannerListener;


/**
 *
 * @author yuryb
 */
public class Palitsa implements DirScannerListener{

    @Override
    public void onEnterDir(String path) {
        
        System.out.println("Entering " + path);
    }

    @Override
    public void onFoundEntry(String path, File e) {
        System.out.println("Found " + e.getName());
    }

    @Override
    public void onLeaveDir() {
        System.out.println("Left dir.");
    }
    
    void scan() {
        DirScanner s = new DirScanner();
        s.setListener(this);
        s.searchFrom("/var/log/");
    }

    @Override
    public void onNoAccess(String path) {
        System.out.println("Cannot access " + path);
    }
    
    

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        System.out.println("Palitsa...");
        new Palitsa().scan();
    }
}
