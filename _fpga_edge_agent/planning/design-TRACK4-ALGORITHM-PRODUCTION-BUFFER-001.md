# TRACK4-ALGORITHM-PRODUCTION-BUFFER-001：连续采集与实际DDR/行预取联合候选 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED。先B整体→C职责→D交接/资源→E中文操作→F映射→G/H验证追踪→I缺口。目标仍完整1080p、五基础六高阶、完整Canny及原识别质量；不指定降低camera或处理fps，不使用外接存储/PC生产计算。

## A. 计划字段、来源与允许行动

- Goal：解决camera不得等慢算法/冻结/OBS的准入冲突，并把完整显示行和算法bytes映射到真实DDR候选子集。
- Current state / Gap：现六immutable SRC包含CAP/LATEST寿命，独立OBS满槽或上一CAP迟关闭均可能错过下一SOF；BR-P单pair至少三core沿不够1080p60。真实DDR端口存在、参考综合PASS，protected内部服务、校准及B后可见性未验证。
- Target：独立有限采集ring、真实import、有限行预取/响应存储、服务/关闭与资源可统一检查，再吸收到整包成熟版本批准。
- Assumptions：六immutable SRC/三结果/单J/单scratch、两个不同物理视频bundle保持；新ring是额外板载DDR容器。core100全局候选有现工程来源，不能替代时钟关系/STA证明。
- Open questions：PB-B01…05。服务期限、producer参数、完整消息/cache/FSM不是凭容量自动成立。
- Dependencies / Artifacts：下表及[纯数据算术](../experiments/track4_algorithms_20261004/01_baseline/production-service-arithmetic-v0.1.json)，2261B / A560EABBB60E1B2998DE06A9929A80918E603462DBFA39056E2FAB565E3AF732。原布局不改，本数据不授runtime grant。
- Milestones / Detailed steps：实际边界反例→独立capture存储→COPY/历史身份→真实AXI子集/行搬运→期限及native容器→联合局部/接口/资源/GT冻结→整包READY/指定批准→work实现/软件验证至bit。
- State transitions / Validation：仅设计/纯数据/实际只读审阅；功能/工具NOT_RUN，不改正式状态/DB。上一目标轮为PROGRESS：PROFILE-SOURCE/布局/审阅、整合v0.6和追加事件已实际保存；没有仍在运行的构建handle。
- Failure handling：无ARM、FIFO overflow、受损/未封存帧不计采集成功；COPY错响应/不完整关闭保留实际债务/Q；固定扫描欠载仍为失败。
- Human approval gates：旧v1.2有限预检不包含本文业务、模型/TB/新构建；本文未成熟，不申请泛化批准。原v1.3/Gate待批准输入不改。
- Rollback / Completion criteria：只新增控制面文档/数据/审阅/追加记录，旧合同保持；完整完成须真实十一项源码/仿真/综合/PNR/STA/bit，不能以本文交付替代。

| 来源 | 实际SHA256 / 采用范围 |
|---|---|
| [PRODUCTION-IO v0.2](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10；camera无ready、ARM/CLOSE、row/clock与固定扫描 |
| [PERFORMANCE v0.2](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469；容量/原子层/工作量与DDR平均预算 |
| [PROFILE-SOURCE v0.1](design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103；逐lease不可变SRC、策略/冻结、六槽反例 |
| [SLOT-JOIN v0.1](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) / [旧布局](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json) | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA / 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75；84.25MiB固定旧对象，不含新ring |
| C2既有work peri / SDC / top | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B / 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF / 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9；真实100MHz global core来源/DDR同net连接，不继承旧宽泛exclusive约束 |
| 0927更新v1真实DDR及master | 本轮实际文件hash/行号见[审阅证据](../experiments/track4_algorithms_20261004/03_review/production-buffer-review-v0.1.md)；protected边界不解密、不据端口猜内行为 |

## B. 整体行为及反例

PB-REQ01：正常camera每帧完整RAW10/插值/数量/CRC及DDR写封存独立处理，camera不等待J、FREEZE、OBS或旧VIEW。基础灰度/窗口/中值/Sobel仍需行流水和真实吞吐，ring不代替其证明。

REQ02：慢后端只选择已经完整封存的候选camera图；未选算法帧、camera失败/无ARM、FIFO溢出、COPY失败分别统计。LIVE latest是选择策略，不是接收端丢帧许可。

REQ03：ALG_IMPORT完整copy形成不可变SRC后才进入SOURCE311/J/BIND；FREEZE_FALLBACK_IMPORT完整补源后交匹配FREEZE lease/实际应用，不创建J。F/OBS/bundle只借immutable SRC，不长期pin循环camera ring。同一capture重复copy不能伪造新输入无限重算。

REQ04：固定1080p60行按完整历史PLAN/render、同源RGB/EDGE/ANN预取/渲染；不把旧单pair OUT或平均DDR峰值当生产服务通过。

REQ05：所有ring/COPY/AXI/row请求、响应、pending、资格及关闭均有限且保持真实身份；未知effects不授复用，所有新结构纳入QUIET/START与全预算。

正常ALG走查：提前保下一CAP真实reservation→旧ARM保存ACK→下一SOF接入独立ring→完整写与receiver closure→真实SEALED/latest→J可接纳且目的SRC空/服务预算齐才ALG_COPY pin→完整6220800B读写/封存→返ring pin→注册SRC→原SOURCE311/算法/VIEW路径。冻结补源另按D2/FREEZE_FALLBACK资格取得匹配F lease；camera继续用其预留槽，不等这条慢路径。

反例：旧3B/F/L/独立OBS满六，或上一CAP等迟CRC/B/CLOSE，原合同可能无ARM；不得称算法skip。三ring还可同时需要writer/closing/latest/COPY四槽。四ring若列这四角色却免费加下一ARM reservation，仍有第五需求；容量与期限必须一起计。

## C. owner、对象与路径

CAMERA_RING_OWNER维护环槽writer/封存/代次/真实引用和下一CAP reservation，LATEST_RING_OWNER只指完整sealed ring；不写CONTROL/J或分配O结果。IMPORT_OWNER最多一个COPY，按D2的ALG或FREEZE_FALLBACK目的分别检查准入，并保持camera优先服务；O/SRC_PROVIDER仍独占immutable目录/注册/逐lease。后续SOURCE_POLICY选择immutable LIVE/FROZEN，VIDEO snapshot/FREEZE仍按实际APPLIED来源。

DDR_PHYSICAL_ADAPTER只答真正bytes/响应/effects，STORE原CLAIM_APPEND/DENSE/latest/phase/commit仍在FPGA。BULK_FETCH按O实际planes授权，ROW_RENDER按既有数学形成三rendered RGB row。观察、F/历史bundle不得直接授ring长期持有；独立控制/CLOSE/错误槽不依赖数据队列空位。

数据：camera→独立ring sealed→有界IMPORT→六immutable SRC→完整算法/三结果→两物理视频bundle→bulk/input row→renderer→三output row→固定scan。基础line FE从真实camera支路处理，与慢整图执行区分；支路逐沿和容器仍PB-B04，不预称已有实现。

## D. 容量、交接和物理候选

### D1. 明确采用五ring容量候选

五ring每份8MiB追加旧84.25MiB之后：[0x05440000,0x07C40000)，总130285568B=124.25MiB；128MiB arena剩3932160B=3.75MiB，板载物理256MiB不变。四ring116.25MiB为比较方案，不采用其免费future reservation证明。选五槽仅容纳writer1/closing capture1/latest sealed1/COPY pin1/future ARM reservation1的条件峰值，**closing≤1、代次返还和预ARM期限仍必须有真实服务依据**，不能由槽数倒推。旧LATEST替换关闭、受损槽隔离或其它readers超出这些角色时必须计入，不能暗造第六ring。异常Q可停系统，正常验收不能发生该停机。

新ring与六immutable SRC是十一份物理图容器，索引namespace不同；旧global SRC6口径显式覆盖。原SRC/AUX/guard区域及8320bit PROFILE实体不改，新ring的目录/guard/控制预算另列；OPT-H1再增0.5MiB未默认吸收。剩余3.75MiB不是已授权匿名空间或完整预算通过。

RING_CTX候选283bit＝epoch32/capture_id64/ring_index3/ring_generation64/camera_cfg_generation64/link_session32/W11/H11/phase2。index0…4合法，5…7拒绝；所有序号先扩位检测耗尽。ring physical handle和immutable source_handle不可cast。SEALED/ARM/COPY/close/cache完整族尚PB-B02；现CAP_ARM280不能静默以此新body替换。

### D2. IMPORT与历史身份

共享单COPY的目的为2bit：0＝ALG_IMPORT、1＝FREEZE_FALLBACK_IMPORT，2/3非法。ALG_IMPORT仅旧J可接受、scratch空、结果信用/终态及目的SRC/运输预算成立才接纳；FREEZE_FALLBACK_IMPORT用于实际NO_ACTIVE冻结补源，只依真实冻结意图/完整请求身份、目的SRC空、camera reservation与运输/服务资格，不等待J/source admission_gate、scratch或结果信用，也不预分配J/O结果或制造JOB_TERM。二者都必须先保下一CAP真实reservation，并证明到各ring reuse deadline的服务可用；共享单COPY不允许同时接受两个目的，不能为COPY延后SOF。接纳时pin完整capture origin、ring generation/封存、目的ref、目的及实际旧策略/冻结请求与CFG/PCTX身份；冻结意图不可被后来的shadow配置替换。

完整低地址RGB bytes读入目的对象；真实读响应/写响应/同源数量、B后可见性资格和write commit皆完成，先关闭COPY读/返ring pin，再注册immutable SRC。ALG目的才按后续SOURCE311准入；FREEZE_FALLBACK目的交给匹配实际冻结请求取得FREEZE lease，不能因source admission_gate已关而阻止其补源，之后才能完成实际冻结策略应用。失败保留实际前缀/UNKNOWN与已issued effects；不能借取消reset清空引用。策略变化依旧held履约，过时未注册候选真实退休；RESUME具有独立取消/关闭记录，可取消等待或在途补源，仍须履约旧held、排尽真实读写和返pin，不等待一个从未创建的J终态。完整目的消息、响应/cache及QUIET矩阵仍PB-B02。

capture_key、camera CFG/link历史代表输入；source_id代表不可变对象；copy_seq代表搬运；job_frame代表执行。工作去重签名要包含完整capture origin/CFG/link和算法CFG/PCTX，不能只靠新source_id导致同capture反复复制。具体完整origin字段/签名和“explicit recompute”联合入口尚PB-B02；原161bit签名被此需求显式覆盖，不能直接接新SRC后仍称去重闭合。

每copy读+写12441600B。必要平均式：1.6GB/s×η > 419904000 + 6220800×f_camera +12441600×f_copy +其它真实流量。camera60/copy60仅条件例，已需1539648000B/s、η>96.228%，未计算法/refresh/rowmiss。copy fps不得默认camera fps，也不据此新设处理1fps验收。

### D3. 实际AXI子集、错误与关闭

公开原master采用128bit/SIZE4/INCR01/ID0/全WSTRB、byte地址、常规LEN127及4KiB拆分；实际slave mask/排序/可见性/校准前接纳隐藏。本文先选16B对齐全拍、最大128拍、逐4KiB拆分、一个已issued物理burst的保守候选，后续若需并发要显式改合同，不从ID4推16并发。未issued队列/服务类别另设有限容量；相机/显示期限必须证明该序列化选择够用，否则在实现前修订，不把低吞吐默定为成功。

一份独立R_ROUTE_CTX在AR提出前锁定旧完整owner/请求/对象/plane/地址/计数/目的，held AR也保持该身份；直到该burst全部RX、RE pending、holding、decoder引用已实际移交给具有独立身份的使用者，再无旧引用，才可释放并允许下一AR。末R仅结束物理响应，不释放仍被缓存引用的route；RX空位足够也不能覆盖旧route。R_ROUTE释放不等待整行READY或整个COPY commit，否则同一行/COPY的后续burst会自锁。物理读响应结束后，COPY目的AW/W/B可以在旧route仍排空时推进，但独立W_CTX及其holding不得覆盖旧R_ROUTE或依赖其先释放；数据真实交到W holding后才解除对应读引用。R/W context、pending和holding均另计PB-B04，若需多历史读route必须另修有界队列及每拍绑定，不能暗增并发。

算法1…64byte可覆盖最多5拍。全WSTRB读改写仅在同对象已初始化rounded span、整个span排他、无immutable写冲突时执行，保留邻byte；不跨guard/别对象。O授权和锁必须覆盖所有实际camera/import/video/算法访问者，而非只锁该caller。窄WSTRB未证明前不默认启用；原upsizer成员的代码不能当活动slave证据。

匹配BID/BRESP及全部W计数/LAST，匹配RID/RRESP/拍序/LAST，正确回复和held消费分别登记。W最后fire/旧bank_sw不是提交；B后可见性、全部旧effects已结束需要实际IP资格验证。没有公开drained/fence证据，不能凭队列空或一次读回就证明无未来写入。known read错误不发布数据，无法确定实际写入范围则UNKNOWN/written0并隔离；超时只能停新业务/Q，不能制造settled或归还。校准/健康失效阻新访问并保留旧债。

### D4. 全行搬运与新增native容器候选

mode5完整行RGB5760B/EDGE240B/ANN480B＝6480B＝405个16B数据拍。地址基址4KiB对齐时按128拍/4KiB拆分实际遍历1080行：RGB最多4burst，EDGE2，ANN2，总最多8，y34/187/750确达8；row0为3+1+1=5。**405拍不能写成所有行仅五个burst**。数据拍理想4.05µs/core100与renderer960pair理想9.6µs是不同资源尺度，不能简单相加或相减得实际期限通过。

新增两个input row bank，和既有三output rendered row独立。每input RGB存360个128bit拍：七lane各20×512，逻辑地址0…359，128bit加高12零成140，七WE可同沿；EDGE120个16bitword、ANN240个16bitword各一WIDTH16/depth512 RAM10，合法逻辑地址分别0…119、0…239。各native剩余地址不得因物理depth512而读取。每input共9RAM10，两份18；RGB renderer用有界预取缓存解决48bit pair跨128bit拍，EDGE/ANN用packed16bit缓存提取2/4bit pair，不逐pair读改写这两plane。每块只在完整本行封存后供renderer，读pending/holding关闭后归还；完整decoder/预读沿表仍PB-B04。每行实际input word写事件为360＋120＋240＝720，若串行每沿写一word需按720沿计填料；405仅是AXI数据拍，不代表容器写次数或decoder已达期限。

共享物理R响应缓冲候选depth128、每项RDATA128/RID4/RRESP2/RLAST1＝135bit，加高5零为140，用七20×512 RAM10。逻辑索引7bit为0…127，native R/WADDR9bit上两位固定0；8bit occupancy只表示0…128数量，不能拿来访问地址128。native余128…511不得读。发AR前除整burst≤128及consumer holding预留，还须满足D3旧R_ROUTE真正无引用与物理burst资格；正常burst内连续接纳R。RGB/EDGE/ANN写row解码可暂停，真实RX pending/holding也计入容量；其RE下一沿捕获，不能把新Rfire直接穿透到row READY。一次物理burst与全收料预留降低对slave任意R停顿的依赖，不能代其错误/超额响应/关闭资格验证。B响应/control不挤入此数据FIFO。新增18+7=25RAM10仅列出的payload存储；当前holding/FSM/目录/端口/错误/close另计，不宣称全机fit。

上述容器均读写同宽、OUTPUT_REG0，完整entry写时WE＝11：WIDTH20的两个WE分别控制10bit半字，WIDTH16分别控制8bit半字。不能把AXI逐byte mask直接接20bit WE；RGB高12零与RX高5零随真实entry写入，未初始化尾地址无valid授权。实际native模型DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33的有限数值审阅见审阅报告；同址读写没有获授。

三output row的15RAM仍按PIO原RGB48 packing，不能与input18或响应7重叠累计假省；新bank不凭容量授第三物理视频bundle。current/next期限优先，candidate首行只用不影响期限的资格。在每行14.8148148µs的期限预算内还要计首次预取、8burst命令/turnaround、FIFO解码、960pair、row发布/CDC和归还；全部服务曲线仍PB-B03。

### D5. 真实clock候选

C2 peri中的MIPI_TX_PLL/PLL_TL0以25MHz参考、core_clk output0/20/gclk，SDC声明10ns；top的DDR axi_clk/core_clk均接该core_clk。这提供一个已有全局100MHz来源候选，不再采用DDR_PLL#4/rclk硬改gclk，也不默改DDR ASYN1。400MHz PHY另由DDR_PLL产生；两PLL同参考/同名义频率仍需核gear/phase/CDC及实际约束。HDMI USER_PLL相关74.25/148.5/742.5、camera byte/pixel及原电气来源保持独立；旧exclusive全clock分组不得复制为新STA通过。本文不生成peri/SDC或更改获批C1。

## E. 中文操作草图

PB-OP01 冷建立：清资格→核真正PLL/DDR初始化/校准及来源版本→建立ring与独立immutable目录→预留真实下一CAP槽/控制关闭容量→跨域保存ARM ACK→后续SOF接纳。不以LED或相机stream-on代cal_done。

OP02 连续采集：旧ARM命名ring→RAW10/历史CFG/phase处理、基础FE独立支路→实际WE计数与水位→RGB canonical写ring→迟CRC/receiver/consumer/write关闭汇合→真实seal/latest。下一ARM有独立reservation，不等慢J；旧closing数量/期限须先证明，异常不覆盖。

OP03 选择导入：先保camera下一reservation和服务→核ALG或FREEZE_FALLBACK完整意图/目的SRC空→ALG另核旧J/scratch/信用，冻结补源不依赖已关闭source gate→锁目的/完整origin/旧PCTX/独立copy_seq与目的writer→whole RGB读写→核响应/效果/封存→读CLOSE/返ring pin→注册SRC→按目的交SOURCE311或匹配FREEZE lease/实际应用。每个阶段取消先旧fire，再禁止新issue，held履约，未知Q；RESUME独立取消并真实收尾，不造J终态。

OP04 物理读写：核logical与rounded权限→byte地址先33bit加法/范围检查→按16B/128拍/4KiB切分→旧R_ROUTE无引用/物理资格/空RX整burst预留→锁历史route后AR held→逐R核ID/RESP/LAST/计数入缓冲→RE旧值/下一沿捕获→按旧route分发decoder，全部实际移交才释放route/允许下一AR；COPY写有独立W context/holding，在旧读物理响应结束后可推进，不能等整行或COPY commit释放route。写保持AW/W并真实B结账，不能以末W造done。

OP05 行生产：锁历史planes/row→填完整input RGB/EDGE/ANN→真实末写/pending关闭→renderer预读旧缓存并逐pair输出三outputbank→末WE和读关闭→原ROW READY跨域→固定scan采用/消费→真实bank归还。吞吐和服务不足需设计修订，scan不等待。

OP06 冻结/恢复与epoch：长F/OBS/B保immutable lease，不保ring；NO_ACTIVE走FREEZE_FALLBACK_IMPORT补源后取得真实F pin，再完成匹配冻结的实际应用，source admission_gate关闭不阻断该补源。RESUME不等待新J，依独立取消记录履行旧held并退役COPY。旧COPY/RAW/row/APPLIED/事件及R_ROUTE/W_CTX独立排空后才QUIET，授权START隔离旧ring/SRC/profile；不单端清FIFO、不清未知effects。每一真实reservation/pin需在目录中定位，不用同宽handle代替。

## F. RTL与三份对应

SV2009候选。core posedge沿前valid&&ready且非rst为fire，RE下一沿捕获，新接纳不穿透；所有packet/body/sideband held，invalid不推进像素，复位/取消保旧承诺。byte地址32加length先33，ring index3拒5…7，COPY purpose2拒2/3；RGB地址9拒360…511，EDGE地址9拒120…511，ANN地址9拒240…511；RX索引7零扩到native9，上两位0，count8可表示128且不充当地址。序号/generation64扩65不回绕。WIDTH20/16分别控制10/8bit半字、完整WE11、读写同宽/OUTPUT_REG0，padding每entry真写零；单块一读一写，未授同址读写。历史R_ROUTE和W_CTX独立且计holding，不因末R/容量空位提前改身份；跨域bank只在immutable交接，相关视频另核真实相位。

数学：原RAW10/灰度/中值/Canny/几何/overlay位规则不改；IMPORT只复制RGB bytes。硬件：按CAP/ring generation/COPY/SRC/J/PCTX/PLAN/row/AXI真实fire/effects/close核对。对应：独立黄金从原camera image/profile生成，未选/错误帧仍分别统计；DUT ring/COPY日志不能生成GT或替代全图比对。Python参考/scoreboard只在完整批准后生成，当前无实现。

## G. 实施与验证计划（全部NOT_RUN）

先闭合I/共同schema/局部及资源/服务，获指定整包批准后work实现camera_ring/import/DDR adapter/rx_fifo/bulk_input_row/decoder/renderer/事件及独立模型/TB，保持完整十一功能工程与bit目标。当前不得生成这些生产文件。

| TEST | 输入/事件和判断 | 关联 |
|---|---|---|
| PB-T01 | 原6 SRC满含长F/OBS，camera独立ring持续帧；无ARM/overflow与算法未选分别核 | REQ01/02，OP01/02 |
| T02 | 五种不同ring角色/提前ARM、closing跨下一SOF、COPY占最老槽、未知Q | D1条件界/真实复用期限；无默认closing≤1 |
| T03 | 同capture重复copy、新CFG/PCTX/明确重算、NO_ACTIVE关闭source gate后冻结补源、补源中resume/reset/held取消 | ALG/fallback目的相容；冻结不等J信用/scratch，不造J；origin签名与held/真实退役，不凭新source_id造新输入 |
| T04 | 最长128beat、跨4KiB、最后物理byte、logical64非对齐、邻byte/guard/immutable | fullmask/RMW权限与33bit端点，无越权扩写 |
| T05 | B/R错ID/RESP/LAST/拍数、早/迟响应、校准前/丢健康、B后读、暖取消 | 真实effects/可见性资格和Q，不以旧bank_sw/timeout成功 |
| T06 | 全1080行独立burst数量、y34/187/750、全部mode/SRC/EDGE/ANN/低lane | 等独立bytes与renderer数学，405数据拍与最多8burst分开 |
| T07 | RX128满/两holding预留、RGB跨拍/EDGE8pair及ANN4pair字界、尾地址/WE/padding；旧RGB末R后decoder停留16拍而新EDGE有空位 | 下一AR仍等旧route无引用；不同R/W context可真实推进，不等整行/COPY commit；405数据拍与720word写分计，无同沿穿透或未初始化读取 |
| T08 | 最坏camera到达/AXI等待、COPY与算法竞争、两row与candidate、row CDC | 冻结服务曲线后按真实期限/全行ready，无正常欠载/溢出 |
| T09 | 真实clock/peri/pin/全core实例、RAM/FF/DSP/PNR/STA/bit与完整功能质量 | 整包真实报告，小top/常量/旧bit不代替 |

## H. 双向追踪

REQ01/02→CAMERA_RING/LATEST/base FE→D1/E01/02→camera_ring/capture/front-end计划组→T01/02/08；REQ03→IMPORT/O/SOURCE_POLICY→D2/E03/06→import/origin signature/lease计划组→T03/05；REQ04→DDR/bulk/renderer/scan→D3/4/E04/05→physical adapter/rx_fifo/input_row计划组→T04…09；REQ05→全部目录/closed/QUIET→D/F/E06→共同schema/预算/独立scoreboard计划→T02…09。各新数据容器反向只承担真实采集、复制、供数或关闭，不新增算法缩减和主机托管。

## I. 未决门槛

| ID | 必须补齐 |
|---|---|
| PB-B01 | 真实DDR slave合法访问子集、128burst/R连续响应、B后可见性/旧effects关闭、校准与PHY/clock关系；匹配器件/工具依赖仍缺 |
| B02 | ring reservation/SEALED/COPY/返回完整消息/cache/错误矩阵/目录/FSM，ALG/fallback实际意图与独立RESUME取消，capture origin去重签名及SOURCE/FREEZE/QUIET联合版本 |
| B03 | 真实camera速率/最大突发、ARM/receiver/write closing/reuse截止、COPY最低份额/最长服务、所有显示行deadline；不得默认closing≤1 |
| B04 | 基础line FE的完整吞吐支路、input RGB跨拍预读/packed plane/720word写/renderer逐沿、R_ROUTE与W_CTX完整字段/holding生命周期，以及全部RAM/FF/DSP/PLL/端口预算 |
| B05 | 新区域/文件/schema/GT/工具/约束共同基线、整包独立复审及指定批准/治理前置 |

§10.3无当前阻塞仍不满足，保持NOT_READY。本候选关闭的是反例归因与具体容量/搬运方向，未关闭B03或五类工作，未证明全部FPGA可实现。

## J. 显式覆盖与恢复

本稿拟覆盖旧“六SRC包含所有camera存储”为六immutable加五独立ring；旧CAP结束后才下一ARM改独立future reservation/closing；SOURCE LATEST来自immutable import，camera latest在ring内部；原161bit source签名需加真实origin；PIO新增input18/RX7不隐含于原output15。原数学/质量、逐lease、真实credit/BIND/COMMIT、两物理bundle/三结果不变。候选变更均未获实施批准，旧数据/局部原字节保留；完整相关合同吸收后才能直接接线。

初稿A056148B067D371F96D1CFE585AD9EADD57998C55FB30D2C8D38DF0B09494EFF/21378B的实际协议全文审阅发现两项交接缺口：NO_ACTIVE冻结补源若与ALG共同等待source gate/J会互等；末R后旧RX decoder尚持数据，空位足够仍不能更新唯一route。保存[初稿原字节](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001-v0.1-before-import-purpose.md)，本修订据此分COPY目的、独立历史R/W context，并按有限数值审阅补尾地址/WE/720word填料。修订只关闭所列反例表达，完整FSM/预算/服务仍未关闭；实际新版限定复核与输入hash以审阅报告为准。

## K. 实际记录

本轮实际只读控制面/Manifest、当前候选、C2 PLL/SDC/top及v1 DDR公开边界；独立审阅确认六槽/迟关闭/future ARM反例、公开全WSTRB主机与未知slave语义。1080行burst与容量/平均流量仅静态算术，纯数据已全文读回；实际限定审阅另存。没有新业务源码、功能脚本/模型/TB/work/工程/约束、仿真/综合/PNR/STA/bit、网络/安装/硬件或正式状态/DB更改。原有限v1.2终态与待批准v1.3/Gate保持。

## L. 阅读与下一允许行动

先B连续采集与慢选择的不同要求→C唯一owner→D1实际新增ring/条件容量→D2 import身份/成本→D3真实DDR边界→D4行burst/native→D5时钟→E逐步流程→F/G/H→I具体未闭合。继续纯设计和有限来源/协议/预算核查，成熟后统一提交指定版本；本文不能作为先写代码后补设计的授权。
