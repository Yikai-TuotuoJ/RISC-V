# Phase 15 SMT Summary

Meaningful checks reported: 126

| test | mode | stream_id_mode | ucp_mode | thread_id | pass_fail | cycles | retired | fetched | stalls | flushes | loads | stores | l1_hits | l1_misses | l2_hits | l2_misses | l3_hits | l3_misses | shadow_hits | cpi_estimate | log |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| branch_jump | smt | 1 | 2 | 0 | PASS | 29 | 5 | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | branch_jump_policy2.log |
| branch_jump | smt | 1 | 2 | 1 | PASS | 29 | 4 | 14 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | branch_jump_policy2.log |
| context_basic | smt | 1 | 2 | 0 | PASS | 28 | 5 | 13 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | context_basic_policy2.log |
| context_basic | smt | 1 | 2 | 1 | PASS | 28 | 4 | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | context_basic_policy2.log |
| hazard_memory | smt | 1 | 2 | 0 | PASS | 35 | 6 | 15 | 6 | 0 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | hazard_memory_policy2.log |
| hazard_memory | smt | 1 | 2 | 1 | PASS | 35 | 6 | 14 | 0 | 0 | 2 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | NA | NA | hazard_memory_policy2.log |
| smt_ucp_balanced | smt | 1 | 0 | 0 | PASS | 138 | 9 | 16 | 74 | 0 | 8 | 0 | 0 | 5 | 0 | 13 | 2 | 3 | NA | NA | smt_ucp_balanced_policy0.log |
| smt_ucp_balanced | smt | 1 | 0 | 1 | PASS | 138 | 9 | 16 | 32 | 0 | 8 | 0 | 0 | 8 | 0 | 13 | 4 | 4 | NA | NA | smt_ucp_balanced_policy0.log |
| smt_ucp_hot_stream | smt | 1 | 1 | 0 | PASS | 196 | 13 | 16 | 92 | 0 | 12 | 0 | 5 | 2 | 0 | 14 | 0 | 2 | NA | NA | smt_ucp_hot_stream_policy1.log |
| smt_ucp_hot_stream | smt | 1 | 1 | 1 | PASS | 196 | 13 | 16 | 72 | 0 | 12 | 0 | 0 | 12 | 0 | 14 | 0 | 12 | NA | NA | smt_ucp_hot_stream_policy1.log |
| smt_ucp_hot_stream | smt | 1 | 2 | 0 | PASS | 196 | 13 | 16 | 92 | 0 | 12 | 0 | 5 | 2 | 0 | 14 | 0 | 2 | NA | NA | smt_ucp_hot_stream_policy2.log |
| smt_ucp_hot_stream | smt | 1 | 2 | 1 | PASS | 196 | 13 | 16 | 72 | 0 | 12 | 0 | 0 | 12 | 0 | 14 | 0 | 12 | NA | NA | smt_ucp_hot_stream_policy2.log |
