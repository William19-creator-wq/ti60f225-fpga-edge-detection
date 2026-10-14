# ANNOTATION-WRITER C2：工程XML元素顺序

- v1范围和用户持续授权有效。annotation_small_002及annotation_min_001实际仿真/独立审计均PASS，生产RTL不改。
- annotation_map_001实际efx_map退出1：ProjectDatabaseParseFailed，在读取工程XML阶段失败，没有综合资源结果。原stdout/stderr/map.out及完整异常保留。
- 现有生成器移除旧design_file后，把新design_file追加在top_vhdl_arch之后；已成功工程的顺序为top_module → design_file列表 → top_vhdl_arch。调整回既有顺序，是否解决由新MAP实际结果验证，不先宣称通过。
- 操作草图：读取XML →取出仅3个design_file →移除原位置 →按frame_owner_pkg、packed_sink、annotation RTL次序插入top_module之后 →保留所有其他device/synthesis/SDC设置 →保存 →新RunId执行MAP。
- 只改project/annotation_writer_component.xml；不改RTL、TB、参考、运行脚本，不改变接口或综合策略。没有重新仿真的必要，因为16份实际仿真源码均不受影响。
- 本卡保存、读回、额外冻结后实施；保留原18份baseline及C1。正式数据库/Manifest/硬件状态不变；禁止把失败MAP说成通过。
