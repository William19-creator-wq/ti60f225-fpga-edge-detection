param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/ddr_model_2048'
$taskTool='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$taskPython='D:/py___/python.exe'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Preserve original attempt; use a new RunId'}
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
        if(([DateTime]::UtcNow-$start).TotalSeconds-ge$Timeout){$timedOut=$true;$process.Kill($true);break}
        if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){Write-Output ($Name+' running pid='+$process.Id);$progress=[DateTime]::UtcNow}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    WriteJson ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Get-FileHash -LiteralPath ($prefix+'.stdout.log')).Hash;stderr_sha256=(Get-FileHash -LiteralPath ($prefix+'.stderr.log')).Hash}
    if($ExpectedFatal){
        if($timedOut -or $process.ExitCode-eq0 -or -not (Select-String -LiteralPath ($prefix+'.stdout.log'),($prefix+'.stderr.log') -SimpleMatch 'fatal exit probe' -Quiet)){throw 'Fatal probe did not reject'}
    }elseif($timedOut -or $process.ExitCode-ne0){throw ($Name+' failed; original logs preserved')}
    Write-Output ($Name+' exit='+$process.ExitCode+' timeout='+$timedOut)
}
function SimulationMacro($Name){
    $path=Join-Path $runRoot ($Name+'.do')
    $lines=@('onerror {quit -code 1}','onbreak {set rc 1; if {![catch {examine -radix binary /tb_ddr_profile/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}','run -all','quit -code 1')
    [IO.File]::WriteAllText($path,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false));return $path
}
$baseline=Get-Content -LiteralPath (Join-Path $taskRoot 'baseline.json') -Raw|ConvertFrom-Json
foreach($file in $baseline.files){if((Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256 -or (Get-FileHash -LiteralPath $file.original).Hash-ne$file.sha256){throw 'Frozen input drift'}}
$sourcePaths=@('rtl/ddr3.sv','deps/2048Mb_ddr3_parameters.vh','tb/tb_ddr_profile.sv','model/profile_reference.py','scripts/run_ddr_profile.ps1')
New-Item -ItemType Directory -Path $runRoot|Out-Null
$backend=Join-Path $runRoot 'backend';New-Item -ItemType Directory -Path $backend|Out-Null
$snapshot=@($sourcePaths|ForEach-Object{$path=Join-Path $taskRoot $_;@{path=$path;relative=$_;sha256=(Get-FileHash -LiteralPath $path).Hash}})
foreach($file in $snapshot){
    $copy=Join-Path $runRoot ('source-snapshot/'+$file.relative)
    New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
    Copy-Item -LiteralPath $file.path -Destination $copy;$file.snapshot=$copy
    if((Get-FileHash -LiteralPath $copy).Hash-ne$file.sha256){throw 'Initial snapshot drift'}
}
WriteJson (Join-Path $runRoot 'source-manifest.json') $snapshot
try{
    InvokeStage 'vlib' (Join-Path $taskTool 'vlib.exe') @('work')
    $sv=@($snapshot|Where-Object{$_.relative-match'\.(sv|v)$'}|ForEach-Object{$_.snapshot})
    $include='+incdir+'+(Join-Path $runRoot 'source-snapshot/deps')
    InvokeStage 'vlog' (Join-Path $taskTool 'vlog.exe') (@('-sv','-work','work',$include,'+define+den2048Mb+sg125+x16+MAX_MEM')+$sv)
    InvokeStage 'vopt' (Join-Path $taskTool 'vopt.exe') @('+acc','work.tb_ddr_profile','-o','profile_opt')
    $macro=SimulationMacro 'fatal_probe'
    InvokeStage 'fatal_probe' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','profile_opt','+EXPECT_FATAL',('+model_data+'+$backend),'-do',$macro) 300 -ExpectedFatal
    if(Test-Path -LiteralPath (Join-Path $runRoot 'profile.json')){throw 'Fatal probe wrote success profile'}
    $macro=SimulationMacro 'profile_vsim'
    InvokeStage 'profile_vsim' (Join-Path $taskTool 'vsim.exe') @('-c','-t','ps','-onfinish','stop','profile_opt',('+model_data+'+$backend),'-do',$macro)
    InvokeStage 'audit' $taskPython @('-B',(Join-Path $runRoot 'source-snapshot/model/profile_reference.py'),$runRoot)
    foreach($file in $snapshot){if((Get-FileHash -LiteralPath $file.path).Hash-ne$file.sha256 -or (Get-FileHash -LiteralPath $file.snapshot).Hash-ne$file.sha256){throw 'Source drift'}}
    WriteJson (Join-Path $runRoot 'suite-result.json') @{status='PASS_M0_SELECTION_ELAB_ONLY';finished=$true;source_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'source-manifest.json')).Hash;density_bits=2147483648;data_bits=16;strict_timing=$true;model_file_backend=$true;actual_ddr_controller_verified=$false;actual_dq_dqs_readwrite_verified=$false;full_project_goal_complete=$false}
}catch{WriteJson (Join-Path $runRoot 'suite-result.json') @{status='FAIL';finished=$false;reason=$_.Exception.Message};throw}
