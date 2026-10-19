from pathlib import Path
import datetime,hashlib,json,shutil
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
OLD=ROOT/'work/active/track4_v7_rawcard_001_20261017';OR=ROOT/'reports/TRACK4-V7-RAWCARD-001'
R=ROOT/'reports/TRACK4-V7-RAWTAG-001';R.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((OR/'build-inputs.json').read_text(encoding='utf-8'))
for f in b['files']:
    src=OLD/f['relative'];dst=W/f['relative'];assert sha(src)==f['sha256'] and not dst.exists()
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
p=W/'rtl/rawcard_overlay.v';s=p.read_text(encoding='utf-8')
s=s.replace('output reg [15:0] out_raw','output reg [15:0] out_raw,\n    output wire raw_y_odd // 与当前输入RAW字同拍；VS下降沿归零，DE下降沿翻行')
s=s.replace('    reg [23:0] rgb;','    assign raw_y_odd = line_y[0];\n    reg [23:0] rgb;')
p.write_text(s,encoding='utf-8',newline='\r\n')
p=W/'rtl/ti60f225_oob_top.v';s=p.read_text(encoding='utf-8')
s=s.replace('wire [15:0] diagnostic_raw;','wire [15:0] diagnostic_raw;\nwire diagnostic_raw_y_odd;')
s=s.replace('.camera_raw({ch0_b,ch0_g}), .out_raw(diagnostic_raw)','.camera_raw({ch0_b,ch0_g}), .out_raw(diagnostic_raw), .raw_y_odd(diagnostic_raw_y_odd)')
assert s.count('.la0_cal_done       ( cal_done            )')==1
s=s.replace('.la0_cal_done       ( cal_done            )','.la0_cal_done       ( diagnostic_raw_y_odd ) // RAWTAG ONLY: legacy probe name now carries RAW row parity, NOT DDR cal_done')
p.write_text(s,encoding='utf-8',newline='\r\n')
for n in ['run_build.py','run_sim.py','tb_rawcard.sv','check_build.py']:
    s=(OLD/'tests'/n).read_text(encoding='utf-8')
    if n=='run_build.py':s=s.replace('TRACK4-V7-RAWCARD-001','TRACK4-V7-RAWTAG-001')
    if n=='tb_rawcard.sv':
        s=s.replace('wire [15:0] raw;','wire [15:0] raw;wire row_odd;')
        s=s.replace('injector(clk,rst_n,vs,de,camera,raw);','injector(clk,rst_n,vs,de,camera,raw,row_odd);')
        s=s.replace('expected_raw=camera;','if(row_odd !== (row%2 != 0)) $fatal(1,"Row tag mismatch y=%0d tag=%b",row,row_odd);\n                    expected_raw=camera;')
        s=s.replace('RAWCARD_PASS','RAWTAG_PASS')
    if n=='run_sim.py':s=s.replace('RAWCARD_PASS','RAWTAG_PASS')
    if n=='check_build.py':
        s=s.replace('TRACK4-V7-RAWCARD-001','TRACK4-V7-RAWTAG-001').replace('track4_v7_colorcard_001_20261017','track4_v7_rawcard_001_20261017').replace('TRACK4-V7-COLORCARD-001','TRACK4-V7-RAWCARD-001')
        s=s.replace("['rtl/ti60f225_oob_top.v','ti60f225_oob.xml','rtl/rawcard_overlay.v']","['rtl/ti60f225_oob_top.v','rtl/rawcard_overlay.v']")
        s=s.replace('RAWCARD_PASS','RAWTAG_PASS').replace('v7_rawcard_001_v1_20261017.bit','v7_rawtag_001_v1_20261017.bit')
    (W/'tests'/n).write_text(s,encoding='utf-8')
files=[dict(relative=f['relative'],sha256=sha(W/f['relative'])) for f in b['files']]
(R/'build-inputs.json').write_text(json.dumps(dict(files=files,baseline=str(OLD)),indent=2),encoding='utf-8')
shutil.copy2(OR/'authorization.json',R/'authorization.json')
(R/'probe-contract.md').write_text('''# RAW 行标记诊断
基于已上板显示正确人工RAW色卡的RAWCARD副本，仅将已有LA0第四个1位探针改接同拍RAW行奇偶。用户已授权自主测试和临时JTAG，不另行审批。
重要：沿用原debug.json和既有debug核接口，UI/VCD中cal_done现在表示raw_y_odd，不再表示DDR校准。probe0 ch0_g=原相机低字节，probe1 ch0_b=原相机高字节，probe2 ch0_de=有效，probe3 cal_done=行奇偶。采样时钟均vid_clk_dvi2，LA统一一级输入寄存器。
行奇偶与现有rawcard的line_y完全一致：VS下降沿归零，DE下降沿递增。标签仅表明显示RAW流的行坐标，不宣称传感器绝对物理行号。
不修改数据、同步、增益、相位、色卡或原始相机探针。仿真在两个帧起点及825600有效字逐一核对行标记，并继续检查人工RAW到RGB组合输出。
采红色时结合已知行奇偶和高低字节判断红响应位置；随后白纸用于四位置响应/白平衡，不以任意段号代替行号。
''',encoding='utf-8')
obs=dict(event='RAWCARD-HARDWARE-OBSERVED',task='TRACK4-V7-RAWCARD-001',program_completed_at='2026-10-17T21:51:54+08:00',checksum='7BA442CA',mode='JTAG',clock_mhz=6,sha256='d8bfd2a69be60bde6165c15ee22ed648c7460d161f3b561f7c0948a2eb1a6343',observation='两组色卡及灰阶无明显紫偏，人工RAW颜色顺序正常；真实相机仍紫。用户确认红色摆位时实时更新。',limitations='手机照片不是色度测量；不能凭合成人工GBRG证明真实相机的CFA相位。',timestamp=datetime.datetime.now().astimezone().isoformat())
photo=Path('C:/Users/34528/OneDrive/文档/xwechat_files/wxid_a9j2j6wu1ehs22_7ef3/temp/RWTemp/2026-10/616f72525261f89ee311a5bd40e491ce/563bc44052bdddbea6930307579f8c3a.jpg')
obs.update(photo=str(photo),photo_sha256=sha(photo))
(OR/'hardware-observation-rawcard.json').write_text(json.dumps(obs,ensure_ascii=False,indent=2),encoding='utf-8')
for p in [ROOT/'runtime/events/2026/10/session-TRACK4-V7-RAWCARD-001-20261017.jsonl',ROOT/'side_effects/ledger/TRACK4-V7-RAWCARD-001-20261017.jsonl']:
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(obs,ensure_ascii=False)+'\n')
print('Prepared RAWTAG 144 frozen inputs; only two production files changed')
