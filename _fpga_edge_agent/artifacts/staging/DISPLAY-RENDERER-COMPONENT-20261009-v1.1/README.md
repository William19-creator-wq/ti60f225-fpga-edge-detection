# 六模式像素合成：阅读与复现实测入口

本包接收已授予行借用、已核全文身份的pair54及同帧render112，输出双像素RGB和同延迟同步/坐标。已完成软件、实际Ti60F225/I3综合及映射后动态；scan、DDR/PHY、TMDS、板级PNR/STA/bit仍待生产联接。

阅读顺序：`planning/design-TRACK4-DISPLAY-RENDERER-001.md`整体/交接/局部中文操作 → J1真实网表验证 → 本包baseline-v1.1的12份冻结输入 → rtl → tb与独立model → scripts/project → runs实际结果。自写7份，复制依赖5份（timing、FF/LUT/ADD原生模型及真实MAP网表），总源码/工具模型12份；依赖不计自写模块。

## 整体/局部语句草图

```text
scan同一owned row的RGB48/EDGE2/ANN4、render112及数据/身份资格
视频时隙的DE/HS/VS/frame_start/x_even/y
 → 组合检查和16bit灰度移位加法 → S0锁当拍快照
 → 两个lane只读旧S0、按mode/标注/边缘优先级选色
 → S1同时提交RGB/同步/坐标/error → 后续发送端
```

输入E_n正沿采样，输出E_(n+1)正沿形成：两个寄存级，实际相隔一个周期。`always_ff`同时读旧snapshot并写新snapshot，不能把当前render混进旧像素。时隙不可回压；上游需提前解决native RAM读延迟。最后RAM响应不等于本流水已空，父必须保留借用到旧输出关闭。

`gray8`先将每RGB通道扩成16bit，再用移位加法形成77R+150G+29B+128，取[15:8]。最高65408，无溢出、除法或DSP。`select_color`逐lane读旧RGB/gray/edge/ann和颜色flags；组合段给全字段默认值，避免悬空和锁存。

|mode|实际颜色规则|
|---|---|
|0|上半SRC灰度，下半EDGE白/黑；source_y缩放由预取完成，不再次抽样|
|1|原RGB888保持|
|2|与R1相同灰度|
|3|EDGE白/黑|
|4|show_edge且EDGE1选edgeRGB，否则原RGB|
|5|show_ann且ANN非00先选圆/矩形/文字码颜色，其次可见EDGE，最后原RGB|

pair低lane0，RGB每lane={R,G,B}。render112高→低为mode3/split_y11/edgeRGB24/ANN01RGB24/ANN10RGB24/ANN11RGB24/show_edge1/show_ann1。ANN00透明、01圆、10矩形、11文字/异类重叠；本叶消费已生成的标注码，识别和字体栅格生成仍属算法侧。

有效区域按顺序检查：非法mode/split/坐标给error2；字段合法而身份坏给error3；字段与身份合法而像素缺给error1。输出黑色且同步照常。blank固定RGB0/error0。输入资格来自上游真实全票据比较，不在此伪造授权。错误黑色只用于明确诊断，不能当作无闪烁/无撕裂验收。

## 操作次序与人工观察位置

1. PowerShell运行 `scripts/run_renderer_sim.ps1 -RunId 新编号`；默认20×8，`-Minimum`为4×2，`-HD`为生产1920×1080并实际跑六整帧。目录存在会拒绝覆盖。
2. 脚本核冻结输入，在每次尝试复制完整source-snapshot，编译这些快照，保存PID/完整参数/开始结束/退出码/stdout/stderr。fatal探针必须非零且不产生成功metrics；实际仿真后独立Python才给最终PASS。
3. 打开renderer-trace.csv：原输入in_cycle至out_cycle应差1；对照同一pair/render/坐标/数据与身份资格和输出，注意mode5两lane可选不同标注色。复位作废旧S0单列，不计正常交付。
4. HD输出frame-mode0..5.bin每个12字节时隙：RGB48小端6B、{DE,HS,VS,frame_start}1B、error1B、x_even小端2B、y小端2B。每帧1237500时隙、2073600有效像素；独立参考逐时隙比较所有字段，并比较整帧SHA。预览是实际输出4×4区域平均，数学fixture没有真实物体或相机采集。
5. 综合：`run_renderer_map.ps1 -RunId 新编号 -SimulationRun 已通过的普通RTL编号`。Efinity打开project/display_renderer_component.xml，Ti60F225/I3、video target13.468ns；接口尚未绑板级引脚，当前范围MAP。
6. 实际网表：`run_renderer_sim.ps1 -RunId 新编号 -PostMap`核MAP001结果/原RTL/网表哈希后，编译原生FF/LUT/ADD和真实网表，不编译行为renderer；仅匹配1920×1080几何的69911条协议/数值场景，不将其称六整帧网表时序仿真。

## 真实结果及边界

合格证据为renderer_small_002/min_002、renderer_hd_001、renderer_postmap_001。四组各69911 trace，共279644条，全部65536种R/G组合、64种metadata、mode0..7和error0..3；有效mode仅0..5。每组2次同步复位/1条S0作废，最终残留1个空白时隙单列。实际六HD帧另7425000时隙/12441600像素；RGB/control/x/y/error全部逐位通过，包括blank。

MAP001真实276FF/314LUT/298ADD/0RAM/0SRL/0DSP，错误日志只有启动头，无错误诊断；唯一警告消去冗余rendered信号，无锁存/未驱动诊断。生产RTL和MAP snapshot一致。MAP/HD001后只增加TB网表分支、顶层独有TEST_RENDER_MAP和模拟入口；HD001原快照完整保留，行为renderer/参考/timing没有变化，小/最小/网表用当前验证源重跑通过，不冒充HD001使用了后来验证入口。

映射后证明为功能模型，无SDF或板级路由延迟；74.25MHz附近仿真时隙不能代替实际STA。上游身份检查、预取deadline、整帧切换/冻结、DDR refresh/QoS和TMDS未在本叶测试，不以纯像素合成替代整机闭合。用户理解验收未作答、硬件观察未进行。

RR01→S0全payload快照/两lane→RT1/3；RR02→select_color→模式/flags/ANN/edge；RR03→gray8→65536R/G与灰度边界/真实加法网表；RR04→两个寄存级→trace周期差与六帧完整控制；RR05→检查/error→优先级及black/blank。每份源码注释、参考和测试记录可反向定位设计。

上排为mode0/1/2，下排为mode3/4/5，图源是数学输入的实际RTL仿真输出：

![六模式数学测试输出预览](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/display_renderer/runs/renderer_hd_001/six-mode-preview.png)
