`timescale 1ns/1ps

module top_pipeline (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_dbg,
    output logic [31:0] instr_dbg,
    output logic        illegal_instr_dbg,
    output logic        trace_flush,
    output logic        trace_redirect,
    output logic [31:0] trace_redirect_target
);
    rv32i_pipeline_core #(
        .IMEM_HEX("tests/phase4_pipeline_basic.hex"),
        .BP_MODE(0)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg),
        .trace_flush(trace_flush),
        .trace_redirect(trace_redirect),
        .trace_redirect_target(trace_redirect_target)
    );
endmodule

