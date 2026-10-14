# 圆父接入 v1：稀疏 overlay 候选

2026-10-11，TRACK4-CIRCLE-PARENT-INTEGRATION-001。ROOT实际读回并呈现设计卡 E6B359013F827A2273EE2426E4427AB54607F3F44020B1C924D956EA4524B863 后，依据用户持续自主、本地审计、免额外TB授权限定实施；不冒称用户按版号单独批准。仅本目录九份RTL、一份XML、before、输入映射及实际差异；未修改main、运行058、旧候选、设计卡、原资料、正式状态或硬件。

| 冻结候选源 | SHA256 |
|---|---|
| board/rtl/board_algorithm_rpc.sv | F5B45139CE67742E627C14204A6AFE13C7DBCBFDD29B913E622FD3F01E1D88BB |
| board/rtl/board_recognition_points.sv | 22A5F16652B7AAAF7B53025EBFB0A322BA8E6F74F3926E9C91D362B26B9C89E5 |
| algorithm/rtl/frame_actors_axi.sv | A05FFA1762A43B3872AAEE57FA5A11DFABEDE07F7D8CFF40F468A6E9FEA55FF5 |
| board/rtl/board_frame_system.sv | 94A47F0A88250E682EDB422CE5C9F6626AD07BAAC38D39CEE1A9650C1A3EE0CB |
| board/rtl/board_recognition_stats.sv（merged_v1_2原样复制） | 14228BE6277F5CDC5989D1D002D62C4590514E941BDEF5D55530D76527835A22 |
| board/rtl/board_circle_histogram.sv（原样复制） | 3A8F9A320E3D6E8B1C7D8455BF24FD2B5B63E9B060C682262F664BD39CE59A50 |
| board/rtl/board_geometry_point_math.sv（radius-only版原样复制） | CC4BF36A1E51325948F12640379346865C48EC5F8778D3C4AAD7209504E64C05 |
| board/rtl/board_circle_reduce.sv（原样复制） | 9785CCF94B22BC0898B32B80E36B20BD2FAAB262DEBF547FFAB7D71DEFC17D03 |
| board/rtl/board_circle_refine.sv（radius-only接线版原样复制） | 0AC562695ECA432200EC74825D71C093F0D4753AA43A7ACFFFF765D8EFEF7EA4 |
| track4_board.xml | 2AFD2A4D4BA89FE253D3773AF48E30A760BF3AF40F8B87394AD3C0DB9F5C528B |

before准确来自 `runs/board_compile_058/flow`，未取后续主改动：RPC 7F4B21CE09F81FBF2236E54000748B32FD522F889AD4997860292B3E5544EE93；POINT 686C4B19D4D8216A6B8F04EA8BBA259FF74B255D3275E4C9A09C60BD2B7C03FF；actors C5B13D0D7DD8B0E4BFC9BBA9F77E3CD6213CAE6E610CDD53ED9419610EC0024C；system 4A6EC6749C0E803540E2A1EA455A17AB8FBE9BCF9FB12342A33ABE903D49FF6E；XML 8D3CE422C634ECB427107C52FAF49DA83444DECDD9FD5FAC3B78FB2F12B81BDD。

实际接线：RPC/actors参数默认0，候选system的唯一actors实例显式1；旧外部接口顺序保留。POINT追加默认0 ANGLE lease，COMPLETE+无fault+真实quiet授给CF，start优先；同一个原angle_core、直接borrow正文、未门控quiet，无第二角度核。STATS显式ENABLE_GEOMETRY=1/GEOMETRY_FULL_FIT=0、仍一个原STATS/FIT，CF显式BORROW_SCOPE/SHARED_RETURN_WORDS/ENABLE_RADIUS_ONLY=1。

NUM真实NONE/FIT/SEED/CF_PM/CF_CR owner；先拥有SEED才发seed_start，CF/FIT用既有fit_num源，PM/CR用第三direct源。每次换owner先shared scalar quiet且无held NUM reply/旧请求，并核private FIT关闭，未bound用旧start/bind_ready；保留BORROW_RESULT后的body/index/16bit返回字，不按valid/quiet清零。输入case三源72个固定16bit位置，完整REQ622/RSP585/ID176/385/25字资格不改，无第二scalar或新宽返回快照。

CF从完整DENSE/LINE/META和SEED/旧DDR真关闭后开始；circle_started最高选择其DDR/PACK，旧sticky dense/seed不能抢。完整CIRC/META、geometry释放、NUM实际NONE、ANGLE实际归还、DDR真closed才交正常done；CF known fault&&drained&&!quarantined同样可提交outcome1/reason80000040，不等待FAILED态不存在的cf_done。CF/memory/RPC UNKNOWN明确禁止commit并保持scope/borrow，不新增暖取消/超时承诺。

ROOT定向静态读回发现POINT的一处同沿交接：旧候选942B11316E95B8BF65744E68A7D3B6D88EE4A44BD724735161480A5E528BCC12在start&&start_ready与angle_owner_request同沿可能双授。仅grant条件补 `!start` 得到上表22A5…；旧值不冒称最终hash，其它源hash不变。ROOT已实际读回actors/system/XML相应差异；新POINT增量及RPC整体仍待父最后确认，未记整包ROOT PASS。

review/保存RPC、POINT、actors、system、XML五份真实no-index diff，作者已完整读回；based literal紧连问号搜索无匹配。input-map.json SHA 5852DDBEFF03D8E8D544D725401FEAD00580028FB194F8D75B589E3E043A8819，映射131个唯一design_file，其中九源来自本候选，其他122源来自058冻结flow；XML仅新增HIST/PM/CR/CF四项，127→131。

**XML是待同根overlay采纳的输入，稀疏candidate不是可单独打开/编译工程。** 没有复制vendor/IP或全部mem/include/peri/SDC。父审核后需将九源与XML合到完整work，再由已批准build_board冻结全部实际输入；预期205→209输入只属父提供的增量估计，最终数量由真实工具登记。本批没有TB、仿真、EDA、时序、bit或硬件操作。

future merge未采用：display_append_v1对system的FIXED_APPEND=1及其新display；scalar_root_narrow_v1对RPC唯一scalar的ROOT_NARROW_WORDS=1及其新core，均需父明确局部合并，不能拿本058副本覆盖后续主改动。RECT、FINAL/ANN/标签、64B CIRC到HDMI消费仍欠；现shape_tracker画面仍原近似框，资源/性能/实物质量未知，不称完整A6、HDMI新圆结果或整机通过。
