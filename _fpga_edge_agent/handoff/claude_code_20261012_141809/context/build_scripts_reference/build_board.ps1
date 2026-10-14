param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
      [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ReuseMapping,
      [ValidateSet('TIMING_3','CONGESTION_1')][string]$OptimizationLevel,
      [ValidateRange(0,2147483647)][int]$PlacerSeed=0,
      [switch]$ScalarResultFf,
      [switch]$AlgorithmReadBufferFf)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_board_first_20261011'
$toolRoot='C:/Users/34528/FPGAEdgeLinks/Efinity2026_1'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
if(Test-Path -LiteralPath $runRoot){throw 'Preserve old run; use a new RunId'}
New-Item -ItemType Directory -Path $runRoot -Force|Out-Null
$flowRoot=Join-Path $runRoot 'flow'
New-Item -ItemType Directory -Path $flowRoot -Force|Out-Null
foreach($dir in @('rtl','ip','algorithm','board')){Copy-Item -LiteralPath (Join-Path $taskRoot $dir) -Destination $flowRoot -Recurse}
foreach($name in @('track4_board.xml','track4_board.sdc','track4_board.peri.xml','Panel_1080p_reg.mem')){
    Copy-Item -LiteralPath (Join-Path $taskRoot $name) -Destination $flowRoot
}
# 仅调整新run的物理实现配方；主工程和正在运行的冻结输入保持原样。
if($OptimizationLevel-or$PlacerSeed-gt0){
    $frozenProjectPath=Join-Path $flowRoot 'track4_board.xml'
    [xml]$frozenProject=Get-Content -LiteralPath $frozenProjectPath -Raw
    if($OptimizationLevel){
        $recipe=$frozenProject.SelectNodes("//*[local-name()='place_and_route']/*[local-name()='param' and @name='optimization_level']")
        if($recipe.Count-ne1){throw 'Expected one place-and-route optimization level'}
        $recipe[0].SetAttribute('value',$OptimizationLevel)
    }
    if($PlacerSeed-gt0){
        $seed=$frozenProject.SelectNodes("//*[local-name()='place_and_route']/*[local-name()='param' and @name='seed']")
        if($seed.Count-ne1){throw 'Expected one place-and-route seed'}
        $seed[0].SetAttribute('value',[string]$PlacerSeed)
    }
    $frozenProject.Save($frozenProjectPath)
}
if($AlgorithmReadBufferFf){
    $readParentPath=Join-Path $flowRoot 'algorithm/services/axi_read_pair_service.sv'
    $readParent=Get-Content -LiteralPath $readParentPath -Raw
    $readStoragePattern="\.DSP_READ_BUFFER\(1'b1\)"
    if([regex]::Matches($readParent,$readStoragePattern).Count-ne1){throw 'Expected one algorithm DDR read snapshot storage setting'}
    $readParent=[regex]::Replace($readParent,$readStoragePattern,".DSP_READ_BUFFER(1'b0)")
    [IO.File]::WriteAllText($readParentPath,$readParent,[Text.UTF8Encoding]::new($false))
}
if($ScalarResultFf){
    $scalarParentPath=Join-Path $flowRoot 'board/rtl/board_algorithm_rpc.sv'
    $scalarParent=Get-Content -LiteralPath $scalarParentPath -Raw
    $resultStoragePattern="\.RAM_RESULT\(1'b1\)"
    if([regex]::Matches($scalarParent,$resultStoragePattern).Count-ne1){throw 'Expected one shared scalar result storage setting'}
    $scalarParent=[regex]::Replace($scalarParent,$resultStoragePattern,".RAM_RESULT(1'b0)")
    [IO.File]::WriteAllText($scalarParentPath,$scalarParent,[Text.UTF8Encoding]::new($false))
}
function SaveJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))}
# 只登记本次构建输入，不重复扫描历史验证包。
$inputs=@(Get-ChildItem -LiteralPath $flowRoot -File -Recurse|ForEach-Object{
    @{relative=$_.FullName.Substring($flowRoot.Length+1);sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}
})
SaveJson (Join-Path $runRoot 'inputs.json') $inputs
$stages=@('compile')
if($ReuseMapping){
    $previous=Join-Path $taskRoot ('runs/'+$ReuseMapping)
    $previousInputs=Get-Content -LiteralPath (Join-Path $previous 'inputs.json') -Raw|ConvertFrom-Json
    foreach($file in $previousInputs){
        if($file.relative-match'^(rtl|ip|algorithm|board)[\\/]'){
            $current=Join-Path $flowRoot $file.relative
            if((Get-FileHash -LiteralPath $current).Hash-ne$file.sha256){throw ('RTL changed; cannot reuse mapping: '+$file.relative)}
        }
    }
    $previousOut=Join-Path $previous 'flow/outflow'
    $newOut=Join-Path $flowRoot 'outflow'
    New-Item -ItemType Directory -Path $newOut -Force|Out-Null
    foreach($file in Get-ChildItem -LiteralPath $previousOut -File){
        if($file.Name-match'\.map\.|\.vdb$|\.res\.csv$|\.err\.log$|\.warn\.log$|\.info\.log$'){
            Copy-Item -LiteralPath $file.FullName -Destination $newOut
        }
    }
    SaveJson (Join-Path $runRoot 'reused-map.json') @{run=$ReuseMapping;rtl_inputs_identical=$true;map_sha256=(Get-FileHash -LiteralPath (Join-Path $newOut 'track4_board.map.v')).Hash}
    $stages=@('interface','pnr','pgm')
}
foreach($stage in $stages){
$psi=[Diagnostics.ProcessStartInfo]::new()
$psi.FileName=$toolRoot+'/python311/bin/python.exe';$psi.WorkingDirectory=$flowRoot
$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
$arguments=@(($toolRoot+'/scripts/efx_run.py'),'track4_board.xml','--flow',$stage,'--output_dir','outflow','--work_dir','work_compile','--timeout','10800')
foreach($argument in $arguments){$psi.ArgumentList.Add($argument)}
foreach($item in @(@('EFINITY_HOME',''),@('EFXPT_HOME','pt'),@('EFXPGM_HOME','pgm'),@('EFXDBG_HOME','debugger'),@('EFXIPM_HOME','ipm'),@('PYTHONHOME','python311'),@('QT_PLUGIN_PATH','bin'),@('QT_QPA_PLATFORM_PLUGIN_PATH','python311/platforms'))){$psi.Environment[$item[0]]=($toolRoot+'/'+$item[1]).TrimEnd('/')}
$psi.Environment['EFINITY_USER_DIR_INI']=(Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'efinity/user_dir.ini').Replace('\','/')
$psi.Environment['QT_LOGGING_CONF']=$toolRoot+'/bin/lc.ini'
$psi.Environment['QTWEBENGINE_CHROMIUM_FLAGS']='--disable-gpu'
$psi.Environment['PATH']=$toolRoot+'/python311/bin;'+$toolRoot+'/bin;'+$toolRoot+'/scripts;'+$psi.Environment['PATH']
$start=[DateTime]::UtcNow;$p=[Diagnostics.Process]::Start($psi)
SaveJson (Join-Path $runRoot ($stage+'.start.json')) @{started_at=$start.ToString('o');pid=$p.Id;argv=$arguments;scope='FULL_BOARD_COMPILE_NO_SIMULATION_NO_PROGRAMMING'}
$stdout=$p.StandardOutput.ReadToEndAsync();$stderr=$p.StandardError.ReadToEndAsync();$progress=$start
while(-not$p.WaitForExit(1000)){
    if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){Write-Output ('Board compile running pid='+$p.Id);$progress=[DateTime]::UtcNow}
}
$p.WaitForExit()
[IO.File]::WriteAllText((Join-Path $runRoot ($stage+'.stdout.log')),$stdout.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $runRoot ($stage+'.stderr.log')),$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
SaveJson (Join-Path $runRoot ($stage+'.result.json')) @{started_at=$start.ToString('o');ended_at=[DateTime]::UtcNow.ToString('o');exit_code=$p.ExitCode;hardware_passed=$false;simulations_run=0}
Write-Output ($stage+' exit '+$p.ExitCode+'; logs '+$runRoot)
if($p.ExitCode-ne0){exit $p.ExitCode}
}
SaveJson (Join-Path $runRoot 'result.json') @{status='PASS';stages=$stages;reuse_mapping=$ReuseMapping;hardware_passed=$false;simulations_run=0;ended_at=[DateTime]::UtcNow.ToString('o')}
exit 0
