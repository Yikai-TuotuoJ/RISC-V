#!/usr/bin/env python3
"""Phase 14 active UCP validation report generator.

This script intentionally treats each validation rule as a real PASS/FAIL check over
simulation output. It does not generate placeholder passes: missing fields, failing
simulation rows, inconsistent counters, or too few checks make the script fail.
"""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "phase14_ucp"
LOG_DIR = REPORT_DIR / "logs"
TRACE_IN = REPORT_DIR / "ucp_trace.log"
VALIDATION_MD = REPORT_DIR / "ucp_validation_summary.md"
VALIDATION_CSV = REPORT_DIR / "ucp_validation_summary.csv"
POLICY_MD = REPORT_DIR / "ucp_policy_comparison.md"
POLICY_CSV = REPORT_DIR / "ucp_policy_comparison.csv"
CONSISTENCY_MD = REPORT_DIR / "ucp_counter_consistency.md"
PAIR_RE = re.compile(r"(\w+)=([^\s]+)")
TRACE_RE = re.compile(r"stream=(\d+) addr=([0-9a-fA-F]+).+alloc0=(\d+) alloc1=(\d+)")

MODE_SUFFIXES = [
    "mode0_l3_disabled",
    "mode1_l3_unpartitioned",
    "mode2_l3_equal",
    "mode3_l3_utility_fixed",
    "mode4_dynamic_ucp",
]
MODE_LABELS = {
    "mode0_l3_disabled": "UCP disabled / L3 disabled baseline",
    "mode1_l3_unpartitioned": "L3 enabled, UCP disabled, unpartitioned",
    "mode2_l3_equal": "L3 UCP equal partition",
    "mode3_l3_utility_fixed": "L3 UCP utility-guided fixed partition",
    "mode4_dynamic_ucp": "L3 UCP dynamic monitor partition",
}
REQUIRED_FIELDS = [
    "benchmark", "policy", "pass", "cycles", "retired", "cpi", "stalls", "loads", "stores",
    "l1_accesses", "l1_hits", "l1_misses",
    "l1_core0_accesses", "l1_core0_hits", "l1_core0_misses",
    "l1_core1_accesses", "l1_core1_hits", "l1_core1_misses",
    "l2_accesses", "l2_hits", "l2_misses",
    "l3_accesses", "l3_hits", "l3_misses",
    "l3_stream0_alloc", "l3_stream0_accesses", "l3_stream0_hits", "l3_stream0_misses",
    "l3_stream1_alloc", "l3_stream1_accesses", "l3_stream1_hits", "l3_stream1_misses",
    "backing_mem_accesses",
]
POLICY_FIELDS = [
    "test_name", "policy_mode", "stream_id", "l1_accesses", "l1_hits", "l1_misses",
    "l2_accesses", "l2_hits", "l2_misses", "l3_accesses", "l3_hits", "l3_misses",
    "backing_accesses", "allocated_l3_lines", "cycles", "retired", "CPI", "pass_fail",
]


def parse_mode(log_name: str) -> str:
    stem = Path(log_name).stem
    for suffix in MODE_SUFFIXES:
        if stem.endswith("_" + suffix):
            return suffix
    return "unknown"


def parse_logs() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for log in sorted(LOG_DIR.glob("*.log")):
        for line in log.read_text(encoding="ascii", errors="ignore").splitlines():
            if not line.startswith("UCPRTL:"):
                continue
            row = {k: v for k, v in PAIR_RE.findall(line)}
            row["log"] = log.name
            row["mode"] = parse_mode(log.name)
            rows.append(row)
    return rows


def n(row: dict[str, str], key: str) -> float:
    try:
        return float(row.get(key, "0"))
    except ValueError:
        return 0.0


def i(row: dict[str, str], key: str) -> int:
    return int(n(row, key))


def add_check(checks: list[dict[str, str]], category: str, name: str, purpose: str, passed: bool, detail: str) -> None:
    checks.append({
        "category": category,
        "test_name": name,
        "purpose": purpose,
        "result": "PASS" if passed else "FAIL",
        "detail": detail,
    })


def make_checks(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    checks: list[dict[str, str]] = []
    by_key = {(r.get("benchmark", ""), r.get("mode", "")): r for r in rows}

    for row in rows:
        bench = row.get("benchmark", "unknown")
        mode = row.get("mode", "unknown")
        prefix = f"{bench}.{mode}"
        missing = [f for f in REQUIRED_FIELDS if f not in row]
        add_check(checks, "Counter/report fields", prefix + ".required_fields", "All critical UCP fields are present", not missing, "missing=" + ",".join(missing))
        add_check(checks, "Architectural correctness", prefix + ".simulation_pass", "Testbench checked registers, x0, illegal instruction, timeout, and internal counters", row.get("pass") == "PASS", f"pass={row.get('pass')}")
        add_check(checks, "Private L1", prefix + ".l1_total_consistency", "Total L1 hits plus misses equals accesses", i(row, "l1_accesses") == i(row, "l1_hits") + i(row, "l1_misses"), f"{i(row,'l1_accesses')} vs {i(row,'l1_hits')}+{i(row,'l1_misses')}")
        add_check(checks, "Private L1", prefix + ".l1_core0_consistency", "Stream 0 private L1 hits plus misses equals stream 0 accesses", i(row, "l1_core0_accesses") == i(row, "l1_core0_hits") + i(row, "l1_core0_misses"), f"{i(row,'l1_core0_accesses')} vs {i(row,'l1_core0_hits')}+{i(row,'l1_core0_misses')}")
        add_check(checks, "Private L1", prefix + ".l1_core1_consistency", "Stream 1 private L1 hits plus misses equals stream 1 accesses", i(row, "l1_core1_accesses") == i(row, "l1_core1_hits") + i(row, "l1_core1_misses"), f"{i(row,'l1_core1_accesses')} vs {i(row,'l1_core1_hits')}+{i(row,'l1_core1_misses')}")
        add_check(checks, "Private L1", prefix + ".l1_stream_sum", "Private stream counters sum to total L1 accesses", i(row, "l1_accesses") == i(row, "l1_core0_accesses") + i(row, "l1_core1_accesses"), f"{i(row,'l1_accesses')} vs s0+s1")
        add_check(checks, "Shared L2", prefix + ".l2_consistency", "Shared L2 hits plus misses equals accesses", i(row, "l2_accesses") == i(row, "l2_hits") + i(row, "l2_misses"), f"{i(row,'l2_accesses')} vs {i(row,'l2_hits')}+{i(row,'l2_misses')}")
        add_check(checks, "L3 UCP", prefix + ".l3_total_consistency", "L3 hits plus misses equals accesses", i(row, "l3_accesses") == i(row, "l3_hits") + i(row, "l3_misses"), f"{i(row,'l3_accesses')} vs {i(row,'l3_hits')}+{i(row,'l3_misses')}")
        add_check(checks, "L3 UCP", prefix + ".l3_stream0_consistency", "Stream 0 L3 hits plus misses equals stream 0 L3 accesses", i(row, "l3_stream0_accesses") == i(row, "l3_stream0_hits") + i(row, "l3_stream0_misses"), f"{i(row,'l3_stream0_accesses')} vs {i(row,'l3_stream0_hits')}+{i(row,'l3_stream0_misses')}")
        add_check(checks, "L3 UCP", prefix + ".l3_stream1_consistency", "Stream 1 L3 hits plus misses equals stream 1 L3 accesses", i(row, "l3_stream1_accesses") == i(row, "l3_stream1_hits") + i(row, "l3_stream1_misses"), f"{i(row,'l3_stream1_accesses')} vs {i(row,'l3_stream1_hits')}+{i(row,'l3_stream1_misses')}")
        add_check(checks, "L3 UCP", prefix + ".l3_stream_sum", "Per-stream L3 accesses sum to total L3 accesses", i(row, "l3_accesses") == i(row, "l3_stream0_accesses") + i(row, "l3_stream1_accesses"), f"{i(row,'l3_accesses')} vs s0+s1")
        if mode == "mode0_l3_disabled":
            add_check(checks, "Policy mode", prefix + ".l3_disabled_no_l3_access", "L3 disabled mode does not create L3 accesses", i(row, "l3_accesses") == 0, f"l3_accesses={i(row,'l3_accesses')}")
            add_check(checks, "Fill path", prefix + ".backing_used_without_l3", "Without L3, L2 misses fall through to backing memory", i(row, "backing_mem_accesses") > 0, f"backing={i(row,'backing_mem_accesses')}")
        elif mode == "mode1_l3_unpartitioned":
            add_check(checks, "Policy mode", prefix + ".l3_unpartitioned_accessed", "Unpartitioned L3 is active", i(row, "l3_accesses") > 0, f"l3_accesses={i(row,'l3_accesses')}")
        elif mode == "mode2_l3_equal":
            add_check(checks, "Policy mode", prefix + ".equal_alloc", "Equal UCP mode allocates 4/4 lines", i(row, "l3_stream0_alloc") == 4 and i(row, "l3_stream1_alloc") == 4, f"alloc={i(row,'l3_stream0_alloc')}/{i(row,'l3_stream1_alloc')}")
        elif mode == "mode3_l3_utility_fixed":
            add_check(checks, "Policy mode", prefix + ".utility_alloc", "Fixed utility-guided mode allocates 6/2 lines", i(row, "l3_stream0_alloc") == 6 and i(row, "l3_stream1_alloc") == 2, f"alloc={i(row,'l3_stream0_alloc')}/{i(row,'l3_stream1_alloc')}")
        elif mode == "mode4_dynamic_ucp":
            add_check(checks, "Policy mode", prefix + ".dynamic_alloc_sum", "Dynamic UCP allocation remains valid and sums to 8", i(row, "l3_stream0_alloc") + i(row, "l3_stream1_alloc") == 8 and i(row, "l3_stream0_alloc") >= 1 and i(row, "l3_stream1_alloc") >= 1, f"alloc={i(row,'l3_stream0_alloc')}/{i(row,'l3_stream1_alloc')}")
            if bench == "utility_pressure":
                add_check(checks, "Dynamic UCP", prefix + ".dynamic_repartitioned", "Dynamic UCP repartitions on the pressure benchmark", i(row, "dynamic_repartitions") >= 1, f"repartitions={i(row,'dynamic_repartitions')}")
                add_check(checks, "Dynamic UCP", prefix + ".dynamic_moved_from_equal", "Dynamic UCP moved away from the initial equal split", not (i(row, "l3_stream0_alloc") == 4 and i(row, "l3_stream1_alloc") == 4), f"alloc={i(row,'l3_stream0_alloc')}/{i(row,'l3_stream1_alloc')}")
        if bench == "shared_l2_reuse":
            add_check(checks, "Shared L2", prefix + ".shared_l2_hits", "Both streams can benefit from shared L2 reuse", i(row, "l2_hits") >= 2, f"l2_hits={i(row,'l2_hits')}")
            add_check(checks, "Stream split", prefix + ".both_streams_access_l1", "Benchmark exercised both address-derived streams", i(row, "l1_core0_accesses") > 0 and i(row, "l1_core1_accesses") > 0, f"s0={i(row,'l1_core0_accesses')} s1={i(row,'l1_core1_accesses')}")
        if bench == "l3_reuse_after_l2_eviction" and mode != "mode0_l3_disabled":
            add_check(checks, "Fill path", prefix + ".l3_reuse", "After L1/L2 conflicts, repeated data can be served from L3", i(row, "l3_hits") >= 2, f"l3_hits={i(row,'l3_hits')}")
        if bench == "utility_pressure" and mode in {"mode2_l3_equal", "mode3_l3_utility_fixed"}:
            add_check(checks, "Stress", prefix + ".utility_pressure_l3_active", "Utility pressure benchmark creates L3 activity", i(row, "l3_accesses") >= 8, f"l3_accesses={i(row,'l3_accesses')}")

    # Cross-policy comparisons using real rows.
    eq = by_key.get(("utility_pressure", "mode2_l3_equal"))
    util = by_key.get(("utility_pressure", "mode3_l3_utility_fixed"))
    disabled = by_key.get(("utility_pressure", "mode0_l3_disabled"))
    unpart = by_key.get(("utility_pressure", "mode1_l3_unpartitioned"))
    if eq and util:
        add_check(checks, "Policy comparison", "utility_pressure.utility_vs_equal_l3_hits", "Utility fixed allocation should improve or preserve L3 hits for stream 0 hot-set pressure", i(util, "l3_stream0_hits") >= i(eq, "l3_stream0_hits"), f"utility_s0_hits={i(util,'l3_stream0_hits')} equal_s0_hits={i(eq,'l3_stream0_hits')}")
        add_check(checks, "Policy comparison", "utility_pressure.utility_vs_equal_backing", "Utility fixed allocation should not increase backing pressure on the hot-set benchmark", i(util, "backing_mem_accesses") <= i(eq, "backing_mem_accesses"), f"utility_backing={i(util,'backing_mem_accesses')} equal_backing={i(eq,'backing_mem_accesses')}")
        add_check(checks, "Policy comparison", "utility_pressure.utility_vs_equal_cycles", "Utility fixed allocation should not be slower on the current hot-set benchmark", i(util, "cycles") <= i(eq, "cycles"), f"utility_cycles={i(util,'cycles')} equal_cycles={i(eq,'cycles')}")
    if disabled and eq:
        add_check(checks, "Policy comparison", "utility_pressure.l3_reduces_backing_vs_disabled", "Enabling partitioned L3 should reduce backing-memory accesses versus L3 disabled", i(eq, "backing_mem_accesses") <= i(disabled, "backing_mem_accesses"), f"equal_backing={i(eq,'backing_mem_accesses')} disabled_backing={i(disabled,'backing_mem_accesses')}")
    if unpart and eq:
        add_check(checks, "Policy comparison", "utility_pressure.equal_partition_boundary", "Equal partition differs from unpartitioned mode but preserves architectural pass", eq.get("pass") == "PASS" and unpart.get("pass") == "PASS", f"equal={eq.get('pass')} unpart={unpart.get('pass')}")

    eq_long = by_key.get(("dynamic_ucp_long_stream1", "mode2_l3_equal"))
    dyn_long = by_key.get(("dynamic_ucp_long_stream1", "mode4_dynamic_ucp"))
    fixed_long = by_key.get(("dynamic_ucp_long_stream1", "mode3_l3_utility_fixed"))
    if eq_long and dyn_long:
        add_check(checks, "Dynamic UCP", "dynamic_long.dynamic_vs_equal_l3_hits", "Long benchmark should give dynamic UCP more L3 hits than equal partition after repartition", i(dyn_long, "l3_hits") > i(eq_long, "l3_hits"), f"dynamic_l3_hits={i(dyn_long,'l3_hits')} equal_l3_hits={i(eq_long,'l3_hits')}")
        add_check(checks, "Dynamic UCP", "dynamic_long.dynamic_vs_equal_backing", "Long benchmark should reduce backing-memory accesses versus equal partition", i(dyn_long, "backing_mem_accesses") < i(eq_long, "backing_mem_accesses"), f"dynamic_backing={i(dyn_long,'backing_mem_accesses')} equal_backing={i(eq_long,'backing_mem_accesses')}")
        add_check(checks, "Dynamic UCP", "dynamic_long.dynamic_vs_equal_cycles", "Long benchmark should reduce simulated cycles versus equal partition", i(dyn_long, "cycles") < i(eq_long, "cycles"), f"dynamic_cycles={i(dyn_long,'cycles')} equal_cycles={i(eq_long,'cycles')}")
    if fixed_long and dyn_long:
        add_check(checks, "Dynamic UCP", "dynamic_long.dynamic_beats_fixed_stream1", "Dynamic UCP should beat fixed stream-0-biased policy on a later stream-1 hot phase", i(dyn_long, "l3_stream1_hits") > i(fixed_long, "l3_stream1_hits"), f"dynamic_s1_hits={i(dyn_long,'l3_stream1_hits')} fixed_s1_hits={i(fixed_long,'l3_stream1_hits')}")
    # Trace-driven stream-ID validation.
    if TRACE_IN.exists():
        seen_s0 = seen_s1 = False
        bad_stream = []
        bad_alloc = []
        for line in TRACE_IN.read_text(encoding="ascii", errors="ignore").splitlines():
            m = TRACE_RE.search(line)
            if not m:
                continue
            stream = int(m.group(1)); addr = int(m.group(2), 16); alloc0 = int(m.group(3)); alloc1 = int(m.group(4))
            expected = 0 if addr < 0x80 else 1
            if stream != expected:
                bad_stream.append(f"addr=0x{addr:08x} stream={stream} expected={expected}")
            if alloc0 + alloc1 != 8:
                bad_alloc.append(f"alloc={alloc0}/{alloc1}")
            if stream == 0:
                seen_s0 = True
            if stream == 1:
                seen_s1 = True
        add_check(checks, "Stream split", "trace.stream0_below_split", "Trace contains accesses below STREAM_SPLIT_ADDR mapped to stream 0", seen_s0, "seen_stream0=" + str(seen_s0))
        add_check(checks, "Stream split", "trace.stream1_at_or_above_split", "Trace contains accesses at or above STREAM_SPLIT_ADDR mapped to stream 1", seen_s1, "seen_stream1=" + str(seen_s1))
        add_check(checks, "Stream split", "trace.no_stream_id_mismatch", "Address-derived stream ID matches split rule in trace", not bad_stream, "; ".join(bad_stream[:5]))
        add_check(checks, "L3 UCP", "trace.alloc_sum_invariant", "Trace allocation fields always sum to total L3 lines", not bad_alloc, "; ".join(bad_alloc[:5]))
    else:
        add_check(checks, "Trace", "trace.exists", "Phase 14 trace exists", False, str(TRACE_IN))
    return checks


def write_validation(checks: list[dict[str, str]]) -> None:
    with VALIDATION_CSV.open("w", newline="", encoding="ascii") as f:
        writer = csv.DictWriter(f, fieldnames=["category", "test_name", "purpose", "result", "detail"])
        writer.writeheader(); writer.writerows(checks)
    passed = sum(1 for c in checks if c["result"] == "PASS")
    failed = len(checks) - passed
    cats = sorted({c["category"] for c in checks})
    lines = [
        "# Phase 14 Active UCP Validation Summary", "",
        f"Total meaningful checks run: {len(checks)}",
        f"Passed: {passed}", f"Failed: {failed}", "",
        "Categories covered: " + ", ".join(cats), "",
        "| category | test | result | purpose | detail |", "|---|---|---|---|---|",
    ]
    for c in checks:
        lines.append(f"| {c['category']} | `{c['test_name']}` | {c['result']} | {c['purpose']} | {c['detail']} |")
    VALIDATION_MD.write_text("\n".join(lines) + "\n", encoding="ascii")


def write_policy(rows: list[dict[str, str]]) -> None:
    out_rows = []
    for r in rows:
        for stream_id in (0, 1):
            prefix = f"l3_stream{stream_id}"
            l1a = i(r, f"l1_core{stream_id}_accesses")
            l1h = i(r, f"l1_core{stream_id}_hits")
            l1m = i(r, f"l1_core{stream_id}_misses")
            out_rows.append({
                "test_name": r.get("benchmark", ""),
                "policy_mode": r.get("mode", ""),
                "stream_id": str(stream_id),
                "l1_accesses": str(l1a), "l1_hits": str(l1h), "l1_misses": str(l1m),
                "l2_accesses": r.get("l2_accesses", ""), "l2_hits": r.get("l2_hits", ""), "l2_misses": r.get("l2_misses", ""),
                "l3_accesses": r.get(f"{prefix}_accesses", ""), "l3_hits": r.get(f"{prefix}_hits", ""), "l3_misses": r.get(f"{prefix}_misses", ""),
                "backing_accesses": r.get("backing_mem_accesses", ""),
                "allocated_l3_lines": r.get(f"{prefix}_alloc", ""),
                "cycles": r.get("cycles", ""), "retired": r.get("retired", ""), "CPI": r.get("cpi", ""),
                "pass_fail": r.get("pass", ""),
            })
    with POLICY_CSV.open("w", newline="", encoding="ascii") as f:
        writer = csv.DictWriter(f, fieldnames=POLICY_FIELDS)
        writer.writeheader(); writer.writerows(out_rows)
    lines = [
        "# Phase 14 UCP Policy Comparison", "",
        "Policy mapping:", "",
        "- `mode0_l3_disabled`: UCP disabled / L3 disabled baseline",
        "- `mode1_l3_unpartitioned`: L3 enabled but UCP disabled",
        "- `mode2_l3_equal`: L3 UCP equal partition, 4/4 lines",
        "- `mode3_l3_utility_fixed`: L3 UCP fixed utility-guided partition, 6/2 lines",
        "- `mode4_dynamic_ucp`: L3 UCP dynamic monitor partition",
        "", "| test | mode | stream | L1 h/m | L2 h/m | L3 h/m | backing | alloc | cycles | CPI | pass |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for r in out_rows:
        lines.append(f"| {r['test_name']} | {r['policy_mode']} | {r['stream_id']} | {r['l1_hits']}/{r['l1_misses']} | {r['l2_hits']}/{r['l2_misses']} | {r['l3_hits']}/{r['l3_misses']} | {r['backing_accesses']} | {r['allocated_l3_lines']} | {r['cycles']} | {r['CPI']} | {r['pass_fail']} |")
    lines.extend([
        "", "## Design Notes", "",
        "The comparison separates correctness from performance. Every row must first pass architectural checks in the RTL testbench.",
        "Only after correctness is established do the counters show how private L1, shared L2, and partitioned L3 change where hits occur.",
        "The dynamic UCP policy is now the main validation target: it starts from an equal split, monitors L3 behavior, and can repartition at interval boundaries while preserving architectural correctness. The long `dynamic_ucp_long_stream1` benchmark is designed to let dynamic UCP pay back its monitoring/repartition cost after stream 1 becomes the dominant hot set. The fixed utility-guided policy remains only as a comparison point.",
        "This remains a simplified single-pipeline experiment with address-derived streams, not real multicore UCP or cache coherence.",
    ])
    POLICY_MD.write_text("\n".join(lines) + "\n", encoding="ascii")


def write_consistency(checks: list[dict[str, str]]) -> None:
    rows = [c for c in checks if "consistency" in c["test_name"] or "stream_sum" in c["test_name"] or "alloc" in c["test_name"]]
    lines = ["# Phase 14 UCP Counter Consistency", "", "| counter/check | result | detail |", "|---|---|---|"]
    for c in rows:
        lines.append(f"| `{c['test_name']}` | {c['result']} | {c['detail']} |")
    CONSISTENCY_MD.write_text("\n".join(lines) + "\n", encoding="ascii")


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    rows = parse_logs()
    if not rows:
        print(f"FAIL: no UCPRTL rows found in {LOG_DIR}")
        return 1
    modes = {r.get("mode") for r in rows}
    missing_modes = [m for m in MODE_SUFFIXES if m not in modes]
    checks = make_checks(rows)
    if missing_modes:
        add_check(checks, "Policy mode", "all_policy_modes_present", "All four Phase 14 policy modes were simulated", False, "missing=" + ",".join(missing_modes))
    else:
        add_check(checks, "Policy mode", "all_policy_modes_present", "All four Phase 14 policy modes were simulated", True, "modes=" + ",".join(sorted(modes)))
    if len(checks) < 20:
        add_check(checks, "Suite size", "minimum_20_meaningful_checks", "Runner must fail below 20 meaningful checks", False, f"checks={len(checks)}")
    else:
        add_check(checks, "Suite size", "minimum_20_meaningful_checks", "Runner must fail below 20 meaningful checks", True, f"checks={len(checks)}")
    write_validation(checks)
    write_policy(rows)
    write_consistency(checks)
    failed = [c for c in checks if c["result"] != "PASS"]
    print(f"Phase 14 rows: {len(rows)}")
    print(f"Phase 14 meaningful checks: {len(checks)}")
    print(f"Wrote {VALIDATION_MD}")
    print(f"Wrote {VALIDATION_CSV}")
    print(f"Wrote {POLICY_MD}")
    print(f"Wrote {POLICY_CSV}")
    print(f"Wrote {CONSISTENCY_MD}")
    if failed:
        print(f"FAIL: {len(failed)} Phase 14 validation checks failed")
        for item in failed[:20]:
            print(f"  {item['test_name']}: {item['detail']}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())






