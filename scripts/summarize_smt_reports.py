import csv
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / "reports" / "perf" / "smt_logs"
OUT_DIR = ROOT / "reports" / "perf"


def parse_kv_line(line):
    result = {}
    for key, value in re.findall(r"(\w+)=([^\s]+)", line):
        result[key] = value
    return result


def read_log(path):
    data = path.read_bytes()
    if b"\x00" in data[:100]:
        return data.decode("utf-16", errors="ignore")
    return data.decode("utf-8", errors="ignore")


def main():
    perf_rows = []
    ucp_rows = []
    check_total = 0
    error_total = 0
    for log in sorted(LOG_DIR.glob("*.log")):
        for line in read_log(log).splitlines():
            if line.startswith("PERF:"):
                row = parse_kv_line(line)
                row["log"] = log.name
                perf_rows.append(row)
            elif line.startswith("SMTUCP:"):
                row = parse_kv_line(line)
                row["log"] = log.name
                ucp_rows.append(row)
            elif line.startswith("SMT_TESTS:"):
                row = parse_kv_line(line)
                check_total += int(row.get("checks", "0"))
                error_total += int(row.get("errors", "0"))

    if not perf_rows or not ucp_rows:
        print("No SMT PERF/SMTUCP rows found", file=sys.stderr)
        return 1
    if check_total < 20:
        print(f"Only {check_total} meaningful SMT checks were reported", file=sys.stderr)
        return 1
    if error_total != 0:
        print(f"SMT logs reported {error_total} errors", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    perf_fields = [
        "test", "mode", "stream_id_mode", "ucp_mode", "thread_id", "pass_fail",
        "cycles", "retired", "fetched", "stalls", "flushes", "loads", "stores",
        "l1_hits", "l1_misses", "l2_hits", "l2_misses", "l3_hits", "l3_misses",
        "shadow_hits", "cpi_estimate", "log",
    ]
    ucp_fields = [
        "test", "stream_id_mode", "ucp_mode", "alloc0", "alloc1", "repartitions",
        "l3_s0_accesses", "l3_s0_hits", "l3_s0_misses", "l3_s1_accesses",
        "l3_s1_hits", "l3_s1_misses", "backing", "checks", "pass_fail", "log",
    ]

    with (OUT_DIR / "smt_summary.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=perf_fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(perf_rows)
    with (OUT_DIR / "smt_ucp_summary.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=ucp_fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(ucp_rows)

    def md_table(rows, fields):
        lines = ["| " + " | ".join(fields) + " |", "| " + " | ".join(["---"] * len(fields)) + " |"]
        for row in rows:
            lines.append("| " + " | ".join(row.get(field, "") for field in fields) + " |")
        return "\n".join(lines) + "\n"

    (OUT_DIR / "smt_summary.md").write_text(
        "# Phase 15 SMT Summary\n\n"
        f"Meaningful checks reported: {check_total}\n\n"
        + md_table(perf_rows, perf_fields)
    )
    (OUT_DIR / "smt_ucp_summary.md").write_text(
        "# Phase 15 SMT/UCP Summary\n\n"
        "Stream ID mode 1 means cache/UCP streams are selected from pipeline-carried thread IDs.\n\n"
        + md_table(ucp_rows, ucp_fields)
    )
    print(f"Generated SMT reports with {len(perf_rows)} PERF rows, {len(ucp_rows)} UCP rows, {check_total} checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
