`timescale 1ns/1ps

module regfile(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,
    input  logic [4:0]  raddr1,
    input  logic [4:0]  raddr2,
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] regs [0:31];
    integer i;

    assign rdata1 = (raddr1 == 5'd0) ? 32'h00000000 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'h00000000 : regs[raddr2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else begin
            if (we && (waddr != 5'd0)) begin
                regs[waddr] <= wdata;
            end
            regs[0] <= 32'h00000000;
        end
    end
endmodule

