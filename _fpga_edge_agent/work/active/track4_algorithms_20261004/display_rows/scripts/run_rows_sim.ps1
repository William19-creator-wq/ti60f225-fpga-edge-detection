param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[switch]$HD,[switch]$Minimum,[switch]$NearMax,[switch]$Join)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/display_rows'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
if($RunId -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid RunId'}
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Use a new attempt; preserve old evidence'}
New-Item -ItemType Directory -Path $runRoot|Out-Null
function WriteJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))}
function InvokeStage($Name,$Exe,$Arguments,$Timeout=600,[switch]$ExpectedFatal){
    $start=[DateTime]::UtcNow;$prefix=Join-Path $runRoot $Name
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$Exe;$psi.WorkingDirectory=$runRoot
    $psi.CreateNoWindow=$true;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    foreach($argument in $Arguments){$psi.ArgumentList.Add([string]$argument)}
    $process=[Diagnostics.Process]::Start($psi)
    WriteJson ($prefix+'.start.json') @{pid=$process.Id;parent_script_pid=$PID;executable=$Exe;argv=$Arguments;cwd=$runRoot;started_at=$start.ToString('o');process_start_time_utc=$process.StartTime.ToUniversalTime().ToString('o');timeout_seconds=$Timeout}
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false;$progress=$start
    while(-not $process.WaitForExit(1000)){
        if(([DateTime]::UtcNow-$start).TotalSeconds -ge $Timeout){$timedOut=$true;$process.Kill($true);break}
        if(([DateTime]::UtcNow-$progress).TotalSeconds -ge 30){Write-Output ($Name+' running pid='+$process.Id);$progress=[DateTime]::UtcNow}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    WriteJson ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Get-FileHash -LiteralPath ($prefix+'.stdout.log')).Hash;stderr_sha256=(Get-FileHash -LiteralPath ($prefix+'.stderr.log')).Hash}
    Write-Output ($Name+' exit='+$process.ExitCode+' timeout='+$timedOut)
    if($ExpectedFatal){
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'fatal exit probe' -Quiet)){throw 'Fatal exit probe did not reject'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; original logs retained')}
}
function SimulationMacro($Name,$Top){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),'run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}


$Width=20;$Height=8;$Rows=24
if($HD){$Width=1920;$Height=1080;$Rows=1080}
if($Minimum){$Width=4;$Height=2;$Rows=24}
if($NearMax){$Rows=3}
$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline-v1.1.json') -Raw|ConvertFrom-Json
foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen dependency drift'}}
$sourcePaths=@('rtl/display_row_pkg.sv','rtl/row_ram54.sv','rtl/display_row_bank.sv','rtl/display_rows3.sv','deps/atomic_mailbox.sv','deps/efx_ram10.v','tb/tb_display_rows.sv','model/row_reference.py','scripts/run_rows_sim.ps1')
if($Join){
 if($NearMax){throw 'Join uses ordinary non-wrapping row generation'}
 $sourcePaths=@($sourcePaths|Where-Object{$_ -ne 'tb/tb_display_rows.sv'})+@('deps/frame_owner_pkg.sv','deps/display_handoff_pkg.sv','deps/display_route.sv','deps/display_handoff.sv','tb/tb_row_scan_join.sv')
}
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$top='tb_display_rows'
if($Join){$top='tb_row_scan_join'}
try{
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($sourcePaths|Where-Object{$_ -match '\.(sv|v)$'}|ForEach-Object{Join-Path $taskRoot $_})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+$sv)
 $params=@(('-GTEST_ROW_W='+$Width),('-GTEST_ROW_H='+$Height),('-GTEST_ROW_COUNT='+$Rows),('-GTEST_ROW_MAX='+[int][bool]$NearMax))
 if($Join){$params=@(('-GTEST_JOIN_W='+$Width),('-GTEST_JOIN_H='+$Height))}
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','rows_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','rows_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 if(Test-Path -LiteralPath (Join-Path $runRoot 'protocol-metrics.json')){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'rows_vsim' $top
 InvokeStage 'rows_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','rows_opt','-do',$macro) 900
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $taskRoot 'model/row_reference.py'),$runRoot)
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_ddr_verified=$false;physical_cdc_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
