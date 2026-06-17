# Phase 14 Active UCP Validation Summary

Total meaningful checks run: 277
Passed: 277
Failed: 0

Categories covered: Architectural correctness, Counter/report fields, Dynamic UCP, Fill path, L3 UCP, Policy comparison, Policy mode, Private L1, Shared L2, Stream split, Stress, Suite size

| category | test | result | purpose | detail |
|---|---|---|---|---|
| Counter/report fields | `dynamic_ucp_long_stream1.mode0_l3_disabled.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `dynamic_ucp_long_stream1.mode0_l3_disabled.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `dynamic_ucp_long_stream1.mode0_l3_disabled.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 38 vs 2+36 |
| Private L1 | `dynamic_ucp_long_stream1.mode0_l3_disabled.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `dynamic_ucp_long_stream1.mode0_l3_disabled.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 29 vs 2+27 |
| Private L1 | `dynamic_ucp_long_stream1.mode0_l3_disabled.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 38 vs s0+s1 |
| Shared L2 | `dynamic_ucp_long_stream1.mode0_l3_disabled.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 36 vs 0+36 |
| L3 UCP | `dynamic_ucp_long_stream1.mode0_l3_disabled.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 0 vs 0+0 |
| L3 UCP | `dynamic_ucp_long_stream1.mode0_l3_disabled.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 0 vs 0+0 |
| L3 UCP | `dynamic_ucp_long_stream1.mode0_l3_disabled.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 0 vs 0+0 |
| L3 UCP | `dynamic_ucp_long_stream1.mode0_l3_disabled.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 0 vs s0+s1 |
| Policy mode | `dynamic_ucp_long_stream1.mode0_l3_disabled.l3_disabled_no_l3_access` | PASS | L3 disabled mode does not create L3 accesses | l3_accesses=0 |
| Fill path | `dynamic_ucp_long_stream1.mode0_l3_disabled.backing_used_without_l3` | PASS | Without L3, L2 misses fall through to backing memory | backing=36 |
| Counter/report fields | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 38 vs 2+36 |
| Private L1 | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 29 vs 2+27 |
| Private L1 | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 38 vs s0+s1 |
| Shared L2 | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 36 vs 0+36 |
| L3 UCP | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 36 vs 24+12 |
| L3 UCP | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 4+5 |
| L3 UCP | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 27 vs 20+7 |
| L3 UCP | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 36 vs s0+s1 |
| Policy mode | `dynamic_ucp_long_stream1.mode1_l3_unpartitioned.l3_unpartitioned_accessed` | PASS | Unpartitioned L3 is active | l3_accesses=36 |
| Counter/report fields | `dynamic_ucp_long_stream1.mode2_l3_equal.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `dynamic_ucp_long_stream1.mode2_l3_equal.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `dynamic_ucp_long_stream1.mode2_l3_equal.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 38 vs 2+36 |
| Private L1 | `dynamic_ucp_long_stream1.mode2_l3_equal.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `dynamic_ucp_long_stream1.mode2_l3_equal.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 29 vs 2+27 |
| Private L1 | `dynamic_ucp_long_stream1.mode2_l3_equal.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 38 vs s0+s1 |
| Shared L2 | `dynamic_ucp_long_stream1.mode2_l3_equal.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 36 vs 0+36 |
| L3 UCP | `dynamic_ucp_long_stream1.mode2_l3_equal.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 36 vs 16+20 |
| L3 UCP | `dynamic_ucp_long_stream1.mode2_l3_equal.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 2+7 |
| L3 UCP | `dynamic_ucp_long_stream1.mode2_l3_equal.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 27 vs 14+13 |
| L3 UCP | `dynamic_ucp_long_stream1.mode2_l3_equal.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 36 vs s0+s1 |
| Policy mode | `dynamic_ucp_long_stream1.mode2_l3_equal.equal_alloc` | PASS | Equal UCP mode allocates 4/4 lines | alloc=4/4 |
| Counter/report fields | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 38 vs 2+36 |
| Private L1 | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 29 vs 2+27 |
| Private L1 | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 38 vs s0+s1 |
| Shared L2 | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 36 vs 0+36 |
| L3 UCP | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 36 vs 6+30 |
| L3 UCP | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 6+3 |
| L3 UCP | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 27 vs 0+27 |
| L3 UCP | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 36 vs s0+s1 |
| Policy mode | `dynamic_ucp_long_stream1.mode3_l3_utility_fixed.utility_alloc` | PASS | Fixed utility-guided mode allocates 6/2 lines | alloc=6/2 |
| Counter/report fields | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 38 vs 2+36 |
| Private L1 | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 29 vs 2+27 |
| Private L1 | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 38 vs s0+s1 |
| Shared L2 | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 36 vs 0+36 |
| L3 UCP | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 36 vs 21+15 |
| L3 UCP | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 1+8 |
| L3 UCP | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 27 vs 20+7 |
| L3 UCP | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 36 vs s0+s1 |
| Policy mode | `dynamic_ucp_long_stream1.mode4_dynamic_ucp.dynamic_alloc_sum` | PASS | Dynamic UCP allocation remains valid and sums to 8 | alloc=3/5 |
| Counter/report fields | `l3_reuse_after_l2_eviction.mode0_l3_disabled.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `l3_reuse_after_l2_eviction.mode0_l3_disabled.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 8 vs 0+8 |
| Private L1 | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 5 vs 0+5 |
| Private L1 | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 8 vs s0+s1 |
| Shared L2 | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 8 vs 0+8 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 0 vs 0+0 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 0 vs 0+0 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 0 vs 0+0 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 0 vs s0+s1 |
| Policy mode | `l3_reuse_after_l2_eviction.mode0_l3_disabled.l3_disabled_no_l3_access` | PASS | L3 disabled mode does not create L3 accesses | l3_accesses=0 |
| Fill path | `l3_reuse_after_l2_eviction.mode0_l3_disabled.backing_used_without_l3` | PASS | Without L3, L2 misses fall through to backing memory | backing=8 |
| Counter/report fields | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 8 vs 0+8 |
| Private L1 | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 5 vs 0+5 |
| Private L1 | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 8 vs s0+s1 |
| Shared L2 | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 8 vs 0+8 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 8 vs 2+6 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 5 vs 1+4 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 3 vs 1+2 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 8 vs s0+s1 |
| Policy mode | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_unpartitioned_accessed` | PASS | Unpartitioned L3 is active | l3_accesses=8 |
| Fill path | `l3_reuse_after_l2_eviction.mode1_l3_unpartitioned.l3_reuse` | PASS | After L1/L2 conflicts, repeated data can be served from L3 | l3_hits=2 |
| Counter/report fields | `l3_reuse_after_l2_eviction.mode2_l3_equal.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `l3_reuse_after_l2_eviction.mode2_l3_equal.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `l3_reuse_after_l2_eviction.mode2_l3_equal.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 8 vs 0+8 |
| Private L1 | `l3_reuse_after_l2_eviction.mode2_l3_equal.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 5 vs 0+5 |
| Private L1 | `l3_reuse_after_l2_eviction.mode2_l3_equal.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `l3_reuse_after_l2_eviction.mode2_l3_equal.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 8 vs s0+s1 |
| Shared L2 | `l3_reuse_after_l2_eviction.mode2_l3_equal.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 8 vs 0+8 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode2_l3_equal.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 8 vs 2+6 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode2_l3_equal.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 5 vs 1+4 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode2_l3_equal.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 3 vs 1+2 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode2_l3_equal.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 8 vs s0+s1 |
| Policy mode | `l3_reuse_after_l2_eviction.mode2_l3_equal.equal_alloc` | PASS | Equal UCP mode allocates 4/4 lines | alloc=4/4 |
| Fill path | `l3_reuse_after_l2_eviction.mode2_l3_equal.l3_reuse` | PASS | After L1/L2 conflicts, repeated data can be served from L3 | l3_hits=2 |
| Counter/report fields | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 8 vs 0+8 |
| Private L1 | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 5 vs 0+5 |
| Private L1 | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 8 vs s0+s1 |
| Shared L2 | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 8 vs 0+8 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 8 vs 2+6 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 5 vs 2+3 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 3 vs 0+3 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 8 vs s0+s1 |
| Policy mode | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.utility_alloc` | PASS | Fixed utility-guided mode allocates 6/2 lines | alloc=6/2 |
| Fill path | `l3_reuse_after_l2_eviction.mode3_l3_utility_fixed.l3_reuse` | PASS | After L1/L2 conflicts, repeated data can be served from L3 | l3_hits=2 |
| Counter/report fields | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 8 vs 0+8 |
| Private L1 | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 5 vs 0+5 |
| Private L1 | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 8 vs s0+s1 |
| Shared L2 | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 8 vs 0+8 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 8 vs 2+6 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 5 vs 1+4 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 3 vs 1+2 |
| L3 UCP | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 8 vs s0+s1 |
| Policy mode | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.dynamic_alloc_sum` | PASS | Dynamic UCP allocation remains valid and sums to 8 | alloc=4/4 |
| Fill path | `l3_reuse_after_l2_eviction.mode4_dynamic_ucp.l3_reuse` | PASS | After L1/L2 conflicts, repeated data can be served from L3 | l3_hits=2 |
| Counter/report fields | `shared_l2_reuse.mode0_l3_disabled.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `shared_l2_reuse.mode0_l3_disabled.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `shared_l2_reuse.mode0_l3_disabled.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 6 vs 0+6 |
| Private L1 | `shared_l2_reuse.mode0_l3_disabled.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode0_l3_disabled.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode0_l3_disabled.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 6 vs s0+s1 |
| Shared L2 | `shared_l2_reuse.mode0_l3_disabled.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 6 vs 2+4 |
| L3 UCP | `shared_l2_reuse.mode0_l3_disabled.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 0 vs 0+0 |
| L3 UCP | `shared_l2_reuse.mode0_l3_disabled.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 0 vs 0+0 |
| L3 UCP | `shared_l2_reuse.mode0_l3_disabled.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 0 vs 0+0 |
| L3 UCP | `shared_l2_reuse.mode0_l3_disabled.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 0 vs s0+s1 |
| Policy mode | `shared_l2_reuse.mode0_l3_disabled.l3_disabled_no_l3_access` | PASS | L3 disabled mode does not create L3 accesses | l3_accesses=0 |
| Fill path | `shared_l2_reuse.mode0_l3_disabled.backing_used_without_l3` | PASS | Without L3, L2 misses fall through to backing memory | backing=4 |
| Shared L2 | `shared_l2_reuse.mode0_l3_disabled.shared_l2_hits` | PASS | Both streams can benefit from shared L2 reuse | l2_hits=2 |
| Stream split | `shared_l2_reuse.mode0_l3_disabled.both_streams_access_l1` | PASS | Benchmark exercised both address-derived streams | s0=3 s1=3 |
| Counter/report fields | `shared_l2_reuse.mode1_l3_unpartitioned.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `shared_l2_reuse.mode1_l3_unpartitioned.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `shared_l2_reuse.mode1_l3_unpartitioned.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 6 vs 0+6 |
| Private L1 | `shared_l2_reuse.mode1_l3_unpartitioned.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode1_l3_unpartitioned.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode1_l3_unpartitioned.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 6 vs s0+s1 |
| Shared L2 | `shared_l2_reuse.mode1_l3_unpartitioned.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 6 vs 2+4 |
| L3 UCP | `shared_l2_reuse.mode1_l3_unpartitioned.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 4 vs 0+4 |
| L3 UCP | `shared_l2_reuse.mode1_l3_unpartitioned.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode1_l3_unpartitioned.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode1_l3_unpartitioned.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 4 vs s0+s1 |
| Policy mode | `shared_l2_reuse.mode1_l3_unpartitioned.l3_unpartitioned_accessed` | PASS | Unpartitioned L3 is active | l3_accesses=4 |
| Shared L2 | `shared_l2_reuse.mode1_l3_unpartitioned.shared_l2_hits` | PASS | Both streams can benefit from shared L2 reuse | l2_hits=2 |
| Stream split | `shared_l2_reuse.mode1_l3_unpartitioned.both_streams_access_l1` | PASS | Benchmark exercised both address-derived streams | s0=3 s1=3 |
| Counter/report fields | `shared_l2_reuse.mode2_l3_equal.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `shared_l2_reuse.mode2_l3_equal.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `shared_l2_reuse.mode2_l3_equal.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 6 vs 0+6 |
| Private L1 | `shared_l2_reuse.mode2_l3_equal.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode2_l3_equal.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode2_l3_equal.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 6 vs s0+s1 |
| Shared L2 | `shared_l2_reuse.mode2_l3_equal.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 6 vs 2+4 |
| L3 UCP | `shared_l2_reuse.mode2_l3_equal.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 4 vs 0+4 |
| L3 UCP | `shared_l2_reuse.mode2_l3_equal.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode2_l3_equal.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode2_l3_equal.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 4 vs s0+s1 |
| Policy mode | `shared_l2_reuse.mode2_l3_equal.equal_alloc` | PASS | Equal UCP mode allocates 4/4 lines | alloc=4/4 |
| Shared L2 | `shared_l2_reuse.mode2_l3_equal.shared_l2_hits` | PASS | Both streams can benefit from shared L2 reuse | l2_hits=2 |
| Stream split | `shared_l2_reuse.mode2_l3_equal.both_streams_access_l1` | PASS | Benchmark exercised both address-derived streams | s0=3 s1=3 |
| Counter/report fields | `shared_l2_reuse.mode3_l3_utility_fixed.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `shared_l2_reuse.mode3_l3_utility_fixed.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `shared_l2_reuse.mode3_l3_utility_fixed.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 6 vs 0+6 |
| Private L1 | `shared_l2_reuse.mode3_l3_utility_fixed.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode3_l3_utility_fixed.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode3_l3_utility_fixed.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 6 vs s0+s1 |
| Shared L2 | `shared_l2_reuse.mode3_l3_utility_fixed.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 6 vs 2+4 |
| L3 UCP | `shared_l2_reuse.mode3_l3_utility_fixed.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 4 vs 0+4 |
| L3 UCP | `shared_l2_reuse.mode3_l3_utility_fixed.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode3_l3_utility_fixed.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode3_l3_utility_fixed.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 4 vs s0+s1 |
| Policy mode | `shared_l2_reuse.mode3_l3_utility_fixed.utility_alloc` | PASS | Fixed utility-guided mode allocates 6/2 lines | alloc=6/2 |
| Shared L2 | `shared_l2_reuse.mode3_l3_utility_fixed.shared_l2_hits` | PASS | Both streams can benefit from shared L2 reuse | l2_hits=2 |
| Stream split | `shared_l2_reuse.mode3_l3_utility_fixed.both_streams_access_l1` | PASS | Benchmark exercised both address-derived streams | s0=3 s1=3 |
| Counter/report fields | `shared_l2_reuse.mode4_dynamic_ucp.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `shared_l2_reuse.mode4_dynamic_ucp.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `shared_l2_reuse.mode4_dynamic_ucp.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 6 vs 0+6 |
| Private L1 | `shared_l2_reuse.mode4_dynamic_ucp.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode4_dynamic_ucp.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 3 vs 0+3 |
| Private L1 | `shared_l2_reuse.mode4_dynamic_ucp.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 6 vs s0+s1 |
| Shared L2 | `shared_l2_reuse.mode4_dynamic_ucp.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 6 vs 2+4 |
| L3 UCP | `shared_l2_reuse.mode4_dynamic_ucp.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 4 vs 0+4 |
| L3 UCP | `shared_l2_reuse.mode4_dynamic_ucp.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode4_dynamic_ucp.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 2 vs 0+2 |
| L3 UCP | `shared_l2_reuse.mode4_dynamic_ucp.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 4 vs s0+s1 |
| Policy mode | `shared_l2_reuse.mode4_dynamic_ucp.dynamic_alloc_sum` | PASS | Dynamic UCP allocation remains valid and sums to 8 | alloc=4/4 |
| Shared L2 | `shared_l2_reuse.mode4_dynamic_ucp.shared_l2_hits` | PASS | Both streams can benefit from shared L2 reuse | l2_hits=2 |
| Stream split | `shared_l2_reuse.mode4_dynamic_ucp.both_streams_access_l1` | PASS | Benchmark exercised both address-derived streams | s0=3 s1=3 |
| Counter/report fields | `utility_pressure.mode0_l3_disabled.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `utility_pressure.mode0_l3_disabled.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `utility_pressure.mode0_l3_disabled.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 13 vs 0+13 |
| Private L1 | `utility_pressure.mode0_l3_disabled.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `utility_pressure.mode0_l3_disabled.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 4 vs 0+4 |
| Private L1 | `utility_pressure.mode0_l3_disabled.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 13 vs s0+s1 |
| Shared L2 | `utility_pressure.mode0_l3_disabled.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 13 vs 0+13 |
| L3 UCP | `utility_pressure.mode0_l3_disabled.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 0 vs 0+0 |
| L3 UCP | `utility_pressure.mode0_l3_disabled.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 0 vs 0+0 |
| L3 UCP | `utility_pressure.mode0_l3_disabled.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 0 vs 0+0 |
| L3 UCP | `utility_pressure.mode0_l3_disabled.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 0 vs s0+s1 |
| Policy mode | `utility_pressure.mode0_l3_disabled.l3_disabled_no_l3_access` | PASS | L3 disabled mode does not create L3 accesses | l3_accesses=0 |
| Fill path | `utility_pressure.mode0_l3_disabled.backing_used_without_l3` | PASS | Without L3, L2 misses fall through to backing memory | backing=13 |
| Counter/report fields | `utility_pressure.mode1_l3_unpartitioned.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `utility_pressure.mode1_l3_unpartitioned.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `utility_pressure.mode1_l3_unpartitioned.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 13 vs 0+13 |
| Private L1 | `utility_pressure.mode1_l3_unpartitioned.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `utility_pressure.mode1_l3_unpartitioned.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 4 vs 0+4 |
| Private L1 | `utility_pressure.mode1_l3_unpartitioned.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 13 vs s0+s1 |
| Shared L2 | `utility_pressure.mode1_l3_unpartitioned.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 13 vs 0+13 |
| L3 UCP | `utility_pressure.mode1_l3_unpartitioned.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 13 vs 5+8 |
| L3 UCP | `utility_pressure.mode1_l3_unpartitioned.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 4+5 |
| L3 UCP | `utility_pressure.mode1_l3_unpartitioned.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 4 vs 1+3 |
| L3 UCP | `utility_pressure.mode1_l3_unpartitioned.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 13 vs s0+s1 |
| Policy mode | `utility_pressure.mode1_l3_unpartitioned.l3_unpartitioned_accessed` | PASS | Unpartitioned L3 is active | l3_accesses=13 |
| Counter/report fields | `utility_pressure.mode2_l3_equal.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `utility_pressure.mode2_l3_equal.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `utility_pressure.mode2_l3_equal.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 13 vs 0+13 |
| Private L1 | `utility_pressure.mode2_l3_equal.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `utility_pressure.mode2_l3_equal.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 4 vs 0+4 |
| Private L1 | `utility_pressure.mode2_l3_equal.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 13 vs s0+s1 |
| Shared L2 | `utility_pressure.mode2_l3_equal.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 13 vs 0+13 |
| L3 UCP | `utility_pressure.mode2_l3_equal.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 13 vs 3+10 |
| L3 UCP | `utility_pressure.mode2_l3_equal.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 2+7 |
| L3 UCP | `utility_pressure.mode2_l3_equal.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 4 vs 1+3 |
| L3 UCP | `utility_pressure.mode2_l3_equal.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 13 vs s0+s1 |
| Policy mode | `utility_pressure.mode2_l3_equal.equal_alloc` | PASS | Equal UCP mode allocates 4/4 lines | alloc=4/4 |
| Stress | `utility_pressure.mode2_l3_equal.utility_pressure_l3_active` | PASS | Utility pressure benchmark creates L3 activity | l3_accesses=13 |
| Counter/report fields | `utility_pressure.mode3_l3_utility_fixed.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `utility_pressure.mode3_l3_utility_fixed.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `utility_pressure.mode3_l3_utility_fixed.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 13 vs 0+13 |
| Private L1 | `utility_pressure.mode3_l3_utility_fixed.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `utility_pressure.mode3_l3_utility_fixed.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 4 vs 0+4 |
| Private L1 | `utility_pressure.mode3_l3_utility_fixed.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 13 vs s0+s1 |
| Shared L2 | `utility_pressure.mode3_l3_utility_fixed.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 13 vs 0+13 |
| L3 UCP | `utility_pressure.mode3_l3_utility_fixed.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 13 vs 6+7 |
| L3 UCP | `utility_pressure.mode3_l3_utility_fixed.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 6+3 |
| L3 UCP | `utility_pressure.mode3_l3_utility_fixed.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 4 vs 0+4 |
| L3 UCP | `utility_pressure.mode3_l3_utility_fixed.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 13 vs s0+s1 |
| Policy mode | `utility_pressure.mode3_l3_utility_fixed.utility_alloc` | PASS | Fixed utility-guided mode allocates 6/2 lines | alloc=6/2 |
| Stress | `utility_pressure.mode3_l3_utility_fixed.utility_pressure_l3_active` | PASS | Utility pressure benchmark creates L3 activity | l3_accesses=13 |
| Counter/report fields | `utility_pressure.mode4_dynamic_ucp.required_fields` | PASS | All critical UCP fields are present | missing= |
| Architectural correctness | `utility_pressure.mode4_dynamic_ucp.simulation_pass` | PASS | Testbench checked registers, x0, illegal instruction, timeout, and internal counters | pass=PASS |
| Private L1 | `utility_pressure.mode4_dynamic_ucp.l1_total_consistency` | PASS | Total L1 hits plus misses equals accesses | 13 vs 0+13 |
| Private L1 | `utility_pressure.mode4_dynamic_ucp.l1_core0_consistency` | PASS | Stream 0 private L1 hits plus misses equals stream 0 accesses | 9 vs 0+9 |
| Private L1 | `utility_pressure.mode4_dynamic_ucp.l1_core1_consistency` | PASS | Stream 1 private L1 hits plus misses equals stream 1 accesses | 4 vs 0+4 |
| Private L1 | `utility_pressure.mode4_dynamic_ucp.l1_stream_sum` | PASS | Private stream counters sum to total L1 accesses | 13 vs s0+s1 |
| Shared L2 | `utility_pressure.mode4_dynamic_ucp.l2_consistency` | PASS | Shared L2 hits plus misses equals accesses | 13 vs 0+13 |
| L3 UCP | `utility_pressure.mode4_dynamic_ucp.l3_total_consistency` | PASS | L3 hits plus misses equals accesses | 13 vs 1+12 |
| L3 UCP | `utility_pressure.mode4_dynamic_ucp.l3_stream0_consistency` | PASS | Stream 0 L3 hits plus misses equals stream 0 L3 accesses | 9 vs 1+8 |
| L3 UCP | `utility_pressure.mode4_dynamic_ucp.l3_stream1_consistency` | PASS | Stream 1 L3 hits plus misses equals stream 1 L3 accesses | 4 vs 0+4 |
| L3 UCP | `utility_pressure.mode4_dynamic_ucp.l3_stream_sum` | PASS | Per-stream L3 accesses sum to total L3 accesses | 13 vs s0+s1 |
| Policy mode | `utility_pressure.mode4_dynamic_ucp.dynamic_alloc_sum` | PASS | Dynamic UCP allocation remains valid and sums to 8 | alloc=3/5 |
| Dynamic UCP | `utility_pressure.mode4_dynamic_ucp.dynamic_repartitioned` | PASS | Dynamic UCP repartitions on the pressure benchmark | repartitions=1 |
| Dynamic UCP | `utility_pressure.mode4_dynamic_ucp.dynamic_moved_from_equal` | PASS | Dynamic UCP moved away from the initial equal split | alloc=3/5 |
| Policy comparison | `utility_pressure.utility_vs_equal_l3_hits` | PASS | Utility fixed allocation should improve or preserve L3 hits for stream 0 hot-set pressure | utility_s0_hits=6 equal_s0_hits=2 |
| Policy comparison | `utility_pressure.utility_vs_equal_backing` | PASS | Utility fixed allocation should not increase backing pressure on the hot-set benchmark | utility_backing=7 equal_backing=10 |
| Policy comparison | `utility_pressure.utility_vs_equal_cycles` | PASS | Utility fixed allocation should not be slower on the current hot-set benchmark | utility_cycles=181 equal_cycles=205 |
| Policy comparison | `utility_pressure.l3_reduces_backing_vs_disabled` | PASS | Enabling partitioned L3 should reduce backing-memory accesses versus L3 disabled | equal_backing=10 disabled_backing=13 |
| Policy comparison | `utility_pressure.equal_partition_boundary` | PASS | Equal partition differs from unpartitioned mode but preserves architectural pass | equal=PASS unpart=PASS |
| Dynamic UCP | `dynamic_long.dynamic_vs_equal_l3_hits` | PASS | Long benchmark should give dynamic UCP more L3 hits than equal partition after repartition | dynamic_l3_hits=21 equal_l3_hits=16 |
| Dynamic UCP | `dynamic_long.dynamic_vs_equal_backing` | PASS | Long benchmark should reduce backing-memory accesses versus equal partition | dynamic_backing=15 equal_backing=20 |
| Dynamic UCP | `dynamic_long.dynamic_vs_equal_cycles` | PASS | Long benchmark should reduce simulated cycles versus equal partition | dynamic_cycles=462 equal_cycles=502 |
| Dynamic UCP | `dynamic_long.dynamic_beats_fixed_stream1` | PASS | Dynamic UCP should beat fixed stream-0-biased policy on a later stream-1 hot phase | dynamic_s1_hits=20 fixed_s1_hits=0 |
| Stream split | `trace.stream0_below_split` | PASS | Trace contains accesses below STREAM_SPLIT_ADDR mapped to stream 0 | seen_stream0=True |
| Stream split | `trace.stream1_at_or_above_split` | PASS | Trace contains accesses at or above STREAM_SPLIT_ADDR mapped to stream 1 | seen_stream1=True |
| Stream split | `trace.no_stream_id_mismatch` | PASS | Address-derived stream ID matches split rule in trace |  |
| L3 UCP | `trace.alloc_sum_invariant` | PASS | Trace allocation fields always sum to total L3 lines |  |
| Policy mode | `all_policy_modes_present` | PASS | All four Phase 14 policy modes were simulated | modes=mode0_l3_disabled,mode1_l3_unpartitioned,mode2_l3_equal,mode3_l3_utility_fixed,mode4_dynamic_ucp |
| Suite size | `minimum_20_meaningful_checks` | PASS | Runner must fail below 20 meaningful checks | checks=276 |
