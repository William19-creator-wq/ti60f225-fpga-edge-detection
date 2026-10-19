from pathlib import Path
import json,hashlib,datetime,shutil
w=Path(__file__).absolute().parents[1];root=Path('C:/Users/34528/FPGAEdgeLinks/Project/_fpga_edge_agent')
task='TRACK4-V7-ALGORITHM-CONTROL-001';r=root/'reports'/task
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=json.loads(read(r/'checks.json'));review=json.loads(read(r/'warning-review.json'))
assert checks['state']=='SOFTWARE_CHECKED' and not review['unreviewed']
assert json.loads(read(sorted(r.glob('build-*-pgm.json'))[-1]))['returncode']==0
for f in json.loads(read(r/'baseline.json'))['files']:assert sha(Path(f['source']))==f['sha256']
inputs=json.loads(read(r/'build-inputs.json'))
for f in inputs['files']:
    p=w/f['relative']
    assert sha(p)==f['sha256'] or (f['relative']=='ti60f225_oob.xml' and hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==f['sha256'])
a=root/'artifacts/staging'/task;a.mkdir(parents=True,exist_ok=True)
bit=a/'v7_algorithm_control_001_v1_20261018.bit';assert not bit.exists()
shutil.copy2(w/'outflow/ti60f225_oob.bit',bit)
result={**checks,'timestamp':datetime.datetime.now().astimezone().isoformat(),'task':task,
 'state':'WAITING_HUMAN_PROGRAM','version':'v1','checkpoint':'mode_and_threshold_controls',
 'bit':dict(path=str(bit),sha256=sha(bit),bytes=bit.stat().st_size),
 'controls':{'KEY0':'reset (preserved v7)','KEY1':'threshold +32','KEY2':'threshold -32','KEY3':'cycle modes'},
 'mode_order':['GRAY','MEDIAN','DIFF X8','SOBEL','OVERLAY','SPLIT','COLOR'],
 'threshold':dict(default=256,minimum=0,maximum=2047,step=32),
 'included':['full-frame gray','full-frame median','same-frame absolute difference x8 saturated','Sobel','red edge overlay','five-region comparison','color','debounced mode/threshold buttons','frame-aligned mode and threshold status'],
 'not_yet_integrated':['freeze','full Canny','shape recognition'],
 'pair_clock_hz':74250000,'fixed_delay_pair_clocks':4402,'fixed_delay_us':4402/74.25,
 'configured_hdmi_width':1920,'configured_hdmi_height':1080,'configured_hdmi_hz':60,
 'camera_fps_this_bit_measured':False,'hardware_programmed':False,'hardware_passed':False,
 'local_audit_exception':True,'formal_state_database_updated':False,'manual_download_preference':True,
 'inputs':[dict(relative=f['relative'],sha256=sha(w/f['relative'])) for f in inputs['files']]}
for p in [a/'manifest.json',r/'delivery.json']:
    assert not p.exists();p.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
doc=r/'按键与同画面对照_交付说明.md'
doc.write_text(f'''# 按键控制与同画面对照

2026-10-18。软件验证及Efinity构建完成，等待人工下载和观察。当前五分区桥接版已由用户确认实时和边缘对齐；本文件是新的按键版，尚未取得它的硬件验收反馈。

## 下载和操作

[下载 bit]({bit.as_posix()})

`{bit}`

SHA256：`{sha(bit)}`

Debugger若已连接先断开。在Programmer用JTAG、Quad RS232-HS、设备1 - 0x10660a79加载本文件，点击下载，看到Programming operation completed后等待画面。默认顶部显示 **GRAY T:0256**。

| 板上丝印 | 动作 |
|---|---|
| KEY0 | 整机复位，保持v7接线 |
| KEY1 | 阈值+32，到2047停止 |
| KEY2 | 阈值−32，到0停止 |
| KEY3 | 按下切一次显示模式，按住不连续切换 |

模式循环：**GRAY → MEDIAN → DIFF X8 → SOBEL → OVERLAY → SPLIT → COLOR → GRAY**。

把镜头固定：初始GRAY是全屏灰度，按一次KEY3是全屏3×3中值，再按一次是DIFF X8。差值图的亮处表示滤波改变过该像素；黑处表示未变或差异很小。差值直接用同帧同坐标灰度与中值相减取绝对值，乘8并饱和到255。它不是轮廓图，也不意味着所有亮点都是噪声。字幕之外保留完整1920×1080原坐标，不缩放。

继续按KEY3到SOBEL，用KEY1/KEY2观察阈值数字及边缘变化；阈值越高，符合条件的边缘不会增多（固定输入条件下）。阈值只影响SOBEL/OVERLAY及SPLIT中的对应区，对灰度、中值、差值无影响。字幕右侧绿方块表示当前位置有匹配算法结果，橙色表示等待，当前像素会回退原图。正常连续运行时应为绿色。

20ms稳定按下才算有效；按住只触发一次，松开后可再按。复位时已经按住的键需要先松开。同拍加减事件抵消，不使用组合键操作。模式与阈值在新帧开始生效，字幕跟随同帧配置。

## 实现与验证

复用原六个前端算法和两份按键模块，新增控制器和小字幕模块，扩展原桥接层差值显示。保留相机、DDR、白平衡、去马赛克、原复位与PLL。新增加三个输入引脚：KEY1=P14/GPIOR_22，KEY2=N14/GPIOR_21，KEY3=A3/GPIOL_03；旧自研版的KEY1复位映射没有照搬。模式和阈值由同一个74.25MHz域锁定，无异步多位配置总线。

- 七模式、字幕、差值、配置帧中变更及故障回退/活动区复位仿真通过。
- 1920×1080连续三帧，6,220,800像素与Python整数参考逐像素一致；3,712,505个同步周期匹配，实际顶层双像素串行化同时检查。三帧对应GRAY、MEDIAN、DIFF X8；其他模式由小图覆盖。
- 消抖N=2/4/31测试启动按住、短抖动、长按、重按、循环、同拍双键、上下饱和和复位通过。生产N=1,485,000，约20ms；实际按键手感待上板。
- 综合/接口/布局布线通过。最小setup {checks['setup_min_ns']}ns、hold {checks['hold_min_ns']}ns；资源XLR {checks['resources']['xlr']}、RAM {checks['resources']['ram']}、DSP {checks['resources']['dsp']}。18组setup和18组hold关系与基线一致；三个按键的两级同步器和约束单独核对。
- 固定桥接延迟4402个双像素时钟，约59.29μs；HDMI配置1080p60。相机真实采集FPS没有在本bit重新测量，不能把显示60Hz当作采集60FPS。

[工程]({(w/'ti60f225_oob.xml').as_posix()}) · [控制器]({(w/'rtl/v7_algorithm_control.sv').as_posix()}) · [桥接与差值]({(w/'rtl/v7_algorithm_video_pair.sv').as_posix()}) · [检查结果]({(r/'checks.json').as_posix()}) · [警告复核]({(r/'warning-review.json').as_posix()})

此前的相机/DDR/JTAG继承警告仍按证据记录；本节点未声称消除所有旧警告或证明所有异步路径。完整Canny、冻结、形状识别仍待后续迁入。本次先验收按键、阈值和同画面对照；下载后请检查各模式实时、无错行/停帧，阈值数字与边缘反应一致。
''',encoding='utf-8')
event=dict(timestamp=result['timestamp'],task=task,event='artifact_registered',state=result['state'],bit=result['bit'],report=str(doc),hardware_programmed=False)
for p in [root/f'runtime/events/2026/10/18/{task}.jsonl',root/f'side_effects/ledger/{task}-20261018.jsonl']:
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(event,ensure_ascii=False)+'\n')
print(json.dumps(event,ensure_ascii=False))
