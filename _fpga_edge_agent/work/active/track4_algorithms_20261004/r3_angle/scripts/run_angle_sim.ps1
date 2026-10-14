param([Parameter(Mandatory)][string]$RunId,[ValidateSet('All','Core','Probe')][string]$Suite='All')
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_angle'
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
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'expected ANGLE fatal probe' -Quiet)){throw 'Fatal exit probe did not reject'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; original logs retained')}
}
function SimulationMacro($Name,$Top){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),'run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}
$sourcePaths=@('rtl/angle_protocol_pkg.sv','rtl/angle_math.sv','rtl/angle_rom.sv','rtl/angle_core.sv','rtl/reset_sync.sv','rtl/angle_probe_top.sv','rtl/angle_boundary.mem','rtl/projection_coeff.mem',
 'model/angle_constants.py','model/angle_reference.py','model/angle_vectors.py','tb/tb_angle_helpers.sv','tb/tb_angle_core.sv','tb/tb_angle_probe_top.sv',
 'scripts/run_angle_sim.ps1','scripts/run_angle_build.ps1','scripts/postroute.tcl','project/angle_probe.xml','project/angle_probe.peri.xml','project/angle_probe.sdc')
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
    InvokeStage 'audit_constants' $taskPython @((Join-Path $taskRoot 'model/angle_vectors.py'),'audit-constants',$runRoot) 900
    InvokeStage 'generate' $taskPython @((Join-Path $taskRoot 'model/angle_vectors.py'),'generate',$runRoot) 900
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sources=@($sourcePaths|Where-Object{$_ -match '\.sv$'}|ForEach-Object{Join-Path $taskRoot $_})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-work','work')+$sources)
    $targets=[Collections.Generic.List[object]]::new();$targets.Add(@('helpers','tb_angle_helpers'))
    if($Suite -in @('All','Core')){$targets.Add(@('core','tb_angle_core'))}
    if($Suite -in @('All','Probe')){$targets.Add(@('probe','tb_angle_probe_top'))}
    foreach($entry in $targets){
        $name=$entry[0];$top=$entry[1];$optimized=$name+'_opt'
        InvokeStage ($name+'_vopt') (Join-Path $taskTool 'vopt.exe') @('+acc',('work.'+$top),'-o',$optimized)
        if($name -eq 'core'){
            $macro=SimulationMacro 'fatal_probe' $top
            InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop',$optimized,('+RUN_DIR='+$runRoot),'+FATAL_PROBE','-do',$macro) 300 -ExpectedFatal
            if(Test-Path -LiteralPath (Join-Path $runRoot 'core-result.json')){throw 'Fatal run wrote success'}
        }
        $macro=SimulationMacro ($name+'_vsim') $top
        InvokeStage ($name+'_vsim') (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop',$optimized,('+RUN_DIR='+$runRoot),'-do',$macro) 3600
        if($name -in @('core','probe')){InvokeStage ('audit_'+$name) $taskPython @((Join-Path $taskRoot 'model/angle_vectors.py'),('audit-'+$name),$runRoot) 900}
    }
    foreach($entry in $snapshot){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Source or actual readmemh ROM changed during run'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status=($(if($Suite -eq 'All'){'PASS'}else{'PARTIAL_PASS'}));suite=$Suite;finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;full_project_goal_complete=$false}
}catch{
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message;full_project_goal_complete=$false}
    throw
}