@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Existing permanent ASCII aliases; this launcher does not change mappings.
set "FPGA_EF_ROOT=C:\Users\34528\FPGAEdgeLinks\Efinity2026_1"
set "FPGA_EF_WORK=C:\Users\34528\FPGAEdgeLinks\Work\active\gui_led"
set "FPGA_EF_CHECK=%FPGA_EF_ROOT%\bin\efinity.exe"
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH
set "FPGA_EF_CHECK=%FPGA_EF_ROOT%\bin\setup.bat"
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH
set "FPGA_EF_CHECK=%FPGA_EF_WORK%\."
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH
set "FPGA_EF_CHECK=%FPGA_EF_WORK%\user_dir.ini"
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH
set "FPGA_EF_CHECK=%FPGA_EF_WORK%\efinity_user\."
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH
set "FPGA_EF_CHECK=%FPGA_EF_WORK%\efinity_user\app.ini"
if not exist "%FPGA_EF_CHECK%" goto :MISSING_PATH

call "%FPGA_EF_ROOT%\bin\setup.bat"
set "FPGA_EF_EXIT=%ERRORLEVEL%"
if not "%FPGA_EF_EXIT%"=="0" goto :SETUP_ERROR
rem Override setup's global preference path only in this process and its children.
set "EFINITY_USER_DIR=%FPGA_EF_WORK:\=/%/efinity_user"
set "EFINITY_USER_DIR_INI=%FPGA_EF_WORK:\=/%/user_dir.ini"
set "PYTHONDONTWRITEBYTECODE=1"
if not defined EFINITY_HOME goto :ENV_ERROR
if not defined PYTHONHOME goto :ENV_ERROR
if not defined QT_QPA_PLATFORM_PLUGIN_PATH goto :ENV_ERROR
if not exist "%EFINITY_HOME%/bin/efinity.exe" goto :ENV_ERROR
if not exist "%PYTHONHOME%/." goto :ENV_ERROR
if not exist "%QT_QPA_PLATFORM_PLUGIN_PATH%/." goto :ENV_ERROR
pushd "%FPGA_EF_WORK%"
if errorlevel 1 goto :WORK_ERROR
echo Open Project: %FPGA_EF_WORK%\LED_8bit_Test.xml
echo Close Efinity and its child tools before closing this launcher.
start "" /wait "%FPGA_EF_ROOT%\bin\efinity.exe"
set "FPGA_EF_EXIT=%ERRORLEVEL%"
popd
if not "%FPGA_EF_EXIT%"=="0" goto :LAUNCH_ERROR
exit /b %FPGA_EF_EXIT%

:MISSING_PATH
echo Required path is missing: "%FPGA_EF_CHECK%"
echo Restore the existing tool or workspace path before trying again.
pause
exit /b 2
:SETUP_ERROR
echo Efinity setup failed with exit code %FPGA_EF_EXIT%.
pause
exit /b %FPGA_EF_EXIT%
:ENV_ERROR
echo Efinity setup did not provide valid tool, Python or Qt paths.
pause
exit /b 3
:WORK_ERROR
echo Cannot enter the working directory: "%FPGA_EF_WORK%"
pause
exit /b 4
:LAUNCH_ERROR
echo Efinity returned exit code %FPGA_EF_EXIT%. Review the messages above.
pause
exit /b %FPGA_EF_EXIT%
