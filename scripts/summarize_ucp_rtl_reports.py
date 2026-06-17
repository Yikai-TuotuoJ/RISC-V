#!/usr/bin/env python3
"""Summarize Phase 13.5 RTL UCP cache reports."""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / "reports" / "perf" / "ucp_rtl_logs"
MD_OUT = ROOT / "reports" / "perf" / "ucp_rtl_partition_summary.md"
CSV_OUT = ROOT / "reports" / "perf" / "ucp_rtl_partition_summary.csv"

PAIR_RE = re.compile(r"(\w+)=([^\s]+)")

FIELDS = [
    "benchmark", "policy", "pass", "cycles", "retired", "cpi", "stalls", "loads", "stores",
    "l1_accesses", "l1_hits", "l1_misses", "l1_hit_rate",
    "l1_core0_accesses", "l1_core0_hits", "l1_core0_misses",
    "l1_core1_accesses", "l1_core1_hits", "l1_core1_misses",
    "l2_accesses", "l2_hits", "l2_misses", "l2_hit_rate",
    "l3_accesses", "l3_hits", "l3_misses", "l3_hit_rate",
    "l3_stream0_alloc", "l3_stream0_accesses", "l3_stream0_hits", "l3_stream0_misses", "l3_stream0_hit_rate",
    "l3_stream1_alloc", "l3_stream1_accesses", "l3_stream1_hits", "l3_stream1_misses", "l3_stream1_hit_rate",
    "backing_mem_accesses", "dynamic_repartitions", "dynamic_interval_count",
]


def parse_logs() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for log in sorted(LOG_DIR.glob("*.log")):
        for line in log.read_text(encoding="ascii", errors="ignore").splitlines():
            if not line.startswith("UCPRTL:"):
                continue
            row = {k: v for k, v in PAIR_RE.findall(line)}
            row["log"] = log.name
            rows.append(row)
    return rows


def num(row: dict[str, str], key: str) -> float:
    try:
        return float(row.get(key, "0"))
    except ValueError:
        return 0.0


def write_csv(rows: list[dict[str, str]]) -> None:
    CSV_OUT.parent.mkdir(parents=True, exist_ok=True)
    with CSV_OUT.open("w", newline="", encoding="ascii") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS + ["log"])
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in FIELDS + ["log"]})


def write_md(rows: list[dict[str, str]]) -> None:
    MD_OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# RTL UCP Cache Partition Summary",
        "",
        "This report is generated from the pipeline-integrated Phase 13.5 RTL cache hierarchy:",
        "",
        "```text",
        "Pipeline MEM stage -> private L1 bank -> shared L2 -> UCP-partitioned L3 -> backing memory",
        "```",
        "",
        "The design still has one CPU pipeline. Logical cores/streams are derived from address regions for this experiment.",
        "",
        "| benchmark | policy | pass | cycles | CPI | L1 hits/misses | L2 hits/misses | L3 alloc S0/S1 | L3 S0 hits/misses | L3 S1 hits/misses | backing accesses | repartitions |",
        "|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            "| {benchmark} | {policy} | {passv} | {cycles} | {cpi} | {l1h}/{l1m} | {l2h}/{l2m} | {a0}/{a1} | {s0h}/{s0m} | {s1h}/{s1m} | {backing} | {reparts} |".format(
                benchmark=row.get("benchmark", ""), policy=row.get("policy", ""), passv=row.get("pass", ""),
                cycles=row.get("cycles", ""), cpi=row.get("cpi", ""),
                l1h=row.get("l1_hits", ""), l1m=row.get("l1_misses", ""),
                l2h=row.get("l2_hits", ""), l2m=row.get("l2_misses", ""),
                a0=row.get("l3_stream0_alloc", ""), a1=row.get("l3_stream1_alloc", ""),
                s0h=row.get("l3_stream0_hits", ""), s0m=row.get("l3_stream0_misses", ""),
                s1h=row.get("l3_stream1_hits", ""), s1m=row.get("l3_stream1_misses", ""),
                backing=row.get("backing_mem_accesses", ""), reparts=row.get("dynamic_repartitions", ""),
            )
        )
    lines.extend(["", "## Design Analysis", ""])
    pressure_equal = next((r for r in rows if r.get("benchmark") == "utility_pressure" and r.get("policy") == "0"), None)
    pressure_utility = next((r for r in rows if r.get("benchmark") == "utility_pressure" and r.get("policy") == "1"), None)
    if pressure_equal and pressure_utility:
        delta_hits = int(num(pressure_utility, "l3_hits") - num(pressure_equal, "l3_hits"))
        delta_cycles = int(num(pressure_equal, "cycles") - num(pressure_utility, "cycles"))
        delta_backing = int(num(pressure_equal, "backing_mem_accesses") - num(pressure_utility, "backing_mem_accesses"))
        lines.extend([
            f"- On `utility_pressure`, utility-guided L3 partitioning increased L3 hits by {delta_hits} and reduced backing-memory accesses by {delta_backing} versus equal partitioning.",
            f"- The same benchmark reduced simulated cycles by {delta_cycles} in this controlled setup, because fewer L3 misses reached backing memory.",
        ])
    lines.extend([
        "- Private L1 banks model the common CPU idea that the closest cache is core-local and latency-sensitive.",
        "- The L2 remains shared and unpartitioned, so both logical streams can reuse recently fetched lines before the L3 policy matters.",
        "- UCP is placed at L3 because a last-level cache is where capacity sharing and partitioning policy are most natural.",
        "- Address-derived stream IDs are an educational stand-in for future thread/core IDs; this is not multicore execution or coherence.",
        "- Correctness checks include architectural register state, x0, no illegal instruction, counter consistency, and partition quota checks, not just hit-rate improvements.",
        "- Policy `2` adds a simplified dynamic UCP monitor that uses shadow tags, exhaustive split search, and safe L3 invalidation on repartition.",
        "- This is still an educational two-stream UCP model, not production cache QoS, coherence, or multicore runtime management.",
    ])
    MD_OUT.write_text("\n".join(lines) + "\n", encoding="ascii")


def main() -> int:
    rows = parse_logs()
    if not rows:
        print(f"FAIL: no UCPRTL rows found in {LOG_DIR}")
        return 1
    bad = [r for r in rows if r.get("pass") != "PASS"]
    write_csv(rows)
    write_md(rows)
    print(f"Wrote {MD_OUT}")
    print(f"Wrote {CSV_OUT}")
    if bad:
        print(f"FAIL: {len(bad)} UCP RTL rows did not pass")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

