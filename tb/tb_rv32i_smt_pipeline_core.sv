`timescale 1ns/1ps

module tb_rv32i_smt_pipeline_core;
    parameter DMEM_LATENCY_CYCLES = 1;
    parameter DCACHE_ENABLE = 1;
    parameter DCACHE_LINES = 1;
    parameter DCACHE_MISS_PENALTY_CYCLES = 3;
    parameter L2_ENABLE = 1;
    parameter L2_LINES = 1;
    parameter L2_HIT_LATENCY = 2;
    parameter L2_MISS_PENALTY = 6;
    parameter PRIVATE_L1_ENABLE = 1;
    parameter L1_NUM_CORES = 2;
    parameter L3_ENABLE = 1;
    parameter L3_LINES = 8;
    parameter L3_UCP_ENABLE = 1;
    parameter L3_UCP_POLICY = 2;
    parameter UCP_REPARTITION_INTERVAL = 8;
    parameter STREAM_SPLIT_ADDR = 32'h00000080;
    parameter STREAM_ID_MODE = 1;
    parameter L3_HIT_LATENCY = 4;
    parameter L3_MISS_PENALTY = 12;

    logic clk;
    logic rst_n;
    logic [31:0] pc0_dbg, pc1_dbg;
    logic fetch_tid_dbg, illegal_instr_dbg;
    logic trace_if_valid, trace_if_tid, trace_id_valid, trace_id_tid, trace_ex_valid, trace_ex_tid;
    logic trace_mem_valid, trace_mem_tid, trace_wb_valid, trace_wb_tid;
    logic [31:0] trace_if_pc, trace_if_instr, trace_id_pc, trace_id_instr, trace_ex_pc, trace_ex_instr;
    logic [31:0] trace_mem_pc, trace_mem_instr, trace_wb_pc, trace_wb_instr, trace_wb_wdata;
    logic [4:0] trace_wb_rd;
    logic trace_wb_we, trace_stall, trace_flush, trace_redirect, trace_redirect_tid;
    logic [31:0] trace_redirect_target;
    logic trace_raw_stall, trace_mem_stall;
    logic [31:0] perf_cycle_count, perf_retired_count, perf_thread0_fetched_count, perf_thread1_fetched_count;
    logic [31:0] perf_thread0_retired_count, perf_thread1_retired_count, perf_thread0_stall_count, perf_thread1_stall_count;
    logic [31:0] perf_thread0_flush_count, perf_thread1_flush_count, perf_thread0_load_count, perf_thread1_load_count;
    logic [31:0] perf_thread0_store_count, perf_thread1_store_count;
    logic trace_dcache_access, trace_dcache_load, trace_dcache_store, trace_dcache_hit, trace_dcache_miss;
    logic trace_dcache_stall, trace_dcache_fill, trace_l2_access, trace_l2_hit, trace_l2_miss;
    logic trace_l3_access, trace_l3_hit, trace_l3_miss, trace_backing_access, trace_ucp_stream_id;
    logic [1:0] trace_cache_hit_level;
    logic [31:0] trace_dcache_addr;
    logic [31:0] perf_l1_core0_access_count, perf_l1_core0_hit_count, perf_l1_core0_miss_count;
    logic [31:0] perf_l1_core1_access_count, perf_l1_core1_hit_count, perf_l1_core1_miss_count;
    logic [31:0] perf_l2_access_count, perf_l2_hit_count, perf_l2_miss_count;
    logic [31:0] perf_l3_access_count, perf_l3_hit_count, perf_l3_miss_count;
    logic [31:0] perf_l3_stream0_access_count, perf_l3_stream0_hit_count, perf_l3_stream0_miss_count;
    logic [31:0] perf_l3_stream1_access_count, perf_l3_stream1_hit_count, perf_l3_stream1_miss_count;
    logic [31:0] perf_l3_stream0_alloc_lines, perf_l3_stream1_alloc_lines, perf_l3_ucp_repartition_count, perf_l3_ucp_interval_count;
    logic [31:0] perf_backing_access_count;

    logic [1023:0] bench_name;
    logic [1023:0] hex0;
    logic [1023:0] hex1;
    integer bench_id, exp_ret0, exp_ret1, timeout_cycles, errors, checks, trace_fd, ucp_fd, i;

    rv32i_smt_pipeline_core #(
        .DMEM_LATENCY_CYCLES(DMEM_LATENCY_CYCLES),
        .DCACHE_ENABLE(DCACHE_ENABLE), .DCACHE_LINES(DCACHE_LINES),
        .DCACHE_MISS_PENALTY_CYCLES(DCACHE_MISS_PENALTY_CYCLES),
        .L2_ENABLE(L2_ENABLE), .L2_LINES(L2_LINES), .L2_HIT_LATENCY(L2_HIT_LATENCY),
        .L2_MISS_PENALTY(L2_MISS_PENALTY), .PRIVATE_L1_ENABLE(PRIVATE_L1_ENABLE),
        .L1_NUM_CORES(L1_NUM_CORES), .L3_ENABLE(L3_ENABLE), .L3_LINES(L3_LINES),
        .L3_UCP_ENABLE(L3_UCP_ENABLE), .L3_UCP_POLICY(L3_UCP_POLICY),
        .UCP_REPARTITION_INTERVAL(UCP_REPARTITION_INTERVAL),
        .STREAM_SPLIT_ADDR(STREAM_SPLIT_ADDR), .STREAM_ID_MODE(STREAM_ID_MODE),
        .L3_HIT_LATENCY(L3_HIT_LATENCY), .L3_MISS_PENALTY(L3_MISS_PENALTY)
    ) dut (
        .clk(clk), .rst_n(rst_n), .pc0_dbg(pc0_dbg), .pc1_dbg(pc1_dbg), .fetch_tid_dbg(fetch_tid_dbg),
        .illegal_instr_dbg(illegal_instr_dbg),
        .trace_if_valid(trace_if_valid), .trace_if_tid(trace_if_tid), .trace_if_pc(trace_if_pc), .trace_if_instr(trace_if_instr),
        .trace_id_valid(trace_id_valid), .trace_id_tid(trace_id_tid), .trace_id_pc(trace_id_pc), .trace_id_instr(trace_id_instr),
        .trace_ex_valid(trace_ex_valid), .trace_ex_tid(trace_ex_tid), .trace_ex_pc(trace_ex_pc), .trace_ex_instr(trace_ex_instr),
        .trace_mem_valid(trace_mem_valid), .trace_mem_tid(trace_mem_tid), .trace_mem_pc(trace_mem_pc), .trace_mem_instr(trace_mem_instr),
        .trace_wb_valid(trace_wb_valid), .trace_wb_tid(trace_wb_tid), .trace_wb_pc(trace_wb_pc), .trace_wb_instr(trace_wb_instr),
        .trace_wb_rd(trace_wb_rd), .trace_wb_wdata(trace_wb_wdata), .trace_wb_we(trace_wb_we),
        .trace_stall(trace_stall), .trace_flush(trace_flush), .trace_redirect(trace_redirect),
        .trace_redirect_tid(trace_redirect_tid), .trace_redirect_target(trace_redirect_target),
        .trace_raw_stall(trace_raw_stall), .trace_mem_stall(trace_mem_stall),
        .perf_cycle_count(perf_cycle_count), .perf_retired_count(perf_retired_count),
        .perf_thread0_fetched_count(perf_thread0_fetched_count), .perf_thread1_fetched_count(perf_thread1_fetched_count),
        .perf_thread0_retired_count(perf_thread0_retired_count), .perf_thread1_retired_count(perf_thread1_retired_count),
        .perf_thread0_stall_count(perf_thread0_stall_count), .perf_thread1_stall_count(perf_thread1_stall_count),
        .perf_thread0_flush_count(perf_thread0_flush_count), .perf_thread1_flush_count(perf_thread1_flush_count),
        .perf_thread0_load_count(perf_thread0_load_count), .perf_thread1_load_count(perf_thread1_load_count),
        .perf_thread0_store_count(perf_thread0_store_count), .perf_thread1_store_count(perf_thread1_store_count),
        .trace_dcache_access(trace_dcache_access), .trace_dcache_load(trace_dcache_load), .trace_dcache_store(trace_dcache_store),
        .trace_dcache_hit(trace_dcache_hit), .trace_dcache_miss(trace_dcache_miss), .trace_dcache_stall(trace_dcache_stall),
        .trace_dcache_fill(trace_dcache_fill), .trace_dcache_addr(trace_dcache_addr),
        .trace_l2_access(trace_l2_access), .trace_l2_hit(trace_l2_hit), .trace_l2_miss(trace_l2_miss),
        .trace_l3_access(trace_l3_access), .trace_l3_hit(trace_l3_hit), .trace_l3_miss(trace_l3_miss),
        .trace_backing_access(trace_backing_access), .trace_ucp_stream_id(trace_ucp_stream_id), .trace_cache_hit_level(trace_cache_hit_level),
        .perf_l1_core0_access_count(perf_l1_core0_access_count), .perf_l1_core0_hit_count(perf_l1_core0_hit_count),
        .perf_l1_core0_miss_count(perf_l1_core0_miss_count), .perf_l1_core1_access_count(perf_l1_core1_access_count),
        .perf_l1_core1_hit_count(perf_l1_core1_hit_count), .perf_l1_core1_miss_count(perf_l1_core1_miss_count),
        .perf_l2_access_count(perf_l2_access_count), .perf_l2_hit_count(perf_l2_hit_count), .perf_l2_miss_count(perf_l2_miss_count),
        .perf_l3_access_count(perf_l3_access_count), .perf_l3_hit_count(perf_l3_hit_count), .perf_l3_miss_count(perf_l3_miss_count),
        .perf_l3_stream0_access_count(perf_l3_stream0_access_count), .perf_l3_stream0_hit_count(perf_l3_stream0_hit_count),
        .perf_l3_stream0_miss_count(perf_l3_stream0_miss_count), .perf_l3_stream1_access_count(perf_l3_stream1_access_count),
        .perf_l3_stream1_hit_count(perf_l3_stream1_hit_count), .perf_l3_stream1_miss_count(perf_l3_stream1_miss_count),
        .perf_l3_stream0_alloc_lines(perf_l3_stream0_alloc_lines), .perf_l3_stream1_alloc_lines(perf_l3_stream1_alloc_lines),
        .perf_l3_ucp_repartition_count(perf_l3_ucp_repartition_count), .perf_l3_ucp_interval_count(perf_l3_ucp_interval_count),
        .perf_backing_access_count(perf_backing_access_count)
    );

    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    task expect_reg(input logic tid, input [4:0] idx, input [31:0] expected);
        begin
            checks = checks + 1;
            if (dut.u_regfile.regs[tid][idx] !== expected) begin
                $display("FAIL: %0s t%0d x%0d expected 0x%08x got 0x%08x", bench_name, tid, idx, expected, dut.u_regfile.regs[tid][idx]);
                errors = errors + 1;
            end
        end
    endtask

    task expect_eq(input [1023:0] name, input [31:0] got, input [31:0] expected);
        begin
            checks = checks + 1;
            if (got !== expected) begin
                $display("FAIL: %0s %0s expected %0d got %0d", bench_name, name, expected, got);
                errors = errors + 1;
            end
        end
    endtask

    task expect_ge(input [1023:0] name, input [31:0] got, input [31:0] minimum);
        begin
            checks = checks + 1;
            if (got < minimum) begin
                $display("FAIL: %0s %0s expected >= %0d got %0d", bench_name, name, minimum, got);
                errors = errors + 1;
            end
        end
    endtask

    task preload_memory;
        begin
            for (i = 0; i < 256; i = i + 1) dut.u_dmem.mem[i] = 32'h00000100 + i;
            dut.u_dmem.mem[0] = 32'h0000000a;
            dut.u_dmem.mem[1] = 32'h00000014;
            dut.u_dmem.mem[2] = 32'h0000001e;
            dut.u_dmem.mem[3] = 32'h00000028;
            dut.u_dmem.mem[8] = 32'h00000080;
            dut.u_dmem.mem[9] = 32'h00000084;
            dut.u_dmem.mem[10] = 32'h00000088;
            dut.u_dmem.mem[11] = 32'h0000008c;
        end
    endtask

    task check_common;
        begin
            expect_reg(1'b0, 5'd0, 32'h00000000);
            expect_reg(1'b1, 5'd0, 32'h00000000);
            expect_eq("retired_sum", perf_retired_count, perf_thread0_retired_count + perf_thread1_retired_count);
            expect_ge("thread0_fetched", perf_thread0_fetched_count, 32'd1);
            expect_ge("thread1_fetched", perf_thread1_fetched_count, 32'd1);
            expect_eq("l1_core0_consistency", perf_l1_core0_access_count, perf_l1_core0_hit_count + perf_l1_core0_miss_count);
            expect_eq("l1_core1_consistency", perf_l1_core1_access_count, perf_l1_core1_hit_count + perf_l1_core1_miss_count);
            expect_eq("l2_consistency", perf_l2_access_count, perf_l2_hit_count + perf_l2_miss_count);
            expect_eq("l3_consistency", perf_l3_access_count, perf_l3_hit_count + perf_l3_miss_count);
            expect_eq("l3_stream0_consistency", perf_l3_stream0_access_count, perf_l3_stream0_hit_count + perf_l3_stream0_miss_count);
            expect_eq("l3_stream1_consistency", perf_l3_stream1_access_count, perf_l3_stream1_hit_count + perf_l3_stream1_miss_count);
            if (L3_ENABLE && L3_UCP_ENABLE) begin
                expect_eq("l3_alloc_sum", perf_l3_stream0_alloc_lines + perf_l3_stream1_alloc_lines, L3_LINES);
                expect_ge("l3_alloc0_min", perf_l3_stream0_alloc_lines, 32'd1);
                expect_ge("l3_alloc1_min", perf_l3_stream1_alloc_lines, 32'd1);
            end
        end
    endtask

    task check_bench;
        begin
            check_common();
            case (bench_id)
                1: begin
                    expect_reg(1'b0, 5'd1, 32'd5); expect_reg(1'b0, 5'd2, 32'd7); expect_reg(1'b0, 5'd3, 32'd12); expect_reg(1'b0, 5'd4, 32'd10);
                    expect_reg(1'b1, 5'd1, 32'd100); expect_reg(1'b1, 5'd2, 32'd1); expect_reg(1'b1, 5'd3, 32'd99); expect_reg(1'b1, 5'd4, 32'd20);
                    expect_eq("cross_thread_x1_diff", dut.u_regfile.regs[0][1], 32'd5);
                end
                2: begin
                    expect_reg(1'b0, 5'd2, 32'd10); expect_reg(1'b0, 5'd3, 32'd20); expect_reg(1'b0, 5'd4, 32'd20);
                    expect_reg(1'b1, 5'd2, 32'd20); expect_reg(1'b1, 5'd3, 32'd25); expect_reg(1'b1, 5'd4, 32'd25);
                    expect_eq("store_t0_mem2", dut.u_dmem.mem[2], 32'd20);
                    expect_eq("store_t1_mem3", dut.u_dmem.mem[3], 32'd25);
                    expect_ge("raw_stalls_seen", perf_thread0_stall_count + perf_thread1_stall_count, 32'd2);
                    expect_ge("loads_seen", perf_thread0_load_count + perf_thread1_load_count, 32'd4);
                    expect_ge("stores_seen", perf_thread0_store_count + perf_thread1_store_count, 32'd2);
                end
                3: begin
                    expect_reg(1'b0, 5'd1, 32'd1); expect_reg(1'b0, 5'd2, 32'd1); expect_reg(1'b0, 5'd5, 32'd55); expect_reg(1'b0, 5'd6, 32'd66);
                    expect_reg(1'b1, 5'd7, 32'd8); expect_reg(1'b1, 5'd5, 32'd77); expect_reg(1'b1, 5'd6, 32'd88);
                    expect_ge("flushes_seen", perf_thread0_flush_count + perf_thread1_flush_count, 32'd1);
                    expect_ge("thread0_pc_advanced", pc0_dbg, 32'd20);
                end
                4: begin
                    expect_reg(1'b0, 5'd2, 32'd10); expect_reg(1'b0, 5'd13, 32'd30);
                    expect_reg(1'b1, 5'd2, 32'd128); expect_reg(1'b1, 5'd13, 32'h00000113);
                    expect_ge("thread0_l1_accesses", perf_l1_core0_access_count, 32'd2);
                    expect_ge("thread1_l1_accesses", perf_l1_core1_access_count, 32'd8);
                    expect_ge("l3_stream0_accesses", perf_l3_stream0_access_count, 32'd2);
                    expect_ge("l3_stream1_accesses", perf_l3_stream1_access_count, 32'd2);
                    if (L3_UCP_POLICY == 2) begin
                        expect_eq("dynamic_ucp_alloc_sum", perf_l3_stream0_alloc_lines + perf_l3_stream1_alloc_lines, L3_LINES);
                    end
                end
                5: begin
                    expect_reg(1'b0, 5'd2, 32'd10); expect_reg(1'b0, 5'd9, 32'd40);
                    expect_reg(1'b1, 5'd2, 32'd128); expect_reg(1'b1, 5'd9, 32'd140);
                    expect_ge("balanced_l3_accesses", perf_l3_access_count, 32'd4);
                end
                default: begin
                    $display("FAIL: unknown SMT bench id %0d", bench_id);
                    errors = errors + 1;
                end
            endcase
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && trace_fd != 0) begin
            $fdisplay(trace_fd, "CYCLE=%0d IF valid=%0d tid=%0d pc=%08x instr=%08x ID valid=%0d tid=%0d pc=%08x EX valid=%0d tid=%0d pc=%08x MEM valid=%0d tid=%0d pc=%08x WB valid=%0d tid=%0d rd=x%0d we=%0d wdata=%08x stall=%0d raw=%0d mem=%0d flush=%0d redir_tid=%0d target=%08x",
                      perf_cycle_count, trace_if_valid, trace_if_tid, trace_if_pc, trace_if_instr,
                      trace_id_valid, trace_id_tid, trace_id_pc, trace_ex_valid, trace_ex_tid, trace_ex_pc,
                      trace_mem_valid, trace_mem_tid, trace_mem_pc, trace_wb_valid, trace_wb_tid,
                      trace_wb_rd, trace_wb_we, trace_wb_wdata, trace_stall, trace_raw_stall,
                      trace_mem_stall, trace_flush, trace_redirect_tid, trace_redirect_target);
        end
        if (rst_n && ucp_fd != 0 && (trace_dcache_access || trace_dcache_stall || trace_dcache_fill || trace_l2_access || trace_l3_access || trace_backing_access)) begin
            $fdisplay(ucp_fd, "SMTUCP cycle=%0d bench=%0s policy=%0d stream_source=%0d tid=%0d stream=%0d addr=%08x L1 hit=%0d miss=%0d L2 hit=%0d miss=%0d L3 hit=%0d miss=%0d backing=%0d alloc0=%0d alloc1=%0d repartitions=%0d",
                      perf_cycle_count, bench_name, L3_UCP_POLICY, STREAM_ID_MODE, trace_mem_tid,
                      trace_ucp_stream_id, trace_dcache_addr, trace_dcache_hit, trace_dcache_miss,
                      trace_l2_hit, trace_l2_miss, trace_l3_hit, trace_l3_miss, trace_backing_access,
                      perf_l3_stream0_alloc_lines, perf_l3_stream1_alloc_lines, perf_l3_ucp_repartition_count);
        end
    end

    initial begin
        if (!$value$plusargs("BENCH=%s", bench_name)) bench_name = "context_basic";
        if (!$value$plusargs("BENCH_ID=%d", bench_id)) bench_id = 1;
        if (!$value$plusargs("HEX0=%s", hex0)) hex0 = "tests/benchmarks/smt/context_basic_t0.hex";
        if (!$value$plusargs("HEX1=%s", hex1)) hex1 = "tests/benchmarks/smt/context_basic_t1.hex";
        if (!$value$plusargs("EXP_RET0=%d", exp_ret0)) exp_ret0 = 5;
        if (!$value$plusargs("EXP_RET1=%d", exp_ret1)) exp_ret1 = 4;
        trace_fd = $fopen("reports/sim/smt_trace.log", "a");
        ucp_fd = $fopen("reports/sim/smt_ucp_trace.log", "a");
        $dumpfile("sim/phase15_smt.vcd");
        $dumpvars(0, tb_rv32i_smt_pipeline_core);
        $readmemh(hex0, dut.u_imem0.mem);
        $readmemh(hex1, dut.u_imem1.mem);
        preload_memory();
        errors = 0;
        checks = 0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        timeout_cycles = 0;
        while (((perf_thread0_retired_count < exp_ret0) || (perf_thread1_retired_count < exp_ret1)) && (timeout_cycles < 5000)) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
        end
        repeat (12) @(posedge clk);
        #1;
        if (timeout_cycles >= 5000) begin
            $display("FAIL: %0s timed out ret0=%0d/%0d ret1=%0d/%0d", bench_name, perf_thread0_retired_count, exp_ret0, perf_thread1_retired_count, exp_ret1);
            errors = errors + 1;
        end
        if (illegal_instr_dbg) begin
            $display("FAIL: %0s illegal instruction detected", bench_name);
            errors = errors + 1;
        end
        check_bench();
        $display("PERF: test=%0s mode=smt stream_id_mode=%0d ucp_mode=%0d thread_id=0 pass_fail=%0s cycles=%0d retired=%0d fetched=%0d stalls=%0d flushes=%0d loads=%0d stores=%0d l1_hits=%0d l1_misses=%0d l2_hits=%0d l2_misses=%0d l3_hits=%0d l3_misses=%0d shadow_hits=NA cpi_estimate=NA",
                 bench_name, STREAM_ID_MODE, L3_UCP_POLICY, (errors == 0) ? "PASS" : "FAIL", perf_cycle_count,
                 perf_thread0_retired_count, perf_thread0_fetched_count, perf_thread0_stall_count,
                 perf_thread0_flush_count, perf_thread0_load_count, perf_thread0_store_count,
                 perf_l1_core0_hit_count, perf_l1_core0_miss_count, perf_l2_hit_count, perf_l2_miss_count,
                 perf_l3_stream0_hit_count, perf_l3_stream0_miss_count);
        $display("PERF: test=%0s mode=smt stream_id_mode=%0d ucp_mode=%0d thread_id=1 pass_fail=%0s cycles=%0d retired=%0d fetched=%0d stalls=%0d flushes=%0d loads=%0d stores=%0d l1_hits=%0d l1_misses=%0d l2_hits=%0d l2_misses=%0d l3_hits=%0d l3_misses=%0d shadow_hits=NA cpi_estimate=NA",
                 bench_name, STREAM_ID_MODE, L3_UCP_POLICY, (errors == 0) ? "PASS" : "FAIL", perf_cycle_count,
                 perf_thread1_retired_count, perf_thread1_fetched_count, perf_thread1_stall_count,
                 perf_thread1_flush_count, perf_thread1_load_count, perf_thread1_store_count,
                 perf_l1_core1_hit_count, perf_l1_core1_miss_count, perf_l2_hit_count, perf_l2_miss_count,
                 perf_l3_stream1_hit_count, perf_l3_stream1_miss_count);
        $display("SMTUCP: test=%0s stream_id_mode=%0d ucp_mode=%0d alloc0=%0d alloc1=%0d repartitions=%0d l3_s0_accesses=%0d l3_s0_hits=%0d l3_s0_misses=%0d l3_s1_accesses=%0d l3_s1_hits=%0d l3_s1_misses=%0d backing=%0d checks=%0d pass_fail=%0s",
                 bench_name, STREAM_ID_MODE, L3_UCP_POLICY, perf_l3_stream0_alloc_lines, perf_l3_stream1_alloc_lines,
                 perf_l3_ucp_repartition_count, perf_l3_stream0_access_count, perf_l3_stream0_hit_count,
                 perf_l3_stream0_miss_count, perf_l3_stream1_access_count, perf_l3_stream1_hit_count,
                 perf_l3_stream1_miss_count, perf_backing_access_count, checks, (errors == 0) ? "PASS" : "FAIL");
        $display("SMT_TESTS: bench=%0s checks=%0d errors=%0d", bench_name, checks, errors);
        if (trace_fd != 0) $fclose(trace_fd);
        if (ucp_fd != 0) $fclose(ucp_fd);
        if (errors == 0) begin
            $display("PASS: %0s", bench_name);
            $finish;
        end else begin
            $display("FAIL: %0s errors=%0d", bench_name, errors);
            $fatal;
        end
    end
endmodule
