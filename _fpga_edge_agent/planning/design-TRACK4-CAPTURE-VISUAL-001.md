# TRACK4-CAPTURE-VISUAL-001 v1：单像素边缘概览可见性

按PLAN_TEMPLATE短修订卡；2026-10-09。Goal：实际同源仿真图人工可见；Current：v4检查点/14新源码/4579登记文件hash及1080p校验通过，但view_image确认普通nearest缩小把单像素轮廓漏掉。Target：新概览v2保留任意3×3区域内的边缘；原数据/native图/v4/旧概览保留只读。Gap：仅概览可视化，不是算法错误。Assumptions：1920×1080恰好3倍640×360、现有Pillow/中文字体可用。Open：无。Milestone：原数据hash→3×3最大值→新图→新报告/来源/v5→view_image实际复核。State：READY保存/readback后沿持续自主授权实施，正式DB/state/硬件不改。Failure：源长度/域/旧hash不符即停止，新名称已有即不覆盖。Rollback：新独立visual脚本及新v5产物，旧证据不改。Completion：数据依据/摘要/新图真实读回及tool视觉观察；整目标仍ACTIVE。

CP-V01全尺寸源/edge对应actual HD PASS，edge字节只0/255，共1078。脚本`delivery_tools/capture_visual_overview.py`先核v4的报告/图片/来源摘要及14新工作文件与10个Manifest摘要；用源RGB nearest缩640×360仅作底图。对每个edge255的实际坐标(x,y)，置概览位图(floor(x/3),floor(y/3))=255，同格多点合并；显式记录native1078/coarse格数。概览edge直接该位图，概览overlay在该位图非零时红255/0/0，其他底图保持。图中文字明确“概览按3×3保留细边缘；精确结果见原尺寸图”。无抗锯齿推断、无AI图像生成/源图编辑/原数据修改。

写新PNG/provenance/report/v5检查点，保留v4追踪。v5继承实际软件结果和154计数，不重新宣称本轮再核4579文件（沿v4，另核Manifest摘要/14工作文件）；写明当前检查范围。事件EV023仅追加既有两JSONL一次；实际view_image后再另记EV024观察结论。中文文档更新仅新报告，冻结组件README/基线不改。测试CP-V01真实输入，CP-V02区域聚合点不丢，CP-V03图native不变且新名无覆盖，CP-V04工作源/Manifest摘要无漂移、报告/图/检查点hash读回。Python任意精度坐标/bytearray限定边界，文件UTF-8。无RTL/API更改。
