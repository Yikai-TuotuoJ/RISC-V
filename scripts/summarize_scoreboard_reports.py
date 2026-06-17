#!/usr/bin/env python3
"""Parse the Phase 16 scoreboard simulation log into Markdown and CSV reports."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


REQUIRED_FIELDS = (
    "accepted",
    "immediate_ready",
    "wait_src1",
    "wait_src2",
    "wakeups",
    "broadcasts",
    "dependencies",
    "full_stalls",
    "thread0_accepted",
    "thread1_accepted",
    "thread0_wakeups",
    "thread1_wakeups",
    "checks",
    "errors",
    "pass",
)


def parse_scoreperf(log_text: str) -> dict[str, str]:
    lines = [line for line in log_text.splitlines() if line.startswith("SCOREPERF:")]
    if not lines:
        raise ValueError("missing SCOREPERF line")
    fields = dict(re.findall(r"(\w+)=([^\s]+)", lines[-1]))
    missing = [field for field in REQUIRED_FIELDS if field not in fields]
    if missing:
        raise ValueError(f"missing SCOREPERF fields: {', '.join(missing)}")
    return fields


def read_powershell_log(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    return raw.decode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--markdown", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    args = parser.parse_args()

    fields = parse_scoreperf(read_powershell_log(args.log))
    numeric = {key: int(value) for key, value in fields.items() if key != "pass"}
    if numeric["checks"] < 20:
        raise ValueError("fewer than 20 meaningful checks were reported")
    if numeric["errors"] != 0 or fields["pass"] != "PASS":
        raise ValueError("scoreboard simulation reported failure")

    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    rows = [(field, fields[field]) for field in REQUIRED_FIELDS]
    args.markdown.write_text(
        "# Phase 16 Scoreboard Summary\n\n"
        "| Metric | Value |\n"
        "| --- | ---: |\n"
        + "".join(f"| `{name}` | {value} |\n" for name, value in rows)
        + "\n## Interpretation\n\n"
        "- `accepted` counts entries allocated into the standalone readiness model.\n"
        "- `dependencies` counts accepted instructions that waited for at least one source.\n"
        "- `wakeups` counts source operands made ready by matching thread-aware broadcasts.\n"
        "- `full_stalls` proves the finite reservation-station-like capacity is enforced.\n"
        "- This model observes readiness only; it does not perform out-of-order architectural commit.\n",
        encoding="utf-8",
    )
    with args.csv.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["metric", "value"])
        writer.writerows(rows)
    print(f"PASS: scoreboard reports generated from {args.log}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
