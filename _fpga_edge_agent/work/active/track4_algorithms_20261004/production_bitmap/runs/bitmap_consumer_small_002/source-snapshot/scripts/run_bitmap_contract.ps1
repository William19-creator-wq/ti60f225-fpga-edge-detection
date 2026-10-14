param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[int]$TestWidth=34,[int]$TestHeight=20,[switch]$HD)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/production_bitmap'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Use a new attempt; preserve prior evidence'}
if($HD -and ($TestWidth-ne1920 -or $TestHeight-ne1080)){throw 'HD requires1920x1080'}
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
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'expected BITMAP CONSUMER fatal probe' -Quiet)){throw 'Fatal exit probe did not reject'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; original logs retained')}
}
function SimulationMacro($Name,$Top){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),'run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}


$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'consumer-baseline.json') -Raw|ConvertFrom-Json
if($baseline.files.Count-ne19 -or $baseline.runtime_sources.Count-ne11){throw '19 frozen inputs and11 actual runtime dependencies required'}
$frozen=@()
foreach($f in $baseline.files){
 if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen consumer input drift'}
 $copy=Join-Path $runRoot ('source-snapshot/'+$f.relative)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $f.path -Destination $copy
 if((Get-FileHash -LiteralPath $copy).Hash-ne$f.sha256){throw 'Frozen input copy drift'}
 $frozen+=@{original=$f.path;snapshot=$copy;relative=$f.relative;sha256=$f.sha256}
}
WriteJson (Join-Path $runRoot 'frozen-input-manifest.json') $frozen
$paths=@($baseline.runtime_sources)+@('tb/axi128_bitmap_frame_memory.sv','tb/tb_bitmap_display_contract.sv','model/bitmap_display_reference.py','scripts/run_bitmap_contract.ps1')
if($paths.Count-ne15){throw '15 runtime sources required'}
$snapshot=@()
foreach($relative in $paths){
 $path=Join-Path $taskRoot $relative;$copy=Join-Path $runRoot ('source-snapshot/'+$relative);$hash=(Get-FileHash -LiteralPath $path).Hash
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $path -Destination $copy
 if((Get-FileHash -LiteralPath $copy).Hash-ne$hash){throw 'Source snapshot drift'}
 $snapshot+=@{path=$path;snapshot=$copy;relative=$relative;sha256=$hash}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$top='tb_bitmap_display_contract'
try{
 $argv=@('-B',(Join-Path $runRoot 'source-snapshot/model/bitmap_display_reference.py'),'generate',$runRoot,'--width',$TestWidth,'--height',$TestHeight)
 if($HD){$argv+='--hd'}
 InvokeStage 'generate' $taskPython $argv 900
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative-match'\.(sv|v)$'}|Sort-Object @{Expression={if($_.relative-match'_pkg\.sv$'){0}elseif($_.relative-match'^vendor/'){1}else{2}}}|ForEach-Object{$_.snapshot})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-svinputport=net','-work','work')+$sv)
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') @('+acc',('work.'+$top),'-o','consumer_opt',('-GTEST_BITMAP_W='+$TestWidth),('-GTEST_BITMAP_H='+$TestHeight),('-GTEST_BITMAP_HD='+[int]$HD.IsPresent))
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','consumer_opt',('+RUN_DIR='+$runRoot),'+FATAL_PROBE','-do',$macro) 300 -ExpectedFatal
 if(Test-Path -LiteralPath (Join-Path $runRoot 'consumer-metrics.json')){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'consumer_vsim' $top
 InvokeStage 'consumer_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','consumer_opt',('+RUN_DIR='+$runRoot),'-do',$macro) 3600
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/bitmap_display_reference.py'),'audit',$runRoot) 1800
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Current/snapshot source drift'}}
 foreach($f in $frozen){if((Get-FileHash -LiteralPath $f.original).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Frozen input drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_simulation_rerun=$true;actual_ddr_verified=$false;production_frame_reference_authority_verified=$false;hardware_actions=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
