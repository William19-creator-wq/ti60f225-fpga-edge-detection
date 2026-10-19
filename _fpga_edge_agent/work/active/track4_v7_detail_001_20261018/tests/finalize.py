from pathlib import Path
import datetime,json,hashlib
W=Path(__file__).resolve().parents[1];ROOT=W.parents[2];R=ROOT/'reports/TRACK4-V7-DETAIL-001'
A=ROOT/'artifacts/staging/TRACK4-V7-DETAIL-001'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
checks=json.loads(read(R/'checks.json'));manifest=json.loads(read(A/'manifest.json'))
bit=Path(manifest['bit']['path']);assert sha(bit)==manifest['bit']['sha256']
baseline=ROOT/'artifacts/validated/TRACK4-V7-COLOR-BASELINE-20261017'
old=json.loads(read(baseline/'manifest.json'))
assert sha(Path(old['bit']['path']))==old['bit']['sha256']
for f in old['source_files']:assert sha(baseline/'source'/f['relative'])==f['sha256']
assert len(old['source_files'])==145
serializer=json.loads(read(W/'tests/serializer_runs/160837/source.json'))
assert sha(Path(serializer['extracted_from']))==serializer['source_sha256']
assert sha(W/'tests/tb_serializer.sv')==serializer['testbench_sha256']
spatial_sources=json.loads(read(W/'tests/runs/160646/sources.json'))
for f in spatial_sources:assert sha(Path(f['path']))==f['sha256']
result=dict(timestamp=datetime.datetime.now().astimezone().isoformat(),task='TRACK4-V7-DETAIL-001',
    event='build_registered',state='WAITING_HUMAN_PROGRAM',bit=manifest['bit'],
    setup_min_ns=checks['setup_min_ns'],hold_min_ns=checks['hold_min_ns'],resources=checks['resources'],
    frozen_color_baseline_reverified_files=145,hardware_programmed=False,spatial_root_cause_closed=False,
    manual_download_preference=True,local_audit_exception=True,formal_state_database_updated=False)
with (R/'delivery.json').open('x',encoding='utf-8') as f:json.dump(result,f,ensure_ascii=False,indent=2)
md=f'''# 空间细节排查与上板说明 — 2026-10-18

当前状态：新的空间细节诊断 bit 已生成并登记，等待用户手动临时 JTAG 下载。尚未证明“大颗粒、重复像素或锯齿”的实机根因，不能将此版本称为清晰度修复完成。

## 已有证据

- 用户确认 HDMI 输入显示 1920×1080；这只说明输出时序，不能单独证明画面中有同等数量的独立细节。
- 三份 CSI 输入采样各自都记录到 1080 行、每行 1920 像素，帧周期约 78.989 ms，即 12.6600 FPS；帧序号递增。这里测的是输入帧周期，不能把 HDMI 刷新率当作相机帧率，也不能由三份瞬时记录证明长时间零丢帧。
- 新增位置编码、横竖条纹、棋盘格的独立数学参考检查：191,000 个内部像素逐个匹配 BGGR 双线性插值，无像素重复或错序的仿真证据。已确认输出相对于输入标签的对齐为上一行、前两像素；排除图像外边界与启动填充。
- 从当前顶层直接提取的双像素转单像素逻辑，在理想同相 2:1 时钟下输出 5,760 个不同像素，顺序和数量一致。没有覆盖实际芯片时钟偏移、物理 HDMI 信号、显示器缩放。
- RAW10 取高 8 位改变数值精度，不等于空间降采样；当前帧缓冲的 960 是双像素字数，对应 1920 像素。输入计数完整仍不能排除其内容已重复，或者 DDR 后存在内容问题。

## 本版具体变化

基于 FPS 诊断版本建立独立副本，共冻结 147 个输入。仅改变 `rtl/colorcard_overlay.v`、`rtl/rawcard_overlay.v`、新增 `rtl/detail_pattern_gray.v` 和工程 XML 源文件列表。顶层、PLL/引脚/时序约束、摄像头寄存器、DDR、白平衡、去马赛克算法和 FPS 监测均与 FPS 版本相同。

| 屏幕区域 | 内容与用途 | 没有覆盖的部分 |
|---|---|---|
| 上方 A 区，约第 0–191 行 | 直接 RGB 灰度细线，经 HDMI 编码和显示器 | 相机、DDR、去马赛克和双像素串行化 |
| 中间 B 区，RAW 注入第 224–415 行 | 灰度 RAW 细线，经去马赛克、双像素串行化和 HDMI；边缘存在正常流水线偏移 | 相机与 DDR，因为注入点在 DDR 读出和白平衡之后 |
| 下方相机区域 | 保留实时相机内容 | 单凭目测不能定量区分光学、传感器和数据通路 |

每块图案有六列，从左到右的线宽是 **1、2、4、8、16、32 像素**；每列占屏幕宽度的六分之一。每块从上到下分别为竖条纹、横条纹、棋盘格。

**B 区的 1、2 像素细纹可产生伪色或变成近似均匀区域，这是当前双线性 Bayer 重建的理论结果，不能因此判错。** 即使 4 像素以上的边缘也可能有一像素宽的插值伪色。先比较第 3–6 列的整体间距、有无丢条纹，以及是否出现超过参考的块状重复。

数学参考图：[detail_reference.png]({(R/'detail_reference.png').as_posix()})。它不是实机截图，不包含相机、DDR 或显示器效果。原始逐像素图片：[直接 RGB]({(R/'direct_pattern_1920x192.png').as_posix()})、[双线性参考]({(R/'bilinear_reference_1920x192.png').as_posix()})；请按 100% 尺寸查看，缩略图的缩放会改变细纹观感。

## 验证结果

- 图案与旁路检查：825,600 个直接 RGB 像素，412,800 个 RAW 数据字，以及空白期、复位旁路检查通过。
- RAW 图案经实际去马赛克 RTL：363,280 个内部输出像素与独立 BGGR 双线性计算逐像素相符，包含六列/三行内部交界。
- 最终局部仿真通过；继承的 `line_buffer.o_x` 调试输出未连接警告保留，不参与数据路径。早期 testbench 的关键字和端口接线错误日志保留，已修正并重新通过，不是生产 RTL 故障。
- Efinity 综合、接口、布局布线、时序检查和 bit 生成通过；18 组 setup / 18 组 hold 时钟关系与 FPS 基线一致，最小 setup 余量 **{checks['setup_min_ns']} ns**，最小 hold 余量 **{checks['hold_min_ns']} ns**。
- 资源：XLR {checks['resources']['xlr']}，RAM {checks['resources']['ram']}，DSP {checks['resources']['dsp']}。相对于 FPS 基线没有新增未审查的综合或流程警告；既有厂商工程警告并非全部消失。
- 145 个冻结颜色基线输入和原 bit 的 SHA256 再次核对一致。

## 手动下载与回报

1. 保持相机、HDMI、供电连接。若 Debugger 已连接，先断开调试连接。
2. 在 Programmer 选择 JTAG、`Quad RS232-HS`、`1 - 0x10660a79`，选择下方 bit，按蓝色三角下载。无需改成 SPI 或写 Flash。
3. 看到 `Programming operation completed` 后等待约 30 秒。上方和中间应各出现一块细线图，下方应有相机画面。
4. 移动或遮挡镜头确认下方仍实时。主要观察两块图的第 3–6 列，回报“上方清楚/也成块、中间与参考接近/明显更差、相机仍粗糙/改善、实时/停帧”。若拍照，提供全屏和细线区域近照，照片本身可能产生摩尔纹；最终优先按肉眼观察。

下载文件：[v7_detail_001_v1_20261018.bit]({bit.as_posix()})

SHA256：`{manifest['bit']['sha256']}`

如果 A 区已经异常，优先查 HDMI 输出/显示器显示比例；如果 A 正常而 B 与数学参考明显不符，查实际去马赛克到 HDMI 的连接与时序；如果 A、B 都接近参考而相机仍粗糙，再向前查 DDR 内容保真、CSI 像素内容、传感器配置和成像条件。这是下一步定位分支，不是已经确定根因。

## 保存与回退

- 独立源码：[工程 XML]({(W/'ti60f225_oob.xml').as_posix()})。
- 正常颜色回退：[已确认颜色基线 bit]({Path(old['bit']['path']).as_posix()})。
- 本次没有操作 Programmer，没有执行硬件下载，也没有更新正式数据库/状态机或推送 GitHub。沿用本批本地审计例外，动作已写入 runtime events 和 side-effects ledger。
- 原 031/refine 无信号问题尚未完成端到端闭环；本次成功测试不能追认它们正常。继续保留已经实机能出图的 v7 派生基线。
'''
with (R/'空间细节排查与下载说明_20261018.md').open('x',encoding='utf-8') as f:f.write(md)
for p in [ROOT/'runtime/events/2026/10/18/TRACK4-V7-DETAIL-001.jsonl',ROOT/'side_effects/ledger/TRACK4-V7-DETAIL-001-20261018.jsonl']:
    with p.open('a',encoding='utf-8') as f:f.write(json.dumps(result,ensure_ascii=False)+'\n')
print(json.dumps(result,ensure_ascii=True,indent=2))
