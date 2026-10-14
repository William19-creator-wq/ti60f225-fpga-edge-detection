# DDR3 官方资料查找实录 v1

日期：2026-10-08。关联申请：REQ-DDR3-MODEL-20261004 v1。范围：官方公开资料查找、输入获取及只读适用性核查。结论：**OFFICIAL_MODEL_ENTRY_LOCATED / MATCHING_MODEL_ARCHIVE_NOT_ACQUIRED / DDR_DYNAMIC_VERIFICATION_NOT_RUN**。

## 授权与当前边界

用户本轮原话：“你是否可以通过官网找”。按该行动请求执行 Micron/Efinix 官网检索、公开页面和产品资料读取，并保存所读公开输入。执行前已追加 `runtime/events/2026/10/session-DDR3-OFFICIAL-LOOKUP-20261008.jsonl` 的 001 事件。此前申请中的 PENDING 是当时的历史状态；本轮官方查找已经取得用户授权并实际执行，不再把“未获准联网查找”作为本轮停止原因。

本轮没有修改控制器、器件模型、RTL、约束或工程，没有运行下载的 JavaScript、安装软件、提交身份资料、注册账号、接受额外协议、向厂商发信或启动仿真。不推导 STATS 或其他实现批次的批准；正式数据库及硬件状态未改变。

## 来源与查到的事实

1. [Micron 选定型号入口](https://www.micron.com/products/memory/dram-components/ddr3-sdram/part-catalog/part-detail/mt41j128m16jt-125-k)。普通页面读取只取得动态页面框架；因此使用该页面公开产品资料接口读取型号信息，所得原始 JSON 已保存。型号为 MT41J128M16JT-125:K；容量 2Gb、总线 x16、电压 1.5V、速度 800MHz / 1600MTPS，官网状态 End of Life。这里的最高速度不等同于本工程采用的 DDR 时钟。
2. [Micron 2Gb 产品模型入口](https://www.micron.com/products/memory/dram-components/ddr3-sdram/part-catalog/part-detail/mt41k128m16jt-125-k)。官网检索结果列出 DDR3 SDRAM Verilog Model，版本 1.74，ZIP 类型，更新日期 2015-10-29，入口标记为 Get Access。该产品自身是 MT41K、1.35V 的 DDR3L；这条记录仅证明官方模型条目存在，尚不能证明压缩包及参数适用于选定 MT41J 器件。
3. [Micron 仿真模型说明](https://www.micron.com/sales-support/sales/faqs)。官网说明 DRAM Verilog 模型以 ZIP 提供，需按器件产品目录寻找。
4. [Efinix DDR3 控制器官方入口](https://www.efinixinc.com/support/ip/ddr3-controller.php)与[用户指南 v2.1](https://www.efinixinc.com/docs/ddr3-controller-core-ug-v2.1.pdf)。指南已下载并验证 PDF 文件标识。它说明 Titanium 支持、Efinity 提供控制器，以及 IP Manager 可生成仿真测试文件；同时说明厂商仅测试默认参数选项。文档本身不提供本轮所需的 2048Mb 参数头，也不证明选定板卡的读写通过。

公开产品接口以官网页面声明的接口形式读取；公开文档清单按照页面客户端显示的匿名查询方式尝试。GET 文档清单返回 HTTP 400；匿名文档清单查询分别对 MT41J 与 MT41K 返回 HTTP 403。这里没有尝试变更身份、伪造已登录标记或获取受限 ZIP。403 只证明本次匿名查询被拒绝，不能断言注册账号即可取得权限。

浏览器已创建官方产品页标签，但两次内容读取超时；未把该超时解释为官网不存在模型。网络查找与产品资料读取使用既有网页工具及普通 HTTP 读取，未新增能力。

## 文件取得状态

取得：公开页面框架、MT41J/MT41K 型号 JSON、官网页面客户端源文本（静态阅读，没有执行）、Efinix 控制器指南 PDF。文件位于 `_fpga_edge_agent/work/dependencies/track4_ddr3_model_20261004/`，各文件字节数、来源和 SHA256 见同名 JSON 实录。

**未取得**：DDR3 模型 ZIP、`2048Mb_ddr3_parameters.vh`、与选定器件匹配的全部模型 include 闭包。因此本轮没有解除匹配模型输入缺口，没有记录任何初始化、校准或读写仿真通过。

## 建议的下一步

通过 Micron 正常登录及 Get Access 流程取得 DDR3 SDRAM Verilog Model 1.74 ZIP，或由板卡厂家提供相同来源的完整模型包。取得 ZIP 后只读列出内容，核对 2048Mb 参数头、x16 分支、模型版本、速度参数与使用条件，再决定是否可冻结为 DDR 动态资格验证输入。不能仅因版本号相同或容量相同就记录匹配通过。

资料获取与下一批业务实现分别管理。STATS v1.1 的实现批准仍待处理，DDR 动态试验还需完整资格设计及相应实现授权；本轮不扩展这些范围。
