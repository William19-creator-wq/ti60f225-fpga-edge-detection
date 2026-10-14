# Environment Lifecycle

`Provision → Bootstrap → Mount Inputs → Execute → Persist Outputs → Publish Runtime Artifacts → Cleanup`。当前环境为本地 Windows；原始资料只读，Agent 目录和获批 work 副本可写。环境重置不得丢失 PostgreSQL、事件归档或检查点中的关键状态。
