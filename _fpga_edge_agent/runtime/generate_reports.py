"""Generate local Markdown/CSV/HTML summaries from append-only events."""
from __future__ import annotations

import csv
import html
import json
import hashlib
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EVENT_ROOT = ROOT / "runtime" / "events"
REPORT_ROOT = ROOT / "reports"
ALERT_ROOT = ROOT / "runtime" / "local_archive"

sys.path.insert(0, str(ROOT / "runtime"))
from agent_runtime import database_health, utc_now  # noqa: E402


def load_events() -> list[dict]:
    events = []
    for path in sorted(EVENT_ROOT.rglob("*.jsonl")):
        for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            try:
                item = json.loads(line)
                item["_source"] = str(path)
                events.append(item)
            except json.JSONDecodeError as exc:
                events.append({"event_type": "INVALID_EVENT", "_source": str(path), "line": line_no, "error": str(exc)})
    return events


def derive_alerts(events: list[dict]) -> list[dict]:
    alerts: list[dict] = []
    db = database_health()
    if db["status"] != "HEALTHY":
        alerts.append({
            "alert_id": "ALT-" + hashlib.sha256(b"DATABASE_UNAVAILABLE").hexdigest()[:16],
            "alert_type": "DATABASE_UNAVAILABLE",
            "severity": "HIGH",
            "state": "OPEN",
            "message": db.get("message"),
            "created_at": utc_now(),
        })
    latest_by_node: dict[str, dict] = {}
    for item in events:
        node = item.get("node_id")
        if node:
            latest_by_node[node] = item
        event_type = str(item.get("event_type", "")).upper()
        if "ERROR" in event_type or "EXCEPTION" in event_type or event_type == "INVALID_EVENT":
            fingerprint = json.dumps([item.get("event_id"), event_type], sort_keys=True)
            alerts.append({
                "alert_id": "ALT-" + hashlib.sha256(fingerprint.encode()).hexdigest()[:16],
                "alert_type": "RUNTIME_EXCEPTION",
                "severity": "HIGH",
                "state": "OPEN",
                "message": str(item.get("payload") or item.get("error") or event_type),
                "node_id": node,
                "created_at": item.get("occurred_at") or utc_now(),
            })
    for node, item in latest_by_node.items():
        state = item.get("state_after")
        if state in ("WAITING_HUMAN_PROGRAM", "WAITING_HUMAN_OBSERVATION"):
            fingerprint = f"HUMAN_GATE_PENDING:{node}:{item.get('event_id')}"
            alerts.append({
                "alert_id": "ALT-" + hashlib.sha256(fingerprint.encode()).hexdigest()[:16],
                "alert_type": "HUMAN_GATE_PENDING",
                "severity": "INFO",
                "state": "OPEN",
                "message": f"Node {node} requires human hardware action/observation",
                "node_id": node,
                "created_at": item.get("occurred_at") or utc_now(),
            })
    return alerts


def append_alerts(alerts: list[dict]) -> None:
    ALERT_ROOT.mkdir(parents=True, exist_ok=True)
    path = ALERT_ROOT / "alerts.jsonl"
    existing = set()
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                existing.add(json.loads(line).get("alert_id"))
            except json.JSONDecodeError:
                continue
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        for alert in alerts:
            if alert.get("alert_id") not in existing:
                handle.write(json.dumps(alert, ensure_ascii=False, sort_keys=True) + "\n")
                existing.add(alert.get("alert_id"))


def write_reports(events: list[dict]) -> None:
    REPORT_ROOT.mkdir(parents=True, exist_ok=True)
    (REPORT_ROOT / "session").mkdir(exist_ok=True)
    (REPORT_ROOT / "node").mkdir(exist_ok=True)
    (REPORT_ROOT / "build").mkdir(exist_ok=True)
    (REPORT_ROOT / "hardware").mkdir(exist_ok=True)
    (REPORT_ROOT / "audit").mkdir(exist_ok=True)
    types = Counter(item.get("event_type", "UNKNOWN") for item in events)
    nodes = Counter(item.get("node_id") or "UNASSIGNED" for item in events)
    status = Counter(item.get("state_after") or "UNKNOWN" for item in events)
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    lines = ["# Session Report", "", f"Generated: `{now}`", "", f"Events: **{len(events)}**", "", "## Event types", ""]
    lines.extend(f"- `{key}`: {value}" for key, value in sorted(types.items()))
    lines.extend(["", "## Nodes", ""])
    lines.extend(f"- `{key}`: {value}" for key, value in sorted(nodes.items()))
    lines.extend(["", "## State transitions", ""])
    lines.extend(f"- `{key}`: {value}" for key, value in sorted(status.items()))
    (REPORT_ROOT / "session" / "session_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    node_lines = ["# Node Report", "", f"Generated: `{now}`", ""]
    node_lines.extend(f"- `{key}`: {value} events" for key, value in sorted(nodes.items()))
    (REPORT_ROOT / "node" / "node_report.md").write_text("\n".join(node_lines) + "\n", encoding="utf-8")

    build_events = [item for item in events if "BUILD" in str(item.get("event_type", "")).upper()]
    build_lines = ["# Build Report", "", f"Build-related events: **{len(build_events)}**", ""]
    build_lines.extend(f"- `{item.get('event_type')}` `{item.get('occurred_at', '')}` `{item.get('state_after', '')}`" for item in build_events)
    (REPORT_ROOT / "build" / "build_report.md").write_text("\n".join(build_lines) + "\n", encoding="utf-8")

    observation_events = [item for item in events if "OBSERV" in str(item.get("event_type", "")).upper()]
    hardware_lines = ["# Hardware Observation Report", "", f"Observation-related events: **{len(observation_events)}**", ""]
    hardware_lines.extend(f"- `{item.get('node_id', '')}` `{item.get('event_type')}` `{item.get('state_after', '')}`" for item in observation_events)
    (REPORT_ROOT / "hardware" / "hardware_observation_report.md").write_text("\n".join(hardware_lines) + "\n", encoding="utf-8")

    approval_events = [item for item in events if "APPROVAL" in str(item.get("event_type", "")).upper()]
    approval_lines = ["# Approval Queue", "", f"Approval-related events: **{len(approval_events)}**", ""]
    approval_lines.extend(f"- `{item.get('event_id', '')}` `{item.get('state_after', '')}` `{item.get('payload', {})}`" for item in approval_events)
    (REPORT_ROOT / "audit" / "approval_queue.md").write_text("\n".join(approval_lines) + "\n", encoding="utf-8")

    exception_events = [item for item in events if "EXCEPTION" in str(item.get("event_type", "")).upper() or "ERROR" in str(item.get("event_type", "")).upper()]
    exception_lines = ["# Exception Report", "", f"Exception/error events: **{len(exception_events)}**", ""]
    exception_lines.extend(f"- `{item.get('event_id', '')}` `{item.get('event_type')}` `{item.get('payload', {})}`" for item in exception_events)
    (REPORT_ROOT / "audit" / "exception_report.md").write_text("\n".join(exception_lines) + "\n", encoding="utf-8")

    artifact_events = [item for item in events if "ARTIFACT" in str(item.get("event_type", "")).upper()]
    artifact_lines = ["# Artifact Diff Report", "", f"Artifact-related events: **{len(artifact_events)}**", "", "Artifact comparison requires hashes from Artifact Manifest.", ""]
    artifact_lines.extend(f"- `{item.get('artifact_id', '')}` `{item.get('event_type')}` `{item.get('payload', {})}`" for item in artifact_events)
    (REPORT_ROOT / "audit" / "artifact_diff_report.md").write_text("\n".join(artifact_lines) + "\n", encoding="utf-8")

    metrics = {
        "event_count": len(events),
        "event_type_counts": dict(types),
        "node_event_counts": dict(nodes),
        "state_counts": dict(status),
        "build_event_count": len(build_events),
        "observation_event_count": len(observation_events),
        "approval_event_count": len(approval_events),
        "exception_event_count": len(exception_events),
        "artifact_event_count": len(artifact_events),
    }
    (REPORT_ROOT / "audit" / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    alerts = derive_alerts(events)
    append_alerts(alerts)
    alert_lines = ["# Alerts", "", f"Open alerts derived in this report: **{len(alerts)}**", ""]
    alert_lines.extend(f"- `{item['severity']}` `{item['alert_type']}` `{item.get('node_id', '')}`: {item.get('message', '')}" for item in alerts)
    (REPORT_ROOT / "audit" / "alerts.md").write_text("\n".join(alert_lines) + "\n", encoding="utf-8")
    (REPORT_ROOT / "audit" / "alerts.json").write_text(json.dumps(alerts, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with (REPORT_ROOT / "audit" / "events.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["event_id", "event_type", "session_id", "turn_id", "node_id", "state_before", "state_after", "occurred_at", "_source"])
        writer.writeheader()
        for item in events:
            writer.writerow({key: item.get(key, "") for key in writer.fieldnames})
    rows = "".join(
        f"<tr><td>{html.escape(str(item.get('occurred_at', '')))}</td><td>{html.escape(str(item.get('event_type', '')))}</td><td>{html.escape(str(item.get('node_id', '')))}</td><td>{html.escape(str(item.get('state_after', '')))}</td></tr>"
        for item in events[-500:]
    )
    html_doc = "<!doctype html><meta charset='utf-8'><title>FPGA Edge Agent Events</title><h1>FPGA Edge Agent Events</h1><table border='1'><tr><th>Time</th><th>Type</th><th>Node</th><th>State</th></tr>" + rows + "</table>"
    (REPORT_ROOT / "audit" / "events.html").write_text(html_doc, encoding="utf-8")
    (REPORT_ROOT / "audit" / "events.json").write_text(json.dumps(events, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    write_reports(load_events())
