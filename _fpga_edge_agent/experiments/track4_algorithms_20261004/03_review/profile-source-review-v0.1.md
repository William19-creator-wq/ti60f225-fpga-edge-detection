# PROFILE-SOURCE v0.1：实际来源与限定审阅记录

2026-10-04。本文保存实际已收到的来源/数值/协议审阅及修订范围。纯设计记录；NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED，所有功能场景NOT_RUN。独立审阅范围不等于整包通过。

## 1. 实际输入及绑定

| 输入 | bytes / SHA256 | 实际阅读范围 |
|---|---|---|
| 初轮卡草稿 | 28838 / E68F5AA880F6ED2957DBD347E272365D9BE39090DFA8827F74E84D46357E767A | 数值审阅D1 L61–75、F L131–137、G L139–154及OP01/02/07；协议审阅194行全文，读前后hash相同。该轮未保存精确草稿快照，不能假称存在。 |
| [PROFILE布局纯数据](../01_baseline/profile-store-layout-v0.1.json) | 4254 / 4FE6BF462E97C30D8F421E9D30FDA96D4D9DFC7AC397024B4320159702B0B810 | 数值审阅全文；根实际全文读回。 |
| [seal修订、OBS修订前快照](../../../planning/design-TRACK4-ALGORITHM-PROFILE-SOURCE-001-v0.1-before-obs-bound.md) | 29571 / FC7EE6EA1F70E754FA1B0880615D609E05AFF2847961E37EDEBB5D586CAB559B | 数值审阅D1新增L75、F L137及OP01；根原全文加改动读回。 |
| [最终候选卡](../../../planning/design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | 30415 / 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | 根读回全文分段及全部差异；独立最终协议范围另见第4节。 |
| [整合v0.5精确快照](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.5-before-profile-source.md) | 40026 / DB1DD10FCF4190036993D7C7AF95C04C03B3307377D1FDDCEE56D2D42256272D | 真实Copy-Item后hash核对；不表示审阅者完整审过整合新v0.6。 |

审阅者为 r2_terminal_numeric_review 与 r2_terminal_protocol_review；均只读，无实现/构建。根负责文档修订与纯数据保存，原HDK不改。

## 2. 来源实际核查的结论与边界

数值来源定向读取当前R4R AA05866F的E10完整1024bit、R3 6D071B0A、CONTROL 2C2CB802及旧RECOGNITION-NUMERIC 17C4A290/RECOGNITION-ALGORITHMS D8C45B02。PROFILE七组128/192/192/192/128/128/64合1024；geometry dedup为Q4，label offset为s8整数像素。候选label off的scale1显式覆盖旧scale0；offset0为本候选选择，不能伪称旧来源已规定。eligible只要求覆盖circle radial及rect inlier门，不增加无依据的TLS残差关系。旧默认门值/新censor guard没有质量验证，不能安装为达标默认。

现装 efx_ram10.v 为17913B / DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33；数值审阅实际读L7–28/42–57/100–135/177–214/329–417。20×512候选、同步读、完整WE与BOOT/GET互斥相容；同址未定义，明确禁止。一个RAM的几何核查不是实际综合结果。八个UI preset不是八profile，ref不是地址。

协议来源读当前CONTROL 2C2CB802、VIEW C7641627、SLOT 6BC15967相关源/返还/历史段；旧CONTROL A0CE9329、FRAME-MANAGER D4CD59B9、CONTROL-JOIN B8DAED20、需求决策FFA7ADB5及两份原题指南已有提取文本。实际旧UC03/04允许慢完整帧模式显示重复和latest候选；基础行流水/采集无丢帧仍独立要求，不能以慢后端政策豁免。冻结仍需真实源借用、同SRC调参重算且不STOP相机。

## 3. 两次实际数值审阅

E68F初轮：8×52=416word，末合法415；8192逻辑加128padding为8320bit，余96word/1920bit。INSTALL1121/ACK1257、BOOT_SEAL100/ACK108、GET184/REPLY1215、lease原请求与ref的8×355=2840、四份PCTX65=260均与字段和相符；e0读首字、e52捕获末字并后续核验/回复符合所读同步模型。目录8×162=1296本身算术正确，但ACK的seal64若为持久独立token，目录还需512bit及分配/holding，不能以ref默认替代。

FC7EE增量：D1已明确独立持久seal、接纳前独立ref/seal预检/预留、真实封存才授有效；目录每项2+32+64+64+64=226，八项1808bit。ref、seal各next/exhausted65，preferred ref/valid65，共195bit，相对旧明列预算增加512+65=577bit。其它独立当前槽/完整last-cache不变时，PR明列payload13795bit，加lease/PCTX为16895，另加最近启动签名161为17056bit。FSM/访问计数/返还holding/CDC等未完整列出，这不是完整FF预算或可综合资源报告。审阅建议OP01补slot/ref/seal；最终稿已同步。

## 4. 实际协议反例与最终有限复核

E68F全文审阅：消息位宽未发现矛盾；原grant role不改、sourcefire/BIND转同lease、PCTX历史、T/R接纳前预留futureGen且ABORT不复用、held COMMIT履约及WAIT_FIRST可RESUME相容。独立OBS反例成立：3B+F+latest占五源，OBS可保留失去最后B/F/L的第六源，下一CAP没有FREE。“不产生新图”不等于“不延长寿命”，角色式不能作为穷尽容量证明。

根选择保守真实占用方案，最终D3/T05明确：六槽准入数完整目录及CAP reservation，OBS独立存活也计入；3B/F/L/独立OBS满六时拒第七CAP/ARM，保留旧图并记录阻塞。角色公式只在OBS与列举源重合时成立；候选不保证下一SOF可接、基础持续无丢帧或DDR服务，PS-B03仍OPEN。没有将拒ARM包装为成功采集。

最终独立协议复核实际读回L91–113、115–121、135–139、147–155、170–196；读前后均为30415B / 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103。确认独立OBS/真实目录/CAP reservation计入、六源公式条件明确、拒第七CAP不覆盖、lease数与distinct源数分开，T05仍NOT_RUN且B03仍OPEN；OP01包含slot/ref/seal，F目录1808bit，K未混淆旧稿范围。限定修订未发现新反例；没有重审整包或执行协议测试。

## 5. 本机Efinity工程事实

本机既有 C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/bin/efinity.exe；既有C0工作项目[ti60f225_oob.xml](../../../work/active/track4_ip_precheck_20261004/C0/ti60f225_oob.xml)为15074B / 5F0CF2C013F945974052FFE796D68E84815C9F5C02B9CF37EA44086221BFED3A，实际device_info选Titanium/Ti60F225/I3，SV2009及RTL/peri/约束既有引用。工具运行版本2026.1.132和当前综合通过来自[有限预检实录](../../track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)，不是XML历史last_run_state。

已实际读取本机官方doc/topics/efn-unified-open-project.html的Procedure：运行Efinity，点击Open Project，选择工程XML，再Open。因此存在可打开的器件/板卡参考工程；本轮未启动GUI或冒称已在界面打开。现装通用Ti60F225_devkit_tutorial选择C4，仅是另一官方教程，不能替代目标V4/I3板卡引脚工程。

有限C0综合/debug/PT通过，但PNR在packer缺USER1 TDI/TDO停止，placement/route/STA未通过；C0/C2 CSI保护区Questa无key，未完成DUT功能仿真。十一项新增功能也未实现。工具/工程存在与完整目标实现证据分别陈述。

## 6. 尚未关闭

实际精确PROFILE门值/GT、完整目录/访问关闭/cache/错误矩阵、UI277/F联合状态、策略COMMIT族、snapshot/cancel/CDC竞争、基础持续采集/DDR期限及全机资源/文件/schema/批准均未闭合。SJ-B02与整包B01…06不因有限读审关闭。

本轮只保存设计/纯数据/实际审阅/入口并追加本地审计；没有新算法work、业务源码/模型/runner/TB/工程/SDC或新编译/PNR/STA/bit，正式状态/Manifest/数据库、原资料、待批准v1.3/Gate保持。
