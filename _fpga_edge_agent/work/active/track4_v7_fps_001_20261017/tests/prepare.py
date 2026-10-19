from pathlib import Path
import datetime, hashlib, json, shutil
W=Path(__file__).resolve().parents[1]; ROOT=W.parents[2]
OLD=ROOT/'work/active/track4_v7_bggr_wb_001_20261017'
R=ROOT/'reports/TRACK4-V7-FPS-001'; R.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
baseline=json.loads(read(ROOT/'reports/TRACK4-V7-BGGR-WB-001/build-inputs.json'))
actual=[]
for f in baseline['files']:
    src=OLD/f['relative']; dst=W/f['relative']
    if sha(src)!=f['sha256']:
        assert f['relative']=='ti60f225_oob.xml'
        assert hashlib.sha256(src.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256']
    assert not dst.exists(),str(dst)
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    actual.append(dict(relative=f['relative'],sha256=sha(src)))
# Scope of acceptance is camera picture/color only, never full algorithm acceptance.
B=ROOT/'artifacts/validated/TRACK4-V7-COLOR-BASELINE-20261017'
B.mkdir(parents=True,exist_ok=False)
src=ROOT/'artifacts/staging/TRACK4-V7-BGGR-WB-001/v7_bggr_wb_001_v1_20261017.bit'
assert sha(src)=='31a95ca1e325c8ff5da12e36a65bd6456517ce9643b6ff12501dfaf0f3045bfd'
shutil.copy2(src,B/src.name)
for p in actual:
    dest=B/'source'/p['relative'];dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(OLD/p['relative'],dest)
record=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),
    accepted_scope='User-confirmed live camera picture and acceptable colors; slight blue white remains',
    user_observation='現在颜色没问题了, 如果非要說, 就是远一点后, 白色有点偏蓝, 但问题不大',
    actual_camera_fps_measured=False,custom_algorithms_accepted=False,
    bit=dict(path=str(B/src.name),sha256=sha(src)),source_files=actual,
    previous_evidence=str(ROOT/'reports/TRACK4-V7-BGGR-WB-001'))
(B/'manifest.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
(R/'baseline.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
p=W/'rtl/ti60f225_oob_top.v';s=read(p)
anchor='wire\tw_mipi_rx_pclk_arstn;'
assert anchor in s
s=s.replace(anchor,anchor+'''
// FPS旁路只观察CSI输入；与输入、逻辑分析仪使用同一50MHz时钟。
wire [15:0] fps_telemetry_word;
wire fps_packet_start, fps_ready;
camera_fps_monitor fps_monitor_inst (
    .clk(i_mipi_rx_pclk), .rst_n(w_mipi_rx_pclk_arstn),
    .vs(w_mipi_rx_vs), .hs(w_mipi_rx_hs), .de(w_mipi_rx_de),
    .telemetry_word(fps_telemetry_word), .packet_start(fps_packet_start),
    .measurement_ready(fps_ready)
);
''')
for a,b in [('( vid_clk_dvi2        ),','( i_mipi_rx_pclk      ),'),('( ch0_g               ),','( fps_telemetry_word[7:0] ),'),('( ch0_b               ),','( fps_telemetry_word[15:8] ),'),('( ch0_de              ),','( fps_packet_start    ),')]:
    # Only replace inside the LA port lines, not the picture path.
    lines=s.splitlines(True)
    hits=[i for i,l in enumerate(lines) if '.la0_' in l and a in l]
    assert len(hits)==1,(a,hits)
    lines[hits[0]]=lines[hits[0]].replace(a,b);s=''.join(lines)
s=s.replace('( diagnostic_raw_y_odd ) // RAWTAG ONLY: legacy probe name now carries RAW row parity, NOT DDR cal_done',
            '( fps_ready ) // FPS ONLY: packet ready flag; NOT DDR cal_done')
p.write_text(s,encoding='utf-8',newline='\r\n')
p=W/'ti60f225_oob.xml';s=read(p)
anchor='        <efx:design_file name="rtl/raw_bggr_balance.v" version="default" library="default" />'
assert s.count(anchor)==1
s=s.replace(anchor,anchor+'\n        <efx:design_file name="rtl/camera_fps_monitor.v" version="default" library="default" />')
p.write_text(s,encoding='utf-8',newline='\n')
for name in ['run_build.py','check_build.py']:
    s=read(OLD/'tests'/name).replace('TRACK4-V7-BGGR-WB-001','TRACK4-V7-FPS-001')
    if name=='check_build.py':
        s=s.replace('track4_v7_rawtag_001_20261017','track4_v7_bggr_wb_001_20261017').replace('TRACK4-V7-RAWTAG-001','TRACK4-V7-BGGR-WB-001')
        s=s.replace("['rtl/ti60f225_oob_top.v','rtl/rawcard_overlay.v','rtl/raw_bggr_balance.v','ti60f225_oob.xml']","['rtl/ti60f225_oob_top.v','rtl/camera_fps_monitor.v','ti60f225_oob.xml']")
        s=s.replace('BGGR_WB_PASS raw_words=825600','FPS_MONITOR_PASS').replace('simulated_raw_words=825600','fps_monitor_simulation=True')
        s=s.replace('v7_bggr_wb_001_v1_20261017.bit','v7_fps_001_v1_20261017.bit')
    (W/'tests'/name).write_text(s,encoding='utf-8')
auth=dict(user_instruction='无需我的批准, 也不用再写草图, 你按照你的見解写代码測試即可',
    current_instruction='保留这份能正常出图的基线，先测真实采集帧率，再逐段接回自研功能',
    download_preference='我自行下载，请给文件路径',local_audit_exception='continued; formal state/database untouched',
    scope='Preserve accepted baseline; independent CSI input FPS/geometry monitor, simulation, build and staging')
(R/'authorization.json').write_text(json.dumps(auth,ensure_ascii=False,indent=2),encoding='utf-8')
for target in [ROOT/'runtime/events/2026/10/session-TRACK4-V7-FPS-001-20261017.jsonl',ROOT/'side_effects/ledger/TRACK4-V7-FPS-001-20261017.jsonl']:
    target.parent.mkdir(parents=True,exist_ok=True)
    with target.open('a',encoding='utf-8') as out:out.write(json.dumps(dict(task='TRACK4-V7-FPS-001',event='baseline_preserved_and_independent_copy_created',timestamp=record['timestamp'],baseline=str(B),authorization=auth),ensure_ascii=False)+'\n')
print('Baseline preserved; FPS independent copy prepared')
