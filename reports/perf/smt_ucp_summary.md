# Phase 15 SMT/UCP Summary

Stream ID mode 1 means cache/UCP streams are selected from pipeline-carried thread IDs.

| test | stream_id_mode | ucp_mode | alloc0 | alloc1 | repartitions | l3_s0_accesses | l3_s0_hits | l3_s0_misses | l3_s1_accesses | l3_s1_hits | l3_s1_misses | backing | checks | pass_fail | log |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| branch_jump | 1 | 2 | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 20 | PASS | branch_jump_policy2.log |
| context_basic | 1 | 2 | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 20 | PASS | context_basic_policy2.log |
| hazard_memory | 1 | 2 | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 22 | PASS | hazard_memory_policy2.log |
| smt_ucp_balanced | 1 | 0 | 4 | 4 | 0 | 5 | 2 | 3 | 8 | 4 | 4 | 7 | 19 | PASS | smt_ucp_balanced_policy0.log |
| smt_ucp_hot_stream | 1 | 1 | 6 | 2 | 0 | 2 | 0 | 2 | 12 | 0 | 12 | 14 | 22 | PASS | smt_ucp_hot_stream_policy1.log |
| smt_ucp_hot_stream | 1 | 2 | 4 | 4 | 0 | 2 | 0 | 2 | 12 | 0 | 12 | 14 | 23 | PASS | smt_ucp_hot_stream_policy2.log |
