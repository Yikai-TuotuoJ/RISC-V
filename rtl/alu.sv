`timescale 1ns/1ps

module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_op,
    output logic  [31:0] y
);
    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_AND = 3'd2;
    localparam ALU_OR  = 3'd3;
    localparam ALU_XOR = 3'd4;

    always_comb begin
        case (alu_op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_AND: y = a & b;
            ALU_OR:  y = a | b;
            ALU_XOR: y = a ^ b;
            default: y = 32'h00000000;
        endcase
    end
endmodule

