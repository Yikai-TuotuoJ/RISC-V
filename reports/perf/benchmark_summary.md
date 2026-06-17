# Phase 9 Benchmark Summary

These are controlled RTL simulation microbenchmarks. CPI is a simulation-level estimate, not a silicon performance claim.

| Benchmark | Mode | Result | Cycles | Retired | CPI | Stalls | Flushes | Branches | Mispredicts | Accuracy | Loads | Stores |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| alu_chain | gshare | PASS | 54 | 49 | 1.102 | 0 | 0 | 0 | 0 | 0.00 | 0 | 0 |
| alu_chain | none | PASS | 54 | 49 | 1.102 | 0 | 0 | 0 | 0 | 0.00 | 0 | 0 |
| alu_chain | simple | PASS | 54 | 49 | 1.102 | 0 | 0 | 0 | 0 | 0.00 | 0 | 0 |
| branch_loop | gshare | PASS | 55 | 42 | 1.310 | 0 | 4 | 5 | 4 | 20.00 | 0 | 0 |
| branch_loop | none | PASS | 55 | 42 | 1.310 | 0 | 4 | 5 | 4 | 20.00 | 0 | 0 |
| branch_loop | simple | PASS | 51 | 42 | 1.214 | 0 | 2 | 5 | 2 | 60.00 | 0 | 0 |
| mem_stream | gshare | PASS | 23 | 18 | 1.278 | 0 | 0 | 0 | 0 | 0.00 | 1 | 1 |
| mem_stream | none | PASS | 23 | 18 | 1.278 | 0 | 0 | 0 | 0 | 0.00 | 1 | 1 |
| mem_stream | simple | PASS | 23 | 18 | 1.278 | 0 | 0 | 0 | 0 | 0.00 | 1 | 1 |
| mixed_program | gshare | PASS | 34 | 27 | 1.259 | 0 | 1 | 1 | 1 | 0.00 | 1 | 1 |
| mixed_program | none | PASS | 34 | 27 | 1.259 | 0 | 1 | 1 | 1 | 0.00 | 1 | 1 |
| mixed_program | simple | PASS | 34 | 27 | 1.259 | 0 | 1 | 1 | 1 | 0.00 | 1 | 1 |

## Notes

- Retired instructions are counted when a valid, non-flushed instruction reaches WB within the benchmark address range.
- Stores and branches count as retired when their valid instruction reaches WB, even though they do not write a register.
- Current stall/load-use counters are expected to remain zero until a future phase adds explicit stall/hazard hardware.
- Predictor accuracy is workload-dependent; correctness is judged by final architectural state, not accuracy.
