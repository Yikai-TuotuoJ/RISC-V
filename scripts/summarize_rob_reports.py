#!/usr/bin/env python3
"""Parse Phase 18 ROB simulation logs into Markdown and CSV."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

REQUIRED_FIELDS = (
    "test",
    "dispatched",
    "rob_allocs",
    "rob_full_stalls",
    "rs_allocs",
    "rs_full_stalls",
    "issued",
    "ooo_issue_events",
    "completed",
    "broadcasts",
    "wakeups",
    "commits",
    "commit_stalls",
    "younger_done_waiting",
    "stale_tag_ignored",
    "x0_commit_suppressed",
    "unsupported",
    "thread0_commits",
    "thread1_commits",
    "checks",
    "errors",
    "pass",
)


def read_log(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    return raw.decode("utf-8")


def parse_robperf(text: str) -> dict[str, str]:
    lines = [line for line in text.splitlines() if line.startswith("ROBPERF:")]
    if not lines:
        raise ValueError("missing ROBPERF line")
    fields = dict(re.findall(r"(\w+)=([^\s]+)", lines[-1]))
    missing = [field for field in REQUIRED_FIELDS if field not in fields]
    if missing:
        raise ValueError(f"missing ROBPERF fields: {', '.join(missing)}")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--markdown", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    args = parser.parse_args()

    fields = parse_robperf(read_log(args.log))
    numeric = {key: int(value) for key, value in fields.items() if key not in ("test", "pass")}

    if numeric["checks"] < 20:
        raise ValueError("fewer than 20 meaningful ROB checks were reported")
    if numeric["errors"] != 0 or fields["pass"] != "PASS":
        raise ValueError("ROB simulation reported failure")
    if numeric["issued"] > numeric["dispatched"]:
        raise ValueError("issued exceeds dispatched")
    if numeric["completed"] > numeric["issued"]:
        raise ValueError("completed exceeds issued")
    if numeric["commits"] > numeric["completed"]:
        raise ValueError("commits exceeds completed")
    if numeric["commit_stalls"] < 1:
        raise ValueError("head-not-ready commit stall was not observed")
    if numeric["younger_done_waiting"] < 1:
        raise ValueError("younger-completed-waiting event was not observed")
    if numeric["ooo_issue_events"] < 1:
        raise ValueError("out-of-order issue event was not observed")
    if numeric["stale_tag_ignored"] < 1:
        raise ValueError("stale tag protection was not exercised")
    if numeric["x0_commit_suppressed"] < 1:
        raise ValueError("x0 commit suppression was not exercised")

    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    rows = [(field, fields[field]) for field in REQUIRED_FIELDS]
    args.markdown.write_text(
        "# Phase 18 ROB / In-Order Commit Summary\n\n"
        "| Metric | Value |\n"
        "| --- | ---: |\n"
        + "".join(f"| `{name}` | {value} |\n" for name, value in rows)
        + "\n## Interpretation\n\n"
        "- `broadcasts` count execution completions placed on the CDB-style path.\n"
        "- `commits` count architectural retirement from the ROB head only.\n"
        "- `commit_stalls` proves the ROB refuses to skip an older not-ready head entry.\n"
        "- `younger_done_waiting` proves a younger completed instruction waited for older work to retire.\n"
        "- `stale_tag_ignored` covers both stale completion and stale register-status clear attempts.\n"
        "- This is a constrained ROB experiment; it does not include an LSQ, branch speculation, precise exceptions, or a production OOO backend.\n",
        encoding="utf-8",
    )
    with args.csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["metric", "value"])
        writer.writerows(rows)
    print(f"PASS: ROB reports generated from {args.log}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
