# DISPLAY-HANDOFF v1 J1：实际综合网表回归

本卡在已读回v1、用户“当你统计完后自行进行，无需我的批准”和本批本地审计例外内自行实施；不冒充逐版人工批准。整体行为、1137/1207/942位接口、时钟、取消及冻结合同不变，增加真实MAP输出验证。

依据：handoff_map_001的Map.result.json退出0、7328FF/6958LUT/57ADD/0RAM/0DSP，warn/err无诊断。网表实际含EFX_FF、EFX_LUT4、EFX_ADD；从现有Efinity安装原样复制三模型及实际map.v到新work deps，基线v1.1在原8份之外追加这4份和本卡，共13份，旧baseline及旧run保持。

中文操作草图：先核Map成功、全部旧snapshot未漂移、当前RTL/pkg/project仍与MAP冻结相同→定义HANDOFF_POST_MAP→用实际网表替代handoff RTL，owner仍用已冻结RTL与独立租约参考→复用完整消息/冻结/取消/异常输入及真实扫描测试→逐bit核独立参考→核源SHA→登记。

接口及资源不改。TB原RTL可用8192周期加速测试watchdog；MAP使用真实默认50500000周期。网表回归跳过这两个加速超时场景，保留所有其他正常/错误/取消/冻结控制和DE内错误边界；真实默认超时的电路时长不冒充已测。真实1080p扫描可单独PostMap FullScan执行，无near-max/Small/mailbox参数覆盖。没有新增业务RTL、板级引脚、PNR、STA或bit。

HT7→实际MAP网表/native模型→原HT2/HT3/HT4/HT5组合+HT6 DE边界→独立完整回复和owner租约参考。11份自写文件数不变；原样依赖/网表单列。保存读回和聊天入口后实施；原库/硬件状态不改。当前无阻塞，物理CDC、row读取及整机仍待续。
