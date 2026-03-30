@echo off
setlocal

if "%~1"=="" (
    goto build_dll
) else (
    goto %~1
)

:build_dll
@echo Building simple.dll (MicroUI GDI)
odin build . -target:windows_i386 -build-mode:dll -out:simple.dll --debug
del /q *.obj *.exp *.lib
exit /b %errorlevel%