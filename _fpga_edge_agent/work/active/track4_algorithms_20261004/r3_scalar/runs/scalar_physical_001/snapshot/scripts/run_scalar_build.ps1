param([Parameter(Mandatory)][string]$RunId,[Parameter(Mandatory)][ValidateSet('Map','Interface','Pnr','Bit')][string]$Stage,[string]$SimulationRun='scalar_suite_003')
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_scalar'
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
if($RunId -notmatch '^[a-zA-Z0-9_-]+$' -or $SimulationRun -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid run identifier'}
$runRoot=Join-Path $taskRoot ('runs/'+$RunId);$flowRoot=Join-Path $runRoot 'flow';$outputRoot=Join-Path $flowRoot 'outflow'
function Hash($Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Json($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
function Require($Condition,$Message){if(-not $Condition){throw $Message}}
function PriorStage($Name){
    $data=Get-Content -LiteralPath (Join-Path $runRoot ($Name+'.result.json')) -Raw|ConvertFrom-Json
    Require ($data.exit_code -eq 0 -and $data.timed_out -is [bool] -and $data.timed_out -eq $false) ($Name+' prerequisite failed')
}
$sourceList=@('rtl/scalar_protocol_pkg.sv','rtl/scalar_core.sv','rtl/reset_sync.sv','rtl/scalar_probe_top.sv',
 'model/scalar_reference.py','model/scalar_vectors.py','tb/tb_scalar_core.sv','tb/tb_scalar_probe_top.sv',
 'scripts/run_scalar_sim.ps1','scripts/run_scalar_build.ps1','project/scalar_probe.xml','project/scalar_probe.peri.xml','project/scalar_probe.sdc')
function SimulationGate {
    $simRoot=Join-Path $taskRoot ('runs/'+$SimulationRun)
    $suite=Get-Content -LiteralPath (Join-Path $simRoot 'suite-result.json') -Raw|ConvertFrom-Json
    Require ($suite.status -eq 'PASS' -and $suite.suite -eq 'All' -and $suite.finished -is [bool] -and $suite.finished -eq $true) 'Full simulation not passed'
    foreach($name in @('audit_core','audit_probe')){
        $exit=Get-Content -LiteralPath (Join-Path $simRoot ($name+'.result.json')) -Raw|ConvertFrom-Json
        Require ($exit.exit_code -eq 0 -and $exit.timed_out -is [bool] -and $exit.timed_out -eq $false) 'Independent audit failed'
    }
    foreach($entry in (Get-Content -LiteralPath (Join-Path $simRoot 'source-manifest.json') -Raw|ConvertFrom-Json)){
        Require ((Hash $entry.path) -eq $entry.sha256) 'Simulation source binding drift'
    }
    $fatal=Get-Content -LiteralPath (Join-Path $simRoot 'fatal_probe.result.json') -Raw|ConvertFrom-Json
    Require ($fatal.exit_code -ne 0 -and $fatal.timed_out -is [bool] -and $fatal.timed_out -eq $false) 'Fatal exit gate failed'
}
try {
    SimulationGate
    if($Stage -eq 'Map'){
        Require (-not (Test-Path -LiteralPath $runRoot)) 'Preserve physical attempt; choose new RunId'
        foreach($dir in @('snapshot','flow/rtl','flow/project','flow/outflow')){New-Item -ItemType Directory -Path (Join-Path $runRoot $dir) -Force|Out-Null}
        $entries=@()
        foreach($relative in $sourceList){
            $source=Join-Path $taskRoot $relative;$copy=Join-Path $runRoot ('snapshot/'+$relative)
            New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null;Copy-Item -LiteralPath $source -Destination $copy
            $entries+=@{relative=$relative;path=$source;snapshot=$copy;sha256=(Hash $source)}
            if($relative -match '^(rtl|project)/'){Copy-Item -LiteralPath $source -Destination (Join-Path $flowRoot $relative)}
        }
        Json (Join-Path $runRoot 'snapshot-manifest.json') @{simulation_run=$SimulationRun;files=$entries}
    }
    $snapshot=Get-Content -LiteralPath (Join-Path $runRoot 'snapshot-manifest.json') -Raw|ConvertFrom-Json
    Require ($snapshot.files.Count -eq 13) '13-file snapshot required'
    foreach($entry in $snapshot.files){Require ((Hash $entry.path) -eq $entry.sha256 -and (Hash $entry.snapshot) -eq $entry.sha256) 'Physical source snapshot drift'}
    if($Stage -in @('Interface','Pnr','Bit')){PriorStage 'Map'}
    if($Stage -in @('Pnr','Bit')){PriorStage 'Interface'}
    if($Stage -eq 'Bit'){
        PriorStage 'Pnr'
        $gate=Get-Content -LiteralPath (Join-Path $runRoot 'release-gate.json') -Raw|ConvertFrom-Json
        Require ($gate.status -eq 'PASS' -and $gate.setup_pass -is [bool] -and $gate.setup_pass -eq $true -and $gate.hold_pass -is [bool] -and $gate.hold_pass -eq $true) 'Timing release gate required'
        Require ($gate.internal_unconstrained -eq 0 -and $gate.pin_review -eq 'PASS' -and $gate.data_path_review -eq 'PASS') 'Physical review missing'
        Require ($gate.snapshot_sha256 -eq (Hash (Join-Path $runRoot 'snapshot-manifest.json'))) 'Gate snapshot mismatch'
        foreach($proof in $gate.evidence){Require ((Hash $proof.path) -eq $proof.sha256) 'Gate proof drift'}
    }
    $prefix=Join-Path $runRoot $Stage
    Require (-not (Test-Path -LiteralPath ($prefix+'.start.json'))) 'Preserve completed/partial stage; no overwrite'
    $timeout=@{Map=3600;Interface=3600;Pnr=7200;Bit=1800}[$Stage]
    $flow=@{Map='map';Interface='interface';Pnr='pnr';Bit='pgm'}[$Stage]
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=Join-Path $toolRoot 'python311/bin/python.exe'
    $psi.WorkingDirectory=Join-Path $flowRoot 'project';$psi.CreateNoWindow=$true;$psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $argv=@((Join-Path $toolRoot 'scripts/efx_run.py'),'scalar_probe.xml','--flow',$flow,'--output_dir',$outputRoot,
      '--work_dir',(Join-Path $flowRoot ('work_'+$flow)),'--timeout',[string]$timeout)
    if($Stage -eq 'Bit'){
        $lbf=Join-Path $flowRoot 'work_pnr/scalar_probe.lbf';Require (Test-Path -LiteralPath $lbf -PathType Leaf) 'Routed LBF missing'
        Require ((Hash $lbf) -eq $gate.routed_lbf_sha256) 'LBF release mismatch'
        foreach($suffix in @('bit','hex')){Require (-not (Test-Path -LiteralPath (Join-Path $outputRoot ('scalar_probe.'+$suffix)))) 'Keep existing bit output'}
        $argv+=@('--pgm_opts',('source='+$lbf),('dest='+(Join-Path $outputRoot 'scalar_probe.hex')))
    }
    foreach($arg in $argv){$psi.ArgumentList.Add([string]$arg)}
    foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),
      @('EFXIPM_HOME','ipm'),@('EFXSVF_HOME','debugger/svf_player'),@('EFXSERDESDBG_HOME','debugger/serdes_debug_tool'),
      @('PYTHONHOME','python311'),@('QT_LOGGING_CONF','bin/lc.ini'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){
        $psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')
    }
    $userIni=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini'
    Require (Test-Path -LiteralPath $userIni -PathType Leaf) 'Existing Efinity user configuration absent'
    $psi.Environment['EFINITY_USER_DIR_INI']=$userIni.Replace('\','/')
    $psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
    $psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/pgm/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
    $start=[DateTime]::UtcNow
    Json ($prefix+'.start.json') @{stage=$Stage;started_at=$start.ToString('o');executable=$psi.FileName;argv=$argv;cwd=$psi.WorkingDirectory;timeout_seconds=$timeout;snapshot_sha256=(Hash (Join-Path $runRoot 'snapshot-manifest.json'))}
    $process=[Diagnostics.Process]::Start($psi)
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false
    while(-not $process.WaitForExit(1000)){if(([DateTime]::UtcNow-$start).TotalSeconds -ge $timeout){$timedOut=$true;$process.Kill($true);break}}
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    Json ($prefix+'.result.json') @{exit_code=$process.ExitCode;timed_out=$timedOut;pid=$process.Id;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Hash ($prefix+'.stdout.log'));stderr_sha256=(Hash ($prefix+'.stderr.log'))}
    Require (-not $timedOut -and $process.ExitCode -eq 0) ($Stage+' failed; original logs preserved')
    foreach($entry in $snapshot.files){Require ((Hash $entry.path) -eq $entry.sha256) 'Source changed during build'}
    Write-Output ($Stage+' exit0; actual report review still required')
} catch {Write-Error $_.Exception.Message -ErrorAction Continue;exit 1}
