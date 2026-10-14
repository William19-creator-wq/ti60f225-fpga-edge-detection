@echo off
setlocal
rem Temporary ASCII alias. Never replace an existing drive or mapping.
if exist R:\ goto :DRIVE_BUSY
subst R: "%~dp0.."
if errorlevel 1 goto :MAP_ERROR

set "FPGA_EF_ROOT=R:\efinity-2026.1.132-windows-x64.tar\efinity-2026.1.132-windows-x64\efinity\2026.1"
if not exist "%FPGA_EF_ROOT%\bin\efinity.exe" goto :TOOL_ERROR
call "%FPGA_EF_ROOT%\bin\setup.bat"
rem Use project-local preferences; do not modify the global user profile.
set "EFINITY_USER_DIR=R:/_fpga_edge_agent/work/active/gui_led/efinity_user"
set "EFINITY_USER_DIR_INI=R:/_fpga_edge_agent/work/active/gui_led/user_dir.ini"
set "PYTHONDONTWRITEBYTECODE=1"
if not exist "R:\_fpga_edge_agent\work\active\gui_led\efinity_user" mkdir "R:\_fpga_edge_agent\work\active\gui_led\efinity_user"
if not exist "%EFINITY_USER_DIR_INI%" (
  > "%EFINITY_USER_DIR_INI%" echo [General]
  >> "%EFINITY_USER_DIR_INI%" echo EFINITY_USER_DIR=%EFINITY_USER_DIR%
)
pushd "R:\_fpga_edge_agent\work\active\gui_led"
echo Open Project: R:\_fpga_edge_agent\work\active\gui_led\LED_8bit_Test.xml
echo Close Efinity and its child tools before closing this launcher.
start "" /wait "%FPGA_EF_ROOT%\bin\efinity.exe"
set "FPGA_EF_EXIT=%ERRORLEVEL%"
popd
rem Remove only the alias established by this invocation.
subst R: /d
exit /b %FPGA_EF_EXIT%

:DRIVE_BUSY
echo R: is already in use. Close a previous Efinity launcher, or ask for a different drive letter.
pause
exit /b 2
:MAP_ERROR
echo Cannot create the temporary R: drive. No existing mapping was changed.
pause
exit /b 3
:TOOL_ERROR
echo Efinity executable was not found at the expected location.
subst R: /d
pause
exit /b 4
