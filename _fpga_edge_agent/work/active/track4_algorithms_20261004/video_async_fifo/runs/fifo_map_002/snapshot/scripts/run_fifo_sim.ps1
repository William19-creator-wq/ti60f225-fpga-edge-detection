param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[switch]$FullHD,
      [ValidateRange(1,320)][int]$Width=128,[ValidateSet(16,32,64,128,256,512,1024,2048,4096)][int]$Depth=1024,
      [ValidateRange(4,1000000)][int]$Records=20480,[double]$WriteHalf=7.143,[double]$ReadHalf=5.0)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/video_async_fifo'
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
$sourcePaths=@('rtl/video_async_fifo.sv','model/fifo_reference.py','tb/tb_video_async_fifo.sv','scripts/run_fifo_sim.ps1')
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
$ramModel='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v'
$snapshot+=@{path=$ramModel;relative='deps/efx_ram10.v';sha256=(Get-FileHash -LiteralPath $ramModel).Hash}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
    if($FullHD){$Width=128;$Depth=1024;$Records=518400;$WriteHalf=7.143;$ReadHalf=5.0}
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sv=@($sourcePaths|Where-Object{$_ -match '\.sv$'}|ForEach-Object{Join-Path $taskRoot $_})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work',$ramModel)+$sv)
    $voptArgs=@('+acc','work.tb_video_async_fifo','-o','control_opt',('-GWIDTH='+$Width),('-GDEPTH='+$Depth),('-GRECORDS='+$Records),('-GWR_HALF='+$WriteHalf.ToString([Globalization.CultureInfo]::InvariantCulture)),('-GRD_HALF='+$ReadHalf.ToString([Globalization.CultureInfo]::InvariantCulture)))
    if($FullHD){$voptArgs+=@('-GRUN_PROTOCOL=0')}
    InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') $voptArgs
    $macro=SimulationMacro 'fatal_probe' 'tb_video_async_fifo'
    InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
    if(Test-Path -LiteralPath (Join-Path $runRoot 'protocol-metrics.json')){throw 'Fatal probe wrote success output'}
    $macro=SimulationMacro 'control_vsim' 'tb_video_async_fifo'
    InvokeStage 'control_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','-do',$macro) 3600
    InvokeStage 'audit' $taskPython @('-B',(Join-Path $taskRoot 'model/fifo_reference.py'),'audit',$runRoot)
    foreach($entry in $snapshot){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Source drift'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;physical_cdc_timing_verified=$false;actual_csi_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message}
    throw
}
