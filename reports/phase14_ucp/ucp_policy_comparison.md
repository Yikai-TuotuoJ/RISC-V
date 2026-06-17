# Phase 14 UCP Policy Comparison

Policy mapping:

- `mode0_l3_disabled`: UCP disabled / L3 disabled baseline
- `mode1_l3_unpartitioned`: L3 enabled but UCP disabled
- `mode2_l3_equal`: L3 UCP equal partition, 4/4 lines
- `mode3_l3_utility_fixed`: L3 UCP fixed utility-guided partition, 6/2 lines
- `mode4_dynamic_ucp`: L3 UCP dynamic monitor partition

| test | mode | stream | L1 h/m | L2 h/m | L3 h/m | backing | alloc | cycles | CPI | pass |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| dynamic_ucp_long_stream1 | mode0_l3_disabled | 0 | 0/9 | 0/36 | 0/0 | 36 | 4 | 414 | 5.447 | PASS |
| dynamic_ucp_long_stream1 | mode0_l3_disabled | 1 | 2/27 | 0/36 | 0/0 | 36 | 4 | 414 | 5.447 | PASS |
| dynamic_ucp_long_stream1 | mode1_l3_unpartitioned | 0 | 0/9 | 0/36 | 4/5 | 12 | 4 | 438 | 5.763 | PASS |
| dynamic_ucp_long_stream1 | mode1_l3_unpartitioned | 1 | 2/27 | 0/36 | 20/7 | 12 | 4 | 438 | 5.763 | PASS |
| dynamic_ucp_long_stream1 | mode2_l3_equal | 0 | 0/9 | 0/36 | 2/7 | 20 | 4 | 502 | 6.605 | PASS |
| dynamic_ucp_long_stream1 | mode2_l3_equal | 1 | 2/27 | 0/36 | 14/13 | 20 | 4 | 502 | 6.605 | PASS |
| dynamic_ucp_long_stream1 | mode3_l3_utility_fixed | 0 | 0/9 | 0/36 | 6/3 | 30 | 6 | 582 | 7.658 | PASS |
| dynamic_ucp_long_stream1 | mode3_l3_utility_fixed | 1 | 2/27 | 0/36 | 0/27 | 30 | 2 | 582 | 7.658 | PASS |
| dynamic_ucp_long_stream1 | mode4_dynamic_ucp | 0 | 0/9 | 0/36 | 1/8 | 15 | 3 | 462 | 6.079 | PASS |
| dynamic_ucp_long_stream1 | mode4_dynamic_ucp | 1 | 2/27 | 0/36 | 20/7 | 15 | 5 | 462 | 6.079 | PASS |
| l3_reuse_after_l2_eviction | mode0_l3_disabled | 0 | 0/5 | 0/8 | 0/0 | 8 | 4 | 96 | 6.000 | PASS |
| l3_reuse_after_l2_eviction | mode0_l3_disabled | 1 | 0/3 | 0/8 | 0/0 | 8 | 4 | 96 | 6.000 | PASS |
| l3_reuse_after_l2_eviction | mode1_l3_unpartitioned | 0 | 0/5 | 0/8 | 1/4 | 6 | 4 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode1_l3_unpartitioned | 1 | 0/3 | 0/8 | 1/2 | 6 | 4 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode2_l3_equal | 0 | 0/5 | 0/8 | 1/4 | 6 | 4 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode2_l3_equal | 1 | 0/3 | 0/8 | 1/2 | 6 | 4 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode3_l3_utility_fixed | 0 | 0/5 | 0/8 | 2/3 | 6 | 6 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode3_l3_utility_fixed | 1 | 0/3 | 0/8 | 0/3 | 6 | 2 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode4_dynamic_ucp | 0 | 0/5 | 0/8 | 1/4 | 6 | 4 | 128 | 8.000 | PASS |
| l3_reuse_after_l2_eviction | mode4_dynamic_ucp | 1 | 0/3 | 0/8 | 1/2 | 6 | 4 | 128 | 8.000 | PASS |
| shared_l2_reuse | mode0_l3_disabled | 0 | 0/3 | 2/4 | 0/0 | 4 | 4 | 66 | 5.500 | PASS |
| shared_l2_reuse | mode0_l3_disabled | 1 | 0/3 | 2/4 | 0/0 | 4 | 4 | 66 | 5.500 | PASS |
| shared_l2_reuse | mode1_l3_unpartitioned | 0 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode1_l3_unpartitioned | 1 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode2_l3_equal | 0 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode2_l3_equal | 1 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode3_l3_utility_fixed | 0 | 0/3 | 2/4 | 0/2 | 4 | 6 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode3_l3_utility_fixed | 1 | 0/3 | 2/4 | 0/2 | 4 | 2 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode4_dynamic_ucp | 0 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| shared_l2_reuse | mode4_dynamic_ucp | 1 | 0/3 | 2/4 | 0/2 | 4 | 4 | 90 | 7.500 | PASS |
| utility_pressure | mode0_l3_disabled | 0 | 0/9 | 0/13 | 0/0 | 13 | 4 | 151 | 5.808 | PASS |
| utility_pressure | mode0_l3_disabled | 1 | 0/4 | 0/13 | 0/0 | 13 | 4 | 151 | 5.808 | PASS |
| utility_pressure | mode1_l3_unpartitioned | 0 | 0/9 | 0/13 | 4/5 | 8 | 4 | 189 | 7.269 | PASS |
| utility_pressure | mode1_l3_unpartitioned | 1 | 0/4 | 0/13 | 1/3 | 8 | 4 | 189 | 7.269 | PASS |
| utility_pressure | mode2_l3_equal | 0 | 0/9 | 0/13 | 2/7 | 10 | 4 | 205 | 7.885 | PASS |
| utility_pressure | mode2_l3_equal | 1 | 0/4 | 0/13 | 1/3 | 10 | 4 | 205 | 7.885 | PASS |
| utility_pressure | mode3_l3_utility_fixed | 0 | 0/9 | 0/13 | 6/3 | 7 | 6 | 181 | 6.962 | PASS |
| utility_pressure | mode3_l3_utility_fixed | 1 | 0/4 | 0/13 | 0/4 | 7 | 2 | 181 | 6.962 | PASS |
| utility_pressure | mode4_dynamic_ucp | 0 | 0/9 | 0/13 | 1/8 | 12 | 3 | 221 | 8.500 | PASS |
| utility_pressure | mode4_dynamic_ucp | 1 | 0/4 | 0/13 | 0/4 | 12 | 5 | 221 | 8.500 | PASS |

## Interview Notes

The comparison separates correctness from performance. Every row must first pass architectural checks in the RTL testbench.
Only after correctness is established do the counters show how private L1, shared L2, and partitioned L3 change where hits occur.
The dynamic UCP policy is now the main validation target: it starts from an equal split, monitors L3 behavior, and can repartition at interval boundaries while preserving architectural correctness. The long `dynamic_ucp_long_stream1` benchmark is designed to let dynamic UCP pay back its monitoring/repartition cost after stream 1 becomes the dominant hot set. The fixed utility-guided policy remains only as a comparison point.
This remains a simplified single-pipeline experiment with address-derived streams, not real multicore UCP or cache coherence.
