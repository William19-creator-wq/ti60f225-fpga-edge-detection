<#
FE F1/G：先核批准和22份基线，再生成独立黄金，逐条执行完整manifest。
RunId必须新建；CasePattern只用于局部诊断，报告会明确PARTIAL。
仅使用现有工具和进程级本机许可；不安装、联网、修改原模型或正式状态。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
    [string]$CasePattern='*',
    [ValidateRange(30,7200)][int]$ToolTimeoutSeconds=1800
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$utf8=New-Object System.Text.UTF8Encoding($false)
$r1Root=Split-Path -Parent $PSScriptRoot
$workAlias='C:/Users/34528/FPGAEdgeLinks/Work'
$workTarget=@((Get-Item -LiteralPath $workAlias).Target)[0]
$projectRoot=[IO.Path]::GetFullPath((Join-Path $workTarget '../..'))
$asciiRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r1'
$runRoot=Join-Path $asciiRoot ('sim/frontend/runs/'+$RunId)
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
$vendorModel='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v'
$baselinePath=Join-Path $projectRoot '_fpga_edge_agent/experiments/track4_algorithms_20261004/01_baseline/algorithm-baseline-v1.1.json'
$approvalPath=Join-Path $projectRoot '_fpga_edge_agent/config/APPROVAL_MANIFEST.yaml'
$report=$null
$priorLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','Process')

function Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Save-Json([string]$Path,$Value) {
    [IO.File]::WriteAllText($Path,($Value | ConvertTo-Json -Depth 30)+[Environment]::NewLine,$utf8)
}
function Save-Report { if($null -ne $report){Save-Json (Join-Path $runRoot 'suite-result.json') $report} }
function Check-InputsUnchanged {
    foreach($entry in $report.inputs) {
        if((Hash $entry.path) -ne $entry.sha256 -or (Get-Item -LiteralPath $entry.path).Length -ne $entry.bytes) {throw ('Runtime source changed: '+$entry.path)}
    }
}
function Field($Object,[string]$Name,$Default) {
    if($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]) {return $Object.$Name}
    return $Default
}
function Quote-Argument([string]$Value) {
    if($Value.Contains("`n") -or $Value.Contains("`r") -or $Value.Contains([char]0)) {throw 'Unsafe native argument'}
    # Windows argv：quote前及结尾的反斜杠翻倍；不经过shell解释。
    '"'+[regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}
function Invoke-Tool([string]$Name,[string]$Exe,[string[]]$Arguments,[int]$Timeout=$ToolTimeoutSeconds) {
    $stdout=Join-Path $runRoot ($Name+'.stdout.log')
    $stderr=Join-Path $runRoot ($Name+'.stderr.log')
    $quoted=($Arguments | ForEach-Object {Quote-Argument $_}) -join ' '
    $started=[DateTime]::UtcNow
    $process=Start-Process -FilePath $Exe -ArgumentList $quoted -WorkingDirectory $runRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    while(-not $process.HasExited) {
        if(([DateTime]::UtcNow-$started).TotalSeconds -gt $Timeout) {
            Stop-Process -Id $process.Id -Force
            throw "Tool timeout: $Name"
        }
        Start-Sleep -Milliseconds 200
        $process.Refresh()
    }
    $process.WaitForExit()
    $result=[ordered]@{name=$Name;exit_code=$process.ExitCode;started_utc=$started.ToString('o');elapsed_seconds=([DateTime]::UtcNow-$started).TotalSeconds;stdout=$stdout;stderr=$stderr}
    $report.tools.Add($result)
    Save-Report
    return $result
}
function Vector-Path([string]$Relative,[string]$ExpectedHash,[int]$Bits,[int]$Count) {
    if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)') {throw 'Vector traversal rejected'}
    $path=[IO.Path]::GetFullPath((Join-Path $vectorsRoot $Relative))
    if(-not $path.StartsWith($vectorsRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw 'Vector outside run rejected'}
    if(-not $seenFiles.Add($path)) {throw 'Duplicate vector path'}
    if((Hash $path) -ne $ExpectedHash) {throw 'Vector hash mismatch'}
    $reader=New-Object IO.StreamReader($path,[Text.Encoding]::ASCII,$false)
    $n=0;$digits=[int][Math]::Ceiling($Bits/4.0)
    try {
        while($null -ne ($line=$reader.ReadLine())) {
            if($line -cnotmatch ('^[0-9a-f]{'+$digits+'}$')) {throw "Noncanonical hexadecimal line: $Relative"}
            if($Bits%4 -ne 0 -and [Convert]::ToInt32($line.Substring(0,1),16) -ge [Math]::Pow(2,$Bits%4)) {throw 'Nonzero high padding'}
            $n++
        }
    } finally {$reader.Dispose()}
    if($n -ne $Count) {throw "Vector count differs: $Relative"}
    $report.checked_hex_lines+=$n
    return $path
}
function Event-Lines($Case) {
    $codes=@{input_bubble=1;output_stall=2;coordinate=3;marker=4;bad=5;cancel=6;reset=7;config_change=8;status_stall=9}
    $phases=@{f1=1;window_a_fill=2;median=3;window_b_fill=4;sobel=5;window_a_replay=6;window_a_tail=7;window_b_replay=8;window_b_tail=9}
    foreach($ev in $Case.scenario.events) {
        $name=[string]$ev.event
        if(-not $codes.ContainsKey($name)) {throw "Unsupported event: $name"}
        $trigger=0;$index=0;$field=0;$when=0
        $atOutput=Field $ev 'at_output_pair' $null
        $atInput=Field $ev 'at_input_pair' $null
        $target=Field $ev 'target' $null
        $eventWhen=[string](Field $ev 'when' '')
        if($null -ne $target) {
            if(-not $phases.ContainsKey([string]$target)) {throw 'Unknown actual phase'}
            $trigger=3;$field=$phases[[string]$target]
        } elseif($null -ne $atOutput) {$trigger=1;$index=[int]$atOutput}
        elseif($null -ne $atInput) {
            $index=[int]$atInput
            # accepted下标是已交接组；fire下标是本次即将交接输出。
            if($eventWhen -eq 'accepted' -and $name -eq 'cancel') {$index++}
        } elseif($name -eq 'status_stall' -or $eventWhen -eq 'status') {$trigger=2}
        else {throw 'Event has no bounded trigger'}
        if($eventWhen -eq 'fire') {$when=1}
        if($name -eq 'coordinate') {
            switch([string]$ev.field) {x {$field=0}; y {$field=1}; default {throw 'Bad coordinate field'}}
        }
        if($name -eq 'marker') {
            switch([string]$ev.field) {sof {$field=0}; eol {$field=1}; eof {$field=2}; default {throw 'Bad marker field'}}
        }
        $changes=Field $ev 'changes' $null
        $items=@($codes[$name],$trigger,$index,(Field $ev 'cycles' 1),$field,(Field $ev 'value' 0),$when,
            (Field $changes 'job_epoch' $Case.job_epoch),(Field $changes 'job_frame_id' $Case.job_frame_id),
            (Field $changes 'job_config_id' $Case.job_config_id),[int][bool](Field $changes 'median_enable' $Case.median_enable),
            (Field $changes 'output_kind' $Case.output_kind),(Field $changes 'threshold' $Case.threshold))
        ($items -join ' ')
    }
}

try {
    $approval=Get-Content -Raw -LiteralPath $approvalPath
    if($approval -notmatch '(?s)approval_id: AP-ALGORITHM-R1-20261004-v1\.1\s+status: APPROVED') {throw 'Specified approval absent'}
    if((Hash $baselinePath) -ne 'DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4') {throw 'Baseline manifest changed'}
    $baseline=Get-Content -Raw -LiteralPath $baselinePath | ConvertFrom-Json
    if($baseline.files.Count -ne 22) {throw 'Expected frozen 22 input baseline'}
    foreach($item in $baseline.files) {
        if((Hash $item.path) -ne $item.sha256 -or (Get-Item -LiteralPath $item.path).Length -ne $item.bytes) {throw "Frozen input changed: $($item.path)"}
    }
    $approvedDesigns=@(
        @{path=(Join-Path $projectRoot '_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md');sha256='DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0'},
        @{path=(Join-Path $projectRoot '_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001.md');sha256='F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00'})
    foreach($design in $approvedDesigns) {if((Hash $design.path) -ne $design.sha256) {throw 'Approved design changed'}}
    if(-not (Test-Path -LiteralPath $asciiRoot)) {throw 'Existing ASCII Work alias absent'}
    if(Test-Path -LiteralPath $runRoot) {throw 'RunId already exists; old evidence is retained'}
    New-Item -ItemType Directory -Path $runRoot | Out-Null
    $report=[ordered]@{schema_version=1;approval_id='AP-ALGORITHM-R1-20261004-v1.1';baseline_id=$baseline.baseline_id;baseline_sha256=(Hash $baselinePath);frozen_inputs_checked=22;run_id=$RunId;status='RUNNING';selection=$CasePattern;full_manifest=$false;checked_hex_lines=0;inputs=@();tools=(New-Object Collections.Generic.List[object]);cases=(New-Object Collections.Generic.List[object]);error=$null;existing_user_process_license_fallback=$false}
    $report.approved_designs=$approvedDesigns
    if([string]::IsNullOrEmpty($priorLicense)) {
        $localLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','User')
        if(-not [string]::IsNullOrEmpty($localLicense)) {
            [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$localLicense,'Process')
            $report.existing_user_process_license_fallback=$true
        }
        $localLicense=$null
    }
    Save-Report
    $reference=Join-Path $asciiRoot 'model/frontend_reference.py'
    $sources=@($vendorModel)+@('line_store_pair','rgb_to_y_pair','median9_pair','sobel_pair','window3x3_pair','frontend_frame_pair' | ForEach-Object {Join-Path $asciiRoot ('rtl/frontend/'+$_+'.sv')})+@('frontend_tb_driver','tb_rgb_to_y_pair','tb_median9_pair','tb_sobel_pair','tb_window3x3_pair','tb_frontend_frame_pair' | ForEach-Object {Join-Path $asciiRoot ('sim/frontend/'+$_+'.sv')})
    $runtimeInputs=$sources+@($reference,(Join-Path $asciiRoot 'model/r1_pattern_crc_reference.py'),$PSCommandPath)+@($approvedDesigns | ForEach-Object {$_.path})
    $report.inputs=@($runtimeInputs | ForEach-Object {@{path=$_;sha256=(Hash $_);bytes=(Get-Item -LiteralPath $_).Length}})
    if((Hash $vendorModel) -ne 'DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33') {throw 'Original vendor model differs'}
    Save-Report
    $python=(Get-Command python -CommandType Application | Select-Object -First 1).Source
    $vectorsRoot=[IO.Path]::GetFullPath((Join-Path $runRoot vectors))
    $generation=Invoke-Tool 'reference' $python @($reference,'--out-dir',$vectorsRoot,'--suite','frontend-v1')
    if($generation.exit_code -ne 0) {throw 'Independent reference generation failed'}
    Check-InputsUnchanged
    $manifestPath=Join-Path $vectorsRoot manifest.json
    $manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if($manifest.schema_version -ne 1 -or $manifest.status -ne 'COMPLETE' -or $manifest.suite -ne 'frontend-v1' -or $manifest.rtl_used_for_reference_generation) {throw 'Incomplete/invalid independent manifest'}
    $seenIds=New-Object 'Collections.Generic.HashSet[string]'
    $seenFiles=New-Object 'Collections.Generic.HashSet[string]'
    $checkedCases=New-Object Collections.Generic.List[object]
    $tops=@{gray='tb_rgb_to_y_pair';median='tb_median9_pair';sobel='tb_sobel_pair';window='tb_window3x3_pair';frontend='tb_frontend_frame_pair'}
    foreach($case in $manifest.cases) {
        if($case.case_id -cnotmatch '^[A-Za-z0-9_-]+$' -or -not $seenIds.Add([string]$case.case_id) -or -not $tops.ContainsKey([string]$case.kind)) {throw 'Duplicate/invalid case metadata'}
        if($case.kind -ne 'frontend' -and $case.scenario.expected_status -ne 'NA') {throw 'Unit manifest status must explicitly be NA'}
        $input=Vector-Path $case.stimulus_file $case.stimulus_sha256 $case.stimulus_bits $case.stimulus_pairs
        $expected=Vector-Path $case.expected_file $case.expected_sha256 $case.expected_bits $case.expected_pairs
        $follow=Field $case 'follow_up' $null
        $followInput=$null;$followExpected=$null
        if($null -ne $follow) {
            $followInput=Vector-Path $follow.stimulus_file $follow.stimulus_sha256 $follow.stimulus_bits $follow.stimulus_pairs
            $followExpected=Vector-Path $follow.expected_file $follow.expected_sha256 $follow.expected_bits $follow.expected_pairs
            if($follow.stimulus_pairs -ne $case.stimulus_pairs -or $follow.expected_pairs -ne $case.expected_pairs) {throw 'Recovery dimensions/count differ'}
        }
        $checkedCases.Add(@{case=$case;input=$input;expected=$expected;follow=$follow;followInput=$followInput;followExpected=$followExpected})
    }
    $fts=@($manifest.cases | ForEach-Object {$_.scenario.ft} | Sort-Object -Unique)
    if(($fts -join ',') -ne ((1..11 | ForEach-Object {'FT-{0:d2}' -f $_}) -join ',')) {throw 'FT01 through FT11 missing'}
    $production=@($manifest.cases | Where-Object {$_.scenario.ft -eq 'FT-11'})
    if($production.Count -ne 4 -or @($production | Where-Object {$_.width -ne 1920 -or $_.height -ne 1080 -or $_.stimulus_pairs -ne 1036800 -or $_.expected_pairs -ne 1036800}).Count -ne 0 -or @($production | ForEach-Object {('{0}:{1}' -f [int]$_.median_enable,$_.output_kind)} | Sort-Object -Unique).Count -ne 4) {throw 'Four complete production jobs missing'}
    $report.manifest_sha256=Hash $manifestPath
    $report.manifest_case_count=$manifest.cases.Count
    $report.ft_coverage=$fts
    $report.manifest_validation=$manifest.validation
    $vlib=Invoke-Tool 'vlib' (Join-Path $toolRoot vlib.exe) @('work')
    if($vlib.exit_code -ne 0) {throw 'vlib failed'}
    $compile=Invoke-Tool 'vlog' (Join-Path $toolRoot vlog.exe) (@('-sv','-timescale','1ns/1ps','-work','work')+$sources)
    if($compile.exit_code -ne 0) {throw 'vlog failed'}
    $selected=@($checkedCases | Where-Object {$_.case.case_id -like $CasePattern})
    if($selected.Count -eq 0) {throw 'CasePattern selected no manifest entries'}
    foreach($record in $selected) {
        $case=$record.case;$caseDir=Join-Path $runRoot $case.case_id
        New-Item -ItemType Directory -Path $caseDir | Out-Null
        $eventPath=Join-Path $caseDir events.txt
        [IO.File]::WriteAllLines($eventPath,[string[]]@(Event-Lines $case),[Text.Encoding]::ASCII)
        $resultPath=Join-Path $caseDir result.json
        $status=if($case.scenario.expected_status -eq 'NA') {-1} else {[int]$case.scenario.expected_status}
        $seed=Field $case 'protocol_seed' 0x431
        $random=[int][bool](Field $case.scenario 'random_stalls' $false)
        $maxCycles=128+32*[Math]::Max([int]$case.stimulus_pairs,[int]$case.expected_pairs)
        $argsList=@('-c','-onfinish','stop','-voptargs=+acc','-lib','work',$tops[[string]$case.kind],('-gW='+$case.width),('-gH='+$case.height),
            ('+CASE='+$case.case_id),('+IN='+$record.input),('+EXPECTED='+$record.expected),('+RESULT='+$resultPath),('+EVENTS='+$eventPath),
            ('+PAIRS='+$case.stimulus_pairs),('+EXPECTED_PAIRS='+$case.expected_pairs),('+STATUS='+$status),('+MAX_CYCLES='+$maxCycles),
            ('+EPOCH='+$case.job_epoch),('+FRAME='+$case.job_frame_id),('+CONFIG='+$case.job_config_id),('+MEDIAN='+[int]$case.median_enable),
            ('+KIND='+$case.output_kind),('+THRESHOLD='+$case.threshold),('+SEED='+('{0:x}' -f [uint32]$seed)),('+RANDOM_STALLS='+$random),'+TIMING=1')
        if($null -ne $record.follow) {
            $follow=$record.follow
            $argsList+=@('+FOLLOW_UP=1',('+FOLLOW_IN='+$record.followInput),('+FOLLOW_EXPECTED='+$record.followExpected),('+NEXT_EPOCH='+$follow.job_epoch),
                ('+NEXT_FRAME='+$follow.job_frame_id),('+NEXT_CONFIG='+$follow.job_config_id),('+NEXT_MEDIAN='+[int]$follow.median_enable),('+NEXT_KIND='+$follow.output_kind),('+NEXT_THRESHOLD='+$follow.threshold))
        }
        $doPath=Join-Path $caseDir run.do
        $top=$tops[[string]$case.kind]
        $doLines=@('onerror {quit -code 1}',('onbreak {set rc 1; if {![catch {examine -radix binary /'+$top+'/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}'))
        if($case.width -le 10 -and $case.height -le 5) {
            $top=$tops[[string]$case.kind]
            # 仅外部交接及真实RAM端口，不记录1024字存储阵列。
            $doLines+=('log /'+$top+'/check/clk /'+$top+'/check/rst /'+$top+'/check/in_valid /'+$top+'/check/in_ready /'+$top+'/check/out_valid /'+$top+'/check/out_ready /'+$top+'/check/actual_value /'+$top+'/check/phase_present /'+$top+'/check/input_index /'+$top+'/check/output_index')
            if($case.kind -eq 'window') {$doLines+=('log /'+$top+'/check/g_window/dut/rd_en /'+$top+'/check/g_window/dut/rd_addr /'+$top+'/check/g_window/dut/recent_wr_en /'+$top+'/check/g_window/dut/older_wr_en /'+$top+'/check/g_window/dut/pending_q /'+$top+'/check/g_window/dut/replay_phase')}
            if($case.kind -eq 'frontend') {
                foreach($win in @('window_before_median','window_before_sobel')) {$prefix='/'+$top+'/check/g_frontend/dut/'+$win+'/';$doLines+=('log '+$prefix+'rd_en '+$prefix+'rd_addr '+$prefix+'recent_wr_en '+$prefix+'older_wr_en '+$prefix+'pending_q '+$prefix+'replay_phase')}
            }
        }
        $doLines+=@('run -all','quit -code 1')
        [IO.File]::WriteAllLines($doPath,[string[]]$doLines,[Text.Encoding]::ASCII)
        $argsList+=@('-wlf',(Join-Path $caseDir trace.wlf),'-do',$doPath)
        Write-Output ('SIM '+$case.case_id)
        $entry=[ordered]@{case_id=$case.case_id;kind=$case.kind;ft=$case.scenario.ft;status='RUNNING';result=$null;reason=$null}
        $report.cases.Add($entry);Save-Report
        $simulation=Invoke-Tool ($case.case_id+'.vsim') (Join-Path $toolRoot vsim.exe) $argsList
        if($simulation.exit_code -ne 0 -or -not (Test-Path -LiteralPath $resultPath)) {throw ('vsim failed/missing result: '+$case.case_id)}
        $result=Get-Content -Raw -LiteralPath $resultPath | ConvertFrom-Json
        $entry.result=$result
        if(-not $result.finished -or $result.case_id -ne $case.case_id -or $result.numeric_errors -ne 0 -or $result.protocol_errors -ne 0 -or $result.delivered_pairs -ne $result.compared_pairs -or $result.status -ne $status -or $result.injections -ne $case.scenario.events.Count) {throw ('Structured case checks failed: '+$case.case_id)}
        $recovery=if($null -ne $record.follow -or $case.scenario.mode -eq 'reset') {[int]$case.expected_pairs} else {0}
        $prefix=[int]$result.compared_pairs-$recovery
        if($case.scenario.mode -eq 'reset') {$prefix=[int]$result.compared_pairs-$result.recovery_compared_pairs}
        if($prefix -lt $case.scenario.allowed_prefix.minimum -or $prefix -gt $case.scenario.allowed_prefix.maximum) {throw 'Delivered prefix outside contract'}
        if($null -ne $record.follow -and ($result.jobs_completed -ne 2 -or $result.recovery_compared_pairs -ne $case.expected_pairs)) {throw 'No-reset new-job recovery incomplete'}
        if($case.scenario.mode -eq 'reset' -and ($result.jobs_completed -ne 1 -or $result.recovery_compared_pairs -ne $case.expected_pairs)) {throw 'Reset recovery incomplete'}
        if($case.scenario.mode -in @('normal','configuration') -and $prefix -ne $case.expected_pairs) {throw 'Normal full comparison incomplete'}
        $requiredPhase=Field $case.scenario 'required_actual_phase' $null
        if($null -ne $requiredPhase -and $result.phase_hits -eq 0) {throw 'Required actual phase never observed'}
        if($case.kind -in @('window','frontend') -and $result.compared_pairs -gt 0 -and $result.ram_reads -eq 0) {throw 'RAM port check did not execute'}
        $entry.status='PASS';Save-Report
    }
    $report.full_manifest=$selected.Count -eq $manifest.cases.Count
    Check-InputsUnchanged
    $report.runtime_input_hashes_unchanged=$true
    $report.status=if($report.full_manifest) {'PASS'} else {'PARTIAL_PASS'}
    $report.completed_utc=[DateTime]::UtcNow.ToString('o')
    Save-Report
    Write-Output ('RESULT '+$report.status+' '+(Join-Path $runRoot suite-result.json))
} catch {
    if($null -ne $report) {
        $report.status='FAIL';$report.error=$_.Exception.Message
        if($report.cases.Count -gt 0 -and $report.cases[$report.cases.Count-1].status -eq 'RUNNING') {$report.cases[$report.cases.Count-1].status='FAIL';$report.cases[$report.cases.Count-1].reason=$_.Exception.Message}
        Save-Report
    }
    Write-Error $_
    exit 1
} finally {
    [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$priorLicense,'Process')
}
