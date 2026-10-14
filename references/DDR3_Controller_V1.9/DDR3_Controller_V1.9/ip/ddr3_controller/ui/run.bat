
<# : chooser.bat
@echo off
@echo 请选中Efinity目录中的setup.bat
setlocal
if exist path.txt (
	for /f "delims=" %%L in (path.txt) do (
		call %%L
		python ipgenerator.py
	)
) else (
	for /f "delims=" %%I in ('powershell -noprofile "iex (${%~f0} | out-string)"') do (
		call %%~I
		python ipgenerator.py
		echo %%~I > path.txt
	)
)
goto :EOF
: end Batch portion / begin PowerShell hybrid chimera #>

Add-Type -AssemblyName System.Windows.Forms
$f = new-object Windows.Forms.OpenFileDialog
$f.InitialDirectory = pwd
$f.Filter = "Bat Files (*.bat)|*.bat|All Files (*.*)|*.*"
$f.ShowHelp = $true
$f.Multiselect = $true
[void]$f.ShowDialog()
if ($f.Multiselect) { $f.FileNames } else { $f.FileName }
