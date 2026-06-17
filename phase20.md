# Codex Task: Phase 20 — Consolidate Final Experimental Tomasulo + ROB + LSQ Core

Phase 19 has passed.

The repository now contains several separate experimental models:

- Phase 16 scoreboard / reservation-station preparation
- Phase 17 standalone Tomasulo-style reservation station + CDB experiment
- Phase 18 constrained ROB / in-order commit experiment
- Phase 19 limited LSQ preparation experiment
- Preserved single-cycle RV32I core
- Preserved 5-stage pipelined RV32I core
- Preserved SMT-style two-thread in-order pipeline
- Preserved cache/UCP hierarchy with dynamic UCP shadow-hit tests
- Windows PowerShell-based flow

Now continue to Phase 20.

## Phase 20 Goal

Build a consolidated final experimental **Tomasulo + ROB + LSQ core** by combining the previous standalone concepts into one coherent experimental design.

This should be the final architecture experiment before project wrap-up.

The goal is not to build a production out-of-order CPU.

The goal is to create one integrated, well-documented experimental core that demonstrates:

- reservation stations
- operand tags and ready bits
- CDB-style broadcast/wakeup
- rename-lite / register-status tracking
- ROB allocation and in-order commit
- LSQ entries for LW/SW
- conservative memory ordering
- stores committing through ROB
- loads completing into ROB
- explicit limitations versus full industrial OOO

## Important Scope Clarification

This phase should be described as:

```text
final experimental Tomasulo/ROB/LSQ core
```

or:

```text
integrated OOO-concept core
```

Do not describe it as:

```text
full production out-of-order CPU
complete ROB-based OOO backend
fully speculative Tomasulo CPU
industrial OOO processor
```

This is still an educational, open-source-tool-compatible SystemVerilog experiment.

## Preserve Existing Functionality

All previous flows must remain available and should still pass:

- single-cycle regression
- 5-stage pipeline regression
- SMT regression
- gshare regression
- cache/UCP regression
- dynamic UCP shadow-hit regression
- scoreboard tests
- Tomasulo Phase 17 tests
- ROB Phase 18 tests
- LSQ Phase 19 tests
- lint and synthesis sanity flows where available

Do not delete or break the previous experimental modules.

The new integrated core should be added as a new top/module/test path.

## SystemVerilog Style Requirement

Follow the repository SystemVerilog style guide.

Use:

- `.sv` files
- `logic`
- `always_ff`
- `always_comb`
- parameters/localparams
- clear enums where useful
- simple open-source-tool-compatible SystemVerilog

Avoid:

- UVM
- classes
- DPI
- vendor-specific IP
- complex interfaces unless already approved by the repo style guide

## Recommended New Module Structure

Create a final integrated experimental core.

Suggested files:

```text
rtl/ooo_experiment_core.sv
rtl/ooo_reservation_station.sv
rtl/ooo_rob.sv
rtl/ooo_lsq.sv
rtl/ooo_cdb.sv
rtl/ooo_reg_status.sv
rtl/ooo_alu.sv
tb/tb_ooo_experiment_core.sv
```

Alternative names are acceptable if clear.

Preferred top-level name:

```text
ooo_experiment_core
```

or:

```text
rv32i_ooo_experiment_core
```

The design should combine the Phase 17/18/19 ideas instead of leaving them as totally separate demonstrations.

## Supported Instruction Scope

Keep the integrated core intentionally limited.

Minimum supported instructions:

```text
ADDI
ADD
SUB
LW
SW
```

Preferred if already easy:

```text
AND
OR
XOR
```

Optional only if clean:

```text
LUI
AUIPC
```

Branches may be excluded from the final OOO experiment.

If branches are excluded, document clearly:

```text
Branch speculation, checkpointing, and rollback are not implemented in this experimental OOO core.
```

Do not attempt full RV32I support in this phase.

## Integrated Pipeline / Dataflow Requirement

The final experimental core should follow a coherent flow similar to:

```text
Instruction stream / small program memory
  -> decode into uops
  -> dispatch
  -> allocate ROB entry
  -> allocate RS entry for ALU uops
  -> allocate LSQ entry for memory uops
  -> track source readiness through register-status table
  -> issue ready ALU uops from RS
  -> process ready memory uops through LSQ conservatively
  -> broadcast completed results on CDB
  -> wake dependent RS/LSQ entries
  -> write completed results into ROB
  -> commit ROB head in order
  -> update architectural register file or memory at commit
```

This should be a unified experiment, not just three unrelated testbenches.

## Reservation Station Requirements

The integrated core should include reservation stations for ALU-type uops.

Each RS entry should track:

```text
valid
issued
thread_id if supported
operation
destination ROB tag
destination architectural register
source 1 ready
source 1 value
source 1 tag
source 2 ready
source 2 value
source 2 tag
immediate if needed
sequence ID if useful
```

Rules:

- ready entries may issue when functional unit is available
- dependent entries wait on CDB wakeup
- issued entries are not issued twice
- completed entries are freed
- source tags should refer to ROB tags or the chosen unified tag system

## Register-Status / Rename-Lite Requirements

Use a unified register-status table.

Preferred behavior:

```text
reg_status[rd] = newest in-flight ROB tag producing rd
```

Rules:

- x0 is never marked busy
- dispatch of destination-producing instruction updates reg_status
- source operands check reg_status:
  - if not busy, read architectural register value
  - if busy, wait on ROB tag
- commit clears reg_status only if committed ROB tag still matches current owner
- stale broadcasts or stale commits must not clear newer producer tags
- final register values must reflect in-order program semantics

If thread-aware support is included, reg_status should be per thread.

## ROB Requirements

The integrated core should include a ROB.

ROB entries should track:

```text
valid
thread_id if supported
operation type
destination architectural register
destination valid
ready/completed
result value
store flag if store
store address/data readiness if useful
sequence ID
```

Required behavior:

- dispatch allocates ROB in program order
- ROB full causes dispatch stall
- completion writes result into ROB
- only ready ROB head commits
- younger completed entries wait behind older incomplete head
- architectural register file updates only at commit
- stores update architectural memory only at commit
- x0 commit is suppressed
- commit counter increments only on actual commit

## LSQ Requirements

The integrated core should include an LSQ for LW/SW.

LSQ entries should track:

```text
valid
is_load
is_store
ROB tag
sequence ID
address ready
address value
address dependency tag if waiting
store data ready
store data value
store data dependency tag if waiting
completed
issued_to_memory
```

Conservative memory policy:

```text
A load waits behind older unresolved stores.
Stores update memory only at ROB commit.
No speculative store update.
No full memory disambiguation.
No replay.
```

Optional store-to-load forwarding is not required.

If forwarding is not implemented, document it as future work.

## CDB / Wakeup Requirements

Use a common broadcast path for completed results.

At minimum:

```text
cdb_valid
cdb_rob_tag
cdb_dest_reg optional
cdb_data
```

Broadcast should:

- wake matching RS source operands
- wake matching LSQ address/data operands
- mark matching ROB entry ready
- not directly commit architectural state
- not affect wrong tag
- not corrupt x0

If only one CDB is modeled, document that only one completion broadcasts per cycle.

## Out-of-Order Execution Demonstration

The integrated core must demonstrate limited out-of-order behavior.

At minimum, include a test where:

```text
Older instruction waits on an operand or memory condition.
Younger independent ALU instruction issues and completes first.
Younger instruction cannot commit before older ROB head.
After older instruction completes, commits occur in program order.
Final architectural state is correct.
```

This is the key Phase 20 proof.

## Memory Ordering Demonstration

The integrated core must also demonstrate memory ordering.

At minimum, include tests where:

```text
Older store waits for address or data.
Younger load waits conservatively behind older unresolved store.
Store updates memory only at ROB commit.
Load after committed store sees correct value.
Final architectural state and memory state are correct.
```

## Thread-Aware Scope

Thread-aware OOO integration is optional in Phase 20.

Given complexity, acceptable options are:

### Option A: single-thread final OOO experiment

This is acceptable if clearly documented.

### Option B: limited thread-aware tags

If practical, carry thread_id through ROB/RS/LSQ/CDB and prove wrong-thread wakeup does not occur.

Do not destabilize the final core by forcing full SMT+OOO integration.

If single-threaded, document:

```text
The final OOO experiment is single-threaded. Earlier Phase 15 separately validates SMT-style in-order thread tagging. Future work would combine SMT and full OOO.
```

## Cache/UCP Scope

Do not deeply integrate the final OOO core into the full private-L1/shared-L2/UCP-L3 hierarchy unless it is already easy and safe.

Acceptable memory backend:

- simple memory array
- simple memory-latency model

Document:

```text
The final OOO experiment focuses on Tomasulo/ROB/LSQ control concepts.
The existing cache/UCP hierarchy remains a separate validated experiment.
Future work would connect the OOO LSQ request path into the cache/UCP hierarchy.
```

This is preferable to a fragile fake integration.

## Counters and Reports

Add integrated OOO counters.

At minimum, report:

- instructions decoded
- instructions dispatched
- ROB allocations
- ROB full stalls
- RS allocations
- RS full stalls
- LSQ allocations
- LSQ full stalls
- ALU issues
- load issues
- store commits
- CDB broadcasts
- wakeup events
- completed uops
- ROB commits
- commit stalls due to head not ready
- younger-completed-waiting events
- conservative load/store ordering stalls
- stale tag ignored events
- x0 commit suppressions
- unsupported instructions

Preferred outputs:

```text
reports/perf/ooo_summary.md
reports/perf/ooo_summary.csv
reports/sim/ooo_trace.log
```

Example report columns:

```text
test | decoded | dispatched | rob_allocs | rs_allocs | lsq_allocs | alu_issues | load_issues | store_commits | broadcasts | wakeups | commits | commit_stalls | memory_order_stalls | younger_done_waiting | stale_tag_ignored | pass_fail
```

## Required Test Count

This phase must include a serious validation suite.

Minimum requirement:

```text
At least 30 meaningful integrated OOO tests must be implemented and run.
```

Recommended target:

```text
40+ meaningful tests/checks
```

The test runner must fail if fewer than 30 meaningful tests are run.

A meaningful test means:

- it exercises a distinct integrated OOO behavior
- it checks explicit expected register/memory/counter results
- it contributes to PASS/FAIL
- it is not just a duplicate script invocation
- it is not just a print statement

## Directed Test Requirements

Create directed tests for the integrated OOO experiment.

At minimum, include tests covering the categories below.

### Category A: Regression Preservation

1. Existing single-cycle regression still passes.
2. Existing pipeline regression still passes.
3. Existing SMT regression still passes.
4. Existing scoreboard regression still passes.
5. Existing Tomasulo Phase 17 regression still passes.
6. Existing ROB Phase 18 regression still passes.
7. Existing LSQ Phase 19 regression still passes.
8. Existing gshare/cache/UCP regression still passes.

### Category B: Dispatch / Allocation

9. Dispatch one ALU instruction.
10. Dispatch multiple ALU instructions.
11. Dispatch one load.
12. Dispatch one store.
13. ROB full stall is detected.
14. RS full stall is detected.
15. LSQ full stall is detected.
16. Unsupported instruction is rejected or reported cleanly.

### Category C: Register Status / Tags

17. Destination register maps to ROB tag.
18. Source waits on ROB tag.
19. x0 is never marked busy.
20. Newer producer replaces older register-status tag.
21. Stale older broadcast does not clear newer tag.
22. Commit clears reg_status only when tag matches.
23. Stale commit does not clear newer producer.

### Category D: RS / ALU / CDB

24. Independent ALU instruction issues.
25. Dependent ALU instruction waits.
26. Broadcast wakes dependent ALU instruction.
27. Multiple waiters wake from one broadcast.
28. Wrong tag does not wake.
29. ADD result correct.
30. SUB result correct.
31. ADDI result correct.
32. AND/OR/XOR result correct if supported.

### Category E: ROB Commit

33. Completed head commits.
34. Not-ready head stalls commit.
35. Younger completed entry waits behind older not-ready head.
36. Architectural register updates only at commit.
37. Broadcast does not directly update architectural state.
38. Commit to x0 is suppressed.
39. Final committed register state matches in-order semantics.

### Category F: LSQ / Memory Ordering

40. Load with ready address executes.
41. Store with ready address/data waits for ROB commit.
42. Store updates memory at commit.
43. Load after committed store reads correct value.
44. Younger load waits behind older unresolved store.
45. Load address waits on dependency tag.
46. Store data waits on dependency tag.
47. Wrong tag does not wake load/store dependency.
48. Conservative ordering stall counter increments.

### Category G: Integrated OOO Demonstrations

49. Younger independent ALU issues before older waiting ALU.
50. Younger independent ALU completes before older waiting ALU.
51. Younger completed ALU waits in ROB before commit.
52. Older completes, then commits before younger.
53. Older store blocks younger load conservatively.
54. Mixed ALU + LW + SW program produces correct final register and memory state.
55. Chain of dependent instructions completes correctly through wakeups.
56. Mixed independent/dependent program shows at least one out-of-order issue event.

### Category H: Report / Trace Consistency

57. dispatched >= committed.
58. completed >= committed.
59. issued <= dispatched.
60. ROB allocations match expected dispatch count.
61. LSQ allocations match expected memory uop count.
62. report contains all required counters.
63. CSV report is machine-readable.
64. trace contains dispatch, allocate, issue, broadcast, wakeup, complete, commit, and memory-order events.

The above list is intentionally larger than 30. Implement at least 30 meaningful tests across multiple categories.

## Test Runner Requirements

Add or update a Windows PowerShell script:

```text
scripts/run_ooo_tests.ps1
```

This script must:

- run the integrated OOO validation suite
- run required prior regressions or call existing regression scripts
- generate OOO reports
- generate OOO trace
- clearly print PASS or FAIL
- fail if fewer than 30 meaningful tests are run
- fail if required reports are missing
- fail if required counter fields are missing

If needed, add:

```text
scripts/summarize_ooo_reports.py
scripts/check_ooo_consistency.py
```

Preferred outputs:

```text
reports/perf/ooo_summary.md
reports/perf/ooo_summary.csv
reports/sim/ooo_trace.log
reports/perf/ooo_logs/
sim/phase20_ooo.vcd
```

Existing scripts should continue to work:

```text
scripts/check_tools.ps1
scripts/clean.ps1
scripts/run_sim.ps1
scripts/run_pipeline_tests.ps1
scripts/run_smt_tests.ps1
scripts/run_scoreboard_tests.ps1
scripts/run_tomasulo_tests.ps1
scripts/run_rob_tests.ps1
scripts/run_lsq_tests.ps1
scripts/run_phase14_ucp_validation.ps1
scripts/run_lint.ps1
scripts/run_synth.ps1
scripts/view_wave.ps1
```

## Trace Requirements

Generate a readable integrated OOO trace.

Example trace style:

```text
DISPATCH: cycle=4 rob=R1 rs=2 op=ADD rd=x5 src1_ready=1 src2_ready=0 q2=R0
DISPATCH: cycle=5 rob=R2 rs=3 op=ADDI rd=x6 src1_ready=1
ISSUE: cycle=6 rs=3 rob=R2 op=ADDI reason=ready
CDB: cycle=7 rob=R2 data=0000000a wake_entries=1 rob_ready=1
COMMIT_STALL: cycle=8 head=R1 reason=head_not_ready younger_ready=R2
ISSUE: cycle=9 rs=2 rob=R1 op=ADD reason=woken
CDB: cycle=10 rob=R1 data=0000000f rob_ready=1
COMMIT: cycle=11 rob=R1 rd=x5 data=0000000f
COMMIT: cycle=12 rob=R2 rd=x6 data=0000000a
LSQ_ALLOC: cycle=13 rob=R3 type=STORE addr_ready=1 data_ready=0
STORE_COMMIT: cycle=18 rob=R3 addr=00000100 data=0000002a
```

Trace is for debugging. PASS/FAIL must come from explicit checks.

## Documentation Updates

Update documentation to reflect Phase 20.

At minimum, update or create:

```text
docs/phase20_integrated_ooo_experiment.md
docs/ooo_experiment_notes.md
docs/tomasulo_notes.md
docs/rob_notes.md
docs/lsq_notes.md
docs/microarchitecture.md
docs/verification_plan.md
docs/debug_workflow.md
docs/resume_notes.md
README.md
```

Documentation should explain:

- why Phase 20 exists
- how earlier standalone experiments are consolidated
- final integrated OOO experimental dataflow
- reservation stations
- CDB/broadcast
- ROB completion vs commit
- LSQ conservative memory ordering
- supported instruction subset
- what is still excluded
- why branch speculation is not implemented
- why cache/UCP is not deeply integrated into the OOO core
- how to run the final OOO tests
- how to interpret reports and traces

## Interview-Oriented Analysis Requirement

Add an interviewer-oriented section to:

```text
docs/phase20_integrated_ooo_experiment.md
```

or:

```text
docs/resume_notes.md
```

It should explain:

- how the final experiment combines Tomasulo, ROB, and LSQ concepts
- why reservation stations enable readiness-based issue
- why ROB is needed for in-order commit
- why LSQ is needed for memory ordering
- why stores commit conservatively
- why branch speculation and full load-store disambiguation are deferred
- how this differs from a production OOO core
- how this fits into the overall RISC-V project story

## Resume Notes Requirement

Update resume notes honestly.

Good wording examples:

- Consolidated separate Tomasulo, ROB, and LSQ concept models into a final integrated OOO-style experimental core supporting a limited RV32I subset.
- Demonstrated readiness-based ALU issue, CDB wakeup, ROB in-order commit, and conservative load/store ordering through directed validation tests.
- Generated reports and traces for dispatch, issue, broadcast, wakeup, completion, commit, and memory-order events.
- Documented limitations versus production OOO processors, including lack of branch speculation, full memory disambiguation, and complete physical register renaming.

Avoid wording like:

- implemented full production out-of-order RISC-V CPU
- completed industrial Tomasulo CPU
- implemented full speculative OOO backend
- implemented precise exception handling
- implemented complete memory disambiguation and replay

## Validation Requirements

After implementation, run the Windows PowerShell flow.

At minimum, validate:

- Existing single-cycle regression still passes.
- Existing pipeline regression still passes.
- Existing SMT regression still passes.
- Existing scoreboard regression still passes.
- Existing Tomasulo Phase 17 regression still passes.
- Existing ROB Phase 18 regression still passes.
- Existing LSQ Phase 19 regression still passes.
- Existing branch/gshare/cache/UCP tests still pass.
- Integrated OOO validation suite runs at least 30 meaningful tests.
- Integrated OOO validation tests pass.
- OOO Markdown summary is generated.
- OOO CSV summary is generated.
- OOO trace is generated.
- VCD waveform is generated.
- Documentation is updated.

If available, also validate:

- Verilator lint passes or warnings are documented.
- Yosys synthesis sanity report still runs or limitations are documented.

## Phase 20 Acceptance Criteria

Phase 20 is complete only if:

1. Existing regressions still pass.
2. Existing SMT/cache/UCP/scoreboard/Tomasulo/ROB/LSQ tests still pass.
3. A final integrated OOO-style experimental core exists.
4. The core includes reservation-station behavior.
5. The core includes CDB-style broadcast/wakeup.
6. The core includes register-status / rename-lite tracking.
7. The core includes ROB completion and in-order commit.
8. The core includes LSQ behavior for LW/SW or clearly documented limited memory support.
9. Stores update memory only when safe, preferably at ROB commit.
10. At least one test demonstrates out-of-order issue.
11. At least one test demonstrates in-order commit despite out-of-order completion.
12. At least one test demonstrates conservative memory ordering.
13. At least 30 meaningful integrated tests are implemented and run.
14. The test runner fails if fewer than 30 meaningful tests are run.
15. OOO reports are generated.
16. OOO trace is generated.
17. Documentation clearly distinguishes this from full production OOO.
18. Resume notes are updated honestly.
19. No full branch speculation, precise exceptions, complete physical register renaming, or full memory disambiguation is claimed.

## Final Report Format

When finished, report:

```text
Phase implemented:
Integrated OOO model type:
Supported instructions:
Reservation station behavior:
Register-status / rename-lite behavior:
CDB/broadcast behavior:
ROB behavior:
LSQ behavior:
Memory ordering policy:
Commit behavior:
Thread-aware behavior:
Cache/UCP integration:
Validation suite size:
Reports generated:
Trace generated:
Key integrated OOO observations:
Files changed:
Commands run:
Single-cycle regression result:
Pipeline regression result:
SMT regression result:
Scoreboard regression result:
Tomasulo regression result:
ROB regression result:
LSQ regression result:
Gshare/cache/UCP regression result:
Integrated OOO test result:
Waveform/trace generated:
Lint result:
Synthesis result:
Remaining issues:
Ready for Phase 21: yes/no
Recommended Phase 21:
```

Recommended Phase 21 should be:

```text
Phase 21: Final project wrap-up, documentation, diagrams, demo scripts, and resume/interview mapping.
```

Do not start Phase 21 until Phase 20 is approved.