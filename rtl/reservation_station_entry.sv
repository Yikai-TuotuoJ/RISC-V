`timescale 1ns/1ps

module reservation_station_entry #(
    parameter TAG_WIDTH = 8
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 allocate,
    input  logic                 release_valid,
    input  logic                 alloc_tid,
    input  logic [3:0]           alloc_op,
    input  logic [4:0]           alloc_rd,
    input  logic [4:0]           alloc_rs1,
    input  logic [4:0]           alloc_rs2,
    input  logic                 alloc_src1_ready,
    input  logic                 alloc_src2_ready,
    input  logic [TAG_WIDTH-1:0] alloc_src1_tag,
    input  logic [TAG_WIDTH-1:0] alloc_src2_tag,
    input  logic [TAG_WIDTH-1:0] alloc_dst_tag,
    input  logic                 broadcast_valid,
    input  logic                 broadcast_tid,
    input  logic [TAG_WIDTH-1:0] broadcast_tag,
    output logic                 valid,
    output logic                 tid,
    output logic [3:0]           op,
    output logic [4:0]           rd,
    output logic [4:0]           rs1,
    output logic [4:0]           rs2,
    output logic                 src1_ready,
    output logic                 src2_ready,
    output logic [TAG_WIDTH-1:0] src1_tag,
    output logic [TAG_WIDTH-1:0] src2_tag,
    output logic [TAG_WIDTH-1:0] dst_tag,
    output logic                 ready,
    output logic [1:0]           wake_count
);
    assign ready = valid && src1_ready && src2_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            tid <= 1'b0;
            op <= 4'd0;
            rd <= 5'd0;
            rs1 <= 5'd0;
            rs2 <= 5'd0;
            src1_ready <= 1'b0;
            src2_ready <= 1'b0;
            src1_tag <= '0;
            src2_tag <= '0;
            dst_tag <= '0;
            wake_count <= 2'd0;
        end else begin
            wake_count <= 2'd0;
            if (release_valid) begin
                valid <= 1'b0;
            end
            if (allocate) begin
                valid <= 1'b1;
                tid <= alloc_tid;
                op <= alloc_op;
                rd <= alloc_rd;
                rs1 <= alloc_rs1;
                rs2 <= alloc_rs2;
                src1_ready <= alloc_src1_ready;
                src2_ready <= alloc_src2_ready;
                src1_tag <= alloc_src1_tag;
                src2_tag <= alloc_src2_tag;
                dst_tag <= alloc_dst_tag;
            end else if (broadcast_valid && valid && (broadcast_tid == tid)) begin
                wake_count <= (!src1_ready && (src1_tag == broadcast_tag)) +
                              (!src2_ready && (src2_tag == broadcast_tag));
                if (!src1_ready && (src1_tag == broadcast_tag)) begin
                    src1_ready <= 1'b1;
                end
                if (!src2_ready && (src2_tag == broadcast_tag)) begin
                    src2_ready <= 1'b1;
                end
            end
        end
    end
endmodule
