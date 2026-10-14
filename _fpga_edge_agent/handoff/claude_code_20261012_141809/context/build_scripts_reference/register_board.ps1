param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RunId,
      [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ArtifactId)
$ErrorActionPreference='Stop'
$controlRoot='D:/大三/FPGA_verilog/_fpga_edge_agent'
$taskRoot='C:/Users/34528/FPGAEdgeLinks/Work/active/track4_board_first_20261011'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
$outRoot=Join-Path $runRoot 'flow/outflow'
function SaveJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
$result=Get-Content -LiteralPath (Join-Path $runRoot 'result.json') -Raw|ConvertFrom-Json
if($result.status-ne'PASS'){throw 'Compile did not complete successfully'}
# CLI通过不替代最终STA；只读取已完成run中的最终报告。
$timingPath=Join-Path $outRoot 'track4_board.timing.rpt'
$setup=@();$hold=@();$section='';$inRelationships=$false;$coreFrequency=0.0
foreach($line in [IO.File]::ReadLines($timingPath)){
    if($line-match'^core_clk\s+\d+\.\d+\s+(\d+\.\d+)\s+\{'){
        $coreFrequency=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture)
    }
    if($line-match'2\. Clock Relationship Summary \(begin\)'){$inRelationships=$true;continue}
    if($inRelationships-and$line-match'Clock Relationship Summary \(end\)'){break}
    if(-not$inRelationships){continue}
    if($line-match'^Setup \(Max\) Clock Relationship'){$section='setup';continue}
    if($line-match'^Hold \(Min\) Clock Relationship'){$section='hold';continue}
    if($line-match'^\s*(\S+)\s+(\S+)\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+\([RF]-[RF]\)'){
        $pair=@{launch=$Matches[1];capture=$Matches[2];slack_ns=[double]::Parse($Matches[4],[Globalization.CultureInfo]::InvariantCulture)}
        if($section-eq'setup'){$setup+=$pair}else{if($section-eq'hold'){$hold+=$pair}}
    }
}
if($setup.Count-eq0-or$hold.Count-eq0-or$coreFrequency-le0){throw 'Cannot read final clock/setup/hold tables'}
$setupMin=($setup.slack_ns|Measure-Object -Minimum).Minimum
$holdMin=($hold.slack_ns|Measure-Object -Minimum).Minimum
$timingPassed=$setupMin-ge0-and$holdMin-ge0
$coreSetup=($setup|Where-Object {$_.launch-eq'core_clk'-and$_.capture-eq'core_clk'}|Select-Object -First 1).slack_ns
$mapText=Get-Content -LiteralPath (Join-Path $outRoot 'track4_board.map.rpt') -Raw
$placeText=Get-Content -LiteralPath (Join-Path $outRoot 'track4_board.place.rpt') -Raw
function MapCount($Name){$match=[regex]::Match($mapText,('(?m)^'+[regex]::Escape($Name)+'\s*:\s*(\d+)'));if(-not$match.Success){return 0};return [int]$match.Groups[1].Value}
$xlrMatch=[regex]::Match($placeText,'XLRs:\s*(\d+)\s*/\s*(\d+)')
if(-not$xlrMatch.Success){throw 'Cannot read physical resource count'}
[xml]$projectXml=Get-Content -LiteralPath (Join-Path $runRoot 'flow/track4_board.xml') -Raw
$sourceCount=$projectXml.GetElementsByTagName('design_file','http://www.efinixinc.com/enf_proj').Count
if($sourceCount-le0){throw 'Cannot read source file list'}
$fitReport=Get-Content -LiteralPath (Join-Path $outRoot 'track4_board.res.csv') -Raw
$hasActualFit=(Test-Path -LiteralPath (Join-Path $runRoot 'flow/board/recognition_numeric/fit_core.sv'))-and
    $fitReport.Contains('fitting:fit_core')
$hasActualAngle=$fitReport.Contains('direction:angle_core')
$hasActualAnchors=$fitReport.Contains('anchors:board_recognition_anchors')
$limitedFit=$fitReport.Contains("LS_TLS_ONLY=1'b1")
$serialLocalFit=$fitReport.Contains("SERIAL_LOCAL_MOVES=1'b1")
$hasActualSeeds=$fitReport.Contains('circle_seeds:board_circle_seeds')
$hasActualDense=$fitReport.Contains('hough_dense:board_hough_dense')
$hasActualLinePeaks=$hasActualDense-and
    (Get-Content -LiteralPath (Join-Path $runRoot 'flow/board/rtl/board_hough_dense.sv') -Raw).Contains('NMS_PEAK_PACK')
$denseLanes=16;$denseMetadataVersion=1
if($hasActualDense){
    $denseParent=Get-Content -LiteralPath (Join-Path $runRoot 'flow/board/rtl/board_algorithm_rpc.sv') -Raw
    $laneMatch=[regex]::Match($denseParent,'board_hough_dense\s*#\([^;]*?\.LANES\((\d+)\)')
    if($laneMatch.Success){$denseLanes=[int]$laneMatch.Groups[1].Value}
    $denseCode=Get-Content -LiteralPath (Join-Path $runRoot 'flow/board/rtl/board_hough_dense.sv') -Raw
    $versionMatch=[regex]::Match($denseCode,"metadata\[\d+:\d+\]=8'd(\d+)")
    if($versionMatch.Success){$denseMetadataVersion=[int]$versionMatch.Groups[1].Value}
}
$hasFlatWrites=$fitReport.Contains("FLAT_WRITES=1'b1")
$fitRom=$fitReport.Contains("ROM_SCALAR=1'b1")
$sourceMatches=$true;$projectMatchesPrebuild=$true
foreach($inputFile in (Get-Content -LiteralPath (Join-Path $runRoot 'inputs.json') -Raw|ConvertFrom-Json)){
    $currentPath=Join-Path $taskRoot $inputFile.relative
    # 当前主工程仍与前置输入比对；另登记Efinity回写后的冻结工程XML哈希。
    if($inputFile.relative-eq'track4_board.xml'){
        $projectMatchesPrebuild=(Test-Path -LiteralPath $currentPath)-and
            (Get-FileHash -LiteralPath $currentPath).Hash-eq$inputFile.sha256
        if(-not$projectMatchesPrebuild){$sourceMatches=$false}
        continue
    }
    if(-not(Test-Path -LiteralPath $currentPath)-or(Get-FileHash -LiteralPath $currentPath).Hash-ne$inputFile.sha256){
        $sourceMatches=$false;break
    }
}
$stageRoot=Join-Path $controlRoot ('Artifacts/staging/'+$ArtifactId)
if(Test-Path -LiteralPath $stageRoot){throw 'Preserve existing artifact; choose a fresh ArtifactId'}
New-Item -ItemType Directory -Path $stageRoot -Force|Out-Null
$relativeFiles=@('inputs.json','result.json',
    'flow/track4_board.xml','flow/track4_board.sdc','flow/track4_board.peri.xml',
    'flow/outflow/track4_board.bit','flow/outflow/track4_board.hex','flow/outflow/track4_board.timing.rpt',
    'flow/outflow/track4_board.place.rpt','flow/outflow/track4_board.route.rpt','flow/outflow/track4_board.pinout.csv',
    'flow/outflow/track4_board.pt.rpt','flow/outflow/track4_board.map.rpt','flow/outflow/track4_board.res.csv')
foreach($stage in $result.stages){
    foreach($suffix in @('.start.json','.stdout.log','.stderr.log','.result.json')){
        $relativeFiles+=($stage+$suffix)
    }
}
if(Test-Path -LiteralPath (Join-Path $runRoot 'reused-map.json')){$relativeFiles+='reused-map.json'}
$files=@()
foreach($relative in $relativeFiles){
    $source=Join-Path $runRoot $relative;$target=Join-Path $stageRoot $relative
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
    Copy-Item -LiteralPath $source -Destination $target
    $files+=@{relative=$relative;bytes=(Get-Item -LiteralPath $target).Length;sha256=(Get-FileHash -LiteralPath $target).Hash}
}
$statusPath=Join-Path $taskRoot 'integration-status.json'
$status=Get-Content -LiteralPath $statusPath -Raw|ConvertFrom-Json
$manifest=[ordered]@{
    artifact_id=$ArtifactId;run=$RunId;registered_at_utc=[DateTime]::UtcNow.ToString('o')
    build_stages=$result.stages
    reused_mapping_from=$result.reuse_mapping
    status=$(if(-not$timingPassed){'SOFTWARE_REWORK_REQUIRED_TIMING'}elseif($hasActualLinePeaks){'SOFTWARE_BUILD_READY_POINT_STATS_SEEDS_DENSE_LINE_PEAKS'}elseif($hasActualDense){'SOFTWARE_BUILD_READY_POINT_STATS_SEEDS_FULL_DENSE'}elseif($hasActualSeeds){'SOFTWARE_BUILD_READY_POINT_STATS_FIT_ANCHORS_CIRCLE_SEEDS'}elseif($hasActualAngle-and$hasActualAnchors){'SOFTWARE_BUILD_READY_POINT_DIRECTION_STATS_FIT_ANCHORS'}elseif($hasActualFit){'SOFTWARE_BUILD_READY_FULL_POINT_STATS_FIT'}else{'SOFTWARE_BUILD_READY_FULL_POINT_STATS'})
    scope=$(if($hasActualLinePeaks){'Initial board video/Canny/partial display; full POINT64 v2, LS/TLS FIT, all-pair circle seeds, all-512-theta/all-POINT Hough DENSE32, radius-1 2D NMS with theta/rho mirror wrap and canonical ties, full LINE64 and versioned META DDR closure. Circle fitting, line segmentation, rectangle search and complete final annotation remain incomplete'}elseif($hasActualDense){'Initial board video/Canny/partial display; full POINT64 v2 and LS/TLS FIT, complete anchor-pair seed generation, all 512 theta and every POINT in parameterized-lane Hough DENSE32 with real DDR/META closure. Circle fitting, line peaks/segmentation, rectangle search and full final annotation remain incomplete'}elseif($hasActualSeeds){'Initial board video/Canny/partial display; full POINT64 v2 direction and LS/TLS FIT; complete anchor-pair circle seed generation, exact numeric ranking/sort and real DDR seed/META export. Complete complex geometry recognition and final annotation are incomplete'}elseif($hasActualAngle-and$hasActualAnchors){'Initial board video/Canny/partial display; full POINT64 v2 with actual 512-step direction, full-point LS/TLS and actual FIT responses, whole-point anchor selection and real DDR export; full complex recognition incomplete'}elseif($hasActualFit){'Initial board video/Canny/partial candidate display; full GRAD32, final EDGE1/POINT64, full-point LS/TLS stats and actual FIT responses committed to DDR; full complex recognition incomplete'}else{'Initial board video/Canny/partial candidate display; full GRAD32, final EDGE1/POINT64 and full-point LS/TLS stats; original full complex recognition incomplete'})
    device='Ti60F225';timing_model='I3';efinity_version='2026.1.132';source_entries=$sourceCount
    lut4=(MapCount 'EFX_LUT4');ff=(MapCount 'EFX_FF');ram10=(MapCount 'EFX_RAM10')
    dsp48=(MapCount 'EFX_DSP48');dsp24=(MapCount 'EFX_DSP24')
    packed_logic=[int]$xlrMatch.Groups[1].Value;capacity=[int]$xlrMatch.Groups[2].Value
    setup_min_ns=$setupMin;hold_min_ns=$holdMin;core_setup_ns=$coreSetup;timing_passed=$timingPassed
    synthesis_passed=$true;pnr_passed=$true;bitstream_ready_for_human_programming=$timingPassed
    hardware_gate=$(if($timingPassed){'WAITING_HUMAN_PROGRAM'}else{'SOFTWARE_REWORK_REQUIRED'})
    hardware_passed=$false;hardware_programming_performed=$false;simulations_run=0;local_audit_exception=$true
    formal_database_or_hardware_state_changed=$false;original_full_complex_recognition_complete=$false
    full_project_goal_complete=$false;point_base='0x05000000';point_capacity=2073600;point_record_bytes=8
    raw_stats_base='0x06000000';raw_stats_bytes=256;application_clock_mhz=$coreFrequency
    full_point_ls_tls_fit_integrated=$hasActualFit
    fit_request_kinds_used=@(11,12)
    unused_fit_branches_pruned=$limitedFit
    fit_local_moves_use_shared_word_arithmetic=$serialLocalFit
    fit_fixed_instruction_rom_integrated=$fitRom
    full_point_direction_integrated=$hasActualAngle
    whole_point_anchor_selection_integrated=$hasActualAnchors
    flattened_write_payload_tree_integrated=$hasFlatWrites
    full_512_theta_dense_integrated=$hasActualDense
    full_2d_nms_line_peaks_integrated=$hasActualLinePeaks
    line_base=$(if($hasActualLinePeaks){'0x06700000'}else{$null})
    line_capacity=$(if($hasActualLinePeaks){1024}else{0})
    line_record_bytes=$(if($hasActualLinePeaks){8}else{0})
    initial_line_min_support=$(if($hasActualLinePeaks){16}else{$null})
    line_threshold_quality_verified=$false
    dense_base=$(if($hasActualDense){'0x06400000'}else{$null})
    dense_bytes=$(if($hasActualDense){1048576}else{0})
    dense_theta_count=$(if($hasActualDense){512}else{0})
    dense_parallel_lanes=$(if($hasActualDense){$denseLanes}else{0})
    dense_point_passes=$(if($hasActualDense){512/$denseLanes}else{0})
    dense_metadata_version=$(if($hasActualDense){$denseMetadataVersion}else{$null})
    cache_tag_ram_integrated=$fitReport.Contains("RAM_TAGS=1'b1")
    queue_history_ram_integrated=$fitReport.Contains("RAM_CARRY=1'b1")
    scalar_ram_word_reads_integrated=$fitReport.Contains("AREA_RAM_WORDS=1'b1")
    gradient_ram_pack_integrated=$fitReport.Contains("RAM_PACK=1'b1")
    axi_snapshot_narrow_ram_read_integrated=$fitReport.Contains("NARROW_RAM_READ=1'b1")
    cache_data_ways_packed=$fitReport.Contains("PACK_DATA_WAYS=1'b1")
    fit_word_slots_integrated=$fitReport.Contains("WORD_SLOTS=1'b1")
    scalar_result_ram_integrated=$fitReport.Contains("RAM_RESULT=1'b1")
    frame_sink_dsp_buffers_integrated=$fitReport.Contains("DSP_BUFFER=1'b1")
    rgb_dsp_packets_integrated=$fitReport.Contains("DSP_PACKETS=1'b1")
    angle_borrowed_request_integrated=$fitReport.Contains("BORROW_REQUEST=1'b1")
    cache_dsp_writeback_integrated=$fitReport.Contains("DSP_WB=1'b1")
    queue_dsp_writer_integrated=$fitReport.Contains("DSP_WRITER=1'b1")
    seed_dsp_records_integrated=$fitReport.Contains("DSP_RECORDS=1'b1")
    fit_dsp_operand_result_integrated=$fitReport.Contains("DSP_OPERAND_RESULT=1'b1")
    axi_dsp_read_snapshot_integrated=$fitReport.Contains("DSP_READ_BUFFER=1'b1")
    recognition_scope_borrowed=$fitReport.Contains("BORROW_SCOPE=1'b1")
    stats_context_borrowed=$fitReport.Contains("BORROW_CONTEXT=1'b1")
    canny_job_context_borrowed=$fitReport.Contains("BORROW_JOB=1'b1")
    display_boxes_borrowed=$fitReport.Contains("BORROW_BOXES=1'b1")
    scalar_header_borrowed=$fitReport.Contains("BORROW_HEADER=1'b1")
    fit_private_sequence_reused=$fitReport.Contains("CLOSE_SEQUENCE=1'b1")
    dense_valid_rho_bins=$(if($hasActualDense){277}else{0})
    dense_physical_rho_bins=$(if($hasActualDense){512}else{0})
    dense_metadata_base=$(if($hasActualDense){'0x06500000'}else{$null})
    complete_anchor_pair_seed_generation_integrated=$hasActualSeeds
    seed_base=$(if($hasActualSeeds){'0x06003000'}else{$null})
    seed_capacity=$(if($hasActualSeeds){256}else{0})
    seed_record_bytes=$(if($hasActualSeeds){16}else{0})
    seed_metadata_base=$(if($hasActualSeeds){'0x06004000'}else{$null})
    point_format_version=$(if($hasActualAngle){2}else{1})
    anchor_base=$(if($hasActualAnchors){'0x06001000'}else{$null})
    anchor_capacity=$(if($hasActualAnchors){768}else{0})
    fit_response_base=$(if($hasActualFit){'0x06000100'}else{$null})
    fit_response_bytes=$(if($hasActualFit){256}else{0})
    current_sources_match_built_snapshot=$sourceMatches
    current_project_xml_matches_prebuild_input=$projectMatchesPrebuild
    built_project_xml_sha256=(Get-FileHash -LiteralPath (Join-Path $runRoot 'flow/track4_board.xml')).Hash
    unclosed_scope=@('Complete complex candidate generation, iterative circle/rotated rectangle fitting, frozen verification, deduplication and complete final annotation/records','Actual camera, DDR and HDMI effects and processing rate')
    files=$files
}
SaveJson (Join-Path $stageRoot 'artifact-manifest.json') $manifest
$event=[ordered]@{event_id=('EV-BOARD-REGISTER-'+$RunId);project_id='FPGA_EDGE_TI60';session_id='FAST-BATCH-20261008';
    operation_id=('REGISTER-'+$ArtifactId);node_id='INITIAL_BOARD_WITH_PARTIAL_A6';artifact_id=$ArtifactId;
    at_utc=[DateTime]::UtcNow.ToString('o');status=$manifest.status;
    artifact_manifest=('_fpga_edge_agent/artifacts/staging/'+$ArtifactId+'/artifact-manifest.json');run=$RunId;
    setup_min_ns=$setupMin;hold_min_ns=$holdMin;packed_logic=$manifest.packed_logic;capacity=$manifest.capacity;
    hardware_gate=$manifest.hardware_gate;hardware_passed=$false;standalone_simulations_run=0;
    original_complex_recognition_complete=$false;full_project_goal_complete=$false;previous_goal_turn_classification='PROGRESS'}
[IO.File]::AppendAllText((Join-Path $controlRoot 'Runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl'),
    ($event|ConvertTo-Json -Compress -Depth 8)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
$status.bitstream_registered=$true;$status.timing_passed=$timingPassed
$status.synthesis_passed=$true;$status.pnr_passed=$true;$status.peripheral_generation_passed=$true
$status.artifact_manifest=$event.artifact_manifest
$status.setup_worst_ns=$setupMin;$status.hold_min_ns=$holdMin;$status.packed_logic=$manifest.packed_logic
$status.latest_lut4=$manifest.lut4;$status.latest_ff=$manifest.ff;$status.latest_ram10=$manifest.ram10
$status.bitstream_path=('runs/'+$RunId+'/flow/outflow/track4_board.bit')
$status.application_clock_mhz=$coreFrequency;$status.hardware_gate=$manifest.hardware_gate
$status.initial_software_build_complete=$timingPassed
$status.current_sources_differ_from_last_built_snapshot=-not$sourceMatches;$status.updated_at_utc=[DateTime]::UtcNow.ToString('o')
if($sourceMatches){
    $status.current_run=$RunId;$status.status=$manifest.status;$status.source_entries=$sourceCount
    $status.current_run_result=$(if($timingPassed){'PASS'}else{'TIMING_FAIL'})
    $status.current_run_synthesis_passed=$true;$status.current_run_pnr_passed=$true
    $status.current_sources_differ_from_running_snapshot=$false
    $status.current_changes=$(if($hasActualDense){'完整点/方向/LS-TLS/FIT/anchor/圆种子，全512theta×全POINT的复用并行DENSE投票、全表与META真实DDR关闭；整机综合、布局布线、STA和bit/hex结束。完整几何识别未完成。'}elseif($hasActualSeeds){'完整点方向/LS-TLS/FIT/anchor；全部a<b圆候选生成、排名排序、SEED256及META真实DDR写回；整机综合/布局布线/最终STA和bit/hex已结束。显示仍为初版几何候选，完整复杂识别未完成。'}elseif($hasActualAngle-and$hasActualAnchors){'完整点表512档方向、LS/TLS与真实FIT、全点种子选择和DDR写回；整机综合、布局布线、最终STA及bit/hex已结束'}elseif($hasActualFit){'完整POINT的LS/TLS统计、真实FIT结果写DDR、队列持有回复复用与整行EDGE RAM；整机综合、布局布线、最终STA及bit/hex已结束'}else{'共享Sobel窗口/梯度，全POINT两遍统计，RAM写快照；整机综合、布局布线、最终STA和bit/hex已结束'})
}else{
    $status.status='SOFTWARE_REWORK_IN_PROGRESS'
}
if($timingPassed){$status.latest_completed_run=$RunId;$status.last_verified_build=@{run=$RunId;artifact=$ArtifactId;synthesis=$true;pnr=$true;timing=$true}}
SaveJson $statusPath $status
Write-Output ('Registered '+$ArtifactId+'; setup='+$setupMin+' ns; hold='+$holdMin+' ns; hardware not programmed')
if(-not$timingPassed){exit 2}
if($timingPassed){
    & (Join-Path $PSScriptRoot 'prepare_debug_handoff.ps1') -RunId $RunId -ArtifactId $ArtifactId
}
