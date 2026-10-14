param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[switch]$HD,[switch]$Minimum,[ValidateSet(6,10,20)][int]$Width=20)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/display_row_stream'
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


$RunWidth=$Width;$Height=8;
if($HD){$RunWidth=1920;$Height=1080}
if($Minimum){$RunWidth=4;$Height=2;}
$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline-v1.1.json') -Raw|ConvertFrom-Json
foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen dependency drift'}}
$prior=$baseline.prior_implementation_snapshot
if((Get-FileHash -LiteralPath $prior.path).Hash-ne$prior.sha256){throw 'Prior implementation snapshot drift'}
$sourcePaths=@('deps/display_row_pkg.sv','deps/frame_owner_pkg.sv','deps/display_fetch_pkg.sv','deps/atomic_mailbox.sv','deps/row_ram54.sv','deps/display_row_bank.sv','deps/display_rows3.sv','deps/efx_ram10.v','deps/display_span_axi.sv','deps/display_meta_ram.sv','deps/display_row_reader.sv','deps/display_fetch_link.sv','deps/display_scan_prefetch_core.sv','deps/axi_read_byte_slave.sv','deps/display_renderer.sv','deps/video_timing_1080p_pair.sv','rtl/display_row_streamer.sv','tb/tb_row_stream.sv','model/stream_reference.py','scripts/run_stream_sim.ps1')
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
foreach($f in $snapshot){
 $copy=Join-Path $runRoot ('source-snapshot/'+$f.relative)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $f.path -Destination $copy
 $f.snapshot=$copy
 if((Get-FileHash -LiteralPath $copy).Hash-ne$f.sha256){throw 'Initial source snapshot drift'}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$top='tb_row_stream'
try{
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative -match '\.(sv|v)$'}|ForEach-Object{$_.snapshot})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+$sv)
 $params=@(('-GTEST_W='+$RunWidth),('-GTEST_H='+$Height))
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','stream_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','stream_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 if((Test-Path -LiteralPath (Join-Path $runRoot 'stream-metrics.json')) -or (Test-Path -LiteralPath (Join-Path $runRoot 'stream-metrics.json'))){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'stream_vsim' $top
 InvokeStage 'stream_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','stream_opt','-do',$macro) 1800
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/stream_reference.py'),$runRoot) 1800
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_ddr_verified=$false;physical_cdc_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
