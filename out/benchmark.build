set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\8.1\bin\x86;C:\D\dmd2\windows\bin;%PATH%
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\benchmark.dep dmd -O -inline -release -w -wi -de -X -Xf"..\out\benchmark.json" -c -of"..\out\benchmark.obj" benchmark.d decimal.d
if %errorlevel% neq 0 goto reportError

set LIB="C:\D\dmd2\windows\bin\..\lib"
echo. > D:\git\decimal\src\..\out\benchmark.link.rsp
echo "..\out\benchmark.obj","..\bin\benchmark.exe","..\out\benchmark.map",user32.lib+ >> D:\git\decimal\src\..\out\benchmark.link.rsp
echo kernel32.lib/NOMAP/NOI/DELEXE >> D:\git\decimal\src\..\out\benchmark.link.rsp

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\benchmark.lnkdep C:\D\dmd2\windows\bin\link.exe @D:\git\decimal\src\..\out\benchmark.link.rsp
if %errorlevel% neq 0 goto reportError
if not exist "..\bin\benchmark.exe" (echo "..\bin\benchmark.exe" not created! && goto reportError)

goto noError

:reportError
echo Building ..\bin\benchmark.exe failed!

:noError
