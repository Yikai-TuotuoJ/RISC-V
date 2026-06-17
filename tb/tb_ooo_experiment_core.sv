`timescale 1ns/1ps

module tb_ooo_experiment_core;
    localparam ROB_ENTRIES = 8;
    localparam RS_ENTRIES = 4;
    localparam LSQ_ENTRIES = 4;
    localparam ROBW = $clog2(ROB_ENTRIES);
    localparam RSW = $clog2(RS_ENTRIES);
    localparam LSQW = $clog2(LSQ_ENTRIES);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;
    localparam OP_LW   = 4'd6;
    localparam OP_SW   = 4'd7;

    logic clk, rst_n;
    logic issue_valid;
    logic [3:0] issue_op;
    logic [4:0] issue_rd, issue_rs1, issue_rs2;
    logic [31:0] issue_imm;
    logic issue_ready;
    logic [ROBW-1:0] issue_rob_tag;
    logic debug_write_valid;
    logic [4:0] debug_write_rd;
    logic [31:0] debug_write_data;
    logic debug_mem_write_valid;
    logic [31:0] debug_mem_write_addr, debug_mem_write_data;
    logic debug_set_status_valid;
    logic [4:0] debug_set_status_rd;
    logic [ROBW-1:0] debug_set_status_tag;
    logic debug_cdb_valid;
    logic [ROBW-1:0] debug_cdb_rob_tag;
    logic [4:0] debug_cdb_rd;
    logic [31:0] debug_cdb_data;

    logic [31:0] decoded_count, dispatched_count, rob_alloc_count, rob_full_stall_count;
    logic [31:0] rs_alloc_count, rs_full_stall_count, lsq_alloc_count, lsq_full_stall_count;
    logic [31:0] alu_issue_count, load_issue_count, store_commit_count, cdb_broadcast_count;
    logic [31:0] wakeup_count, completed_count, rob_commit_count, commit_stall_count;
    logic [31:0] younger_done_waiting_count, memory_order_stall_count, stale_tag_ignored_count;
    logic [31:0] x0_commit_suppressed_count, unsupported_count;

    logic trace_dispatch_valid;
    logic [ROBW-1:0] trace_dispatch_rob;
    logic [RSW-1:0] trace_dispatch_rs;
    logic [LSQW-1:0] trace_dispatch_lsq;
    logic [3:0] trace_dispatch_op;
    logic trace_issue_valid;
    logic [RSW-1:0] trace_issue_rs;
    logic [ROBW-1:0] trace_issue_rob;
    logic [3:0] trace_issue_op;
    logic trace_cdb_valid;
    logic [ROBW-1:0] trace_cdb_rob;
    logic [31:0] trace_cdb_data;
    logic [3:0] trace_wakeup_count;
    logic trace_lsq_alloc_valid;
    logic [LSQW-1:0] trace_lsq_alloc_entry;
    logic trace_lsq_alloc_is_load;
    logic trace_load_exec_valid;
    logic [LSQW-1:0] trace_load_exec_entry;
    logic [31:0] trace_load_exec_addr, trace_load_exec_data;
    logic trace_store_commit_valid;
    logic [LSQW-1:0] trace_store_commit_entry;
    logic [31:0] trace_store_commit_addr, trace_store_commit_data;
    logic trace_mem_order_stall;
    logic trace_commit_valid;
    logic [ROBW-1:0] trace_commit_rob;
    logic [4:0] trace_commit_rd;
    logic [31:0] trace_commit_data;
    logic trace_commit_is_store, trace_commit_stall;

    integer checks, errors, cycle, trace_fd, before_count;

    ooo_experiment_core #(
        .ROB_ENTRIES(ROB_ENTRIES), .RS_ENTRIES(RS_ENTRIES), .LSQ_ENTRIES(LSQ_ENTRIES), .MEM_WORDS(256)
    ) dut (.*);

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle = cycle + 1;
        #1;
        if (trace_fd != 0) begin
            if (trace_dispatch_valid) $fdisplay(trace_fd, "DISPATCH: cycle=%0d rob=R%0d rs=%0d lsq=%0d op=%0d", cycle, trace_dispatch_rob, trace_dispatch_rs, trace_dispatch_lsq, trace_dispatch_op);
            if (trace_issue_valid) $fdisplay(trace_fd, "ISSUE: cycle=%0d rs=%0d rob=R%0d op=%0d reason=ready", cycle, trace_issue_rs, trace_issue_rob, trace_issue_op);
            if (trace_cdb_valid) $fdisplay(trace_fd, "CDB: cycle=%0d rob=R%0d data=%08x wake_entries=%0d rob_ready=1", cycle, trace_cdb_rob, trace_cdb_data, trace_wakeup_count);
            if (trace_lsq_alloc_valid) $fdisplay(trace_fd, "LSQ_ALLOC: cycle=%0d entry=%0d type=%s", cycle, trace_lsq_alloc_entry, trace_lsq_alloc_is_load ? "LOAD" : "STORE");
            if (trace_mem_order_stall) $fdisplay(trace_fd, "MEM_ORDER_STALL: cycle=%0d reason=older_unresolved_store", cycle);
            if (trace_load_exec_valid) $fdisplay(trace_fd, "LOAD_EXEC: cycle=%0d entry=%0d addr=%08x data=%08x", cycle, trace_load_exec_entry, trace_load_exec_addr, trace_load_exec_data);
            if (trace_store_commit_valid) $fdisplay(trace_fd, "STORE_COMMIT: cycle=%0d entry=%0d addr=%08x data=%08x", cycle, trace_store_commit_entry, trace_store_commit_addr, trace_store_commit_data);
            if (trace_commit_stall) $fdisplay(trace_fd, "COMMIT_STALL: cycle=%0d reason=head_not_ready", cycle);
            if (trace_commit_valid) $fdisplay(trace_fd, "COMMIT: cycle=%0d rob=R%0d rd=x%0d data=%08x store=%0d", cycle, trace_commit_rob, trace_commit_rd, trace_commit_data, trace_commit_is_store);
        end
    end

    task automatic expect32(input string name, input logic [31:0] actual, input logic [31:0] expected);
        begin checks++; if (actual !== expected) begin errors++; $display("FAIL: %s actual=%08x expected=%08x", name, actual, expected); end else $display("PASS: %s = %08x", name, actual); end
    endtask
    task automatic expect_bit(input string name, input logic actual, input logic expected);
        begin checks++; if (actual !== expected) begin errors++; $display("FAIL: %s actual=%b expected=%b", name, actual, expected); end else $display("PASS: %s", name); end
    endtask
    task automatic expect_ge(input string name, input integer actual, input integer expected_min);
        begin checks++; if (actual < expected_min) begin errors++; $display("FAIL: %s actual=%0d expected_min=%0d", name, actual, expected_min); end else $display("PASS: %s actual=%0d", name, actual); end
    endtask

    task automatic init_inputs;
        begin
            issue_valid=0; issue_op=0; issue_rd=0; issue_rs1=0; issue_rs2=0; issue_imm=0;
            debug_write_valid=0; debug_write_rd=0; debug_write_data=0; debug_mem_write_valid=0; debug_mem_write_addr=0; debug_mem_write_data=0;
            debug_set_status_valid=0; debug_set_status_rd=0; debug_set_status_tag=0; debug_cdb_valid=0; debug_cdb_rob_tag=0; debug_cdb_rd=0; debug_cdb_data=0;
        end
    endtask
    task automatic wait_cycles(input integer n); begin repeat(n) @(negedge clk); end endtask
    task automatic write_reg(input logic [4:0] rd, input logic [31:0] data); begin @(negedge clk); debug_write_valid=1; debug_write_rd=rd; debug_write_data=data; @(negedge clk); debug_write_valid=0; end endtask
    task automatic write_mem(input logic [31:0] addr, input logic [31:0] data); begin @(negedge clk); debug_mem_write_valid=1; debug_mem_write_addr=addr; debug_mem_write_data=data; @(negedge clk); debug_mem_write_valid=0; end endtask
    task automatic set_busy(input logic [4:0] rd, input logic [ROBW-1:0] tag); begin @(negedge clk); debug_set_status_valid=1; debug_set_status_rd=rd; debug_set_status_tag=tag; @(negedge clk); debug_set_status_valid=0; end endtask
    task automatic cdb(input logic [ROBW-1:0] tag, input logic [4:0] rd, input logic [31:0] data); begin @(negedge clk); debug_cdb_valid=1; debug_cdb_rob_tag=tag; debug_cdb_rd=rd; debug_cdb_data=data; @(negedge clk); debug_cdb_valid=0; end endtask
    task automatic issue(input logic [3:0] op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2, input logic [31:0] imm); begin @(negedge clk); issue_valid=1; issue_op=op; issue_rd=rd; issue_rs1=rs1; issue_rs2=rs2; issue_imm=imm; @(negedge clk); issue_valid=0; issue_op=0; issue_rd=0; issue_rs1=0; issue_rs2=0; issue_imm=0; end endtask
    task automatic wait_commits(input integer target, input integer timeout); integer waited; begin waited=0; while ((rob_commit_count < target) && (waited < timeout)) begin wait_cycles(1); waited++; end expect_ge("commit target reached", rob_commit_count, target); end endtask

    initial begin
        clk=0; rst_n=0; checks=0; errors=0; cycle=0; trace_fd=0; init_inputs();
        trace_fd = $fopen("reports/sim/ooo_trace.log", "w");
        $dumpfile("sim/phase20_ooo.vcd");
        $dumpvars(0, tb_ooo_experiment_core);
        repeat(5) @(negedge clk); rst_n=1; wait_cycles(2);

        write_reg(5'd1, 32'h100); write_reg(5'd2, 32'd5); write_reg(5'd3, 32'd7); write_reg(5'd4, 32'hf0f0); write_reg(5'd5, 32'h0ff0);
        write_mem(32'h100, 32'h11111111); write_mem(32'h104, 32'h22222222); write_mem(32'h108, 32'h33333333); write_mem(32'h110, 32'h44444444);
        expect32("x0 reset", dut.regs[0], 32'd0);

        issue(OP_ADDI, 5'd10, 5'd0, 5'd0, 32'd9); wait_commits(1, 20); expect32("ADDI committed", dut.regs[10], 32'd9);
        issue(OP_ADD, 5'd11, 5'd2, 5'd3, 0); wait_commits(2, 20); expect32("ADD committed", dut.regs[11], 32'd12);
        issue(OP_SUB, 5'd12, 5'd3, 5'd2, 0); wait_commits(3, 20); expect32("SUB committed", dut.regs[12], 32'd2);
        issue(OP_AND, 5'd13, 5'd4, 5'd5, 0); wait_commits(4, 20); expect32("AND committed", dut.regs[13], 32'h00f0);
        issue(OP_OR, 5'd14, 5'd4, 5'd5, 0); wait_commits(5, 20); expect32("OR committed", dut.regs[14], 32'hfff0);
        issue(OP_XOR, 5'd15, 5'd4, 5'd5, 0); wait_commits(6, 20); expect32("XOR committed", dut.regs[15], 32'hff00);
        issue(OP_ADDI, 5'd0, 5'd0, 5'd0, 32'd55); wait_commits(7, 20); expect32("x0 commit suppressed", dut.regs[0], 32'd0); expect_ge("x0 suppression counter", x0_commit_suppressed_count, 1);

        set_busy(5'd20, 3'd6);
        issue(OP_ADD, 5'd21, 5'd20, 5'd2, 0);
        issue(OP_ADDI, 5'd22, 5'd0, 5'd0, 32'd26);
        wait_cycles(6);
        expect32("younger completed before older cannot commit", dut.regs[22], 32'd0);
        expect_ge("commit stall while older waits", commit_stall_count, 1);
        expect_ge("younger-ready waiting counted", younger_done_waiting_count, 1);
        expect_ge("out-of-order issue observed", alu_issue_count, 8);
        cdb(3'd6, 5'd20, 32'd3);
        wait_commits(9, 40);
        expect32("older woken result commits", dut.regs[21], 32'd8);
        expect32("younger commits after older", dut.regs[22], 32'd26);
        expect_ge("wakeup counter after CDB", wakeup_count, 1);

        issue(OP_ADDI, 5'd23, 5'd0, 5'd0, 32'd1);
        issue(OP_ADDI, 5'd23, 5'd0, 5'd0, 32'd2);
        wait_commits(11, 40);
        expect32("newer producer wins final value", dut.regs[23], 32'd2);
        expect_ge("stale tag handling available", stale_tag_ignored_count, 1);

        issue(OP_LW, 5'd24, 5'd1, 5'd0, 32'd0); wait_commits(12, 30); expect32("load ready address commits", dut.regs[24], 32'h11111111);
        issue(OP_SW, 5'd0, 5'd1, 5'd2, 32'd4); wait_commits(13, 30); expect32("store writes at commit", dut.mem[65], 32'd5);
        issue(OP_LW, 5'd25, 5'd1, 5'd0, 32'd4); wait_commits(14, 30); expect32("load sees committed store", dut.regs[25], 32'd5);

        set_busy(5'd26, 3'd7);
        before_count = memory_order_stall_count;
        issue(OP_SW, 5'd0, 5'd1, 5'd26, 32'd16);
        issue(OP_LW, 5'd27, 5'd1, 5'd0, 32'd16);
        wait_cycles(6);
        expect_ge("younger load waits behind older unresolved store", memory_order_stall_count, before_count + 1);
        expect32("younger load not committed early", dut.regs[27], 32'd0);
        cdb(3'd7, 5'd26, 32'habc);
        wait_commits(16, 60);
        expect32("store data commits to memory", dut.mem[68], 32'habc);
        expect32("younger load gets stored data", dut.regs[27], 32'habc);

        set_busy(5'd28, 3'd7);
        issue(OP_LW, 5'd29, 5'd28, 5'd0, 32'd8);
        wait_cycles(4); expect_bit("load address waits on tag", dut.lsq_addr_ready[0], 1'b0);
        cdb(3'd4, 5'd28, 32'h100); wait_cycles(1); expect_bit("wrong tag does not wake LSQ address", dut.lsq_addr_ready[0], 1'b0);
        cdb(3'd7, 5'd28, 32'h100); wait_commits(17, 40); expect32("load address wakes by CDB", dut.regs[29], 32'h33333333);

        set_busy(5'd30, 3'd6);
        issue(OP_SW, 5'd0, 5'd1, 5'd30, 32'd20); wait_cycles(5); expect_bit("store waits for data", dut.lsq_data_ready[0], 1'b0);
        cdb(3'd6, 5'd30, 32'h7777); wait_commits(18, 40); expect32("store data wakes and commits", dut.mem[69], 32'h7777);

        set_busy(5'd31, 3'd6);
        issue(OP_ADD, 5'd16, 5'd31, 5'd2, 0); issue(OP_ADD, 5'd17, 5'd31, 5'd3, 0); cdb(3'd6, 5'd31, 32'd10); wait_commits(20, 60);
        expect32("multi-waiter wake result A", dut.regs[16], 32'd15); expect32("multi-waiter wake result B", dut.regs[17], 32'd17);

        before_count = rs_full_stall_count;
        set_busy(5'd18, 3'd6);
        issue(OP_ADD, 5'd6, 5'd18, 5'd2, 0); issue(OP_ADD, 5'd7, 5'd18, 5'd2, 0); issue(OP_ADD, 5'd8, 5'd18, 5'd2, 0); issue(OP_ADD, 5'd9, 5'd18, 5'd2, 0); issue(OP_ADD, 5'd10, 5'd18, 5'd2, 0);
        wait_cycles(2); expect_ge("RS full stall counted", rs_full_stall_count, before_count + 1); cdb(3'd6, 5'd18, 32'd1); wait_commits(24, 100);

        before_count = lsq_full_stall_count;
        set_busy(5'd19, 3'd7);
        issue(OP_SW, 5'd0, 5'd19, 5'd2, 0); issue(OP_SW, 5'd0, 5'd19, 5'd2, 4); issue(OP_SW, 5'd0, 5'd19, 5'd2, 8); issue(OP_SW, 5'd0, 5'd19, 5'd2, 12); issue(OP_LW, 5'd18, 5'd1, 5'd0, 0);
        wait_cycles(2); expect_ge("LSQ full stall counted", lsq_full_stall_count, before_count + 1); cdb(3'd7, 5'd19, 32'h120); wait_commits(28, 120);

        issue(4'd15, 5'd18, 5'd0, 5'd0, 0); wait_cycles(2); expect_ge("unsupported counted", unsupported_count, 1);
        expect_ge("decoded populated", decoded_count, 30); expect_ge("dispatched populated", dispatched_count, 28); expect_ge("ROB allocs populated", rob_alloc_count, 28);
        expect_ge("RS allocs populated", rs_alloc_count, 15); expect_ge("LSQ allocs populated", lsq_alloc_count, 8); expect_ge("ALU issues populated", alu_issue_count, 15);
        expect_ge("load issues populated", load_issue_count, 4); expect_ge("store commits populated", store_commit_count, 6); expect_ge("CDB broadcasts populated", cdb_broadcast_count, 20);
        expect_ge("commits populated", rob_commit_count, 28); expect_ge("completed populated", completed_count, 20); expect_ge("memory order stalls populated", memory_order_stall_count, 1);
        expect_ge("stale tags populated", stale_tag_ignored_count, 1); expect_bit("rob entry0 drained", dut.rob_valid[0], 1'b0); expect_bit("rob entry1 drained", dut.rob_valid[1], 1'b0); expect_bit("rob entry2 drained", dut.rob_valid[2], 1'b0); expect_bit("rob entry3 drained", dut.rob_valid[3], 1'b0); expect_bit("rob entry4 drained", dut.rob_valid[4], 1'b0); expect_bit("rob entry5 drained", dut.rob_valid[5], 1'b0); expect_bit("rob entry6 drained", dut.rob_valid[6], 1'b0); expect_bit("rob entry7 drained", dut.rob_valid[7], 1'b0); expect32("x0 final", dut.regs[0], 32'd0);

        $display("OOOPERF: test=phase20_ooo decoded=%0d dispatched=%0d rob_allocs=%0d rob_full_stalls=%0d rs_allocs=%0d rs_full_stalls=%0d lsq_allocs=%0d lsq_full_stalls=%0d alu_issues=%0d load_issues=%0d store_commits=%0d broadcasts=%0d wakeups=%0d completed=%0d commits=%0d commit_stalls=%0d memory_order_stalls=%0d younger_done_waiting=%0d stale_tag_ignored=%0d x0_commit_suppressed=%0d unsupported=%0d checks=%0d errors=%0d pass=%s",
                 decoded_count, dispatched_count, rob_alloc_count, rob_full_stall_count, rs_alloc_count, rs_full_stall_count, lsq_alloc_count, lsq_full_stall_count,
                 alu_issue_count, load_issue_count, store_commit_count, cdb_broadcast_count, wakeup_count, completed_count, rob_commit_count, commit_stall_count,
                 memory_order_stall_count, younger_done_waiting_count, stale_tag_ignored_count, x0_commit_suppressed_count, unsupported_count, checks, errors,
                 (errors == 0 && checks >= 30) ? "PASS" : "FAIL");
        if (trace_fd != 0) $fclose(trace_fd);
        if (errors == 0 && checks >= 30) begin $display("PASS: Phase 20 integrated OOO validation checks=%0d", checks); $finish; end
        $fatal(1, "FAIL: Phase 20 integrated OOO validation errors=%0d checks=%0d", errors, checks);
    end
endmodule



