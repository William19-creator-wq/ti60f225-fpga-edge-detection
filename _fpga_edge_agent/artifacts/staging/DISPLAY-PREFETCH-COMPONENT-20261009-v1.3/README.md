# 显示行预取：先读设计，再读代码与运行证据

本包把 owner 的 RGB/EDGE/ANN 布局变成真正的标准 AXI 读取，再写入原生三行 RAM。当前达到独立软件动态验证与 Ti60F225/I3 MAP；尚未接真实 DDR/PHY、生产扫描调度或 TMDS，也未完成本包板级布局布线、时序与比特流。

阅读次序：整体与局部设计 `_fpga_edge_agent/planning/design-TRACK4-DISPLAY-PREFETCH-001.md` → J1 至 J4 → `baseline-v1.3.json` 的14份冻结输入 → `rtl` 四个模块 → `tb` 实际字节从端和整体测试台 → `model` 独立参考 → `scripts` → `project` → `runs`。

## 整体与交接草图

```text
完整owner OFFER942 + row ticket543 + 父真实RO许可
 → reader锁包/逐字段检查 → 既有rows3实际fill/ACK → 父消费ACK
 → span AXI AR/R → metadata原始字节1KB / RGB carry32B
 → EDGE两个/ANN两个word cache → {ann4,edge2,rgb48}
 → 真实WR、地址/代次核对 → 真正IO和producer关闭
 → success实际publish / 安全失败实际abort+return / 未知隔离
 → 视频原子行票据 → 原生RAM read → release → 独立core return
```

外部成功终态表示行已发布，父还必须处理视频借用及正常归还。安全取消只回收未发布的行；未知响应保留行和借用，drained=0。共同复位资格由平台证明，本测试台清空受控模型不能替真实 DDR 证明。

## 局部代码观察顺序

|模块|先观察的语句/状态|接到下一模块时的关键条件|
|---|---|---|
|`display_span_axi.sv`|IDLE→PLAN→AR→R→AFTER_BURST，req_end33、burst≤64、4KiB、128bit holding|实际RID/RESP/LAST检查和holding消费完成后才给安全done；Q不因迟到尾拍改安全|
|`display_meta_ram.sv`|native16×512、同步RE、OUTPUT_REG=0|全部metadata WE完毕才开始RE，先保留cache RESERVED，再捕获真实pending输出|
|`display_row_reader.sv`|CHECK/CFG_REPLY→EDGE→ANN→RGB_RUN，32B旧carry先消费再附加新beat|每个pair保留完整坐标/gen；prepared−delivered≤1，停顿/取消不撤旧out valid|
|`display_prefetch_rows.sv`|HEADER/ROW_FILL/ROW_ACK/USER_ACK→RUN→publish或abort/return|不自己伪造io_closed；内部abort的真实return消费后才row_returned=1，正常已发布return继续对外|

参数：生产默认 W=1920/H=1080，core100MHz/video pair约74.25MHz，AXI128bit/READ_ID=2，ADDRESS_BYTES=256MiB。合法边界测试W4/6/10/20，均保持偶数几何。RGB低地址为R/G/B，输出pair低lane为{R0,G0,B0}；EDGE1bit/pixel，ANN2bit/pixel，ANN map从descriptor+4224开始。mode0上下半屏SRC/EDGE、1/2 SRC、3 EDGE、4 SRC+EDGE、5全部，缺平面输出0。

## 软件运行操作草图

1. 在 PowerShell 调用 `scripts/run_prefetch_sim.ps1 -RunId 新编号`。默认20×8；`-HD` 为1920×1080/1080条基础行，`-Minimum` 为4×2，`-Width 6` 或10验证非8倍宽度。RunId已存在时拒绝覆盖。
2. 脚本核14份输入哈希，绑定15份模拟源，执行vlib/vlog/vopt、预期fatal非零探针、实际仿真、独立Python参考。检查 `suite-result.json` 与 `reference-result.json`，保留每stage的PID/参数/退出码/开始结束和stdout/stderr。
3. 按事件先看job全票据/ACK，再看真正AR/R，接着WR/publish或abort/abort_return，最后视频read与完整ticket return。不要把“提出LAST/取消/末行”代替真实握手闭合。
4. 综合入口 `run_prefetch_map.ps1 -RunId 新编号 -SimulationRun 已通过编号`，生成独立snapshot及实际MAP日志。Efinity可打开 `project/display_prefetch_component.xml`，器件为Ti60F225/I3。该工程是组件综合工程，接口尚未绑定板级引脚，当前只跑MAP；最终生产top会提供实际引脚和时钟/CDC约束。

## 已跑结果及人工阅读检查

最新合格尝试：prefetch_hd_003/min_003/w6_002/w10_001/small_004。共1409场景、1274成功行、90拒绝、25安全失败/取消、20隔离；实际6599 AR、311688 R、1048473 WR、1047320正确54bit视频响应。HD组含1080基础行及10附加成功行，全部为独立row job；整帧同一bundle扫描与呈现仍待后续模块。

人工阅读可顺序核查：非法字段/权限未发AR；真实AR一在途且不跨4KiB；完整源/结果/policy/row generation跟随数据；三bank同时保留后BUSY拒绝；旧行read/return与新预取并行；取消保留旧AR/R/out holding；安全终态前实际abort_return；错ID/早缺LAST/enable-loss不回收且不重新开放。这是阅读与软件证据入口，用户理解验收仍待实际作答，硬件观察未进行。

MAP001：19 EFX_RAM10、8081 FF、11968 LUT4、439 ADD、1 DSP、0 SRL。MAP后只有TB刺激和模拟运行入口变化，11份生产RTL/原语模型与MAP snapshot逐SHA相同，无需因测试入口变化重复综合。Questa有15条packed input kind默认var提示；MAP有8条冗余循环变量、3个小cache映射逻辑、未使用job_bundle输入位及工具报告132个综合后提示；错误日志只有工具启动头，无错误诊断，详细原日志保留。后续必须在生产配置/renderer整合中重新检查这些输入的实际职责。

HD mode5在测试模型ideal（无随机延迟，R拍间仍有模型气泡）下，从job接受到首次done共1365个100MHz周期=13.65µs；包含测试中的ACK holding，终态holding等待另外记录。理想行预算14.814815µs仅余约116周期，真实DDR刷新/QoS尚未证，不能据此承诺持续60Hz。各独立组件资源不能直接相加当整机可装入。

失败原尝试保留：small_001的声明顺序；HD/min_001脚本参数入口；min_002把合法单拍LAST错误归为提前LAST。J2/J4说明修复和独立重跑，未改原资料。

PF01→CHECK/合法fill→字段/忙/代次测试；PF02→span/meta/carry→逐字节与54bit坐标；PF03→AR/R→边界/holding/ID/RESP/LAST；PF04/05→真实WR/publish/abort/return→完整行及取消；PF06→Q→未知不闭合；PF07→有限存储→真实19RAM/MAP与1365周期。反向查代码注释和事件可回到对应设计要求。
