#!/usr/bin/env python3
"""Simplified UCP-style shared-cache partitioning model.

This is a trace-level educational model, not a production UCP implementation.
It replays logical workload/stream memory traces through a partitioned shared
cache and compares a static equal allocation against a deterministic
utility-guided allocation.
"""
from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple


@dataclass
class Access:
    workload: str
    op: str
    addr: int


@dataclass
class Result:
    trace: str
    policy: str
    workload: str
    allocated_lines: int
    accesses: int
    hits: int
    misses: int
    estimated_penalty_cycles: int
    total_policy_penalty_cycles: int
    total_policy_hits: int
    total_policy_misses: int

    @property
    def hit_rate(self) -> float:
        return (100.0 * self.hits / self.accesses) if self.accesses else 0.0

    @property
    def miss_rate(self) -> float:
        return 100.0 - self.hit_rate if self.accesses else 0.0


class LruPartition:
    def __init__(self, capacity: int):
        self.capacity = max(0, capacity)
        self.lines: List[int] = []

    def access(self, line_addr: int) -> bool:
        if self.capacity <= 0:
            return False
        if line_addr in self.lines:
            self.lines.remove(line_addr)
            self.lines.insert(0, line_addr)
            return True
        self.lines.insert(0, line_addr)
        if len(self.lines) > self.capacity:
            self.lines.pop()
        return False


def parse_trace(path: Path) -> List[Access]:
    accesses: List[Access] = []
    for lineno, raw in enumerate(path.read_text(encoding="ascii").splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) != 3:
            raise ValueError(f"{path}:{lineno}: expected '<workload> <op> <addr>'")
        workload, op, addr_text = parts
        op = op.upper()
        if op not in {"R", "W"}:
            raise ValueError(f"{path}:{lineno}: op must be R or W")
        accesses.append(Access(workload=workload, op=op, addr=int(addr_text, 0)))
    if not accesses:
        raise ValueError(f"{path}: trace contains no accesses")
    return accesses


def workloads_for(accesses: Iterable[Access]) -> List[str]:
    return sorted({a.workload for a in accesses})


def equal_allocation(workloads: List[str], total_lines: int) -> Dict[str, int]:
    if not workloads:
        return {}
    base = total_lines // len(workloads)
    rem = total_lines % len(workloads)
    return {w: base + (1 if i < rem else 0) for i, w in enumerate(workloads)}


def all_two_workload_allocations(workloads: List[str], total_lines: int) -> Iterable[Dict[str, int]]:
    if len(workloads) != 2:
        yield equal_allocation(workloads, total_lines)
        return
    a, b = workloads
    for a_lines in range(1, total_lines):
        yield {a: a_lines, b: total_lines - a_lines}


def replay(accesses: List[Access], allocation: Dict[str, int], line_bytes: int, miss_penalty: int) -> Tuple[Dict[str, Dict[str, int]], int, int]:
    parts = {w: LruPartition(lines) for w, lines in allocation.items()}
    stats: Dict[str, Dict[str, int]] = {w: {"accesses": 0, "hits": 0, "misses": 0} for w in allocation}
    for acc in accesses:
        if acc.workload not in parts:
            parts[acc.workload] = LruPartition(0)
            stats[acc.workload] = {"accesses": 0, "hits": 0, "misses": 0}
        line_addr = acc.addr // line_bytes
        hit = parts[acc.workload].access(line_addr)
        stats[acc.workload]["accesses"] += 1
        stats[acc.workload]["hits" if hit else "misses"] += 1
    total_hits = sum(s["hits"] for s in stats.values())
    total_misses = sum(s["misses"] for s in stats.values())
    return stats, total_hits, total_misses * miss_penalty


def choose_utility_guided(accesses: List[Access], workloads: List[str], total_lines: int, line_bytes: int, miss_penalty: int) -> Tuple[Dict[str, int], Dict[str, object]]:
    best_alloc: Dict[str, int] | None = None
    best_score: Tuple[int, int, Tuple[int, ...]] | None = None
    candidates = []
    for alloc in all_two_workload_allocations(workloads, total_lines):
        stats, hits, penalty = replay(accesses, alloc, line_bytes, miss_penalty)
        misses = penalty // miss_penalty if miss_penalty else sum(s["misses"] for s in stats.values())
        # Deterministic tie-breaker: prefer more total hits, then lower misses,
        # then allocation closest to equal partition.
        equal = equal_allocation(workloads, total_lines)
        distance = sum(abs(alloc[w] - equal.get(w, 0)) for w in workloads)
        score = (-hits, misses, (distance, tuple(alloc[w] for w in workloads)))
        candidates.append({"allocation": dict(alloc), "hits": hits, "misses": misses, "penalty": penalty})
        if best_score is None or score < best_score:
            best_score = score
            best_alloc = dict(alloc)
    assert best_alloc is not None
    return best_alloc, {"candidates": candidates, "rule": "choose allocation with most hits, then fewest misses, then closest to equal"}


def results_for_trace(trace_path: Path, total_lines: int, line_bytes: int, miss_penalty: int) -> Tuple[List[Result], Dict[str, object]]:
    accesses = parse_trace(trace_path)
    wloads = workloads_for(accesses)
    if len(wloads) < 2:
        raise ValueError(f"{trace_path}: expected at least two workloads")
    policies = [("equal", equal_allocation(wloads, total_lines))]
    ug_alloc, meta = choose_utility_guided(accesses, wloads, total_lines, line_bytes, miss_penalty)
    policies.append(("utility_guided", ug_alloc))
    rows: List[Result] = []
    policy_meta = {"trace": trace_path.name, "workloads": wloads, "utility": meta}
    for policy_name, allocation in policies:
        stats, total_hits, total_penalty = replay(accesses, allocation, line_bytes, miss_penalty)
        total_misses = total_penalty // miss_penalty if miss_penalty else sum(s["misses"] for s in stats.values())
        for workload in wloads:
            s = stats[workload]
            rows.append(Result(
                trace=trace_path.name,
                policy=policy_name,
                workload=workload,
                allocated_lines=allocation[workload],
                accesses=s["accesses"],
                hits=s["hits"],
                misses=s["misses"],
                estimated_penalty_cycles=s["misses"] * miss_penalty,
                total_policy_penalty_cycles=total_penalty,
                total_policy_hits=total_hits,
                total_policy_misses=total_misses,
            ))
    return rows, policy_meta


def write_csv(rows: List[Result], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="ascii") as f:
        writer = csv.writer(f)
        writer.writerow([
            "benchmark_or_trace", "policy", "workload", "allocated_lines",
            "accesses", "hits", "misses", "hit_rate", "miss_rate",
            "estimated_penalty_cycles", "total_policy_hits", "total_policy_misses",
            "total_policy_penalty_cycles", "model_type",
        ])
        for r in rows:
            writer.writerow([
                r.trace, r.policy, r.workload, r.allocated_lines,
                r.accesses, r.hits, r.misses, f"{r.hit_rate:.2f}", f"{r.miss_rate:.2f}",
                r.estimated_penalty_cycles, r.total_policy_hits, r.total_policy_misses,
                r.total_policy_penalty_cycles, "trace_estimated",
            ])


def write_markdown(rows: List[Result], path: Path, total_lines: int, line_bytes: int, miss_penalty: int, metas: List[Dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# UCP-Style Partition Summary",
        "",
        "This report is generated from a trace-level simplified UCP-style cache partition model.",
        "It estimates hit/miss behavior and miss-penalty cycles; it does not claim pipeline-integrated CPI.",
        "",
        f"- Shared cache lines: {total_lines}",
        f"- Line size bytes: {line_bytes}",
        f"- Estimated miss penalty cycles: {miss_penalty}",
        "- Static policy: equal partition across workloads",
        "- Utility-guided policy: evaluate legal allocations and choose the allocation with most hits, then fewest misses, then closest to equal",
        "",
        "| benchmark_or_trace | policy | workload | allocated_lines | accesses | hits | misses | hit_rate | estimated_penalty_cycles | total_policy_penalty_cycles |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for r in rows:
        lines.append(
            f"| {r.trace} | {r.policy} | {r.workload} | {r.allocated_lines} | {r.accesses} | {r.hits} | {r.misses} | {r.hit_rate:.2f}% | {r.estimated_penalty_cycles} | {r.total_policy_penalty_cycles} |"
        )
    lines.extend(["", "## Allocation Notes", ""])
    for meta in metas:
        util = meta["utility"]
        lines.append(f"### {meta['trace']}")
        lines.append("")
        lines.append(f"Utility rule: {util['rule']}")
        lines.append("")
        lines.append("Candidate utility-guided allocations:")
        lines.append("")
        lines.append("| allocation | hits | misses | estimated_penalty_cycles |")
        lines.append("|---|---:|---:|---:|")
        for cand in util["candidates"]:
            alloc = ", ".join(f"{w}={n}" for w, n in cand["allocation"].items())
            lines.append(f"| {alloc} | {cand['hits']} | {cand['misses']} | {cand['penalty']} |")
        lines.append("")
    lines.extend([
        "## Limitations",
        "",
        "- This is a trace replay model, not an RTL shared-cache controller.",
        "- Workloads are logical stream labels in trace files, not hardware threads.",
        "- Estimated penalty cycles are based on a fixed miss penalty and are not silicon timing.",
        "- The model is intended to make cache utility and partition tradeoffs visible before any SMT or multicore work.",
    ])
    path.write_text("\n".join(lines) + "\n", encoding="ascii")


def validate(rows: List[Result], total_lines: int) -> List[str]:
    errors: List[str] = []
    by_trace_policy: Dict[Tuple[str, str], List[Result]] = {}
    for row in rows:
        if row.accesses != row.hits + row.misses:
            errors.append(f"{row.trace}/{row.policy}/{row.workload}: accesses != hits + misses")
        if row.allocated_lines < 1:
            errors.append(f"{row.trace}/{row.policy}/{row.workload}: allocated_lines < 1")
        by_trace_policy.setdefault((row.trace, row.policy), []).append(row)
    for (trace, policy), group in by_trace_policy.items():
        total_alloc = sum(r.allocated_lines for r in group)
        if total_alloc != total_lines:
            errors.append(f"{trace}/{policy}: expected total allocation {total_lines}, got {total_alloc}")
    # Check that utility guidance never performs worse than equal for each trace.
    traces = sorted({r.trace for r in rows})
    for trace in traces:
        equal = [r for r in rows if r.trace == trace and r.policy == "equal"]
        utility = [r for r in rows if r.trace == trace and r.policy == "utility_guided"]
        if equal and utility:
            equal_penalty = equal[0].total_policy_penalty_cycles
            util_penalty = utility[0].total_policy_penalty_cycles
            if util_penalty > equal_penalty:
                errors.append(f"{trace}: utility-guided penalty {util_penalty} worse than equal {equal_penalty}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Run simplified UCP-style partition model")
    parser.add_argument("--trace-dir", default="tests/benchmarks/ucp")
    parser.add_argument("--out-dir", default="reports/perf")
    parser.add_argument("--total-lines", type=int, default=4)
    parser.add_argument("--line-bytes", type=int, default=4)
    parser.add_argument("--miss-penalty", type=int, default=10)
    args = parser.parse_args()

    trace_dir = Path(args.trace_dir)
    out_dir = Path(args.out_dir)
    traces = sorted(trace_dir.glob("trace_*.txt"))
    if len(traces) < 2:
        raise SystemExit(f"FAIL: expected at least two traces in {trace_dir}")

    all_rows: List[Result] = []
    metas: List[Dict[str, object]] = []
    log_dir = out_dir / "ucp_logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    for trace in traces:
        rows, meta = results_for_trace(trace, args.total_lines, args.line_bytes, args.miss_penalty)
        all_rows.extend(rows)
        metas.append(meta)
        log_lines = [f"TRACE: {trace.name}"]
        for row in rows:
            log_lines.append(
                "UCPPERF: "
                f"trace={row.trace} policy={row.policy} workload={row.workload} "
                f"allocated_lines={row.allocated_lines} accesses={row.accesses} "
                f"hits={row.hits} misses={row.misses} hit_rate={row.hit_rate:.2f} "
                f"estimated_penalty_cycles={row.estimated_penalty_cycles} "
                f"total_policy_penalty_cycles={row.total_policy_penalty_cycles} model=trace_estimated"
            )
        (log_dir / f"{trace.stem}.log").write_text("\n".join(log_lines) + "\n", encoding="ascii")
        print("\n".join(log_lines))

    md_path = out_dir / "ucp_partition_summary.md"
    csv_path = out_dir / "ucp_partition_summary.csv"
    write_markdown(all_rows, md_path, args.total_lines, args.line_bytes, args.miss_penalty, metas)
    write_csv(all_rows, csv_path)

    errors = validate(all_rows, args.total_lines)
    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1
    print(f"PASS: generated {md_path}")
    print(f"PASS: generated {csv_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
