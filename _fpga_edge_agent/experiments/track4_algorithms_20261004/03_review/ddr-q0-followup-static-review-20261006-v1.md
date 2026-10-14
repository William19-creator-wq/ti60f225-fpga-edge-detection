# DDR Q0 后续静态核查与动态验证入口 v1

2026-10-06。状态：READ_ONLY_REVIEW_COMPLETE；真实DDR动态仿真仍NOT_RUN。本次没有更改控制器、FIFO、器件模型或工程，没有生成业务RTL、TB、功能脚本，没有再次运行Q0、启动vsim或联网。

## 先看整体结论

现有控制器已经由获批Q0完成真实编译和合法展开。后续任务是用匹配板载器件的模型验证初始化、校准和AXI读写，再让生产存储适配接入完整Canny与识别。不能用理想RAM、另一容量的模型或Q0的成功退出代替这条路径。

阅读次序：本页结论→FIFO分支表→器件模型清单→后续逐步草图→原资格设计。原[资格设计v0.1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-DDR-QUALIFICATION-001.md)保留原字节和历史状态；本页是新证据补充，没有将其提升为READY，也没有扩大两批既有实施批准。

用户最新允许现有板载DDR3，继续保持1080p、全部五项基础和六项高阶、完整八邻域Canny及原圆/任意旋转矩形识别目标。本页没有重新引入排除DDR或追加外部存储条件。

## 局部：42条FIFO连接警告影响哪些分支

真实来源是Q0独立副本 `input/rtl/ddr3_controller/common/efx_fifo_v2.3/efx_fifo_wrapper.v`，54025字节，SHA256 `040558D9DAFD6D7F4C6610B8CD8040CDEDC3F95B58A6F31F32DBD7429182EB98`。本轮用逐行读取、遇保护标记停止的办法审读公开L180–850；L1–180已在此前读取。这里没有采用保护体实现。

外层wrapper端口有a_rst_i、a_wr_rst_i、a_rd_rst_i；L105–144实例化内层efx_fifo_top时，只连接公共a_rst_i，遗漏独立读/写复位输入，以及prog_full_o/prog_empty_o/datacount_o三个输出。内层公开L471–522共24端口，外层连接19个。下面按内层真实generate分支判断，不能只看外层默认值。

| 实际参数条件 | 内层复位来源 | 独立读/写复位漏接的静态影响 |
|---|---|---|
| SYNC_CLK=0、BYPASS_RESET_SYNC=0 | L583–595公共a_rst_i分别异步置位两域两级同步器，L603–605使用同步器最高位 | 独立输入不参与被选复位分支；仍需验证公共复位接线和两域释放，不能据此宣称FIFO动态通过 |
| SYNC_CLK=0、BYPASS_RESET_SYNC=1 | L598–600直接使用a_wr_rst_i/a_rd_rst_i，rst_busy固定0 | 被选复位源未连接；不能当作无害警告，必须先停止相关动态资格判定，形成明确修订或厂商匹配依据 |
| SYNC_CLK=1、BYPASS_RESET_SYNC=0 | L611–615公共a_rst_i生成同域两级释放，L624–626使用其最高位 | 独立输入不参与被选复位分支；公共复位和实际clk_i仍需检查 |
| SYNC_CLK=1、BYPASS_RESET_SYNC=1 | L619–621直接使用公共a_rst_i，rst_busy固定0 | 独立输入不参与被选复位分支；复位释放责任在外部，不能沿用内部同步器保证 |

L675–676将wr_rst_int/rd_rst_int交给实际FIFO控制器；L550–576决定真实时钟。同步、异步和复位旁路是不同选择。三个遗漏输出与两个遗漏输入要分开判断：未导出的输出本身不驱动内部状态，两个输入则可能成为活动复位源。

Q0 vopt日志是七种efx_fifo_wrapper参数特化各六条连接警告，共42条，再加一条+acc优化提示，总43条。**七种特化不是实际FIFO实例数量**；本次没有从保护体实例化语句或合法仿真层级取得全部实例参数，因此actual_instance_parameters=NOT_QUERIED，actual_instance_count=NOT_ESTABLISHED。外层默认BYPASS_RESET_SYNC=0不能证明每个真实实例均采用默认值。

后续必须通过工具支持的合法公开参数/层级观察取得每个真实实例的路径、SYNC_CLK、BYPASS_RESET_SYNC、两域时钟和复位连接；不解密，不读取保护体，不向保护内部force。当前Q0批准明确排除vsim，所以本次没有越界启动参数查询，也没有为压制警告修改源码。

## 局部：模型文件多，独立内容少

机器可读清单：[ddr-local-model-inventory-20261006-v1.json](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/ddr-local-model-inventory-20261006-v1.json)，SHA256 `A026A5F2C0FDA88E60BA1CEA828BA4801907B41B352B34D648F95F36A3F5C5B5`。

本轮在项目已解出的文件中按ddr3.v、*ddr3*parameters*.vh、*2048*.vh三个文件名模式检索，包含隐藏文件，排除工作副本、已登记产物和.git；对每个命中文件计算SHA256。51份文件只有3种字节内容：

| 内容 | 项目副本数 | SHA256 |
|---|---:|---|
| Micron ddr3.v，168423字节 | 25 | AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA |
| 4096Mb_ddr3_parameters.vh，54733字节 | 25 | 39BD3B893D9BEB65EA181DFE53A83ACC6291749A05FB46BBDF77C3ACD155A349 |
| 8192Mb_ddr3_parameters.vh，39425字节 | 1 | 96DDE2B377F65527DF67A7E77EC7009A4682064F9103FFB15F1E5D4E0F46D187 |

另检查既有Efinity2026_1安装目录中的三份同名文件，分别与上述三种hash相同。没有命中2048Mb参数头。这个结论覆盖上述模式与已解出文件，**不宣称所有压缩包成员、任意别名文件或用户电脑全部目录均不存在匹配模型**；此前更新HDK证据另保存了具体ZIP/RAR成员检查范围。

本轮重新读取模型公开L80–155：L97–98固定den4096Mb和x16；L122–123的den2048Mb分支需要2048Mb_ddr3_parameters.vh。4096Mb头的x16分支L555–560使用ROW_BITS15/COL_BITS10/DQ_BITS16/DQS_BITS2。Q0实际控制器参数头是ROW_WIDTH14/COL_WIDTH10/BANK_WIDTH3/DQ_WIDTH16/DQS_WIDTH2，CL6/CWL5/tCK2500ps/CK_RATIO4/ASYN_AXI_CLK1。容量和几何不一致，不能把4096文件改名后宣称已匹配2Gb。

板资料先前定位的器件为MT41J128M16JT-125，2Gb/x16。缺口是匹配的行为模型、完整参数/include闭包、速度/时序与使用依据，**不是缺少DDR控制器源码**。控制器已有时序参数不等于器件行为模型已提供或已经验证。

## 整体到局部的下一批操作草图

1. 沿现有[REQ-DDR3-MODEL-20261004 v1](D:/大三/FPGA_verilog/_fpga_edge_agent/tools/REQUEST_DDR3_MODEL_20261004.md)取得官方匹配输入。只查公开器件/模型资料，限定官方来源及其明确链接CDN，不上传工程，不安装或执行下载文件。该申请仍PENDING，本轮没有联网。
2. 资料到齐后逐项核几何、x16、CL/CWL和400MHz条件、初始化/刷新/ZQ等时序、模型版本、全部include、许可和保护使用条件。保留不匹配项；不能直接切换到另外容量或关闭时序检查凑通过。
3. 将真实FIFO公开参数观察、公开PHY双沿/OE、动态PLL相移响应、400MHz/100MHz及AXI跨域释放，与匹配模型一起冻结进下一份完整资格版本。实际实例参数未知是要由获批试验合法观察的项目，不在批准前猜值。
4. 设计可读回并获指定版本/范围批准后生成有限master、独立期望、协议监控和TB。先真实初始化/校准，再单拍与四拍全/部分字节写，实际B交付后发真实读，按实际R握手逐字节对照；覆盖AW/W先后、背压、LAST/ID、4KiB和arena边界。
5. 复位/校准失效沿先结算旧握手，再停止新请求；保留已接受写入和未决响应账本。自身静止、cal_done或短时间没有响应不能独自证明IP绝无未来effects。无匹配关闭依据时保留UNKNOWN，不能释放旧对象后当作恢复通过。
6. 动态资格证据足够后接入生产DDR服务，再与完整Canny滞后连接、识别、摄像头与HDMI整合；最终在同一整包基线上重新验证资源、时钟/CDC、带宽、引脚和时序。现有独立算术bit不替代整机bit。

现有资格设计Q-B01已由独立获批Q0实录闭合；Q-B02的匹配输入仍缺，Q-B03的PHY/相移与各域复位合同、Q-B04的完成/关闭语义、Q-B05合法异常覆盖仍需冻结。Q-B06不能沿用已完成Q0/R3的本地审计例外扩大到新实现。

## 审计、恢复和停止点

原Q0/R3设计、基线、源文件、运行结果及staging产物保留字节；正式Manifest、PROJECT_STATE、TASK_LEDGER、数据库和硬件状态不变。本次只保存静态清单与评审文档，读回核对，并追加本地审计事件。工具读取中的一次PowerShell管道语法错误已修正后完成安装目录清单；不涉及EDA失败或重新运行Q0。

下一外部依赖使用既有申请v1，不创建重复能力申请。项目[config/AGENTS.md](D:/大三/FPGA_verilog/_fpga_edge_agent/config/AGENTS.md)要求“任何下载、安装、升级、驱动写入、网络访问、插件/MCP/Skill 启用或外部服务写入都必须先登记并等待批准。”因此官方检索/下载须获得该具体申请的批准；这与用户已允许使用板载DDR3是两个不同的授权对象。取得输入后的业务实现仍按规范先有中文内部草图和指定设计版本批准。

完整目标保持ACTIVE、未完成；本轮没有确认仍在运行的EDA会话，不把等待聊天回复记为正在运行的工具。
