param([Parameter(Mandatory)][ValidatePattern('^board_compile_\d{3}$')][string]$RunId,
      [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ArtifactId)
$ErrorActionPreference='Stop'
$controlRoot='D:/大三/FPGA_verilog/_fpga_edge_agent'
$taskRoot=Join-Path $controlRoot 'work/active/track4_board_first_20261011'
$runRoot=Join-Path $taskRoot ('runs/'+$RunId)
$flowRoot=Join-Path $runRoot 'flow'
$artifactRoot=Join-Path $controlRoot ('artifacts/staging/'+$ArtifactId)
$manifestPath=Join-Path $artifactRoot 'artifact-manifest.json'
$number=$RunId.Substring('board_compile_'.Length)
$debugName='track4_board_debug_'+$number+'_20261011'
$debugRoot=Join-Path $controlRoot ('work/active/'+$debugName)
$debugRelative='_fpga_edge_agent/work/active/'+$debugName
$utf8=[Text.UTF8Encoding]::new($false)
function SaveJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 12),$utf8)}
function ChildPath($Root,[string]$Relative){
    if([string]::IsNullOrWhiteSpace($Relative)-or[IO.Path]::IsPathRooted($Relative)){throw 'Invalid relative evidence path'}
    $base=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))+[IO.Path]::DirectorySeparatorChar
    $path=[IO.Path]::GetFullPath((Join-Path $base $Relative))
    if(-not$path.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)){throw ('Evidence path escapes its root: '+$Relative)}
    return $path
}
function AssertFile($Path,[string]$ExpectedHash,$ExpectedBytes=$null){
    $file=Get-Item -LiteralPath $Path
    if($file.PSIsContainer-or$ExpectedHash-notmatch'^[A-Fa-f0-9]{64}$'){throw ('Invalid file/hash: '+$Path)}
    if($null-ne$ExpectedBytes-and$file.Length-ne$ExpectedBytes){throw ('File length mismatch: '+$Path)}
    $actual=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if($actual-ne$ExpectedHash){throw ('File hash mismatch: '+$Path)}
    return $actual
}

# 先检查真实已登记的同一 run；失败编译或初步 placement 时序不能形成硬件交付。
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
$result=Get-Content -LiteralPath (Join-Path $runRoot 'result.json') -Raw|ConvertFrom-Json
if($manifest.artifact_id-ne$ArtifactId-or$manifest.run-ne$RunId-or$result.status-ne'PASS'){
    throw 'Handoff requires the registered artifact from this successful run'
}
if($manifest.timing_passed-ne$true-or$manifest.synthesis_passed-ne$true-or$manifest.pnr_passed-ne$true-or
   $manifest.bitstream_ready_for_human_programming-ne$true-or$manifest.setup_min_ns-lt0-or$manifest.hold_min_ns-lt0){
    throw 'Handoff requires successful synthesis, route and final setup/hold timing'
}
if($manifest.packed_logic-gt$manifest.capacity-or$manifest.device-ne'Ti60F225'-or$manifest.timing_model-ne'I3'){
    throw 'Registered capacity/device does not match this handoff'
}
if(Test-Path -LiteralPath $debugRoot){throw ('Refusing to overwrite existing debug directory: '+$debugRoot)}
$registered=@{}
foreach($entry in $manifest.files){
    $relative=([string]$entry.relative).Replace('\','/')
    if($registered.ContainsKey($relative)){throw ('Duplicate registered evidence: '+$relative)}
    $registered[$relative]=$entry
    $null=AssertFile (ChildPath $runRoot $relative) $entry.sha256 $entry.bytes
    $null=AssertFile (ChildPath $artifactRoot $relative) $entry.sha256 $entry.bytes
}
foreach($relative in @('inputs.json','result.json','flow/track4_board.xml','flow/track4_board.sdc',
    'flow/track4_board.peri.xml','flow/outflow/track4_board.bit','flow/outflow/track4_board.hex',
    'flow/outflow/track4_board.timing.rpt','flow/outflow/track4_board.place.rpt',
    'flow/outflow/track4_board.route.rpt','flow/outflow/track4_board.pinout.csv',
    'flow/outflow/track4_board.pt.rpt','flow/outflow/track4_board.map.rpt','flow/outflow/track4_board.res.csv')){
    if(-not$registered.ContainsKey($relative)-or$registered[$relative].bytes-le0){throw ('Missing registered evidence: '+$relative)}
}
$postXmlHash=[string]$manifest.built_project_xml_sha256
if($postXmlHash-ne$registered['flow/track4_board.xml'].sha256){throw 'Registered postcompile XML identity mismatch'}
$inputs=@(Get-Content -LiteralPath (Join-Path $runRoot 'inputs.json') -Raw|ConvertFrom-Json)
if($inputs.Count-ne205){throw 'This delivery profile requires the 205 frozen prebuild inputs'}
$inputMap=@{}
$preXmlHash=$null
foreach($entry in $inputs){
    $relative=([string]$entry.relative).Replace('\','/')
    if($inputMap.ContainsKey($relative)){throw ('Duplicate frozen input: '+$relative)}
    $inputMap[$relative]=$entry
    $expected=[string]$entry.sha256
    if($relative-eq'track4_board.xml'){$preXmlHash=$expected;$expected=$postXmlHash}
    $null=AssertFile (ChildPath $flowRoot $relative) $expected
}
if($null-eq$preXmlHash){throw 'Frozen project XML input is missing'}
[xml]$project=Get-Content -LiteralPath (Join-Path $flowRoot 'track4_board.xml') -Raw
$sources=$project.GetElementsByTagName('design_file','http://www.efinixinc.com/enf_proj')
if($sources.Count-ne$manifest.source_entries-or$sources.Count-le0){throw 'Postcompile source list differs from the registered count'}
foreach($source in $sources){
    $relative=([string]$source.name).Replace('\','/')
    if(-not$inputMap.ContainsKey($relative)){throw ('Project source is outside the frozen inputs: '+$relative)}
}
foreach($directory in @('algorithm','board','ip','rtl','outflow','work_compile')){
    if(-not(Test-Path -LiteralPath (Join-Path $flowRoot $directory) -PathType Container)){throw ('Missing compiled directory: '+$directory)}
}
$identitySource=Join-Path $controlRoot 'work/active/track4_board_debug_031_20261011/hardware-identity-confirmation.json'
$identity=Get-Content -LiteralPath $identitySource -Raw|ConvertFrom-Json
if($identity.confirmed_by-ne'USER'-or$identity.board-ne'Ti60F225 DemoBoard V4'-or$identity.camera-ne'SC431HAI'){
    throw 'Confirmed V4/SC431HAI hardware identity is required'
}

# 同 run 的 flow 全量复制：四个源码目录、编译中间文件、最终报告和真实 postcompile XML。
$null=New-Item -ItemType Directory -Path $debugRoot
foreach($item in Get-ChildItem -LiteralPath $flowRoot -Force){
    Copy-Item -LiteralPath $item.FullName -Destination $debugRoot -Recurse
}
$flowPrefix=[IO.Path]::GetFullPath($flowRoot).TrimEnd([char[]]@('\','/'))+[IO.Path]::DirectorySeparatorChar
$copiedFiles=@(foreach($file in Get-ChildItem -LiteralPath $flowRoot -Recurse -File -Force){
    $relative=$file.FullName.Substring($flowPrefix.Length).Replace('\','/')
    $hash=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $null=AssertFile (ChildPath $debugRoot $relative) $hash $file.Length
    @{relative=$relative;bytes=$file.Length;sha256=$hash}
})
foreach($entry in $inputs){
    $relative=([string]$entry.relative).Replace('\','/')
    $expected=[string]$entry.sha256
    if($relative-eq'track4_board.xml'){$expected=$postXmlHash}
    $null=AssertFile (ChildPath $debugRoot $relative) $expected
}
$evidenceRoot=Join-Path $debugRoot 'evidence'
$null=New-Item -ItemType Directory -Path $evidenceRoot
foreach($entry in $manifest.files){
    $relative=([string]$entry.relative).Replace('\','/')
    if($relative.StartsWith('flow/')){$destination=ChildPath $debugRoot $relative.Substring(5)}
    else{
        $destination=ChildPath $evidenceRoot $relative
        $parent=Split-Path -Parent $destination
        $null=New-Item -ItemType Directory -Path $parent -Force
        Copy-Item -LiteralPath (ChildPath $runRoot $relative) -Destination $destination
    }
    $null=AssertFile $destination $entry.sha256 $entry.bytes
}
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $evidenceRoot 'artifact-manifest.json')
$null=AssertFile (Join-Path $evidenceRoot 'artifact-manifest.json') (Get-FileHash -LiteralPath $manifestPath).Hash
Copy-Item -LiteralPath $identitySource -Destination (Join-Path $debugRoot 'hardware-identity-confirmation.json')
$null=AssertFile (Join-Path $debugRoot 'hardware-identity-confirmation.json') (Get-FileHash -LiteralPath $identitySource).Hash
$at=[DateTime]::UtcNow.ToString('o')
$bitHash=$registered['flow/outflow/track4_board.bit'].sha256
$handoff=@{
    delivery_scope='INITIAL_BOARD_DEBUG_WITH_PARTIAL_GEOMETRY';built_run=$RunId;artifact_id=$ArtifactId;copied_at_utc=$at
    project='track4_board.xml';top='track4_board_top';device=$manifest.device;timing_model=$manifest.timing_model
    source_entries=$sources.Count;frozen_input_count=$inputs.Count;validated_input_count=$inputs.Count;flow_file_count=$copiedFiles.Count
    copied_files_equal_actual_compiled_run=$true;source_constraints_match_prebuild_inputs=$true
    project_xml_matches_registered_postcompile_project=$true;project_xml_differs_from_prebuild_hash=($postXmlHash-ne$preXmlHash)
    prebuild_project_xml_sha256=$preXmlHash;postcompile_project_xml_sha256=$postXmlHash
    bit='outflow/track4_board.bit';bit_sha256=$bitHash;hex='outflow/track4_board.hex';hex_sha256=$registered['flow/outflow/track4_board.hex'].sha256
    registered_artifact='_fpga_edge_agent/artifacts/staging/'+$ArtifactId+'/artifact-manifest.json'
    synthesis_passed=$true;pnr_passed=$true;timing_passed=$true;setup_min_ns=$manifest.setup_min_ns
    hold_min_ns=$manifest.hold_min_ns;core_setup_ns=$manifest.core_setup_ns;application_clock_mhz=$manifest.application_clock_mhz
    packed_logic=$manifest.packed_logic;packed_capacity=$manifest.capacity;lut4=$manifest.lut4;ff=$manifest.ff
    ram10=$manifest.ram10;dsp48=$manifest.dsp48;dsp24=$manifest.dsp24;simulations_run_this_batch=$manifest.simulations_run
    dense_parallel_lanes=$manifest.dense_parallel_lanes;dense_point_passes=$manifest.dense_point_passes
    dense_metadata_version=$manifest.dense_metadata_version;complete_anchor_pair_seed_generation_integrated=$manifest.complete_anchor_pair_seed_generation_integrated
    hardware_identity_source='_fpga_edge_agent/work/active/track4_board_debug_031_20261011/hardware-identity-confirmation.json'
    hardware_identity_event=$identity.event_id;hardware_gate='WAITING_HUMAN_PROGRAM'
    hardware_programmed=$false;hardware_effects_verified=$false;hardware_feedback_status='NOT_RECEIVED'
    original_full_complex_recognition_complete=$false;full_project_goal_complete=$false
    local_audit_exception=$true;formal_database_or_hardware_state_changed=$false
    files=$copiedFiles;registered_files=$manifest.files;unclosed_scope=$manifest.unclosed_scope
}
SaveJson (Join-Path $debugRoot 'handoff.json') $handoff
SaveJson (Join-Path $debugRoot 'hardware-firsttest-feedback.json') @{
    artifact_id=$ArtifactId;built_run=$RunId;created_at_utc=$at;status='NOT_RECEIVED'
    hardware_gate='WAITING_HUMAN_PROGRAM';hardware_programming_reported=$false;hardware_effects_verified=$false
    note='本版本尚未收到人工下载或实物观察回报；复制的硬件身份记录仅证明板卡与摄像头型号。'
    formal_database_or_hardware_state_changed=$false
}
$guide=@"
Ti60F225 DemoBoard V4 + SC431HAI 实物首测（$number，2026-10-11）

一、交付内容
打开项目：$debugRoot/track4_board.xml
顶层 track4_board_top，芯片 Ti60F225，速度模型 I3，Efinity $($manifest.efinity_version)。
本目录来自 $RunId 完整冻结 flow，包含 $($sources.Count) 项工程源码、205 份已核对输入、outflow 与 work_compile。
下载文件：$debugRoot/outflow/track4_board.bit
bit SHA256：$bitHash
最终综合、布局布线及 STA 通过；setup 最小 $($manifest.setup_min_ns) ns，hold 最小 $($manifest.hold_min_ns) ns，core setup $($manifest.core_setup_ns) ns。
实际 XLR $($manifest.packed_logic)/$($manifest.capacity)，LUT $($manifest.lut4)，FF $($manifest.ff)，RAM10 $($manifest.ram10)，DSP48 $($manifest.dsp48)，DSP24 $($manifest.dsp24)。
真实 postcompile XML、bit/hex、最终 STA 与资源报告的登记哈希见 evidence/artifact-manifest.json；全量复制哈希见 handoff.json。
硬件型号已由用户确认；本版本尚未收到下载及效果回报。本批没有新增独立仿真测试，软件编译通过不能替代实物观察。

二、人工下载
1. 按 V4 原厂说明连接 SC431HAI、供电和跳线；使用 V4 的接口位置与供电要求。
2. 接 HDMI TX 到支持 1080p60 的显示器，连接 FTDI/JTAG USB。
3. 在 Efinity 用 Open Project 打开上面的 track4_board.xml。
4. 打开 Programmer，选择 JTAG 及本目录 outflow/track4_board.bit，人工执行 Program FPGA。
5. 保存 Programmer 成功/失败日志。成功后短按 KEY1 复位，等待 DDR 初始化和画面出现。本说明采用易失 JTAG 下载，断电后需重新下载。

三、先观察模式 0–4
默认模式 4：彩色摄像头画面叠加红色 Canny 边缘。
模式 0：彩色原图；1：灰度；2：左灰度、右 Sobel；3：黑白 Canny；4：彩色加红色边缘；5：初版几何候选框。
KEY3 短按并松开依次切换，默认 4 的下一项为 5，再下一项为 0。先在默认 4 检查彩色画面与边缘，再切其他模式观察。
从默认 4 短按两次到 0 会经过 5：若模式 5 的作业已被接受，随后改为 0 不会立即终止当前配对/Hough 作业，旧帧仍保持，需等本次处理关闭才能更新。
KEY1 复位可重新从默认 4 开始；模式键不能保证即时中断正在进行的模式 5 处理。
用白纸上的粗黑圆或矩形作为简单场景；中值滤波已接入处理链，没有单独显示模式。

四、模式 5 的等待与当前边界
模式 5 有最多四组可见强轮廓候选框，绿色 C、黄色 R、白色 C/R 是初版分类提示。
内部已接完整 POINT 方向、LS/TLS/FIT、全点 anchor、全部 a<b anchor 配对圆种子、全 512 theta DENSE 投票与二维 NMS。
Hough 采用 $($manifest.dense_parallel_lanes) 路复用、完整 POINT 表 $($manifest.dense_point_passes) 遍处理；768 个 anchor 最多产生 294528 对候选。
它需要整条识别链关闭后才能发布新的完整显示帧，期间显示上一张已完成帧。点多或纹理复杂时可能等待分钟级；实际处理时间尚未在实物测量，不能承诺切到 5 后立刻更新。
显示器 1080p60 扫描刷新率不等于算法每秒完成 60 帧。建议先用少量清晰粗轮廓，模式 0–4 优先。
完整圆/旋转矩形拟合、遮挡与整边缺失、重叠、多目标去重及最终完整标注仍未完成或证明；模式 5 的框与字母不能当作全部原始复杂识别指标已达成。

五、按键与 LED
KEY1/P13：复位。KEY0/C4：提高边缘阈值；KEY2/N13：降低阈值。
KEY3/A3：短按松开切模式；长按约 0.22 秒触发冻结/恢复，首测可按住约 0.5 秒以区别短按。
冻结保持上一张已完成显示帧，恢复更新仍需等待当前处理关闭。
KEY0+KEY2 同时按：轮换四种 Bayer 相位，默认 1；仅在颜色明显异常时尝试，下一帧生效。
LED0/N14：DDR 校准完成后周期闪烁。LED1/P14：正常状态为 0，冻结时周期变化，故障时为 1；物理亮灭以板卡 LED 极性为准。
LED 变化仅帮助判断控制状态，不能单独证明摄像头、DDR 内容和 HDMI 效果正常。

六、首测回报
记录 Programmer 是否成功、显示器是无信号还是已锁定黑屏、LED/复位反应、模式 0 是否实时彩色、模式 1–4 切换及边缘效果。
模式 5 另记录场景、等待时间、画面是否最终更新和框/字母表现；先用少轮廓场景，不用纹理背景估计首帧速度。
如无画面，附板卡丝印、摄像头与 HDMI 接线照片及 Programmer 日志。本版本 hardware-firsttest-feedback.json 当前是 NOT_RECEIVED，需收到真实人工回报后再更新。
"@
[IO.File]::WriteAllText((Join-Path $debugRoot ('实物首测说明_'+$number+'.txt')),$guide,$utf8)
$readme=@"
# Ti60F225 V4 初步实物调试包 $number

在 Efinity 打开 [track4_board.xml](track4_board.xml)，下载 [outflow/track4_board.bit](outflow/track4_board.bit)。
人工接线、JTAG 下载、模式、按键与观察方法见 [实物首测说明_${number}.txt](实物首测说明_${number}.txt)。

本包是 $RunId 完整 flow 的冻结副本，$($sources.Count) 项源码，205 份输入全部核对；项目 XML 使用真实已登记 postcompile SHA。
最终综合、布局布线与 setup/hold 均通过；setup $($manifest.setup_min_ns) ns、hold $($manifest.hold_min_ns) ns；XLR $($manifest.packed_logic)/$($manifest.capacity)，RAM10 $($manifest.ram10)，DSP48 $($manifest.dsp48)。
先在默认 4 验证，再观察 0–4；模式 5 含全 anchor 配对和 $($manifest.dense_point_passes) 遍完整 POINT Hough，复杂场景可能分钟级等待。若 5 作业已经开始，随后切到 0 不会立即中断它，需等待关闭；KEY1 复位可返回默认 4。完整复杂几何识别及实际效果仍未闭合。

bit SHA256：$bitHash

证据：[handoff.json](handoff.json)、[登记清单](evidence/artifact-manifest.json)、[硬件身份确认](hardware-identity-confirmation.json)。
新版本实物反馈为 NOT_RECEIVED，未进行硬件下载；正式数据库和硬件状态均未修改。
"@
[IO.File]::WriteAllText((Join-Path $debugRoot 'README.md'),$readme,$utf8)
$event=@{
    event_id='EV-BOARD-HANDOFF-'+$RunId;project_id='FPGA_EDGE_TI60';session_id='FAST-BATCH-20261008';at_utc=$at
    operation_id='PREPARE-DEBUG-'+$ArtifactId;built_run=$RunId;artifact_id=$ArtifactId
    node_id='INITIAL_BOARD_WITH_PARTIAL_A6';previous_goal_turn_classification='PROGRESS'
    debug_handoff_record=$debugRelative+'/handoff.json';debug_handoff_project=$debugRelative+'/track4_board.xml'
    source_entries=$sources.Count;validated_input_count=$inputs.Count;postcompile_xml_sha256=$postXmlHash;bit_sha256=$bitHash
    synthesis_passed=$true;pnr_passed=$true;timing_passed=$true;hardware_gate='WAITING_HUMAN_PROGRAM'
    hardware_programming_performed=$false;hardware_effects_verified=$false;hardware_feedback_status='NOT_RECEIVED'
    local_audit_exception=$true;formal_database_or_hardware_state_changed=$false
    original_full_complex_recognition_complete=$false;full_project_goal_complete=$false
}
[IO.File]::AppendAllText((Join-Path $controlRoot 'Runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl'),
    ($event|ConvertTo-Json -Compress -Depth 8)+[Environment]::NewLine,$utf8)
$statusPath=Join-Path $taskRoot 'integration-status.json'
$status=Get-Content -LiteralPath $statusPath -Raw|ConvertFrom-Json
$updates=@{
    debug_handoff_project=$event.debug_handoff_project;debug_handoff_record=$event.debug_handoff_record
    debug_handoff_sources=$sources.Count;debug_handoff_run=$RunId;debug_handoff_ready=$true;debug_handoff_completed_at_utc=$at
    completed_phase='SOFTWARE_BUILD_AND_DEBUG_HANDOFF_COMPLETE'
    hardware_gate='WAITING_HUMAN_PROGRAM';hardware_feedback_status='NOT_RECEIVED';updated_at_utc=$at
}
foreach($key in $updates.Keys){$status|Add-Member -MemberType NoteProperty -Name $key -Value $updates[$key] -Force}
if($status.current_run-eq$RunId){
    $status|Add-Member -MemberType NoteProperty -Name current_build_phase -Value 'SOFTWARE_BUILD_AND_DEBUG_HANDOFF_COMPLETE' -Force
}
SaveJson $statusPath $status
Write-Output ('Prepared '+$debugName+'; '+$sources.Count+' sources; 205 inputs verified; hardware feedback NOT_RECEIVED')
