`timescale 1ns/1ps

module tb_scoreboard;
    localparam NUM_ENTRIES = 4;
    localparam TAG_WIDTH = 8;

    logic clk;
    logic rst_n;
    logic issue_valid;
    logic issue_tid;
    logic [3:0] issue_op;
    logic [4:0] issue_rd;
    logic [4:0] issue_rs1;
    logic [4:0] issue_rs2;
    logic issue_src1_needed;
    logic issue_src2_needed;
    logic issue_ready;
    logic [$clog2(NUM_ENTRIES)-1:0] issue_entry;
    logic [TAG_WIDTH-1:0] issue_dst_tag;
    logic release_valid;
    logic [$clog2(NUM_ENTRIES)-1:0] release_entry;
    logic broadcast_valid;
    logic broadcast_tid;
    logic [4:0] broadcast_rd;
    logic [TAG_WIDTH-1:0] broadcast_tag;
    logic [NUM_ENTRIES-1:0] entry_valid;
    logic [NUM_ENTRIES-1:0] entry_ready;
    logic [31:0] accepted_count;
    logic [31:0] immediate_ready_count;
    logic [31:0] wait_src1_count;
    logic [31:0] wait_src2_count;
    logic [31:0] wakeup_count;
    logic [31:0] broadcast_count;
    logic [31:0] dependency_count;
    logic [31:0] full_stall_count;
    logic [31:0] thread0_accepted_count;
    logic [31:0] thread1_accepted_count;
    logic [31:0] thread0_wakeup_count;
    logic [31:0] thread1_wakeup_count;
    integer checks;
    integer errors;
    integer cycle;
    integer trace_fd;
    integer e_x0;
    integer e_t0_x5;
    integer e_t0_dep;
    integer e_t1_cross;
    integer e_x10;
    integer e_x11;
    integer e_x12;
    integer e_x20;
    integer e_x21;
    integer e_x22;
    integer e_t1_x7;
    integer e_t1_x8;
    integer e_x9;
    integer e_store;
    integer e_branch;
    integer e_full0;
    integer e_full1;
    integer e_full2;
    integer e_full3;
    integer e_reuse;
    logic [TAG_WIDTH-1:0] tag_x0;
    logic [TAG_WIDTH-1:0] tag_t0_x5;
    logic [TAG_WIDTH-1:0] tag_t0_dep;
    logic [TAG_WIDTH-1:0] tag_t1_cross;
    logic [TAG_WIDTH-1:0] tag_x10;
    logic [TAG_WIDTH-1:0] tag_x11;
    logic [TAG_WIDTH-1:0] tag_x12;
    logic [TAG_WIDTH-1:0] tag_x20;
    logic [TAG_WIDTH-1:0] tag_x21;
    logic [TAG_WIDTH-1:0] tag_x22;
    logic [TAG_WIDTH-1:0] tag_t1_x7;
    logic [TAG_WIDTH-1:0] tag_t1_x8;
    logic [TAG_WIDTH-1:0] tag_x9;
    logic [TAG_WIDTH-1:0] tag_store;
    logic [TAG_WIDTH-1:0] tag_branch;
    logic [TAG_WIDTH-1:0] tag_full0;
    logic [TAG_WIDTH-1:0] tag_full1;
    logic [TAG_WIDTH-1:0] tag_full2;
    logic [TAG_WIDTH-1:0] tag_full3;
    logic [TAG_WIDTH-1:0] tag_reuse;

    scoreboard_issue_model #(
        .NUM_ENTRIES(NUM_ENTRIES),
        .TAG_WIDTH(TAG_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .issue_valid(issue_valid),
        .issue_tid(issue_tid),
        .issue_op(issue_op),
        .issue_rd(issue_rd),
        .issue_rs1(issue_rs1),
        .issue_rs2(issue_rs2),
        .issue_src1_needed(issue_src1_needed),
        .issue_src2_needed(issue_src2_needed),
        .issue_ready(issue_ready),
        .issue_entry(issue_entry),
        .issue_dst_tag(issue_dst_tag),
        .release_valid(release_valid),
        .release_entry(release_entry),
        .broadcast_valid(broadcast_valid),
        .broadcast_tid(broadcast_tid),
        .broadcast_rd(broadcast_rd),
        .broadcast_tag(broadcast_tag),
        .entry_valid(entry_valid),
        .entry_ready(entry_ready),
        .accepted_count(accepted_count),
        .immediate_ready_count(immediate_ready_count),
        .wait_src1_count(wait_src1_count),
        .wait_src2_count(wait_src2_count),
        .wakeup_count(wakeup_count),
        .broadcast_count(broadcast_count),
        .dependency_count(dependency_count),
        .full_stall_count(full_stall_count),
        .thread0_accepted_count(thread0_accepted_count),
        .thread1_accepted_count(thread1_accepted_count),
        .thread0_wakeup_count(thread0_wakeup_count),
        .thread1_wakeup_count(thread1_wakeup_count)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle = cycle + 1;
        if (trace_fd != 0) begin
            $fdisplay(trace_fd,
                "SCOREBOARD: cycle=%0d issue_valid=%0d issue_ready=%0d tid=%0d op=%0d rd=x%0d rs1=x%0d rs2=x%0d alloc_entry=%0d tag=%0d valid=%b ready=%b",
                cycle, issue_valid, issue_ready, issue_tid, issue_op, issue_rd,
                issue_rs1, issue_rs2, issue_entry, issue_dst_tag, entry_valid, entry_ready);
            if (broadcast_valid) begin
                $fdisplay(trace_fd,
                    "BROADCAST: cycle=%0d tid=%0d rd=x%0d tag=%0d",
                    cycle, broadcast_tid, broadcast_rd, broadcast_tag);
            end
        end
    end

    task automatic expect_bit(input string name, input logic actual, input logic expected);
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %s actual=%b expected=%b", name, actual, expected);
            end else begin
                $display("PASS: %s", name);
            end
        end
    endtask

    task automatic expect_ge(input string name, input integer actual, input integer expected_min);
        begin
            checks = checks + 1;
            if (actual < expected_min) begin
                errors = errors + 1;
                $display("FAIL: %s actual=%0d expected_min=%0d", name, actual, expected_min);
            end else begin
                $display("PASS: %s actual=%0d", name, actual);
            end
        end
    endtask

    task automatic issue_inst(
        input logic tid,
        input logic [3:0] op,
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input logic src1_needed,
        input logic src2_needed,
        output integer slot,
        output logic [TAG_WIDTH-1:0] tag
    );
        begin
            @(negedge clk);
            issue_valid = 1'b1;
            issue_tid = tid;
            issue_op = op;
            issue_rd = rd;
            issue_rs1 = rs1;
            issue_rs2 = rs2;
            issue_src1_needed = src1_needed;
            issue_src2_needed = src2_needed;
            #1;
            if (!issue_ready) begin
                $display("FAIL: issue_inst unexpectedly blocked tid=%0d rd=x%0d", tid, rd);
                errors = errors + 1;
            end
            slot = issue_entry;
            tag = issue_dst_tag;
            @(posedge clk);
            #1;
            issue_valid = 1'b0;
        end
    endtask

    task automatic release_slot(input integer slot);
        begin
            @(negedge clk);
            release_valid = 1'b1;
            release_entry = slot[$clog2(NUM_ENTRIES)-1:0];
            @(posedge clk);
            #1;
            release_valid = 1'b0;
        end
    endtask

    task automatic broadcast_result(
        input logic tid,
        input logic [4:0] rd,
        input logic [TAG_WIDTH-1:0] tag
    );
        begin
            @(negedge clk);
            broadcast_valid = 1'b1;
            broadcast_tid = tid;
            broadcast_rd = rd;
            broadcast_tag = tag;
            @(posedge clk);
            #1;
            broadcast_valid = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        issue_valid = 1'b0;
        issue_tid = 1'b0;
        issue_op = 4'd0;
        issue_rd = 5'd0;
        issue_rs1 = 5'd0;
        issue_rs2 = 5'd0;
        issue_src1_needed = 1'b0;
        issue_src2_needed = 1'b0;
        release_valid = 1'b0;
        release_entry = '0;
        broadcast_valid = 1'b0;
        broadcast_tid = 1'b0;
        broadcast_rd = 5'd0;
        broadcast_tag = '0;
        checks = 0;
        errors = 0;
        cycle = 0;
        trace_fd = $fopen("reports/sim/scoreboard_trace.log", "w");
        $dumpfile("sim/phase16_scoreboard.vcd");
        $dumpvars(0, tb_scoreboard);

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        expect_bit("thread0 x0 reset available", dut.busy[0][0], 1'b0);
        expect_bit("thread1 x0 reset available", dut.busy[1][0], 1'b0);

        issue_inst(1'b0, 4'd1, 5'd0, 5'd0, 5'd0, 1'b0, 1'b0, e_x0, tag_x0);
        expect_bit("x0 issue accepted as ready", entry_ready[e_x0], 1'b1);
        expect_bit("x0 is never marked busy", dut.busy[0][0], 1'b0);
        release_slot(e_x0);

        issue_inst(1'b0, 4'd1, 5'd5, 5'd0, 5'd0, 1'b0, 1'b0, e_t0_x5, tag_t0_x5);
        expect_bit("thread0 destination x5 marked busy", dut.busy[0][5], 1'b1);
        expect_bit("independent ADDI ready immediately", entry_ready[e_t0_x5], 1'b1);
        expect_bit("entry stores thread0 metadata", dut.entry_tid[e_t0_x5], 1'b0);
        issue_inst(1'b0, 4'd2, 5'd6, 5'd5, 5'd1, 1'b1, 1'b0, e_t0_dep, tag_t0_dep);
        expect_bit("same-thread RAW waits for source", dut.entry_src1_ready[e_t0_dep], 1'b0);
        expect_bit("dependent instruction is not ready", entry_ready[e_t0_dep], 1'b0);
        expect_bit("dependent source tag matches producer", dut.entry_src1_tag[e_t0_dep] == tag_t0_x5, 1'b1);
        issue_inst(1'b1, 4'd2, 5'd6, 5'd5, 5'd1, 1'b1, 1'b0, e_t1_cross, tag_t1_cross);
        expect_bit("cross-thread same register stays independent", entry_ready[e_t1_cross], 1'b1);
        expect_bit("thread1 destination x6 marked busy independently", dut.busy[1][6], 1'b1);
        broadcast_result(1'b1, 5'd5, tag_t0_x5);
        expect_bit("wrong-thread broadcast does not wake thread0", entry_ready[e_t0_dep], 1'b0);
        expect_bit("wrong-thread broadcast does not clear thread0 busy", dut.busy[0][5], 1'b1);
        broadcast_result(1'b0, 5'd5, tag_t0_x5);
        expect_bit("matching broadcast wakes thread0 dependency", entry_ready[e_t0_dep], 1'b1);
        expect_bit("matching broadcast clears thread0 busy", dut.busy[0][5], 1'b0);
        broadcast_result(1'b0, 5'd6, tag_t0_dep);
        broadcast_result(1'b1, 5'd6, tag_t1_cross);
        release_slot(e_t0_x5);
        release_slot(e_t0_dep);
        release_slot(e_t1_cross);

        issue_inst(1'b0, 4'd2, 5'd10, 5'd0, 5'd0, 1'b0, 1'b0, e_x10, tag_x10);
        issue_inst(1'b0, 4'd2, 5'd11, 5'd0, 5'd0, 1'b0, 1'b0, e_x11, tag_x11);
        issue_inst(1'b0, 4'd2, 5'd12, 5'd10, 5'd11, 1'b1, 1'b1, e_x12, tag_x12);
        expect_bit("two-source RAW source1 initially waits", dut.entry_src1_ready[e_x12], 1'b0);
        expect_bit("two-source RAW source2 initially waits", dut.entry_src2_ready[e_x12], 1'b0);
        expect_bit("two-source RAW entry initially blocked", entry_ready[e_x12], 1'b0);
        broadcast_result(1'b0, 5'd10, tag_x10);
        expect_bit("first broadcast wakes source1", dut.entry_src1_ready[e_x12], 1'b1);
        expect_bit("entry waits until second source arrives", entry_ready[e_x12], 1'b0);
        broadcast_result(1'b0, 5'd11, tag_x11);
        expect_bit("second broadcast wakes source2", dut.entry_src2_ready[e_x12], 1'b1);
        expect_bit("entry ready after both broadcasts", entry_ready[e_x12], 1'b1);
        broadcast_result(1'b0, 5'd12, tag_x12);
        release_slot(e_x10);
        release_slot(e_x11);
        release_slot(e_x12);

        issue_inst(1'b0, 4'd2, 5'd20, 5'd0, 5'd0, 1'b0, 1'b0, e_x20, tag_x20);
        issue_inst(1'b0, 4'd2, 5'd21, 5'd20, 5'd0, 1'b1, 1'b0, e_x21, tag_x21);
        issue_inst(1'b0, 4'd2, 5'd22, 5'd20, 5'd0, 1'b1, 1'b0, e_x22, tag_x22);
        broadcast_result(1'b0, 5'd20, tag_x20);
        expect_bit("one broadcast wakes first waiting entry", entry_ready[e_x21], 1'b1);
        expect_bit("one broadcast wakes second waiting entry", entry_ready[e_x22], 1'b1);
        broadcast_result(1'b0, 5'd21, tag_x21);
        broadcast_result(1'b0, 5'd22, tag_x22);
        release_slot(e_x20);
        release_slot(e_x21);
        release_slot(e_x22);

        issue_inst(1'b1, 4'd2, 5'd7, 5'd0, 5'd0, 1'b0, 1'b0, e_t1_x7, tag_t1_x7);
        issue_inst(1'b1, 4'd2, 5'd8, 5'd7, 5'd0, 1'b1, 1'b0, e_t1_x8, tag_t1_x8);
        broadcast_result(1'b0, 5'd7, tag_t1_x7);
        expect_bit("thread0 broadcast cannot wake thread1", entry_ready[e_t1_x8], 1'b0);
        broadcast_result(1'b1, 5'd7, tag_t1_x7);
        expect_bit("thread1 broadcast wakes thread1 dependency", entry_ready[e_t1_x8], 1'b1);
        broadcast_result(1'b1, 5'd8, tag_t1_x8);
        release_slot(e_t1_x7);
        release_slot(e_t1_x8);

        issue_inst(1'b0, 4'd2, 5'd9, 5'd0, 5'd0, 1'b0, 1'b0, e_x9, tag_x9);
        issue_inst(1'b0, 4'd8, 5'd0, 5'd0, 5'd9, 1'b1, 1'b1, e_store, tag_store);
        issue_inst(1'b0, 4'd9, 5'd0, 5'd9, 5'd0, 1'b1, 1'b1, e_branch, tag_branch);
        expect_bit("store waits for busy data source", dut.entry_src2_ready[e_store], 1'b0);
        expect_bit("branch waits for busy compare source", dut.entry_src1_ready[e_branch], 1'b0);
        broadcast_result(1'b0, 5'd9, tag_x9);
        expect_bit("store becomes ready after data broadcast", entry_ready[e_store], 1'b1);
        expect_bit("branch becomes ready after compare broadcast", entry_ready[e_branch], 1'b1);
        release_slot(e_x9);
        release_slot(e_store);
        release_slot(e_branch);

        issue_inst(1'b0, 4'd2, 5'd24, 5'd0, 5'd0, 1'b0, 1'b0, e_full0, tag_full0);
        issue_inst(1'b0, 4'd2, 5'd25, 5'd0, 5'd0, 1'b0, 1'b0, e_full1, tag_full1);
        issue_inst(1'b1, 4'd2, 5'd26, 5'd0, 5'd0, 1'b0, 1'b0, e_full2, tag_full2);
        issue_inst(1'b1, 4'd2, 5'd27, 5'd0, 5'd0, 1'b0, 1'b0, e_full3, tag_full3);
        expect_bit("all scoreboard entries allocated", &entry_valid, 1'b1);
        @(negedge clk);
        issue_valid = 1'b1;
        issue_tid = 1'b0;
        issue_op = 4'd2;
        issue_rd = 5'd28;
        issue_rs1 = 5'd0;
        issue_rs2 = 5'd0;
        issue_src1_needed = 1'b0;
        issue_src2_needed = 1'b0;
        #1;
        expect_bit("full scoreboard blocks issue", issue_ready, 1'b0);
        @(posedge clk);
        #1;
        issue_valid = 1'b0;
        expect_ge("full scoreboard stall counter increments", full_stall_count, 1);
        release_slot(e_full0);
        issue_inst(1'b0, 4'd2, 5'd28, 5'd0, 5'd0, 1'b0, 1'b0, e_reuse, tag_reuse);
        expect_bit("released entry can be reused", entry_valid[e_reuse], 1'b1);
        expect_bit("reused independent entry is ready", entry_ready[e_reuse], 1'b1);
        broadcast_result(1'b0, 5'd24, tag_full0);
        broadcast_result(1'b0, 5'd25, tag_full1);
        broadcast_result(1'b1, 5'd26, tag_full2);
        broadcast_result(1'b1, 5'd27, tag_full3);
        broadcast_result(1'b0, 5'd28, tag_reuse);
        release_slot(e_full1);
        release_slot(e_full2);
        release_slot(e_full3);
        release_slot(e_reuse);

        expect_bit("thread0 x0 remains available", dut.busy[0][0], 1'b0);
        expect_bit("thread1 x0 remains available", dut.busy[1][0], 1'b0);
        expect_ge("accepted instruction counter populated", accepted_count, 20);
        expect_ge("immediate-ready counter populated", immediate_ready_count, 8);
        expect_ge("source1 wait counter populated", wait_src1_count, 5);
        expect_ge("source2 wait counter populated", wait_src2_count, 2);
        expect_ge("wakeup counter populated", wakeup_count, 8);
        expect_ge("broadcast counter populated", broadcast_count, 10);
        expect_ge("dependency counter populated", dependency_count, 6);
        expect_ge("thread0 accepted counter populated", thread0_accepted_count, 10);
        expect_ge("thread1 accepted counter populated", thread1_accepted_count, 3);
        expect_ge("thread0 wakeup counter populated", thread0_wakeup_count, 6);
        expect_ge("thread1 wakeup counter populated", thread1_wakeup_count, 1);

        $display("SCOREPERF: accepted=%0d immediate_ready=%0d wait_src1=%0d wait_src2=%0d wakeups=%0d broadcasts=%0d dependencies=%0d full_stalls=%0d thread0_accepted=%0d thread1_accepted=%0d thread0_wakeups=%0d thread1_wakeups=%0d checks=%0d errors=%0d pass=%s",
            accepted_count, immediate_ready_count, wait_src1_count, wait_src2_count,
            wakeup_count, broadcast_count, dependency_count, full_stall_count,
            thread0_accepted_count, thread1_accepted_count, thread0_wakeup_count,
            thread1_wakeup_count, checks, errors, (errors == 0) ? "PASS" : "FAIL");
        if (trace_fd != 0) begin
            $fclose(trace_fd);
        end
        if (checks < 20) begin
            $fatal(1, "FAIL: fewer than 20 meaningful scoreboard checks");
        end
        if (errors != 0) begin
            $fatal(1, "FAIL: scoreboard validation errors=%0d", errors);
        end
        $display("PASS: Phase 16 scoreboard validation checks=%0d", checks);
        $finish;
    end
endmodule
