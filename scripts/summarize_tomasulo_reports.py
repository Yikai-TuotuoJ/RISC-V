#!/usr/bin/env python3
"""Parse Phase 17 Tomasulo-style simulation logs into Markdown and CSV."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


REQUIRED_FIELDS = (
    "test",
    "accepted",
    "rs_allocs",
    "rs_full_stalls",
    "ready_observed",
    "issued",
    "ooo_issue_events",
    "broadcasts",
    "wakeups",
    "stale_tag_ignored",
    "completed",
    "unsupported",
    "thread0_accepted",
    "thread1_accepted",
    "thread0_issued",
    "thread1_issued",
    "thread0_completed",
    "thread1_completed",
    "checks",
    "errors",
    "pass",
)


def read_log(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    return raw.decode("utf-8")


def parse_tomperf(text: str) -> dict[str, str]:
    lines = [line for line in text.splitlines() if line.startswith("TOMPERF:")]
    if not lines:
        raise ValueError("missing TOMPERF line")
    fields = dict(re.findall(r"(\w+)=([^\s]+)", lines[-1]))
    missing = [field for field in REQUIRED_FIELDS if field not in fields]
    if missing:
        raise ValueError(f"missing TOMPERF fields: {', '.join(missing)}")
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--markdown", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    args = parser.parse_args()

    fields = parse_tomperf(read_log(args.log))
    numeric = {key: int(value) for key, value in fields.items() if key not in ("test", "pass")}
    if numeric["checks"] < 20:
        raise ValueError("fewer than 20 meaningful Tomasulo checks were reported")
    if numeric["errors"] != 0 or fields["pass"] != "PASS":
        raise ValueError("Tomasulo simulation reported failure")
    if numeric["issued"] > numeric["accepted"]:
        raise ValueError("issued exceeds accepted")
    if numeric["completed"] > numeric["issued"]:
        raise ValueError("completed exceeds issued")
    if numeric["ooo_issue_events"] < 1:
        raise ValueError("out-of-order issue event was not observed")
    if numeric["stale_tag_ignored"] < 1:
        raise ValueError("stale tag protection was not exercised")

    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    rows = [(field, fields[field]) for field in REQUIRED_FIELDS]
    args.markdown.write_text(
        "# Phase 17 Tomasulo-Style Summary\n\n"
        "| Metric | Value |\n"
        "| --- | ---: |\n"
        + "".join(f"| `{name}` | {value} |\n" for name, value in rows)
        + "\n## Interpretation\n\n"
        "- `ooo_issue_events` counts cases where a younger ready instruction issued while an older entry waited.\n"
        "- `wakeups` counts operand sources made ready by CDB-style broadcasts.\n"
        "- `stale_tag_ignored` proves older producers cannot clobber a newer architectural destination tag.\n"
        "- This is a constrained scheduling experiment; it does not include a ROB, speculative commit, or a load/store queue.\n",
        encoding="utf-8",
    )
    with args.csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["metric", "value"])
        writer.writerows(rows)
    print(f"PASS: Tomasulo reports generated from {args.log}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
