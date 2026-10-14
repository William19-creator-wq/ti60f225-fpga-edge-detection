param([Parameter(Mandatory)][string]$RunId,[Parameter(Mandatory)][ValidateSet('Map','Interface','Pnr','Sta','Bit')][string]$Stage,[Parameter(Mandatory)][string]$SimulationRun)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r3_fit'
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
if($RunId -notmatch '^[a-zA-Z0-9_-]+$' -or $SimulationRun -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid run identifier'}
$runRoot=Join-Path $taskRoot ('runs/'+$RunId);$flowRoot=Join-Path $runRoot 'flow';$outputRoot=Join-Path $flowRoot 'outflow'
function Hash($Path){(Get-FileHash -LiteralPath $Path).Hash}
function Json($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
function Require($Condition,$Message){if(-not $Condition){throw $Message}}
function PriorStage($Name){
    $data=Get-Content -LiteralPath (Join-Path $runRoot ($Name+'.result.json')) -Raw|ConvertFrom-Json
    Require ($data.exit_code-eq0 -and $data.timed_out-is[bool] -and -not $data.timed_out) ($Name+' prerequisite failed')
}
try {
    $simRoot=Join-Path $taskRoot ('runs/'+$SimulationRun)
    $suite=Get-Content -LiteralPath (Join-Path $simRoot 'suite-result.json') -Raw|ConvertFrom-Json
    Require ($suite.status-eq'PASS' -and $suite.suite-eq'All' -and $suite.finished-is[bool] -and $suite.finished) 'Full simulation prerequisite missing'
    $sources=@(Get-Content -LiteralPath (Join-Path $simRoot 'source-manifest.json') -Raw|ConvertFrom-Json)
    Require ($sources.Count-eq19) 'Exactly19 approved source files required'
    foreach($entry in $sources){Require ((Hash $entry.path)-eq$entry.sha256) 'Simulation source drift'}
    foreach($name in @('audit_core','audit_probe')){
        $item=Get-Content -LiteralPath (Join-Path $simRoot ($name+'.result.json')) -Raw|ConvertFrom-Json
        Require ($item.exit_code-eq0 -and $item.timed_out-is[bool] -and -not $item.timed_out) 'Independent audit prerequisite failed'
    }
    $fatal=Get-Content -LiteralPath (Join-Path $simRoot 'fatal_probe.result.json') -Raw|ConvertFrom-Json
    Require ($fatal.exit_code-ne0 -and $fatal.timed_out-is[bool] -and -not $fatal.timed_out) 'Fatal exit prerequisite failed'
    if($Stage-eq'Map'){
        Require (-not(Test-Path -LiteralPath $runRoot)) 'Preserve attempt; choose new RunId'
        foreach($dir in @('snapshot','flow/rtl','flow/project','flow/outflow')){New-Item -ItemType Directory -Path (Join-Path $runRoot $dir) -Force|Out-Null}
        $copies=@()
        foreach($entry in $sources){
            $copy=Join-Path $runRoot ('snapshot/'+$entry.relative);New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
            Copy-Item -LiteralPath $entry.path -Destination $copy
            $copies+=@{path=$entry.path;snapshot=$copy;relative=$entry.relative;sha256=$entry.sha256}
            if($entry.relative-match'^(rtl|project)/'){Copy-Item -LiteralPath $entry.path -Destination (Join-Path $flowRoot $entry.relative)}
        }
        Json (Join-Path $runRoot 'snapshot-manifest.json') @{simulation_run=$SimulationRun;files=$copies}
    }
    $snapshot=Get-Content -LiteralPath (Join-Path $runRoot 'snapshot-manifest.json') -Raw|ConvertFrom-Json
    foreach($entry in $snapshot.files){Require ((Hash $entry.path)-eq$entry.sha256 -and (Hash $entry.snapshot)-eq$entry.sha256) 'Physical snapshot drift'}
    if($Stage-ne'Map'){PriorStage 'Map'}
    if($Stage-in@('Pnr','Sta','Bit')){PriorStage 'Interface'}
    if($Stage-in@('Sta','Bit')){PriorStage 'Pnr'}
    if($Stage-eq'Bit'){
        PriorStage 'Sta'
        $gate=Get-Content -LiteralPath (Join-Path $runRoot 'release-gate.json') -Raw|ConvertFrom-Json
        Require ($gate.status-eq'PASS' -and $gate.setup_pass-eq$true -and $gate.hold_pass-eq$true) 'Release timing gate missing'
        Require ($gate.internal_unconstrained-eq0 -and $gate.pin_review-eq'PASS' -and $gate.data_path_review-eq'PASS') 'Physical evidence review missing'
        Require ($gate.xlr-le50000 -and $gate.ram-eq0 -and $gate.dsp-le16) 'Approved resource budget exceeded'
        Require ($gate.snapshot_sha256-eq(Hash (Join-Path $runRoot 'snapshot-manifest.json'))) 'Release snapshot mismatch'
        foreach($proof in $gate.evidence){Require ((Hash $proof.path)-eq$proof.sha256) 'Release proof drift'}
    }
    $prefix=Join-Path $runRoot $Stage
    Require (-not(Test-Path -LiteralPath ($prefix+'.start.json'))) 'No stage evidence overwrite'
    $timeout=@{Map=3600;Interface=3600;Pnr=7200;Sta=600;Bit=1800}[$Stage]
    $psi=[Diagnostics.ProcessStartInfo]::new();$psi.CreateNoWindow=$true;$psi.UseShellExecute=$false
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    if($Stage-eq'Sta'){
        $staRoot=Join-Path $runRoot 'sta';New-Item -ItemType Directory -Path $staRoot|Out-Null
        foreach($dir in @('outflow','rtl','project')){Copy-Item -LiteralPath (Join-Path $flowRoot $dir) -Destination (Join-Path $staRoot $dir) -Recurse}
        Copy-Item -LiteralPath (Join-Path $flowRoot 'work_pnr') -Destination (Join-Path $staRoot 'work_sta') -Recurse
        Copy-Item -LiteralPath (Join-Path $runRoot 'snapshot/scripts/postroute.tcl') -Destination (Join-Path $staRoot 'postroute.tcl')
        $psi.FileName=Join-Path $toolRoot 'bin/efx_sta.exe';$psi.WorkingDirectory=$staRoot
        $argv=@('--prj',(Join-Path $staRoot 'project/fit_probe.xml'),'-t',(Join-Path $staRoot 'postroute.tcl'),'--','--circuit','fit_probe','--family','Titanium','--device','Ti60F225','--operating_conditions','I3',
          '--vdb_file',(Join-Path $staRoot 'outflow/fit_probe.vdb'),'--use_vdb_file','on','--output_dir',(Join-Path $staRoot 'outflow'),'--work_dir',(Join-Path $staRoot 'work_sta'),
          '--place_file',(Join-Path $staRoot 'outflow/fit_probe.place'),'--sync_file',(Join-Path $staRoot 'outflow/fit_probe.interface.csv'),'--sdc_file',(Join-Path $staRoot 'project/fit_probe.sdc'))
    } else {
        $psi.FileName=Join-Path $toolRoot 'python311/bin/python.exe';$psi.WorkingDirectory=Join-Path $flowRoot 'project'
        $flow=@{Map='map';Interface='interface';Pnr='pnr';Bit='pgm'}[$Stage]
        $argv=@((Join-Path $toolRoot 'scripts/efx_run.py'),'fit_probe.xml','--flow',$flow,'--output_dir',$outputRoot,'--work_dir',(Join-Path $flowRoot ('work_'+$flow)),'--timeout',[string]$timeout)
        if($Stage-eq'Bit'){
            $lbf=Join-Path $flowRoot 'work_pnr/fit_probe.lbf';Require ((Hash $lbf)-eq$gate.routed_lbf_sha256) 'Routed LBF mismatch'
            foreach($suffix in @('bit','hex')){Require (-not(Test-Path -LiteralPath (Join-Path $outputRoot ('fit_probe.'+$suffix)))) 'Existing bit is preserved'}
            $argv+=@('--pgm_opts',('source='+$lbf),('dest='+(Join-Path $outputRoot 'fit_probe.hex')))
        }
    }
    foreach($arg in $argv){$psi.ArgumentList.Add([string]$arg)}
    foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),@('EFXIPM_HOME','ipm'),@('EFXSVF_HOME','debugger/svf_player'),@('EFXSERDESDBG_HOME','debugger/serdes_debug_tool'),@('PYTHONHOME','python311'),@('QT_LOGGING_CONF','bin/lc.ini'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){$psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')}
    $userIni=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini'
    Require (Test-Path -LiteralPath $userIni) 'Existing Efinity user configuration required'
    $psi.Environment['EFINITY_USER_DIR_INI']=$userIni.Replace('\','/');$psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
    $psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/pgm/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
    $start=[DateTime]::UtcNow
    Json ($prefix+'.start.json') @{stage=$Stage;executable=$psi.FileName;argv=$argv;cwd=$psi.WorkingDirectory;timeout_seconds=$timeout;started_at=$start.ToString('o');snapshot_sha256=(Hash (Join-Path $runRoot 'snapshot-manifest.json'))}
    $process=[Diagnostics.Process]::Start($psi);$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false;$lastProgress=$start
    while(-not $process.WaitForExit(1000)){
        if(([DateTime]::UtcNow-$start).TotalSeconds-ge$timeout){$timedOut=$true;$process.Kill($true);break}
        if(([DateTime]::UtcNow-$lastProgress).TotalSeconds-ge30){Write-Output ($Stage+' running pid='+$process.Id);$lastProgress=[DateTime]::UtcNow}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    Json ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Hash ($prefix+'.stdout.log'));stderr_sha256=(Hash ($prefix+'.stderr.log'))}
    Require (-not$timedOut -and $process.ExitCode-eq0) ($Stage+' failed; original logs preserved')
    foreach($entry in $snapshot.files){Require ((Hash $entry.path)-eq$entry.sha256) 'Source changed during build'}
    Write-Output ($Stage+' exit0; original reports still require evidence review')
} catch {Write-Error $_.Exception.Message -ErrorAction Continue;exit 1}
