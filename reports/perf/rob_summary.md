# Phase 18 ROB / In-Order Commit Summary

| Metric | Value |
| --- | ---: |
| `test` | phase18 |
| `dispatched` | 20 |
| `rob_allocs` | 20 |
| `rob_full_stalls` | 1 |
| `rs_allocs` | 20 |
| `rs_full_stalls` | 0 |
| `issued` | 20 |
| `ooo_issue_events` | 1 |
| `completed` | 20 |
| `broadcasts` | 22 |
| `wakeups` | 1 |
| `commits` | 20 |
| `commit_stalls` | 58 |
| `younger_done_waiting` | 4 |
| `stale_tag_ignored` | 3 |
| `x0_commit_suppressed` | 1 |
| `unsupported` | 1 |
| `thread0_commits` | 19 |
| `thread1_commits` | 1 |
| `checks` | 56 |
| `errors` | 0 |
| `pass` | PASS |

## Interpretation

- `broadcasts` count execution completions placed on the CDB-style path.
- `commits` count architectural retirement from the ROB head only.
- `commit_stalls` proves the ROB refuses to skip an older not-ready head entry.
- `younger_done_waiting` proves a younger completed instruction waited for older work to retire.
- `stale_tag_ignored` covers both stale completion and stale register-status clear attempts.
- This is a constrained ROB experiment; it does not include an LSQ, branch speculation, precise exceptions, or a production OOO backend.
