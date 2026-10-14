<# Root指定的局部补强诊断。只读既有数学黄金，新库/日志/TBhash；不声称完整suite。 #>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ProbeId)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$r1='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r1'
$run=Join-Path $r1 ('sim/frontend/runs/'+$ProbeId)
$referenceRun=Join-Path $r1 'sim/frontend/runs/frontend_suite_005'
$vectors=Join-Path $referenceRun vectors
$manifestPath=Join-Path $vectors manifest.json
$tools='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$runner=Join-Path $r1 scripts/run_frontend_sim.ps1
$utf8=New-Object Text.UTF8Encoding($false)
# 只复用已批准/本工作区runner的纯Field/Event-Lines/Hash/Save-Json定义。
# 不执行runner主流程、不评估manifest字符串为代码，复用源hash同时保存。
$tokens=$null;$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw 'Runner parse failed'}
$wanted=@('Field','Event-Lines','Hash','Save-Json')
$definitions=$ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in $wanted},$true)
if($definitions.Count -ne $wanted.Count){throw 'Pure helper definitions missing'}
foreach($definition in $definitions){. ([scriptblock]::Create($definition.Extent.Text))}
if(Test-Path -LiteralPath $run){throw 'Fresh probe required'}
$oldLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','Process')
$summary=$null
try {
    New-Item -ItemType Directory -Path $run | Out-Null
    $manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if($manifest.status -ne 'COMPLETE'){throw 'Reference manifest incomplete'}
    $cases=@($manifest.cases | Where-Object {$_.scenario.ft -in @('FT-05','FT-08','FT-09','FT-10')})
    $sources=@('C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v')+@('line_store_pair','rgb_to_y_pair','median9_pair','sobel_pair','window3x3_pair','frontend_frame_pair' | ForEach-Object {Join-Path $r1 ('rtl/frontend/'+$_+'.sv')})+@('frontend_tb_driver','tb_rgb_to_y_pair','tb_median9_pair','tb_sobel_pair','tb_window3x3_pair','tb_frontend_frame_pair' | ForEach-Object {Join-Path $r1 ('sim/frontend/'+$_+'.sv')})
    $inputHashes=@($sources+@($runner,$PSCommandPath) | ForEach-Object {@{path=$_;sha256=(Hash $_)}})
    $summary=[ordered]@{schema_version=1;scope='SUPPLEMENTAL_PROTOCOL_PROBE_NOT_FULL_SUITE';status='RUNNING';reference_manifest=$manifestPath;reference_manifest_sha256=(Hash $manifestPath);legacy_unit_metadata='FT05 old metadata 0 is explicitly NA by FE F1; final default suite uses corrected new reference';inputs=$inputHashes;cases=(New-Object Collections.Generic.List[object]);error=$null}
    Save-Json (Join-Path $run probe-result.json) $summary
    if([string]::IsNullOrEmpty($oldLicense)){[Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','User'),'Process')}
    Push-Location -LiteralPath $run
    try {
        & (Join-Path $tools vlib.exe) work > vlib.log 2>&1
        if($LASTEXITCODE){throw 'Probe vlib failed'}
        & (Join-Path $tools vlog.exe) -sv -timescale 1ns/1ps -work work @sources > vlog.log 2>&1
        if($LASTEXITCODE){throw 'Probe vlog failed'}
        foreach($case in $cases) {
            $dir=Join-Path $run $case.case_id
            New-Item -ItemType Directory -Path $dir | Out-Null
            $records=@($case)+@(if($null -ne (Field $case follow_up $null)){$case.follow_up})
            foreach($record in $records){
                foreach($role in @('stimulus','expected')) {
                    $rel=$record.($role+'_file')
                    if([IO.Path]::IsPathRooted($rel) -or $rel -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Unsafe reference path'}
                    if((Hash (Join-Path $vectors $rel)) -ne $record.($role+'_sha256')){throw 'Read-only vector changed'}
                }
            }
            $eventPath=Join-Path $dir events.txt
            [IO.File]::WriteAllLines($eventPath,[string[]]@(Event-Lines $case),[Text.Encoding]::ASCII)
            $top=if($case.kind -eq 'window'){'tb_window3x3_pair'}else{'tb_frontend_frame_pair'}
            $status=if($case.kind -eq 'window'){-1}else{[int]$case.scenario.expected_status}
            $doPath=Join-Path $dir run.do
            $macro=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$top+'/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}'),('log /'+$top+'/check/clk /'+$top+'/check/frontend_all_empty /'+$top+'/check/status_valid /'+$top+'/check/status_ready /'+$top+'/check/phase_present'),'run -all','quit -code 1')
            [IO.File]::WriteAllLines($doPath,[string[]]$macro,[Text.Encoding]::ASCII)
            $resultPath=Join-Path $dir result.json
            $argsList=@('-c','-onfinish','stop','-voptargs=+acc','-lib','work',$top,('-gW='+$case.width),('-gH='+$case.height),('+CASE='+$case.case_id),('+IN='+(Join-Path $vectors $case.stimulus_file)),('+EXPECTED='+(Join-Path $vectors $case.expected_file)),('+RESULT='+$resultPath),('+EVENTS='+$eventPath),('+PAIRS='+$case.stimulus_pairs),('+EXPECTED_PAIRS='+$case.expected_pairs),('+STATUS='+$status),'+MAX_CYCLES=3000',('+EPOCH='+$case.job_epoch),('+FRAME='+$case.job_frame_id),('+CONFIG='+$case.job_config_id),('+MEDIAN='+[int]$case.median_enable),('+KIND='+$case.output_kind),('+THRESHOLD='+$case.threshold),'-wlf',(Join-Path $dir trace.wlf),'-do',$doPath)
            $follow=Field $case follow_up $null
            if($null -ne $follow){$argsList+=@('+FOLLOW_UP=1',('+FOLLOW_IN='+(Join-Path $vectors $follow.stimulus_file)),('+FOLLOW_EXPECTED='+(Join-Path $vectors $follow.expected_file)),('+NEXT_EPOCH='+$follow.job_epoch),('+NEXT_FRAME='+$follow.job_frame_id),('+NEXT_CONFIG='+$follow.job_config_id),('+NEXT_MEDIAN='+[int]$follow.median_enable),('+NEXT_KIND='+$follow.output_kind),('+NEXT_THRESHOLD='+$follow.threshold))}
            Write-Output ('PROBE '+$case.case_id)
            & (Join-Path $tools vsim.exe) @argsList > (Join-Path $dir vsim.log) 2>&1
            $exit=$LASTEXITCODE
            $result=if(Test-Path -LiteralPath $resultPath){Get-Content -Raw -LiteralPath $resultPath | ConvertFrom-Json}else{$null}
            $entry=@{case_id=$case.case_id;exit_code=$exit;result=$result;status='FAIL'}
            $summary.cases.Add($entry)
            if($exit -ne 0 -or $null -eq $result -or -not $result.finished -or $result.numeric_errors -ne 0 -or $result.protocol_errors -ne 0 -or $result.status -ne $status -or $result.compared_pairs -ne $result.delivered_pairs -or $result.injections -ne $case.scenario.events.Count){throw ('Protocol probe failed: '+$case.case_id)}
            if($null -ne $follow -and ($result.jobs_completed -ne 2 -or $result.recovery_compared_pairs -ne $case.expected_pairs)){throw 'Follow-up incomplete'}
            if($case.scenario.mode -eq 'reset' -and ($result.jobs_completed -ne 1 -or $result.recovery_compared_pairs -ne $case.expected_pairs)){throw 'Reset recovery incomplete'}
            $entry.status='PASS'
            Save-Json (Join-Path $run probe-result.json) $summary
        }
        foreach($input in $inputHashes){if((Hash $input.path) -ne $input.sha256){throw 'Probe source changed'}}
        $summary.status='SUPPLEMENTAL_PASS'
        Save-Json (Join-Path $run probe-result.json) $summary
    } finally {Pop-Location}
} catch {
    if($null -ne $summary){$summary.status='FAIL';$summary.error=$_.Exception.Message;Save-Json (Join-Path $run probe-result.json) $summary}
    throw
} finally {[Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$oldLicense,'Process')}
