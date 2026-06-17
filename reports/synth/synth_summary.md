# Phase 8 Synthesis Summary

Generated from Yosys reports. These are synthesis sanity and area/statistics-style observations, not signoff timing results.

| Variant | Top | Cells | Wire Bits | DFF Cells | Mux Cells | Warnings | Check Problems |
|---|---:|---:|---:|---:|---:|---:|---:|
| Single-cycle | top_single_cycle | 25143 | 26129 | 9216 | 8381 | 1 | 0 |
| Pipeline, no prediction | top_pipeline | 39037 | 52053 | 10761 | 256 | 28 | 0 |
| Pipeline, gshare | top_pipeline_gshare | 39082 | 52200 | 10762 | 287 | 28 | 0 |

## Cell Category Snapshot

| Variant | AND | OR | XOR | NOT | MUX | DFF |
|---|---:|---:|---:|---:|---:|---:|
| Single-cycle | 531 | 3307 | 282 | 3426 | 8381 | 9216 |
| Pipeline, no prediction | 7383 | 7298 | 1131 | 12208 | 256 | 10761 |
| Pipeline, gshare | 7402 | 7294 | 1131 | 12206 | 287 | 10762 |

## Observations

- Pipeline/no-prediction cells vs single-cycle cells: 39037 vs 25143.
- Gshare wrapper cells vs no-prediction pipeline cells: delta 45 cells in this generic mapping.
- ABC delay estimates are included only if Yosys reports them in the log. This flow does not perform industrial timing signoff.
