# Phase 16 Scoreboard Summary

| Metric | Value |
| --- | ---: |
| `accepted` | 20 |
| `immediate_ready` | 13 |
| `wait_src1` | 6 |
| `wait_src2` | 2 |
| `wakeups` | 8 |
| `broadcasts` | 19 |
| `dependencies` | 7 |
| `full_stalls` | 1 |
| `thread0_accepted` | 15 |
| `thread1_accepted` | 5 |
| `thread0_wakeups` | 7 |
| `thread1_wakeups` | 1 |
| `checks` | 49 |
| `errors` | 0 |
| `pass` | PASS |

## Interpretation

- `accepted` counts entries allocated into the standalone readiness model.
- `dependencies` counts accepted instructions that waited for at least one source.
- `wakeups` counts source operands made ready by matching thread-aware broadcasts.
- `full_stalls` proves the finite reservation-station-like capacity is enforced.
- This model observes readiness only; it does not perform out-of-order architectural commit.
