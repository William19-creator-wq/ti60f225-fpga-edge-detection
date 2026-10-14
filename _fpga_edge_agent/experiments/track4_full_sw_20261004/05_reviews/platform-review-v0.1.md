# PLATFORM v0.1实际读稿审查

2026-10-04；TRACK4-PLATFORM-001。范围：[平台主稿](../../../planning/design-TRACK4-PLATFORM-001.md)、[原理图/封装来源v2](../01_baseline/board-pin-source-evidence-v2.md)、[SC431来源v1](../01_baseline/camera-source-and-phase-evidence-v1.md)及已保存FM/DDR/Canny/识别邻接。原资料只读；本记录是设计分析，不能代替RTL/器件/CDC/STA结果。

## 1. 实际完成的读稿

主Agent实际保存/读回主稿A–L与两来源页。三个独立方向读取实际文件：原理图/球号/电压、显示/容量/事件/资源、时钟复位/镜像/恢复/CDC。主Agent修订后，三个方向再次读取其指出的相关段落；最终指定审查范围未发现剩余直接文字矛盾。没有将此结论升级为全部算法、协议或硬件正确性证明。

| 方向与发现 | 实际修订/再读范围 |
|---|---|
| 引脚表缺HDMI/CSI/I²C/reset及VREF方向/owner | 来源v2补专用serializer输出、PHY/CSI接收、开漏driver/OE/读回、camera reset唯一输出未知极性及VREF专用参考；再次读回确认 |
| A14/A15只写“工具核对”不足 | 停放须匹配2Gb器件pin定义/板线，工具仅验证封装配置合法；PL-B02/07保留 |
| pending OPEN可能在fault冻结后补成功ACK | OP04/D4明确未提交者BUSY/终止安装，已提交者先合并再冻结；禁止新OPEN使旧集合完整 |
| 冻结CLOSE与commit撤valid冲突 | 冻结CLOSE BUSY不记成功/不放pin；FINAL done实际消费、cold/held归还后再关闭，CLOSE ACK后复用 |
| 停钟期间旧admit1可能复活 | sticky stop_new异步置位/同步解除候选，保持域不由私有rst清；不撤旧AXI承诺；真实原语仍B |
| 先等借bank归还再授权恢复互等 | 两阶段PREPARE808/FINAL808及独立814done；0x11先授权身份处置旧承诺/借用，再收0x3F。新PHY AXI epoch隔离避免旧valid重入；旧Q不改成功 |
| snapshot/epoch/session/queued关联不足 | fault/manifest/entry冻结同序号与mask/count；实际slot索引、漏/重复不算成功；FIFO含queued/pending/holding固定绑定旧link_session，双端关闭后更新 |
| seq耗尽可能阻断未提出CLOSE/恢复 | OPEN预留CLOSE id，READY预留fault/停止健康token；恢复复用OPEN token与fault/full_scope/类型组合；已有收尾不再争新seq |
| invalid索引与显示扫描冲突/迟到pair横移 | 输入逻辑接受索引和物理video坐标分开；迟到项不能挪到下一槽，超前项保持/安全pixel；精确DISPLAY恢复仍B |
| depth1邮箱及APPLIED/FAULT容量遗漏 | 私有槽满不捕获/不ACK；换active先预留APPLIED业务槽；运输ACK不等业务消费/再arm |
| FE资源可能重复加算 | 119已含FE/Canny44（FE本身8）；平台30后149，仅已列小计。14行bank替代9FIFO为154、同时保留为163，仍非全机预算 |
| 优雅复位先全禁prepare与末WB冲突 | 最后再读PL03/INV02/OP03/05：kind0/1允许旧job当前phase已授权有限尾/padding/dirtyWB prepare，local_quiesced后seal；kind2另走故障结账/PREPARE |

主Agent另核字段算术：health147、reset117/123、mirror688/694、manifest133/entry712、fault136、两恢复808/814、CAP189/DISP168；scope623装640容器，FIFO/镜像30块及119+30=149。算术不是原语映射/实际资源证据。

## 2. 来源复核的新结论

V4所选原理图与当前封装表的主要映射一致：KEY1/P13与历史KEY0/C4分开；DDR活动row14地址；HDMI四对板P/FPGA N交换及TX反馈脚NC；25/27MHz网络与bank电源有原图依据。没有新的v6 pinout报告或真实电压。

SC431原PDF8/30/31页实际查看，表明T4≥4ms以及原始读出坐标相位；旧ROM在crop/mirror完成前stream-on。I²C底层确有ACK采样，但高层仅等TIP=0而未检查NACK/AL，wr_done不是全部配置成功。名义SCL约30.303kHz为源码推算；Bayer裁剪/flip结果为有前提推断，真实模组相位/复位/电平未确认。

本轮tar只流式读取，不写出源码。个别猜测成员路径返回Not found，后按真实归档目录修正并重新读取/哈希；审计只计退出0的真实成员，不将失败路径当存在文件。

## 3. 状态与下一入口

平台为LOCAL_DESIGN；PL-B01…08保留，主要是冷初始化/真实锁定/停止clock、2Gb/受保护PHY、邻接mirror/recovery端口、CAMERA首HS/模式及模组、双clock原语/容量、related HDMI/约束、最终pin电气和整机期限/资源。没有READY或新实现批准请求。

下一步按依赖完成CAMERA/DISPLAY完整局部稿，再让FM/DDR等吸收已明确的接口/保持域/镜像与恢复顺序；整机批准前不生成业务源、功能脚本或可执行测试。原FE/FM/Canny/DDR/识别稿和输入保留，正式PROJECT_STATE/TASK_LEDGER/DB不修改。

PL-T01…16全部NOT_RUN；业务RTL/可执行TB/编译、仿真、综合、PNR/STA、bit/hex均未执行。现有模型获取和FRONTEND批准申请保持PENDING，没有重复询问。理解验收待用户实际作答。

历史识别阶段32份文档审计另存[document-checks-recognition-v0.1.json](document-checks-recognition-v0.1.json)，SHA256 C2AB087C402217EBC260B8B73ECFFB3C9004458CC581F4F1E79A1241A95AE13B；当前整机索引v0.10及文档检查重新绑定到[document-checks.json](document-checks.json)。检查链接/编号/hash/表格只证明文档维护结果，不证明功能已验收。

