# Handoff and Recovery

## Resume order

1. Read `state/PROJECT_STATE.json`.
2. Read the latest checkpoint under `runtime/checkpoints/`.
3. Check `FPGA_AGENT_DATABASE_URL` without printing its value.
4. Verify database migration version and local event archive integrity.
5. Check Side-effect Ledger before retrying any external action.
6. Confirm the work-copy hash and latest artifact hash.
7. Resume only from the last safe state in `STATE_MACHINE.md`.

## Safe pause states

- `WAITING_FOR_HARDWARE_BASELINE`
- `WAITING_HUMAN_PROGRAM`
- `WAITING_HUMAN_OBSERVATION`
- `SUSPENDED_FOR_APPROVAL`
- `BLOCKED`

No tool call is retried solely because a process exited. First inspect its event and side-effect record.

## 2026-09-23 continuation

Superseding functional-test update: read `reports/audit/environment_acceptance/ENVIRONMENT_ACCEPTANCE.md`. Minimum LED compile/PNR/STA/bit/hex and FIFO generation passed using a temporary ASCII alias. Original debug profile failed; ModelSim10.1c has both license and current FIFO compatibility blockers. Local runtime negative test failed illegal-transition rejection. Overall NOT_ACCEPTED, no installation or hardware programming. The paragraph below preserves earlier inspection history.

Track 4 confirmed. Actual hardware is undecided; user requests VF-Ti60F225 as an environment inspection example only. Read `planning/CURRENT_PLAN.md`, the track 4 requirements/workflow and `reports/audit/environment_20260923/ENVIRONMENT_READINESS.md` before continuing. Efinity imports/parser and ModelSim HDL compilation passed, but simulation failed with invalid license environment; no full Efinity build or hardware test occurred. Preserve H0 waiting for physical baseline. PostgreSQL and runtime enforcement remain unaccepted. No new tools were installed.
