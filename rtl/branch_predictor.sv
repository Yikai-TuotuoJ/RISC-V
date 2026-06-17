`timescale 1ns/1ps

module branch_predictor #(
    parameter INDEX_BITS = 4,
    parameter ENTRIES = 16
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] fetch_pc,
    output logic        predict_taken,
    input  logic        update_en,
    input  logic [31:0] update_pc,
    input  logic        actual_taken
);
    logic [ENTRIES-1:0] pred_table;
    logic [INDEX_BITS-1:0] fetch_index;
    logic [INDEX_BITS-1:0] update_index;
    integer i;

    assign fetch_index = fetch_pc[INDEX_BITS+1:2];
    assign update_index = update_pc[INDEX_BITS+1:2];
    assign predict_taken = pred_table[fetch_index];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                pred_table[i] <= 1'b0;
            end
        end else if (update_en) begin
            pred_table[update_index] <= actual_taken;
        end
    end
endmodule

