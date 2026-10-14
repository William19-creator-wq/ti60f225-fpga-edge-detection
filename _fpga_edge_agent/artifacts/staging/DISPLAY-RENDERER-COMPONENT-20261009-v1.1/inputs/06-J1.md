# Renderer v1 J1：实际MAP网表数值和固定延迟验证

small_001/min_001各69911条公开输入输出已通过，MAP001实际276FF/314LUT/298ADD/0RAM/SRL/DSP，错误日志只有启动头，唯一提示是消去冗余rendered信号。HD001六帧仿真已结束，独立全时隙参考仍在运行；不提前称其审计通过。

验证计划增补：原生EFX_FF/LUT4/ADD模型原样从已登记handoff依赖复制，MAP001真实网表原样冻结；testbench新增编译分支，只从公开端口驱动真实网表，不访问DUT内部结构。MAP固定W1920/H1080，post-MAP的TEST_RENDER_MAP只选择匹配生产几何，而不运行昂贵的六整帧；使用同一69911条字段/优先级/灰度/控制/热配置/复位用例，独立Python按公开记录计算黄金。

中文操作草图：runner先核当前baseline、MAP001实际成功/网表哈希及当前生产RTL相等→编译三原生模型/真实网表/旧timing/TB（不再编译行为renderer）→vopt只设置顶层唯一TEST_RENDER_MAP→fatal非零探针→实际网表动态→原参考→检查源没有漂移。TB分支不向网表传不存在的IMAGE参数；所有公开input/output位宽、两个寄存级和RR01..05合同保持。

baseline-v1.1为原7份加J1、3原生模型和1真实网表，共12份；原7份不改。计划仍7份自写文件，deps/model另列，不以复制工具网表当自写代码。MAP后的TB/runner变化只在验证，不改生产RTL，保留MAP001 snapshot和旧三个尝试；HD正在运行时不修改其原源，等待其明确终态后再生成这项验证分支。

RR03/04/05→真实映射加法与寄存门级→RT2/3/5。按已有自主软件/本地审计授权读回后实施，无新工具/网络/硬件动作；组件PnR/STA和完整scan/DDRIO/TMDS仍不在本项结果内。
