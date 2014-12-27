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
public interface DirScannerListener {
    void onFoundEntry(String path, File e);
    void onEnterDir(String path);
    void onLeaveDir();
    void onNoAccess(String path);
}
