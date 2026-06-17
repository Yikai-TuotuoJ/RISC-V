# Phase 20 Integrated OOO Experiment Summary

| Metric | Value |
| --- | ---: |
| `test` | phase20_ooo |
| `decoded` | 31 |
| `dispatched` | 28 |
| `rob_allocs` | 28 |
| `rob_full_stalls` | 0 |
| `rs_allocs` | 17 |
| `rs_full_stalls` | 1 |
| `lsq_allocs` | 11 |
| `lsq_full_stalls` | 1 |
| `alu_issues` | 17 |
| `load_issues` | 4 |
| `store_commits` | 7 |
| `broadcasts` | 21 |
| `wakeups` | 14 |
| `completed` | 21 |
| `commits` | 28 |
| `commit_stalls` | 79 |
| `memory_order_stalls` | 9 |
| `younger_done_waiting` | 9 |
| `stale_tag_ignored` | 8 |
| `x0_commit_suppressed` | 1 |
| `unsupported` | 1 |
| `checks` | 75 |
| `errors` | 0 |
| `pass` | PASS |

## Interpretation

- `rs_allocs` and `alu_issues` show reservation-station allocation and readiness-based ALU issue.
- `broadcasts` and `wakeups` show CDB-style completion and dependent operand wakeup.
- `commits`, `commit_stalls`, and `younger_done_waiting` show ROB-based in-order commit despite out-of-order completion.
- `lsq_allocs`, `load_issues`, `store_commits`, and `memory_order_stalls` show limited LSQ behavior with conservative memory ordering.
- This is an integrated OOO-concept core, not a production OOO backend with branch speculation, precise exceptions, full renaming, or memory replay.
