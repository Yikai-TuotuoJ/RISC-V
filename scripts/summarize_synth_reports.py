from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "synth"

VARIANTS = [
    ("single_cycle", "Single-cycle", "single_cycle_yosys.log"),
    ("pipeline", "Pipeline, no prediction", "pipeline_yosys.log"),
    ("pipeline_gshare", "Pipeline, gshare", "pipeline_gshare_yosys.log"),
]

METRICS = [
    "wires",
    "wire bits",
    "public wires",
    "public wire bits",
    "memories",
    "memory bits",
    "processes",
    "cells",
]


def parse_log(path: Path) -> dict:
    text = path.read_text(errors="replace") if path.exists() else ""
    result = {key: "" for key in METRICS}
    result.update(
        {
            "top_module": "",
            "and_cells": "",
            "dff_cells": "",
            "mux_cells": "",
            "not_cells": "",
            "or_cells": "",
            "xor_cells": "",
            "warnings": "0",
            "check_problems": "",
            "abc_delay_estimate": "",
        }
    )

    top_match = re.search(r"Top module:\s+\\?(\S+)", text)
    if top_match:
        result["top_module"] = top_match.group(1).strip()

    hierarchy_block = text
    marker = "=== design hierarchy ==="
    if marker in text:
        hierarchy_block = text.split(marker)[-1]
        hierarchy_block = hierarchy_block.split("Executing CHECK", 1)[0]

    for line in hierarchy_block.splitlines():
        metric_match = re.match(r"\s*(\d+)\s+(wires|wire bits|public wires|public wire bits|memories|memory bits|processes|cells)\s*$", line)
        if metric_match:
            result[metric_match.group(2)] = metric_match.group(1)

        cell_match = re.match(r"\s*(\d+)\s+(\$_[A-Z0-9_]+_?)\s*$", line)
        if cell_match:
            count = int(cell_match.group(1))
            cell = cell_match.group(2)
            if "XNOR" in cell or "XOR" in cell:
                result["xor_cells"] = str(int(result["xor_cells"] or 0) + count)
            elif "AND" in cell:
                result["and_cells"] = str(int(result["and_cells"] or 0) + count)
            elif "DFF" in cell:
                result["dff_cells"] = str(int(result["dff_cells"] or 0) + count)
            elif "MUX" in cell:
                result["mux_cells"] = str(int(result["mux_cells"] or 0) + count)
            elif "NOT" in cell:
                result["not_cells"] = str(int(result["not_cells"] or 0) + count)
            elif "OR" in cell:
                result["or_cells"] = str(int(result["or_cells"] or 0) + count)

    warnings = re.findall(r"Warnings:\s+(\d+)\s+unique messages?,\s+(\d+)\s+total", text)
    if warnings:
        result["warnings"] = warnings[-1][1]
    else:
        result["warnings"] = str(len(re.findall(r"\bWarning:", text)))

    check = re.findall(r"Found and reported\s+(\d+)\s+problems?", text)
    if check:
        result["check_problems"] = check[-1]

    delay_patterns = [
        r"[dD]elay[^0-9]*([0-9]+(?:\.[0-9]+)?)",
        r"[cC]ritical path[^0-9]*([0-9]+(?:\.[0-9]+)?)",
        r"[lL]ongest path[^0-9]*([0-9]+(?:\.[0-9]+)?)",
    ]
    for pattern in delay_patterns:
        match = re.search(pattern, text)
        if match:
            result["abc_delay_estimate"] = match.group(1)
            break

    return result


def as_int(value: str) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for key, label, log_name in VARIANTS:
        parsed = parse_log(REPORT_DIR / log_name)
        parsed["variant"] = key
        parsed["label"] = label
        parsed["log"] = f"reports/synth/{log_name}"
        rows.append(parsed)

    columns = [
        "variant",
        "label",
        "top_module",
        "wires",
        "wire bits",
        "public wires",
        "public wire bits",
        "memories",
        "memory bits",
        "processes",
        "cells",
        "and_cells",
        "dff_cells",
        "mux_cells",
        "not_cells",
        "or_cells",
        "xor_cells",
        "warnings",
        "check_problems",
        "abc_delay_estimate",
        "log",
    ]

    csv_path = REPORT_DIR / "synth_summary.csv"
    with csv_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow({col: row.get(col, "") for col in columns})

    md_path = REPORT_DIR / "synth_summary.md"
    with md_path.open("w", encoding="utf-8") as f:
        f.write("# Phase 8 Synthesis Summary\n\n")
        f.write("Generated from Yosys reports. These are synthesis sanity and area/statistics-style observations, not signoff timing results.\n\n")
        table_cols = ["label", "top_module", "cells", "wire bits", "dff_cells", "mux_cells", "warnings", "check_problems"]
        f.write("| Variant | Top | Cells | Wire Bits | DFF Cells | Mux Cells | Warnings | Check Problems |\n")
        f.write("|---|---:|---:|---:|---:|---:|---:|---:|\n")
        for row in rows:
            values = [row.get(col, "") for col in table_cols]
            f.write("| " + " | ".join(values) + " |\n")

        f.write("\n## Cell Category Snapshot\n\n")
        f.write("| Variant | AND | OR | XOR | NOT | MUX | DFF |\n")
        f.write("|---|---:|---:|---:|---:|---:|---:|\n")
        for row in rows:
            f.write(
                f"| {row['label']} | {row.get('and_cells','')} | {row.get('or_cells','')} | "
                f"{row.get('xor_cells','')} | {row.get('not_cells','')} | {row.get('mux_cells','')} | {row.get('dff_cells','')} |\n"
            )

        f.write("\n## Observations\n\n")
        single = next((r for r in rows if r["variant"] == "single_cycle"), None)
        pipe = next((r for r in rows if r["variant"] == "pipeline"), None)
        gshare = next((r for r in rows if r["variant"] == "pipeline_gshare"), None)
        if single and pipe:
            f.write(f"- Pipeline/no-prediction cells vs single-cycle cells: {as_int(pipe.get('cells'))} vs {as_int(single.get('cells'))}.\n")
        if pipe and gshare:
            delta = as_int(gshare.get("cells")) - as_int(pipe.get("cells"))
            f.write(f"- Gshare wrapper cells vs no-prediction pipeline cells: delta {delta} cells in this generic mapping.\n")
        f.write("- ABC delay estimates are included only if Yosys reports them in the log. This flow does not perform industrial timing signoff.\n")

    print(f"Wrote {md_path}")
    print(f"Wrote {csv_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
