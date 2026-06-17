# UCP-Style Partition Summary

This report is generated from a trace-level simplified UCP-style cache partition model.
It estimates hit/miss behavior and miss-penalty cycles; it does not claim pipeline-integrated CPI.

- Shared cache lines: 4
- Line size bytes: 4
- Estimated miss penalty cycles: 10
- Static policy: equal partition across workloads
- Utility-guided policy: evaluate legal allocations and choose the allocation with most hits, then fewest misses, then closest to equal

| benchmark_or_trace | policy | workload | allocated_lines | accesses | hits | misses | hit_rate | estimated_penalty_cycles | total_policy_penalty_cycles |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| trace_balanced_hotsets.txt | equal | A | 2 | 8 | 6 | 2 | 75.00% | 20 | 40 |
| trace_balanced_hotsets.txt | equal | B | 2 | 8 | 6 | 2 | 75.00% | 20 | 40 |
| trace_balanced_hotsets.txt | utility_guided | A | 2 | 8 | 6 | 2 | 75.00% | 20 | 40 |
| trace_balanced_hotsets.txt | utility_guided | B | 2 | 8 | 6 | 2 | 75.00% | 20 | 40 |
| trace_hot_array_vs_stream.txt | equal | A | 2 | 12 | 10 | 2 | 83.33% | 20 | 100 |
| trace_hot_array_vs_stream.txt | equal | B | 2 | 8 | 0 | 8 | 0.00% | 80 | 100 |
| trace_hot_array_vs_stream.txt | utility_guided | A | 2 | 12 | 10 | 2 | 83.33% | 20 | 100 |
| trace_hot_array_vs_stream.txt | utility_guided | B | 2 | 8 | 0 | 8 | 0.00% | 80 | 100 |
| trace_mixed_utility.txt | equal | A | 2 | 12 | 0 | 12 | 0.00% | 120 | 170 |
| trace_mixed_utility.txt | equal | B | 2 | 8 | 3 | 5 | 37.50% | 50 | 170 |
| trace_mixed_utility.txt | utility_guided | A | 3 | 12 | 9 | 3 | 75.00% | 30 | 110 |
| trace_mixed_utility.txt | utility_guided | B | 1 | 8 | 0 | 8 | 0.00% | 80 | 110 |

## Allocation Notes

### trace_balanced_hotsets.txt

Utility rule: choose allocation with most hits, then fewest misses, then closest to equal

Candidate utility-guided allocations:

| allocation | hits | misses | estimated_penalty_cycles |
|---|---:|---:|---:|
| A=1, B=3 | 6 | 10 | 100 |
| A=2, B=2 | 12 | 4 | 40 |
| A=3, B=1 | 6 | 10 | 100 |

### trace_hot_array_vs_stream.txt

Utility rule: choose allocation with most hits, then fewest misses, then closest to equal

Candidate utility-guided allocations:

| allocation | hits | misses | estimated_penalty_cycles |
|---|---:|---:|---:|
| A=1, B=3 | 0 | 20 | 200 |
| A=2, B=2 | 10 | 10 | 100 |
| A=3, B=1 | 10 | 10 | 100 |

### trace_mixed_utility.txt

Utility rule: choose allocation with most hits, then fewest misses, then closest to equal

Candidate utility-guided allocations:

| allocation | hits | misses | estimated_penalty_cycles |
|---|---:|---:|---:|
| A=1, B=3 | 3 | 17 | 170 |
| A=2, B=2 | 3 | 17 | 170 |
| A=3, B=1 | 9 | 11 | 110 |

## Limitations

- This is a trace replay model, not an RTL shared-cache controller.
- Workloads are logical stream labels in trace files, not hardware threads.
- Estimated penalty cycles are based on a fixed miss penalty and are not silicon timing.
- The model is intended to make cache utility and partition tradeoffs visible before any SMT or multicore work.
