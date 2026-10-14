# IP预检输入v1.1实际批准

2026-10-04，审批ID AP-IP-PRECHECK-20261004-v1.1。用户来源 `["request_user_input_async","call_r8fX5uF2Wli9TZ6JTHrHTMFe",0]`；原问题明确输入修订v1.1/IP-PRECHECK-BL-v1.1/91份，仅原89＋原工程timescale.v及i2c_master_defines.v、原C0–C3范围、保留本地审计例外，不包含算法、bit/hex或硬件。

用户原文：**批准这项输入修订并继续**。

批准设计 SHA256 `07EA95A4E266DF270835827800546C5B71FF305D9EA0CF3953881A59807790CC`，原字节快照`approved-design-v1.1.md`；91候选基线 SHA256 `2333F4B42836EDC58B7F8083D0044542BFF8D2C9D375698F9A609C0C1A144AEC`，保留原89清单及首次失败。批准后91原源重新hash匹配；向C0补入两份原字节后91 work输入hash全部匹配，见C0-attempt2-input-check.json。未修改原HDK、正式数据库或硬件状态。

本批准是输入集合修订，不能扩大到protected IP更新、debug信号/profile改变或替换CSI设置。后续既有auto-instantiation/profile的正常官方工具生成阶段如实施，须记录命令、产物和来源，保持原连接；未知或越界仍停止相应case。
