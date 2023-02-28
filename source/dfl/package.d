// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

/// Imports all of DFL's public interface.
module dfl;


/*
version(bud)
    version = build;
version(DFL_NO_BUD_DEF)
    version = DFL_NO_BUILD_DEF;


    //$(TOC pragmas, Pragmas)
       // $(TOC_SUB pragmas,pragma_build, build)
      //  $(TOC_SUB pragmas,pragma_build_def, build def)
      //  $(TOC_SUB pragmas,pragma_export_version, export version)
      //  $(TOC_SUB pragmas,pragma_ignore, ignore)
      //  $(TOC_SUB pragmas,pragma_include, include)
     //   $(TOC_SUB pragmas,pragma_link, link)
        
version(build)
{

    version(WINE)
    {
    }
    else
    {
        version(DFL_NO_LIB)
        {
        }
        else
        {
            pragma(link, "dfl_build");
            
            pragma(link, "ws2_32");
            pragma(link, "gdi32");
            pragma(link, "comctl32");
            pragma(link, "advapi32");
            pragma(link, "comdlg32");
            pragma(link, "ole32");
            pragma(link, "uuid");
        }
        
        version(DFL_NO_BUILD_DEF)
        {
        }
        else
        {
            pragma(build_def, "EXETYPE NT");
            version(gui)
            {
                pragma(build_def, "SUBSYSTEM WINDOWS,4.0");
            }
            else
            {
                pragma(build_def, "SUBSYSTEM CONSOLE,4.0");
            }
        }
    }
}
*/
 // pragma(link, "SUBSYSTEM WINDOWS,4.0");



// Windows libraries that DFL depends on. Put here instead of using LoadLibrary to manually load everything - D.O
pragma(lib, "advapi32");
pragma(lib, "comdlg32");
pragma(lib, "comctl32");
pragma(lib, "gdi32");
pragma(lib, "ole32");
pragma(lib, "oleaut32");
pragma(lib, "ws2_32");
pragma(lib, "uuid");    
pragma(lib, "user32");

// This is to activate common controls ver. 6 without some wacky winapi calls. Disabled for now, but this (imo) is better than calling
// Application.enableVisualStyles() each time at startup. The proper way is by making an actual manifest file, but i don't know how to
// do this with VS + VisualD (at least ver. 1.3.1) - D.O
// pragma(linkerDirective, "\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0'  processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"");




public import
    dfl.base, dfl.menu, dfl.control, // dfl.usercontrol,
    dfl.form, dfl.drawing, dfl.panel, dfl.event,
    dfl.application, dfl.button, dfl.socket,
    dfl.timer, dfl.environment, dfl.label, dfl.textbox,
    dfl.listbox, dfl.splitter, dfl.groupbox, dfl.messagebox,
    dfl.registry, dfl.notifyicon, dfl.collections, dfl.data,
    dfl.clipboard, dfl.commondialog, dfl.richtextbox, dfl.tooltip,
    dfl.combobox, dfl.treeview, dfl.picturebox, dfl.tabcontrol,
    dfl.listview, dfl.statusbar, dfl.progressbar, dfl.resources,
    dfl.imagelist, dfl.toolbar;

