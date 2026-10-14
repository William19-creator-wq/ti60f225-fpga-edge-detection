# PostgreSQL Runtime Store

PostgreSQL is the only structured database backend for this Agent. The current environment did not expose `FPGA_AGENT_DATABASE_URL`, `psql`, `pg_dump`, `pg_restore` or a PostgreSQL service during configuration. The Agent must therefore report the database as unavailable until an existing service is supplied.

## Connection

Set `FPGA_AGENT_DATABASE_URL` in the process environment. Never put a password in this directory, source files, logs or chat messages.

## Migration

Review `database/schema.sql` and `database/migrations/001_initial.sql` first. Applying a migration requires approval in `config/APPROVAL_MANIFEST.yaml`; this repository does not auto-create databases, roles or permissions.

Example after approval, using an approved PostgreSQL client:

```powershell
psql "$env:FPGA_AGENT_DATABASE_URL" -v ON_ERROR_STOP=1 -f database/migrations/001_initial.sql
```

The example is documentation only and was not executed during configuration.

## Driver policy

The runtime uses Python standard library functionality for local events and reports. `runtime/pg_store.py` provides parameterized event/project/metric writes when an approved PostgreSQL driver such as `psycopg` is available. The driver is optional and is not installed automatically; request it through `docs/TOOL_REQUEST_TEMPLATE.md`.

## Data rules

- Database records and local JSONL events share stable IDs.
- Local JSONL is an append-only recovery/audit archive.
- Database migrations are versioned and hashed.
- Database failure stops database-backed execution; there is no silent SQLite fallback.
