# 实际三叶读服务：联合验证语句草图 T1

2026-10-10，附于已读回呈现的 v1，不改变生产 RTL/接口/范围。READY_FOR_REVIEW；依据用户持续“当你统计完后自行进行，无需我的批准”及本批本地审计例外继续软件实施，不另申请批准。正式 DB/H0 与硬件不改。之前 IDE 展示提供实际 GUI 加载 Ti60/I3 证据，但没有增加功能验证；当前恢复真实联合测试。

## 整体与端口

目标仍为五基础六高阶/1080p/原识别范围；这里补 v1 七计划文件中剩余六个。actual wrapper、line/span/arbiter 三冻结依赖原样，同 clk/rst；数学 AXI slave 是协议刺激，不能当真实 DDR。req/rsp/data/done 均用正沿前 valid&&ready 记事件，负沿驱动；NBA 后再检查可观察结果。

正常路径：两个应用 req 接受→实际叶锁请求→实际仲裁锁49位 AR→物理AR接受→slave按地址产生全128位字→实际叶组装512或持有128→应用交付。物理末R可先于应用交付，独立账仍保留应用身份。

## T1..T7 局部中文草图

1. TB `step` 在正沿记录全端口、实际火事件和完整正文，稍后返回负沿；记录每个周期而非只记成功。独立文件有 case、clock/reset/enables/cancel、两应用输入、全512/128输出、全49/135物理总线和各Q/idle/occupied。expected-fatal 单独会失败且不能写成功结果。
2. slave 仅维护由实际AR接受建立的地址、ID、长度和beat；一个在途。地址字节公式为 ((address+i)*37+11) mod256，小端16B。停顿时R的128/ID/RESP/LAST全部保持；错误/早晚LAST/wrongRID是明确测试场景，不修改DUT寄存器。真实尾是否还能流动遵从实际Rready，不强迫drained。
3. 应用刺激以真实req ready为条件，连续混合64B line及16/1024/8192B span，含跨4KiB及256MiB末端。独立ledger从请求和物理AR/R重建有效数据队列；512由四个地址字拼成，128逐字比。只用公开事件，不读DUT state、counter、holding或内部AR数组作为期望。
4. AR不得无请求、越范围、重复已发段、跨4KiB或大于64拍；line固定ID0/4拍、span ID2。接收先建应用记录，物理事务存在至正确尾或明确共同冷reset；失归属后保留unknown，绝不从idle或叶notice消费推出引用closed。
5. 每个场景给字面终态期望和请求/AR/返回数策略；invalid input是ERROR且无AR。RESP error为ERROR/drained1并保留已交付前缀，算法全512错误口为0。cancel为CANCEL128；held旧data仍交付。disable在live导致UNKNOWN/drained0，区别cancel。terminal已形成后cancel不改终态。Q阻新req，held旧reply/data/notice仍走；正确旧尾可以流动但busQ保持unknown，不冒充恢复。
6. 对所有valid&&!ready的AR、R、line reply、display data和done逐周期检查完整正文保持。正常结束时没有丢失/重复应用；共同冷reset显式作废所有应用/物理slave，计数单列，不说暖reset安全。两源压力检验各真实完成，不把机会3:1当deadline保证。
7. runner源快照包括wrapper/三deps/TB/reference/sim共7份，守卫冻结9输入（原8+本T1）；vlib/vlog/vopt、fatal、vsim、独立audit分别保存PID/argv/start/exit/timeout/SHA，任何失败保留；MAP需当前联合PASS，增XML/SDC/map共10快照，实际Ti60/I3/100MHz目标/speed/retiming0/seq_opt0。无PNR/STA/bit或真实DDR资格。

## 场景及对应 v1 RPT

1..7 正常双源持续、大span与背压、16/1024/跨页8192、line/span容量末端；8..15 非法地址/长度；16/17 两叶RESP error；18..22 cancel在PLAN/ARhold/R/holding/terminal；23..26 两叶disable各阶段；27..32 wrongRID/早/晚LAST、Q与旧通知/尾；33..35 共同reset在AR/R/held应用；36/37 arbiter停用前/已locked；38 AR沿零延迟R、后续正常返回。上述只是完整接口的验证，图幅不降。

对应 RP01/02→事件账/数学全字/地址与长度；RP03→Q门与通知保持；RP04→物理/应用分账、held数据及冷reset。源码TB/reference/runner/project读序遵循v1。独立ledger额外验证显式场景覆盖和计数，不以“工具退出0”当PASS。若查出源行为违约先短卡，不改期望掩盖故障。

## 基线与限制

原8 SHA逐个核现有冻结文件，本T1第9份新增冻结副本；旧v1不改，原七文件计划/三依赖不改。当前只有compile/elab已通过；本T1不声称仿真/综合已做。理解验收待用户实际回答。保存、读回、呈现后才补六份可执行文件。
