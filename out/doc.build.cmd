set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\8.1\bin\x86;C:\D\dmd2\windows\bin;%PATH%
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\doc.dep dmd -O -inline -release -w -wi -de -D -Dd..\doc -X -Xf"..\out\doc.json" -c -od..\out macros\dlang.org.ddoc macros\doc.ddoc macros\html.ddoc macros\macros.ddoc macros\std.ddoc decimal.d
if %errorlevel% neq 0 goto reportError

goto noError

:reportError
echo Building ..\lib\doc.lib failed!

:noError
