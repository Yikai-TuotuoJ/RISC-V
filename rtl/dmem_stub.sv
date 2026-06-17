`timescale 1ns/1ps

module dmem_stub #(
    parameter MEM_WORDS = 256
)(
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem [0:MEM_WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
    end

    assign rdata = mem[addr[9:2]];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr[9:2]] <= wdata;
        end
    end
endmodule

