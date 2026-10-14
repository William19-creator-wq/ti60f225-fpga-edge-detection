param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
 [ValidateRange(6,1920)][int]$TestWidth=1920,[ValidateRange(6,1080)][int]$TestHeight=1080,
 [switch]$NearHandleMax,[switch]$NearSequenceMax)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/frame_read_authority'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
if($TestWidth%2 -ne 0 -or $TestHeight%2 -ne 0){throw 'Even geometry required'}
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


# RA08：先核验冻结来源，实际执行只读快照；不提供旧执行复用。
$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline.json') -Raw|ConvertFrom-Json
if($baseline.files.Count-ne15){throw 'Fifteen frozen inputs required'}
foreach($f in $baseline.files){
 if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.original).Hash-ne$f.sha256){throw 'Frozen input drift'}
}
$sourcePaths=@('deps/frame_owner_pkg.sv','deps/display_row_pkg.sv','deps/display_fetch_pkg.sv',
 'rtl/frame_owner_read_authority.sv','tb/tb_frame_owner_authority_compat.sv','tb/tb_frame_read_authority.sv',
 'deps/frame_owner_reference.py','model/frame_read_authority_reference.py','scripts/run_authority_sim.ps1')
$snapshot=@()
foreach($rel in $sourcePaths){
 $path=Join-Path $taskRoot $rel;$copy=Join-Path $runRoot ('source-snapshot/'+$rel)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $path -Destination $copy
 $hash=(Get-FileHash -LiteralPath $path).Hash
 if((Get-FileHash -LiteralPath $copy).Hash-ne$hash){throw 'Source snapshot copy drift'}
 $snapshot+=@{relative=$rel;path=$path;snapshot=$copy;sha256=$hash}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
WriteJson (Join-Path $runRoot 'frozen-input-manifest.json') $baseline.files
try{
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative-match'\.sv$'}|ForEach-Object{$_.snapshot})
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-svinputport=net','-work','work')+$sv)
 $common=@(('-GTEST_W='+$TestWidth),('-GTEST_H='+$TestHeight))
 InvokeStage 'compat_vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc','work.tb_frame_owner_authority_compat','-o','compat_opt')+$common+@('-GTEST_NEAR_MAX='+[int][bool]$NearHandleMax))
 InvokeStage 'query_vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc','work.tb_frame_read_authority','-o','query_opt')+$common+@('-GTEST_NEAR_SEQUENCE='+[int][bool]$NearSequenceMax))
 $macro=SimulationMacro 'compat_fatal_probe' 'tb_frame_owner_authority_compat'
 InvokeStage 'compat_fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','compat_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 $macro=SimulationMacro 'query_fatal_probe' 'tb_frame_read_authority'
 InvokeStage 'query_fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','query_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 if((Test-Path -LiteralPath (Join-Path $runRoot 'compat-metrics.json')) -or (Test-Path -LiteralPath (Join-Path $runRoot 'authority-metrics.json'))){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'compat_vsim' 'tb_frame_owner_authority_compat'
 InvokeStage 'compat_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','compat_opt','-do',$macro) 900
 $macro=SimulationMacro 'query_vsim' 'tb_frame_read_authority'
 InvokeStage 'query_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','query_opt','-do',$macro) 900
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/frame_read_authority_reference.py'),$runRoot)
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Source drift'}}
 foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.original).Hash-ne$f.sha256){throw 'Frozen input drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;width=$TestWidth;height=$TestHeight;near_handle_max=[bool]$NearHandleMax;near_sequence_max=[bool]$NearSequenceMax;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_simulation_rerun=$true;read_authority_component_verified=$true;production_automatic_publish_verified=$false;actual_ddr_verified=$false;hardware_actions=$false;full_project_goal_complete=$false}
}catch{
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message}
 throw
}
