// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

/// Imports all of DFL's public interface.
module dfl;

// Windows libraries that DFL2 depends on. Put here instead of using LoadLibrary to manually load everything - D.O
pragma(lib, "advapi32");
pragma(lib, "comdlg32");
pragma(lib, "comctl32");
pragma(lib, "gdi32");
pragma(lib, "ole32");
pragma(lib, "oleaut32");
pragma(lib, "ws2_32");
pragma(lib, "uuid");    
pragma(lib, "user32");

// This is to activate common controls ver. 6 without some wacky winapi calls. Enabled to not rely on Application.enableVisualStyles()
// Passing /MANIFESTDEPENDENCY to the VS linker makes it include the dependency into a manifest file, creating one if missing
// It would probably be better to create dfl2.manifest and link with it, but i don't know how to do this with VisualD (at least ver. 1.3.1)
enum LINK_ENABLE_COMCTRL = 
"\"/MANIFESTDEPENDENCY:type='win32'
name='Microsoft.Windows.Common-Controls'
version='6.0.0.0'
processorArchitecture='*'
publicKeyToken='6595b64144ccf1df'
language='*'\"";
pragma(linkerDirective, LINK_ENABLE_COMCTRL);

public import
    dfl.application,
    dfl.base,
    dfl.button,
    dfl.clipboard,
    dfl.collections,
    dfl.combobox,
    dfl.commandbutton,
    dfl.commondialog,
    dfl.control,
    dfl.data,
    dfl.drawing,
    dfl.environment,
    dfl.event,
    dfl.form,
    dfl.groupbox,
    dfl.imagelist,
    dfl.label,
    dfl.listbox,
    dfl.listview,
    dfl.menu,
    dfl.messagebox,
    dfl.notifyicon,
    dfl.panel,
    dfl.picturebox,
    dfl.progressbar,
    dfl.registry,
    dfl.resources,
    dfl.richtextbox,
    dfl.splitbutton,
    dfl.splitter,
    dfl.statusbar,
    dfl.tabcontrol,
    dfl.textbox,
    dfl.timer,
    dfl.toolbar,
    dfl.tooltip,
    dfl.trackbar,
    dfl.treeview;