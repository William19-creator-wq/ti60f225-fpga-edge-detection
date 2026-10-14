# DDR Q0 输入闭合与资源边界复核 v0.1

2026-10-05，纯文档、文件身份和有限静态加法复核。本轮没有新业务代码、可执行测试、仿真、EDA、比特流、联网、数据库或硬件动作。旧 R1 软件验收保持；完整五基础/六高阶尚未完成。

## 1. 可供批准的下一步

[Q0短卡v1](../../../planning/design-TRACK4-DDR-Q0-001.md) 已收敛为独立 `ddr3_top` 编译→合法展开诊断，READY_FOR_REVIEW／NOT_APPROVED／NOT_RUN。最终108行/19135B，SHA256 C71025F22C68E29858C57175E9976924D063A2BCE52BE1FBEDA8FD531467087D。它不要求先准备 DRAM 模型、TB 或 PHY 时钟刺激，所以可先解决工具/保护支持和隐藏实例绑定是否可用。通过只证明所冻输入合法编译/展开，不能证明实际初始化、读写、无未来访问、全资源或帧率。

[基线DDR-Q0-BL-20261005-v1](../01_baseline/ddr-q0-baseline-v1.json)，435行/18520B，SHA256 9460D055EFDD83D228F05DAB28632DDFFCE785CB096F84C288800F218B56A4E1：31文件=14 DUT .v+参数头1+vendor .v15+INI1，另4工具入口+9上下文，共44项。本轮逐项bytes/SHA全部一致，复制target无重复；新Q0 work不存在。参数/源不改，使用新库、过程局部INI、vopt合法观察，不调用vsim、推进时间或补依赖重试。

独立读回发现并修正两个问题：①原候选把live Manifest冻为输入，而批准登记必然改它；现改为[不可变审批前快照](../01_baseline/ddr-q0-approval-manifest-snapshot-v1.yaml)，live另外核真实指定批准与有原始授权的合法scope追加，不接受任意规则变更；②JSON中过宽的ENV_FAIL已收窄为有直接环境证据才成立，普通设计诊断不能被吞并。未批准v1草稿修订不改变任何已批准输入。

根先全文读初稿108行，再全文读最终语义稿108行/C2FAEC…；末尾只改L102引用§7→实际§10.4，根定向读回并核真实规范468–499。两位独立读者 production_directory_numeric 与 load_grad_point_pin_review 均实际全文读语义稿108行/19132B SHA C2FAECABFD22C1B9CA5F720435ACC1BAC0B8813170CDEE716D22BE0B01AF4FAD及最终JSON435行，逐44项0不一致，支持本Q0范围READY。最后引用更正不改执行合同，最终定向复核另留本轮检查点。旧DDR资格卡2C6B…保持，Q1–Q3仍OPEN。

## 2. 原控制器与资料能证明的事实

下列C2路径在 `work/active/track4_ip_precheck_20261004/C2` 下；旧参考工程只读。根读实际top公开1–192、参数头全文54、XML1–65和真实SDP全文67；独立资料读者有限补读公开MC端口、top接线、原说明文件。范围不冒称全工程功能验证。

| 真实来源 | SHA256 / 实际有限事实 |
|---|---|
| C2/rtl/ddr3_controller/ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A；Elitestek v1.1、公开五通道B/R、maintenance与cal_done端口；不读L193后保护体 |
| C2/rtl/ddr3_controller/ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80；ROW14/COL10/BANK3/DQ16/DQS2、ASYN1、CK_RATIO4、CL6/CWL5 |
| C2/rtl/simple_dual_port_ram.v | 01B74E74D39C4E4AE380BC7BE73329987B17FFFAEA58BC7C92A9B24E4A110C5D；真实选入源67行/1440B，RAM_INIT_FILE默认空，非空才readmem；注释默认0不等于仿真数组已赋零 |
| C2/ti60f225_oob.xml | D67BFF492FDE948FDA71B8A9905218B6A5A07E7CA6BFA278CB266E0140299DE8；L14–28选真实SDP、13个DDR .v及参数头 |
| [旧DUT日志](../../track4_full_sw_20261004/05_reviews/ip-precheck/C2-questa-DUT-vlog.log) | E96838F68E478EAAC83B8DB17E149FE8CAD2EC00ADCC2FA2A1F727EE6B43849B；根全文83行，DDR模块编译后旧CSI三错误；没有独立DDR展开结果 |
| [旧vendor日志](../../track4_full_sw_20261004/05_reviews/ip-precheck/C2-questa-vendor-vlog.log) | 1B22EA9AD5B8FC564130C19A69DF90D7D420FDD95975DB7B7F9CC65B14E8CE10；根全文62行，15模型旧当次Errors0/Warnings0 |

独立资料核查：原0927板说明PDF SHA15800EEBCA75C067DE5CD68988A011A69A2976A7AA72B3315542DF6C8B258719仅文本24–29（中文提取有缺字、不作图片布局断言），给器件/几何/800Mbps；原frame_buffer调试总结docx SHA913A52A6F418EF8CBBA87053FD97C27C8A7BD69D2456E0AE70F92FA113E56FB4全文10个非空段落；原readme SHA0FFC7F859850D033529912FEBC39BFDA64E507A67B7E17F30D269B1D51BB2298全文117行；DDR zip SHA CAC8F9BBD296D712D407FDF5FF943BF8305E7DC142D9D62E511491121C0B9D56列22成员。都没有匹配此IP的B可见性、reset drain或no-future保证。原zip只含16源码及6目录，不补出缺失器件模型。

MC公开端口也只支持观察候选：axi4_bus_ctl公开1–100、local_bus_ctl1–80、memory_bus_ctl61–136未定义独立write-completed/drained/epoch ack；C2 top接线332–366/590–636/659–718/802–838 maintenance req全0，cal_done接出，复位来源PLL锁定。不能把accept/ready/empty、app_sr_active或cal_done高直接当隔离证书。

本机Efinity generic帮助文本仅作差异证据：hlp-ddr3-soft-controller SHA1394771103FEB7A9FB46724DC0CCB47A9A25AD6EE7EB65295EDCCAEC5D8BBE34；fd SHA8F6DF6DAF9A3F462BFFFE8D4A0AD5DCA30971407ECAB390016D0EEF3F8DA332A；features SHA3C49D3ED152EF786D41BCDBDE1AA556A7D86AEB6701A5BEBECFF5E46FDC9D276；params SHAA8579D107D3FC42C3F46225FC3BF5D1AB8B3FB1DECE9F37D6ACA6383C3ECA255。根实际从HTML剥标记后的关键词定位文本核对，未称完整手册语义审阅；所述generic缓冲深度64/默认切换8不能移植为Elitestek v1.1的服务保证。未打开在线UG链接或下载模型；[原模型请求](../../../tools/REQUEST_DDR3_MODEL_20261004.md)保持PENDING。

## 3. 资源账的准确边界

本轮资源读者实际重新核旧映射/独立候选，根全文复读[唯一资源报告](production-unique-resource-and-control-ram-v0.1.md)100行与[旧DDR RAM证据](../../track4_full_sw_20261004/01_baseline/ddr-service-ram-evidence-v1.md)14行，并有限读[DIR](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)165–184、[SC](../../../planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)184–210、[SV](../../../planning/design-TRACK4-ALGORITHM-CLOSURE-SOURCE-VIEW-001.md)126–138、[识别R4R](../../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)202–229。按原表做静态整数加法，没有编译模型或新测试。

| 项目 | 可复算数字与限制 |
|---|---|
| 具名RAM候选 | DDR父39+CSI父11+新camera31+ROW40+FE/Canny28+PROFILE/FONT/R3 ROM4+CONTROL2+SCAN1+DIR11+独立R1 FE8=175；CH0独立+1=176。不同层级类型不得当176个实际同型EFX_RAM10；识别工作池等未覆盖 |
| 实测与去重 | 原C2父DDR39已含PHY22/桥17，不能再加子项；C2顶层89是EFX_RAM10 85+DPRAM10 4。原demo framebuffer28/debug2和替换链不整包叠加；当前共享FE尚未证明，保独立8 |
| DIR剩余 | 当前104448可寻址bit−101408已用=3040bit：journal48、M065、M139，共152个native20词。不是连续自由池；M0/M1余104词，五RowCtx220词还差116，端口/授权也未授 |
| 识别存储 | R4R D7各表逐项求和17,526,269B，POINT16,588,800B；未映射真实backend/银行/端口，额外SRC/GRAD/闭包另计。旧RC91是另一存储路线，不能直接加91或任选最小旧账来补当前预算 |
| selected状态 | 21606+15792+5279+5926+6+1991=50600bit。是部分真实保存位置的并集，未计全部scalar/双端保持/CDC/算术，不能当实际FF或60800XLR的利用率 |
| 已验证R1 | 仅原有限top：实际place报告全42行，SHAE249B53B316780C94CDE993B308055AEFC8F49BEC3BBCD432C4F7ECF7A04CAC0；packed XLR3411、RAM8、DSP0、GBUF1。不能将R1局部0DSP或8RAM当整机结论 |

标称256−176=80只是未列块数，不是已证明可用余量。完整账须纳入七类实际owner/端口/同时寿命：S scalar及序号/有效位；O/allocator/permit与物理路由；J/C0/L/C的另一端体和历史；识别backend/R3算术；ROW/SCAN/CONTROL/PROFILE冷热记录；camera/COPY完整保持/CDC；平台PLL/复位/TMDS/I²C/IP及观察通信。先选真实存放，再按完整实例账判断fit，不用宽body名称相同当可免费别名。

## 4. 只读核查偏差与边界

子审阅在核同名文件时误用固定前58行读取未选的 `C2/rtl/ddr3_controller/common/simple_dual_port_ram.v`，只输出30–58，其中包含保护封装/部分密文。该3413B文件SHA256 41DA4FB5D1E10B94A1F35DF8075A594071BDF154823FF4EDC87AC5F4E128D934不在冻结源清单。保护标记精确首行本轮未取得，不为补行号再读；已立即停止，无解密、解释、采用、修改、59以后读取或再次读取。本报告不重印内容，不能记录为“本轮完全未输出保护行”。偏差已向用户说明；后续只扫描公开头，遇真实保护标记即停止，不用固定行数猜边界。

## 5. 守护核验与后续

R1的22份、R2的48份输入及原10个正式状态/交付/BIT/HEX guard全部一致；本次44项Q0身份一致；正式Manifest仍没有Q0/R2批准，DB配置存在性false。旧DQ/SV/闭包及R2输入保持原字节；R2和Q0 work均不存在。审阅属于纯设计，不借R1本地审计例外运行新阶段。

可立即呈现Q0 v1指定批准；已待答的R2 v1问题不重复。得到批准后按独立work执行有限Q0；匹配2Gb器件模型、PHY接线、真实五通道功能与故障关闭资格仍沿完整DQ设计继续，整机资源/生产I/O/共同实施基线仍待完成。本轮的控制面文档检查点仅本地追加，不写正式数据库或伪造硬件状态。
