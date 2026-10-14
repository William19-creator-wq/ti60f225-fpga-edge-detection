"""CP01..04：仅通过且源绑定的组件形成新检查点；PNG来自真实仿真数据。"""
import datetime, hashlib, json, pathlib
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path('D:/大三/FPGA_verilog/_fpga_edge_agent')
WORK = ROOT / 'work/active/track4_algorithms_20261004'
OUT = ROOT / 'experiments/track4_algorithms_20261004/05_delivery'
CAPTURE = WORK / 'capture_canny_axi'
READER = WORK / 'rgb_frame_reader'
CAP_ID = 'CAPTURE-CANNY-AXI-COMPONENT-20261009-v1.1'
READER_ID = 'RGB-FRAME-READER-COMPONENT-20261009-v1'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def fresh(path):
    assert path.resolve().is_relative_to(ROOT.resolve())
    assert not path.exists(), ('Preserve old output', str(path))
    return path

def write_json(path, value):
    fresh(path).write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    assert read(path) == value

def audited(unit, name):
    run = unit / 'runs' / name
    suite = read(run / 'suite-result.json')
    assert suite['status'] == 'PASS' and suite['finished']
    audit = read(run / 'reference-audit.json')
    assert audit['status'] == 'PASS'
    assert read(run / 'protocol-metrics.json')['finished']
    for entry in read(run / 'source-manifest.json'):
        assert sha(pathlib.Path(entry['path'])) == entry['sha256'].upper()
    return audit

def main():
    checkpoint = fresh(OUT / 'fast-batch-checkpoint-20261009-v4.json')
    report = fresh(OUT / 'CONTINUATION_20261009_READBACK_CANNY.md')
    hd = audited(CAPTURE, 'capture_hd_001')
    small = audited(CAPTURE, 'capture_small_010')
    narrow = audited(CAPTURE, 'capture_narrow_001')
    assert hd['full1080p'] and hd['pixels_compared'] == 2073600
    assert narrow['metrics']['held_fp_failure_witness'] > 0
    assert narrow['metrics']['failed_fp_discards'] > 0
    audited(READER, 'reader_hd_001')
    assert read(CAPTURE / 'runs/capture_map_001/Map.result.json')['exit_code'] == 0
    assert read(READER / 'runs/reader_map_001/Map.result.json')['exit_code'] == 0
    old2_path = OUT / 'fast-batch-checkpoint-20261008-v2.json'
    old3_path = OUT / 'fast-batch-checkpoint-20261009-v3.json'
    old2, old3 = read(old2_path), read(old3_path)
    for entry in old2['new_files_checked'] + old3['new_files_checked']:
        assert sha(pathlib.Path(entry['path'])) == entry['sha256'].upper()
    artifacts = [v['artifact'] for v in old3['registered_components']] + [READER_ID, CAP_ID]
    registered = []
    for name in artifacts:
        folder = ROOT / 'artifacts/staging' / name
        manifest_path = folder / 'artifact-manifest.json'
        manifest = read(manifest_path)
        for entry in manifest['files']:
            assert sha(folder / entry['relative']) == entry['sha256'].upper()
        prior = next((v for v in old3['registered_components'] if v['artifact'] == name), None)
        if prior:
            assert sha(manifest_path) == prior['manifest_sha256'].upper()
        registered.append(dict(artifact=name, files_checked=len(manifest['files']), manifest_sha256=sha(manifest_path)))
    new_files = []
    for unit, artifact in ((READER, READER_ID), (CAPTURE, CAP_ID)):
        own = []
        for category in ('rtl', 'tb', 'model', 'scripts', 'project'):
            own += [p for p in (unit / category).iterdir() if p.is_file() and p.suffix in ('.sv', '.py', '.ps1', '.xml', '.sdc')]
        assert len(own) == 7
        for path in sorted(own):
            relative = path.relative_to(unit).as_posix()
            frozen = ROOT / 'artifacts/staging' / artifact / 'source' / relative
            assert sha(path) == sha(frozen)
            new_files.append(dict(path=str(path), sha256=sha(path), artifact=artifact, relative=relative))
    assert len(new_files) == 14 and old3['total_business_and_validation_files'] == 140
    cap_manifest = read(ROOT / 'artifacts/staging' / CAP_ID / 'artifact-manifest.json')
    assert cap_manifest['resources'] == dict(EFX_RAM10=46, EFX_FF=21976, EFX_LUT4=27109, EFX_ADD=1776, DSP=0, EFX_SRL8=166)

    # 观察图只转换实际数据表示；缩小概览不能替代native逐像素结果。
    run = CAPTURE / 'runs/capture_hd_001'
    source_path, edge_path = run / 'actual-0.source.bin', run / 'actual-0.result.bin'
    source, edges = source_path.read_bytes(), edge_path.read_bytes()
    n = 1920 * 1080
    assert len(source) == 3 * n and len(edges) == n and set(edges) <= {0, 255}
    assert edges.count(255) == read(run / 'vector-summary.json')['cases'][0]['edges'] == 1078
    rgb = Image.frombytes('RGB', (1920, 1080), source)
    edge = Image.frombytes('L', (1920, 1080), edges)
    overlay_data = bytearray(source)
    for index, value in enumerate(edges):
        if value:
            overlay_data[index * 3:index * 3 + 3] = b'\xff\x00\x00'
    overlay = Image.frombytes('RGB', (1920, 1080), bytes(overlay_data))
    pictures = []
    for label, bitmap in (('source', rgb), ('edge', edge), ('overlay', overlay)):
        path = fresh(OUT / f'capture-canny-1080p-actual-{label}-20261009.png')
        bitmap.save(path)
        pictures.append(dict(kind=label, path=str(path), sha256=sha(path), size=list(bitmap.size), native=True))
    font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 26)
    panel = Image.new('RGB', (1920, 500), (15, 23, 42))
    draw = ImageDraw.Draw(panel)
    labels = ('实际RAW插值的RGB源图', '实际同源Canny边缘', '同源观察叠加（软件）')
    for i, (bitmap, label) in enumerate(zip((rgb, edge.convert('RGB'), overlay), labels)):
        draw.text((i * 640 + 24, 18), label, font=font, fill='white')
        panel.paste(bitmap.resize((640, 360), Image.Resampling.NEAREST), (i * 640, 72))
    draw.text((24, 446), '软件仿真 1920×1080：2,073,600像素逐位一致；边缘1,078。概览已缩小，原尺寸图另存。', font=font, fill='white')
    panel_path = fresh(OUT / 'capture-canny-1080p-actual-panel-20261009.png')
    panel.save(panel_path)
    pictures.append(dict(kind='overview', path=str(panel_path), sha256=sha(panel_path), size=list(panel.size), native=False))
    provenance = dict(label='ACTUAL_SOFTWARE_SIMULATION_NOT_HARDWARE', software_run='capture_hd_001',
                      source_path=str(source_path), source_sha256=sha(source_path), edge_path=str(edge_path), edge_sha256=sha(edge_path),
                      overlay_rule='edge255 -> red255,0,0; otherwise preserve sourceRGB', pictures=pictures,
                      rtl_color_overlay_integrated=False, production_ddr_verified=False, hardware_actions=False)
    provenance_path = OUT / 'capture-canny-1080p-actual-20261009.provenance.json'
    write_json(provenance_path, provenance)
    resources = cap_manifest['resources']
    remaining = ['camera I2C/CSI/non-backpressure FIFO/CDC/RX closure',
                 'full memory grant/scope/phase fence and frame-manager/freeze resume',
                 'display prefetch/TMDS/annotation/same-source presentation',
                 'candidate quality and circle/rotated rectangle/occlusion/multiobject recognition',
                 'arithmetic sharing/total resources/process time/production top/pins/clocks/PNR/STA/total bit']
    text = f'''# 2026-10-09 第二批：源读回与完整同源Canny

本批新增reader与capture组合各7份业务/验证文件，累计从140到154；文件数不等于模块数，文档/共享镜像/运行数据/审计脚本不重复计。已沿既有授权自行实施和验证，整项目仍ACTIVE。

reader完整1080p：1,036,800对、97,200真实读取；综合0 RAM、1384 FF、2058 LUT4、26 ADD、0 DSP。

capture组合真实RAW→源写回→实际源读回→完整R2/分类/cache/queue/八邻域连接→结果写回→唯一128bit AXI。34×19和6×109各20图像、34协议；窄图实际held-FP故障witness=1、discard=1。完整1920×1080逐位核对2,073,600像素、源6,220,800字节及分类/最终状态/队列/FP/CS592/Origin；边缘1078、discard0，作业36,811,963拍。源写/读各97,200，全部AW138,846/AR114,544、W555,384/R458,176/B138,846。

实际组合MAP：46 RAM10、21,976 FF、27,109 LUT4、1,776 ADD、166 SRL8、0 DSP。100MHz是组件目标约束；此数字不替代生产PNR/STA/帧率证据。三个当前源绑定的仿真PASS和MAP快照一致；失败attempt仍在work/runs保留，修订原因在设计卡J1…J8。

两个新增不可覆盖包：{READER_ID}、{CAP_ID}。本次校验10份组件Manifest共{sum(v['files_checked'] for v in registered)}条文件、旧70份工作文件加新14份，hash漂移0。初始70份功能文件沿此前登记证据，本轮不虚构重新逐文件检查全部154份。

阅读顺序：planning/design-TRACK4-CAPTURE-CANNY-AXI-001.md → work/active/track4_algorithms_20261004/capture_canny_axi/docs/README.md → 父端口/范围检查/子实例 → 父状态/源取消适配 → reader字节组合 → Canny实际共享服务 → runs独立审计/实际MAP → staging冻结副本。Efinity可打开capture_canny_axi/project/capture_canny_axi_component.xml；内部端口须接最终生产top，不直接成为板卡引脚。

![同源软件仿真概览]({panel_path.as_posix()})

图来自实际通过软件仿真的源/结果；旁边三份native PNG保留1920×1080。红色观察叠加为软件显示，尚不称RTL彩色叠加已经整合。来源SHA/图SHA由provenance.json记录。

后续五类：摄像头实际I2C/CSI及不可反压FIFO/CDC；完整存储授权/真实fence/FM冻结恢复；显示预取/TMDS/标注；复杂识别/负样本质量/候选；算术复用、总资源与时间、单一生产top/引脚/时钟/PNR/STA/总bit。DDR匹配2Gb/x16模型/PHY/校准/读后可见性缺口仍在，仅对应物理动态证据受影响，其他编码继续推进。STATS独立包资源和最重HY时钟风险仍需实改优化，不能把各独立包相加宣称整机装得下。

约束保持Ti60F225/I3、SC431HAI、1080p、板卡现有资源、DDR允许；不改变原识别要求。中文设计先读回，持续自主实施与本地审计继续。原HDK/冻结包/正式DB/state/hardware不改，总bit后停止硬件步骤。理解验收待实际作答，软件通过不冒充硬件通过。
'''
    report.write_text(text, encoding='utf-8')
    result = dict(schema_version='1.3', task_id='TRACK4-FULL-SW-001', at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  status='PROGRESS_FULL_GOAL_ACTIVE', classification='progress', full_project_goal_complete=False,
                  user_autonomous_instruction='当你统計完后自行进行, 无需我的批准', earlier_business_files=140, new_files=14,
                  total_business_and_validation_files=154, new_unit_counts=dict(rgb_frame_reader=7, capture_canny_axi=7),
                  new_files_checked=new_files, old_work_files_checked=70, new_source_drift=0,
                  previous_checkpoint_sha256=sha(old3_path), registered_components=registered, registered_hash_drift=0,
                  registered_files_checked=sum(v['files_checked'] for v in registered), live_tool_sessions=[],
                  capture_hd=hd, capture_small=small, capture_narrow=narrow, capture_resources=resources,
                  production_ddr_verified=False, production_csi_verified=False, frame_publish_verified=False,
                  production_pnr_sta_total_bit_verified=False, hardware_actions=False, formal_state_changed=False,
                  remaining=remaining, next='继续实际camera/CDC与帧管理/显示软件；另推进算术复用，不重复索取已授权批准',
                  delivery=str(report), delivery_sha256=sha(report), visualization=str(panel_path), visualization_sha256=sha(panel_path),
                  provenance=str(provenance_path), provenance_sha256=sha(provenance_path), checkpoint_tool_sha256=sha(pathlib.Path(__file__)))
    write_json(checkpoint, result)
    event = dict(event_id='EV-FAST-BATCH-20261008-022', at_utc=result['at_utc'], status=result['status'], classification='progress',
                 checkpoint=str(checkpoint), checkpoint_sha256=sha(checkpoint), business_files=154, new_files=14,
                 registered_files_checked=result['registered_files_checked'], registered_hash_drift=0,
                 full_project_goal_complete=False, hardware_actions=False, formal_state_changed=False)
    journals = [ROOT / 'runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl',
                ROOT / 'experiments/track4_algorithms_20261004/03_review/side-effects.jsonl']
    for path in journals:
        assert event['event_id'] not in path.read_text(encoding='utf-8-sig')
    for path in journals:
        with path.open('a', encoding='utf-8') as handle:
            handle.write(json.dumps(event, ensure_ascii=False) + '\n')
    for entry in pictures:
        assert sha(pathlib.Path(entry['path'])) == entry['sha256']
    print(json.dumps(event, ensure_ascii=False))

if __name__ == '__main__':
    main()
