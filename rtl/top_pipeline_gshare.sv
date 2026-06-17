`timescale 1ns/1ps

module top_pipeline_gshare (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_dbg,
    output logic [31:0] instr_dbg,
    output logic        illegal_instr_dbg,
    output logic        trace_flush,
    output logic        trace_redirect,
    output logic [31:0] trace_redirect_target,
    output logic [3:0]  trace_bp_ghr,
    output logic [3:0]  trace_bp_index,
    output logic [31:0] bp_total_branches,
    output logic [31:0] bp_correct_count,
    output logic [31:0] bp_mispredict_count
);
    rv32i_pipeline_core #(
        .IMEM_HEX("tests/phase7_gshare_branch_heavy.hex"),
        .BP_MODE(2)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg),
        .trace_flush(trace_flush),
        .trace_redirect(trace_redirect),
        .trace_redirect_target(trace_redirect_target),
        .trace_bp_ghr(trace_bp_ghr),
        .trace_bp_index(trace_bp_index),
        .bp_total_branches(bp_total_branches),
        .bp_correct_count(bp_correct_count),
        .bp_mispredict_count(bp_mispredict_count)
    );
endmodule

