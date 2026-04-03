@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
cl /nologo /W3 /O2 C:\Users\kraken\forge\demos\win_demo_run.c /Fe:C:\Users\kraken\forge\demos\win_demo.exe > C:\Users\kraken\forge\demos\build_output.txt 2>&1
if %errorlevel% neq 0 (
    echo BUILD FAILED >> C:\Users\kraken\forge\demos\build_output.txt
    exit /b %errorlevel%
)
echo. >> C:\Users\kraken\forge\demos\build_output.txt
C:\Users\kraken\forge\demos\win_demo.exe >> C:\Users\kraken\forge\demos\build_output.txt 2>&1
