`timescale 1ns/1ps

module tb_rv32i_pipeline_core_phase7_gshare;
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
    logic [31:0] simple_pc_dbg;
    logic [31:0] simple_instr_dbg;
    logic simple_illegal_instr_dbg;
    logic [31:0] simple_bp_total_branches;
    logic [31:0] simple_bp_pred_taken_count;
    logic [31:0] simple_bp_pred_not_taken_count;
    logic [31:0] simple_bp_actual_taken_count;
    logic [31:0] simple_bp_actual_not_taken_count;
    logic [31:0] simple_bp_correct_count;
    logic [31:0] simple_bp_mispredict_count;

    integer errors;
    integer report_fd;
    integer trace_fd;
    integer cycle;
    integer accuracy;
    integer simple_accuracy;
    integer correct_delta;
    integer mispredict_delta;

    rv32i_pipeline_core #(
        .IMEM_HEX("tests/phase7_gshare_branch_heavy.hex"),
        .BP_MODE(2)
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
        .bp_mispredict_count(bp_mispredict_count)
    );

    rv32i_pipeline_core #(
        .IMEM_HEX("tests/phase7_gshare_branch_heavy.hex"),
        .BP_MODE(1)
    ) simple_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(simple_pc_dbg),
        .instr_dbg(simple_instr_dbg),
        .illegal_instr_dbg(simple_illegal_instr_dbg),
        .bp_total_branches(simple_bp_total_branches),
        .bp_pred_taken_count(simple_bp_pred_taken_count),
        .bp_pred_not_taken_count(simple_bp_pred_not_taken_count),
        .bp_actual_taken_count(simple_bp_actual_taken_count),
        .bp_actual_not_taken_count(simple_bp_actual_not_taken_count),
        .bp_correct_count(simple_bp_correct_count),
        .bp_mispredict_count(simple_bp_mispredict_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle <= 0;
        end else begin
            $fwrite(trace_fd, "CYCLE=%0d\n", cycle);
            $fwrite(trace_fd, "IF:  valid=%0d pc=%08x instr=%08x\n", trace_if_valid, trace_if_pc, trace_if_instr);
            $fwrite(trace_fd, "ID:  valid=%0d pc=%08x instr=%08x\n", trace_id_valid, trace_id_pc, trace_id_instr);
            $fwrite(trace_fd, "EX:  valid=%0d pc=%08x instr=%08x\n", trace_ex_valid, trace_ex_pc, trace_ex_instr);
            $fwrite(trace_fd, "MEM: valid=%0d pc=%08x instr=%08x\n", trace_mem_valid, trace_mem_pc, trace_mem_instr);
            $fwrite(trace_fd, "WB:  valid=%0d pc=%08x instr=%08x rd=x%0d we=%0d wdata=%08x\n", trace_wb_valid, trace_wb_pc, trace_wb_instr, trace_wb_rd, trace_wb_we, trace_wb_wdata);
            $fwrite(trace_fd, "CTRL: stall=%0d flush=%0d taken=%0d target=%08x\n", trace_stall, trace_flush, trace_redirect, trace_redirect_target);
            $fwrite(trace_fd, "BP: mode=GSHARE pc=%08x ghr=%0d index=%0d pred_taken=%0d pred_target=%08x actual_taken=%0d actual_target=%08x mispredict=%0d\n\n",
                    trace_ex_pc, trace_bp_ghr, trace_bp_index, trace_bp_pred_taken, trace_bp_pred_target, trace_bp_actual_taken, trace_bp_actual_target, trace_bp_mispredict);
            cycle <= cycle + 1;
        end
    end

    task expect_reg;
        input [4:0] idx;
        input [31:0] expected;
        begin
            if (dut.u_regfile.regs[idx] !== expected) begin
                $display("FAIL: x%0d expected 0x%08x got 0x%08x", idx, expected, dut.u_regfile.regs[idx]);
                errors = errors + 1;
            end else begin
                $display("PASS: x%0d = 0x%08x", idx, expected);
            end
        end
    endtask

    task expect_nonzero;
        input [255:0] name;
        input [31:0] value;
        begin
            if (value == 0) begin
                $display("FAIL: %0s was zero", name);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s = %0d", name, value);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/phase7_gshare.vcd");
        $dumpvars(0, tb_rv32i_pipeline_core_phase7_gshare);
        report_fd = $fopen("reports/sim/gshare_branch_prediction_report.log", "w");
        trace_fd = $fopen("reports/sim/gshare_branch_prediction_trace.log", "w");

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (180) @(posedge clk);
        #1;

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end
        if (simple_illegal_instr_dbg) begin
            $display("FAIL: simple predictor comparison core saw illegal instruction at pc=0x%08x instr=0x%08x", simple_pc_dbg, simple_instr_dbg);
            errors = errors + 1;
        end

        expect_reg(5'd0, 32'h00000000);
        expect_reg(5'd1, 32'h00000008);
        expect_reg(5'd2, 32'h00000008);
        expect_reg(5'd3, 32'h0000007b);
        expect_reg(5'd4, 32'h00000001);
        expect_reg(5'd7, 32'h00000000);
        expect_reg(5'd8, 32'h00000000);
        expect_reg(5'd9, 32'h00000009);
        expect_reg(5'd10, 32'h0000000a);
        expect_reg(5'd11, 32'h00000000);
        expect_reg(5'd12, 32'h00000000);
        expect_reg(5'd13, 32'h0000000d);

        if (bp_total_branches !== 32'd11) begin
            $display("FAIL: expected 11 resolved branches, got %0d", bp_total_branches);
            errors = errors + 1;
        end else begin
            $display("PASS: resolved branches = %0d", bp_total_branches);
        end

        expect_nonzero("pred_taken_count", bp_pred_taken_count);
        expect_nonzero("pred_not_taken_count", bp_pred_not_taken_count);
        expect_nonzero("actual_taken_count", bp_actual_taken_count);
        expect_nonzero("actual_not_taken_count", bp_actual_not_taken_count);
        expect_nonzero("correct_count", bp_correct_count);
        expect_nonzero("mispredict_count", bp_mispredict_count);

        if (dut.u_gshare_branch_predictor.ghr == 4'b0000) begin
            $display("FAIL: GHR did not update from reset value");
            errors = errors + 1;
        end else begin
            $display("PASS: GHR updated to 0x%0x", dut.u_gshare_branch_predictor.ghr);
        end

        accuracy = (bp_total_branches == 0) ? 0 : ((bp_correct_count * 100) / bp_total_branches);
        simple_accuracy = (simple_bp_total_branches == 0) ? 0 : ((simple_bp_correct_count * 100) / simple_bp_total_branches);
        correct_delta = bp_correct_count - simple_bp_correct_count;
        mispredict_delta = bp_mispredict_count - simple_bp_mispredict_count;
        $display("Gshare branch prediction accuracy: %0d%% (%0d/%0d)", accuracy, bp_correct_count, bp_total_branches);
        $display("Simple predictor comparison accuracy: %0d%% (%0d/%0d)", simple_accuracy, simple_bp_correct_count, simple_bp_total_branches);

        $fwrite(report_fd, "Phase 7 Gshare Branch Prediction Report\n");
        $fwrite(report_fd, "Predictor: gshare\n");
        $fwrite(report_fd, "PHT entries: 16\n");
        $fwrite(report_fd, "GHR width: 4\n");
        $fwrite(report_fd, "Counter type: 2-bit saturating\n");
        $fwrite(report_fd, "Initial counter state: weakly not taken\n");
        $fwrite(report_fd, "Index: branch_pc[5:2] XOR GHR\n");
        $fwrite(report_fd, "total_conditional_branches=%0d\n", bp_total_branches);
        $fwrite(report_fd, "predicted_taken=%0d\n", bp_pred_taken_count);
        $fwrite(report_fd, "predicted_not_taken=%0d\n", bp_pred_not_taken_count);
        $fwrite(report_fd, "actual_taken=%0d\n", bp_actual_taken_count);
        $fwrite(report_fd, "actual_not_taken=%0d\n", bp_actual_not_taken_count);
        $fwrite(report_fd, "correct_predictions=%0d\n", bp_correct_count);
        $fwrite(report_fd, "mispredictions=%0d\n", bp_mispredict_count);
        $fwrite(report_fd, "accuracy_percent=%0d\n", accuracy);
        $fwrite(report_fd, "simple_predictor_same_program_accuracy_percent=%0d\n", simple_accuracy);
        $fwrite(report_fd, "simple_predictor_same_program_correct_predictions=%0d\n", simple_bp_correct_count);
        $fwrite(report_fd, "simple_predictor_same_program_mispredictions=%0d\n", simple_bp_mispredict_count);
        $fwrite(report_fd, "gshare_minus_simple_correct_predictions=%0d\n", correct_delta);
        $fwrite(report_fd, "gshare_minus_simple_mispredictions=%0d\n", mispredict_delta);

        if (errors == 0) begin
            $display("PASS: Phase 7 gshare directed test passed");
        end else begin
            $display("FAIL: Phase 7 gshare directed test failed with %0d error(s)", errors);
        end

        $fclose(report_fd);
        $fclose(trace_fd);
        $finish;
    end
endmodule

