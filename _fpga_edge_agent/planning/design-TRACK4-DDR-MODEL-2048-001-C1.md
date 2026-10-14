# TRACK4-DDR-MODEL-2048-001 v1 / C1：DM双向端口连接

真实 `ddr_profile_001/fatal_probe.stdout.log` 报vsim-3053，Micron `dm_tdqs`是inout，TB直接把常量2'd0接到双向端口，加载exit12；不是2048参数不匹配。原attempt和snapshot保留；positive/audit没有运行，不登记通过。

范围仅MOD2 TB：声明2bit net，continuous assign驱动0，再把该net接dm_tdqs。DM01..05及IF1外部固定DM0行为不变，保留model原接口；不改model/header/strict/clock/reset/后端。关联T-DM1/T-DM4。

中文草图：外部TB持有DM导线，连续驱动两个byte mask位为0；model对同一net有正常inout访问，不能以禁止检查/强制值修复加载。M0仍reset低、无命令和读写。

READY_FOR_REVIEW；保存、读回、呈现、冻结后沿用持续软件授权和本地审计例外，在新 `ddr_profile_002` 运行实际加载/有限时间/独立profile对照。源包、参数、正式数据库/H0/Manifest及硬件不改。
