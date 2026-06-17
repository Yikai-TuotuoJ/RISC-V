import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / "reports" / "perf" / "cache_logs"
OUT_MD = ROOT / "reports" / "perf" / "cache_summary.md"
OUT_CSV = ROOT / "reports" / "perf" / "cache_summary.csv"

FIELDS = [
    "benchmark", "dcache_enable", "icache_enable", "miss_penalty", "pass", "cycles",
    "retired", "cpi", "stalls", "memory_stalls", "load_use_stalls", "flushes", "loads",
    "stores", "dcache_accesses", "dcache_load_accesses", "dcache_store_accesses",
    "dcache_hits", "dcache_misses", "dcache_hit_rate", "dcache_miss_penalty_cycles",
]

def parse_perf_line(line):
    if not line.startswith("CACHEPERF:"):
        return None
    row = {}
    for token in line.strip().split()[1:]:
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        row[key] = value
    return row

def main():
    rows = []
    if LOG_DIR.exists():
        for path in sorted(LOG_DIR.glob("*.log")):
            for line in path.read_text(errors="ignore").splitlines():
                row = parse_perf_line(line)
                if row is not None:
                    rows.append(row)

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        OUT_MD.write_text("# Cache Summary\n\nNo CACHEPERF lines found.\n", encoding="ascii")
        with OUT_CSV.open("w", newline="", encoding="ascii") as f:
            csv.writer(f).writerow(FIELDS)
        return 1

    with OUT_CSV.open("w", newline="", encoding="ascii") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in FIELDS})

    lines = ["# Cache Summary", "", "| " + " | ".join(FIELDS) + " |", "| " + " | ".join(["---"] * len(FIELDS)) + " |"]
    for row in rows:
        lines.append("| " + " | ".join(row.get(field, "") for field in FIELDS) + " |")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"Wrote {OUT_MD}")
    print(f"Wrote {OUT_CSV}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
