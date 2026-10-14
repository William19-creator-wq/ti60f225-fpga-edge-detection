"""Minimal parameterized PostgreSQL adapter.

The module has no hard dependency at import time. It imports an approved
psycopg/psycopg2 driver only when a caller explicitly requests a database
operation. It never creates databases, roles, schemas, or migrations.
"""
from __future__ import annotations

import json
import os
from contextlib import contextmanager
from typing import Any, Iterator


def _driver():
    for name in ("psycopg", "psycopg2"):
        try:
            return __import__(name)
        except ImportError:
            continue
    raise RuntimeError("No approved psycopg/psycopg2 driver is installed")


def _url() -> str:
    value = os.environ.get("FPGA_AGENT_DATABASE_URL")
    if not value:
        raise RuntimeError("FPGA_AGENT_DATABASE_URL is not set")
    return value


@contextmanager
def connection() -> Iterator[Any]:
    driver = _driver()
    conn = driver.connect(_url(), connect_timeout=3)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def insert_event(event: dict[str, Any]) -> None:
    required = ("event_id", "project_id", "event_type", "schema_version", "occurred_at", "payload_hash")
    missing = [key for key in required if not event.get(key)]
    if missing:
        raise ValueError(f"event missing required fields: {', '.join(missing)}")
    query = """
        INSERT INTO events (
          event_id, project_id, session_id, turn_id, operation_id, artifact_id,
          node_id, event_type, schema_version, occurred_at, state_before,
          state_after, payload, payload_hash
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb, %s)
        ON CONFLICT (event_id) DO NOTHING
    """
    params = (
        event["event_id"], event["project_id"], event.get("session_id"), event.get("turn_id"),
        event.get("operation_id"), event.get("artifact_id"), event.get("node_id"),
        event["event_type"], event["schema_version"], event["occurred_at"],
        event.get("state_before"), event.get("state_after"),
        json.dumps(event.get("payload", {}), ensure_ascii=False), event["payload_hash"],
    )
    with connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query, params)


def upsert_project(project: dict[str, Any]) -> None:
    query = """
        INSERT INTO projects (project_id, name, root_path, control_plane_path, metadata)
        VALUES (%s, %s, %s, %s, %s::jsonb)
        ON CONFLICT (project_id) DO UPDATE SET
          name = EXCLUDED.name,
          root_path = EXCLUDED.root_path,
          control_plane_path = EXCLUDED.control_plane_path,
          metadata = EXCLUDED.metadata
    """
    params = (
        project["project_id"], project["name"], project["root_path"],
        project["control_plane_path"], json.dumps(project.get("metadata", {}), ensure_ascii=False),
    )
    with connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query, params)


def insert_metric(metric: dict[str, Any]) -> None:
    query = """
        INSERT INTO metrics (metric_id, project_id, session_id, node_id, name, value, unit, labels)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s::jsonb)
        ON CONFLICT (metric_id) DO NOTHING
    """
    params = (
        metric["metric_id"], metric["project_id"], metric.get("session_id"), metric.get("node_id"),
        metric["name"], metric["value"], metric.get("unit"),
        json.dumps(metric.get("labels", {}), ensure_ascii=False),
    )
    with connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(query, params)
