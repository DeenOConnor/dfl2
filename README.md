DFL2
====
DFL2, or D Forms Library 2, is a GUI library for Windows. \
DFL2 is based on original DFL by Christopher E. Miller, which was abandoned in 2011. \
This project is an attempt to bring DFL to modern D2 and make it a viable alternative to other existing GUI libraries. \
Latest DMD version that compiles the library - 2.105.3

linker libs:
---
advapi32.lib, comdlg32.lib, comctl32.lib, gdi32.lib, ole32.lib, oleaut32.lib, ws2_32.lib, uuid.lib and user32.lib

How to start:
--
git clone https://github.com/DeenOConnor/dfl2 \
Copy `dfl2\source\dfl` folder to your project \
Use with `import dfl.all;`

The latest features:
---
1 - it works (somewhat). \
2 - Strings are all UTF-16 (or WCHAR) where possible. Respective WinAPI calls are also WCHAR. \
3 - Full 64-bit support, 32-bit is not supported and build fails for 32-bit.

How to get the libs or exe files:
---
Since this is still a WIP, best way is to avoid this version of DFL. If you want, you may try [Rayerd's version](https://github.com/Rayerd/dfl) \
If you still want to try this version, then your best option is to use Visual Studio with VisualD extension to open and build the project. \
Alternatively, you could try building with DMD only, starting in dfl2\source\dfl folder: \
To generate a .lib file `dmd -lib -m64 -of="..\..\dfl2.lib" all.d application.d base.d button.d clipboard.d clippingform.d collections.d colordialog.d combobox.d commondialog.d control.d data.d drawing.d environment.d event.d filedialog.d folderdialog.d fontdialog.d form.d groupbox.d imagelist.d label.d listbox.d listview.d menu.d messagebox.d notifyicon.d package.d panel.d picturebox.d progressbar.d registry.d resources.d richtextbox.d socket.d splitter.d statusbar.d tabcontrol.d textbox.d timer.d toolbar.d tooltip.d treeview.d usercontrol.d` \
Right now there are problems with generating .dll file, so no instructions for now. \
Build command tested with powershell on windows 10 22h2

note:  The library is updated to work for 64-bit only! It is possible to build it for 32-bit, but it requires some updates to the code!
---



  Screenshots:
---
   
   IntelliSense in VS 2022

  ![dfl's intellisense in VS 2022](https://raw.githubusercontent.com/DeenOConnor/dfl2/devel/Images/vs2022.png)

