param([Parameter(Mandatory)][string]$RunId,[switch]$FullHD,
      [ValidateRange(6,1920)][int]$Width=34,[ValidateRange(5,1080)][int]$Height=19)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/capture_canny_axi'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
if($RunId -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid RunId'}
if($FullHD){$Width=1920;$Height=1080}
if($Width%2){throw 'Even width required'}
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
$sourcePaths=@('../canny_full_sw/rtl/packed_frame_line_sink.sv',
 '../canny_full_sw/rtl/class_frame_writer.sv',
 '../canny_full_sw/rtl/edge_frame_writer.sv',
 '../canny_full_sw/rtl/canny_full_top.sv',
 '../r2/rtl/r2/r2_protocol_pkg.sv',
 '../r2/rtl/r2/gradient_direction_pair.sv',
 '../r2/rtl/r2/canny_fork_pair.sv',
 '../r2/rtl/r2/nms_classify_pair.sv',
 '../r2/rtl/r2/gaussian5x5_pair.sv',
 '../r2/rtl/r2/nms_window_pair.sv',
 '../r2/rtl/r2/canny_stream_controller.sv',
 '../r2/rtl/r2/canny_stream_top.sv',
 '../r1/rtl/frontend/frontend_frame_pair.sv',
 '../r1/rtl/frontend/rgb_to_y_pair.sv',
 '../r1/rtl/frontend/median9_pair.sv',
 '../r1/rtl/frontend/sobel_pair.sv',
 '../r1/rtl/frontend/window3x3_pair.sv',
 '../r1/rtl/frontend/line_store_pair.sv',
 '../canny_memory_join/rtl/line_rpc_arbiter2.sv',
 '../canny_memory_join/rtl/canny_memory_top.sv',
 '../canny_memory_join/rtl/hysteresis_core_memory.sv',
 '../state_cache/rtl/state_cache_ram16.sv',
 '../state_cache/rtl/canny_state_cache.sv',
 '../work_queue/rtl/queue_ram16_1r1w.sv',
 '../work_queue/rtl/canny_work_queue.sv',
 '../raw_source_join/rtl/raw_source_join.sv',
 '../raw10_color_stream/rtl/raw10_color_stream.sv',
 '../raw10_color_stream/rtl/raw10_window_pair.sv',
 '../raw10_color_stream/rtl/raw10_line_store_pair.sv',
 '../debayer_kernel/rtl/raw10_debayer_pair.sv',
 '../rgb_source_writer/rtl/rgb_source_writer.sv',
 '../rgb_source_writer/rtl/rgb_source_ram_word.sv',
 '../rgb_frame_reader/rtl/rgb_frame_reader.sv',
 '../axi_line_bridge/rtl/axi_line_bridge.sv',
 'rtl/capture_canny_axi.sv',
 '../axi_line_bridge/tb/axi128_byte_memory.sv',
 'tb/tb_capture_canny_axi.sv',
 'model/capture_reference.py',
 'scripts/run_capture_sim.ps1',
 '../canny_full_sw/model/full_canny_reference.py',
 '../canny_memory_join/model/memory_join_reference.py',
 '../debayer_kernel/model/debayer_reference.py',
 '../r1/model/frontend_reference.py',
 '../r2/model/canny_stream_reference.py',
 '../raw10_color_stream/model/raw_color_reference.py',
 '../raw_source_join/model/join_reference.py')
$vendorModel='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v'
if((Get-FileHash -LiteralPath $vendorModel).Hash-ne'DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33'){throw 'Original RAM model drift'}
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_.Replace('../','deps/');sha256=(Get-FileHash -LiteralPath $path).Hash}})
$snapshot=@(@{path=$vendorModel;relative='vendor/efx_ram10.v';sha256=(Get-FileHash -LiteralPath $vendorModel).Hash})+$snapshot
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
    $generateArgs=@((Join-Path $taskRoot 'model/capture_reference.py'),'generate',$runRoot,'--width',[string]$Width,'--height',[string]$Height)
    if($FullHD){$generateArgs+='--full'}
    InvokeStage 'generate' $taskPython $generateArgs
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sv=@($vendorModel)+@($sourcePaths|Where-Object{$_ -match '\.sv$'}|ForEach-Object{Join-Path $taskRoot $_})
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+$sv)
    $voptArgs=@('+acc','work.tb_capture_canny_axi','-o','control_opt',('-GWIDTH='+$Width),('-GHEIGHT='+$Height))
    if($FullHD){$voptArgs+='-GRUN_PROTOCOL=0'}
    InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') $voptArgs
    $macro=SimulationMacro 'fatal_probe' 'tb_capture_canny_axi'
    InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','+EXPECT_FATAL','-do',$macro) 300 -ExpectedFatal
    if(Test-Path -LiteralPath (Join-Path $runRoot 'actual-results.txt')){throw 'Fatal run wrote output'}
    $macro=SimulationMacro 'control_vsim' 'tb_capture_canny_axi'
    InvokeStage 'control_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-onfinish','stop','control_opt','-do',$macro) 3600
    InvokeStage 'audit' $taskPython @((Join-Path $taskRoot 'model/capture_reference.py'),'audit',$runRoot)
    foreach($entry in $snapshot){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Source drift'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;physical_verified=$false;hardware_verified=$false;full_project_goal_complete=$false}
}catch{
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message}
    throw
}
