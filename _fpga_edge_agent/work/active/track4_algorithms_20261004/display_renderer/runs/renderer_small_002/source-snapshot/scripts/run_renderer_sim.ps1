param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,[switch]$HD,[switch]$Minimum,[switch]$PostMap)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/display_renderer'
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


$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline-v1.1.json') -Raw|ConvertFrom-Json
foreach($f in $baseline.files){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Frozen dependency drift'}}
$sourcePaths=@('rtl/display_renderer.sv','deps/video_timing_1080p_pair.sv','tb/tb_display_renderer.sv','model/render_reference.py','scripts/run_renderer_sim.ps1')
if($PostMap){
 if($HD -or $Minimum){throw 'PostMap uses production geometry stress suite'}
 $map=Join-Path $taskRoot 'runs/renderer_map_001'
 $mapResult=Get-Content -LiteralPath (Join-Path $map 'Map.result.json') -Raw|ConvertFrom-Json
 if($mapResult.exit_code-ne0 -or $mapResult.timed_out){throw 'Actual MAP prerequisite failed'}
 $bound=Get-Content -LiteralPath (Join-Path $map 'snapshot-manifest.json') -Raw|ConvertFrom-Json
 $rtl=@($bound.files|Where-Object{$_.relative-eq'rtl/display_renderer.sv'})
 if($rtl.Count-ne1 -or (Get-FileHash -LiteralPath $rtl[0].path).Hash-ne$rtl[0].sha256){throw 'MAP production RTL drift'}
 if((Get-FileHash -LiteralPath (Join-Path $taskRoot 'deps/display_renderer_mapped.v')).Hash-ne(Get-FileHash -LiteralPath (Join-Path $map 'flow/outflow/display_renderer_component.map.v')).Hash){throw 'Actual mapped netlist drift'}
 $sourcePaths=@('deps/efx_ff.v','deps/efx_lut4.v','deps/efx_add.v','deps/display_renderer_mapped.v')+@($sourcePaths|Where-Object{$_-ne'rtl/display_renderer.sv'})
}

$snapshot=@()
foreach($relative in $sourcePaths){
 $path=Join-Path $taskRoot $relative;$copy=Join-Path $runRoot ('source-snapshot/'+$relative)
 New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
 Copy-Item -LiteralPath $path -Destination $copy
 $snapshot+=@{path=$path;relative=$relative;snapshot=$copy;sha256=(Get-FileHash -LiteralPath $path).Hash}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
WriteJson (Join-Path $runRoot 'baseline-manifest.json') @{baseline_sha256=(Get-FileHash -LiteralPath (Join-Path $taskRoot 'baseline-v1.1.json')).Hash;inputs=$baseline.files}
$top='tb_display_renderer'
try{
 InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
 $sv=@($snapshot|Where-Object{$_.relative -match '\.(sv|v)$'}|ForEach-Object{$_.snapshot})
 $compileArgs=@('-sv','-timescale','1ns/1ps','-work','work');if($PostMap){$compileArgs+=@('+define+RENDERER_POST_MAP')}
 InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') ($compileArgs+$sv)
 $params=@(('-GTEST_RENDER_HD='+[int][bool]$HD),('-GTEST_RENDER_MIN='+[int][bool]$Minimum),('-GTEST_RENDER_MAP='+[int][bool]$PostMap))
 InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') (@('+acc',('work.'+$top),'-o','renderer_opt')+$params)
 $macro=SimulationMacro 'fatal_probe' $top
 InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','renderer_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
 if(Test-Path -LiteralPath (Join-Path $runRoot 'protocol-metrics.json')){throw 'Fatal probe wrote success metrics'}
 $macro=SimulationMacro 'renderer_vsim' $top
 InvokeStage 'renderer_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','renderer_opt','-do',$macro) 900
 InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/render_reference.py'),$runRoot)
 foreach($f in $snapshot){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256 -or (Get-FileHash -LiteralPath $f.snapshot).Hash-ne$f.sha256){throw 'Source drift'}}
 WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;actual_ddr_verified=$false;physical_cdc_verified=$false;mapped_protocol_verified=[bool]$PostMap;hardware_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
