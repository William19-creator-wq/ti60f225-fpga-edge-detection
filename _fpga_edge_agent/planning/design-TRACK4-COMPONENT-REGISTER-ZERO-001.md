# TRACK4-COMPONENT-REGISTER-ZERO-001 v1：零原语资源登记

2026-10-09，持续自主授权，独立软件审计工具局部修正。Goal：登记实际0RAM/0ADD组件，不虚构缺失报告。Current：AXI桥1297场景及MAP通过，报告仅列非零FF/LUT，现工具要求RAM/ADD各恰一行，无法登记。Target/Gap：只补有明确实际网表证据的0判断；旧包不改、正式DB和硬件不改。Assumption：LUT/FF非零报告各唯一，NoDSP明确；所有源/MAP快照/仿真仍逐hash通过。Open questions：无。

整体和接口：register_memory_component.py CLI、source校验、复制及冻结、JSONL审计不变；新增zero_resource_evidence供人复核。局部中文草图：原资源正则找到唯一非零行则沿用原数；未找到且资源是RAM10或ADD时，实际.map.v读取，RAM检查所有RAM/DPRAM类别都不存在，ADD检查EFX_ADD不存在，才能记录0和实际map.v SHA及“summary省略且网表无原语”证据；其它缺失/重复或网表仍有原语则拒绝。

语言契约：Python整数、正则、固定白名单，不以异常兜底填零、不修改报告或工具日志。Milestones：保存/readback READY→helper局部改→正常旧报告仍解析→AXI零资源实际登记/重读manifest。Failure/Rollback：拒绝登记且保留原报告；新artifact必须不存在才复制，不覆盖原包。Human gates：无硬件。

验证和双向追踪：ZR01只接受证实0→固定白名单+网表不存在断言→AXI报告FF1068/LUT1362/MemoryPorts0及.actual map.v；ZR02旧正数/源hash/副作用保持→原流程不动→RAW/RGB已登记包不变；ZR03源/MAP缺失或漂移仍失败→原Require/断言。完成范围只是本地登记修正，不变更FPGA设计、权限、DB、硬件状态。
