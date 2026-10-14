# 中文阅读与人工观察草图

这份阅读页配合[R1权威设计](../../../planning/design-TRACK4-ALGORITHM-R1-001.md)，不另定义接口。没有实际代码或波形，以下是获批后的观察次序。

1. 先读[整体路线](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)B/C，看五批如何从可独立运行的算法进入完整任务。
2. R1 B/C：规则图样→灰度→两行窗口1→九级中值/同延迟旁路→两行窗口2→六级Sobel→结果CRC→LED。
3. R1 D：job和首像素分沿；两个lane与窗口中心；FO记录/FS记录；ready低时全部伴随保持。
4. [原FRONTEND](../../../planning/design-TRACK4-FRONTEND-001.md)E：整体job先理解，再看灰度/中值/Sobel，最后细看RAM旧读回/新写入、行交接和REPLAY/TAIL。
5. R1 E2/E3：q/r只在实际输入接受时走；K一次捕获160bit，之后逐bit处理，忙时反压；status要等最后data CRC完成再交接。
6. R1 E4/E5：KEY同步释放、LED唯一driver、J2真实40ns、异步例外止于适当端点；看map/pin/STA报告。
7. R1 G/H：逐坐标参考和协议证据，与工程/bit分别验收，最后读实际文件/Run ID。

逐沿正常路径：接受job→下一沿起提出RGB→算法等待邻域并输出同中心M/edge→FO真握手捕获record→随后160沿CRC→最后输出已交付且末data处理完→FS真握手→终态record处理完锁CRC/tag→下一job。不要把CRC低速算成算法内部固定延迟。

看波形先找：锁定配置/三ID；FP握手/q/r；RAM同沿不同址；窗口输出中心；FO挂起数据稳定；K捕获/首bit/末bit的新CRC；FE尾部/empty；FS保持/消费；reset后新首两行。记录Run ID、case/沿或坐标、期望、实际和结论，不能只写“正常”。

看工具报告先找：Ti60F225/I3/生产尺寸；8个行RAM和真实算术层级；结果到CRC/LED扇出；J2/P13/N14/P14；40ns内部setup/hold覆盖；例外和告警；最后bit输入/日志/hash。若算法被常量裁掉、pin错或内部路径未约束，该工程不能通过。

获批后补实际Questa/Efinity GUI打开工程、仿真波形/报告阅读和可复现命令。当前“人工观察”是软件结果/波形阅读计划，不包含实体下载。理解验收待用户实际反馈，不用考试阻碍已批准的实现。

