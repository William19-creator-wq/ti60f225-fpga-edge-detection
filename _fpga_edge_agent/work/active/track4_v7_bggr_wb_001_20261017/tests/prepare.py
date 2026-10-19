from pathlib import Path
import hashlib,json,shutil,datetime
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
OLD=ROOT/'work/active/track4_v7_rawtag_001_20261017'
OR=ROOT/'reports/TRACK4-V7-RAWTAG-001';R=ROOT/'reports/TRACK4-V7-BGGR-WB-001'
R.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((OR/'build-inputs.json').read_text(encoding='utf-8'))
for f in b['files']:
    src=OLD/f['relative'];dst=W/f['relative']
    assert sha(src)==f['sha256'] and not dst.exists(),str(src)
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
p=W/'rtl/ti60f225_oob_top.v';s=p.read_text(encoding='utf-8')
s=s.replace('// PH-1/3: P00; 固定实验模式。Debugger的gain/gamma控件在本实验中不控制画面。','// 实测RAW行标记支持BGGR，采用P11；Debugger gain/gamma控件不控制画面。')
s=s.replace("localparam BAYER_Y_PHASE_XOR = 1'b0;","localparam BAYER_Y_PHASE_XOR = 1'b1;").replace("localparam BAYER_RB_SWAP = 1'b0;","localparam BAYER_RB_SWAP = 1'b1;")
s=s.replace('// 人工RAW只覆盖中部色卡；相机其余数据及原同步逐位保留。','// 相机RAW先扣黑电平并白平衡，随后注入已知BGGR色卡；同步及拍数保持。')
s=s.replace('wire diagnostic_raw_y_odd;','''wire diagnostic_raw_y_odd;
wire [15:0] balanced_camera_raw;
raw_bggr_balance balance_inst (
    .enable(vid_rst_n && ch0_de), .row_odd(diagnostic_raw_y_odd),
    .raw_in({ch0_b,ch0_g}), .raw_out(balanced_camera_raw)
);''')
s=s.replace('.camera_raw({ch0_b,ch0_g}), .out_raw(diagnostic_raw)', '.camera_raw(balanced_camera_raw), .out_raw(diagnostic_raw)')
p.write_text(s,encoding='utf-8',newline='\r\n')
p=W/'rtl/rawcard_overlay.v';s=p.read_text(encoding='utf-8')
s=s.replace('已知GBRG样本，适配P00','已知BGGR样本，适配P11')
s=s.replace('{rgb[15:8],rgb[23:16]}; // 奇数行：低R、高G','{rgb[23:16],rgb[15:8]}; // 奇数行：低G、高R')
s=s.replace('{rgb[7:0],rgb[15:8]};   // 偶数行：低G、高B','{rgb[15:8],rgb[7:0]};   // 偶数行：低B、高G')
p.write_text(s,encoding='utf-8',newline='\r\n')
p=W/'ti60f225_oob.xml';s=p.read_text(encoding='utf-8')
anchor='        <efx:design_file name="rtl/rawcard_overlay.v" version="default" library="default" />'
assert s.count(anchor)==1
s=s.replace(anchor,anchor+'\n        <efx:design_file name="rtl/raw_bggr_balance.v" version="default" library="default" />')
p.write_text(s,encoding='utf-8',newline='\n')
for n in ['run_build.py','run_sim.py','check_build.py','tb_rawcard.sv']:
    s=(OLD/'tests'/n).read_text(encoding='utf-8')
    s=s.replace('TRACK4-V7-RAWTAG-001','TRACK4-V7-BGGR-WB-001').replace('RAWTAG_PASS','BGGR_WB_PASS')
    if n=='run_sim.py':s=s.replace("W/'rtl/rawcard_overlay.v'","W/'rtl/rawcard_overlay.v',W/'rtl/raw_bggr_balance.v'")
    if n=='check_build.py':
        s=s.replace('track4_v7_rawcard_001_20261017','track4_v7_rawtag_001_20261017').replace('TRACK4-V7-RAWCARD-001','TRACK4-V7-RAWTAG-001')
        s=s.replace("['rtl/ti60f225_oob_top.v','rtl/rawcard_overlay.v']","['rtl/ti60f225_oob_top.v','rtl/rawcard_overlay.v','rtl/raw_bggr_balance.v','ti60f225_oob.xml']")
        s=s.replace('v7_rawtag_001_v1_20261017.bit','v7_bggr_wb_001_v1_20261017.bit')
    (W/'tests'/n).write_text(s,encoding='utf-8')
auth=dict(user_instruction='无需我的批准, 也不用再写草图, 你按照你的見解写代码測試即可',hardware_authorization='你来操作电脑进行下载和烧录',sampling_preference='我想自己操作采样',scope='Independent BGGR/P11 + measured black level and manual white balance correction; simulation/build/register',local_audit_exception='continued; formal database/state untouched')
(R/'authorization.json').write_text(json.dumps(auth,ensure_ascii=False,indent=2),encoding='utf-8')
print('Copied verified RAWTAG baseline; freeze new inputs after RTL/test preparation')
