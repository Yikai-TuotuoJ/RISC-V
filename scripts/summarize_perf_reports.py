from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
PERF_DIR = ROOT / "reports" / "perf"
LOG_DIR = PERF_DIR / "benchmark_logs"

FIELDS = [
    "benchmark",
    "mode",
    "pass",
    "cycles",
    "retired",
    "cpi",
    "stalls",
    "load_use_stalls",
    "flushes",
    "branch_jump_flushes",
    "branches",
    "branch_taken",
    "branch_not_taken",
    "branch_correct",
    "mispredicts",
    "accuracy",
    "loads",
    "stores",
    "core_cycles",
    "core_retired",
    "log",
]


def parse_perf_line(line: str) -> dict:
    row = {}
    for key, value in re.findall(r"(\w+)=([^\s]+)", line):
        row[key] = value
    return row


def main() -> int:
    PERF_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for log_path in sorted(LOG_DIR.glob("*.log")):
        text = log_path.read_text(errors="replace").replace("\x00", "")
        for line in text.splitlines():
            if line.lstrip().startswith("PERF:"):
                row = parse_perf_line(line)
                row["log"] = str(log_path.relative_to(ROOT)).replace("\\", "/")
                rows.append(row)

    if not rows:
        print("No PERF lines found under reports/perf/benchmark_logs")
        return 1

    csv_path = PERF_DIR / "benchmark_summary.csv"
    with csv_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in FIELDS})

    md_path = PERF_DIR / "benchmark_summary.md"
    with md_path.open("w", encoding="utf-8") as f:
        f.write("# Phase 9 Benchmark Summary\n\n")
        f.write("These are controlled RTL simulation microbenchmarks. CPI is a simulation-level estimate, not a silicon performance claim.\n\n")
        f.write("| Benchmark | Mode | Result | Cycles | Retired | CPI | Stalls | Flushes | Branches | Mispredicts | Accuracy | Loads | Stores |\n")
        f.write("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n")
        for row in rows:
            f.write(
                f"| {row.get('benchmark','')} | {row.get('mode','')} | {row.get('pass','')} | "
                f"{row.get('cycles','')} | {row.get('retired','')} | {row.get('cpi','')} | "
                f"{row.get('stalls','')} | {row.get('flushes','')} | {row.get('branches','')} | "
                f"{row.get('mispredicts','')} | {row.get('accuracy','')} | {row.get('loads','')} | {row.get('stores','')} |\n"
            )
        f.write("\n## Notes\n\n")
        f.write("- Retired instructions are counted when a valid, non-flushed instruction reaches WB within the benchmark address range.\n")
        f.write("- Stores and branches count as retired when their valid instruction reaches WB, even though they do not write a register.\n")
        f.write("- Current stall/load-use counters are expected to remain zero until a future phase adds explicit stall/hazard hardware.\n")
        f.write("- Predictor accuracy is workload-dependent; correctness is judged by final architectural state, not accuracy.\n")

    print(f"Wrote {md_path}")
    print(f"Wrote {csv_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
