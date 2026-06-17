# Memory Latency Summary

| benchmark | mem_latency | cache_mode | pass | cycles | retired | CPI | stalls | memory_stalls | load_use_stalls | load_stalls | store_stalls | loads | stores | flushes |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| mem_load_chain | 1 | none | PASS | 29 | 14 | 2.071 | 9 | 0 | 3 | 0 | 0 | 1 | 1 | 0 |
| mem_load_chain | 3 | none | PASS | 33 | 14 | 2.357 | 13 | 4 | 3 | 2 | 2 | 1 | 1 | 0 |
| mem_load_chain | 5 | none | PASS | 37 | 14 | 2.643 | 17 | 8 | 3 | 4 | 4 | 1 | 1 | 0 |
| mem_mixed_latency | 1 | none | PASS | 37 | 17 | 2.176 | 12 | 0 | 6 | 0 | 0 | 2 | 2 | 1 |
| mem_mixed_latency | 3 | none | PASS | 45 | 17 | 2.647 | 20 | 8 | 6 | 4 | 4 | 2 | 2 | 1 |
| mem_mixed_latency | 5 | none | PASS | 53 | 17 | 3.118 | 28 | 16 | 6 | 8 | 8 | 2 | 2 | 1 |
| mem_store_load | 1 | none | PASS | 27 | 16 | 1.688 | 5 | 0 | 3 | 0 | 0 | 2 | 2 | 0 |
| mem_store_load | 3 | none | PASS | 35 | 16 | 2.188 | 13 | 8 | 3 | 4 | 4 | 2 | 2 | 0 |
| mem_store_load | 5 | none | PASS | 43 | 16 | 2.688 | 21 | 16 | 3 | 8 | 8 | 2 | 2 | 0 |

Notes:
- `mem_latency=1` is the baseline one-cycle memory behavior.
- Higher latency values model extra MEM-stage wait cycles for loads and stores.
- `cache_mode=none`; Phase 10 implements latency infrastructure, not a cache hierarchy.
- CPI is a simulation-level microbenchmark estimate, not silicon signoff performance.
