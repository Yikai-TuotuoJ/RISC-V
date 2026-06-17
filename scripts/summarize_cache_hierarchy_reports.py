import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / "reports" / "perf" / "cache_hierarchy_logs"
OUT_MD = ROOT / "reports" / "perf" / "cache_hierarchy_summary.md"
OUT_CSV = ROOT / "reports" / "perf" / "cache_hierarchy_summary.csv"
FIELDS = ["benchmark", "cache_mode", "l1_enable", "l2_enable", "pass", "cycles", "retired", "cpi", "stalls", "memory_stalls", "loads", "stores", "l1_accesses", "l1_hits", "l1_misses", "l1_hit_rate", "l2_accesses", "l2_hits", "l2_misses", "l2_hit_rate", "backing_mem_accesses", "l2_hit_latency", "l2_miss_penalty"]

def parse(line):
    if not line.startswith("HIERPERF:"):
        return None
    row = {}
    for token in line.strip().split()[1:]:
        if "=" in token:
            k, v = token.split("=", 1)
            row[k] = v
    return row

def main():
    rows = []
    if LOG_DIR.exists():
        for path in sorted(LOG_DIR.glob("*.log")):
            for line in path.read_text(errors="ignore").splitlines():
                row = parse(line)
                if row:
                    rows.append(row)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="ascii") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in FIELDS})
    if rows:
        lines = ["# Cache Hierarchy Summary", "", "| " + " | ".join(FIELDS) + " |", "| " + " | ".join(["---"] * len(FIELDS)) + " |"]
        for row in rows:
            lines.append("| " + " | ".join(row.get(field, "") for field in FIELDS) + " |")
    else:
        lines = ["# Cache Hierarchy Summary", "", "No HIERPERF lines found."]
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"Wrote {OUT_MD}")
    print(f"Wrote {OUT_CSV}")
    return 0 if rows else 1

if __name__ == "__main__":
    raise SystemExit(main())
