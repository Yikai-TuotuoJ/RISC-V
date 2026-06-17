`timescale 1ns/1ps

module tb_rv32i_pipeline_perf;
    parameter BP_MODE = 2;

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

    logic [1023:0] bench_name;
    logic [1023:0] hex_file;
    logic [1023:0] mode_name;
    integer bench_id;
    integer end_pc;
    integer errors;
    integer cycles;
    integer retired;
    integer stalls;
    integer load_use_stalls;
    integer flushes;
    integer branch_jump_flushes;
    integer branches;
    integer branch_taken;
    integer branch_not_taken;
    integer branch_correct;
    integer branch_mispredict;
    integer loads;
    integer stores;
    integer accuracy_x100;
    real cpi;

    rv32i_pipeline_core #(
        .IMEM_HEX("tests/benchmarks/alu_chain.hex"),
        .BP_MODE(BP_MODE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg),
        .trace_if_valid(trace_if_valid),
        .trace_if_pc(trace_if_pc),
        .trace_if_instr(trace_if_instr),
        .trace_id_valid(trace_id_valid),
        .trace_id_pc(trace_id_pc),
        .trace_id_instr(trace_id_instr),
        .trace_ex_valid(trace_ex_valid),
        .trace_ex_pc(trace_ex_pc),
        .trace_ex_instr(trace_ex_instr),
        .trace_mem_valid(trace_mem_valid),
        .trace_mem_pc(trace_mem_pc),
        .trace_mem_instr(trace_mem_instr),
        .trace_wb_valid(trace_wb_valid),
        .trace_wb_pc(trace_wb_pc),
        .trace_wb_instr(trace_wb_instr),
        .trace_wb_rd(trace_wb_rd),
        .trace_wb_wdata(trace_wb_wdata),
        .trace_wb_we(trace_wb_we),
        .trace_stall(trace_stall),
        .trace_flush(trace_flush),
        .trace_redirect(trace_redirect),
        .trace_redirect_target(trace_redirect_target),
        .trace_bp_pred_taken(trace_bp_pred_taken),
        .trace_bp_pred_target(trace_bp_pred_target),
        .trace_bp_actual_taken(trace_bp_actual_taken),
        .trace_bp_actual_target(trace_bp_actual_target),
        .trace_bp_mispredict(trace_bp_mispredict),
        .trace_bp_mode(trace_bp_mode),
        .trace_bp_ghr(trace_bp_ghr),
        .trace_bp_index(trace_bp_index),
        .bp_total_branches(bp_total_branches),
        .bp_pred_taken_count(bp_pred_taken_count),
        .bp_pred_not_taken_count(bp_pred_not_taken_count),
        .bp_actual_taken_count(bp_actual_taken_count),
        .bp_actual_not_taken_count(bp_actual_not_taken_count),
        .bp_correct_count(bp_correct_count),
        .bp_mispredict_count(bp_mispredict_count),
        .perf_cycle_count(perf_cycle_count),
        .perf_retired_count(perf_retired_count),
        .perf_stall_count(perf_stall_count),
        .perf_load_use_stall_count(perf_load_use_stall_count),
        .perf_flush_count(perf_flush_count),
        .perf_branch_jump_flush_count(perf_branch_jump_flush_count),
        .perf_load_count(perf_load_count),
        .perf_store_count(perf_store_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function is_branch;
        input [31:0] instr;
        begin
            is_branch = (instr[6:0] == 7'b1100011);
        end
    endfunction

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
                0: begin
                    expect_reg(5'd1, 32'h0000000b);
                end
                1: begin
                    expect_reg(5'd1, 32'h00000040);
                    expect_reg(5'd2, 32'h0000002a);
                    expect_reg(5'd3, 32'h0000002a);
                    expect_mem(8'd16, 32'h0000002a);
                end
                2: begin
                    expect_reg(5'd1, 32'h00000005);
                    expect_reg(5'd2, 32'h00000005);
                    expect_reg(5'd3, 32'h0000007b);
                end
                3: begin
                    expect_reg(5'd1, 32'h00000020);
                    expect_reg(5'd2, 32'h00000007);
                    expect_reg(5'd3, 32'h00000007);
                    expect_reg(5'd5, 32'h0000000e);
                    expect_reg(5'd6, 32'h00000000);
                    expect_reg(5'd7, 32'h00000000);
                    expect_reg(5'd8, 32'h00000008);
                    expect_mem(8'd8, 32'h00000007);
                end
                default: begin
                    $display("FAIL: unknown benchmark id %0d", bench_id);
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
            load_use_stalls <= 0;
            flushes <= 0;
            branch_jump_flushes <= 0;
            branches <= 0;
            branch_taken <= 0;
            branch_not_taken <= 0;
            branch_correct <= 0;
            branch_mispredict <= 0;
            loads <= 0;
            stores <= 0;
        end else begin
            cycles <= cycles + 1;
            if (trace_stall) stalls <= stalls + 1;
            if (trace_stall) load_use_stalls <= load_use_stalls + 1;
            if (trace_flush) flushes <= flushes + 1;
            if (trace_redirect) branch_jump_flushes <= branch_jump_flushes + 1;
            if (trace_ex_valid && (trace_ex_pc < end_pc) && is_branch(trace_ex_instr)) begin
                branches <= branches + 1;
                if (trace_bp_actual_taken) branch_taken <= branch_taken + 1;
                else branch_not_taken <= branch_not_taken + 1;
                if (trace_bp_mispredict) branch_mispredict <= branch_mispredict + 1;
                else branch_correct <= branch_correct + 1;
            end
            if (trace_wb_valid && (trace_wb_pc < end_pc)) begin
                retired <= retired + 1;
                if (is_load(trace_wb_instr)) loads <= loads + 1;
                if (is_store(trace_wb_instr)) stores <= stores + 1;
            end
        end
    end

    initial begin
        if (!$value$plusargs("BENCH=%s", bench_name)) bench_name = "unknown";
        if (!$value$plusargs("HEX=%s", hex_file)) hex_file = "tests/benchmarks/alu_chain.hex";
        if (!$value$plusargs("BENCH_ID=%d", bench_id)) bench_id = 0;
        if (!$value$plusargs("END_PC=%d", end_pc)) end_pc = 196;

        if (BP_MODE == 0) mode_name = "none";
        else if (BP_MODE == 1) mode_name = "simple";
        else if (BP_MODE == 2) mode_name = "gshare";
        else mode_name = "unknown";

        $dumpfile("sim/phase9_benchmark.vcd");
        $dumpvars(0, tb_rv32i_pipeline_perf);
        $readmemh(hex_file, dut.u_imem.mem);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        wait (trace_wb_valid && (trace_wb_pc == (end_pc - 4)));
        repeat (2) @(posedge clk);
        #1;

        if (illegal_instr_dbg) begin
            $display("FAIL: %0s illegal instruction observed pc=0x%08x instr=0x%08x", bench_name, pc_dbg, instr_dbg);
            errors = errors + 1;
        end

        check_expected();

        cpi = (retired == 0) ? 0.0 : (cycles * 1.0 / retired);
        accuracy_x100 = (branches == 0) ? 0 : ((branch_correct * 10000) / branches);

        if (errors == 0) begin
            $display("PASS: benchmark=%0s mode=%0s", bench_name, mode_name);
            $display("PERF: benchmark=%0s mode=%0s pass=PASS cycles=%0d retired=%0d cpi=%0.3f stalls=%0d load_use_stalls=%0d flushes=%0d branch_jump_flushes=%0d branches=%0d branch_taken=%0d branch_not_taken=%0d branch_correct=%0d mispredicts=%0d accuracy=%0d.%02d loads=%0d stores=%0d core_cycles=%0d core_retired=%0d",
                     bench_name, mode_name, cycles, retired, cpi, stalls, load_use_stalls,
                     flushes, branch_jump_flushes, branches, branch_taken, branch_not_taken,
                     branch_correct, branch_mispredict, accuracy_x100 / 100, accuracy_x100 % 100,
                     loads, stores, perf_cycle_count, perf_retired_count);
        end else begin
            $display("FAIL: benchmark=%0s mode=%0s errors=%0d", bench_name, mode_name, errors);
        end
        $finish;
    end
endmodule

