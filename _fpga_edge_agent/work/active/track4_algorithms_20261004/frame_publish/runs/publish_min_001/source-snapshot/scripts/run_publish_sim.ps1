param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
      [switch]$HD,[switch]$Minimum,[switch]$CompileOnly)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/frame_publish'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Preserve original attempt; use a new RunId'}
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
        if(([DateTime]::UtcNow-$start).TotalSeconds-ge$Timeout){$timedOut=$true;$process.Kill($true);break}
        if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){Write-Output ($Name+' running pid='+$process.Id);$progress=[DateTime]::UtcNow}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    WriteJson ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Get-FileHash -LiteralPath ($prefix+'.stdout.log')).Hash;stderr_sha256=(Get-FileHash -LiteralPath ($prefix+'.stderr.log')).Hash}
    if($ExpectedFatal){
        if($timedOut -or $process.ExitCode-eq0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'fatal exit probe' -Quiet)){throw 'Fatal probe did not reject'}
    }elseif($timedOut -or $process.ExitCode-ne0){throw ($Name+' failed; original logs preserved')}
    Write-Output ($Name+' exit='+$process.ExitCode+' timeout='+$timedOut)
}
function SimulationMacro($Name){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}','onbreak {set rc 1; if {![catch {examine -radix binary /tb_frame_publish/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}','run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}
$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline.json') -Raw|ConvertFrom-Json
foreach($file in $baseline.files){if((Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256){throw 'Frozen input drift'}}
$sourcePaths=@($baseline.runtime_sources)+@('rtl/frame_owner_command_arbiter4.sv','rtl/frame_result_manager.sv','rtl/frame_result_retire.sv','rtl/frame_publish_control.sv','scripts/run_publish_sim.ps1')
if(-not $CompileOnly){$sourcePaths+=@('tb/tb_frame_publish.sv','model/publish_reference.py')}
foreach($relative in $sourcePaths){if(-not(Test-Path -LiteralPath (Join-Path $taskRoot $relative))){throw ('Implementation not yet complete: '+$relative)}}
New-Item -ItemType Directory -Path $runRoot|Out-Null
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
foreach($file in $snapshot){
    $copy=Join-Path $runRoot ('source-snapshot/'+$file.relative)
    New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
    Copy-Item -LiteralPath $file.path -Destination $copy
    $file.snapshot=$copy
    if((Get-FileHash -LiteralPath $copy).Hash-ne$file.sha256){throw 'Initial snapshot drift'}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sv=@($snapshot|Where-Object{$_.relative-match'\.(sv|v)$'}|ForEach-Object{$_.snapshot})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-svinputport=net','-work','work')+$sv)
    if(-not $CompileOnly){
        $width=34;$height=20
        if($Minimum){$width=4;$height=2}
        if($HD){$width=1920;$height=1080}
        InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') @('+acc','work.tb_frame_publish','-o','publish_opt',('-GTEST_W='+$width),('-GTEST_H='+$height))
        $macro=SimulationMacro 'fatal_probe'
        InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','publish_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
        if(Test-Path -LiteralPath (Join-Path $runRoot 'publish-metrics.json')){throw 'Fatal probe wrote success metrics'}
        $macro=SimulationMacro 'publish_vsim'
        InvokeStage 'publish_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','publish_opt','-do',$macro) 1800
        InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/publish_reference.py'),$runRoot)
    }
    foreach($file in $snapshot){if((Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256 -or (Get-FileHash -LiteralPath $file.snapshot).Hash-ne$file.sha256){throw 'Source drift'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status=$(if($CompileOnly){'PASS_COMPILE_ONLY_DYNAMIC_UNVERIFIED'}else{'PASS'});finished=$true;compile_only=[bool]$CompileOnly;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;producer_and_row0_closed_fixture_only=$true;actual_ddr_verified=$false;whole_system_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
