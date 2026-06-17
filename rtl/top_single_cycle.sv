`timescale 1ns/1ps

module top_single_cycle (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_dbg,
    output logic [31:0] instr_dbg,
    output logic        illegal_instr_dbg
);
    rv32i_core #(
        .IMEM_HEX("tests/phase3_jump_upper.hex")
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg)
    );
endmodule

