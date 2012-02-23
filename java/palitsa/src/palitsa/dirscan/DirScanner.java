/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package palitsa.dirscan;

import java.io.File;

/**
 *
 * @author yuryb
 */
public class DirScanner {
    DirScannerListener listener;

    public DirScanner() {
    }

    
    
    public DirScanner(DirScannerListener listener) {
        this.listener = listener;
    }

    public void setListener(DirScannerListener listener) {
        this.listener = listener;
    }

    public DirScannerListener getListener() {
        return listener;
    }
    
    
    /// main function
    public void searchFrom(String path) {
        File [] files = new File(path).listFiles();
        if (files == null)
        {
            listener.onNoAccess(path);
            return;
        }
        
        for(File f : files) {
            //System.out.println(f.getName());
            //System.out.println(File.separator);
            listener.onFoundEntry(path, f);
            if (f.isDirectory())
            {
                String ndir = path.endsWith(File.separator) ? path + f.getName() : 
                        path + File.separator + f.getName();
                
                listener.onEnterDir(ndir);
                searchFrom(ndir);
                listener.onLeaveDir();
            }
        }
        
        
        
    }
}
