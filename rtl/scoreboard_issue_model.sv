`timescale 1ns/1ps

module scoreboard_issue_model #(
    parameter NUM_THREADS = 2,
    parameter NUM_ENTRIES = 4,
    parameter TAG_WIDTH = 8
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 issue_valid,
    input  logic                 issue_tid,
    input  logic [3:0]           issue_op,
    input  logic [4:0]           issue_rd,
    input  logic [4:0]           issue_rs1,
    input  logic [4:0]           issue_rs2,
    input  logic                 issue_src1_needed,
    input  logic                 issue_src2_needed,
    output logic                 issue_ready,
    output logic [$clog2(NUM_ENTRIES)-1:0] issue_entry,
    output logic [TAG_WIDTH-1:0] issue_dst_tag,
    input  logic                 release_valid,
    input  logic [$clog2(NUM_ENTRIES)-1:0] release_entry,
    input  logic                 broadcast_valid,
    input  logic                 broadcast_tid,
    input  logic [4:0]           broadcast_rd,
    input  logic [TAG_WIDTH-1:0] broadcast_tag,
    output logic [NUM_ENTRIES-1:0] entry_valid,
    output logic [NUM_ENTRIES-1:0] entry_ready,
    output logic [31:0] accepted_count,
    output logic [31:0] immediate_ready_count,
    output logic [31:0] wait_src1_count,
    output logic [31:0] wait_src2_count,
    output logic [31:0] wakeup_count,
    output logic [31:0] broadcast_count,
    output logic [31:0] dependency_count,
    output logic [31:0] full_stall_count,
    output logic [31:0] thread0_accepted_count,
    output logic [31:0] thread1_accepted_count,
    output logic [31:0] thread0_wakeup_count,
    output logic [31:0] thread1_wakeup_count
);
    logic busy [0:NUM_THREADS-1][0:31];
    logic [TAG_WIDTH-1:0] busy_tag [0:NUM_THREADS-1][0:31];
    logic [TAG_WIDTH-1:0] next_tag;
    logic free_found;
    logic alloc_src1_ready;
    logic alloc_src2_ready;
    logic [TAG_WIDTH-1:0] alloc_src1_tag;
    logic [TAG_WIDTH-1:0] alloc_src2_tag;
    logic [TAG_WIDTH-1:0] allocated_tag;
    logic [NUM_ENTRIES-1:0] alloc_onehot;
    logic [NUM_ENTRIES-1:0] release_onehot;
    logic [1:0] entry_wake_count [0:NUM_ENTRIES-1];
    /* verilator lint_off UNUSEDSIGNAL */
    logic entry_tid [0:NUM_ENTRIES-1];
    logic [3:0] entry_op [0:NUM_ENTRIES-1];
    logic [4:0] entry_rd [0:NUM_ENTRIES-1];
    logic [4:0] entry_rs1 [0:NUM_ENTRIES-1];
    logic [4:0] entry_rs2 [0:NUM_ENTRIES-1];
    logic [TAG_WIDTH-1:0] entry_src1_tag [0:NUM_ENTRIES-1];
    logic [TAG_WIDTH-1:0] entry_src2_tag [0:NUM_ENTRIES-1];
    logic [TAG_WIDTH-1:0] entry_dst_tag [0:NUM_ENTRIES-1];
    logic entry_src1_ready [0:NUM_ENTRIES-1];
    logic entry_src2_ready [0:NUM_ENTRIES-1];
    /* verilator lint_on UNUSEDSIGNAL */
    logic [31:0] wake_sum;
    integer comb_i;
    integer t;
    integer reset_i;
    integer wake_i;

    always_comb begin
        free_found = 1'b0;
        issue_entry = '0;
        alloc_onehot = '0;
        release_onehot = '0;
        for (comb_i = 0; comb_i < NUM_ENTRIES; comb_i = comb_i + 1) begin
            if (!free_found && !entry_valid[comb_i]) begin
                free_found = 1'b1;
                issue_entry = comb_i[$clog2(NUM_ENTRIES)-1:0];
            end
            if (release_valid && (release_entry == comb_i[$clog2(NUM_ENTRIES)-1:0])) begin
                release_onehot[comb_i] = 1'b1;
            end
        end
        issue_ready = free_found;
        if (issue_valid && free_found) begin
            alloc_onehot[issue_entry] = 1'b1;
        end
        alloc_src1_ready = !issue_src1_needed || (issue_rs1 == 5'd0) || !busy[issue_tid][issue_rs1];
        alloc_src2_ready = !issue_src2_needed || (issue_rs2 == 5'd0) || !busy[issue_tid][issue_rs2];
        alloc_src1_tag = busy_tag[issue_tid][issue_rs1];
        alloc_src2_tag = busy_tag[issue_tid][issue_rs2];
        allocated_tag = next_tag;
        issue_dst_tag = allocated_tag;
    end

    always_comb begin
        wake_sum = 32'd0;
        for (wake_i = 0; wake_i < NUM_ENTRIES; wake_i = wake_i + 1) begin
            wake_sum = wake_sum + {{30{1'b0}}, entry_wake_count[wake_i]};
        end
    end

    generate
        genvar g;
        for (g = 0; g < NUM_ENTRIES; g = g + 1) begin : gen_entries
            reservation_station_entry #(.TAG_WIDTH(TAG_WIDTH)) u_entry (
                .clk(clk), .rst_n(rst_n), .allocate(alloc_onehot[g]), .release_valid(release_onehot[g]),
                .alloc_tid(issue_tid), .alloc_op(issue_op), .alloc_rd(issue_rd),
                .alloc_rs1(issue_rs1), .alloc_rs2(issue_rs2),
                .alloc_src1_ready(alloc_src1_ready), .alloc_src2_ready(alloc_src2_ready),
                .alloc_src1_tag(alloc_src1_tag), .alloc_src2_tag(alloc_src2_tag),
                .alloc_dst_tag(allocated_tag), .broadcast_valid(broadcast_valid),
                .broadcast_tid(broadcast_tid), .broadcast_tag(broadcast_tag),
                .valid(entry_valid[g]), .tid(entry_tid[g]), .op(entry_op[g]), .rd(entry_rd[g]),
                .rs1(entry_rs1[g]), .rs2(entry_rs2[g]), .src1_ready(entry_src1_ready[g]),
                .src2_ready(entry_src2_ready[g]), .src1_tag(entry_src1_tag[g]),
                .src2_tag(entry_src2_tag[g]), .dst_tag(entry_dst_tag[g]),
                .ready(entry_ready[g]), .wake_count(entry_wake_count[g])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_tag <= {{(TAG_WIDTH-1){1'b0}}, 1'b1};
            accepted_count <= 32'd0;
            immediate_ready_count <= 32'd0;
            wait_src1_count <= 32'd0;
            wait_src2_count <= 32'd0;
            wakeup_count <= 32'd0;
            broadcast_count <= 32'd0;
            dependency_count <= 32'd0;
            full_stall_count <= 32'd0;
            thread0_accepted_count <= 32'd0;
            thread1_accepted_count <= 32'd0;
            thread0_wakeup_count <= 32'd0;
            thread1_wakeup_count <= 32'd0;
            for (t = 0; t < NUM_THREADS; t = t + 1) begin
                for (reset_i = 0; reset_i < 32; reset_i = reset_i + 1) begin
                    busy[t][reset_i] <= 1'b0;
                    busy_tag[t][reset_i] <= '0;
                end
            end
        end else begin
            busy[0][0] <= 1'b0;
            busy[1][0] <= 1'b0;
            if (wake_sum != 0) begin
                wakeup_count <= wakeup_count + wake_sum;
                if (broadcast_tid) thread1_wakeup_count <= thread1_wakeup_count + wake_sum;
                else thread0_wakeup_count <= thread0_wakeup_count + wake_sum;
            end
            if (broadcast_valid) begin
                broadcast_count <= broadcast_count + 32'd1;
                if ((broadcast_rd != 5'd0) && busy[broadcast_tid][broadcast_rd] &&
                    (busy_tag[broadcast_tid][broadcast_rd] == broadcast_tag)) begin
                    busy[broadcast_tid][broadcast_rd] <= 1'b0;
                end
            end
            if (issue_valid && issue_ready) begin
                accepted_count <= accepted_count + 32'd1;
                next_tag <= next_tag + {{(TAG_WIDTH-1){1'b0}}, 1'b1};
                if (alloc_src1_ready && alloc_src2_ready) immediate_ready_count <= immediate_ready_count + 32'd1;
                if (!alloc_src1_ready) wait_src1_count <= wait_src1_count + 32'd1;
                if (!alloc_src2_ready) wait_src2_count <= wait_src2_count + 32'd1;
                if (!alloc_src1_ready || !alloc_src2_ready) dependency_count <= dependency_count + 32'd1;
                if (issue_tid) thread1_accepted_count <= thread1_accepted_count + 32'd1;
                else thread0_accepted_count <= thread0_accepted_count + 32'd1;
                if (issue_rd != 5'd0) begin
                    busy[issue_tid][issue_rd] <= 1'b1;
                    busy_tag[issue_tid][issue_rd] <= allocated_tag;
                end
            end else if (issue_valid && !issue_ready) begin
                full_stall_count <= full_stall_count + 32'd1;
            end
        end
    end
endmodule
