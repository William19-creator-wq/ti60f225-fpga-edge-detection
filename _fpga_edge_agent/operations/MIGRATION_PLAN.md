# Migration Plan

迁移对象包括控制面目录、PostgreSQL Schema 和运行事件。先比较文件哈希和 Schema 版本，再生成迁移计划；未解决漂移或缺少审批时停止。
