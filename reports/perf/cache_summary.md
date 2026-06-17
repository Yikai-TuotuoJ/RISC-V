# Cache Summary

| benchmark | dcache_enable | icache_enable | miss_penalty | pass | cycles | retired | cpi | stalls | memory_stalls | load_use_stalls | flushes | loads | stores | dcache_accesses | dcache_load_accesses | dcache_store_accesses | dcache_hits | dcache_misses | dcache_hit_rate | dcache_miss_penalty_cycles |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| conflict_loads | 0 | 0 | 3 | PASS | 20 | 10 | 2.000 | 4 | 0 | 2 | 0 | 4 | 0 | 4 | 4 | 0 | 0 | 0 | 0.00 | 0 |
| conflict_loads | 1 | 0 | 3 | PASS | 28 | 10 | 2.800 | 12 | 9 | 1 | 0 | 4 | 0 | 4 | 4 | 0 | 1 | 3 | 25.00 | 9 |
| conflict_loads | 1 | 0 | 5 | PASS | 34 | 10 | 3.400 | 18 | 15 | 1 | 0 | 4 | 0 | 4 | 4 | 0 | 1 | 3 | 25.00 | 15 |
| mixed_cache_program | 0 | 0 | 3 | PASS | 28 | 10 | 2.800 | 12 | 0 | 6 | 0 | 2 | 2 | 4 | 2 | 2 | 0 | 0 | 0.00 | 0 |
| mixed_cache_program | 1 | 0 | 3 | PASS | 34 | 10 | 3.400 | 18 | 6 | 6 | 0 | 2 | 2 | 4 | 2 | 2 | 2 | 2 | 50.00 | 6 |
| mixed_cache_program | 1 | 0 | 5 | PASS | 38 | 10 | 3.800 | 22 | 10 | 6 | 0 | 2 | 2 | 4 | 2 | 2 | 2 | 2 | 50.00 | 10 |
| repeated_load | 0 | 0 | 3 | PASS | 25 | 10 | 2.500 | 9 | 0 | 3 | 0 | 2 | 0 | 2 | 2 | 0 | 0 | 0 | 0.00 | 0 |
| repeated_load | 1 | 0 | 3 | PASS | 28 | 10 | 2.800 | 12 | 3 | 3 | 0 | 2 | 0 | 2 | 2 | 0 | 1 | 1 | 50.00 | 3 |
| repeated_load | 1 | 0 | 5 | PASS | 30 | 10 | 3.000 | 14 | 5 | 3 | 0 | 2 | 0 | 2 | 2 | 0 | 1 | 1 | 50.00 | 5 |
| store_load_check | 0 | 0 | 3 | PASS | 22 | 10 | 2.200 | 6 | 0 | 3 | 0 | 1 | 1 | 2 | 1 | 1 | 0 | 0 | 0.00 | 0 |
| store_load_check | 1 | 0 | 3 | PASS | 25 | 10 | 2.500 | 9 | 3 | 3 | 0 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 50.00 | 3 |
| store_load_check | 1 | 0 | 5 | PASS | 27 | 10 | 2.700 | 11 | 5 | 3 | 0 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 50.00 | 5 |
