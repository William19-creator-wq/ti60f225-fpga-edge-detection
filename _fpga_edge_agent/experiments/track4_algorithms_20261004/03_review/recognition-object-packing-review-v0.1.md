# 识别记录打包静态检查（v0.1，2026-10-05）

状态：LOCAL_DOCUMENT_REVIEW / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。入口是[PK设计卡](../../../planning/design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md) → [打包字典](../01_baseline/recognition-packed-record-map-v0.1.json) → [原槽位JSON](../01_baseline/production-slot-layout-v0.1.json)。本报告只证明静态几何和文档边界，不能代替功能/物理验证。

| 本轮产物 | 行数 / 字节 | SHA256 |
|---|---|---|
| PK卡最终版 | 134 / 20,844 | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 |
| 打包JSON | 1616 / 32,617 | D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
| 原槽位JSON（未改） | 395 / 11,516 | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 |

## 1. 实际检查范围与结果

字典共26类对象、32实例；D7工作集为对象2…25的24表（一份当前RECORD）、private为21表。EDGE/GRAD属于只读输入，不混入D7的工作集总和；三份历史RECORD不重复清零。每实例base、logical_bytes、physical_data_end及slot_end/guard与原槽位逐字段相同；五份来源哈希匹配，不能从这些地址获得运行许可。
连续位打包及容量有限的余128偏移列表相符；FIT_STATS仅16项，最大offset105→3单元；VC最大112→4单元；当前所有记录最多4个128bit单元。该上界依赖当前宽度、容量和64字节对齐基址，不是通用未对齐64B请求的上界。
独立复算五项预算：逻辑17,526,269B；整表round16为17,526,288B；当前round64为17,526,400B；逐record补整字节19,100,956B；逐record补128bit槽67,380,480B。后二者仅比较，不采用；128bit逐record方案使POINT和ANN各需33,177,600B，不能沿现有16MiB/512KiB槽。
已核POINT基址0x04340000会被旧26bit接口截成0x00340000；s/e42bit、先真实容量再33bit末端核验、最后32bit地址的顺序相符。未检查的32bit index不能先截成33bit偏移再相加。
DENSE67 s1407/off127→2单元；VC7 s2800/off112→4；FIT15 s3945/off105→3；NMS1107 s23247/off79→1，整表23268bit使末字节高4bit为零。HIST658首字节87,318,527 mod4096=4095，32B对齐跨度[87,318,512,87,318,544)跨页，需两侧合法16B请求。
全工作数据round64清零候选17,526,400B对应1,095,400个16B单元/273,850个64B段；它尚未选为实施策略，尚无真实清零/完成或时间保证，guard不属于数据。

## 2. 读回与独立审阅

Root实际全文读回初卡1…135，最终定向读回46/50/63/64/95及实际hash；最终134行与初卡的末尾空行差别不增加语义修改。JSON通过完整解析、全部26表/32实例关键字段及全部余128列表投影阅读；Root没有宣称逐行全文阅读JSON。
独立读者 production_directory_numeric 实际初卡1…135、JSON1…1616（截断段739…908补读）；质量数值读者 quality_recipe_static_counts 实际初卡1…135、JSON1…1616四段无截断；协议读者 load_grad_point_pin_review 实际初卡1…135、JSON全部字段解析。初卡hash为18EA8C9102F02881F4D539D75D486DF6F1DAB420D98F57BC06C1ED91CEE1A51F，JSON始终D403…0A51。
协议审阅提出两项具体澄清，已修订：只有RECORD COMMIT携F，POINT/ANN payload全零；取消封尚未published新组，旧held RQ799/NUM622/RSP872继续原握手且同沿先记旧fire。同时精确写明stage_index2值2/REGISTER schema8值3不为lookup新增字段，并具体写NMS末项期望。
最终版本由语义、协议、数值读者分别作有限定向复核；实际最终hash为50ED…A771，未发现确定缺陷。最后定向检查不冒充对最终全卡重新全文审阅。审阅结论只支持保留NOT_READY，不支持wholefit、批准或实现。

## 3. 未完成与授权边界

PK-B01：完整逻辑和rounded物理许可、SC桥、初始化/前缀与SEAL/COMMIT管理能力。PK-B02：最新值、跨单元记录写及DENSE16组、journal/同沿取消/回声捕获和partial/UNKNOWN关闭。PK-B03：匹配实际DDR的写后可见性及无后续副作用证据。PK-B04：时钟、FF/RAM/DSP完整实例及服务时间账。全部OPEN。
BK ordinary仅16B、CLEAR才16/32/48/64B；旧RQ324/RSP449、CLASS/QUEUE两槽journal不是RC799/872实现。部分写不能假回滚，pin/access关闭不能代替O退休；未初始化邻位不能靠第一条POINT写猜值，也不能等下一条item来凑满一个物理单元。
已批准R1继续保留原交付；R2/Q0尚无新的指定批准答复和work，原R1本地审计例外不扩到新业务范围。没有新增业务源码、C++参考、功能脚本、TB、编译、仿真、综合、布局布线、时序、bit或硬件动作。
本轮对R1 22份、R2 48份及Q0 44项重新逐字节/哈希核对，0不一致；10项正式/交付/bit/hex守护项、8份旧闭包/DQ/R2文档和五份字典来源未变。正确数据库环境键FPGA_AGENT_DATABASE_URL仅检查配置存在性，仍未配置；数据库、正式Manifest/项目状态/任务账和原资料没有修改。
控制面元数据写入曾因Windows长命令被CreateProcess拒绝（错误206），未创建进程或文件，确认不存在后改用apply_patch保存；另一次元数据采样对R2不存在的tools调用GetType报错，随后定向读取files/root成功。二者均为控制面诊断，没有执行业务设计或产生未审实现。

## 4. 有限下一步

沿既有槽位闭合RC对象适配的权限/初始化/最新值/原子组与失败证明，再加入实占片上缓存、journal和时间预算，完成READY门槛后呈现指定审批。已有R2/Q0待答问题保持，不重复；不把十一项完整目标标完成。当前交付的是“如何放置记录”的可核对字典，真实“如何访问及可靠完成”尚待实施设计和验证。

