DFL2
====
DFL2, or D Forms Library 2, is a GUI library for Windows. \
DFL2 is based on original DFL by Christopher E. Miller, which was abandoned in 2011. \
This project is an attempt to bring DFL to modern D2 and make it a viable alternative to other existing GUI libraries. \
Latest DMD version that compiles the library - 2.108.0

Linker dependencies:
---
advapi32.lib, comdlg32.lib, comctl32.lib, gdi32.lib, ole32.lib, oleaut32.lib, ws2_32.lib, uuid.lib and user32.lib

How to start:
--
git clone https://github.com/DeenOConnor/dfl2 \
Copy `dfl2\source\dfl` folder to your project \
Use with `import dfl.all;`

The latest features:
---
1 - It works. \
2 - Strings are all UTF-16 (or WCHAR) where possible. Respective WinAPI calls are also WCHAR. \
3 - Full 64-bit support at the cost of not supporting 32-bit. \
4 - Some additional features that don't exist in original DFL.

How to build separately:
---
Your best option is to use Visual Studio with VisualD extension to open and build the project. \
Building with DMD only is also possible, starting in dfl2\source folder: \
To generate a .lib file `dmd -m64 -J=dfl -lib -of="..\dfl2.lib" dfl\package.d` \
To generate a .dll file `dmd -m64 -J=dfl -shared -c -of="..\dfl2.dll" dfl\package.d` \
Build command tested with powershell on windows 10 22h2



  Screenshots:
---
   
   IntelliSense in VS 2022

  ![dfl's intellisense in VS 2022](https://raw.githubusercontent.com/DeenOConnor/dfl2/devel/Images/vs2022.png)

