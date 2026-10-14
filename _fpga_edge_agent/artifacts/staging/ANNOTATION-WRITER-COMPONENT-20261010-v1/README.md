# 标注结果写入与授权读回

阅读次序：

1. [整体与局部中文草图](control/design-v1.md)：先看范围和数据路径，再看各端口与逐状态操作。
2. [C1 测试调度修订](inputs/control/C1-v1.md)：第66个头部输入接受后，必须等真正写回才能向标签阶段注入故障。
3. [生产模块](rtl/annotation_frame_writer.sv)：`canonical_job` → `body_sink` 的交接 → `annotation_control` 中各状态。
4. [测试平台](tb/tb_annotation_writer.sv)：真实账本分配、写入、完成、发布、权限查询、行读取。
5. [独立参考与公开总线审计](model/annotation_reference.py)：按公开 AW/W/B/AR/R 重建实际字节，核对标注头、标签、尾零和逐像素输出。
6. `runs/`：每次真实运行独立保存，不覆盖失败尝试；`source-manifest.json` 固定当次实际源码。最终结果以 `suite-result.json` 与 `independent-audit.json` 为准。

这一步解决识别结果如何可靠存入帧区。它接受调用者生成的头部和标签；复杂识别算法生成这些数据的部分仍需后续完成。Source/EDGE 在本批测试中是明确夹具，ANN 是真正写入，不能把本批理解为相机到显示的全链路验证。

```
真实 ALLOC_RESULT 回执
        ↓ 合法性检查与一次原子采样
66×64B 头部 → 实际写请求 → AW / 四个W / B → 闭合回执
        ↓ 全部66块真实完成后
连续双像素标签 → 私有512位打包 → 实际写请求与回执
        ↓ 最后事务实际结束
安全 DONE（身份、计数、错误）
        ↓ 测试调用者发送真实账本命令
RESULT_END → OFFER → APPLY → 逐行权限查询
        ↓
真实行读取 / RAM10 → RGB + EDGE + ANN 双像素包
```

1920×1080 时，标签图为 518400 字节；加 4224 字节头部，共 522624 字节，正好 A64 对齐。每帧66个头部事务、8100个标签事务。小尺寸帧尾不足64字节时补零；一行结束不单独补齐，下一行连续接着打包。

如果正常停顿，valid及其正文保持。匹配取消只停止新的输入，公开请求和真实存储事务继续履约；drained=0时隔离并等待共同冷复位。完成事件不由超时或输入计数单独产生。

运行入口为 `scripts/run_annotation_sim.ps1` 和 `scripts/run_annotation_map.ps1`。MAP仅用于当前组件综合预检；板级引脚、跨时钟、布局布线、STA和比特流仍属于后续整包任务。未获得实机观察，不声称硬件通过。

当前验证已结束，详见 [完成核对](completion-review.md) 与 [实际综合资源](resource-result.json)：34×20、4×2、1920×1080 三次当前仿真及独立总线审计通过，共13帧、2077728像素；组件综合2100 LUT、1669 FF、52 ADD、0 RAM、0 DSP。失败尝试保留在 annotation_small_001 和 annotation_map_001；C1/C2 修订记录说明原因和差异。
