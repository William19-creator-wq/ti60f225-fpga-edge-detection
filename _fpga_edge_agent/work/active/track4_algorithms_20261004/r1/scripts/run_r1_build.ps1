[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string] $RunId,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Prepare', 'Map', 'Interface', 'Pnr', 'Bit')]
    [string] $Stage,
    [ValidateRange(60, 7200)]
    [int] $TimeoutSeconds = 1800,
    [string] $BitAttempt = ''
)

# R1-REQ05/06：只操作获批work；阶段日志不覆盖，不调用compile/full/program。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolRoot = 'C:\Users\34528\FPGAEdgeLinks\Efinity2026_1'
$expectedWork = 'D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r1'
$asciiWork = 'C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1'
if ($workRoot -eq $asciiWork) { $workRoot = $expectedWork }
$controlRoot = [IO.Path]::GetFullPath((Join-Path $workRoot '..\..\..\..'))
$runRoot = Join-Path $workRoot "runs\$RunId"
$approvedDesign = 'DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0'
$approvedBaseline = 'DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4'
$vendorRam = Join-Path $toolRoot 'sim_models\verilog\efx_ram10.v'
$sourceFiles = @(
    'rtl/frontend/line_store_pair.sv', 'rtl/frontend/rgb_to_y_pair.sv',
    'rtl/frontend/window3x3_pair.sv', 'rtl/frontend/median9_pair.sv',
    'rtl/frontend/sobel_pair.sv', 'rtl/frontend/frontend_frame_pair.sv',
    'rtl/r1/reset_sync.sv', 'rtl/r1/pattern_pair_source.sv',
    'rtl/r1/r1_job_supervisor.sv', 'rtl/r1/result_crc_observer.sv',
    'rtl/r1/r1_led_status.sv', 'rtl/r1/r1_algorithm_top.sv'
)
$projectFiles = @('project/r1_algorithm.xml', 'project/r1_algorithm.peri.xml', 'project/r1_algorithm.sdc')

function Get-Sha([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing input: $Path" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Write-NewJson([string] $Path, $Body) {
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($Body | ConvertTo-Json -Depth 16))
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
}

function Require([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function Read-WorkProof([string] $Path, [string] $Hash) {
    $full = if ([IO.Path]::IsPathRooted($Path)) { [IO.Path]::GetFullPath($Path) }
            else { [IO.Path]::GetFullPath((Join-Path $workRoot $Path)) }
    Require ($full.StartsWith($workRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'Proof file escapes approved work'
    Require ($Hash -match '^[A-Fa-f0-9]{64}$') 'Proof SHA256 is missing or malformed'
    Require ((Get-Sha $full) -eq $Hash) "Proof hash mismatch: $Path"
    return $full
}

function Check-CurrentApproval {
    Require ($workRoot -eq $expectedWork) 'Runner is outside approved R1 work'
    $alias = Get-Item -LiteralPath 'C:\Users\34528\FPGAEdgeLinks\Work'
    Require ($alias.LinkType -eq 'Junction') 'Existing Work alias must remain a junction'
    Require (@($alias.Target)[0] -eq (Join-Path $controlRoot 'work')) 'Existing Work alias target changed'
    Require ((Get-Sha (Join-Path $controlRoot 'planning\design-TRACK4-ALGORITHM-R1-001-v1.1.md')) -eq $approvedDesign) 'Approved design changed'
    Require ((Get-Sha (Join-Path $controlRoot 'planning\design-TRACK4-ALGORITHM-R1-001.md')) -eq 'F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00') 'Inherited R1 design changed'
    $basePath = Join-Path $controlRoot 'experiments\track4_algorithms_20261004\01_baseline\algorithm-baseline-v1.1.json'
    Require ((Get-Sha $basePath) -eq $approvedBaseline) 'Approved baseline manifest changed'
    $baseline = Get-Content -LiteralPath $basePath -Raw -Encoding UTF8 | ConvertFrom-Json
    Require (@($baseline.files).Count -eq 22) 'Baseline must contain 22 frozen sources'
    foreach ($file in $baseline.files) {
        Require ((Get-Sha $file.path) -eq $file.sha256) "Baseline input changed: $($file.path)"
        Require ((Get-Item -LiteralPath $file.path).Length -eq $file.bytes) "Baseline input size changed: $($file.path)"
    }
    # 正式Manifest有本次新增scoped批准；不把冻结的批准前快照当运行授权。
    $manifestPath = Join-Path $controlRoot 'config\APPROVAL_MANIFEST.yaml'
    $text = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
    $match = [regex]::Match($text, '(?ms)^  - approval_id: AP-ALGORITHM-R1-20261004-v1\.1\r?\n(?<body>.*?)(?=^  - approval_id:|^hardware_nodes:|\z)')
    Require $match.Success 'Current R1 scoped approval is missing'
    $body = $match.Groups['body'].Value
    Require ($body -match '(?m)^    status: APPROVED\s*$') 'Current R1 approval is not APPROVED'
    Require ($body.Contains($approvedDesign) -and $body.Contains($approvedBaseline)) 'Current approval hashes do not match'
    Require ($body.Contains('work/active/track4_algorithms_20261004/r1')) 'Current approved work scope does not match'
    return (Get-Sha $manifestPath)
}

function Prepare-Snapshot([string] $ApprovalHash) {
    Require (-not (Test-Path -LiteralPath $runRoot)) 'RunId already exists; old run is preserved'
    foreach ($relative in ($sourceFiles + $projectFiles)) { $null = Get-Sha (Join-Path $workRoot $relative) }
    $null = New-Item -ItemType Directory -Path $runRoot
    $files = @()
    $inputs = $sourceFiles + $projectFiles
    foreach ($model in @('model/frontend_reference.py', 'model/r1_pattern_crc_reference.py')) {
        if (Test-Path -LiteralPath (Join-Path $workRoot $model) -PathType Leaf) { $inputs += $model }
    }
    foreach ($relative in $inputs) {
        $origin = Join-Path $workRoot $relative
        $destination = Join-Path $runRoot ("snapshot/" + $relative)
        $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force
        Copy-Item -LiteralPath $origin -Destination $destination
        $hash = Get-Sha $origin
        Require ((Get-Sha $destination) -eq $hash) 'Source changed while taking snapshot'
        $files += [ordered]@{ path = $relative; sha256 = $hash }
        if ($relative.StartsWith('rtl/') -or $relative.StartsWith('project/')) {
            $flowFile = Join-Path $runRoot ("flow/" + $relative)
            $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($flowFile)) -Force
            Copy-Item -LiteralPath $destination -Destination $flowFile
        }
    }
    Write-NewJson (Join-Path $runRoot 'snapshot-manifest.json') ([ordered]@{
        schema_version = 1; run_id = $RunId; approval_id = 'AP-ALGORITHM-R1-20261004-v1.1'
        approval_manifest_sha256 = $ApprovalHash; baseline_id = 'ALGO-BL-20261004-v1.1'
        design_sha256 = $approvedDesign; created_utc = [DateTime]::UtcNow.ToString('o')
        files = $files; vendor_ram_path = $vendorRam; vendor_ram_sha256 = Get-Sha $vendorRam
    })
}

function Check-Snapshot {
    $manifest = Get-Content -LiteralPath (Join-Path $runRoot 'snapshot-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Require ($manifest.run_id -eq $RunId -and $manifest.design_sha256 -eq $approvedDesign) 'Snapshot identity mismatch'
    foreach ($path in ($sourceFiles + $projectFiles)) {
        Require (@($manifest.files | Where-Object { $_.path -eq $path }).Count -eq 1) "Frozen input missing or repeated: $path"
    }
    foreach ($entry in $manifest.files) {
        Require (($sourceFiles + $projectFiles + @('model/frontend_reference.py', 'model/r1_pattern_crc_reference.py')) -contains $entry.path) 'Unexpected frozen input'
        Require ((Get-Sha (Join-Path $runRoot ("snapshot/" + $entry.path))) -eq $entry.sha256) "Frozen source changed: $($entry.path)"
        Require ((Get-Sha (Join-Path $workRoot $entry.path)) -eq $entry.sha256) "Active source changed; use a new run: $($entry.path)"
        if ($entry.path.StartsWith('rtl/') -or $entry.path.EndsWith('.sdc')) {
            Require ((Get-Sha (Join-Path $runRoot ("flow/" + $entry.path))) -eq $entry.sha256) "Tool working RTL/SDC changed: $($entry.path)"
        }
    }
    Require ($manifest.vendor_ram_path -eq $vendorRam) 'Vendor RAM source path changed'
    Require ((Get-Sha $vendorRam) -eq $manifest.vendor_ram_sha256) 'Vendor model changed'
    return $manifest
}

function Require-StageResult([string] $Name) {
    $record = Get-Content -LiteralPath (Join-Path $runRoot "$Name.result.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    Require ($record.run_id -eq $RunId -and $record.stage -eq $Name -and $record.exit_code -eq 0) "Required tool stage failed or missing: $Name"
}

function Check-SourceProof($Records, $Snapshot, [string[]] $RequiredPaths) {
    $seen = @{}
    foreach ($record in $Records) {
        $path = [string]$record.path
        Require (-not $seen.ContainsKey($path)) "Duplicate proof source: $path"
        $seen[$path] = $true
        if ($path -eq $vendorRam) {
            Require ($record.sha256 -eq $Snapshot.vendor_ram_sha256) 'Simulation vendor RAM mismatch'
        } else {
            $null = Read-WorkProof $path $record.sha256
            $frozen = @($Snapshot.files | Where-Object { $_.path -eq $path })
            if ($frozen.Count -eq 1) { Require ($record.sha256 -eq $frozen[0].sha256) "Frozen/proof source mismatch: $path" }
        }
    }
    foreach ($path in $RequiredPaths) { Require ($seen.ContainsKey($path)) "Missing required proof source: $path" }
}

function Check-ReleaseGate($Snapshot) {
    $gate = Get-Content -LiteralPath (Join-Path $runRoot 'release-gate.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Require ($gate.schema_version -eq 1 -and $gate.approval_id -eq 'AP-ALGORITHM-R1-20261004-v1.1') 'Release gate approval mismatch'
    Require ($gate.baseline_id -eq 'ALGO-BL-20261004-v1.1' -and $gate.design_sha256 -eq $approvedDesign) 'Release gate design/baseline mismatch'
    foreach ($model in @('model/frontend_reference.py', 'model/r1_pattern_crc_reference.py')) {
        Require (@($Snapshot.files | Where-Object { $_.path -eq $model }).Count -eq 1) "Reference was not frozen; use a new run: $model"
    }
    Require ($gate.frontend.status -eq 'PASS') 'Frontend functional verification has not passed'
    foreach ($number in 1..11) {
        $key = 'FT-{0:00}' -f $number
        Require ($gate.frontend.required_tests.$key -eq 'PASS') "Required frontend test is not PASS: $key"
    }
    $null = Read-WorkProof $gate.frontend.manifest_path $gate.frontend.manifest_sha256
    $null = Read-WorkProof $gate.frontend.result_path $gate.frontend.result_sha256
    Check-SourceProof $gate.frontend.source_hashes $Snapshot ($sourceFiles[0..5] + @('model/frontend_reference.py', $vendorRam))
    Require (@($gate.frontend.production_jobs).Count -ge 4) 'Four complete 1080p jobs are required'
    $combinations = @{}
    foreach ($job in $gate.frontend.production_jobs) {
        Require ($job.W -eq 1920 -and $job.H -eq 1080 -and $job.compared_pairs -eq 1036800) 'Production comparison dimensions/count failed'
        Require ($job.numeric_errors -eq 0 -and $job.protocol_errors -eq 0 -and $job.status_code -eq 0 -and $job.finished -eq $true) 'Production job did not finish correctly'
        Require (($job.median_enable -in @(0, 1)) -and ($job.output_kind -in @(0, 1))) 'Missing production median/kind configuration'
        $combinations["$($job.median_enable):$($job.output_kind)"] = $true
    }
    foreach ($pair in @('0:0', '1:0', '0:1', '1:1')) { Require ($combinations.ContainsKey($pair)) "Missing production configuration: $pair" }
    Require ($gate.r1.status -eq 'PASS') 'R1 shell verification has not passed'
    foreach ($number in 2..5) {
        $key = 'R1-T{0:00}' -f $number
        Require ($gate.r1.required_tests.$key -eq 'PASS') "Required R1 test is not PASS: $key"
    }
    $null = Read-WorkProof $gate.r1.result_path $gate.r1.result_sha256
    Check-SourceProof $gate.r1.source_hashes $Snapshot ($sourceFiles + @('model/r1_pattern_crc_reference.py', $vendorRam))
    Require ($gate.r1.patterns_258_completed -eq 4 -and $gate.r1.top_4x3_jobs_completed -ge 64 -and $gate.r1.top_8x5_jobs_completed -ge 1 -and $gate.r1.crc_record_errors -eq 0) 'Required shell coverage is incomplete'
    $implementation = $gate.implementation
    Require ($implementation.status -eq 'PASS' -and $implementation.build_run_id -eq $RunId) 'Implementation review is not PASS for this run'
    Check-SourceProof $implementation.source_hashes $Snapshot $sourceFiles
    foreach ($item in @(@('project_sha256', 'project/r1_algorithm.xml'), @('peri_sha256', 'project/r1_algorithm.peri.xml'), @('sdc_sha256', 'project/r1_algorithm.sdc'))) {
        $expected = @($Snapshot.files | Where-Object { $_.path -eq $item[1] })[0].sha256
        Require ($implementation.($item[0]) -eq $expected) 'Implementation project/constraint snapshot mismatch'
    }
    $null = Read-WorkProof $implementation.pin_report_path $implementation.pin_report_sha256
    $null = Read-WorkProof $implementation.sta_report_path $implementation.sta_report_sha256
    $null = Read-WorkProof $implementation.map_report_path $implementation.map_report_sha256
    Require ($implementation.internal_unconstrained_paths -eq 0 -and $implementation.setup_pass -eq $true -and $implementation.hold_pass -eq $true) 'Internal timing verification failed'
    Require ($implementation.pin_map_review -eq $true -and $implementation.exceptions_review -eq $true -and $implementation.resources_review -eq $true) 'Required physical report review missing'
    Require ($implementation.ram10_count -eq 8 -and $implementation.dsp_count -eq 0 -and $implementation.xlr_count -le 8000 -and $implementation.xlr_count -gt 0) 'Approved resource budget failed'
}

try {
    $approvalHash = Check-CurrentApproval
    if ($Stage -eq 'Prepare') {
        Prepare-Snapshot $approvalHash
        Write-Output "R1 snapshot prepared: $RunId; no Efinity flow executed"
        exit 0
    }
    $snapshot = Check-Snapshot
    if ($Stage -eq 'Interface') { Require-StageResult 'Map' }
    if ($Stage -eq 'Pnr' -or $Stage -eq 'Bit') {
        Require-StageResult 'Map'; Require-StageResult 'Interface'
    }
    if ($Stage -eq 'Bit') { Require-StageResult 'Pnr'; Check-ReleaseGate $snapshot }
    $stageRoot = $runRoot
    if ($BitAttempt) {
        Require ($Stage -eq 'Bit' -and $BitAttempt -match '^[A-Za-z0-9_-]+$') 'BitAttempt is only a named Bit retry'
        Require (Test-Path -LiteralPath (Join-Path $runRoot 'Bit.no-artifact.json') -PathType Leaf) 'A retry requires the preserved no-artifact observation'
        $stageRoot = Join-Path $runRoot "bit-attempts/$BitAttempt"
        Require (-not (Test-Path -LiteralPath $stageRoot)) 'Bit attempt directory already exists; retain prior logs'
        $null = New-Item -ItemType Directory -Path $stageRoot
    }
    $bitSource = $null
    $bitSourceHash = $null
    if ($Stage -eq 'Bit') {
        # 同run布线输入按先前物理审阅记录绑定，禁止工具在空目录静默跳过。
        $audit = Get-Content -LiteralPath (Join-Path $runRoot 'physical-audit.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        Require ($audit.build_run_id -eq $RunId -and $audit.status -eq 'PASS') 'Physical input audit is missing for this run'
        $lbfProof = @($audit.postroute_audit.physical_input_copies | Where-Object { $_.original.path -eq "runs/$RunId/flow/work_pnr/r1_algorithm.lbf" })
        Require ($lbfProof.Count -eq 1) 'Exactly one reviewed routed LBF input is required'
        $bitSource = Read-WorkProof $lbfProof[0].original.path $lbfProof[0].original.sha256
        $null = Read-WorkProof $lbfProof[0].copy.path $lbfProof[0].copy.sha256
        $bitSourceHash = Get-Sha $bitSource
        foreach ($suffix in @('bit', 'hex')) {
            Require (-not (Test-Path -LiteralPath (Join-Path $runRoot "flow/outflow/r1_algorithm.$suffix"))) 'Existing generated bitstream must not be replaced'
        }
    }
    $resultPath = Join-Path $stageRoot "$Stage.result.json"
    Require (-not (Test-Path -LiteralPath $resultPath)) 'Stage already attempted; use a new run after a failure'
    Require (-not (Test-Path -LiteralPath (Join-Path $stageRoot "$Stage.start.json"))) 'Interrupted stage is retained; use a new run'
    Require (-not (Test-Path -LiteralPath (Join-Path $stageRoot "$Stage.stdout.log"))) 'Existing stdout log must be retained'
    Require (-not (Test-Path -LiteralPath (Join-Path $stageRoot "$Stage.stderr.log"))) 'Existing stderr log must be retained'
    $flow = @{ Map = 'map'; Interface = 'interface'; Pnr = 'pnr'; Bit = 'pgm' }[$Stage]
    $python = Join-Path $toolRoot 'python311\bin\python.exe'
    $runner = Join-Path $toolRoot 'scripts\efx_run.py'
    $null = Get-Sha $python; $null = Get-Sha $runner
    $processInfo = [Diagnostics.ProcessStartInfo]::new()
    $processInfo.FileName = $python
    $processInfo.WorkingDirectory = Join-Path $runRoot 'flow\project'
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $arguments = @($runner, 'r1_algorithm.xml', '--flow', $flow, '--output_dir', (Join-Path $runRoot 'flow\outflow'), '--work_dir', (Join-Path $runRoot ("flow\work_" + $flow)), '--timeout', [string]$TimeoutSeconds)
    if ($Stage -eq 'Bit') {
        $arguments += @('--pgm_opts', "source=$bitSource", ('dest=' + (Join-Path $runRoot 'flow/outflow/r1_algorithm.hex')))
    }
    foreach ($argument in $arguments) { $processInfo.ArgumentList.Add($argument) }
    $toolSlash = $toolRoot.Replace('\', '/')
    $processInfo.Environment['EFINITY_HOME'] = $toolSlash
    $processInfo.Environment['EFXPT_HOME'] = "$toolSlash/pt"
    $processInfo.Environment['EFXPGM_HOME'] = "$toolSlash/pgm"
    $processInfo.Environment['EFXDBG_HOME'] = "$toolSlash/debugger"
    $processInfo.Environment['EFXIPM_HOME'] = "$toolSlash/ipm"
    $processInfo.Environment['EFXSVF_HOME'] = "$toolSlash/debugger/svf_player"
    $processInfo.Environment['EFXSERDESDBG_HOME'] = "$toolSlash/debugger/serdes_debug_tool"
    $userDirIni = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini'
    Require (Test-Path -LiteralPath $userDirIni -PathType Leaf) 'Existing Efinity user_dir.ini is missing; keep installed tool configuration unchanged'
    $processInfo.Environment['EFINITY_USER_DIR_INI'] = $userDirIni.Replace('\', '/')
    $processInfo.Environment['PYTHONHOME'] = "$toolSlash/python311"
    $processInfo.Environment['QT_LOGGING_CONF'] = "$toolSlash/bin/lc.ini"
    $processInfo.Environment['QT_PLUGIN_PATH'] = "$toolSlash/bin"
    $processInfo.Environment['QT_QPA_PLATFORM_PLUGIN_PATH'] = "$toolSlash/python311/platforms"
    $processInfo.Environment['QTWEBENGINE_CHROMIUM_FLAGS'] = '--disable-gpu'
    $processInfo.Environment['PATH'] = "$toolRoot\python311\bin;$toolRoot\bin;$toolRoot\pgm\bin;$toolRoot\debugger\bin;$toolRoot\debugger\svf_player\bin;$toolRoot\debugger\serdes_debug_tool\bin;$toolRoot\scripts;$toolRoot\ipm\bin\ip_packager;" + $processInfo.Environment['PATH']
    # 同run工具工作副本通过现有ASCII别名寻址，不创建/修改junction。
    $asciiPrefix = 'C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1'
    $processInfo.WorkingDirectory = $processInfo.WorkingDirectory.Replace($workRoot, $asciiPrefix)
    for ($index = 0; $index -lt $processInfo.ArgumentList.Count; $index++) {
        $processInfo.ArgumentList[$index] = $processInfo.ArgumentList[$index].Replace($workRoot, $asciiPrefix)
    }
    # 工具可能更新XML/peri运行属性；逐阶段保留实际工作配置hash，报告仍须人工读回。
    $workingProjectHashes = @($projectFiles | ForEach-Object {
        [ordered]@{ path = $_; sha256 = Get-Sha (Join-Path $runRoot ("flow/" + $_)) }
    })
    $started = [DateTime]::UtcNow
    Write-NewJson (Join-Path $stageRoot "$Stage.start.json") ([ordered]@{ run_id = $RunId; stage = $Stage; attempt = $BitAttempt; flow = $flow; started_utc = $started.ToString('o'); executable = $python; arguments = @($processInfo.ArgumentList); runner_sha256 = Get-Sha $PSCommandPath; bit_source_sha256 = $bitSourceHash; approval_manifest_sha256 = $approvalHash; snapshot_manifest_sha256 = Get-Sha (Join-Path $runRoot 'snapshot-manifest.json'); working_project_hashes_before = $workingProjectHashes })
    Write-Output "R1 $RunId stage $Stage starts; bit allowed only at explicitly gated Bit stage"
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $processInfo
    $null = $process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = -not $process.WaitForExit(($TimeoutSeconds + 120) * 1000)
    if ($timedOut) { $process.Kill($true); $process.WaitForExit() }
    [IO.File]::WriteAllText((Join-Path $stageRoot "$Stage.stdout.log"), $stdoutTask.GetAwaiter().GetResult(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $stageRoot "$Stage.stderr.log"), $stderrTask.GetAwaiter().GetResult(), [Text.UTF8Encoding]::new($false))
    $exitCode = if ($timedOut) { 124 } else { $process.ExitCode }
    $process.Dispose()
    $workingProjectHashes = @($projectFiles | ForEach-Object {
        [ordered]@{ path = $_; sha256 = Get-Sha (Join-Path $runRoot ("flow/" + $_)) }
    })
    $bitArtifacts = @()
    $artifactPass = $null
    if ($Stage -eq 'Bit') {
        $artifactPass = ($exitCode -eq 0 -and (Get-Sha $bitSource) -eq $bitSourceHash)
        foreach ($suffix in @('bit', 'hex')) {
            $artifactPath = Join-Path $runRoot "flow/outflow/r1_algorithm.$suffix"
            if (Test-Path -LiteralPath $artifactPath -PathType Leaf) {
                $bytes = (Get-Item -LiteralPath $artifactPath).Length
                $bitArtifacts += [ordered]@{ path = "runs/$RunId/flow/outflow/r1_algorithm.$suffix"; bytes = $bytes; sha256 = Get-Sha $artifactPath }
                if ($bytes -le 0) { $artifactPass = $false }
            } else { $artifactPass = $false }
        }
    }
    Write-NewJson $resultPath ([ordered]@{ schema_version = 1; run_id = $RunId; stage = $Stage; attempt = $BitAttempt; flow = $flow; exit_code = $exitCode; timed_out = $timedOut; started_utc = $started.ToString('o'); finished_utc = [DateTime]::UtcNow.ToString('o'); stdout_sha256 = Get-Sha (Join-Path $stageRoot "$Stage.stdout.log"); stderr_sha256 = Get-Sha (Join-Path $stageRoot "$Stage.stderr.log"); working_project_hashes_after = $workingProjectHashes; bit_source_sha256 = $bitSourceHash; artifact_check_pass = $artifactPass; artifacts = $bitArtifacts; functional_status = 'SEE_SEPARATE_SIMULATION_REPORT'; physical_review = 'REQUIRED_NOT_AUTOMATIC' })
    Require ($exitCode -eq 0) "Efinity stage failed: $Stage, exit $exitCode; logs preserved"
    if ($Stage -eq 'Bit') { Require ($artifactPass -eq $true) 'Bit generator returned without two valid nonempty bit/hex artifacts; logs preserved' }
    Write-Output "R1 $RunId stage $Stage exited 0; review actual reports before claiming PASS"
    exit 0
} catch {
    Write-Error $_.Exception.Message -ErrorAction Continue
    exit 1
}
