#!/usr/bin/env python3
"""Parse Phase 19 LSQ simulation logs into Markdown and CSV."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

REQUIRED_FIELDS = (
    "test",
    "memory_uops",
    "loads",
    "stores",
    "lsq_full_stalls",
    "addr_waits",
    "store_addr_waits",
    "store_data_waits",
    "load_store_order_stalls",
    "conservative_order_stalls",
    "load_execs",
    "load_completions",
    "store_commits",
    "store_completions",
    "rob_commits",
    "rob_commit_stalls",
    "alu_completes",
    "stale_tag_ignored",
    "x0_commit_suppressed",
    "unsupported",
    "checks",
    "errors",
    "pass",
)


def read_log(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    return raw.decode("utf-8")


def parse_lsqperf(text: str) -> dict[str, str]:
    lines = [line for line in text.splitlines() if line.startswith("LSQPERF:")]
    if not lines:
        raise ValueError("missing LSQPERF line")
    fields = dict(re.findall(r"(\w+)=([^\s]+)", lines[-1]))
    missing = [field for field in REQUIRED_FIELDS if field not in fields]
    if missing:
        raise ValueError(f"missing LSQPERF fields: {', '.join(missing)}")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--markdown", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    args = parser.parse_args()

    fields = parse_lsqperf(read_log(args.log))
    numeric = {key: int(value) for key, value in fields.items() if key not in ("test", "pass")}

    if numeric["checks"] < 20:
        raise ValueError("fewer than 20 meaningful LSQ checks were reported")
    if numeric["errors"] != 0 or fields["pass"] != "PASS":
        raise ValueError("LSQ simulation reported failure")
    if numeric["memory_uops"] != numeric["loads"] + numeric["stores"]:
        raise ValueError("memory_uops does not equal loads + stores")
    if numeric["load_execs"] > numeric["loads"]:
        raise ValueError("load_execs exceeds loads")
    if numeric["load_completions"] < numeric["load_execs"]:
        raise ValueError("load_completions is below load_execs")
    if numeric["store_commits"] > numeric["stores"]:
        raise ValueError("store_commits exceeds stores")
    if numeric["store_completions"] < numeric["store_commits"]:
        raise ValueError("store_completions is below store_commits")
    if numeric["lsq_full_stalls"] < 1:
        raise ValueError("LSQ full condition was not exercised")
    if numeric["addr_waits"] < 1:
        raise ValueError("load address wait was not exercised")
    if numeric["store_data_waits"] < 1:
        raise ValueError("store data wait was not exercised")
    if numeric["load_store_order_stalls"] < 1:
        raise ValueError("load behind older store stall was not exercised")
    if numeric["rob_commit_stalls"] < 1:
        raise ValueError("ROB commit stall was not exercised")
    if numeric["stale_tag_ignored"] < 1:
        raise ValueError("wrong/stale tag protection was not exercised")
    if numeric["x0_commit_suppressed"] < 1:
        raise ValueError("x0 suppression was not exercised")
    if numeric["unsupported"] < 1:
        raise ValueError("unsupported op path was not exercised")

    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    rows = [(field, fields[field]) for field in REQUIRED_FIELDS]
    args.markdown.write_text(
        "# Phase 19 Limited LSQ Preparation Summary\n\n"
        "| Metric | Value |\n"
        "| --- | ---: |\n"
        + "".join(f"| `{name}` | {value} |\n" for name, value in rows)
        + "\n## Interpretation\n\n"
        "- `loads` and `stores` count memory uops allocated into the LSQ.\n"
        "- `addr_waits` and `store_data_waits` prove address and store-data readiness are tracked independently.\n"
        "- `load_store_order_stalls` proves a younger load waited behind an older unresolved store.\n"
        "- `store_commits` count stores that updated memory only when the ROB reached the store.\n"
        "- `stale_tag_ignored` shows wrong-tag wakeups are rejected.\n"
        "- This is a limited LSQ preparation experiment, not full speculative memory disambiguation, replay, or store-to-load forwarding.\n",
        encoding="utf-8",
    )
    with args.csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["metric", "value"])
        writer.writerows(rows)
    print(f"PASS: LSQ reports generated from {args.log}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
