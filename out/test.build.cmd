set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\8.1\bin\x86;C:\D\dmd2\windows\bin;%PATH%
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\test.dep dmd -g -debug -w -wi -de -X -Xf"..\out\test.json" -c -of"..\out\test.obj" decimal.d test.d -unittest
if %errorlevel% neq 0 goto reportError

set LIB="C:\D\dmd2\windows\bin\..\lib"
echo. > D:\git\decimal\src\..\out\test.link.rsp
echo "..\out\test.obj","..\bin\test.exe","..\out\test.map",user32.lib+ >> D:\git\decimal\src\..\out\test.link.rsp
echo kernel32.lib/NOMAP/CO/NOI/DELEXE >> D:\git\decimal\src\..\out\test.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\test.lnkdep C:\D\dmd2\windows\bin\link.exe @D:\git\decimal\src\..\out\test.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist "..\bin\test.exe" (echo "..\bin\test.exe" not created! && goto reportError)

goto noError

:reportError
echo Building ..\bin\test.exe failed!

:noError
