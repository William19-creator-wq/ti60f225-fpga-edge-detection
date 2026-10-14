# PostgreSQL Backup and Restore

Backup and restore are external database actions and require approval. Do not put credentials in command history or files.

After an approved client is available:

```powershell
pg_dump "$env:FPGA_AGENT_DATABASE_URL" --format=custom --file .\runtime\local_archive\fpga_edge_agent.dump
pg_restore --list .\runtime\local_archive\fpga_edge_agent.dump
```

Before restore, record the database version, migration version and target database. Restore to a verified target, run the read-only queries, compare counts and hashes, and record the result as an exception or recovery event. The Agent never overwrites a database or drops objects automatically.
