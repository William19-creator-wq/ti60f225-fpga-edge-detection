# TRACK4-CAPTURE-DISPLAY-HUB-001 v1.1 / J1：旧终态保持与真实读竞争

在首次compile/仿真之前核对v1交接，发现两点必须先调整设计。持续自主软件/local audit授权仍有效，不改正式DB/硬件。原v1/54输入冻结副本保留，本卡加入第55输入，runtime55源/工程及10自写文件数不变。

1. DH01/04的public DONE保持：原capture父只有自身工作域Q，状态更新末尾无条件if(Q)进入QUARANTINE；新组合加入独立display域，可能在整个capture job已形成且held safe DONE之后出现displayQ。机械保留该条件会撤done_valid/改outcome，违反先前公开终态保持要求。本次在新capture_canny_rpc（旧登记父不改）将Q状态覆盖限定为state!=DONE；held DONE不改正文，仍可消费，memory/globalQ始终挡下一job。消费沿后进入IDLE，下一沿仍Q则进QUARANTINE。原done断言仍要求真实all_closed，允许无关域memoryQ与已形成safe DONE同时存在，不把其局部safe DONE当新的FrameRef发布许可。其余状态/数值/CJ/base/取消/错误优先级保持原样。

中文操作：计算quarantined和producer_localQ仍按v1；在旧FF尾部Q分支加“旧状态不是DONE”，其他FF语句逐字保留；将原done_valid&&(!all_closed||quarantined)检查改为done_valid&&!all_closed，另外公共held DONE逐沿全正文核对。用只读文本差异把修改定位这两处，不宣称整段尾部仍字节相同。T4增加safe held capture DONE时发独立display malformed R，必须旧DONE不撤/不改、可消费、下一job始终不ready。未形成DONE时发生Q仍禁止safe done。

2. T1/T2实际algorithm与display读竞争：display若只在RAW开始读一次旧Source，可能在Canny启动前已读完，不能证明读服务的两个真实producer竞争。每个正常图像读取同一不可变/授权旧Source两遍：第一遍随RAW采集，第二遍在公开phase进入START_CANNY(4)或其后开始；两遍所有字节核对。第二遍真实ID2读取必须与实际algorithm ID0请求共处并记录服务，不能另造算法刺激。expected-display仍一份完整A64，actual-display保存两遍，独立审计比较expected×2。保持旧Source lease到两遍真实done；不冒称生产frame authority已经实现。

追踪：DH01/04→新parent末尾Q guard/公开DONE body→T4 late unrelatedQ；DH02/03→display两遍真实输入→T1/T2算法读竞争/所有bytes。无接口/数值/存储布局/CRC/生产范围变更，局部语义补足已声明保证。READY v1.1，先读回呈现，再修新work代码和验证；旧源、v1设计及原54冻结输入只读。
