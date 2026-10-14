<# SI-REQ07/G3：实际20源冻结、分阶段Efinity；Bit只读完整验证gate。
不调用full/compile/program，不更改原工程、共享R1或正式数据库。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
    [Parameter(Mandatory=$true)][ValidateSet('Prepare','Map','Interface','Pnr','Bit')][string]$Stage
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$workRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r2'
$algorithmRoot=[IO.Path]::GetFullPath((Join-Path $workRoot '..'))
$workTarget=@((Get-Item -LiteralPath 'C:/Users/34528/FPGAEdgeLinks/Work').Target)[0]
$controlRoot=[IO.Path]::GetFullPath((Join-Path $workTarget '..'))
$runRoot=Join-Path $workRoot ('runs/'+$RunId)
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
$designHash='1728A3163F600CE7F85075BB5704154827FC3B7A0698E0EA6CC0CADA98CDFB27'
$baselineHash='F7CF4DF2F8CE8A5874C33E7B9DEA997A6A09BCF0C417282D7D6DD4DAE8A93E7E'
$approvalHash='73C00712BDAED97025A5F45B54CF560D43905855CEEBFC0E9A0728AEE20E686A'
function Require([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function NewJson([string]$Path,$Body){
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
    try{$bytes=$utf8.GetBytes(($Body|ConvertTo-Json -Depth 30)+[Environment]::NewLine);$stream.Write($bytes,0,$bytes.Length)}
    finally{$stream.Dispose()}
}
function Proof($Entry){
    $path=[IO.Path]::GetFullPath([string]$Entry.path)
    Require ($path.StartsWith($algorithmRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) 'Proof outside experiment work'
    Require ((Hash $path) -eq $Entry.sha256) ('Proof changed: '+$path)
    return $path
}
function CheckApproval{
    Require ((Hash (Join-Path $controlRoot 'planning/design-TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001.md')) -eq $designHash) 'Approved design drift'
    Require ((Hash (Join-Path $controlRoot 'experiments/track4_algorithms_20261004/03_review/approval-r2-v1.md')) -eq $approvalHash) 'Approved scope drift'
    $basePath=Join-Path $controlRoot 'experiments/track4_algorithms_20261004/01_baseline/algorithm-r2-stream-baseline-v1.json'
    Require ((Hash $basePath) -eq $baselineHash) 'Baseline identity drift'
    $baseline=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json
    Require ($baseline.files.Count -eq 48) 'Wrong baseline cardinality'
    foreach($entry in $baseline.files){
        Require ((Hash $entry.path) -eq $entry.sha256 -and (Get-Item -LiteralPath $entry.path).Length -eq $entry.bytes) ('Frozen input drift: '+$entry.path)
    }
}
function StagePassed([string]$Name){
    $record=Get-Content -LiteralPath (Join-Path $runRoot ($Name+'.result.json')) -Raw|ConvertFrom-Json
    Require ($record.run_id -eq $RunId -and $record.stage -eq $Name -and $record.exit_code -eq 0 -and -not $record.timed_out) ('Missing successful stage: '+$Name)
}
function SnapshotCheck{
    $snapshot=Get-Content -LiteralPath (Join-Path $runRoot 'snapshot-manifest.json') -Raw|ConvertFrom-Json
    Require ($snapshot.run_id -eq $RunId -and $snapshot.design_sha256 -eq $designHash -and $snapshot.rtl_count -eq 20) 'Snapshot identity wrong'
    foreach($entry in $snapshot.files){
        Require ((Hash $entry.original_path) -eq $entry.sha256 -and (Hash $entry.snapshot_path) -eq $entry.sha256) ('Snapshot/live drift: '+$entry.original_path)
        if($entry.role -in @('rtl','sdc')){Require ((Hash $entry.flow_path) -eq $entry.sha256) 'Tool working source drift'}
    }
    return $snapshot
}
function ReleaseCheck($Snapshot){
    $gate=Get-Content -LiteralPath (Join-Path $runRoot 'release-gate.json') -Raw|ConvertFrom-Json
    Require ($gate.schema_version -eq 1 -and $gate.build_run_id -eq $RunId -and $gate.design_sha256 -eq $designHash -and $gate.status -eq 'PASS') 'Release gate is not PASS for this frozen run'
    Require ($gate.snapshot_sha256 -eq (Hash (Join-Path $runRoot 'snapshot-manifest.json'))) 'Release source snapshot mismatch'
    $required=@((1..44|ForEach-Object {'U-G{0:d3}' -f $_}),(1..49|ForEach-Object {'U-D{0:d3}' -f $_}),
        (1..6|ForEach-Object {'U-F{0:d3}' -f $_}),(1..12|ForEach-Object {'U-NW{0:d3}' -f $_}),
        (1..24|ForEach-Object {'U-NC{0:d3}' -f $_}),(1..21|ForEach-Object {'C0-C{0:d2}' -f $_}),
        (1..24|ForEach-Object {'MD{0:d3}' -f $_}),(1..4|ForEach-Object {'HD{0:d3}' -f $_}),
        @('HD-F001','HD-F002'),(1..14|ForEach-Object {'OBS-B{0:d3}' -f $_}),
        (1..24|ForEach-Object {'OBS-R{0:d3}' -f $_}),(1..4|ForEach-Object {'SRC{0:d3}' -f $_}),
        @('TOP-S001','TOP-HD001'))|ForEach-Object {$_}
    # 一次展开每个家庭；HashSet禁止重复case冒充230份覆盖。
    $seen=[Collections.Generic.HashSet[string]]::new()
    Require ($required.Count -eq 230 -and $gate.cases.Count -eq 230) '230 necessary case proofs missing'
    foreach($case in $gate.cases){
        Require ($required -contains $case.case_id -and $seen.Add([string]$case.case_id)) 'Unknown/duplicate release case'
        $path=Proof $case.result;$result=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
        Require ($result.case_id -eq $case.case_id -and $result.status -eq 'PASS' -and $result.finished -and $result.numeric_errors -eq 0 -and $result.protocol_errors -eq 0) 'Actual simulation result failed'
        $null=Proof $case.tool_exit
        $exit=Get-Content -LiteralPath $case.tool_exit.path -Raw|ConvertFrom-Json
        Require ($exit.exit_code -eq 0 -and -not $exit.timed_out) 'Simulation exit/timeout failed'
        Require ($case.schema_review -eq 'PASS' -and $case.current_source_binding -eq 'PASS') 'Result schema/current source binding missing'
        if($case.case_id -match '^(MD|HD|OBS-|TOP-)'){$null=Proof $case.protocol_audit}
    }
    Require ($gate.input_probes.case_count -eq 12 -and $gate.fatal_probes.Count -eq 3) 'Input/fatal probes missing'
    $null=Proof $gate.input_probes.result
    foreach($probe in $gate.fatal_probes){
        $null=Proof $probe.result;$record=Get-Content -LiteralPath $probe.result.path -Raw|ConvertFrom-Json
        Require ($record.exit_code -ne 0 -and -not $record.timed_out -and $probe.success_json_exists -eq $false) 'Fatal was accepted as success'
    }
    foreach($source in $gate.source_hashes){$null=Proof $source}
    foreach($entry in $Snapshot.files|Where-Object {$_.role -in @('rtl','model')}){
        $gateMatches=@($gate.source_hashes|Where-Object {$_.path -eq $entry.original_path -and $_.sha256 -eq $entry.sha256})
        Require ($gateMatches.Count -eq 1) 'Release evidence source differs from physical snapshot'
    }
    $physical=$gate.physical
    Require ($physical.setup_pass -and $physical.hold_pass -and $physical.internal_unconstrained_paths -eq 0 -and
        $physical.pin_review -eq 'PASS' -and $physical.exceptions_review -eq 'PASS' -and $physical.algorithm_fanout_review -eq 'PASS') 'Physical timing/pin/fanout review incomplete'
    Require ($physical.xlr_count -gt 0 -and $physical.xlr_count -le 22000 -and $physical.ram10_count -gt 0 -and $physical.ram10_count -le 28 -and $physical.dsp_count -eq 0) 'Physical resource budget failed'
    foreach($record in $physical.reports){$null=Proof $record}
    $lbf=Proof $physical.routed_lbf
    Require ($lbf -eq [IO.Path]::GetFullPath((Join-Path $runRoot 'flow/r2/work_pnr/r2_algorithm.lbf')) -and (Get-Item -LiteralPath $lbf).Length -gt 0) 'Reviewed same-run routed LBF missing'
    foreach($record in $physical.interface_inputs){$null=Proof $record}
    return $lbf
}
try{
    CheckApproval
    if($Stage -eq 'Prepare'){
        Require (-not (Test-Path -LiteralPath $runRoot)) 'RunId already exists; preserve old run'
        Require ((Get-PSDrive D).Free -ge 16GB) '16GB free space required'
        $null=New-Item -ItemType Directory -Path $runRoot
        [xml]$project=Get-Content -LiteralPath (Join-Path $workRoot 'project/r2_algorithm.xml') -Raw
        $ns=[Xml.XmlNamespaceManager]::new($project.NameTable);$ns.AddNamespace('e','http://www.efinixinc.com/enf_proj')
        Require ($project.SelectSingleNode('/e:project/e:device_info/e:device',$ns).name -eq 'Ti60F225' -and
            $project.SelectSingleNode('/e:project/e:device_info/e:timing_model',$ns).name -eq 'I3' -and
            $project.SelectSingleNode('/e:project/e:design_info/e:top_module',$ns).name -eq 'r2_algorithm_top') 'Production project identity wrong'
        $entries=@();$paths=[Collections.Generic.HashSet[string]]::new()
        foreach($file in $project.SelectNodes('/e:project/e:design_info/e:design_file',$ns)){
            $path=[IO.Path]::GetFullPath((Join-Path $workRoot ('project/'+$file.name)))
            Require ($path.StartsWith($algorithmRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and $paths.Add($path)) 'RTL path escapes/duplicates'
            $entries+=@(@{original_path=$path;role='rtl'})
        }
        Require ($entries.Count -eq 20) 'Exactly20 production sources required'
        foreach($pair in @(@('project/r2_algorithm.xml','project'),@('project/r2_algorithm.peri.xml','peri'),
            @('project/r2_algorithm.sdc','sdc'),@('model/canny_stream_reference.py','model'),
            @('model/r2_observer_reference.py','model'),@('model/r2_vectors.py','model'),@('scripts/run_r2_build.ps1','runner'))){
            $entries+=@(@{original_path=[IO.Path]::GetFullPath((Join-Path $workRoot $pair[0]));role=$pair[1]})
        }
        foreach($entry in $entries){
            $relative=[IO.Path]::GetRelativePath($algorithmRoot,$entry.original_path)
            $entry.snapshot_path=Join-Path $runRoot ('snapshot/'+$relative)
            $entry.flow_path=Join-Path $runRoot ('flow/'+$relative)
            $entry.sha256=Hash $entry.original_path
            foreach($destination in @($entry.snapshot_path,$entry.flow_path)){
                $null=New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force
                Copy-Item -LiteralPath $entry.original_path -Destination $destination
                Require ((Hash $destination) -eq $entry.sha256) 'Snapshot copy mismatch'
            }
        }
        NewJson (Join-Path $runRoot 'snapshot-manifest.json') @{schema_version=1;run_id=$RunId;design_sha256=$designHash;
            baseline_sha256=$baselineHash;approval_sha256=$approvalHash;rtl_count=20;files=$entries;created_at=[DateTime]::UtcNow.ToString('o')}
        Write-Output ('R2 snapshot prepared '+$RunId+'; no Efinity flow executed');exit 0
    }
    $snapshot=SnapshotCheck
    if($Stage -in @('Interface','Pnr','Bit')){StagePassed 'Map'}
    if($Stage -in @('Pnr','Bit')){StagePassed 'Interface'}
    $lbf=$null;if($Stage -eq 'Bit'){StagePassed 'Pnr';$lbf=ReleaseCheck $snapshot}
    $resultPath=Join-Path $runRoot ($Stage+'.result.json');$startPath=Join-Path $runRoot ($Stage+'.start.json')
    Require (-not (Test-Path -LiteralPath $resultPath) -and -not (Test-Path -LiteralPath $startPath)) 'Attempt exists; preserve old logs and use new run'
    $flow=@{Map='map';Interface='interface';Pnr='pnr';Bit='pgm'}[$Stage]
    $timeout=@{Map=3600;Interface=3600;Pnr=7200;Bit=1800}[$Stage]
    $flowRoot=Join-Path $runRoot 'flow/r2';$outputRoot=Join-Path $flowRoot 'outflow'
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=Join-Path $toolRoot 'python311/bin/python.exe'
    $psi.WorkingDirectory=Join-Path $flowRoot 'project';$psi.CreateNoWindow=$true;$psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $argv=@((Join-Path $toolRoot 'scripts/efx_run.py'),'r2_algorithm.xml','--flow',$flow,'--output_dir',$outputRoot,
        '--work_dir',(Join-Path $flowRoot ('work_'+$flow)),'--timeout',[string]$timeout)
    if($Stage -eq 'Bit'){
        foreach($suffix in @('bit','hex')){Require (-not (Test-Path -LiteralPath (Join-Path $outputRoot ('r2_algorithm.'+$suffix)))) 'Existing bit output retained'}
        $argv+=@('--pgm_opts',('source='+$lbf),('dest='+(Join-Path $outputRoot 'r2_algorithm.hex')))
    }
    foreach($arg in $argv){$psi.ArgumentList.Add($arg)}
    foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),
        @('EFXIPM_HOME','ipm'),@('EFXSVF_HOME','debugger/svf_player'),@('EFXSERDESDBG_HOME','debugger/serdes_debug_tool'),
        @('PYTHONHOME','python311'),@('QT_LOGGING_CONF','bin/lc.ini'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){
        $psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')
    }
    $userIni=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini'
    Require (Test-Path -LiteralPath $userIni -PathType Leaf) 'Existing Efinity configuration missing'
    $psi.Environment['EFINITY_USER_DIR_INI']=$userIni.Replace('\','/')
    $psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
    $psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/pgm/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
    $before=@($snapshot.files|Where-Object {$_.role -in @('project','peri','sdc')}|ForEach-Object {@{path=$_.flow_path;sha256=(Hash $_.flow_path)}})
    NewJson $startPath @{run_id=$RunId;stage=$Stage;started_at=[DateTime]::UtcNow.ToString('o');timeout_seconds=$timeout;
        executable=$psi.FileName;argv=$argv;working_directory=$psi.WorkingDirectory;working_project_hashes_before=$before;
        snapshot_sha256=(Hash (Join-Path $runRoot 'snapshot-manifest.json'))}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$psi;Require ($process.Start()) 'Process start failed'
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false;$start=[DateTime]::UtcNow
    while(-not $process.WaitForExit(1000)){
        if(([DateTime]::UtcNow-$start).TotalSeconds -ge $timeout){$timedOut=$true;$process.Kill($true);break}
    }
    $process.WaitForExit();$exit=$process.ExitCode;$process.Dispose()
    [IO.File]::WriteAllText((Join-Path $runRoot ($Stage+'.stdout.log')),$stdout.GetAwaiter().GetResult(),$utf8)
    [IO.File]::WriteAllText((Join-Path $runRoot ($Stage+'.stderr.log')),$stderr.GetAwaiter().GetResult(),$utf8)
    $artifacts=@()
    if($Stage -eq 'Bit' -and -not $timedOut -and $exit -eq 0){
        foreach($suffix in @('bit','hex')){
            $path=Join-Path $outputRoot ('r2_algorithm.'+$suffix)
            Require ((Test-Path -LiteralPath $path -PathType Leaf) -and (Get-Item -LiteralPath $path).Length -gt 0) 'Generator returned without nonempty bit/hex'
            $artifacts+=@(@{path=$path;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Hash $path)})
        }
    }
    $after=@($snapshot.files|Where-Object {$_.role -in @('project','peri','sdc')}|ForEach-Object {@{path=$_.flow_path;sha256=(Hash $_.flow_path)}})
    NewJson $resultPath @{run_id=$RunId;stage=$Stage;exit_code=$exit;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');
        working_project_hashes_after=$after;artifacts=$artifacts;review_status='ACTUAL_REPORT_REVIEW_REQUIRED'}
    Require (-not $timedOut -and $exit -eq 0) ('Efinity '+$Stage+' failed; logs preserved')
    $null=SnapshotCheck
    Write-Output ('R2 '+$RunId+' '+$Stage+' exit0; separate actual report review required')
}catch{Write-Error $_.Exception.Message -ErrorAction Continue;exit 1}
