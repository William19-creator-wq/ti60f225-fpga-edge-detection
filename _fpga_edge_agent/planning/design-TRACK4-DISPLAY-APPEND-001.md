# TRACK4-DISPLAY-APPEND-001 v1：显示字节拼接优化

2026-10-11。按模板合并小任务字段；用户已授权自主完成整合、免新增长草图和独立测试、本地审计。本卡只限定独立候选，先读回再编码，不冒称新版本逐项获批。原资料、058冻结输入、硬件和正式数据库不改。

- Goal / 当前差距：现显示每次把128位DDR输入通过256位可变移位加入字节队列。057显示直接LUT2720，实际优化幅度未知；降低选择结构成本，为完整算法接入留余量。
- Baseline：主 `board/rtl/board_frame_display.sv` SHA CF567D6DB40134C5D156A25ED0771D48EF77426E691441319033628676C77C8D；主 `board/rtl/board_frame_system.sv` SHA 4A6EC6749C0E803540E2A1EA455A17AB8FBE9BCF9FB12342A33ABE903D49FF6E，包含058写源优化和冻结重算，不能用旧副本覆盖。
- 范围：只两文件独立candidate。显示追加参数 FIXED_APPEND 默认0；参数0沿用旧可变移位。参数1在原 take && RDATA 分支，用原 next_bytes 选择九个固定256位拼接；板端唯一实例置1。无新寄存器、RAM、DSP、时钟、端口或拍数；RGB/EDGE/标签/扫描/CDC/回复关闭都不改。

## 整体、接口与局部契约

DDR span原提供完整128bit输入，每次take加16字节；FIFO原push每次输出48bit即6字节。reset及每行RREQ把bytes置0。唯一计数写入为原 next_bytes；从0开始、加16/减6保持偶数。take仅在bytes<=16时可能成立；若同时push，next_bytes=bytes-6<=10，否则next_bytes=bytes<=16，因此实际追加位置恰为0/2/4/6/8/10/12/14/16字节。

固定拼接分别把data放在低0/16/32/48/64/80/96/112/128 bit，上下补零后仍完整256bit，并与已经shift48后的next_reservoir OR。接受、扣字节、加字节和reservoir提交保留原边沿，背压时不接受输入、不推进pair。字节顺序不变，不丢高位数据，不额外缓冲。其余位置由契约证明不可达，启用分支default保持旧next_reservoir但仍使用原加16计数；不把X/内部损坏当可接受输入，未改变正常上游接口。

RDATA中bytes可大于16，此时允许push但禁止take；新case只处于take分支，因此不把26等队列长度误当输入位置。每行5760字节/960对，原收尾与frame指针切换保持。reset源、两个时钟域、FIFO深度、span请求及done处理原样。无C++映射。

REQ-DISPLAY-APPEND：相同合法DDR字节流及背压→相同reservoir/bytes/pair/RGB序列；接口证明→take/count偶数及<=16→九个固定连接；原默认兼容→参数0完整保留旧表达式。所有其它显示要求反向映射原代码不改。

## 验证、回退与门槛

静态读回九项256bit宽度和字节位置，覆盖同时push/take、FIFO背压、bytes0/2/16/32、行结束和reset。按用户指令不新增TB或仿真。编码后实际diff/hash登记；只在下一次新的整机run测LUT/容量/布线/STA，不能称已省资源或已验证实物。参数关回0或before两文件回退，仅回退本候选，不退058修改。

状态 READY_FOR_REVIEW，供ROOT限定读回与自主实施。完成候选不等于完整A6、性能或新下载版本完成；硬件保持人工下载与观察。
