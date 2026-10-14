# 识别 DENSE / NMS 生命周期有限静态审阅 v0.1

2026-10-05。对象：[NS 设计卡 v0.1](../../../planning/design-TRACK4-ALGORITHM-RECOGNITION-NMS-LIFECYCLE-001.md)。最终125行、23,944B，SHA256 `85B837A89412AB10D299AF1FDEA02DFCF8915A01B065F6EE525DDAA847326504`。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。

## 实际读回及有限复核

Root 对初卡实际读1–73、74–125，125行/22,982B，SHA `1AF3648231A5040DDF1373F7A538D8242C201AB93F3D7469F77ED17ADD9FE591`。随后修订只改L29/30/49/62/63/66/67，Root实际逐行读回最终七行并核最终身份；没有将最终定向读说成再次全文阅读。
独立语义读者 `/root/production_directory_numeric` 实际初卡全文1–125；中间修订实际读L5/29/30/62/66/67（23,617B、SHA `6E0A9317C82ECCF2A124FD02EA48ADEC7F8E570B12A88400CAC5B0C787D8DE21`）；最后实际读最终L5/49/63及metadata。独立数值读者 `/root/production_directory_numeric/quality_recipe_static_counts` 实际初卡1–65/66–125；中间五项差异、最终L5/49/63及metadata实际核读。独立协议读者 `/root/production_directory_numeric/load_grad_point_pin_review` 实际初卡全文；最终七行及status/OPEN实际核读。三者最终身份均85B837…6504；不宣称最终再全文审阅。
各读者仅只读与静态算术；没有业务脚本/参考/TB、仿真、EDA或保护体内容读取。此前各来源的定向/全文阅读范围由交接明确，来源保持原身份，不拿省略段或历史工具通过推全局结论。

## 已选定的具体衔接

一个 DENSE4432×21 与一个 NMS1108×21 DDR packed 对象保持；NMS四行是原票数：固定θ0/1、rolling末两行。batch0复制0/1/14/15后判1…14；后续先判旧末/新首/批内，再等旧债关闭并复制新末两行；末批复制510/511后判511、0。`14＋31×16＋2＝512` 恰一次，中心141,824；LINE明确按1…511,0及ρ升序append，不能假称已排序θ升序。
每批真CLEAR，不以initialized_prefix免除新批清票；DENSE ready只在全票/effects关闭后的后续沿发布。copy每行277完整成功才row ready；旧permit/native/borrow/物理效果未知时保持隔离，不覆写。逐行不是whole SEAL_TABLE，row ready不是SC/O资格；真实LINE_WORK权限和动态row gate仍待共同接线。
镜像为整个邻居ρ坐标，合法ρ235仍参与；支持门票等于阈值可进入比较，已确定拒绝可早退。READ先核canonical/票≤E；成功READ RSP.value低21、WRITE RQ.payload低21、成功WRITE RSP.value全0。operand21保持至目标操作结果/引用闭合，held遇cancel兑现。

## 数量与资源边界

Root与独立数值读者各自复算，语义/协议读者核对费用解释：66行/18,282 source READ＋18,282目标WRITE；source spans21,152、dest spans21,152；保护RMW后63,456次16B数据传输/1,015,296B。目标journal1,078,638 native issues＝548,460WE＋530,178RE；源READ/INIT/admin不套59，issue不是cycle。
四行在同一连续bitpack，起点offset128为0/57/114/43；row2首项跨含θ1尾位的unit90，必须真实保邻位。现行逐record数320/321不能直接改为bulk46/47，另选bulk需真实权限/借用与保邻位设计。
142bit＝row metadata40＋中心/operand42＋具名控制60，仅本worker部分。它不含RC/RA运输、完整H/profile、投影/系数/NUM、LINE计数/关闭/history；不等FF/XLR或全机RAM/DSP。全九邻逻辑读上界1,273,344、非中心1,131,520；有支持/邻居早退，未称真实工作量或成功时间。
32批CLEAR23,296×16B/372,736B；若第一批与首次INIT确实同一次合法事件则新增31批22,568写，另跑INIT必须额外收费。NMS首次184写/2944B与原一次容量账相同才不重复；不能免费忽略。

## 守护、范围和下一动作

当前8份来源及10项正式/R1守护身份全部一致，R1/R2/Q0冻结输入22/48/44逐项字节/哈希一致；R2/Q0 work确实不存在，当前EDA进程集合空。`FPGA_AGENT_DATABASE_URL`仍未配置，仅检查存在性，无凭据输出或数据库写入；Manifest/PROJECT_STATE/TASK_LEDGER与硬件不改。
前一goal turn分类ACTUAL_PROGRESS（RA初始化/单槽/组门设计和真实费用）；本轮ACTUAL_PROGRESS（完整batch/NMS衔接、非覆盖/镜像/输出顺序及独立费用）；没有confirmed live job/handle，不能把待聊天答复称verified wait。完整十一项仍未软件交付。
NS-B01真实phase/CLEAR/动态前缀row gate、NS-B02租约/实际DDR可见性/no-future、NS-B03全机资源/服务及共同吸收仍OPEN，RA-B05不因此整体关闭。下一可安全动作是这些联合设计闭合；已有R2/Q0指定批准待答，不重复问题，不扩旧R1授权。静态审阅不是数学/质量/仿真/综合/P&R/STA通过。
