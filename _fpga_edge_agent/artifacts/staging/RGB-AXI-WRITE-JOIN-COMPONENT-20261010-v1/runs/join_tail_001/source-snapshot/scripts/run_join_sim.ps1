param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId, [int]$TestWidth=34, [int]$TestHeight=19, [switch]$Full, [switch]$Protocol)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/rgb_axi_write_join'
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
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'expected RGB JOIN fatal probe' -Quiet)){throw 'Fatal exit probe did not reject'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; original logs retained')}
}
function SimulationMacro($Name,$Top){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),'run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}


$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline.json') -Raw|ConvertFrom-Json
if($baseline.files.Count-ne11){throw 'Eleven frozen inputs required'}
foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen dependency drift'}}
foreach($dep in @('rgb_source_writer.sv','rgb_source_ram_word.sv','axi_write_pair_service.sv','axi_line_bridge.sv','efx_ram10.v')){
 $f=$baseline.files|Where-Object{$_.relative-eq('inputs/'+$dep)}
 if((Get-FileHash -LiteralPath (Join-Path $taskRoot ('deps/'+$dep))).Hash-ne$f.sha256){throw 'Actual dependency copy drift'}
}
$sourcePaths=@('rtl/rgb_axi_write_join.sv','deps/rgb_source_writer.sv','deps/rgb_source_ram_word.sv','deps/axi_write_pair_service.sv','deps/axi_line_bridge.sv','deps/efx_ram10.v','tb/tb_rgb_axi_write_join.sv','model/join_reference.py','scripts/run_join_sim.ps1')
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
foreach($f in $snapshot){
 $copy=Join-Path $runRoot ('source-snapshot/'+$f.relative)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $f.path -Destination $copy
 $f.snapshot=$copy
 if((Get-FileHash -LiteralPath $copy).Hash-ne$f.sha256){throw 'Initial source snapshot drift'}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$top='tb_rgb_axi_write_join'
try{
 $generate=@('-B',(Join-Path $runRoot 'source-snapshot/model/join_reference.py'),'generate',$runRoot,'--width',$TestWidth,'--height',$TestHeight)
 if($Full){$generate+='--full'};if($Protocol){$generate+='--protocol'}
 InvokeStage 'generate' $taskPython $generate 1800
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative -match '\.(sv|v)$'}|ForEach-Object{$_.snapshot})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-svinputport=net','-work','work')+$sv)
 $params=@(('-GTEST_WIDTH='+$TestWidth),('-GTEST_HEIGHT='+$TestHeight),('-GTEST_PROTOCOL='+[int]$Protocol.IsPresent))
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','join_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','join_opt',('+RUN_DIR='+$runRoot),'+FATAL_PROBE','-do',$macro) 300 -ExpectedFatal
 if((Test-Path -LiteralPath (Join-Path $runRoot 'join-result.json')) -or (Test-Path -LiteralPath (Join-Path $runRoot 'join-audit.json'))){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'join_vsim' $top
 InvokeStage 'join_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','join_opt',('+RUN_DIR='+$runRoot),'-do',$macro) 1800
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/join_reference.py'),'audit',$runRoot) 1800
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_ddr_verified=$false;physical_cdc_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
