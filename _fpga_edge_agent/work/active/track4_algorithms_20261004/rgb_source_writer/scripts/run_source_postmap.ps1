param([Parameter(Mandatory)][string]$RunId,[Parameter(Mandatory)][string]$MappingRun)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/rgb_source_writer'
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
if($MappingRun -notmatch '^[A-Za-z0-9_-]+$'){throw 'Invalid MappingRun'}
$mapRoot=Join-Path $taskRoot ('runs/'+$MappingRun)
$mapResult=Get-Content -LiteralPath (Join-Path $mapRoot 'Map.result.json') -Raw|ConvertFrom-Json
if($mapResult.exit_code-ne0){throw 'MAP prerequisite failed'}
$mapManifest=Get-Content -LiteralPath (Join-Path $mapRoot 'snapshot-manifest.json') -Raw|ConvertFrom-Json
foreach($entry in $mapManifest.files){if((Get-FileHash -LiteralPath $entry.path).Hash-ne$entry.sha256){throw 'MAP source drift'}}
$sources=@()
foreach($name in @('efx_ff.v','efx_lut4.v','efx_add.v','efx_ram10.v')){
 $path='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/'+$name
 $sources+=@{path=$path;relative=('vendor/'+$name);sha256=(Get-FileHash -LiteralPath $path).Hash}
}
$netlist=Join-Path $mapRoot 'flow/outflow/rgb_source_writer_component.map.v'
$sources+=@{path=$netlist;relative='deps/postmap/rgb_source_writer_component.map.v';sha256=(Get-FileHash -LiteralPath $netlist).Hash}
foreach($relative in @('model/source_reference.py','tb/tb_rgb_source_writer.sv','scripts/run_source_postmap.ps1')){
 $path=Join-Path $taskRoot $relative;$sources+=@{path=$path;relative=$relative;sha256=(Get-FileHash -LiteralPath $path).Hash}
}
$snapshot=$sources
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
$Width=1920;$Height=1080;$FullHD=$true
try{
    $generateArgs=@((Join-Path $taskRoot 'model/source_reference.py'),'generate',$runRoot,'--width',[string]$Width,'--height',[string]$Height)
    if($FullHD){$generateArgs+=@('--full')}
    InvokeStage 'generate' $taskPython $generateArgs
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sv=@($sources|Where-Object{$_.path-match'\.(sv|v)$'}|ForEach-Object{$_.path})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','+define+POSTMAP','-timescale','1ns/1ps','-work','work')+$sv)
    $voptArgs=@('+acc','work.tb_rgb_source_writer','-o','control_opt',('-GWIDTH='+$Width),('-GHEIGHT='+$Height))
    if($FullHD){$voptArgs+=@('-GRUN_PROTOCOL=0')}
    InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') $voptArgs
    $macro=SimulationMacro 'fatal_probe' 'tb_rgb_source_writer'
    InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
    if(Test-Path -LiteralPath (Join-Path $runRoot 'actual-results.txt')){throw 'Fatal run wrote output'}
    $macro=SimulationMacro 'control_vsim' 'tb_rgb_source_writer'
    InvokeStage 'control_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','-do',$macro) 3600
    InvokeStage 'audit' $taskPython @((Join-Path $taskRoot 'model/source_reference.py'),'audit',$runRoot)
    foreach($entry in $snapshot){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Source drift'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;physical_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message}
    throw
}
