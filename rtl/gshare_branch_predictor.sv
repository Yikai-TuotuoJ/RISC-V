`timescale 1ns/1ps

module gshare_branch_predictor #(
    parameter INDEX_BITS = 4,
    parameter ENTRIES = 16,
    parameter GHR_WIDTH = 4
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [31:0]             fetch_pc,
    output logic                    predict_taken,
    output logic [GHR_WIDTH-1:0]    fetch_ghr,
    output logic [INDEX_BITS-1:0]   fetch_index,
    input  logic                    update_en,
    input  logic [31:0]             update_pc,
    input  logic                    actual_taken
);
    localparam COUNTER_STRONGLY_NOT_TAKEN = 2'b00;
    localparam COUNTER_WEAKLY_NOT_TAKEN   = 2'b01;
    localparam COUNTER_STRONGLY_TAKEN     = 2'b11;

    logic [1:0] pht [0:ENTRIES-1];
    logic [GHR_WIDTH-1:0] ghr;
    logic [INDEX_BITS-1:0] pc_fetch_index;
    logic [INDEX_BITS-1:0] pc_update_index;
    logic [INDEX_BITS-1:0] update_index;
    integer i;

    assign pc_fetch_index = fetch_pc[INDEX_BITS+1:2];
    assign pc_update_index = update_pc[INDEX_BITS+1:2];
    assign fetch_index = pc_fetch_index ^ ghr[INDEX_BITS-1:0];
    assign update_index = pc_update_index ^ ghr[INDEX_BITS-1:0];
    assign predict_taken = pht[fetch_index][1];
    assign fetch_ghr = ghr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghr <= {GHR_WIDTH{1'b0}};
            for (i = 0; i < ENTRIES; i = i + 1) begin
                pht[i] <= COUNTER_WEAKLY_NOT_TAKEN;
            end
        end else if (update_en) begin
            if (actual_taken) begin
                if (pht[update_index] != COUNTER_STRONGLY_TAKEN) begin
                    pht[update_index] <= pht[update_index] + 2'b01;
                end
            end else begin
                if (pht[update_index] != COUNTER_STRONGLY_NOT_TAKEN) begin
                    pht[update_index] <= pht[update_index] - 2'b01;
                end
            end

            ghr <= {ghr[GHR_WIDTH-2:0], actual_taken};
        end
    end
endmodule

