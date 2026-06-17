import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "reports" / "perf" / "smt_ucp_summary.csv"


def to_int(row, key):
    try:
        return int(row.get(key, "0"))
    except ValueError:
        return 0


def main():
    if not CSV_PATH.exists():
        print(f"Missing {CSV_PATH}", file=sys.stderr)
        return 1
    rows = list(csv.DictReader(CSV_PATH.open()))
    if not rows:
        print("SMT UCP summary is empty", file=sys.stderr)
        return 1
    errors = 0
    for row in rows:
        name = row.get("test", "unknown")
        alloc_sum = to_int(row, "alloc0") + to_int(row, "alloc1")
        if alloc_sum != 8:
            print(f"{name}: allocation sum expected 8 got {alloc_sum}", file=sys.stderr)
            errors += 1
        for stream in ("s0", "s1"):
            accesses = to_int(row, f"l3_{stream}_accesses")
            hits = to_int(row, f"l3_{stream}_hits")
            misses = to_int(row, f"l3_{stream}_misses")
            if hits + misses != accesses:
                print(f"{name}: l3_{stream} hits+misses={hits + misses} accesses={accesses}", file=sys.stderr)
                errors += 1
        if row.get("pass_fail") != "PASS":
            print(f"{name}: pass_fail={row.get('pass_fail')}", file=sys.stderr)
            errors += 1
    if errors:
        return 1
    print(f"SMT counter consistency PASS for {len(rows)} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
