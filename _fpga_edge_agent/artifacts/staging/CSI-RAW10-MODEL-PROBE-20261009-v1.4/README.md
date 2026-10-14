# CSI RAW10 软件核验：先接口事实，再接入采集

2026-10-09，TRACK4-CSI-MODEL-PROBE-001 v1，当前输入修订 v1.4。新自写输入3份：TB、独立Python参考、运行脚本；官方源、头文件、基线和日志分别管理，不重复计为自写模块。原厂保护主体没有修改、解密或替换。

## 整体、阅读和局部交接

先读控制面同名设计卡，尤其J1…J4，再读本说明、tb/tb_csi_model_probe.sv、model/csi_reference.py、scripts/run_csi_probe.ps1、当前runs与冻结副本。

官方vga_gen在50MHz像素钟提供组坐标、valid及HS/VS；TB按独立数值公式形成四个10位像素；官方TX核心把它编码为四lane LP/HS字节；官方RX核心真实解码；TB只采样其公开输出。control100MHz、byte约70MHz、pixel50MHz，4lane/Pack15/GENERIC/Discontinuous/FIFO1024/AREGISTER8/ASYNC2等RX参数按原活动实例选择。

局部操作：复位模型→等待300µs→启用官方视频源→每个有效输入沿生成RAW40，另给上24位变化哨兵→TX/RX真实交换→RX有效沿保存实际data/PPC/元数据→源达到完整帧数量并到VS下降后停止新payload→继续收集→核完整数量与独立参考。等候只帮助测试收集输出，不能作为生产接收closure。

公式为p(x,y,f)=(37x+53y+7(x xor y)+101f) mod1024，四像素由最低10位起依次放入40位。SV锁定源提交值，Python按输出顺序独立重算帧/行/组及每个像素，包含LSB变化和y>1023。源坐标使用官方14/12位，没有沿旧例csichk把y截为10位。

原观察每条16字节little-endian：data64/PPC8/DT8/VC8/HSVS8/WC16/short16；附一字节unknown-mask，未知字段不被0占位掩盖。三个域分别记录公开端口边沿；tx-lanes.bin保存活动四lane与LP状态，便于后续独立链路实验。没有读取保护主体内部状态生成期望。

## 实际通过和实际发现

当前源绑定的csi_raw_small_005：20×8两帧，80组/320像素，逐位与数量通过。csi_raw_hd_001：1920×1080一帧，518400组/2073600像素全部10位一致；实际首有效输出371990ns，末有效33053670ns，源帧结束33123770ns。两个运行均先验证fatal非零出口，真实动态仿真0errors/0warnings，独立审计PASS。

1080p全部有效拍实测：PPC=4、低40位为四个顺序10位像素、上24位0、DT=0x2B、VC=0、WC=2400、HS=1、VS=1，没有未知字段。原shortpkt_data_field在这些payload拍也为2400，与WC相同，不能把它直接解释成当前帧编号。原字段的此项观测只覆盖本模式和这些场景；未证明所有混合包/尾拍的对齐。

帧末原字段后来变DT=0x01、WC/short=0x1337，像素域VS于33124890ns下降，晚于末payload71220ns；这是正常运行观察，尚未证明所有接收错误先于此下降。可选pixel sideband、CRC故障注入/归属、失钟/包损坏/短包事件关联、生产接收closure、SC431HAI真实PHY和板卡均未验证。

源依赖来自官方RX/TX ip_component.xml的external_testbench_modelsim并集，共47份库/头文件，另有未修改的官方VGA源。其source_modelsim、D-PHY、common同步器、efx_fifo_2文件都实际复制并核SHA。两个旧打包model仍保留，但当前通过采用官方完整源码链；未将某个stub当CSI接收。

## 失败、根因和当前脚本

001/002旧打包模型展开报告潜在无限递归；003准备时junction路径归一化错误，实际仍运行旧脚本；004完整链定位到公开FIFO Gray→binary递归。Questa官方CLI帮助说明-G会覆盖所有同名参数。错误来自本探针脚本-GWIDTH=20，它覆盖内部WIDTH-1，破坏本来有限的递归；移除-G后同一编译库展开成功，原厂源码未改。当前TB改用专用PROBE_WIDTH/PROBE_HEIGHT/PROBE_FRAMES参数，005/HD重新验证通过。失败日志不覆盖，不称原厂模型逻辑有错。

已有其他组件脚本也有-GWIDTH，但本轮只读查到相关自写模块WIDTH表示图像宽度或本FIFO记录宽度，官方RAM10使用READ_WIDTH/WRITE_WIDTH；没有把这个问题机械扩展为旧包全部失败。其完整依赖还须按实际节点复核；冻结包未改，不以这段检查伪称全项目重新测试。

## 下一采集设计与使用边界

正常RAW10可从data[39:0]取四像素，并按真实PPC/HSVS/数量核验，接到双时钟缓冲和RAW/RGB源写入链；元数据、帧身份与错误事件仍要明确对齐/归属。输入无ready，不能把FIFO的接纳信号回传当真实摄像头反压。帧管理与真实接收closed证据继续设计，实现时保留scope/handle、错误关闭与源写fence。

本探针没有综合、板级PNR/STA或bit，不包含FPGA生产RTL。没有证明当前完整库与C2嵌入保护体逐项等价，更没有实物操作。登记为软件模型证据，整体五基础/六高阶仍在推进。

追踪：CPREQ01→官方源/TX/RX→CP01…03；CPREQ02→raw_group/独立group→CP02/03；CPREQ03→二进制/unknown/三个域端口记录→CP04；CPREQ04→source_done/有界收集→CP03/04；CPREQ05→runner/源SHA/fatal/日志→CP05。新RunId拒绝覆盖旧证据。
