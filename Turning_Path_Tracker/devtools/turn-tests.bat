@echo off
REM ---------------------------------------------------------------------------
REM Unattended TURN test runner.
REM
REM   turn-tests.bat [script] [product] [template]
REM
REM   script   name of a .scr in this folder, without the extension.
REM            Default: turn-core-tests
REM   product  c3d   Civil 3D 2026          (default)
REM            acad  plain AutoCAD 2027
REM            2024  plain AutoCAD 2024
REM   template c3d   start from the Civil 3D Imperial NCS template.
REM            Needed only to create Civil 3D objects: a drawing started from
REM            acad.dwt has one alignment style and no label sets, and the
REM            Aecc COM calls fail with "the parameter is incorrect". The other
REM            suites deliberately do NOT pass a template -- launching with no
REM            drawing and no /t is the arrangement they were proven on.
REM
REM   devtools\turn-tests.bat turn-core-tests
REM   devtools\turn-tests.bat turn-integration-tests acad
REM   devtools\turn-tests.bat turn-release-smoke
REM
REM NO PATHS ARE HARDCODED HERE except the two AutoCAD installs. TURNDEV is this
REM file's own folder (%~dp0), handed to AutoCAD in the environment and read by
REM turn-dev-paths.lsp, which every .scr loads on its first line. Clone the tree
REM anywhere and the tests still run.
REM
REM The 2026 install registers only as Civil 3D on this machine, so its acad.exe
REM starts as the vertical no matter what; /product ACAD there does nothing.
REM Plain AutoCAD therefore means the 2024 install, which has a real one.
REM ---------------------------------------------------------------------------

setlocal

set TURNDEV=%~dp0
if "%TURNDEV:~-1%"=="\" set TURNDEV=%TURNDEV:~0,-1%

set SCR=%1
if "%SCR%"=="" set SCR=turn-core-tests

set PRODUCT=%2
if "%PRODUCT%"=="" set PRODUCT=c3d

set TEMPLATE=%3

if not exist "%TURNDEV%\%SCR%.scr" (
  echo ERROR: no such script: %TURNDEV%\%SCR%.scr
  exit /b 1
)

if /i "%PRODUCT%"=="c3d"  goto run_c3d
if /i "%PRODUCT%"=="acad" goto run_acad
if /i "%PRODUCT%"=="2024" goto run_2024
echo ERROR: product must be c3d, acad or 2024, not "%PRODUCT%"
exit /b 1

:run_c3d
set ACADDIR=C:\Program Files\Autodesk\AutoCAD 2026
if not exist "%ACADDIR%\acad.exe" goto no_install
set TSWITCH=
if /i "%TEMPLATE%"=="c3d" set TPL=%LOCALAPPDATA%\Autodesk\C3D 2026\enu\Template\_Autodesk Civil 3D (Imperial) NCS.dwt
if /i "%TEMPLATE%"=="c3d" if not exist "%TPL%" echo ERROR: template not found: %TPL% & exit /b 1
if /i "%TEMPLATE%"=="c3d" set TSWITCH=/t "%TPL%"
echo Running %SCR% on Civil 3D 2026 ...
"%ACADDIR%\acad.exe" /ld "%ACADDIR%\AecBase.dbx" /product C3D /language en-US /p "Turning_Path_Tracker" /nologo %TSWITCH% /b "%TURNDEV%\%SCR%.scr"
goto done

:run_acad
set ACADDIR=C:\Program Files\Autodesk\AutoCAD 2027
if not exist "%ACADDIR%\acad.exe" goto no_install
echo Running %SCR% on plain AutoCAD 2027 ...
"%ACADDIR%\acad.exe" /product ACAD /language "en-US" /p "Turning_Path_Tracker" /nologo /b "%TURNDEV%\%SCR%.scr"
goto done

:run_2024
set ACADDIR=C:\Program Files\Autodesk\AutoCAD 2024
if not exist "%ACADDIR%\acad.exe" goto no_install
echo Running %SCR% on plain AutoCAD 2024 ...
"%ACADDIR%\acad.exe" /product ACAD /language "en-US" /p "Turning_Path_Tracker" /nologo /b "%TURNDEV%\%SCR%.scr"
goto done

:no_install
echo ERROR: not installed: %ACADDIR%\acad.exe
exit /b 1

:done
echo Finished. Results in %TURNDEV%\turn-test-log.md
endlocal
