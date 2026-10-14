"""Offline-safe runtime helpers for the FPGA Edge Agent.

This module deliberately uses only Python's standard library. PostgreSQL writes
are not attempted unless an approved psycopg driver is installed and a database
URL is present. Local event archival and report generation remain available
without silently changing the configured database backend.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
EVENT_ROOT = ROOT / "runtime" / "events"
CHECKPOINT_ROOT = ROOT / "runtime" / "checkpoints"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def new_id(prefix: str) -> str:
    return f"{prefix}-{uuid.uuid4().hex}"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def redact_database_url(url: str | None) -> str | None:
    if not url:
        return None
    # Avoid printing credentials while keeping scheme/host useful for diagnostics.
    if "@" in url and "://" in url:
        scheme, rest = url.split("://", 1)
        authority, tail = rest.split("@", 1)
        user = authority.split(":", 1)[0]
        return f"{scheme}://{user}:***@{tail}"
    return "***configured***"


def event_path(session_id: str, when: str | None = None) -> Path:
    stamp = (when or utc_now())[:7].replace("-", "/")
    path = EVENT_ROOT / stamp / f"session-{session_id}.jsonl"
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def append_event(event: dict[str, Any]) -> Path:
    required = ("event_id", "project_id", "event_type", "schema_version", "occurred_at")
    missing = [key for key in required if not event.get(key)]
    if missing:
        raise ValueError(f"event missing required fields: {', '.join(missing)}")
    event = dict(event)
    event.setdefault("payload", {})
    event.setdefault("recorded_at", utc_now())
    event["payload_hash"] = sha256_bytes(
        json.dumps(event["payload"], sort_keys=True, ensure_ascii=False).encode("utf-8")
    )
    session_id = event.get("session_id") or "unassigned"
    path = event_path(session_id, event["occurred_at"])
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")
    return path


def write_checkpoint(checkpoint: dict[str, Any]) -> Path:
    if not checkpoint.get("checkpoint_id"):
        checkpoint = {"checkpoint_id": new_id("CP"), **checkpoint}
    checkpoint.setdefault("created_at", utc_now())
    data = json.dumps(checkpoint, ensure_ascii=False, sort_keys=True, indent=2).encode("utf-8")
    checkpoint["content_hash"] = sha256_bytes(data)
    CHECKPOINT_ROOT.mkdir(parents=True, exist_ok=True)
    path = CHECKPOINT_ROOT / f"{checkpoint['checkpoint_id']}.json"
    path.write_text(json.dumps(checkpoint, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return path


def database_health() -> dict[str, Any]:
    url = os.environ.get("FPGA_AGENT_DATABASE_URL")
    result: dict[str, Any] = {
        "backend": "postgresql",
        "configured": bool(url),
        "url": redact_database_url(url),
        "driver": None,
        "status": "UNAVAILABLE",
        "message": None,
    }
    if not url:
        result["message"] = "FPGA_AGENT_DATABASE_URL is not set"
        return result
    driver = None
    for name in ("psycopg", "psycopg2"):
        try:
            driver = __import__(name)
            result["driver"] = name
            break
        except ImportError:
            continue
    if driver is None:
        result["message"] = "No approved psycopg/psycopg2 driver is installed; no connection attempted"
        return result
    try:
        with driver.connect(url, connect_timeout=3) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        result["status"] = "HEALTHY"
        result["message"] = "connection and SELECT 1 succeeded"
    except Exception as exc:  # driver-specific exception types vary
        result["message"] = f"connection failed: {type(exc).__name__}"
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="FPGA Edge Agent offline runtime helpers")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("db-health")
    event_parser = sub.add_parser("event")
    event_parser.add_argument("--type", required=True)
    event_parser.add_argument("--project", default="FPGA_EDGE_TI60")
    event_parser.add_argument("--session", default=None)
    event_parser.add_argument("--node", default=None)
    event_parser.add_argument("--before", default=None)
    event_parser.add_argument("--after", default=None)
    event_parser.add_argument("--payload", default="{}")
    checkpoint_parser = sub.add_parser("checkpoint")
    checkpoint_parser.add_argument("path", type=Path)
    args = parser.parse_args()
    if args.command == "db-health":
        print(json.dumps(database_health(), ensure_ascii=False, indent=2))
        return 0
    if args.command == "event":
        event = {
            "event_id": new_id("EVT"),
            "project_id": args.project,
            "session_id": args.session,
            "node_id": args.node,
            "event_type": args.type,
            "schema_version": "1.0",
            "occurred_at": utc_now(),
            "state_before": args.before,
            "state_after": args.after,
            "payload": json.loads(args.payload),
        }
        print(append_event(event))
        return 0
    if args.command == "checkpoint":
        print(write_checkpoint(json.loads(args.path.read_text(encoding="utf-8"))))
        return 0
    return 2


if __name__ == "__main__":
    sys.exit(main())
