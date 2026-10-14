<# R2-G：仅批准范围、既有本机工具；每次新run保留全部日志/退出码。
本阶段只有D/NC家庭已生成，完整186+44范围未满足时一律PARTIAL。
后续家庭接入同入口；不能把诊断筛选成功当完整套件PASS。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
    [ValidateSet('r2-stream-v1','r2-observer-v1')][string]$Suite='r2-stream-v1',
    [string]$CasePattern='*'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$asciiRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r2'
$workTarget=@((Get-Item -LiteralPath 'C:/Users/34528/FPGAEdgeLinks/Work').Target)[0]
$projectRoot=[IO.Path]::GetFullPath((Join-Path $workTarget '../..'))
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$runRoot=Join-Path $asciiRoot ('sim/r2/runs/'+$RunId)
$priorLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','Process')
$report=$null
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function SaveJson([string]$Path,$Object){[IO.File]::WriteAllText($Path,($Object|ConvertTo-Json -Depth 30)+[Environment]::NewLine,$utf8)}
function SaveReport{if($null -ne $report){SaveJson (Join-Path $runRoot 'suite-result.json') $report}}
function CheckSources{
    foreach($entry in $report.inputs){if((Hash $entry.path) -ne $entry.sha256){throw ('Source changed during run: '+$entry.path)}}
}
function InvokeTool([string]$Name,[string]$Exe,[string[]]$Arguments,[int]$Timeout=900){
    $start=[DateTime]::UtcNow
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$Exe;$info.WorkingDirectory=$runRoot
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    foreach($arg in $Arguments){$info.ArgumentList.Add($arg)}
    SaveJson (Join-Path $runRoot ($Name+'.start.json')) @{executable=$Exe;argv=$Arguments;started_at=$start.ToString('o');timeout_seconds=$Timeout}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$info
    if(-not $process.Start()){throw 'Process start failed'}
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
    $timedOut=$false
    while(-not $process.WaitForExit(1000)){
        if(([DateTime]::UtcNow-$start).TotalSeconds -ge $Timeout){$timedOut=$true;$process.Kill($true);break}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText((Join-Path $runRoot ($Name+'.stdout.log')),$stdout.GetAwaiter().GetResult(),$utf8)
    [IO.File]::WriteAllText((Join-Path $runRoot ($Name+'.stderr.log')),$stderr.GetAwaiter().GetResult(),$utf8)
    $exit=$process.ExitCode
    SaveJson (Join-Path $runRoot ($Name+'.result.json')) @{exit_code=$exit;timed_out=$timedOut;pid=$process.Id;ended_at=[DateTime]::UtcNow.ToString('o')}
    $process.Dispose()
    if($timedOut -or $exit -ne 0){throw ('Tool failed: '+$Name+' exit='+$exit)}
}
try {
    if($Suite -ne 'r2-stream-v1'){throw 'Observer family not implemented yet; no PASS produced'}
    $design=Join-Path $projectRoot '_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001.md'
    $approval=Join-Path $projectRoot '_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/approval-r2-v1.md'
    $baseline=Join-Path $projectRoot '_fpga_edge_agent/experiments/track4_algorithms_20261004/01_baseline/algorithm-r2-stream-baseline-v1.json'
    if((Hash $design) -ne '1728A3163F600CE7F85075BB5704154827FC3B7A0698E0EA6CC0CADA98CDFB27' -or
        (Hash $baseline) -ne 'F7CF4DF2F8CE8A5874C33E7B9DEA997A6A09BCF0C417282D7D6DD4DAE8A93E7E' -or
        -not (Test-Path -LiteralPath $approval)){throw 'Approved identity missing/drifted'}
    $b=Get-Content -LiteralPath $baseline -Raw|ConvertFrom-Json
    if($b.files.Count -ne 48){throw 'Wrong input baseline count'}
    foreach($entry in $b.files){if((Hash $entry.path) -ne $entry.sha256 -or (Get-Item -LiteralPath $entry.path).Length -ne $entry.bytes){throw ('Frozen input drift: '+$entry.path)}}
    if((Get-PSDrive D).Free -lt 16GB){throw '16GB free space required'}
    if(Test-Path -LiteralPath $runRoot){throw 'RunId already exists; old run preserved'}
    New-Item -ItemType Directory -Path $runRoot|Out-Null
    $vendorModel='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v'
    if((Hash $vendorModel) -ne 'DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33'){throw 'Original RAM model drift'}
    $sources=@($vendorModel)+@('rtl/r2/r2_protocol_pkg.sv','rtl/r2/gradient_direction_pair.sv',
        'rtl/r2/canny_fork_pair.sv','rtl/r2/nms_classify_pair.sv',
        'rtl/r2/gaussian5x5_pair.sv','rtl/r2/nms_window_pair.sv',
        'sim/r2/tb_gradient_direction_pair.sv','sim/r2/tb_canny_fork_pair.sv','sim/r2/tb_nms_classify_pair.sv'|ForEach-Object {Join-Path $asciiRoot $_})
    $inputPaths=@($sources)+@((Join-Path $asciiRoot 'model/canny_stream_reference.py'),
        (Join-Path $asciiRoot 'model/r2_vectors.py'),$PSCommandPath,$approval,$design,$baseline)
    $report=[ordered]@{schema_version=1;run_id=$RunId;suite=$Suite;status='RUNNING';scope_status='PARTIAL';
        case_pattern=$CasePattern;approval_path=$approval;design_sha256=(Hash $design);baseline_sha256=(Hash $baseline);
        inputs=@($inputPaths|ForEach-Object {@{path=$_;sha256=(Hash $_)}});cases=[Collections.Generic.List[object]]::new()}
    $snapshotRoot=Join-Path $runRoot 'source_snapshot';New-Item -ItemType Directory -Path $snapshotRoot|Out-Null
    $snapshotIndex=0
    foreach($entry in $report.inputs){
        $snapshotIndex++;$snapshotPath=Join-Path $snapshotRoot ('{0:d3}-{1}' -f $snapshotIndex,[IO.Path]::GetFileName($entry.path))
        Copy-Item -LiteralPath $entry.path -Destination $snapshotPath
        if((Hash $snapshotPath) -ne $entry.sha256){throw 'Source snapshot mismatch'}
        $entry.snapshot_path=$snapshotPath
    }
    SaveReport
    $localLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','User')
    if([string]::IsNullOrEmpty($priorLicense) -and -not [string]::IsNullOrEmpty($localLicense)){
        [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$localLicense,'Process')
    }
    InvokeTool 'python_version' 'D:/py___/python.exe' @('--version')
    InvokeTool 'vlog_version' (Join-Path $toolRoot 'vlog.exe') @('-version')
    InvokeTool 'reference' 'D:/py___/python.exe' @((Join-Path $asciiRoot 'model/r2_vectors.py'),'--out-dir',(Join-Path $runRoot 'vectors')) 3600
    $manifestPath=Join-Path $runRoot 'vectors/manifest.json'
    $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
    if($manifest.status -ne 'COMPLETE' -or $manifest.suite -ne $Suite -or $manifest.required_case_ids.Count -ne 186 -or
        $manifest.rtl_used_for_reference_generation){throw 'Invalid reference manifest'}
    $report.manifest_sha256=Hash $manifestPath
    $report.required_case_count=$manifest.required_case_ids.Count
    $report.generated_case_count=$manifest.cases.Count
    $report.not_generated_case_ids=$manifest.not_generated_case_ids
    foreach($case in $manifest.cases){
        foreach($property in $case.PSObject.Properties){
            if($property.Value -is [pscustomobject] -and $null -ne $property.Value.PSObject.Properties['sha256']){
                $meta=$property.Value;$vectorPath=Join-Path $runRoot ('vectors/'+$meta.path)
                if((Hash $vectorPath) -ne $meta.sha256){throw 'Golden file hash mismatch'}
                $report.inputs+=@(@{path=$vectorPath;sha256=$meta.sha256})
            }
        }
    }
    SaveReport;CheckSources
    InvokeTool 'vlib' (Join-Path $toolRoot 'vlib.exe') @('work')
    InvokeTool 'vlog' (Join-Path $toolRoot 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+@($sources))
    $tops=@{direction='tb_gradient_direction_pair';fork='tb_canny_fork_pair';classify='tb_nms_classify_pair'}
    foreach($top in $tops.Values){InvokeTool ($top+'.vopt') (Join-Path $toolRoot 'vopt.exe') @('+acc',('work.'+$top),'-o',($top+'_opt'))}
    $selected=@($manifest.cases|Where-Object {$_.case_id -like $CasePattern})
    if($selected.Count -eq 0){throw 'No implemented cases selected'}
    foreach($case in $selected){
        $top=$tops[[string]$case.kind];$casePath=Join-Path $runRoot $case.case_id
        New-Item -ItemType Directory -Path $casePath|Out-Null
        $resultPath=Join-Path $casePath 'result.json'
        $argsList=@('-c','-onfinish','stop',($top+'_opt'),
            ('+CASE='+$case.case_id),('+IN='+(Join-Path $runRoot ('vectors/'+$case.input.path))),
            ('+RESULT='+$resultPath))
        if($case.kind -ne 'fork'){$argsList+=@('+EXPECTED='+(Join-Path $runRoot ('vectors/'+$case.expected.path)))}
        if($case.kind -eq 'direction'){
            $argsList+=@(('+BAD='+[int][bool]$case.bad),('+FLUSH_ERROR='+[int][bool]$case.flush_error))
            if($case.bad){$argsList+=@(('+ERROR='+(Join-Path $runRoot ('vectors/'+$case.error.path))),
                ('+RECOVERY_IN='+(Join-Path $runRoot ('vectors/'+$case.recovery_input.path))),
                ('+RECOVERY_EXPECTED='+(Join-Path $runRoot ('vectors/'+$case.recovery_expected.path))),
                ('+RECOVERY_IDS='+$case.recovery_identity))}
        }elseif($case.kind -eq 'fork'){
            $argsList+=@(('+NEXPECTED='+(Join-Path $runRoot ('vectors/'+$case.expected_n.path))),
                ('+GEXPECTED='+(Join-Path $runRoot ('vectors/'+$case.expected_grad.path))),('+SCHEDULE='+$case.schedule))
            if($case.schedule -eq 4){$argsList+=@(('+RECOVERY_IN='+(Join-Path $runRoot ('vectors/'+$case.recovery_input.path))),
                ('+RECOVERY_N='+(Join-Path $runRoot ('vectors/'+$case.recovery_n.path))),
                ('+RECOVERY_G='+(Join-Path $runRoot ('vectors/'+$case.recovery_grad.path))))}
        }else{$argsList+=@(('+TL='+$case.tl),('+TH='+$case.th))}
        $doPath=Join-Path $casePath 'run.do'
        $observedPorts=if($case.kind -eq 'fork'){@('clk','rst','in_valid','in_ready','n_valid','n_ready','grad_valid','grad_ready')}else{@('clk','rst','in_valid','in_ready','out_valid','out_ready')}
        $logCommand='log '+(($observedPorts|ForEach-Object {'/'+$top+'/'+$_}) -join ' ')
        $doLines=@('onerror {quit -code 1}',
            ('onbreak {set rc 1; if {![catch {examine -radix binary /'+$top+'/finished} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),
            $logCommand,'run -all','quit -code 1')
        [IO.File]::WriteAllLines($doPath,[string[]]$doLines,[Text.Encoding]::ASCII)
        $argsList+=@('-wlf',(Join-Path $casePath 'trace.wlf'),'-do',$doPath)
        Write-Output ('SIM '+$case.case_id)
        InvokeTool ($case.case_id+'.vsim') (Join-Path $toolRoot 'vsim.exe') $argsList
        $result=Get-Content -LiteralPath $resultPath -Raw|ConvertFrom-Json
        $expectedCompared=if($case.kind -eq 'direction' -and $case.bad){24}else{[int]$case.expected_pairs}
        if($case.kind -eq 'fork' -and $case.schedule -eq 4){$expectedCompared=40}
        if(-not $result.finished -or $result.case_id -ne $case.case_id -or $result.status -ne 'PASS' -or
            $result.numeric_errors -ne 0 -or $result.protocol_errors -ne 0 -or
            $result.compared_pairs -ne $expectedCompared){throw ('Incomplete actual comparison: '+$case.case_id)}
        $report.cases.Add(@{case_id=$case.case_id;status='PASS';result_path=$resultPath;result_sha256=(Hash $resultPath);result=$result})
        SaveReport
    }
    CheckSources
    $report.status='PARTIAL_PASS'
    $report.passed_cases=$report.cases.Count
    SaveReport
    Write-Output ('PARTIAL_PASS '+$report.cases.Count+'/'+$report.required_case_count+' stream cases; full suite incomplete')
}catch{
    if($null -ne $report){$report.status='FAILED';$report.failure=$_.Exception.Message;SaveReport}
    throw
}finally{[Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$priorLicense,'Process')}
