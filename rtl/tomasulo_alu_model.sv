`timescale 1ns/1ps

module tomasulo_alu_model (
    input  logic [3:0]  op,
    input  logic [31:0] src1,
    input  logic [31:0] src2,
    output logic [31:0] result,
    output logic        supported
);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;

    always_comb begin
        supported = 1'b1;
        case (op)
            OP_ADD,
            OP_ADDI: result = src1 + src2;
            OP_SUB:  result = src1 - src2;
            OP_AND:  result = src1 & src2;
            OP_OR:   result = src1 | src2;
            OP_XOR:  result = src1 ^ src2;
            default: begin
                result = 32'd0;
                supported = 1'b0;
            end
        endcase
    end
endmodule
