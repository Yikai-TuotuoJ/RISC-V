.PHONY: help check-tools sim wave view-wave lint synth clean phase2-sim phase2-wave phase2-view-wave phase3-sim phase3-wave phase3-view-wave phase4-sim phase4-wave phase4-view-wave phase4-lint phase4-synth phase5-trace phase5-random phase5-lint phase5-synth phase5-view-trace-wave pipeline-tests phase6-branch phase6-lint phase6-synth phase7-gshare phase7-lint phase7-synth synth-reports benchmarks phase9-lint memory-latency phase10-lint cache-tests cache-hierarchy ucp-tests tomasulo-tests tomasulo-lint tomasulo-synth rob-tests rob-lint rob-synth lsq-tests lsq-lint lsq-synth ooo-tests ooo-lint ooo-synth

POWERSHELL ?= powershell

help:
	@echo Available targets:
	@echo   make check-tools
	@echo   make sim
	@echo   make wave
	@echo   make view-wave
	@echo   make lint
	@echo   make synth
	@echo   make pipeline-tests
	@echo   make phase6-branch
	@echo   make phase6-lint
	@echo   make phase6-synth
	@echo   make phase7-gshare
	@echo   make phase7-lint
	@echo   make phase7-synth
	@echo   make synth-reports
	@echo   make benchmarks
	@echo   make phase9-lint
	@echo   make memory-latency
	@echo   make phase10-lint
	@echo   make cache-tests
	@echo   make cache-hierarchy
	@echo   make ucp-tests
	@echo   make tomasulo-tests
	@echo   make tomasulo-lint
	@echo   make tomasulo-synth
	@echo   make rob-tests
	@echo   make rob-lint
	@echo   make rob-synth
	@echo   make lsq-tests
	@echo   make lsq-lint
	@echo   make lsq-synth
	@echo   make ooo-tests
	@echo   make ooo-lint
	@echo   make ooo-synth
	@echo   make clean

check-tools:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/check_tools.ps1

sim:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_sim.ps1

wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_wave.ps1

view-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/view_wave.ps1

lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_lint.ps1

synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_synth.ps1

clean:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/clean.ps1

phase2-sim:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase2_sim.ps1

phase2-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase2_wave.ps1

phase2-view-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/view_phase2_wave.ps1

phase3-sim:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase3_sim.ps1

phase3-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase3_wave.ps1

phase3-view-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/view_phase3_wave.ps1

phase4-sim:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase4_sim.ps1

phase4-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase4_wave.ps1

phase4-view-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/view_phase4_wave.ps1

phase4-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase4_lint.ps1

phase4-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase4_synth.ps1

phase5-trace:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase5_trace.ps1

phase5-random:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase5_random.ps1

phase5-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase5_lint.ps1

phase5-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase5_synth.ps1

phase5-view-trace-wave:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/view_phase5_trace_wave.ps1

pipeline-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_pipeline_tests.ps1

phase6-branch:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_branch_predictor_tests.ps1

phase6-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase6_lint.ps1

phase6-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase6_synth.ps1

phase7-gshare:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_gshare_tests.ps1

phase7-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase7_lint.ps1

phase7-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase7_synth.ps1

synth-reports:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_synth_reports.ps1

benchmarks:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_benchmarks.ps1

phase9-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase9_lint.ps1

memory-latency:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_memory_latency_tests.ps1

phase10-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_phase10_lint.ps1

cache-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_cache_tests.ps1

cache-hierarchy:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_cache_hierarchy_tests.ps1





ucp-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_ucp_tests.ps1


tomasulo-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_tomasulo_tests.ps1

tomasulo-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_tomasulo_lint.ps1

tomasulo-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_tomasulo_synth.ps1
rob-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_rob_tests.ps1

rob-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_rob_lint.ps1

rob-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_rob_synth.ps1
lsq-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_lsq_tests.ps1

lsq-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_lsq_lint.ps1

lsq-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_lsq_synth.ps1
ooo-tests:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_ooo_tests.ps1

ooo-lint:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_ooo_lint.ps1

ooo-synth:
	$(POWERSHELL) -ExecutionPolicy Bypass -File scripts/run_ooo_synth.ps1

