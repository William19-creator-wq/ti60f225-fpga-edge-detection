param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
      [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ArtifactId)
$ErrorActionPreference='Stop'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_board_first_20261011'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
$resultPath=Join-Path $runRoot 'result.json'
$missingSince=$null;$progress=[DateTime]::UtcNow
while(-not(Test-Path -LiteralPath $resultPath)){
    # 普通compile与复用MAP后的interface/pnr/pgm都按真实分段结果判断。
    foreach($stage in @('compile','interface','pnr','pgm')){
        $stageResultPath=Join-Path $runRoot ($stage+'.result.json')
        if(Test-Path -LiteralPath $stageResultPath){
            $stageResult=Get-Content -LiteralPath $stageResultPath -Raw|ConvertFrom-Json
            if($stageResult.exit_code-ne0){throw ('Stage '+$stage+' failed; no successful artifact registered: '+$RunId)}
        }
    }
    $latestStart=Get-ChildItem -LiteralPath $runRoot -Filter '*.start.json' -File|
        Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
    $startRecord=if($latestStart){Get-Content -LiteralPath $latestStart.FullName -Raw|ConvertFrom-Json}else{$null}
    $live=if($startRecord){Get-Process -Id $startRecord.pid -ErrorAction SilentlyContinue}else{$null}
    if($live){$missingSince=$null}else{
        if($null-eq$missingSince){$missingSince=[DateTime]::UtcNow}
        if(([DateTime]::UtcNow-$missingSince).TotalSeconds-ge15){throw 'Compiler ended without a successful result; inspect original run'}
    }
    if(([DateTime]::UtcNow-$progress).TotalSeconds-ge30){
        Write-Output ('Waiting for actual build '+$RunId+' pid='+$(if($startRecord){$startRecord.pid}else{'pending'}))
        $progress=[DateTime]::UtcNow
    }
    Start-Sleep -Milliseconds 500
}
& (Join-Path $taskRoot 'scripts/register_board.ps1') -RunId $RunId -ArtifactId $ArtifactId
exit $LASTEXITCODE
