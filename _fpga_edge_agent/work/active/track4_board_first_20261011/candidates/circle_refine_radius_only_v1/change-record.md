# CF radius-only 接线候选 v1

2026-10-11。依据用户持续自主/本地审计/免额外TB授权及 root 限定实施通知。root 已完整读回旧 CF/CR、关闭合同及协议，旧版 ROOT STATIC PASS；本候选只复制CF到新目录并作四处接线增量，不覆盖 circle_refine_v1、设计卡、主源码、XML、scalar、HDK、正式状态或硬件。

| 内容 | SHA256 |
|---|---|
| before/board/rtl/board_circle_refine.sv（旧CF逐字副本） | 9412A428E8841F017F0D435651CFA5040AC5D334D8BB841ABF8E95194BA601DE |
| board/rtl/board_circle_refine.sv（本候选） | 0AC562695ECA432200EC74825D71C093F0D4753AA43A7ACFFFF765D8EFEF7EA4 |
| planning/design-TRACK4-GEOMETRY-RADIUS-ONLY-001.md（只读） | BD01AFA1E9E776F7F5555FD8CD7309E8AFAEC932F230A70D46054DFA88D70DDD |
| planning/design-TRACK4-CIRCLE-REFINE-001.md（冻结不改） | 03549B326357F4E38C8C2EAC9B8B2BEFB66BF99921E5865320604AA27678D443 |
| geometry_radius_only_v1/board/rtl/board_geometry_point_math.sv（新PM依赖） | CC4BF36A1E51325948F12640379346865C48EC5F8778D3C4AAD7209504E64C05 |

只追加 `ENABLE_RADIUS_ONLY` 参数默认0，传给child PM，并连接 `eval_radius_only` 的四子阶段谓词：`!hist_owned && ((phase==2 && pm_step==1) || (phase==3 && pm_step==0) || (phase==4 && (pm_step==0 || pm_step==2)))`。模块参数/端口原顺序保留；不改成员、计数、数值资格或关闭FSM。

| 子阶段 | radius-only请求位 | 保留用途 |
|---|---:|---|
| B/c1：phase2/step1 | 1 | 原A成员内均值只取完整radius18，不读normal |
| C/c0：phase3/step0 | 1 | 原P(q0)只取完整radius18，不读normal |
| D/c0：phase4/step0 | 1 | 原P(q0)只取完整radius18，不读normal |
| D/c2：phase4/step2 | 1 | 原C成员内均值只取完整radius18，不读normal |
| HIST/A、B/c0、C/c1、D/c1、E | 0 | 继续原normal计算和成员资格 |

phase/pm_step/hist_owned从EVAL接受到回复消费与PM quiet保持；UNKNOWN不切这些来源。原PM_CLOSE在真实quiet后才改step或进入下一pass，故新位与旧EVAL同寿命。参数0恢复原18步数学行为，仍需要CC4…新版PM的参数和新增端口；不能以默认0声称与旧PM源码接口兼容。父正式启用时需置参数1，并选择上述新PM依赖，未在本轮整包接入。

作者已读回完整差异，只有参数、谓词、child参数/端口四处；四个真正不用normal的分支已对照旧PM_CLOSE。based literal紧连问号搜索无匹配，旧CF和旧卡SHA保持不变。没有TB、仿真或EDA；本候选等待父实际读回，未记ROOT PASS、资源/速度或识别运行证明。CR/HIST及其它共享依赖沿旧CF记录不变，不在新目录重复复制。
