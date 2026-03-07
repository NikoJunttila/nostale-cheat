@echo off
setlocal

if "%~1"=="" (
    goto build_dll
) else (
    goto %~1
)

:build_dll
@echo Building simple.dll
odin build ./simple-dll/ -target:windows_i386 -build-mode:dll -out:simple.dll
del /q *.obj *.exp *.lib
exit /b %errorlevel%

:injector
@echo Building injector.exe
odin build ./injector/ -target:windows_i386 -out:injector.exe
exit /b %errorlevel%

:simple
@echo Building simple injector.exe
odin build ./simple-injector/ -target:windows_i386 -out:simple.exe
exit /b %errorlevel%

:example
@echo Building simple injector.exe
odin build ./example32bit/ -target:windows_i386 -out:exampletotarget.exe
exit /b %errorlevel%

:clean
@echo Cleaning up object files
del /q *.obj
exit /b %errorlevel%
