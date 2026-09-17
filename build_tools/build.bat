setlocal

set BARE_COMMAND=.\build_tools\nasm.exe
set OPTIMIZATION_FLAG=-O0

if "%~1" == "o" (set OPTIMIZATION_FLAG=-Ox)

set COMMAND=%BARE_COMMAND% %OPTIMIZATION_FLAG%

cd ..
mkdir build

%COMMAND% -fobj src/main.asm -o build/main.o
%COMMAND% -fobj src/utils/memory.asm -o build/memory.o
%COMMAND% -fobj src/utils/console.asm -o build/console.o
%COMMAND% -fobj src/utils/string.asm -o build/string.o

.\build_tools\alink.exe -subsys console -oPE ^
build/main.o ^
build/memory.o ^
build/console.o ^
build/string.o ^
-o build/test.exe

cd build
.\test.exe

endlocal