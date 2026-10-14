param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[switch]$NearMax,[switch]$Small,
 [switch]$PostMap,[ValidatePattern('^[A-Za-z0-9_-]+$')][string]$MapRun)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/frame_owner'
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


$Width=1920;$Height=1080;if($Small){$Width=4;$Height=2}
$top='tb_frame_owner'
$sourcePaths=@('rtl/frame_owner_pkg.sv','rtl/frame_owner.sv','tb/tb_frame_owner.sv','model/frame_owner_reference.py','scripts/run_owner_sim.ps1')
if($PostMap){
 if($Small -or $NearMax -or -not$MapRun){throw 'PostMap requires production geometry and MapRun'}
 $mappedRoot=Join-Path $taskRoot ('runs/'+$MapRun)
 $mappedResult=Get-Content -LiteralPath (Join-Path $mappedRoot 'Map.result.json') -Raw|ConvertFrom-Json
 if($mappedResult.exit_code-ne0 -or $mappedResult.timed_out){throw 'MAP prerequisite failed'}
 foreach($entry in (Get-Content -LiteralPath (Join-Path $mappedRoot 'snapshot-manifest.json') -Raw|ConvertFrom-Json).files){
  if((Get-FileHash -LiteralPath $entry.snapshot).Hash-ne$entry.sha256){throw 'Frozen MAP input drift'}
 }
 $sourcePaths=@('rtl/frame_owner_pkg.sv',('runs/'+$MapRun+'/flow/outflow/frame_owner_component.map.v'),
  'tb/tb_frame_owner.sv','model/frame_owner_reference.py','scripts/run_owner_sim.ps1','deps/efx_ff.v','deps/efx_lut4.v')
}
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($sourcePaths|Where-Object{$_ -match '\.(sv|v)$'}|ForEach-Object{Join-Path $taskRoot $_})
 $defines=@();if($PostMap){$defines=@('+define+OWNER_POST_MAP')}
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+$defines+$sv)
 $params=@(('-GTEST_W='+$Width),('-GTEST_H='+$Height),('-GTEST_NEAR_MAX='+[int][bool]$NearMax))
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','control_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','control_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 if(Test-Path -LiteralPath (Join-Path $runRoot 'protocol-metrics.json')){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'control_vsim' $top
 InvokeStage 'control_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','control_opt','-do',$macro) 600
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $taskRoot 'model/frame_owner_reference.py'),$runRoot)
 foreach($entry in $snapshot){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;post_map_verified=[bool]$PostMap;map_run=$MapRun;physical_fence_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message}
 throw
}
