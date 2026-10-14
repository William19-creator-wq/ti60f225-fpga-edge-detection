"""Static, dependency-free control-plane validation."""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "README.md", "AGENTS.md", "config/AGENTS.md", "config/AGENT_PROMPT.md", "config/PROJECT_CONFIG.yaml",
    "docs/WORKFLOW.md", "docs/STATE_MACHINE.md", "state/PROJECT_STATE.json", "state/TASK_LEDGER.csv",
    "state/DECISION_LOG.md", "state/EXCEPTION_LOG.md", "config/APPROVAL_MANIFEST.yaml",
    "config/CAPABILITY_REGISTRY.yaml", "docs/TOOL_REQUEST_TEMPLATE.md",
    "docs/HUMAN_OBSERVATION_TEMPLATE.md", "docs/HANDOFF.md", "docs/RECEIPT_AUDIT.md",
    "database/README.md", "database/schema.sql", "database/migrations/001_initial.sql",
    "database/queries/read_only.sql", "database/backup_restore.md", "database/MIGRATION_MANIFEST.json", "runtime/agent_runtime.py",
    "runtime/pg_store.py", "runtime/generate_reports.py",
    "planning/CURRENT_PLAN.md", "planning/PLAN_TEMPLATE.md", "skills/fpga-hardware-node-gate/SKILL.md",
    "docs/workflows/TRACK4_WORKFLOW.md", "docs/requirements/TRACK4_REQUIREMENTS.md",
    "docs/requirements/TRACK4_REQUIREMENTS.csv", "docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md",
    "tools/TOOL_REGISTRY.csv", "tools/COMMAND_CATALOG.csv", "tools/MCP_REQUIREMENTS.md",
    "tools/PLUGIN_ASSESSMENT.md", "tools/TOOL_PERMISSION_MATRIX.csv",
    "agents/AGENT_ROLE_CATALOG.md", "agents/ORCHESTRATION_SPEC.md", "agents/SUBAGENT_OUTPUT.schema.json",
    "validation/VALIDATION_ARCHITECTURE.md", "validation/GUARDRAIL_POLICY.md", "validation/HOOK_DESIGN.md",
    "observability/OBSERVABILITY_SPEC.md", "observability/EVAL_PLAN.md", "observability/REGRESSION_TEST_MATRIX.csv",
    "security/THREAT_MODEL.md", "security/SECURITY_POLICY.md", "security/SECRET_MANAGEMENT.md", "security/DATA_RETENTION.md",
    "operations/INSTALLATION_PLAN.md", "operations/MIGRATION_PLAN.md", "operations/BACKUP_PLAN.md", "operations/ROLLBACK_PLAN.md", "operations/RESOURCE_BUDGET.yaml",
    "context/CONTEXT_POLICY.md", "context/MEMORY_ARCHITECTURE.md", "context/COMPACTION_POLICY.md",
    "events/EVENT_CATALOG.yaml", "events/EVENT_HANDLER_REGISTRY.yaml", "events/EVENT_DELIVERY_POLICY.md",
    "side_effects/SIDE_EFFECT_POLICY.md", "side_effects/IDEMPOTENCY_POLICY.md", "side_effects/ledger/README.md",
    "deployment/DEPLOYMENT_POLICY.md", "deployment/ROLLBACK_AND_PROMOTION.md",
    "runtime/RUNTIME_MODEL.md", "runtime/SESSION_MODEL.md", "runtime/TURN_EVENT_MODEL.md",
    "runtime/ENVIRONMENT_LIFECYCLE.md", "runtime/DURABLE_SESSION_POLICY.md",
]


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []
    state = {}
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            fail(f"missing: {relative}", errors)
    try:
        state = json.loads((ROOT / "state/PROJECT_STATE.json").read_text(encoding="utf-8"))
        if not state.get("state") or not state.get("current_node"):
            fail("project state/current node missing", errors)
        if state.get("database", {}).get("fallback_backend"):
            fail("unexpected database fallback configured", errors)
    except Exception as exc:
        fail(f"PROJECT_STATE.json invalid: {exc}", errors)
    try:
        with (ROOT / "state/TASK_LEDGER.csv").open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        if any(None in row or any(value is None for value in row.values()) for row in rows):
            fail("task ledger has missing or extra CSV fields", errors)
        node_ids = [row["node_id"] for row in rows]
        if len(node_ids) != len(set(node_ids)) or any(not item for item in node_ids):
            fail("task ledger has duplicate/empty node ids", errors)
        if state.get("current_node") not in node_ids:
            fail("current node not in task ledger", errors)
        config_text = (ROOT / "config/PROJECT_CONFIG.yaml").read_text(encoding="utf-8")
        node_block = re.search(r"(?m)^nodes:\s*\n((?:[ \t]+- [^\n]+\n)+)", config_text)
        configured_nodes = re.findall(r"(?m)^\s+- (\S+)", node_block[1]) if node_block else []
        if not configured_nodes or set(configured_nodes) != set(node_ids):
            fail("configured nodes and task ledger differ", errors)
        with (ROOT / "docs/requirements/TRACK4_REQUIREMENTS.csv").open(encoding="utf-8", newline="") as handle:
            requirements = list(csv.DictReader(handle))
        if any(None in row or any(value is None for value in row.values()) for row in requirements):
            fail("requirements have missing or extra CSV fields", errors)
        expected_requirements = {f"T4-B{i}" for i in range(1, 6)} | {f"T4-A{i}" for i in range(1, 7)}
        requirement_ids = [row["requirement_id"] for row in requirements]
        if set(requirement_ids) != expected_requirements or len(requirement_ids) != len(expected_requirements):
            fail("track 4 requirement coverage is incomplete or duplicated", errors)
        for row in requirements:
            refs = re.split(r"[;|]", row["node_ids"])
            if any(ref.strip() not in node_ids for ref in refs):
                fail(f"unknown node reference in {row['requirement_id']}", errors)
    except Exception as exc:
        fail(f"TASK_LEDGER.csv invalid: {exc}", errors)
    schema = (ROOT / "database/schema.sql").read_text(encoding="utf-8")
    manifest = json.loads((ROOT / "database/MIGRATION_MANIFEST.json").read_text(encoding="utf-8"))
    if set(manifest.get("files", {})) != {"schema.sql", "migrations/001_initial.sql"}:
        fail("migration manifest does not cover schema and initial migration", errors)
    for table in ["projects", "sessions", "events", "approvals", "artifacts", "build_runs", "hardware_observations", "side_effect_ledger", "metrics", "alerts"]:
        if not re.search(rf"CREATE TABLE IF NOT EXISTS {table}\b", schema, re.I):
            fail(f"schema missing table: {table}", errors)
    prompt = (ROOT / "config/AGENT_PROMPT.md").read_text(encoding="utf-8")
    for phrase in ["WAITING_HUMAN_PROGRAM", "WAITING_HUMAN_OBSERVATION", "PostgreSQL", "不包含 Verilog/C++/TinyML"]:
        if phrase not in prompt:
            fail(f"prompt missing safety phrase: {phrase}", errors)
    config = (ROOT / "config/PROJECT_CONFIG.yaml").read_text(encoding="utf-8")
    for module in ["planning", "skills", "tools_mcp_plugins", "agents_orchestration", "validation_guardrails_hooks", "observability_eval", "security", "operations", "context_memory", "events_async", "side_effects", "deployment"]:
        if module not in config:
            fail(f"PROJECT_CONFIG.yaml missing module mapping: {module}", errors)
    if errors:
        print("CONTROL_PLANE_INVALID")
        print("\n".join(f"- {error}" for error in errors))
        return 1
    print("CONTROL_PLANE_STATIC_VALID")
    print("scope=files_and_references_only_not_runtime_or_database_acceptance")
    print(f"files_checked={len(REQUIRED)}")
    print("database_backend=postgresql")
    print("hardware_programming=human_only")
    return 0


if __name__ == "__main__":
    sys.exit(main())
