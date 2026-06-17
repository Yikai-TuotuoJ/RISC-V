`timescale 1ns/1ps

module imem #(
    parameter MEM_WORDS = 256,
    parameter HEX_FILE = "tests/phase1_basic.hex"
)(
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:MEM_WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = 32'h00000013;
        end
        $readmemh(HEX_FILE, mem);
    end

    assign instr = mem[addr[9:2]];
endmodule

