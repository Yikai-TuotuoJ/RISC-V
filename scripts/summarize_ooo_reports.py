#!/usr/bin/env python3
"""Parse Phase 20 integrated OOO simulation logs into Markdown and CSV."""
from __future__ import annotations
import argparse, csv, re
from pathlib import Path

REQUIRED_FIELDS = (
    "test", "decoded", "dispatched", "rob_allocs", "rob_full_stalls", "rs_allocs", "rs_full_stalls",
    "lsq_allocs", "lsq_full_stalls", "alu_issues", "load_issues", "store_commits", "broadcasts",
    "wakeups", "completed", "commits", "commit_stalls", "memory_order_stalls", "younger_done_waiting",
    "stale_tag_ignored", "x0_commit_suppressed", "unsupported", "checks", "errors", "pass"
)

def read_log(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    return raw.decode("utf-8")

def parse(text: str) -> dict[str, str]:
    lines = [line for line in text.splitlines() if line.startswith("OOOPERF:")]
    if not lines:
        raise ValueError("missing OOOPERF line")
    fields = dict(re.findall(r"(\w+)=([^\s]+)", lines[-1]))
    missing = [f for f in REQUIRED_FIELDS if f not in fields]
    if missing:
        raise ValueError("missing OOOPERF fields: " + ", ".join(missing))
    return fields

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True, type=Path)
    ap.add_argument("--markdown", required=True, type=Path)
    ap.add_argument("--csv", required=True, type=Path)
    args = ap.parse_args()
    fields = parse(read_log(args.log))
    n = {k:int(v) for k,v in fields.items() if k not in ("test", "pass")}
    if n["checks"] < 30:
        raise ValueError("fewer than 30 meaningful integrated OOO checks were reported")
    if n["errors"] != 0 or fields["pass"] != "PASS":
        raise ValueError("integrated OOO simulation reported failure")
    if n["dispatched"] > n["decoded"]:
        raise ValueError("dispatched exceeds decoded")
    if n["commits"] > n["dispatched"]:
        raise ValueError("commits exceeds dispatched")
    if n["alu_issues"] > n["rs_allocs"]:
        raise ValueError("ALU issues exceed RS allocations")
    if n["load_issues"] > n["lsq_allocs"]:
        raise ValueError("load issues exceed LSQ allocations")
    for field in ("rs_full_stalls", "lsq_full_stalls", "commit_stalls", "memory_order_stalls", "younger_done_waiting", "stale_tag_ignored", "x0_commit_suppressed", "unsupported"):
        if n[field] < 1:
            raise ValueError(f"required event not exercised: {field}")
    rows = [(f, fields[f]) for f in REQUIRED_FIELDS]
    args.markdown.parent.mkdir(parents=True, exist_ok=True)
    args.csv.parent.mkdir(parents=True, exist_ok=True)
    args.markdown.write_text(
        "# Phase 20 Integrated OOO Experiment Summary\n\n"
        "| Metric | Value |\n| --- | ---: |\n" + "".join(f"| `{k}` | {v} |\n" for k,v in rows) +
        "\n## Interpretation\n\n"
        "- `rs_allocs` and `alu_issues` show reservation-station allocation and readiness-based ALU issue.\n"
        "- `broadcasts` and `wakeups` show CDB-style completion and dependent operand wakeup.\n"
        "- `commits`, `commit_stalls`, and `younger_done_waiting` show ROB-based in-order commit despite out-of-order completion.\n"
        "- `lsq_allocs`, `load_issues`, `store_commits`, and `memory_order_stalls` show limited LSQ behavior with conservative memory ordering.\n"
        "- This is an integrated OOO-concept core, not a production OOO backend with branch speculation, precise exceptions, full renaming, or memory replay.\n",
        encoding="utf-8")
    with args.csv.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["metric", "value"]); w.writerows(rows)
    print(f"PASS: OOO reports generated from {args.log}")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
