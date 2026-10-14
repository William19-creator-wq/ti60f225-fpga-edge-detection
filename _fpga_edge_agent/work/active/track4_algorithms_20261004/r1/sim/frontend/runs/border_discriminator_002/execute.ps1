# Root授权的隔离FT06 T41专项；修正001审计路径数组，保留其失败。
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$root='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_algorithms_20261004/r1'
$run=Join-Path $root 'sim/frontend/runs/border_discriminator_002'
$tools='C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64'
if(Test-Path -LiteralPath (Join-Path $run vectors)){throw 'Fresh generation required'}
& 'D:/py___/python.exe' -B (Join-Path $run generate.py) > (Join-Path $run reference.log) 2>&1
if($LASTEXITCODE){throw 'Independent reference failed'}
$manifest=Get-Content -Raw -LiteralPath (Join-Path $run vectors/manifest.json) | ConvertFrom-Json
$sources=@('C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v')+@('line_store_pair','rgb_to_y_pair','median9_pair','sobel_pair','window3x3_pair','frontend_frame_pair' | ForEach-Object {Join-Path $root ('rtl/frontend/'+$_+'.sv')})+@('frontend_tb_driver','tb_rgb_to_y_pair','tb_median9_pair','tb_sobel_pair','tb_window3x3_pair','tb_frontend_frame_pair' | ForEach-Object {Join-Path $root ('sim/frontend/'+$_+'.sv')})
$auditFiles=$sources+@((Join-Path $run generate.py),(Join-Path $run vectors/manifest.json),$PSCommandPath,(Join-Path $root model/frontend_reference.py))
$hashes=@($auditFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$summary=[ordered]@{scope='SUPPLEMENTAL_FT06_T41_NOT_FULL_SUITE';status='RUNNING';inputs=$hashes;reference_sha256=$manifest.reference_sha256;cases=@();error=$null}
$old=[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','Process')
try {
    if([string]::IsNullOrEmpty($old)){[Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',[Environment]::GetEnvironmentVariable('MGLS_LICENSE_FILE','User'),'Process')}
    Push-Location -LiteralPath $run
    try {
        & (Join-Path $tools vlib.exe) work > vlib.log 2>&1
        if($LASTEXITCODE){throw 'vlib failed'}
        & (Join-Path $tools vlog.exe) -sv -timescale 1ns/1ps -work work @sources > vlog.log 2>&1
        if($LASTEXITCODE){throw 'vlog failed'}
        foreach($case in $manifest.cases){
            $dir=Join-Path $run $case.case_id
            New-Item -ItemType Directory -Path $dir | Out-Null
            $macro=Join-Path $dir run.do
            [IO.File]::WriteAllLines($macro,@('onerror {quit -code 1}','onbreak {set rc 1; if {![catch {examine -radix binary /tb_frontend_frame_pair/check/done} value] && $value eq "1"} {set rc 0}; quit -code $rc}','log /tb_frontend_frame_pair/check/clk /tb_frontend_frame_pair/check/out_valid /tb_frontend_frame_pair/check/out_ready /tb_frontend_frame_pair/check/out_y_pair /tb_frontend_frame_pair/check/out_edge /tb_frontend_frame_pair/check/g_frontend/dut/unused_l1','run -all','quit -code 1'))
            $argsList=@('-c','-onfinish','stop','-voptargs=+acc','-lib','work','tb_frontend_frame_pair','-gW=4','-gH=3',('+CASE='+$case.case_id),('+IN='+(Join-Path $run ('vectors/'+$case.stimulus_file))),('+EXPECTED='+(Join-Path $run ('vectors/'+$case.expected_file))),('+RESULT='+(Join-Path $dir result.json)),'+PAIRS=6','+EXPECTED_PAIRS=6','+STATUS=0','+MAX_CYCLES=500','+EPOCH=7','+FRAME=101','+CONFIG=141',('+MEDIAN='+[int]$case.median_enable),'+KIND=1','+THRESHOLD=41','+TIMING=1','-wlf',(Join-Path $dir trace.wlf),'-do',$macro)
            & (Join-Path $tools vsim.exe) @argsList > (Join-Path $dir vsim.log) 2>&1
            $exitCode=$LASTEXITCODE
            $result=Get-Content -Raw -LiteralPath (Join-Path $dir result.json) | ConvertFrom-Json
            $summary.cases+=@{case_id=$case.case_id;exit_code=$exitCode;result=$result;corner_reference_l1=$case.corner_reference_l1;corner_expected_edges=$case.corner_expected_edges}
            if($exitCode -ne 0 -or -not $result.finished -or $result.status -ne 0 -or $result.jobs_completed -ne 1 -or $result.compared_pairs -ne 6 -or $result.accepted_pairs -ne 6 -or $result.delivered_pairs -ne 6 -or $result.numeric_errors -ne 0 -or $result.protocol_errors -ne 0){throw 'Numeric/protocol comparison failed'}
        }
        foreach($input in $hashes){if((Get-FileHash -LiteralPath $input.path -Algorithm SHA256).Hash -ne $input.sha256){throw 'Input source changed'}}
        $summary.status='SUPPLEMENTAL_PASS'
    } finally {Pop-Location}
} catch {$summary.status='FAIL';$summary.error=$_.Exception.Message;throw}
finally {
    $summary | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath (Join-Path $run supplemental-result.json) -Encoding utf8
    [Environment]::SetEnvironmentVariable('MGLS_LICENSE_FILE',$old,'Process')
}
