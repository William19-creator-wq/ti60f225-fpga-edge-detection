param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
      [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$SimulationRun)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/annotation_writer'
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
function Json($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
function Hash($Path){(Get-FileHash -LiteralPath $Path).Hash}
function Require($Condition,$Message){if(-not $Condition){throw $Message}}
try{
    $sim=Join-Path $taskRoot ('runs/'+$SimulationRun)
    $result=Get-Content -LiteralPath (Join-Path $sim 'suite-result.json') -Raw|ConvertFrom-Json
    Require ($result.status-eq'PASS' -and $result.finished-eq$true) 'Simulation prerequisite failed'
    Require ($result.ann_actual_writes-eq$true) 'Actual ANN write simulation prerequisite required'
    $sources=@(Get-Content -LiteralPath (Join-Path $sim 'source-manifest.json') -Raw|ConvertFrom-Json)
    Require ($sources.Count-eq16) '16 simulated inputs required'
    foreach($file in $sources){Require ((Hash $file.path)-eq$file.sha256) 'Simulation source drift'}
    Require (-not(Test-Path -LiteralPath $runRoot)) 'Preserve attempt; choose new RunId'
    foreach($dir in @('snapshot','flow/rtl','flow/project','flow/outflow')){New-Item -ItemType Directory -Path (Join-Path $runRoot $dir) -Force|Out-Null}
    $projectName='annotation_writer_component.xml'
    foreach($relative in @(('project/'+$projectName),'project/annotation_writer_component.sdc','scripts/run_annotation_map.ps1')){
        $path=Join-Path $taskRoot $relative;$sources+=@{path=$path;relative=$relative;sha256=(Hash $path)}
    }
    $copies=@()
    foreach($file in $sources){
        $copy=Join-Path $runRoot ('snapshot/'+$file.relative)
        New-Item -ItemType Directory -Path (Split-Path $copy) -Force|Out-Null
        Copy-Item -LiteralPath $file.path -Destination $copy
        $copies+=@{path=$file.path;snapshot=$copy;relative=$file.relative;sha256=$file.sha256}
        if($file.relative-match'^(rtl|project|deps)/'){
            $flowCopy=Join-Path $runRoot ('flow/'+$file.relative)
            New-Item -ItemType Directory -Path (Split-Path $flowCopy) -Force|Out-Null
            Copy-Item -LiteralPath $file.path -Destination $flowCopy
        }
    }
    $topName='annotation_frame_writer'
    $flowProject=Join-Path $runRoot ('flow/project/'+$projectName)
    [xml]$flowXml=Get-Content -LiteralPath $flowProject -Raw
    $flowXml.SelectSingleNode('//*[local-name()="top_module"]').SetAttribute('name',$topName)
    $flowXml.Save($flowProject)
    Json (Join-Path $runRoot 'snapshot-manifest.json') @{simulation_run=$SimulationRun;files=$copies;top=$topName;variant='Current';scope='COMPONENT_SYNTHESIS_ONLY_NO_BOARD_IO'}
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=Join-Path $toolRoot 'python311/bin/python.exe';$psi.WorkingDirectory=Join-Path $runRoot 'flow/project'
    $psi.CreateNoWindow=$true;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    $argv=@((Join-Path $toolRoot 'scripts/efx_run.py'),$projectName,'--flow','map',
      '--output_dir',(Join-Path $runRoot 'flow/outflow'),'--work_dir',(Join-Path $runRoot 'flow/work_map'),'--timeout','3600')
    foreach($argument in $argv){$psi.ArgumentList.Add($argument)}
    foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),@('EFXIPM_HOME','ipm'),@('PYTHONHOME','python311'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){$psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')}
    $userIni=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini'
    Require (Test-Path -LiteralPath $userIni) 'Existing Efinity user configuration required'
    $psi.Environment['EFINITY_USER_DIR_INI']=$userIni.Replace('\','/')
    $psi.Environment['QT_LOGGING_CONF']=$toolRoot+'/bin/lc.ini'
    $psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
    $psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
    $start=[DateTime]::UtcNow;$prefix=Join-Path $runRoot 'Map'
    $process=[Diagnostics.Process]::Start($psi)
    Json ($prefix+'.start.json') @{pid=$process.Id;parent_script_pid=$PID;executable=$psi.FileName;argv=$argv;cwd=$psi.WorkingDirectory;started_at=$start.ToString('o');process_start_time_utc=$process.StartTime.ToUniversalTime().ToString('o');timeout_seconds=3600}
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$timedOut=$false;$progress=$start
    while(-not $process.WaitForExit(1000)){
        if(([DateTime]::UtcNow-$start).TotalSeconds-ge3600){$timedOut=$true;$process.Kill($true);break}
        if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){Write-Output ('Map running pid='+$process.Id);$progress=[DateTime]::UtcNow}
    }
    $process.WaitForExit()
    [IO.File]::WriteAllText($prefix+'.stdout.log',$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($prefix+'.stderr.log',$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
    Json ($prefix+'.result.json') @{pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;ended_at=[DateTime]::UtcNow.ToString('o');stdout_sha256=(Hash ($prefix+'.stdout.log'));stderr_sha256=(Hash ($prefix+'.stderr.log'))}
    Require (-not$timedOut -and $process.ExitCode-eq0) 'Map failed; retain original logs'
    foreach($file in $copies){Require ((Hash $file.path)-eq$file.sha256 -and (Hash $file.snapshot)-eq$file.sha256) 'Source drift'}
    Write-Output 'Component MAP exit0; read actual RAM/resource report next. No board PNR/STA/bit.'
}catch{Write-Error $_.Exception.Message -ErrorAction Continue;exit 1}
