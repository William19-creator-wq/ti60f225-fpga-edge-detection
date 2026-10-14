param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_fit_serial_20261011'
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Preserve old attempt; choose a fresh RunId'}
$flowRoot=Join-Path $runRoot 'flow'
New-Item -ItemType Directory -Path $flowRoot -Force|Out-Null
foreach($relative in @('rtl','deps','project')){Copy-Item -LiteralPath (Join-Path $taskRoot $relative) -Destination $flowRoot -Recurse}
function SaveJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))}
$files=@(Get-ChildItem -LiteralPath $flowRoot -File -Recurse|ForEach-Object{
    @{relative=$_.FullName.Substring($flowRoot.Length+1);sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}
})
SaveJson (Join-Path $runRoot 'inputs.json') $files
$psi=[Diagnostics.ProcessStartInfo]::new()
$psi.FileName=$toolRoot+'/python311/bin/python.exe';$psi.WorkingDirectory=Join-Path $flowRoot 'project'
$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
$arguments=@(($toolRoot+'/scripts/efx_run.py'),'fit_operand_component.xml','--flow','map',
    '--output_dir',(Join-Path $flowRoot 'outflow'),'--work_dir',(Join-Path $flowRoot 'work_map'),'--timeout','3600')
foreach($argument in $arguments){$psi.ArgumentList.Add($argument)}
foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),@('EFXIPM_HOME','ipm'),@('PYTHONHOME','python311'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){$psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')}
$psi.Environment['EFINITY_USER_DIR_INI']=(Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini').Replace('\','/')
$psi.Environment['QT_LOGGING_CONF']=$toolRoot+'/bin/lc.ini'
$psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
$psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
$start=[DateTime]::UtcNow;$process=[Diagnostics.Process]::Start($psi)
SaveJson (Join-Path $runRoot 'map.start.json') @{pid=$process.Id;started_at=$start.ToString('o');argv=$arguments;scope='FULL_FIT_COMPONENT_RESOURCE_MAPPING_NO_TEST_NO_PNR_NO_BIT_NO_HARDWARE'}
$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$progress=$start
while(-not$process.WaitForExit(1000)){
    if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){Write-Output ('FIT mapping pid='+$process.Id);$progress=[DateTime]::UtcNow}
}
$process.WaitForExit()
[IO.File]::WriteAllText((Join-Path $runRoot 'map.stdout.log'),$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $runRoot 'map.stderr.log'),$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
SaveJson (Join-Path $runRoot 'map.result.json') @{exit_code=$process.ExitCode;ended_at=[DateTime]::UtcNow.ToString('o');simulations_run=0;hardware_passed=$false;board_integration_proven=$false}
Write-Output ('FIT map exit '+$process.ExitCode+'; logs '+$runRoot)
exit $process.ExitCode
