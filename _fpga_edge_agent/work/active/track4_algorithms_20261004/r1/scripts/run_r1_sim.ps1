param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId)
# R1-T02..05：新目录、独立公式向量、真实工具/握手/CRC计数；不安装或改单机许可。
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskWorkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskRunRoot=Join-Path $taskWorkRoot ('sim/r1/runs/'+$RunId)
if(Test-Path -LiteralPath $taskRunRoot){throw 'RunId already exists; preserving old run'}
New-Item -ItemType Directory -Path $taskRunRoot | Out-Null
$taskPython='D:\py___\python.exe'
$taskToolRoot='C:\Users\34528\FPGAEdgeLinks\Questa2024_1\win64'
$taskVendor='C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\sim_models\verilog\efx_ram10.v'
$taskRunState=[ordered]@{schema_version=1;run_id=$RunId;status='INCOMPLETE';governance=$null;governance_unchanged=$false;commands=@();inputs=@();cases=@();negative_probes=@();error=$null}
$taskOriginalLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','Process')
$taskLocation=Get-Location
function Add-InputEvidence([string]$Path){
    $script:taskRunState.inputs+=@{path=$Path;bytes=(Get-Item -LiteralPath $Path).Length;
        sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
}
function Check-Governance {
    $expectedWork='D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r1'
    $aliasWork='C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1'
    if($taskWorkRoot -ne $expectedWork -and $taskWorkRoot -ne $aliasWork){throw 'Runner outside approved work'}
    $control='D:\大三\FPGA_verilog\_fpga_edge_agent'
    $alias=Get-Item -LiteralPath 'C:\Users\34528\FPGAEdgeLinks\Work'
    if($alias.LinkType -ne 'Junction' -or @($alias.Target)[0] -ne (Join-Path $control 'work')){throw 'Existing ASCII work alias changed'}
    $design='DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0'
    $inherited='F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00'
    $baselineHash='DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4'
    foreach($entry in @(@('planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md',$design),
                       @('planning/design-TRACK4-ALGORITHM-R1-001.md',$inherited))){
        if((Get-FileHash -LiteralPath (Join-Path $control $entry[0]) -Algorithm SHA256).Hash -ne $entry[1]){throw 'Approved/inherited design changed'}
    }
    $basePath=Join-Path $control 'experiments/track4_algorithms_20261004/01_baseline/algorithm-baseline-v1.1.json'
    if((Get-FileHash -LiteralPath $basePath -Algorithm SHA256).Hash -ne $baselineHash){throw 'Approved baseline manifest changed'}
    $baseline=Get-Content -LiteralPath $basePath -Raw -Encoding utf8|ConvertFrom-Json
    if($baseline.files.Count -ne 22 -or $baseline.baseline_id -ne 'ALGO-BL-20261004-v1.1'){throw 'Baseline must contain approved 22 inputs'}
    foreach($inputFile in $baseline.files){
        if((Get-Item -LiteralPath $inputFile.path).Length -ne $inputFile.bytes -or
           (Get-FileHash -LiteralPath $inputFile.path -Algorithm SHA256).Hash -ne $inputFile.sha256){throw 'Frozen baseline input changed'}
    }
    $approvalPath=Join-Path $control 'config/APPROVAL_MANIFEST.yaml'
    $approvalText=Get-Content -LiteralPath $approvalPath -Raw -Encoding utf8
    $match=[regex]::Match($approvalText,'(?ms)^  - approval_id: AP-ALGORITHM-R1-20261004-v1\.1\r?\n(?<body>.*?)(?=^  - approval_id:|^hardware_nodes:|\z)')
    if(-not $match.Success){throw 'Current formal R1 scoped approval absent'}
    $body=$match.Groups['body'].Value
    if($body -notmatch '(?m)^    status: APPROVED\s*$' -or -not $body.Contains($design) -or
       -not $body.Contains($inherited) -or -not $body.Contains($baselineHash) -or
       -not $body.Contains('work/active/track4_algorithms_20261004/r1')){throw 'Current R1 approval scope/hash mismatch'}
    $notePath=Join-Path $control 'experiments/track4_algorithms_20261004/03_review/approval-r1-v1.1.md'
    $note=Get-Content -LiteralPath $notePath -Raw -Encoding utf8
    if(-not $note.Contains('批准 R1 v1.1 及本次本地审计例外') -or -not $note.Contains($design) -or
       -not $note.Contains($inherited) -or -not $note.Contains($baselineHash)){throw 'Real approval evidence mismatch'}
    return [ordered]@{approval_id='AP-ALGORITHM-R1-20261004-v1.1';approved_design_sha256=$design;
        inherited_design_sha256=$inherited;baseline_id=$baseline.baseline_id;baseline_manifest_sha256=$baselineHash;
        approval_manifest_sha256=(Get-FileHash -LiteralPath $approvalPath -Algorithm SHA256).Hash;
        approval_note_sha256=(Get-FileHash -LiteralPath $notePath -Algorithm SHA256).Hash;
        frozen_inputs_checked=22;frozen_input_mismatches=0;frozen_inputs=@($baseline.files)}
}
function Save-RunState {
    $taskRunState | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $taskRunRoot 'run-result.json') -Encoding utf8
}
function Invoke-RecordedTool([string]$Executable,[string[]]$Arguments,[string]$Label,[bool]$ExpectFailure=$false){
    $log=Join-Path $taskRunRoot ($Label+'.stdout.log')
    & $Executable @Arguments *> $log
    $exit=$LASTEXITCODE
    $script:taskRunState.commands+=@{executable=$Executable;arguments=$Arguments;exit_code=$exit;log=$log;log_sha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash}
    Save-RunState
    if($ExpectFailure){if($exit -eq 0){throw ($Label+' negative probe returned zero')}}
    elseif($exit -ne 0){throw ($Label+' failed, exit '+$exit+'; complete log retained')}
}
function Add-TextFile([string]$Path,[string]$Text){
    [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))
}
function Check-HexFile([string]$Relative,[string]$ExpectedHash,[int]$Digits,[int]$Count){
    if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Unsafe fixture path'}
    $path=[IO.Path]::GetFullPath((Join-Path $taskVectorRoot $Relative))
    if(-not $path.StartsWith($taskVectorRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture escapes run'}
    if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $ExpectedHash){throw 'Fixture hash mismatch'}
    $lines=[IO.File]::ReadAllLines($path)
    if($lines.Count -ne $Count){throw 'Fixture line count mismatch'}
    foreach($line in $lines){if($line -cnotmatch ('^[0-9a-f]{'+$Digits+'}$')){throw 'Noncanonical hex fixture'}}
    return $path
}
function Run-Case([string]$Name,[string]$Top,[int]$Width,[int]$Height,[string[]]$PlusArguments,[bool]$NegativeProbe=$false){
    $result=Join-Path $taskRunRoot ($Name+'.result.json')
    $macro=Join-Path $taskRunRoot ($Name+'.do')
    # 真正finish寄存器与JSON同为必需证据；fatal不能落到成功退出。
    $doneSignal='/'+$Top+'/finished'
    $macroText='onerror {quit -code 2}'+"`n"+
        'onbreak {set rc 3; if {![catch {examine -radix binary '+$doneSignal+'} value] && $value eq "1"} {set rc 0}; quit -code $rc}'+"`n"+
        'log -r /*'+"`n"+'run -all'+"`n"+'quit -code 3'+"`n"
    Add-TextFile $macro $macroText
    $args=@('-c','-onfinish','stop','-voptargs=+acc','-l',(Join-Path $taskRunRoot ($Name+'.transcript.log')),
        '-wlf',(Join-Path $taskRunRoot ($Name+'.wlf')))
    if($Top -ne 'tb_r1_observer_supervisor'){$args+=@(('-gW='+$Width),('-gH='+$Height))}
    $args+=@(('work.'+$Top),('+RESULT='+$result))+$PlusArguments+@('-do',$macro)
    if($NegativeProbe){$args+=@('+FAIL_PROBE')}
    Invoke-RecordedTool (Join-Path $taskToolRoot 'vsim.exe') $args $Name $NegativeProbe
    if($NegativeProbe){
        if(Test-Path -LiteralPath $result){throw 'Negative probe emitted successful result'}
        $script:taskRunState.negative_probes+=@{case_id=$Name;nonzero_exit=$true;finished_json_absent=$true}
        Save-RunState;return
    }
    if(-not(Test-Path -LiteralPath $result)){throw 'Simulation omitted result file'}
    $record=Get-Content -Raw -LiteralPath $result | ConvertFrom-Json
    if(-not $record.finished -or $record.numeric_errors -ne 0 -or $record.protocol_errors -ne 0){throw 'Simulation incomplete/errors'}
    $script:taskRunState.cases+=@{case_id=$Name;result=$record;result_sha256=(Get-FileHash -LiteralPath $result -Algorithm SHA256).Hash}
    Save-RunState
    return $record
}
try {
    $taskRunState.governance=Check-Governance
    Save-RunState
    # 仅当前runner进程继承现有User配置，不输出值，不改User/Machine，finally恢复。
    if([string]::IsNullOrWhiteSpace($taskOriginalLicense)){
        $taskUserLicense=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','User')
        if(-not [string]::IsNullOrWhiteSpace($taskUserLicense)){
            [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$taskUserLicense,'Process')
        }
    }
    $taskVectorRoot=Join-Path $taskRunRoot 'r1-vectors'
    # 数学生成依赖与runner在调用前固定，运行末重读核对；junction不放宽边界。
    Add-InputEvidence $PSCommandPath
    Add-InputEvidence (Join-Path $taskWorkRoot 'model/frontend_reference.py')
    Add-InputEvidence (Join-Path $taskWorkRoot 'model/r1_pattern_crc_reference.py')
    Invoke-RecordedTool $taskPython @('-B',(Join-Path $taskWorkRoot 'model/r1_pattern_crc_reference.py'),'--out-dir',$taskVectorRoot,'--suite','r1-pattern-crc-v1') 'reference'
    $taskManifest=Get-Content -Raw -LiteralPath (Join-Path $taskVectorRoot 'manifest.json') | ConvertFrom-Json
    if($taskManifest.status -ne 'COMPLETE' -or $taskManifest.cases.Count -ne 128 -or
       $taskManifest.source_only_cases.Count -ne 4 -or $taskManifest.component_cases.Count -ne 8){throw 'Reference manifest incomplete'}
    $taskFixtures=@{}
    foreach($taskCase in $taskManifest.cases){
        $r=Check-HexFile $taskCase.records_file $taskCase.records_sha256 40 $taskCase.record_count
        $c=Check-HexFile $taskCase.running_crc_file $taskCase.running_crc_sha256 8 $taskCase.record_count
        $taskFixtures[$taskCase.case_id]=@{records=$r;crc=$c}
    }
    $taskFrontend=@('line_store_pair.sv','rgb_to_y_pair.sv','median9_pair.sv','sobel_pair.sv','window3x3_pair.sv','frontend_frame_pair.sv')
    $taskShell=@('pattern_pair_source.sv','result_crc_observer.sv','r1_job_supervisor.sv','r1_led_status.sv','reset_sync.sv','r1_algorithm_top.sv')
    $taskSources=@($taskVendor)
    foreach($n in $taskFrontend){$taskSources+=Join-Path $taskWorkRoot ('rtl/frontend/'+$n)}
    foreach($n in $taskShell){$taskSources+=Join-Path $taskWorkRoot ('rtl/r1/'+$n)}
    $taskSources+=@((Join-Path $taskWorkRoot 'sim/r1/tb_r1_algorithm_top.sv'),
        (Join-Path $taskWorkRoot 'sim/r1/tb_pattern_pair_source.sv'),(Join-Path $taskWorkRoot 'sim/r1/tb_r1_observer_supervisor.sv'))
    foreach($p in $taskSources){Add-InputEvidence $p}
    $taskRunState.inputs+=@{path=(Join-Path $taskVectorRoot 'manifest.json');sha256=(Get-FileHash -LiteralPath (Join-Path $taskVectorRoot 'manifest.json') -Algorithm SHA256).Hash}
    Set-Location -LiteralPath $taskRunRoot
    Invoke-RecordedTool (Join-Path $taskToolRoot 'vlib.exe') @('work') 'vlib'
    Invoke-RecordedTool (Join-Path $taskToolRoot 'vmap.exe') @('work',(Join-Path $taskRunRoot 'work')) 'vmap'
    Invoke-RecordedTool (Join-Path $taskToolRoot 'vlog.exe') (@('-sv','-timescale','1ns/1ps','-work','work')+$taskSources) 'vlog'
    foreach($probeTop in @('tb_r1_algorithm_top','tb_pattern_pair_source','tb_r1_observer_supervisor')){
        Run-Case ('negative-'+$probeTop) $probeTop 4 3 @() $true
    }
    foreach($size in @(@(4,3),@(8,5))){
        $w=$size[0];$h=$size[1];$rs='';$cs=''
        foreach($case in ($taskManifest.cases | Where-Object {$_.width -eq $w -and $_.height -eq $h} | Sort-Object k)){
            $rs+=[IO.File]::ReadAllText($taskFixtures[$case.case_id].records)
            $cs+=[IO.File]::ReadAllText($taskFixtures[$case.case_id].crc)
        }
        $rp=Join-Path $taskRunRoot ('top-W'+$w+'-H'+$h+'.records.hex')
        $cp=Join-Path $taskRunRoot ('top-W'+$w+'-H'+$h+'.crc.hex')
        Add-TextFile $rp $rs;Add-TextFile $cp $cs
        $r=Run-Case ('top-W'+$w+'-H'+$h) 'tb_r1_algorithm_top' $w $h @(('+RECORDS='+$rp),('+CRC='+$cp))
        $n=$w*$h/2
        if($r.jobs_completed -ne 69 -or $r.unique_jobs -ne 64 -or $r.records_compared -ne 69*($n+1)+1 -or
           $r.record_crc_checks -ne 69*($n+1) -or $r.data_pairs_compared -ne 69*$n+1 -or $r.reset_count -ne 1){throw 'Top counts incomplete'}
    }
    foreach($case in $taskManifest.source_only_cases){
        $path=Check-HexFile $case.input_file $case.input_sha256 12 $case.pairs
        $r=Run-Case ('source-pattern'+$case.pattern) 'tb_pattern_pair_source' 258 258 @(('+EXPECTED='+$path),('+PATTERN='+$case.pattern))
        if($r.compared_pairs -ne 33282 -or $r.boundary_pairs -ne 1290 -or $r.held_cycles -le 0){throw 'Source coverage incomplete'}
    }
    $rs='';$cs='';$ms=''
    foreach($case in $taskManifest.component_cases){
        $rp=Check-HexFile $case.records_file $case.records_sha256 40 $case.record_count
        $cp=Check-HexFile $case.running_crc_file $case.running_crc_sha256 8 $case.record_count
        $rs+=[IO.File]::ReadAllText($rp);$cs+=[IO.File]::ReadAllText($cp)
        $ms+=('{0} {1} {2:x8} {3} {4} {5}' -f $case.case_id,$case.data_records,[uint32]$case.job_sequence,
            [int]$case.drain_before_status,[int]$case.expected_good,[int]$case.reset_before)+"`n"
    }
    $rp=Join-Path $taskRunRoot 'component.records.hex';$cp=Join-Path $taskRunRoot 'component.crc.hex';$mp=Join-Path $taskRunRoot 'component.meta.txt'
    Add-TextFile $rp $rs;Add-TextFile $cp $cs;Add-TextFile $mp $ms
    $r=Run-Case 'observer-supervisor' 'tb_r1_observer_supervisor' 4 3 @(('+RECORDS='+$rp),('+CRC='+$cp),('+META='+$mp))
    if($r.cases_completed -ne 8 -or $r.records_compared -ne 47 -or $r.record_crc_checks -ne 46 -or
       $r.busy_reset_checks -ne 1 -or $r.exhausted_jobs -ne 2){throw 'Typed component counts incomplete'}
    if($taskRunState.cases.Count -ne 7 -or $taskRunState.negative_probes.Count -ne 3){throw 'Missing required shell case/probe'}
    foreach($item in $taskRunState.inputs){if((Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash -ne $item.sha256){throw 'Input changed during run'}}
    $taskFinalGovernance=Check-Governance
    if($taskFinalGovernance.approval_manifest_sha256 -ne $taskRunState.governance.approval_manifest_sha256 -or
       $taskFinalGovernance.approval_note_sha256 -ne $taskRunState.governance.approval_note_sha256){throw 'Formal approval changed during run'}
    $taskRunState.governance_unchanged=$true
    $taskRunState.status='COMPLETE';Save-RunState
    Write-Output ('R1 sim COMPLETE: '+$taskRunRoot+'; cases=7')
} catch {
    $taskRunState.status='FAILED';$taskRunState.error=$_.Exception.Message;Save-RunState
    throw
} finally {
    [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$taskOriginalLicense,'Process')
    Set-Location -LiteralPath $taskLocation.Path
}
