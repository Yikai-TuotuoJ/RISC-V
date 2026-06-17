`timescale 1ns/1ps

module tb_rv32i_pipeline_ucp_cache;
    parameter BP_MODE = 2;
    parameter DMEM_LATENCY_CYCLES = 1;
    parameter DCACHE_ENABLE = 1;
    parameter DCACHE_LINES = 2;
    parameter DCACHE_MISS_PENALTY_CYCLES = 3;
    parameter L2_ENABLE = 1;
    parameter L2_LINES = 2;
    parameter L2_HIT_LATENCY = 2;
    parameter L2_MISS_PENALTY = 6;
    parameter PRIVATE_L1_ENABLE = 1;
    parameter L1_NUM_CORES = 2;
    parameter L3_ENABLE = 1;
    parameter L3_LINES = 8;
    parameter L3_UCP_ENABLE = 1;
    parameter L3_UCP_POLICY = 0;
    parameter UCP_REPARTITION_INTERVAL = 8;
    parameter STREAM_SPLIT_ADDR = 32'h00000080;
    parameter L3_HIT_LATENCY = 4;
    parameter L3_MISS_PENALTY = 12;

    logic clk;
    logic rst_n;
    logic [31:0] pc_dbg, instr_dbg;
    logic illegal_instr_dbg;
    logic trace_if_valid, trace_id_valid, trace_ex_valid, trace_mem_valid, trace_wb_valid;
    logic [31:0] trace_if_pc, trace_if_instr, trace_id_pc, trace_id_instr, trace_ex_pc, trace_ex_instr;
    logic [31:0] trace_mem_pc, trace_mem_instr, trace_wb_pc, trace_wb_instr, trace_wb_wdata;
    logic [4:0] trace_wb_rd;
    logic trace_wb_we, trace_stall, trace_flush, trace_redirect;
    logic [31:0] trace_redirect_target;
    logic trace_bp_pred_taken, trace_bp_actual_taken, trace_bp_mispredict;
    logic [31:0] trace_bp_pred_target, trace_bp_actual_target;
    logic [1:0] trace_bp_mode;
    logic [3:0] trace_bp_ghr, trace_bp_index;
    logic [31:0] bp_total_branches, bp_pred_taken_count, bp_pred_not_taken_count;
    logic [31:0] bp_actual_taken_count, bp_actual_not_taken_count, bp_correct_count, bp_mispredict_count;
    logic [31:0] perf_cycle_count, perf_retired_count, perf_stall_count, perf_load_use_stall_count;
    logic [31:0] perf_flush_count, perf_branch_jump_flush_count, perf_load_count, perf_store_count;
    logic [31:0] perf_mem_stall_count, perf_load_stall_count, perf_store_stall_count;
    logic trace_dcache_access, trace_dcache_load, trace_dcache_store, trace_dcache_hit, trace_dcache_miss;
    logic trace_dcache_stall, trace_dcache_fill, trace_l2_access, trace_l2_hit, trace_l2_miss, trace_backing_access;
    logic trace_l3_access, trace_l3_hit, trace_l3_miss, trace_ucp_stream_id;
    logic [1:0] trace_cache_hit_level;
    logic [31:0] trace_dcache_addr;
    logic [31:0] perf_dcache_access_count, perf_dcache_load_access_count, perf_dcache_store_access_count;
    logic [31:0] perf_dcache_hit_count, perf_dcache_miss_count, perf_dcache_miss_stall_count;
    logic [31:0] perf_l1_core0_access_count, perf_l1_core0_hit_count, perf_l1_core0_miss_count;
    logic [31:0] perf_l1_core1_access_count, perf_l1_core1_hit_count, perf_l1_core1_miss_count;
    logic [31:0] perf_l2_access_count, perf_l2_hit_count, perf_l2_miss_count, perf_backing_access_count;
    logic [31:0] perf_l3_access_count, perf_l3_hit_count, perf_l3_miss_count;
    logic [31:0] perf_l3_stream0_access_count, perf_l3_stream0_hit_count, perf_l3_stream0_miss_count;
    logic [31:0] perf_l3_stream1_access_count, perf_l3_stream1_hit_count, perf_l3_stream1_miss_count;
    logic [31:0] perf_l3_stream0_alloc_lines, perf_l3_stream1_alloc_lines;
    logic [31:0] perf_l3_ucp_repartition_count, perf_l3_ucp_interval_count;

    logic [1023:0] bench_name;
    logic [1023:0] hex_file;
    integer bench_id, end_pc, errors, cycles, retired, stalls, loads, stores, timeout_cycles, trace_fd, i;
    real cpi, l1_hit_rate, l2_hit_rate, l3_hit_rate, s0_l3_hit_rate, s1_l3_hit_rate;

    rv32i_pipeline_core #(
        .IMEM_HEX("tests/benchmarks/ucp_rtl/shared_l2_reuse.hex"),
        .BP_MODE(BP_MODE), .DMEM_LATENCY_CYCLES(DMEM_LATENCY_CYCLES),
        .DCACHE_ENABLE(DCACHE_ENABLE), .DCACHE_LINES(DCACHE_LINES),
        .DCACHE_MISS_PENALTY_CYCLES(DCACHE_MISS_PENALTY_CYCLES),
        .L2_ENABLE(L2_ENABLE), .L2_LINES(L2_LINES), .L2_HIT_LATENCY(L2_HIT_LATENCY),
        .L2_MISS_PENALTY(L2_MISS_PENALTY), .PRIVATE_L1_ENABLE(PRIVATE_L1_ENABLE),
        .L1_NUM_CORES(L1_NUM_CORES), .L3_ENABLE(L3_ENABLE), .L3_LINES(L3_LINES),
        .L3_UCP_ENABLE(L3_UCP_ENABLE), .L3_UCP_POLICY(L3_UCP_POLICY),
        .UCP_REPARTITION_INTERVAL(UCP_REPARTITION_INTERVAL),
        .STREAM_SPLIT_ADDR(STREAM_SPLIT_ADDR), .L3_HIT_LATENCY(L3_HIT_LATENCY),
        .L3_MISS_PENALTY(L3_MISS_PENALTY)
    ) dut (
        .clk(clk), .rst_n(rst_n), .pc_dbg(pc_dbg), .instr_dbg(instr_dbg), .illegal_instr_dbg(illegal_instr_dbg),
        .trace_if_valid(trace_if_valid), .trace_if_pc(trace_if_pc), .trace_if_instr(trace_if_instr),
        .trace_id_valid(trace_id_valid), .trace_id_pc(trace_id_pc), .trace_id_instr(trace_id_instr),
        .trace_ex_valid(trace_ex_valid), .trace_ex_pc(trace_ex_pc), .trace_ex_instr(trace_ex_instr),
        .trace_mem_valid(trace_mem_valid), .trace_mem_pc(trace_mem_pc), .trace_mem_instr(trace_mem_instr),
        .trace_wb_valid(trace_wb_valid), .trace_wb_pc(trace_wb_pc), .trace_wb_instr(trace_wb_instr),
        .trace_wb_rd(trace_wb_rd), .trace_wb_wdata(trace_wb_wdata), .trace_wb_we(trace_wb_we),
        .trace_stall(trace_stall), .trace_flush(trace_flush), .trace_redirect(trace_redirect), .trace_redirect_target(trace_redirect_target),
        .trace_bp_pred_taken(trace_bp_pred_taken), .trace_bp_pred_target(trace_bp_pred_target),
        .trace_bp_actual_taken(trace_bp_actual_taken), .trace_bp_actual_target(trace_bp_actual_target),
        .trace_bp_mispredict(trace_bp_mispredict), .trace_bp_mode(trace_bp_mode), .trace_bp_ghr(trace_bp_ghr), .trace_bp_index(trace_bp_index),
        .bp_total_branches(bp_total_branches), .bp_pred_taken_count(bp_pred_taken_count), .bp_pred_not_taken_count(bp_pred_not_taken_count),
        .bp_actual_taken_count(bp_actual_taken_count), .bp_actual_not_taken_count(bp_actual_not_taken_count),
        .bp_correct_count(bp_correct_count), .bp_mispredict_count(bp_mispredict_count),
        .perf_cycle_count(perf_cycle_count), .perf_retired_count(perf_retired_count), .perf_stall_count(perf_stall_count),
        .perf_load_use_stall_count(perf_load_use_stall_count), .perf_flush_count(perf_flush_count),
        .perf_branch_jump_flush_count(perf_branch_jump_flush_count), .perf_load_count(perf_load_count), .perf_store_count(perf_store_count),
        .perf_mem_stall_count(perf_mem_stall_count), .perf_load_stall_count(perf_load_stall_count), .perf_store_stall_count(perf_store_stall_count),
        .trace_dcache_access(trace_dcache_access), .trace_dcache_load(trace_dcache_load), .trace_dcache_store(trace_dcache_store),
        .trace_dcache_hit(trace_dcache_hit), .trace_dcache_miss(trace_dcache_miss), .trace_dcache_stall(trace_dcache_stall),
        .trace_dcache_fill(trace_dcache_fill), .trace_dcache_addr(trace_dcache_addr),
        .perf_dcache_access_count(perf_dcache_access_count), .perf_dcache_load_access_count(perf_dcache_load_access_count),
        .perf_dcache_store_access_count(perf_dcache_store_access_count), .perf_dcache_hit_count(perf_dcache_hit_count),
        .perf_dcache_miss_count(perf_dcache_miss_count), .perf_dcache_miss_stall_count(perf_dcache_miss_stall_count),
        .trace_l2_access(trace_l2_access), .trace_l2_hit(trace_l2_hit), .trace_l2_miss(trace_l2_miss), .trace_backing_access(trace_backing_access),
        .perf_l2_access_count(perf_l2_access_count), .perf_l2_hit_count(perf_l2_hit_count),
        .perf_l2_miss_count(perf_l2_miss_count), .perf_backing_access_count(perf_backing_access_count),
        .trace_l3_access(trace_l3_access), .trace_l3_hit(trace_l3_hit), .trace_l3_miss(trace_l3_miss),
        .trace_ucp_stream_id(trace_ucp_stream_id), .trace_cache_hit_level(trace_cache_hit_level),
        .perf_l1_core0_access_count(perf_l1_core0_access_count), .perf_l1_core0_hit_count(perf_l1_core0_hit_count),
        .perf_l1_core0_miss_count(perf_l1_core0_miss_count), .perf_l1_core1_access_count(perf_l1_core1_access_count),
        .perf_l1_core1_hit_count(perf_l1_core1_hit_count), .perf_l1_core1_miss_count(perf_l1_core1_miss_count),
        .perf_l3_access_count(perf_l3_access_count), .perf_l3_hit_count(perf_l3_hit_count), .perf_l3_miss_count(perf_l3_miss_count),
        .perf_l3_stream0_access_count(perf_l3_stream0_access_count), .perf_l3_stream0_hit_count(perf_l3_stream0_hit_count),
        .perf_l3_stream0_miss_count(perf_l3_stream0_miss_count), .perf_l3_stream1_access_count(perf_l3_stream1_access_count),
        .perf_l3_stream1_hit_count(perf_l3_stream1_hit_count), .perf_l3_stream1_miss_count(perf_l3_stream1_miss_count),
        .perf_l3_stream0_alloc_lines(perf_l3_stream0_alloc_lines), .perf_l3_stream1_alloc_lines(perf_l3_stream1_alloc_lines),
        .perf_l3_ucp_repartition_count(perf_l3_ucp_repartition_count), .perf_l3_ucp_interval_count(perf_l3_ucp_interval_count)
    );

    initial begin clk = 1'b0; forever #5 clk = ~clk; end
    function is_load(input [31:0] instr); begin is_load = (instr[6:0] == 7'b0000011); end endfunction
    function is_store(input [31:0] instr); begin is_store = (instr[6:0] == 7'b0100011); end endfunction

    task expect_reg(input [4:0] idx, input [31:0] expected);
        begin if (dut.u_regfile.regs[idx] !== expected) begin $display("FAIL: %0s x%0d expected 0x%08x got 0x%08x", bench_name, idx, expected, dut.u_regfile.regs[idx]); errors = errors + 1; end end
    endtask
    task expect_ge(input [1023:0] name, input [31:0] value, input [31:0] minimum);
        begin if (value < minimum) begin $display("FAIL: %0s %0s expected >= %0d got %0d", bench_name, name, minimum, value); errors = errors + 1; end end
    endtask
    task expect_eq(input [1023:0] name, input [31:0] value, input [31:0] expected);
        begin if (value !== expected) begin $display("FAIL: %0s %0s expected %0d got %0d", bench_name, name, expected, value); errors = errors + 1; end end
    endtask

    task preload_memory;
        begin
            for (i = 0; i < 256; i = i + 1) dut.u_dmem.mem[i] = 32'h00000000;
            dut.u_dmem.mem[0] = 32'h00000011;
            dut.u_dmem.mem[2] = 32'h00000022;
            dut.u_dmem.mem[4] = 32'h00000033;
            dut.u_dmem.mem[32] = 32'h00000080;
            dut.u_dmem.mem[33] = 32'h00000084;
            dut.u_dmem.mem[34] = 32'h00000088;
            dut.u_dmem.mem[35] = 32'h0000008c;
            dut.u_dmem.mem[36] = 32'h00000090;
        end
    endtask

    task check_registers;
        begin
            expect_reg(5'd0, 32'h00000000);
            case (bench_id)
                50: begin expect_reg(5'd3, 32'h11); expect_reg(5'd4, 32'h22); expect_reg(5'd5, 32'h11); expect_reg(5'd6, 32'h80); expect_reg(5'd7, 32'h88); expect_reg(5'd8, 32'h80); end
                51: begin expect_reg(5'd3, 32'h11); expect_reg(5'd4, 32'h22); expect_reg(5'd5, 32'h11); expect_reg(5'd6, 32'h80); expect_reg(5'd7, 32'h88); expect_reg(5'd8, 32'h80); expect_reg(5'd9, 32'h33); expect_reg(5'd10, 32'h11); end
                52: begin expect_reg(5'd3, 32'h11); expect_reg(5'd4, 32'h22); expect_reg(5'd5, 32'h33); expect_reg(5'd6, 32'h11); expect_reg(5'd7, 32'h22); expect_reg(5'd8, 32'h33); expect_reg(5'd9, 32'h80); expect_reg(5'd10, 32'h84); expect_reg(5'd11, 32'h88); expect_reg(5'd12, 32'h80); expect_reg(5'd13, 32'h11); expect_reg(5'd14, 32'h22); expect_reg(5'd15, 32'h33); end
                53: begin expect_reg(5'd3, 32'h11); expect_reg(5'd4, 32'h22); expect_reg(5'd5, 32'h33); expect_reg(5'd16, 32'h80); expect_reg(5'd17, 32'h84); expect_reg(5'd18, 32'h88); expect_reg(5'd19, 32'h8c); expect_reg(5'd20, 32'h90); end
                default: begin $display("FAIL: unknown UCP RTL benchmark id %0d", bench_id); errors = errors + 1; end
            endcase
        end
    endtask

    task check_counters;
        begin
            expect_eq("l1_core0_access_consistency", perf_l1_core0_access_count, perf_l1_core0_hit_count + perf_l1_core0_miss_count);
            expect_eq("l1_core1_access_consistency", perf_l1_core1_access_count, perf_l1_core1_hit_count + perf_l1_core1_miss_count);
            expect_eq("l3_total_access_consistency", perf_l3_access_count, perf_l3_hit_count + perf_l3_miss_count);
            expect_eq("l3_stream0_access_consistency", perf_l3_stream0_access_count, perf_l3_stream0_hit_count + perf_l3_stream0_miss_count);
            expect_eq("l3_stream1_access_consistency", perf_l3_stream1_access_count, perf_l3_stream1_hit_count + perf_l3_stream1_miss_count);
            expect_eq("l3_stream_sum", perf_l3_access_count, perf_l3_stream0_access_count + perf_l3_stream1_access_count);
            if (L3_ENABLE && L3_UCP_ENABLE && (L3_UCP_POLICY == 0)) begin
                expect_eq("stream0_alloc_equal", perf_l3_stream0_alloc_lines, 32'd4);
                expect_eq("stream1_alloc_equal", perf_l3_stream1_alloc_lines, 32'd4);
            end else if (L3_ENABLE && L3_UCP_ENABLE && (L3_UCP_POLICY == 1)) begin
                expect_eq("stream0_alloc_utility", perf_l3_stream0_alloc_lines, 32'd6);
                expect_eq("stream1_alloc_utility", perf_l3_stream1_alloc_lines, 32'd2);
            end else if (L3_ENABLE && L3_UCP_ENABLE) begin
                expect_eq("dynamic_alloc_sum", perf_l3_stream0_alloc_lines + perf_l3_stream1_alloc_lines, L3_LINES);
                expect_ge("dynamic_stream0_min_alloc", perf_l3_stream0_alloc_lines, 32'd1);
                expect_ge("dynamic_stream1_min_alloc", perf_l3_stream1_alloc_lines, 32'd1);

            end else if (L3_ENABLE) begin
                expect_eq("l3_unpartitioned_alloc_sum", perf_l3_stream0_alloc_lines + perf_l3_stream1_alloc_lines, L3_LINES);
            end
            case (bench_id)
                50: begin
                    expect_ge("l2_hits", perf_l2_hit_count, 32'd2);
                    if (L3_ENABLE) expect_ge("l3_accesses", perf_l3_access_count, 32'd4);
                    else expect_ge("backing_accesses_without_l3", perf_backing_access_count, 32'd4);
                end
                51: begin
                    if (L3_ENABLE) begin
                        expect_ge("l3_hits", perf_l3_hit_count, 32'd2);
                        expect_ge("stream0_l3_accesses", perf_l3_stream0_access_count, 32'd4);
                        expect_ge("stream1_l3_accesses", perf_l3_stream1_access_count, 32'd3);
                    end else begin
                        expect_ge("backing_accesses_without_l3", perf_backing_access_count, 32'd6);
                    end
                end
                52: begin
                    if (!L3_ENABLE) begin
                        expect_ge("backing_accesses_without_l3", perf_backing_access_count, 32'd8);
                    end else if (L3_UCP_ENABLE && (L3_UCP_POLICY == 1)) begin
                        expect_ge("utility_stream0_l3_hits", perf_l3_stream0_hit_count, 32'd5);
                    end else if (L3_UCP_ENABLE && (L3_UCP_POLICY == 2)) begin
                        if ((perf_l3_stream0_alloc_lines == 32'd4) && (perf_l3_stream1_alloc_lines == 32'd4)) begin $display("FAIL: %0s dynamic allocation did not move from equal split", bench_name); errors = errors + 1; end
                        expect_ge("dynamic_l3_accesses", perf_l3_access_count, 32'd8);
                        expect_ge("dynamic_repartitions", perf_l3_ucp_repartition_count, 32'd1);
                    end else begin
                        expect_ge("equal_l3_accesses", perf_l3_access_count, 32'd8);
                    end
                end
                53: begin
                    if (L3_ENABLE) expect_ge("long_l3_accesses", perf_l3_access_count, 32'd24);
                    else expect_ge("long_backing_without_l3", perf_backing_access_count, 32'd24);
                    if (L3_UCP_ENABLE && (L3_UCP_POLICY == 2)) begin
                        expect_ge("long_dynamic_repartitions", perf_l3_ucp_repartition_count, 32'd1);
                        expect_ge("long_dynamic_stream1_alloc", perf_l3_stream1_alloc_lines, 32'd5);
                        expect_ge("long_dynamic_stream1_hits", perf_l3_stream1_hit_count, 32'd8);
                    end
                end
                default: begin end
            endcase
        end
    endtask
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin cycles <= 0; retired <= 0; stalls <= 0; loads <= 0; stores <= 0; end
        else begin
            cycles <= cycles + 1;
            if (trace_stall) stalls <= stalls + 1;
            if (trace_wb_valid && (trace_wb_pc < end_pc)) begin
                retired <= retired + 1;
                if (is_load(trace_wb_instr)) loads <= loads + 1;
                if (is_store(trace_wb_instr)) stores <= stores + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && trace_fd != 0 && (trace_dcache_access || trace_dcache_stall || trace_dcache_fill || trace_l2_access || trace_l3_access || trace_backing_access)) begin
            $fdisplay(trace_fd, "UCPRTL cycle=%0d bench=%0s policy=%0d stream=%0d addr=%08x L1 access=%0d hit=%0d miss=%0d L2 access=%0d hit=%0d miss=%0d L3 access=%0d hit=%0d miss=%0d backing=%0d stall=%0d fill=%0d level=%0d alloc0=%0d alloc1=%0d",
                      cycles, bench_name, L3_UCP_POLICY, trace_ucp_stream_id, trace_dcache_addr,
                      trace_dcache_access, trace_dcache_hit, trace_dcache_miss, trace_l2_access, trace_l2_hit, trace_l2_miss,
                      trace_l3_access, trace_l3_hit, trace_l3_miss, trace_backing_access, trace_dcache_stall, trace_dcache_fill, trace_cache_hit_level, perf_l3_stream0_alloc_lines, perf_l3_stream1_alloc_lines);
        end
    end

    initial begin
        if (!$value$plusargs("BENCH=%s", bench_name)) bench_name = "unknown";
        if (!$value$plusargs("HEX=%s", hex_file)) hex_file = "tests/benchmarks/ucp_rtl/shared_l2_reuse.hex";
        if (!$value$plusargs("BENCH_ID=%d", bench_id)) bench_id = 50;
        if (!$value$plusargs("END_PC=%d", end_pc)) end_pc = 48;
        trace_fd = $fopen("reports/sim/ucp_rtl_trace.log", "a");
        if (trace_fd != 0) $fdisplay(trace_fd, "== bench=%0s policy=%0d split=%08x l1_lines=%0d l2_lines=%0d l3_lines=%0d interval=%0d ==", bench_name, L3_UCP_POLICY, STREAM_SPLIT_ADDR, DCACHE_LINES, L2_LINES, L3_LINES, UCP_REPARTITION_INTERVAL);
        $dumpfile("sim/phase13_5_ucp_cache.vcd");
        $dumpvars(0, tb_rv32i_pipeline_ucp_cache);
        $readmemh(hex_file, dut.u_imem.mem);
        preload_memory();
        errors = 0; rst_n = 1'b0; repeat (2) @(posedge clk); rst_n = 1'b1;
        timeout_cycles = 0;
        while (!(trace_wb_valid && (trace_wb_pc == (end_pc - 4))) && (timeout_cycles < 2500)) begin @(posedge clk); timeout_cycles = timeout_cycles + 1; end
        if (timeout_cycles >= 2500) begin $display("FAIL: %0s timed out", bench_name); errors = errors + 1; end
        repeat (4) @(posedge clk); #1;
        if (illegal_instr_dbg) begin $display("FAIL: %0s illegal instruction pc=0x%08x instr=0x%08x", bench_name, pc_dbg, instr_dbg); errors = errors + 1; end
        check_registers();
        check_counters();
        cpi = (retired == 0) ? 0.0 : (cycles * 1.0 / retired);
        l1_hit_rate = (perf_dcache_access_count == 0) ? 0.0 : (perf_dcache_hit_count * 100.0 / perf_dcache_access_count);
        l2_hit_rate = (perf_l2_access_count == 0) ? 0.0 : (perf_l2_hit_count * 100.0 / perf_l2_access_count);
        l3_hit_rate = (perf_l3_access_count == 0) ? 0.0 : (perf_l3_hit_count * 100.0 / perf_l3_access_count);
        s0_l3_hit_rate = (perf_l3_stream0_access_count == 0) ? 0.0 : (perf_l3_stream0_hit_count * 100.0 / perf_l3_stream0_access_count);
        s1_l3_hit_rate = (perf_l3_stream1_access_count == 0) ? 0.0 : (perf_l3_stream1_hit_count * 100.0 / perf_l3_stream1_access_count);
        if (errors == 0) begin
            $display("PASS: ucp_rtl_benchmark=%0s policy=%0d", bench_name, L3_UCP_POLICY);
            $display("UCPRTL: benchmark=%0s policy=%0d pass=PASS cycles=%0d retired=%0d cpi=%0.3f stalls=%0d loads=%0d stores=%0d l1_accesses=%0d l1_hits=%0d l1_misses=%0d l1_hit_rate=%0.2f l1_core0_accesses=%0d l1_core0_hits=%0d l1_core0_misses=%0d l1_core1_accesses=%0d l1_core1_hits=%0d l1_core1_misses=%0d l2_accesses=%0d l2_hits=%0d l2_misses=%0d l2_hit_rate=%0.2f l3_accesses=%0d l3_hits=%0d l3_misses=%0d l3_hit_rate=%0.2f l3_stream0_alloc=%0d l3_stream0_accesses=%0d l3_stream0_hits=%0d l3_stream0_misses=%0d l3_stream0_hit_rate=%0.2f l3_stream1_alloc=%0d l3_stream1_accesses=%0d l3_stream1_hits=%0d l3_stream1_misses=%0d l3_stream1_hit_rate=%0.2f backing_mem_accesses=%0d dynamic_repartitions=%0d dynamic_interval_count=%0d",
                     bench_name, L3_UCP_POLICY, cycles, retired, cpi, stalls, loads, stores,
                     perf_dcache_access_count, perf_dcache_hit_count, perf_dcache_miss_count, l1_hit_rate,
                     perf_l1_core0_access_count, perf_l1_core0_hit_count, perf_l1_core0_miss_count,
                     perf_l1_core1_access_count, perf_l1_core1_hit_count, perf_l1_core1_miss_count,
                     perf_l2_access_count, perf_l2_hit_count, perf_l2_miss_count, l2_hit_rate,
                     perf_l3_access_count, perf_l3_hit_count, perf_l3_miss_count, l3_hit_rate,
                     perf_l3_stream0_alloc_lines, perf_l3_stream0_access_count, perf_l3_stream0_hit_count, perf_l3_stream0_miss_count, s0_l3_hit_rate,
                     perf_l3_stream1_alloc_lines, perf_l3_stream1_access_count, perf_l3_stream1_hit_count, perf_l3_stream1_miss_count, s1_l3_hit_rate,
                     perf_backing_access_count, perf_l3_ucp_repartition_count, perf_l3_ucp_interval_count);
        end else begin
            $display("FAIL: ucp_rtl_benchmark=%0s policy=%0d errors=%0d", bench_name, L3_UCP_POLICY, errors);
        end
        if (trace_fd != 0) $fclose(trace_fd);
        $finish;
    end
endmodule




