set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Tools\MSVC\14.12.25827\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE;C:\Program Files (x86)\Windows Kits\8.1\bin\x86;C:\D\dmd2\windows\bin;%PATH%
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps ..\out\decimal.dep dmd -O -inline -release -w -wi -lib -de -noboundscheck -X -Xf"..\out\\decimal32.json" -of"..\lib\\decimal32.lib" -map "..\out\\decimal.map" -L/NOMAP decimal.d
if %errorlevel% neq 0 goto reportError
if not exist "..\lib\\decimal32.lib" (echo "..\lib\\decimal32.lib" not created! && goto reportError)

goto noError

:reportError
echo Building ..\lib\\decimal32.lib failed!

:noError
