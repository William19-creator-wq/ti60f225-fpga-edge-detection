# R4 STATS v1.1：最终设计读回与评审入口

2026-10-08；READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本报告是当前Agent的设计自检，无独立审查Agent、用户理解验收或本模块实际仿真/EDA结果。

阅读：[整体、接口、中文语句草图与22文件](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R4-STATS-001.md)B/C→D→E→G/H，然后读[具体来源/消费者与容器预算](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-source-and-budget-v1.1.md)、[独立验证/逐沿组合](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-validation-v1.1.md)。

## 当前范围与实际审阅

任务TRACK4-ALGORITHM-R4-STATS-001，设计v1.1，基线ALGO-R4-STATS-BL-20261008-v1.1，54份输入＝14份原FIT seed/经验＋10份既有工具＋30份规则/设计/证据。22份业务文件拟在独立r4_stats内生成，当前该目录不存在。实现目标为点集→精确圆LS/TLS统计→kind11/12/17/18原FIT真实组合；独立参考、四TB及Ti60F225/I3四pin25MHz联合软件工程。必要软件门槛通过才bit/hex登记，随即停止硬件步骤。

三份设计的共同主体已全文读回，v1.1修订段、主卡状态/基线/新参数/十项门槛及两个附稿新第7节另实际读回。旧端口/消息字典/质量公式、reset_sync及R3/R4 POINT/统计文本已实际读取；语义检查不是凭文件存在或hash推断。

接口数相加正确：token262＝ID176+op2+payload84，STAT632＝NUM622+outcome2+reason8；真实FIT返回585不是统计结果。FIELD、ID、START配置及reserved都从当前冻结契约映射，原六RTL与fit_reference原字节复用，旧FIT含唯一scalar/bridge/cache。STAT失败不发NUM，少点合法统计仍交原FIT判LOCAL_COUNT。

流水线POINT t0接受→t4五槽/n原子提交；include0仍推进扫描/合法坐标历史；TLS贡献明确p0/p2/p1映射。末POINT紧邻END时t+3最后提交、t+4离DRAIN、t+5形成STAT，要求关闭后≤6沿。有效ABORT同沿不提交旧算术，已有首错保持；源必须兑现旧公开token后原ID关闭。raw_seen先u23核u22，恶意超容量不回绕或伪完成，PROTOCOL_STUCK只共同reset恢复。合法域溢出守卫按数学分析与隔离helper验证，动态未覆盖态须明确披露。

真正stat_fire后注册622请求、真实原FIT返回消费/quiet确认后才发表585观察；observer_fire才转移共享响应字所有权，随后完整585沿CRC。source等待观察done才开始下一个job；不因旧返回或外层取消清除真实义务。控制进展有明确有限源/ready假设，没有用RTL超时伪关闭。

可读LS例n3/A3/B0/C2/D6/F4与现有源码公式核对，中心Q4(32,32)、质量RNE62914；全N对称fixture质量65535另算。TLS五矩及其字段域也核对。原POINT非零梯度/合模1530是更强生产条件，独立typed试验允许零/每分量1020，不冒称这些为实际Canny输出。

逻辑容器1810+1787+8955＝12552bit；新七core/五source/六adapter态分别3/3/4bit，不隐藏第二结果或scalar。实际XLR/FF/DSP及帧率未测。拟联合门槛XLR≤56000/RAM0/DSP≤32/25MHz、非负setup/hold、内部未约束/无clock/多clock0、实际非空Q→D及四pin/PT配置核对；未改旧FIT已批准50k门槛。

## v1.1补齐的尾域验证起点

FIRST_SEQUENCE unsigned64默认0，物理工程固定0。共同reset将next_seq置该常量、current_seq清0、exhausted清0，并准备相同身份START；只有真实START fire锁current_seq/推进序号。软件主probe仍0起点64job+reset4job；独立尾域实例MAX−1起点、同seed，真实处理MAX−1/kind17故障和MAX/kind18主动ABORT两job，完整关闭/观察后HALT，再257沿无START。无需等待2^64次调用或force更改在途身份；参数没有新时序容器，不扩大生产epoch恢复承诺。

v1及其54份基线保留为中间候选，当前不申请/执行v1；v1主卡完整字节已保存独立快照。当前v1.1仍未收到实现批准。

## 冻结字节、呈现与停止

| 当前文件 | bytes / SHA256 |
|---|---|
| 主卡v1.1 | 33201 / D10F798AB1C04C7423463F99FF147DDF5C4CC2A402A9D43F22C3269739FAD24D |
| 54份输入清单 | 19393 / 3254F0055C4D1E1C60519829D2C5C8502A1EA82196AF6B50DF8F0A55087E6925 |

[实际基线](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/01_baseline/algorithm-r4-stats-baseline-v1.1.json)于2026-10-08T05:57:44.400837Z保存，54项bytes/hash逐项核对0漂移；旧FIT244项登记及14份seed与当前原FIT源码也实际核对一致，未重跑未改动的旧FIT全套。最终再核及两附稿/本报告的hash保存到同目录r4-stats-design-readback-v1.1.json；该证明不塞回自身输入基线，避免循环hash。

聊天已呈现整体/接口/局部/测试阅读次序、22文件/验证范围，并说明v1.1补充测试起点。UI打开返回queued，只记已排队。当前READY是设计自检结果，不声称用户看过/批准、代码生成或测试通过。待执行计划仍含1024常规、固定错误/中止/复位、四场真实全N扫描（各2073600 POINT）、原FIT组合、68probe及尾域两job、同源综合/布线/STA和bit登记。

最近用户“批准”已有真实记录对应FIT v1，已完成该批；未扩大为STATS/ANGLE/DDR联网。规范§10.4“默认需要用户明确批准指定版本与范围”，因此下一步需明确批准本v1.1、54输入/22文件及本批本地审计例外。设计批准后相同边界内正常实施不逐变量重复批准。

正式DB仍NOT_CONFIGURED且URL未提供，H0/WAITING_FOR_HARDWARE_BASELINE、TASK_LEDGER、Approval Manifest不改；控制面设计/本地追加档案沿已有许可，新的业务执行审计例外只是REQUESTED。无新业务目录/RTL/模型/功能脚本/TB、EDA、bit/hex、网络/安装/硬件步骤。

完整十一项尚未完成：ANGLE/投影、候选/支撑/去重/原场景质量、完整Canny滞后、DDR动态/帧服务、生产相机/HDMI/CDC/阈值/冻结/叠加及整包资源/性能/引脚/最终产物仍待完成。本模块设计独立可实现，不撤销这些后续义务。
