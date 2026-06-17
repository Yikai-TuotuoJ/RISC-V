`timescale 1ns/1ps

module threaded_regfile #(
    parameter NUM_THREADS = 2
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        we,
    input  logic        rtid,
    input  logic        wtid,
    input  logic [4:0]  raddr1,
    input  logic [4:0]  raddr2,
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] regs [0:NUM_THREADS-1][0:31];
    integer t;
    integer i;

    assign rdata1 = (raddr1 == 5'd0) ? 32'h00000000 : regs[rtid][raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'h00000000 : regs[rtid][raddr2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (t = 0; t < NUM_THREADS; t = t + 1) begin
                for (i = 0; i < 32; i = i + 1) begin
                    regs[t][i] <= 32'h00000000;
                end
            end
        end else begin
            for (t = 0; t < NUM_THREADS; t = t + 1) begin
                regs[t][0] <= 32'h00000000;
            end
            if (we && (waddr != 5'd0)) begin
                regs[wtid][waddr] <= wdata;
            end
        end
    end
endmodule
