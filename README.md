DFL2
====
DFL2, or D Forms Library 2, is a GUI library for Windows.
DFL2 is based on original DFL by Christopher E. Miller, which was abandoned in 2011.
This project is an attempt to bring DFL to modern D2 and make it a viable alternative to other existing GUI libraries.

linker libs:
---
user32.lib ole32.lib oleAut32.lib gdi32.lib Comctl32.lib Comdlg32.lib advapi32.lib uuid.lib ws2_32.lib.

How to start:
--
git clone https://github.com/DeenOConnor/dfl2

or 

dub fetch dfl2 --local

The latest features:
---
1、dfl can be build by dco,and can get the  64 bit version.

2、dfl can be used in Visual Studio .net (here VS 2010)， whose intellisense will help you very well(to look at the Screenshot),now it can debug in VD 0.3.39.

3、dfl can be used in DUB:

base work
--
You should  copy the 'dfl2\source\dfl' folder to your  'dmd2\window\import'(if not exists,create it),and add importpath to sc.ini (after 'DFLAGS=', add "-I%@P%\..\..\windows\import").

How to get the libs or exe files:
---
1、 Double click the 'build.bat',to get them in the folder,if your x64 can work,you can get the 64 bit  version 'dfl64.lib'.(some things will be auto work)

or

2、run the dubbuild.bat in the path, to get them in 'debug' folder.
   or 
     dub fetch dfl2,and run the dubbuild.bat in the path(C:\Users\[yourUserName]\AppData\Roaming\dub\packages\dfl2-1.0.7)

or

3、Open the dfl.sln, and run the projects to get them in 'debug' folder and 'release' folder(Now,auto copy to the '$(DMDInstallDir)windows\lib' OR 'bin' folder ).
	 
note:  If you want to get the release version ,use dcobuild.bat. or vs2010 please.
---

New thing :  dco.exe
---
'dco.exe' can create the batch processing info :

How to use the 'dco':
--- 
  dco ↓

or

  dco app.d

or

  dco app.d -gui 
 
more info : dco -h

more examples: git clone https://github.com/FrankLIKE/dfl-examples-d2
--

  Screenshot:
---
   in dco:

  ![dfl2 In dco](https://raw.githubusercontent.com/FrankLIKE/dfl2/master/Images/dco_build.png)

   in DUB:

  ![dfl2 In DUB](https://raw.githubusercontent.com/FrankLIKE/dfl2/master/Images/dub_build.png)
   
   in VS2010

  ![dfl's intellisense in VS2010](https://raw.githubusercontent.com/FrankLIKE/dfl2/master/Images/dflpart.png)

