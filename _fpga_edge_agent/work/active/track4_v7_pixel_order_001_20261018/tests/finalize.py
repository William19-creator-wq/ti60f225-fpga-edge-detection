from pathlib import Path
import datetime,json,hashlib,re
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2]
R=ROOT/'reports/TRACK4-V7-PIXEL-ORDER-001';A=ROOT/'artifacts/staging/TRACK4-V7-PIXEL-ORDER-001'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=json.loads(read(R/'checks.json'));manifest=json.loads(read(A/'manifest.json'))
bit=Path(manifest['bit']['path']);assert sha(bit)==manifest['bit']['sha256']
baseline=ROOT/'artifacts/validated/TRACK4-V7-COLOR-BASELINE-20261017'
frozen=json.loads(read(baseline/'manifest.json'))
assert sha(Path(frozen['bit']['path']))==frozen['bit']['sha256']
for f in frozen['source_files']:assert sha(baseline/'source'/f['relative'])==f['sha256']
assert len(frozen['source_files'])==145
origin_inputs=json.loads(read(ROOT/'reports/TRACK4-V7-REBUILD-001/inputs.json'))
origin=Path(origin_inputs['source']);origin_by_path={f['relative']:f for f in origin_inputs['files']}
origin_evidence=[]
for relative in ['rtl/ti60f225_oob_top.v','rtl/frame_buffer_V4/ser2par_v1.v','rtl/frame_buffer_V4/vid_par2ser.v','rtl/frame_buffer_V4/ddr_wr_buffer.v','rtl/frame_buffer_V4/ddr_rd_buffer.v']:
    p=origin/relative;assert sha(p)==origin_by_path[relative]['sha256']
    if relative.endswith('ti60f225_oob_top.v'):
        expr=lambda q:re.findall(r'/\*i\*/\.vin\s*\((\{[^}]+\})\s*\)',read(q))
        assert expr(p)==expr(W.parent/'track4_v7_detail_001_20261018'/relative)
    else:assert sha(p)==sha(W/relative)
    origin_evidence.append(dict(path=str(p),sha256=sha(p),relationship='original vin unchanged in DETAIL' if relative.endswith('ti60f225_oob_top.v') else 'byte-identical to current source'))
with (R/'official-v7-origin.json').open('x',encoding='utf-8') as f:json.dump(origin_evidence,f,indent=2)
# Record exact active implementation evidence. The similarly named *_v1
# writer is present in the file list but is NOT instantiated by ddr_buffer.
chain=[]
for relative,needle,meaning in [
 ('rtl/ti60f225_oob_top.v','.vin','Only changed production connection: RAW10 quartet -> input 32-bit word'),
 ('rtl/frame_buffer_V4/frame_info_det.v','o_data  <= i_data','Input register preserves bits'),
 ('rtl/frame_buffer_V4/vid_rx_align_v1.v','ser2par_v1 #','Active 32-to-128 packer instance'),
 ('rtl/frame_buffer_V4/ser2par_v1.v','par_pix_data <= {','Earlier 32-bit words move toward MSB'),
 ('rtl/frame_buffer_V4/ddr_buffer.v','ddr_wr_buffer1 #','Active writer is ddr_wr_buffer1 from ddr_wr_buffer.v'),
 ('rtl/frame_buffer_V4/ddr_wr_buffer.v','assign wdata','128-bit write payload passes without byte reorder'),
 ('rtl/frame_buffer_V4/ddr_rd_buffer.v','ddr_rd_data <= rdata','128-bit read payload passes without byte reorder'),
 ('rtl/frame_buffer_V4/vid_par2ser.v','assign tx_fifo_wrdata','Active 128-to-16 unpacker emits MSB halfword first'),
 ('rtl/frame_buffer_V4/user_cvo_axi_v1/cvo_axi_v1.v','assign vout','Two-pixel output preserves word bits')]:
    p=W/relative
    matches=[dict(line=i,text=t.strip()) for i,t in enumerate(read(p).splitlines(),1) if needle in t]
    assert matches,(relative,needle)
    chain.append(dict(path=str(p),sha256=sha(p),meaning=meaning,matches=matches))
with (R/'data-path-evidence.json').open('x',encoding='utf-8') as f:json.dump(chain,f,indent=2)
result=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task='TRACK4-V7-PIXEL-ORDER-001',
    event='build_registered',state='WAITING_HUMAN_PROGRAM',bit=manifest['bit'],
    setup_min_ns=checks['setup_min_ns'],hold_min_ns=checks['hold_min_ns'],resources=checks['resources'],
    frozen_color_baseline_reverified_files=145,hardware_programmed=False,
    software_pixel_order_defect_reproduced=True,hardware_spatial_root_cause_closed=False,
    manual_download_preference=True,local_audit_exception=True,formal_state_database_updated=False)
with (R/'delivery.json').open('x',encoding='utf-8') as f:json.dump(result,f,ensure_ascii=False,indent=2)
md=f'''# 相机像素顺序修正与实机对照 — 2026-10-18

状态：已在实际打包/拆包 RTL 的局部仿真中复现每四像素内部的成对错序；最小修正通过仿真、综合、布局布线和时序检查，已生成 bit，等待用户手动 JTAG 下载。尚未确认这是实机所有颗粒感/锯齿的根因，也未宣告图像质量验收通过。

## 本次人眼观察如何解释

用户确认 DETAIL-001 中间第 3–6 列条纹完整，主要是边缘发软或有细彩边；下方相机仍实时变化。该表现与既有双线性 Bayer 参考定性相符，并不能要求中间 RAW 插值图与上方直接 RGB 图完全一样。参考测试不覆盖相机和 DDR，因为两块图的注入点均在本次发现的错序之后。

## 找到的代码问题

Efinix 官方 [MIPI CSI-2 RX Controller User Guide，表 19，第 14 页](https://www.efinixinc.com/docs/mipi-csi2-rx-core-ug-v3.2.pdf#page=14) 规定 RAW10 四像素由低位向高位排列：首像素 `[9:0]`，然后 `[19:10]`、`[29:20]`、`[39:30]`。工程启用 Pack_40；以下以 P0–P3 表示这四个像素的高 8 位。

| 环节 | 原连接 | 修正连接 |
|---|---|---|
| 输入 32 位字，从高位到低位 | P3、P2、P1、P0 | P1、P0、P3、P2 |
| 32→128 打包 | 早到的 32 位字位于高位 | 相同 |
| 128→16 拆包 | 高 16 位先输出 | 相同 |
| 下游每拍两个像素 | 低字节为先像素 | 相同 |
| 实际输出空间顺序 | **P2、P3、P0、P1** | **P0、P1、P2、P3** |

错序在每四像素中将两对像素交换，保留了像素数量、行长度及 Bayer 奇偶关系。因此它可以与“计数为 1920×1080、颜色大体正确”同时存在，并可能使细节错位。其对当前实机颗粒感的贡献需下载对照；单凭计数不能排除这类内容错误。

实际例化链已核查：frame_buffer → vid_rx_align_v1 / ser2par_v1 → ddr_buffer / **ddr_wr_buffer1（文件 ddr_wr_buffer.v）** / ddr_rd_buffer → vid_par2ser → cvo_axi_v1。写读数据均保留整个 128 位字，未发现额外字节重排。详细行号与哈希见 [data-path-evidence.json]({(R/'data-path-evidence.json').as_posix()})。没有将未使用的另一套 par2ser 或同名近似模块当作实际路径。

还对照了本机资料包的原始 v7：上述顶层输入拼接相同，相关四份打包/拆包和 DDR 读写 RTL 与当前副本逐字节一致，且原文件哈希符合此前重建时的输入登记。它是 v7 派生链继承的连接，不是本次细线图新增的行为。原始资料保持只读，证据见 [official-v7-origin.json]({(R/'official-v7-origin.json').as_posix()})。此处核对针对像素顺序，不代表原 031/refine 无信号原因已经闭环。

## 修改与验证

- 在 DETAIL-001 的独立副本中冻结 147 项输入快照；唯一生产文件差异为顶层 `rtl/ti60f225_oob_top.v` 的 `.vin` 拼接及说明注释。其他输入哈希一致，详见 [production.diff]({(R/'production.diff').as_posix()})。
- 从原版和修正版顶层提取实际 `.vin` 表达式，与实际 `ser2par_v1`、`vid_par2ser` 运行对照。每个版本分别检查 11,520 个像素值，覆盖连续输入、输入气泡、输入气泡加输出 almost-full 暂停。原版稳定复现索引 XOR 2；修正版逐像素匹配原空间顺序，数量和读写拍数正确。
- 仿真用透明 128 位队列模拟存储，不是完整 DDR 控制器/PHY 仿真，不代替硬件验证。保留厂商未使用参数 `I_VID_DIV` 在整除位宽下的常量除零警告，两实例各一次；参数无使用处，实际分支不依赖它。
- 先前去马赛克/测试图验证所涉及 RTL 哈希未变，沿用已通过的局部结果。未重新宣称完整相机链路或自研 031/refine 正常。
- 综合、接口、布局布线、bit 生成成功。18 组 setup 和 18 组 hold 时钟关系与 DETAIL 基线一致；最小 setup **{checks['setup_min_ns']} ns**、hold **{checks['hold_min_ns']} ns**。资源：XLR **{checks['resources']['xlr']}**，RAM **{checks['resources']['ram']}**，DSP **{checks['resources']['dsp']}**。
- 综合/流程警告增量已审查，无新增未审查警告。第一次综合前端被启动环境 `PYTHONUTF8=1` 导致的本机编码解码异常中断，后台综合子进程仍继续写文件，使随后的重试出现双份报告（警告日志 2780 行，对照基线 1390 行）。这两轮产物均未交付：日志保留于 failed-map-01，混合输出和工作目录整体归档于 build_attempts/mixed_first_run；确认综合/布局布线进程均已结束后，在新建的空输出目录完整重跑。最终验收只使用第三轮 map、第二轮 interface/pnr 及之后生成的 bit。未修改厂商工具或生产源码来规避检查。
- 145 项已接受颜色基线及其 bit 重新核对哈希一致。本次不改变传感器配置、曝光、白平衡、去马赛克算法、时钟或引脚。之前三份采集记录约 12.66 FPS 是旧版实测；本版未再次实测帧率。

## 手动下载与观察

文件：[v7_pixel_order_001_v1_20261018.bit]({bit.as_posix()})

SHA256：`{manifest['bit']['sha256']}`

1. Debugger 如仍连接，先断开；Programmer 选 JTAG、Quad RS232-HS、设备 `1 - 0x10660a79`，加载本 bit 并下载。无需写 Flash。
2. 显示 `Programming operation completed` 后等约 30 秒，移动或遮挡镜头确认下方仍实时。
3. 保持同一照明、距离和焦点，对准印刷文字、斜线或物体边缘，重点比较**下方真实相机画面**的颗粒、锯齿和小文字。上下两块测试图预计保持原样；它们绕过此修正点，中间仍可能比上方软。
4. 回报实际相机区域是明显改善、变化不大还是变差，以及颜色与实时性是否正常。没有实机改善时，继续排查相机 RAW 内容、光学/对焦、传感器采样方式及插值性能，不把本次软件修正当作全部问题结案。

工程：[ti60f225_oob.xml]({(W/'ti60f225_oob.xml').as_posix()})。
正常颜色回退：[已接受基线 bit]({Path(frozen['bit']['path']).as_posix()})。

本次未操作 Programmer、未执行硬件下载、未推送 GitHub；继续采用用户已经授权的独立副本修改/编译及本地审计例外。正式状态机和数据库未更新，事件及交付写入本地 runtime events 和 side-effects ledger。
'''
with (R/'像素顺序问题与下载说明_20261018.md').open('x',encoding='utf-8') as f:f.write(md)
for p in [ROOT/'runtime/events/2026/10/18/TRACK4-V7-PIXEL-ORDER-001.jsonl',ROOT/'side_effects/ledger/TRACK4-V7-PIXEL-ORDER-001-20261018.jsonl']:
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(result,ensure_ascii=False)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
