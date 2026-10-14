# TRACK4-CHECKPOINT-20261009-V6-001 v1

2026-10-09，控制面软件进度核验。READY_FOR_REVIEW；保存、读回后按用户“当你统计完后自行进行，无需我的批准”执行，沿本地审计例外。正式状态/数据库/硬件/源工程不改。

Goal：将已经通过的SC431HAI配置及video_async_fifo纳入原v5进度；Current：154份业务/验证文件，10包4579登记条目；Target：实际核对新增13+7文件、当前源码绑定的11组仿真和2个MAP、共12份不可覆盖登记包。Gap：新v6进度JSON与中文进度文档；不是新业务模块。Assumptions：旧v2/v3/v5及新两包SHA为已存在证据，不伪造旧初始70文件重新测试。Dependencies：上述真实文件、JSONL、本机Python标准库；网络N/A。Milestones：读旧进度/核验实际源/运行/登记所有文件→新JSON/中文报告→读回→追加事件。Rollback：只新增，不覆盖旧快照。Human gate：沿自主授权，无硬件动作。Completion：哈希与计数一致并记录未完成项，整目标继续ACTIVE。

整体：输入旧进度和当前2组件真实结果，输出“PROGRESS_FULL_GOAL_ACTIVE”，显式full_project_goal_complete=false。REQCP01：各新源逐个与登记source比；REQCP02：各仿真PASS/finished且当前源hash相等，MAP实际exit0及登记资源一致；REQCP03：旧10 Manifest及新增2均逐条hash；REQCP04：在控制面新建v6/报告、追加独立EV027，不改旧文件、不把组件数字当整机资源/时序。

接口：UTF-8-sig读JSON，SHA256大写字串；所有读取真实绝对路径，新增仅在控制面05_delivery；不得新路径覆盖现有文件。Python字典/列表与整数，不依赖第三方库。共174份只指业务/验证输入数量，不能称174个模块；104份工作源实核与初始70沿既有证据明确区分。

中文草图：先核旧v2/3/5链并重核其70+14工作源；以旧10artifacts列表逐Manifest/文件核SHA；新2包同样核；按RTL/model/TB/scripts/project/data仅纳入合法自写输入，SC13/FIFO7与冻结副本逐一比；按SC2和FIFO9运行核suite/audit/源manifest/MAP0；用实际metrics生成资源/测试摘要；全部检查通过才新建JSON和Markdown；实际读回JSON，再追加JSONL事件。出错保留旧进度，不能新增PASS事件。

验证：断言20新源、104工作源、12包/5071登记条目、SC43+2和FIFO49场景及518400零丢失、两MAP资源准确；追踪REQCP01→source核验，02→运行，03→Manifest，04→fresh/write/readback/event。已完整说明边界/正常和hash失败/接口/语句/UTF与位数/只读所有权/追踪/实施，达到READY后实施，helper不计业务源码。真实CSI、DDR动态、帧管理、显示识别、整机性能/PNR/STA/bit仍后续。
