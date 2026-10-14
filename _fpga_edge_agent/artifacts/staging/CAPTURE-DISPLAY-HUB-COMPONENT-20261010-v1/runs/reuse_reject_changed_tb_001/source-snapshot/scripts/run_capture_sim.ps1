param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId, [int] $TestWidth=34, [int] $TestHeight=19, [switch]$Full, [switch]$Protocol,
      [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ReuseSimulationRun)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/capture_display_hub'
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
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'expected CAPTURE HUB fatal probe' -Quiet)){throw 'Fatal exit probe did not reject'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; original logs retained')}
}
function SimulationMacro($Name,$Top){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),'run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}


$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline.json') -Raw|ConvertFrom-Json
if($baseline.files.Count-ne58){throw 'Fifty-eight frozen inputs required'}
foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen dependency drift'}}
foreach($dep in $baseline.runtime_dependencies){
 if((Get-FileHash -LiteralPath (Join-Path $taskRoot $dep.relative)).Hash-ne$dep.sha256){throw 'Actual runtime dependency drift'}
}
$sourcePaths=@($baseline.runtime_dependencies|ForEach-Object{$_.relative})+@('rtl/video_memory_hub.sv','rtl/capture_canny_rpc.sv','rtl/capture_display_axi.sv','tb/axi128_duplex_byte_memory.sv','tb/tb_capture_display_axi.sv','model/capture_display_reference.py','scripts/run_capture_sim.ps1')
if($sourcePaths.Count-ne52){throw '52 runtime simulation sources required'}
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
foreach($f in $snapshot){
 $copy=Join-Path $runRoot ('source-snapshot/'+$f.relative)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $f.path -Destination $copy
 $f.snapshot=$copy
 if((Get-FileHash -LiteralPath $copy).Hash-ne$f.sha256){throw 'Initial source snapshot drift'}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$top='tb_capture_display_axi'
try{
 if($ReuseSimulationRun){
    # J2：仅复用已结束的实际仿真；新参考单独审计，旧FAIL从不重写。
    $priorRoot=Join-Path $taskRoot ('runs/'+$ReuseSimulationRun)
    $priorSuite=Get-Content -LiteralPath (Join-Path $priorRoot 'suite-result.json') -Raw|ConvertFrom-Json
    if($priorSuite.status-ne'PASS' -and $priorSuite.reason-ne'audit failed; original logs retained'){throw 'Only a successful simulation/audit-only failure may be recovered'}
    $priorSources=@(Get-Content -LiteralPath (Join-Path $priorRoot 'source-manifest.json') -Raw|ConvertFrom-Json)
    if($priorSources.Count-ne52){throw 'Original52 source snapshots required'}
    $changed=@();$unchanged=0
    foreach($f in $priorSources){
        if((Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Original execution snapshot drift'}
        $now=@($snapshot|Where-Object{$_.relative-eq$f.relative})
        if($now.Count-ne1){throw 'Original/current source list mismatch'}
        if($now[0].sha256-ne$f.sha256){
            if($f.relative-notin@('model/capture_display_reference.py','scripts/run_capture_sim.ps1')){throw 'RTL/TB/native/math dependency changed; actual simulation must rerun'}
            $changed+=$f.relative
        }else{$unchanged++}
    }
    if($unchanged-lt50){throw 'At least50 actual execution/math inputs must match'}
    $oldModel=($priorSources|Where-Object{$_.relative-eq'model/capture_display_reference.py'}).snapshot
    $oldPrefix=([IO.File]::ReadAllText($oldModel).Replace("`r`n","`n") -split 'def audit_hub\(')[0]
    $newPrefix=([IO.File]::ReadAllText((Join-Path $taskRoot 'model/capture_display_reference.py')).Replace("`r`n","`n") -split 'def audit_hub\(')[0]
    if($oldPrefix-cne$newPrefix){throw 'Generator/import/math preparation changed; simulation reuse forbidden'}
    $meta=Get-Content -LiteralPath (Join-Path $priorRoot 'vector-summary.json') -Raw|ConvertFrom-Json
    $oldMetrics=Get-Content -LiteralPath (Join-Path $priorRoot 'protocol-metrics.json') -Raw|ConvertFrom-Json
    $hubMetrics=Get-Content -LiteralPath (Join-Path $priorRoot 'hub-protocol-metrics.json') -Raw|ConvertFrom-Json
    if($meta.width-ne$TestWidth -or $meta.height-ne$TestHeight -or $meta.full1080p-ne$Full.IsPresent -or -not$oldMetrics.finished -or -not$hubMetrics.finished -or $hubMetrics.cases-ne33){throw 'Recovered simulation geometry/completion mismatch'}
    if($oldMetrics.protocol_cases-ne$(if($Protocol){18}else{0})){throw 'Recovered actual capture protocol selection mismatch'}
    foreach($stage in @('generate','vlib','vlog','vopt','fatal_probe','hub_vopt','hub_fatal_probe','hub_vsim','capture_vsim')){
        $prefix=Join-Path $priorRoot $stage;$result=Get-Content -LiteralPath ($prefix+'.result.json') -Raw|ConvertFrom-Json
        if($result.timed_out){throw 'Timed-out execution cannot be recovered'}
        foreach($stream in @('stdout','stderr')){
            if((Get-FileHash -LiteralPath ($prefix+'.'+$stream+'.log')).Hash-ne$result.($stream+'_sha256')){throw 'Original process log SHA drift'}
        }
        if($stage-in@('fatal_probe','hub_fatal_probe')){
            if($result.exit_code-eq0 -or -not(Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'expected CAPTURE HUB fatal probe' -Quiet)){throw 'Original fatal rejection not proven'}
        }elseif($result.exit_code-ne0){throw 'Original real execution failed'}
    }
    $carried=@()
    foreach($file in @(Get-ChildItem -LiteralPath $priorRoot -File)){
        $copy=Join-Path $runRoot ('prior-execution/'+$file.Name)
        New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $copy
        $hash=(Get-FileHash -LiteralPath $file.FullName).Hash
        if((Get-FileHash -LiteralPath $copy).Hash-ne$hash){throw 'Recovered evidence copy drift'}
        $carried+=@{original=$file.FullName;snapshot=$copy;sha256=$hash}
        if($file.Name-notmatch '\.(start|result)\.json$|\.(stdout|stderr)\.log$|\.do$|^source-manifest\.json$|^suite-result\.json$|^reference-audit\.json$|^hub-protocol-result\.json$|^transcript$'){
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $runRoot $file.Name)
            if((Get-FileHash -LiteralPath (Join-Path $runRoot $file.Name)).Hash-ne$hash){throw 'Recovered data copy drift'}
        }
    }
    WriteJson (Join-Path $runRoot 'simulation-reuse.json') @{original_run=$ReuseSimulationRun;original_execution_sources=$priorSources;original_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $priorRoot 'source-manifest.json')).Hash;unchanged_execution_sources=$unchanged;changed_audit_organization_only=$changed;generator_import_prefix_equal=$true;carried_evidence=$carried;actual_simulation_rerun=$false;old_suite_unchanged=$true}
    Write-Output ('Recovered actual simulation evidence from '+$ReuseSimulationRun+'; current audit will run independently')
 }else{
 $generate=@('-B',(Join-Path $runRoot 'source-snapshot/model/capture_display_reference.py'),'generate',$runRoot,'--width',$TestWidth,'--height',$TestHeight)
 if($Full){$generate+='--full'};
 InvokeStage 'generate' $taskPython $generate 1800
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative -match '\.(sv|v)$'}|Sort-Object @{Expression={if($_.relative-match'_pkg\.sv$'){0}elseif($_.relative-match'vendor/'){1}else{2}}}|ForEach-Object{$_.snapshot})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-svinputport=net','-work','work')+$sv)
 if($Full -and ($TestWidth-ne1920 -or $TestHeight-ne1080)){throw 'Full requires1920x1080'}
 $params=@(('-GTEST_WIDTH='+$TestWidth),('-GTEST_HEIGHT='+$TestHeight),('-GTEST_PROTOCOL='+[int]$Protocol.IsPresent))
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','capture_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','capture_opt',('+RUN_DIR='+$runRoot),'+FATAL_PROBE','-do',$macro) 300 -ExpectedFatal
 if((Test-Path -LiteralPath (Join-Path $runRoot 'protocol-metrics.json')) -or (Test-Path -LiteralPath (Join-Path $runRoot 'reference-audit.json'))){throw 'Fatal probe wrote success metrics'}
 InvokeStage 'hub_vopt' (Join-Path $taskTool 'vopt.exe') @('+acc','work.tb_video_memory_hub_protocol','-o','hub_opt')
 $hubMacro=SimulationMacro 'hub_fatal_probe' 'tb_video_memory_hub_protocol'
 InvokeStage 'hub_fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','hub_opt',('+RUN_DIR='+$runRoot),'+FATAL_PROBE','-do',$hubMacro) 300 -ExpectedFatal
 if(Test-Path -LiteralPath (Join-Path $runRoot 'hub-protocol-metrics.json')){throw 'Hub fatal probe wrote success metrics'}
 $hubMacro=SimulationMacro 'hub_vsim' 'tb_video_memory_hub_protocol'
 InvokeStage 'hub_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','hub_opt',('+RUN_DIR='+$runRoot),'-do',$hubMacro) 600
 $macro=SimulationMacro 'capture_vsim' $top
 InvokeStage 'capture_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','capture_opt',('+RUN_DIR='+$runRoot),'-do',$macro) 1800
 }
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/capture_display_reference.py'),'audit',$runRoot) 1800
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;simulation_reused_from=$ReuseSimulationRun;actual_simulation_rerun=(-not[bool]$ReuseSimulationRun);actual_ddr_verified=$false;physical_cdc_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
