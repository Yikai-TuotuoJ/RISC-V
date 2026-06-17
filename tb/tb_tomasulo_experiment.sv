`timescale 1ns/1ps

module tb_tomasulo_experiment;
    localparam RS_ENTRIES = 4;
    localparam TAG_WIDTH = 8;
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
    logic [TAG_WIDTH-1:0] issue_dst_tag;
    logic debug_write_valid;
    logic debug_write_tid;
    logic [4:0] debug_write_rd;
    logic [31:0] debug_write_data;
    logic debug_set_busy_valid;
    logic debug_set_busy_tid;
    logic [4:0] debug_set_busy_rd;
    logic [TAG_WIDTH-1:0] debug_set_busy_tag;
    logic debug_cdb_valid;
    logic debug_cdb_tid;
    logic [4:0] debug_cdb_rd;
    logic [TAG_WIDTH-1:0] debug_cdb_tag;
    logic [31:0] debug_cdb_data;
    logic [31:0] accepted_count;
    logic [31:0] rs_alloc_count;
    logic [31:0] rs_full_stall_count;
    logic [31:0] ready_observed_count;
    logic [31:0] issued_count;
    logic [31:0] ooo_issue_count;
    logic [31:0] broadcast_count;
    logic [31:0] wakeup_count;
    logic [31:0] stale_tag_ignored_count;
    logic [31:0] completed_count;
    logic [31:0] unsupported_count;
    logic [31:0] thread0_accepted_count;
    logic [31:0] thread1_accepted_count;
    logic [31:0] thread0_issued_count;
    logic [31:0] thread1_issued_count;
    logic [31:0] thread0_completed_count;
    logic [31:0] thread1_completed_count;
    logic trace_alloc_valid;
    logic [$clog2(RS_ENTRIES)-1:0] trace_alloc_entry;
    logic [TAG_WIDTH-1:0] trace_alloc_tag;
    logic trace_issue_valid;
    logic [$clog2(RS_ENTRIES)-1:0] trace_issue_entry;
    logic [TAG_WIDTH-1:0] trace_issue_tag;
    logic trace_cdb_valid;
    logic [TAG_WIDTH-1:0] trace_cdb_tag;
    logic [4:0] trace_cdb_rd;
    logic [31:0] trace_cdb_data;
    logic [3:0] trace_wakeup_count;

    integer checks;
    integer errors;
    integer cycle;
    integer trace_fd;
    logic [TAG_WIDTH-1:0] tag_tmp;
    logic [TAG_WIDTH-1:0] tag_old;
    logic [TAG_WIDTH-1:0] tag_new;
    logic [TAG_WIDTH-1:0] tag_dep0;
    logic [TAG_WIDTH-1:0] tag_t0;
    logic [TAG_WIDTH-1:0] tag_t1;
    logic [31:0] target_completed;

    tomasulo_experiment_core #(
        .RS_ENTRIES(RS_ENTRIES),
        .TAG_WIDTH(TAG_WIDTH),
        .ALU_LATENCY(1)
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
        .issue_dst_tag(issue_dst_tag),
        .debug_write_valid(debug_write_valid),
        .debug_write_tid(debug_write_tid),
        .debug_write_rd(debug_write_rd),
        .debug_write_data(debug_write_data),
        .debug_set_busy_valid(debug_set_busy_valid),
        .debug_set_busy_tid(debug_set_busy_tid),
        .debug_set_busy_rd(debug_set_busy_rd),
        .debug_set_busy_tag(debug_set_busy_tag),
        .debug_cdb_valid(debug_cdb_valid),
        .debug_cdb_tid(debug_cdb_tid),
        .debug_cdb_rd(debug_cdb_rd),
        .debug_cdb_tag(debug_cdb_tag),
        .debug_cdb_data(debug_cdb_data),
        .accepted_count(accepted_count),
        .rs_alloc_count(rs_alloc_count),
        .rs_full_stall_count(rs_full_stall_count),
        .ready_observed_count(ready_observed_count),
        .issued_count(issued_count),
        .ooo_issue_count(ooo_issue_count),
        .broadcast_count(broadcast_count),
        .wakeup_count(wakeup_count),
        .stale_tag_ignored_count(stale_tag_ignored_count),
        .completed_count(completed_count),
        .unsupported_count(unsupported_count),
        .thread0_accepted_count(thread0_accepted_count),
        .thread1_accepted_count(thread1_accepted_count),
        .thread0_issued_count(thread0_issued_count),
        .thread1_issued_count(thread1_issued_count),
        .thread0_completed_count(thread0_completed_count),
        .thread1_completed_count(thread1_completed_count),
        .trace_alloc_valid(trace_alloc_valid),
        .trace_alloc_entry(trace_alloc_entry),
        .trace_alloc_tag(trace_alloc_tag),
        .trace_issue_valid(trace_issue_valid),
        .trace_issue_entry(trace_issue_entry),
        .trace_issue_tag(trace_issue_tag),
        .trace_cdb_valid(trace_cdb_valid),
        .trace_cdb_tag(trace_cdb_tag),
        .trace_cdb_rd(trace_cdb_rd),
        .trace_cdb_data(trace_cdb_data),
        .trace_wakeup_count(trace_wakeup_count)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle = cycle + 1;
        #1;
        if (trace_fd != 0) begin
            if (trace_alloc_valid) begin
                $fdisplay(trace_fd,
                    "ALLOC: cycle=%0d entry=%0d tid=%0d op=%0d rd=x%0d tag=T%0d rs1=x%0d ready1=%0d rs2=x%0d ready2=%0d",
                    cycle, trace_alloc_entry, issue_tid, issue_op, issue_rd, trace_alloc_tag,
                    issue_rs1, dut.rs_q1_ready[trace_alloc_entry], issue_rs2,
                    dut.rs_q2_ready[trace_alloc_entry]);
            end
            if (trace_issue_valid) begin
                $fdisplay(trace_fd,
                    "ISSUE: cycle=%0d entry=%0d tag=T%0d reason=ready",
                    cycle, trace_issue_entry, trace_issue_tag);
            end
            if (trace_cdb_valid) begin
                $fdisplay(trace_fd,
                    "CDB: cycle=%0d tag=T%0d rd=x%0d data=%08x wake_sources=%0d",
                    cycle, trace_cdb_tag, trace_cdb_rd, trace_cdb_data, trace_wakeup_count);
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
            @(posedge clk);
            #1;
            debug_write_valid = 1'b0;
        end
    endtask

    task automatic debug_busy(input logic tid, input logic [4:0] rd, input logic [TAG_WIDTH-1:0] tag);
        begin
            @(negedge clk);
            debug_set_busy_valid = 1'b1;
            debug_set_busy_tid = tid;
            debug_set_busy_rd = rd;
            debug_set_busy_tag = tag;
            @(posedge clk);
            #1;
            debug_set_busy_valid = 1'b0;
        end
    endtask

    task automatic inject_cdb(
        input logic tid,
        input logic [4:0] rd,
        input logic [TAG_WIDTH-1:0] tag,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            debug_cdb_valid = 1'b1;
            debug_cdb_tid = tid;
            debug_cdb_rd = rd;
            debug_cdb_tag = tag;
            debug_cdb_data = data;
            @(posedge clk);
            #1;
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
            issue_imm = imm;
            issue_src1_needed = src1_needed;
            issue_src2_needed = src2_needed;
            issue_src2_is_imm = src2_is_imm;
            #1;
            if (!issue_ready) begin
                errors = errors + 1;
                $display("FAIL: issue unexpectedly blocked op=%0d rd=x%0d", op, rd);
            end
            tag = issue_dst_tag;
            @(posedge clk);
            #1;
            issue_valid = 1'b0;
        end
    endtask

    task automatic expect_issue_blocked(
        input logic tid,
        input logic [3:0] op,
        input logic [4:0] rd,
        input logic [4:0] rs1,
        input logic [4:0] rs2
    );
        begin
            @(negedge clk);
            issue_valid = 1'b1;
            issue_tid = tid;
            issue_op = op;
            issue_rd = rd;
            issue_rs1 = rs1;
            issue_rs2 = rs2;
            issue_imm = 32'd0;
            issue_src1_needed = 1'b1;
            issue_src2_needed = 1'b1;
            issue_src2_is_imm = 1'b0;
            #1;
            expect_bit("issue blocked when reservation stations are full", issue_ready, 1'b0);
            @(posedge clk);
            #1;
            issue_valid = 1'b0;
        end
    endtask

    task automatic wait_completed(input logic [31:0] target);
        integer timeout;
        begin
            timeout = 0;
            while ((completed_count < target) && (timeout < 200)) begin
                @(posedge clk);
                #1;
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
        debug_set_busy_valid = 1'b0;
        debug_set_busy_tid = 1'b0;
        debug_set_busy_rd = 5'd0;
        debug_set_busy_tag = '0;
        debug_cdb_valid = 1'b0;
        debug_cdb_tid = 1'b0;
        debug_cdb_rd = 5'd0;
        debug_cdb_tag = '0;
        debug_cdb_data = 32'd0;
        checks = 0;
        errors = 0;
        cycle = 0;
        trace_fd = $fopen("reports/sim/tomasulo_trace.log", "w");
        $dumpfile("sim/phase17_tomasulo.vcd");
        $dumpvars(0, tb_tomasulo_experiment);

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        expect32("thread0 x0 reset", dut.regs[0][0], 32'd0);
        expect32("thread1 x0 reset", dut.regs[1][0], 32'd0);
        expect_bit("thread0 x0 not busy", dut.reg_busy[0][0], 1'b0);
        expect_bit("thread1 x0 not busy", dut.reg_busy[1][0], 1'b0);

        debug_write(1'b0, 5'd1, 32'd5);
        debug_write(1'b0, 5'd2, 32'd7);
        debug_write(1'b0, 5'd3, 32'h0000f0f0);
        debug_write(1'b0, 5'd4, 32'h00000ff0);
        debug_write(1'b1, 5'd1, 32'd10);
        debug_write(1'b1, 5'd2, 32'd3);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADD, 5'd5, 5'd1, 5'd2, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        expect_bit("destination busy after ADD allocation", dut.reg_busy[0][5], 1'b1);
        wait_completed(target_completed);
        expect32("ADD result", dut.regs[0][5], 32'd12);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_SUB, 5'd6, 5'd2, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_completed(target_completed);
        expect32("SUB result", dut.regs[0][6], 32'd2);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_AND, 5'd7, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_completed(target_completed);
        expect32("AND result", dut.regs[0][7], 32'h000000f0);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_OR, 5'd8, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_completed(target_completed);
        expect32("OR result", dut.regs[0][8], 32'h0000fff0);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_XOR, 5'd9, 5'd3, 5'd4, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        wait_completed(target_completed);
        expect32("XOR result", dut.regs[0][9], 32'h0000ff00);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd10, 5'd1, 5'd0, 32'd9, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_completed(target_completed);
        expect32("ADDI result", dut.regs[0][10], 32'd14);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd0, 5'd1, 5'd0, 32'd99, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_completed(target_completed);
        expect32("x0 write ignored", dut.regs[0][0], 32'd0);
        expect_bit("x0 never busy after write attempt", dut.reg_busy[0][0], 1'b0);

        debug_busy(1'b0, 5'd20, 8'haa);
        issue_uop(1'b0, OP_ADD, 5'd11, 5'd20, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_dep0);
        expect_bit("older dependency waits on source tag", dut.rs_q1_ready[0], 1'b0);
        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd12, 5'd1, 5'd0, 32'd21, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_completed(target_completed);
        expect32("younger independent issued before older waiting", dut.regs[0][12], 32'd26);
        expect_ge("out-of-order issue counter increments", ooo_issue_count, 1);
        inject_cdb(1'b0, 5'd20, 8'haa, 32'd3);
        target_completed = completed_count + 1;
        wait_completed(target_completed);
        expect32("older dependent wakes and completes", dut.regs[0][11], 32'd8);

        debug_busy(1'b0, 5'd21, 8'hbb);
        issue_uop(1'b0, OP_ADD, 5'd14, 5'd21, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_old);
        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd14, 5'd1, 5'd0, 32'd96, 1'b1, 1'b0, 1'b1, tag_new);
        wait_completed(target_completed);
        expect32("newer same-rd writer wins initially", dut.regs[0][14], 32'd101);
        inject_cdb(1'b0, 5'd21, 8'hbb, 32'd4);
        target_completed = completed_count + 1;
        wait_completed(target_completed);
        expect32("stale older writer cannot clobber latest rd", dut.regs[0][14], 32'd101);
        expect_ge("stale-tag ignored counter increments", stale_tag_ignored_count, 1);

        target_completed = completed_count + 1;
        issue_uop(1'b1, OP_ADD, 5'd5, 5'd1, 5'd2, 32'd0, 1'b1, 1'b1, 1'b0, tag_t1);
        wait_completed(target_completed);
        expect32("thread1 ADD uses thread1 register bank", dut.regs[1][5], 32'd13);
        expect32("thread0 x5 remains independent", dut.regs[0][5], 32'd12);

        debug_busy(1'b0, 5'd22, 8'hcc);
        issue_uop(1'b0, OP_ADD, 5'd15, 5'd22, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_t0);
        target_completed = completed_count + 1;
        issue_uop(1'b1, OP_ADDI, 5'd15, 5'd22, 5'd0, 32'd1, 1'b1, 1'b0, 1'b1, tag_t1);
        expect_bit("thread0 waits on thread0 x22", dut.rs_q1_ready[0], 1'b0);
        expect_bit("thread1 same register number does not wait", dut.rs_q1_ready[1], 1'b1);
        wait_completed(target_completed);
        inject_cdb(1'b1, 5'd22, 8'hcc, 32'd44);
        expect_bit("wrong-thread CDB does not wake thread0", dut.rs_q1_ready[0], 1'b0);
        inject_cdb(1'b0, 5'd22, 8'hcc, 32'd6);
        target_completed = completed_count + 1;
        wait_completed(target_completed);
        expect32("thread0 wakes from matching CDB", dut.regs[0][15], 32'd11);
        expect32("thread1 result independent", dut.regs[1][15], 32'd1);

        debug_busy(1'b0, 5'd23, 8'hdd);
        issue_uop(1'b0, OP_ADD, 5'd24, 5'd23, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        issue_uop(1'b0, OP_ADD, 5'd25, 5'd23, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        issue_uop(1'b0, OP_ADD, 5'd26, 5'd23, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        issue_uop(1'b0, OP_ADD, 5'd27, 5'd23, 5'd1, 32'd0, 1'b1, 1'b1, 1'b0, tag_tmp);
        expect_bit("all reservation stations valid", dut.rs_valid[0] & dut.rs_valid[1] & dut.rs_valid[2] & dut.rs_valid[3], 1'b1);
        expect_issue_blocked(1'b0, OP_ADD, 5'd28, 5'd1, 5'd2);
        expect_ge("RS full stall counter increments", rs_full_stall_count, 1);
        inject_cdb(1'b0, 5'd23, 8'hdd, 32'd2);
        target_completed = completed_count + 4;
        wait_completed(target_completed);
        expect32("freed RS entries drain after wake", dut.regs[0][27], 32'd7);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd28, 5'd1, 5'd0, 32'd1, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_completed(target_completed);
        expect32("freed RS entry reused", dut.regs[0][28], 32'd6);

        target_completed = completed_count + 1;
        issue_uop(1'b0, OP_ADDI, 5'd29, 5'd2, 5'd0, 32'd5, 1'b1, 1'b0, 1'b1, tag_tmp);
        wait_completed(target_completed);
        expect32("additional ADDI keeps counter coverage healthy", dut.regs[0][29], 32'd12);

        @(negedge clk);
        issue_valid = 1'b1;
        issue_tid = 1'b0;
        issue_op = 4'd15;
        issue_rd = 5'd30;
        #1;
        expect_bit("unsupported op is not ready to allocate", issue_ready, 1'b0);
        @(posedge clk);
        #1;
        issue_valid = 1'b0;
        expect_ge("unsupported counter increments", unsupported_count, 1);

        expect_ge("accepted counter populated", accepted_count, 20);
        expect_ge("RS allocation counter populated", rs_alloc_count, 20);
        expect_ge("ready-observed counter populated", ready_observed_count, 10);
        expect_ge("issued counter populated", issued_count, 20);
        expect_ge("broadcast counter populated", broadcast_count, 20);
        expect_ge("wakeup counter populated", wakeup_count, 6);
        expect_ge("completed counter populated", completed_count, 20);
        expect_ge("thread0 accepted counter populated", thread0_accepted_count, 18);
        expect_ge("thread1 accepted counter populated", thread1_accepted_count, 2);
        expect_ge("thread0 issued counter populated", thread0_issued_count, 18);
        expect_ge("thread1 issued counter populated", thread1_issued_count, 2);
        expect_ge("thread0 completed counter populated", thread0_completed_count, 18);
        expect_ge("thread1 completed counter populated", thread1_completed_count, 2);
        expect_bit("issued count does not exceed accepted", issued_count <= accepted_count, 1'b1);
        expect_bit("completed count does not exceed issued", completed_count <= issued_count, 1'b1);
        expect32("thread0 x0 final", dut.regs[0][0], 32'd0);
        expect32("thread1 x0 final", dut.regs[1][0], 32'd0);

        $display("TOMPERF: test=phase17 accepted=%0d rs_allocs=%0d rs_full_stalls=%0d ready_observed=%0d issued=%0d ooo_issue_events=%0d broadcasts=%0d wakeups=%0d stale_tag_ignored=%0d completed=%0d unsupported=%0d thread0_accepted=%0d thread1_accepted=%0d thread0_issued=%0d thread1_issued=%0d thread0_completed=%0d thread1_completed=%0d checks=%0d errors=%0d pass=%s",
            accepted_count, rs_alloc_count, rs_full_stall_count, ready_observed_count,
            issued_count, ooo_issue_count, broadcast_count, wakeup_count,
            stale_tag_ignored_count, completed_count, unsupported_count,
            thread0_accepted_count, thread1_accepted_count, thread0_issued_count,
            thread1_issued_count, thread0_completed_count, thread1_completed_count,
            checks, errors, (errors == 0) ? "PASS" : "FAIL");

        if (trace_fd != 0) begin
            $fclose(trace_fd);
        end
        if (checks < 20) begin
            $fatal(1, "FAIL: fewer than 20 meaningful Tomasulo checks");
        end
        if (errors != 0) begin
            $fatal(1, "FAIL: Tomasulo validation errors=%0d", errors);
        end
        $display("PASS: Phase 17 Tomasulo-style validation checks=%0d", checks);
        $finish;
    end
endmodule
