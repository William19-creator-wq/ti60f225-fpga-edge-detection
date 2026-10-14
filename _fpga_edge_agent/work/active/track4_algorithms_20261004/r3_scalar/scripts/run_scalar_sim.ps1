param([Parameter(Mandatory)][string]$RunId,[ValidateSet('All','Core','Probe')][string]$Suite='All')
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_scalar'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
if($RunId -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid RunId'}
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Preserve old attempt; RunId must be new'}
New-Item -ItemType Directory -Path $runRoot | Out-Null
function WriteJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
function InvokeStage($Name,$Exe,$Arguments,$Timeout=600,[switch]$ExpectedFatal){
    $start=[DateTime]::UtcNow
    $prefix=Join-Path $runRoot $Name
    WriteJson ($prefix+'.start.json') @{executable=$Exe;argv=$Arguments;cwd=$runRoot;started_at=$start.ToString('o');timeout_seconds=$Timeout}
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$Exe;$psi.WorkingDirectory=$runRoot
    $psi.CreateNoWindow=$true;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    foreach($arg in $Arguments){$psi.ArgumentList.Add([string]$arg)}
    $process=[Diagnostics.Process]::Start($psi)
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false
    while(-not $process.HasExited){
        if(([DateTime]::UtcNow-$start).TotalSeconds -ge $Timeout){$timedOut=$true;$process.Kill($true);break}
        Start-Sleep -Milliseconds 100
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    WriteJson ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Get-FileHash -LiteralPath ($prefix+'.stdout.log') -Algorithm SHA256).Hash;stderr_sha256=(Get-FileHash -LiteralPath ($prefix+'.stderr.log') -Algorithm SHA256).Hash}
    Write-Output ($Name+' exit='+$process.ExitCode+' timeout='+$timedOut)
    if($ExpectedFatal){
        if($timedOut -or $process.ExitCode -eq 0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -Pattern 'expected scalar fatal probe' -Quiet)){throw 'Fatal probe did not fail as intended'}
    } elseif($timedOut -or $process.ExitCode -ne 0){throw ($Name+' failed; see original logs')}
}
function SimulationMacro($Name,$Top,[switch]$Waves){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}',
        ('onbreak {set rc 1; if {![catch {examine -radix binary /'+$Top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'))
    if($Waves){$lines+=('log -r /'+$Top+'/dut/*')}
    $lines+=@('run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false))
    return $path
}
$sourcePaths=@('rtl/scalar_protocol_pkg.sv','rtl/scalar_core.sv','rtl/reset_sync.sv','rtl/scalar_probe_top.sv','tb/tb_scalar_core.sv','tb/tb_scalar_probe_top.sv','model/scalar_reference.py','model/scalar_vectors.py','scripts/run_scalar_sim.ps1')
$sourceSnapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}})
WriteJson (Join-Path $runRoot 'source-manifest.json') $sourceSnapshot
try {
    InvokeStage 'input_probes' $taskPython @((Join-Path $taskRoot 'model/scalar_vectors.py'),'input-probes')
    InvokeStage 'generate' $taskPython @((Join-Path $taskRoot 'model/scalar_vectors.py'),'generate',(Join-Path $runRoot 'vectors'))
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sources=@($sourcePaths|Where-Object {$_ -match '\.sv$'}|ForEach-Object{Join-Path $taskRoot $_})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-work','work')+$sources)
    if($Suite -in @('All','Core')){
        InvokeStage 'core_vopt' (Join-Path $taskTool 'vopt.exe') @('+acc','work.tb_scalar_core','-o','core_opt')
        New-Item -ItemType Directory -Path (Join-Path $runRoot 'fatal-probe') | Out-Null
        $fatalMacro=SimulationMacro 'fatal_probe' 'tb_scalar_core'
        InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','core_opt',('+RUN_DIR='+$runRoot+'/fatal-probe'),'+FATAL_PROBE','-do',$fatalMacro) -ExpectedFatal
        if(Test-Path -LiteralPath (Join-Path $runRoot 'fatal-probe/core-result.json')){throw 'Fatal probe created success result'}
        $coreMacro=SimulationMacro 'core_vsim' 'tb_scalar_core'
        InvokeStage 'core_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','core_opt',('+RUN_DIR='+$runRoot),'-do',$coreMacro) 900
        InvokeStage 'audit_core' $taskPython @((Join-Path $taskRoot 'model/scalar_vectors.py'),'audit-core',$runRoot)
    }
    if($Suite -in @('All','Probe')){
        InvokeStage 'probe_vopt' (Join-Path $taskTool 'vopt.exe') @('+acc','work.tb_scalar_probe_top','-o','probe_opt')
        $probeMacro=SimulationMacro 'probe_vsim' 'tb_scalar_probe_top' -Waves
        InvokeStage 'probe_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','probe_opt',('+RUN_DIR='+$runRoot),'-wlf',(Join-Path $runRoot 'probe.wlf'),'-do',$probeMacro) 900
        InvokeStage 'audit_probe' $taskPython @((Join-Path $taskRoot 'model/scalar_vectors.py'),'audit-probe',$runRoot)
    }
    foreach($entry in $sourceSnapshot){if((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -ne $entry.sha256){throw 'Source changed while simulation ran'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status=($(if($Suite -eq 'All'){'PASS'}else{'PARTIAL_PASS'}));suite=$Suite;finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json') -Algorithm SHA256).Hash;full_project_goal_complete=$false}
} catch {
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message;full_project_goal_complete=$false}
    throw
}
