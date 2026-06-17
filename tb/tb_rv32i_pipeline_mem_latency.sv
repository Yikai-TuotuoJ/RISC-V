`timescale 1ns/1ps

module tb_rv32i_pipeline_mem_latency;
    parameter BP_MODE = 2;
    parameter DMEM_LATENCY_CYCLES = 3;

    logic clk;
    logic rst_n;
    logic [31:0] pc_dbg;
    logic [31:0] instr_dbg;
    logic illegal_instr_dbg;
    logic trace_if_valid;
    logic [31:0] trace_if_pc;
    logic [31:0] trace_if_instr;
    logic trace_id_valid;
    logic [31:0] trace_id_pc;
    logic [31:0] trace_id_instr;
    logic trace_ex_valid;
    logic [31:0] trace_ex_pc;
    logic [31:0] trace_ex_instr;
    logic trace_mem_valid;
    logic [31:0] trace_mem_pc;
    logic [31:0] trace_mem_instr;
    logic trace_wb_valid;
    logic [31:0] trace_wb_pc;
    logic [31:0] trace_wb_instr;
    logic [4:0] trace_wb_rd;
    logic [31:0] trace_wb_wdata;
    logic trace_wb_we;
    logic trace_stall;
    logic trace_flush;
    logic trace_redirect;
    logic [31:0] trace_redirect_target;
    logic trace_bp_pred_taken;
    logic [31:0] trace_bp_pred_target;
    logic trace_bp_actual_taken;
    logic [31:0] trace_bp_actual_target;
    logic trace_bp_mispredict;
    logic [1:0] trace_bp_mode;
    logic [3:0] trace_bp_ghr;
    logic [3:0] trace_bp_index;
    logic [31:0] bp_total_branches;
    logic [31:0] bp_pred_taken_count;
    logic [31:0] bp_pred_not_taken_count;
    logic [31:0] bp_actual_taken_count;
    logic [31:0] bp_actual_not_taken_count;
    logic [31:0] bp_correct_count;
    logic [31:0] bp_mispredict_count;
    logic [31:0] perf_cycle_count;
    logic [31:0] perf_retired_count;
    logic [31:0] perf_stall_count;
    logic [31:0] perf_load_use_stall_count;
    logic [31:0] perf_flush_count;
    logic [31:0] perf_branch_jump_flush_count;
    logic [31:0] perf_load_count;
    logic [31:0] perf_store_count;
    logic [31:0] perf_mem_stall_count;
    logic [31:0] perf_load_stall_count;
    logic [31:0] perf_store_stall_count;

    logic [1023:0] bench_name;
    logic [1023:0] hex_file;
    integer bench_id;
    integer end_pc;
    integer errors;
    integer cycles;
    integer retired;
    integer stalls;
    integer flushes;
    integer loads;
    integer stores;
    integer timeout_cycles;
    real cpi;

    rv32i_pipeline_core #(
        .IMEM_HEX("tests/benchmarks/mem_load_chain.hex"),
        .BP_MODE(BP_MODE),
        .DMEM_LATENCY_CYCLES(DMEM_LATENCY_CYCLES)
    ) dut (
        .clk(clk), .rst_n(rst_n), .pc_dbg(pc_dbg), .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg), .trace_if_valid(trace_if_valid),
        .trace_if_pc(trace_if_pc), .trace_if_instr(trace_if_instr),
        .trace_id_valid(trace_id_valid), .trace_id_pc(trace_id_pc), .trace_id_instr(trace_id_instr),
        .trace_ex_valid(trace_ex_valid), .trace_ex_pc(trace_ex_pc), .trace_ex_instr(trace_ex_instr),
        .trace_mem_valid(trace_mem_valid), .trace_mem_pc(trace_mem_pc), .trace_mem_instr(trace_mem_instr),
        .trace_wb_valid(trace_wb_valid), .trace_wb_pc(trace_wb_pc), .trace_wb_instr(trace_wb_instr),
        .trace_wb_rd(trace_wb_rd), .trace_wb_wdata(trace_wb_wdata), .trace_wb_we(trace_wb_we),
        .trace_stall(trace_stall), .trace_flush(trace_flush), .trace_redirect(trace_redirect),
        .trace_redirect_target(trace_redirect_target), .trace_bp_pred_taken(trace_bp_pred_taken),
        .trace_bp_pred_target(trace_bp_pred_target), .trace_bp_actual_taken(trace_bp_actual_taken),
        .trace_bp_actual_target(trace_bp_actual_target), .trace_bp_mispredict(trace_bp_mispredict),
        .trace_bp_mode(trace_bp_mode), .trace_bp_ghr(trace_bp_ghr), .trace_bp_index(trace_bp_index),
        .bp_total_branches(bp_total_branches), .bp_pred_taken_count(bp_pred_taken_count),
        .bp_pred_not_taken_count(bp_pred_not_taken_count), .bp_actual_taken_count(bp_actual_taken_count),
        .bp_actual_not_taken_count(bp_actual_not_taken_count), .bp_correct_count(bp_correct_count),
        .bp_mispredict_count(bp_mispredict_count), .perf_cycle_count(perf_cycle_count),
        .perf_retired_count(perf_retired_count), .perf_stall_count(perf_stall_count),
        .perf_load_use_stall_count(perf_load_use_stall_count), .perf_flush_count(perf_flush_count),
        .perf_branch_jump_flush_count(perf_branch_jump_flush_count), .perf_load_count(perf_load_count),
        .perf_store_count(perf_store_count), .perf_mem_stall_count(perf_mem_stall_count),
        .perf_load_stall_count(perf_load_stall_count), .perf_store_stall_count(perf_store_stall_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function is_load;
        input [31:0] instr;
        begin
            is_load = (instr[6:0] == 7'b0000011);
        end
    endfunction

    function is_store;
        input [31:0] instr;
        begin
            is_store = (instr[6:0] == 7'b0100011);
        end
    endfunction

    task expect_reg;
        input [4:0] idx;
        input [31:0] expected;
        begin
            if (dut.u_regfile.regs[idx] !== expected) begin
                $display("FAIL: %0s x%0d expected 0x%08x got 0x%08x", bench_name, idx, expected, dut.u_regfile.regs[idx]);
                errors = errors + 1;
            end
        end
    endtask

    task expect_mem;
        input [7:0] idx;
        input [31:0] expected;
        begin
            if (dut.u_dmem.mem[idx] !== expected) begin
                $display("FAIL: %0s mem[%0d] expected 0x%08x got 0x%08x", bench_name, idx, expected, dut.u_dmem.mem[idx]);
                errors = errors + 1;
            end
        end
    endtask

    task check_expected;
        begin
            expect_reg(5'd0, 32'h00000000);
            case (bench_id)
                10: begin
                    expect_reg(5'd1, 32'h00000040);
                    expect_reg(5'd2, 32'h0000000b);
                    expect_reg(5'd3, 32'h0000000b);
                    expect_reg(5'd4, 32'h0000000c);
                    expect_reg(5'd5, 32'h00000017);
                    expect_mem(8'd16, 32'h0000000b);
                end
                11: begin
                    expect_reg(5'd1, 32'h00000050);
                    expect_reg(5'd4, 32'h00000015);
                    expect_reg(5'd5, 32'h00000016);
                    expect_reg(5'd6, 32'h0000002b);
                    expect_mem(8'd20, 32'h00000015);
                    expect_mem(8'd21, 32'h00000016);
                end
                12: begin
                    expect_reg(5'd1, 32'h00000060);
                    expect_reg(5'd3, 32'h00000005);
                    expect_reg(5'd4, 32'h0000000f);
                    expect_reg(5'd5, 32'h0000000f);
                    expect_reg(5'd6, 32'h00000000);
                    expect_reg(5'd7, 32'h00000007);
                    expect_mem(8'd24, 32'h00000005);
                    expect_mem(8'd25, 32'h0000000f);
                end
                default: begin
                    $display("FAIL: unknown memory benchmark id %0d", bench_id);
                    errors = errors + 1;
                end
            endcase
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycles <= 0;
            retired <= 0;
            stalls <= 0;
            flushes <= 0;
            loads <= 0;
            stores <= 0;
        end else begin
            cycles <= cycles + 1;
            if (trace_stall) stalls <= stalls + 1;
            if (trace_flush) flushes <= flushes + 1;
            if (trace_wb_valid && (trace_wb_pc < end_pc)) begin
                retired <= retired + 1;
                if (is_load(trace_wb_instr)) loads <= loads + 1;
                if (is_store(trace_wb_instr)) stores <= stores + 1;
            end
        end
    end

    initial begin
        if (!$value$plusargs("BENCH=%s", bench_name)) bench_name = "unknown";
        if (!$value$plusargs("HEX=%s", hex_file)) hex_file = "tests/benchmarks/mem_load_chain.hex";
        if (!$value$plusargs("BENCH_ID=%d", bench_id)) bench_id = 10;
        if (!$value$plusargs("END_PC=%d", end_pc)) end_pc = 56;

        $dumpfile("sim/phase10_memory_latency.vcd");
        $dumpvars(0, tb_rv32i_pipeline_mem_latency);
        $readmemh(hex_file, dut.u_imem.mem);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        timeout_cycles = 0;
        while (!(trace_wb_valid && (trace_wb_pc == (end_pc - 4))) && (timeout_cycles < 500)) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
        end
        if (timeout_cycles >= 500) begin
            $display("FAIL: %0s timed out", bench_name);
            errors = errors + 1;
        end

        repeat (2) @(posedge clk);
        #1;

        if (illegal_instr_dbg) begin
            $display("FAIL: %0s illegal instruction observed pc=0x%08x instr=0x%08x", bench_name, pc_dbg, instr_dbg);
            errors = errors + 1;
        end

        check_expected();
        cpi = (retired == 0) ? 0.0 : (cycles * 1.0 / retired);

        if (errors == 0) begin
            $display("PASS: memory_benchmark=%0s latency=%0d", bench_name, DMEM_LATENCY_CYCLES);
            $display("MEMPERF: benchmark=%0s mem_latency=%0d cache_mode=none pass=PASS cycles=%0d retired=%0d cpi=%0.3f stalls=%0d memory_stalls=%0d load_use_stalls=%0d load_stalls=%0d store_stalls=%0d flushes=%0d loads=%0d stores=%0d core_cycles=%0d core_retired=%0d",
                     bench_name, DMEM_LATENCY_CYCLES, cycles, retired, cpi, stalls,
                     perf_mem_stall_count, perf_load_use_stall_count, perf_load_stall_count,
                     perf_store_stall_count, flushes, loads, stores, perf_cycle_count, perf_retired_count);
        end else begin
            $display("FAIL: memory_benchmark=%0s latency=%0d errors=%0d", bench_name, DMEM_LATENCY_CYCLES, errors);
        end
        $finish;
    end
endmodule



