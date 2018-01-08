set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\8.1\bin\x86;C:\D\dmd2\windows\bin;%PATH%
if %errorlevel% neq 0 goto reportError

if %errorlevel% neq 0 goto reportError
copy nul > ..\lib\doc.lib

if not exist "..\lib\doc.lib" (echo "..\lib\doc.lib" not created! && goto reportError)

goto noError

:reportError
echo Building ..\lib\doc.lib failed!

:noError
