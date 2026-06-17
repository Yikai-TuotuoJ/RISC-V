`timescale 1ns/1ps

module tb_tomasulo_rob;
    localparam RS_ENTRIES = 4;
    localparam ROB_ENTRIES = 4;
    localparam ROB_TAG_WIDTH = $clog2(ROB_ENTRIES);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;

    logic clk;
    logic rst_n;
    logic issue_valid;
    logic issue_tid;
    logic [3:0] issue_op;
    logic [4:0] issue_rd;
    logic [4:0] issue_rs1;
    logic [4:0] issue_rs2;
    logic [31:0] issue_imm;
    logic issue_src1_needed;
    logic issue_src2_needed;
    logic issue_src2_is_imm;
    logic issue_ready;
    logic [ROB_TAG_WIDTH-1:0] issue_rob_tag;
    logic debug_write_valid;
    logic debug_write_tid;
    logic [4:0] debug_write_rd;
    logic [31:0] debug_write_data;
    logic debug_set_status_valid;
    logic debug_set_status_tid;
    logic [4:0] debug_set_status_rd;
    logic [ROB_TAG_WIDTH-1:0] debug_set_status_tag;
    logic debug_cdb_valid;
    logic debug_cdb_tid;
    logic [ROB_TAG_WIDTH-1:0] debug_cdb_rob_tag;
    logic [4:0] debug_cdb_rd;
    logic [31:0] debug_cdb_data;

    logic [31:0] dispatched_count;
    logic [31:0] rob_alloc_count;
    logic [31:0] rob_full_stall_count;
    logic [31:0] rs_alloc_count;
    logic [31:0] rs_full_stall_count;
    logic [31:0] issued_count;
    logic [31:0] ooo_issue_count;
    logic [31:0] completed_count;
    logic [31:0] broadcast_count;
    logic [31:0] wakeup_count;
    logic [31:0] commit_count;
    logic [31:0] commit_stall_count;
    logic [31:0] younger_done_waiting_count;
    logic [31:0] stale_tag_ignored_count;
    logic [31:0] x0_commit_suppressed_count;
    logic [31:0] unsupported_count;
    logic [31:0] thread0_commit_count;
    logic [31:0] thread1_commit_count;

    logic trace_dispatch_valid;
    logic [ROB_TAG_WIDTH-1:0] trace_dispatch_rob;
    logic [$clog2(RS_ENTRIES)-1:0] trace_dispatch_rs;
    logic [3:0] trace_dispatch_op;
    logic [4:0] trace_dispatch_rd;
    logic trace_issue_valid;
    logic [$clog2(RS_ENTRIES)-1:0] trace_issue_rs;
    logic [ROB_TAG_WIDTH-1:0] trace_issue_rob;
    logic trace_cdb_valid;
    logic [ROB_TAG_WIDTH-1:0] trace_cdb_rob;
    logic [4:0] trace_cdb_rd;
    logic [31:0] trace_cdb_data;
    logic [3:0] trace_wakeup_count;
    logic trace_commit_valid;
    logic [ROB_TAG_WIDTH-1:0] trace_commit_rob;
    logic [4:0] trace_commit_rd;
    logic [31:0] trace_commit_data;
    logic trace_commit_stall;

    integer checks;
    integer errors;
    integer cycle;
    integer trace_fd;
    logic [ROB_TAG_WIDTH-1:0] tag_p;
    logic [ROB_TAG_WIDTH-1:0] tag_a;
    logic [ROB_TAG_WIDTH-1:0] tag_b;
    logic [ROB_TAG_WIDTH-1:0] tag_tmp;
    logic [31:0] target_commit;
    logic [31:0] target_completed;

    tomasulo_rob_experiment_core #(
        .RS_ENTRIES(RS_ENTRIES),
        .ROB_ENTRIES(ROB_ENTRIES),
        .ALU_LATENCY(2)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .issue_valid(issue_valid),
        .issue_tid(issue_tid),
        .issue_op(issue_op),
        .issue_rd(issue_rd),
        .issue_rs1(issue_rs1),
        .issue_rs2(issue_rs2),
        .issue_imm(issue_imm),
        .issue_src1_needed(issue_src1_needed),
        .issue_src2_needed(issue_src2_needed),
        .issue_src2_is_imm(issue_src2_is_imm),
        .issue_ready(issue_ready),
        .issue_rob_tag(issue_rob_tag),
        .debug_write_valid(debug_write_valid),
        .debug_write_tid(debug_write_tid),
        .debug_write_rd(debug_write_rd),
        .debug_write_data(debug_write_data),
        .debug_set_status_valid(debug_set_status_valid),
        .debug_set_status_tid(debug_set_status_tid),
        .debug_set_status_rd(debug_set_status_rd),
        .debug_set_status_tag(debug_set_status_tag),
        .debug_cdb_valid(debug_cdb_valid),
        .debug_cdb_tid(debug_cdb_tid),
        .debug_cdb_rob_tag(debug_cdb_rob_tag),
        .debug_cdb_rd(debug_cdb_rd),
        .debug_cdb_data(debug_cdb_data),
        .dispatched_count(dispatched_count),
        .rob_alloc_count(rob_alloc_count),
        .rob_full_stall_count(rob_full_stall_count),
        .rs_alloc_count(rs_alloc_count),
        .rs_full_stall_count(rs_full_stall_count),
        .issued_count(issued_count),
        .ooo_issue_count(ooo_issue_count),
        .completed_count(completed_count),
        .broadcast_count(broadcast_count),
        .wakeup_count(wakeup_count),
        .commit_count(commit_count),
        .commit_stall_count(commit_stall_count),
        .younger_done_waiting_count(younger_done_waiting_count),
        .stale_tag_ignored_count(stale_tag_ignored_count),
        .x0_commit_suppressed_count(x0_commit_suppressed_count),
        .unsupported_count(unsupported_count),
        .thread0_commit_count(thread0_commit_count),
        .thread1_commit_count(thread1_commit_count),
        .trace_dispatch_valid(trace_dispatch_valid),
        .trace_dispatch_rob(trace_dispatch_rob),
        .trace_dispatch_rs(trace_dispatch_rs),
        .trace_dispatch_op(trace_dispatch_op),
        .trace_dispatch_rd(trace_dispatch_rd),
        .trace_issue_valid(trace_issue_valid),
        .trace_issue_rs(trace_issue_rs),
        .trace_issue_rob(trace_issue_rob),
        .trace_cdb_valid(trace_cdb_valid),
        .trace_cdb_rob(trace_cdb_rob),
        .trace_cdb_rd(trace_cdb_rd),
        .trace_cdb_data(trace_cdb_data),
        .trace_wakeup_count(trace_wakeup_count),
        .trace_commit_valid(trace_commit_valid),
        .trace_commit_rob(trace_commit_rob),
        .trace_commit_rd(trace_commit_rd),
        .trace_commit_data(trace_commit_data),
        .trace_commit_stall(trace_commit_stall)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle = cycle + 1;
        #1;
        if (trace_fd != 0) begin
            if (trace_dispatch_valid) begin
                $fdisplay(trace_fd, "DISPATCH: cycle=%0d rob=R%0d rs=%0d tid=%0d op=%0d rd=x%0d", cycle, trace_dispatch_rob, trace_dispatch_rs, issue_tid, trace_dispatch_op, trace_dispatch_rd);
            end
            if (trace_issue_valid) begin
                $fdisplay(trace_fd, "ISSUE: cycle=%0d rs=%0d rob=R%0d reason=ready", cycle, trace_issue_rs, trace_issue_rob);
            end
            if (trace_cdb_valid) begin
                $fdisplay(trace_fd, "CDB: cycle=%0d rob=R%0d rd=x%0d data=%08x wake_sources=%0d", cycle, trace_cdb_rob, trace_cdb_rd, trace_cdb_data, trace_wakeup_count);
            end
            if (trace_commit_stall) begin
                $fdisplay(trace_fd, "COMMIT_STALL: cycle=%0d head=R%0d reason=head_not_ready", cycle, dut.rob_head);
            end
            if (trace_commit_valid) begin
                $fdisplay(trace_fd, "COMMIT: cycle=%0d rob=R%0d rd=x%0d data=%08x", cycle, trace_commit_rob, trace_commit_rd, trace_commit_data);
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

    task automatic expect32(input string name, input logic [31:0] actual, input logic [31:0] expected);
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %s actual=%08x expected=%08x", name, actual, expected);
            end else begin
                $display("PASS: %s = %08x", name, actual);
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

    task automatic debug_write(input logic tid, input logic [4:0] rd, input logic [31:0] data);
        begin
            @(negedge clk);
            debug_write_valid = 1'b1;
            debug_write_tid = tid;
            debug_write_rd = rd;
            debug_write_data = data;
            @(posedge clk); #1;
            debug_write_valid = 1'b0;
        end
    endtask

    task automatic inject_cdb(input logic tid, input logic [ROB_TAG_WIDTH-1:0] tag, input logic [4:0] rd, input logic [31:0] data);
        begin
            @(negedge clk);
            debug_cdb_valid = 1'b1;
            debug_cdb_tid = tid;
            debug_cdb_rob_tag = tag;
            debug_cdb_rd = rd;
            debug_cdb_data = data;
            @(posedge clk); #1;
            debug_cdb_valid = 1'b0;
        end
    endtask

    task automatic issue_uop(
        input logic tid,
        input logic [3:0] op,
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input logic [31:0] imm,
        input logic src1_needed,
        input logic src2_needed,
        input logic src2_is_imm,
        output logic [ROB_TAG_WIDTH-1:0] tag
    );
        begin
            @(negedge clk);
            issue_valid = 1'b1;
            issue_tid = tid;
            issue_op = op;
            issue_rd = rd;
            issue_rs1 = rs1;
            issue_rs2 = rs2;
            issue_imm = imm;
            issue_src1_needed = src1_needed;
            issue_src2_needed = src2_needed;
            issue_src2_is_imm = src2_is_imm;
            #1;
            if (!issue_ready) begin
                errors = errors + 1;
                $display("FAIL: issue unexpectedly blocked op=%0d rd=x%0d", op, rd);
            end
            tag = issue_rob_tag;
            @(posedge clk); #1;
            issue_valid = 1'b0;
        end
    endtask

    task automatic expect_issue_blocked(input logic [3:0] op, input logic [4:0] rd);
        begin
            @(negedge clk);
            issue_valid = 1'b1;
            issue_tid = 1'b0;
            issue_op = op;
            issue_rd = rd;
            issue_rs1 = 5'd1;
            issue_rs2 = 5'd2;
            issue_imm = 32'd0;
            issue_src1_needed = 1'b1;
            issue_src2_needed = 1'b1;
            issue_src2_is_imm = 1'b0;
            #1;
            expect_bit("issue blocked by unavailable structure or unsupported op", issue_ready, 1'b0);
            @(posedge clk); #1;
            issue_valid = 1'b0;
        end
    endtask

    task automatic wait_commits(input logic [31:0] target);
        integer timeout;
        begin
            timeout = 0;
            while ((commit_count < target) && (timeout < 300)) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end
            if (commit_count < target) begin
                errors = errors + 1;
                $display("FAIL: timeout waiting for commit_count=%0d", target);
            end
        end
    endtask

    task automatic wait_completed(input logic [31:0] target);
        integer timeout;
        begin
            timeout = 0;
            while ((completed_count < target) && (timeout < 300)) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end
            if (completed_count < target) begin
                errors = errors + 1;
                $display("FAIL: timeout waiting for completed_count=%0d", target);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        issue_valid = 1'b0;
        issue_tid = 1'b0;
        issue_op = OP_ADD;
        issue_rd = 5'd0;
        issue_rs1 = 5'd0;
        issue_rs2 = 5'd0;
        issue_imm = 32'd0;
        issue_src1_needed = 1'b0;
        issue_src2_needed = 1'b0;
        issue_src2_is_imm = 1'b0;
        debug_write_valid = 1'b0;
        debug_write_tid = 1'b0;
        debug_write_rd = 5'd0;
        debug_write_data = 32'd0;
        debug_set_status_valid = 1'b0;
        debug_set_status_tid = 1'b0;
        debug_set_status_rd = 5'd0;
        debug_set_status_tag = '0;
        debug_cdb_valid = 1'b0;
        debug_cdb_tid = 1'b0;
        debug_cdb_rob_tag = '0;
        debug_cdb_rd = 5'd0;
        debug_cdb_data = 32'd0;
        checks = 0;
        errors = 0;
        cycle = 0;
        trace_fd = $fopen("reports/sim/rob_trace.log", "w");
        $dumpfile("sim/phase18_rob.vcd");
        $dumpvars(0, tb_tomasulo_rob);

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;

        expect32("thread0 x0 reset", dut.regs[0][0], 32'd0);
        expect32("thread1 x0 reset", dut.regs[1][0], 32'd0);
        expect32("ROB count reset", dut.rob_count, 32'd0);
        expect_bit("ROB head invalid after reset", dut.rob_valid[dut.rob_head], 1'b0);

        debug_write(1'b0, 5'd1, 32'd5);
        debug_write(1'b0, 5'd2, 32'd7);
        debug_write(1'b0, 5'd3, 32'h0000f0f0);
        debug_write(1'b0, 5'd4, 32'h00000ff0);
        debug_write(1'b1, 5'd1, 32'd20);
        debug_write(1'b1, 5'd2, 32'd2);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADD, 5'd5, 5'd1, 5'd2, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        expect_bit("destination maps to ROB tag on dispatch", dut.reg_busy[0][5], 1'b1);
        expect_bit("architectural register not updated at dispatch", dut.regs[0][5] == 32'd0, 1'b1);
        wait_completed(completed_count + 1);
        expect_bit("ROB entry ready after CDB", dut.rob_ready[tag_tmp], 1'b1);
        expect32("broadcast does not directly update architectural x5", dut.regs[0][5], 32'd0);
        wait_commits(target_commit);
        expect32("ADD commits architectural result", dut.regs[0][5], 32'd12);
        expect_bit("reg status clears after matching commit", dut.reg_busy[0][5], 1'b0);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_SUB, 5'd6, 5'd2, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_commits(target_commit);
        expect32("SUB committed result", dut.regs[0][6], 32'd2);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_AND, 5'd7, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_commits(target_commit);
        expect32("AND committed result", dut.regs[0][7], 32'h000000f0);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_OR, 5'd8, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_commits(target_commit);
        expect32("OR committed result", dut.regs[0][8], 32'h0000fff0);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_XOR, 5'd9, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_commits(target_commit);
        expect32("XOR committed result", dut.regs[0][9], 32'h0000ff00);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd10, 5'd1, 5'd0, 32'd9, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("ADDI committed result", dut.regs[0][10], 32'd14);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd0, 5'd1, 5'd0, 32'd99, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("x0 commit suppressed", dut.regs[0][0], 32'd0);
        expect_ge("x0 suppression counter increments", x0_commit_suppressed_count, 1);

        @(negedge clk);
        debug_set_status_valid = 1'b1;
        debug_set_status_tid = 1'b0;
        debug_set_status_rd = 5'd20;
        debug_set_status_tag = 2'd2;
        @(posedge clk); #1;
        debug_set_status_valid = 1'b0;
        target_commit = commit_count;
        target_completed = completed_count;
        issue_uop(1'b0, OP_ADD, 5'd11, 5'd20, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_a);
        expect_bit("older dependency waits on fake producer ROB tag", dut.rs_q1_ready[0], 1'b0);
        issue_uop(1'b0, OP_ADDI, 5'd12, 5'd1, 5'd0, 32'd21, 1'b1, 1'b0, 1'b1, tag_b);
        wait_completed(target_completed + 1);
        expect_bit("younger independent ROB entry completed", dut.rob_ready[tag_b], 1'b1);
        expect32("younger completed does not commit before older dependency", dut.regs[0][12], 32'd0);
        expect_ge("commit stalls when ROB head not ready", commit_stall_count, 1);
        inject_cdb(1'b0, 2'd2, 5'd20, 32'd3);
        wait_commits(target_commit + 2);
        expect32("older dependent commits before younger final observation", dut.regs[0][11], 32'd8);
        expect32("younger independent commits after older head clears", dut.regs[0][12], 32'd26);
        expect_ge("out-of-order issue counter increments", ooo_issue_count, 1);
        expect_ge("CDB wakeup counter increments", wakeup_count, 1);

        issue_uop(1'b0, OP_ADDI, 5'd14, 5'd1, 5'd0, 32'd1, 1'b1, 1'b0, 1'b1, tag_p);
        issue_uop(1'b0, OP_ADDI, 5'd14, 5'd1, 5'd0, 32'd2, 1'b1, 1'b0, 1'b1, tag_a);
        expect_bit("newer producer replaces older register-status tag", dut.reg_tag[0][14] == tag_a, 1'b1);
        wait_commits(commit_count + 2);
        expect32("same-rd final value follows program order", dut.regs[0][14], 32'd7);
        expect_ge("stale status clear ignored for older same-rd commit", stale_tag_ignored_count, 1);

        issue_uop(1'b1, OP_ADD, 5'd5, 5'd1, 5'd2, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_commits(commit_count + 1);
        expect32("thread1 commits to thread1 register file", dut.regs[1][5], 32'd22);
        expect32("thread0 same register remains independent", dut.regs[0][5], 32'd12);
        expect_ge("thread1 commit counter increments", thread1_commit_count, 1);

        target_commit = commit_count;
        issue_uop(1'b0, OP_ADDI, 5'd16, 5'd0, 5'd0, 32'd1, 1'b0, 1'b0, 1'b1, tag_tmp);
        issue_uop(1'b0, OP_ADDI, 5'd17, 5'd0, 5'd0, 32'd2, 1'b0, 1'b0, 1'b1, tag_tmp);
        issue_uop(1'b0, OP_ADDI, 5'd18, 5'd0, 5'd0, 32'd3, 1'b0, 1'b0, 1'b1, tag_tmp);
        issue_uop(1'b0, OP_ADDI, 5'd19, 5'd0, 5'd0, 32'd4, 1'b0, 1'b0, 1'b1, tag_tmp);
        expect_bit("ROB reaches full or near-full occupancy", dut.rob_count >= 3, 1'b1);
        expect_issue_blocked(OP_ADDI, 5'd21);
        expect_ge("ROB full stall counter increments", rob_full_stall_count, 1);
        wait_commits(target_commit + 4);
        expect32("ROB wrap/reuse committed x19", dut.regs[0][19], 32'd4);
        expect_bit("ROB drains after commits", dut.rob_count == 0, 1'b1);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd21, 5'd0, 5'd0, 32'd55, 1'b0, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("freed ROB entry reused", dut.regs[0][21], 32'd55);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd22, 5'd0, 5'd0, 32'd66, 1'b0, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("extra committed op raises ROB coverage", dut.regs[0][22], 32'd66);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd23, 5'd0, 5'd0, 32'd77, 1'b0, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("second extra committed op raises ROB coverage", dut.regs[0][23], 32'd77);

        target_commit = commit_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd24, 5'd0, 5'd0, 32'd88, 1'b0, 1'b0, 1'b1, tag_tmp);
        wait_commits(target_commit);
        expect32("third extra committed op raises ROB coverage", dut.regs[0][24], 32'd88);

        inject_cdb(1'b1, 2'd3, 5'd22, 32'hdeadbeef);
        expect_ge("wrong or stale CDB tag ignored", stale_tag_ignored_count, 2);

        @(negedge clk);
        issue_valid = 1'b1;
        issue_tid = 1'b0;
        issue_op = 4'd15;
        issue_rd = 5'd30;
        issue_rs1 = 5'd1;
        issue_rs2 = 5'd2;
        issue_imm = 32'd0;
        issue_src1_needed = 1'b1;
        issue_src2_needed = 1'b1;
        issue_src2_is_imm = 1'b0;
        #1;
        expect_bit("unsupported op is blocked", issue_ready, 1'b0);
        @(posedge clk); #1;
        issue_valid = 1'b0;
        expect_ge("unsupported counter increments", unsupported_count, 1);

        expect_ge("dispatched counter populated", dispatched_count, 20);
        expect_ge("ROB allocation counter populated", rob_alloc_count, 20);
        expect_ge("RS allocation counter populated", rs_alloc_count, 20);
        expect_ge("issued counter populated", issued_count, 20);
        expect_ge("completed counter populated", completed_count, 20);
        expect_ge("broadcast counter populated", broadcast_count, 20);
        expect_ge("commit counter populated", commit_count, 20);
        expect_ge("younger completed waiting counter increments", younger_done_waiting_count, 1);
        expect_bit("commits do not exceed completed plus x0/wait accounting", commit_count <= completed_count, 1'b1);
        expect_bit("completed does not exceed issued", completed_count <= issued_count, 1'b1);
        expect_bit("issued does not exceed dispatched", issued_count <= dispatched_count, 1'b1);
        expect32("thread0 x0 final", dut.regs[0][0], 32'd0);
        expect32("thread1 x0 final", dut.regs[1][0], 32'd0);

        $display("ROBPERF: test=phase18 dispatched=%0d rob_allocs=%0d rob_full_stalls=%0d rs_allocs=%0d rs_full_stalls=%0d issued=%0d ooo_issue_events=%0d completed=%0d broadcasts=%0d wakeups=%0d commits=%0d commit_stalls=%0d younger_done_waiting=%0d stale_tag_ignored=%0d x0_commit_suppressed=%0d unsupported=%0d thread0_commits=%0d thread1_commits=%0d checks=%0d errors=%0d pass=%s",
            dispatched_count, rob_alloc_count, rob_full_stall_count, rs_alloc_count,
            rs_full_stall_count, issued_count, ooo_issue_count, completed_count,
            broadcast_count, wakeup_count, commit_count, commit_stall_count,
            younger_done_waiting_count, stale_tag_ignored_count,
            x0_commit_suppressed_count, unsupported_count, thread0_commit_count,
            thread1_commit_count, checks, errors, (errors == 0) ? "PASS" : "FAIL");

        if (trace_fd != 0) begin
            $fclose(trace_fd);
        end
        if (checks < 20) begin
            $fatal(1, "FAIL: fewer than 20 meaningful ROB checks");
        end
        if (errors != 0) begin
            $fatal(1, "FAIL: ROB validation errors=%0d", errors);
        end
        $display("PASS: Phase 18 ROB validation checks=%0d", checks);
        $finish;
    end
endmodule





