`timescale 1ns/1ps

module tb_lsq_experiment;
    localparam ROB_ENTRIES = 8;
    localparam LSQ_ENTRIES = 4;
    localparam ROB_TAG_WIDTH = $clog2(ROB_ENTRIES);
    localparam LSQ_INDEX_WIDTH = $clog2(LSQ_ENTRIES);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_ADDI = 4'd5;
    localparam OP_LW   = 4'd6;
    localparam OP_SW   = 4'd7;

    logic clk;
    logic rst_n;
    logic issue_valid;
    logic issue_tid;
    logic [3:0] issue_op;
    logic [4:0] issue_rd;
    logic [4:0] issue_rs1;
    logic [4:0] issue_rs2;
    logic [31:0] issue_imm;
    logic issue_ready;
    logic [ROB_TAG_WIDTH-1:0] issue_rob_tag;
    logic debug_write_valid;
    logic debug_write_tid;
    logic [4:0] debug_write_rd;
    logic [31:0] debug_write_data;
    logic debug_mem_write_valid;
    logic [31:0] debug_mem_write_addr;
    logic [31:0] debug_mem_write_data;
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
    logic [31:0] rob_commit_count;
    logic [31:0] rob_commit_stall_count;
    logic [31:0] alu_complete_count;
    logic [31:0] memory_uop_count;
    logic [31:0] loads_alloc_count;
    logic [31:0] stores_alloc_count;
    logic [31:0] lsq_full_stall_count;
    logic [31:0] loads_wait_addr_count;
    logic [31:0] stores_wait_addr_count;
    logic [31:0] stores_wait_data_count;
    logic [31:0] load_store_order_stall_count;
    logic [31:0] conservative_order_stall_count;
    logic [31:0] load_exec_count;
    logic [31:0] load_complete_count;
    logic [31:0] store_commit_count;
    logic [31:0] store_complete_count;
    logic [31:0] stale_tag_ignored_count;
    logic [31:0] x0_commit_suppressed_count;
    logic [31:0] unsupported_count;

    logic trace_lsq_alloc_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_lsq_alloc_entry;
    logic trace_lsq_alloc_is_load;
    logic [ROB_TAG_WIDTH-1:0] trace_lsq_alloc_rob;
    logic trace_addr_ready_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_addr_ready_entry;
    logic [31:0] trace_addr_ready_value;
    logic trace_store_data_ready_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_store_data_ready_entry;
    logic [31:0] trace_store_data_value;
    logic trace_order_stall_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_order_stall_entry;
    logic trace_load_exec_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_load_exec_entry;
    logic [ROB_TAG_WIDTH-1:0] trace_load_exec_rob;
    logic [31:0] trace_load_exec_addr;
    logic [31:0] trace_load_exec_data;
    logic trace_store_commit_valid;
    logic [LSQ_INDEX_WIDTH-1:0] trace_store_commit_entry;
    logic [ROB_TAG_WIDTH-1:0] trace_store_commit_rob;
    logic [31:0] trace_store_commit_addr;
    logic [31:0] trace_store_commit_data;
    logic trace_commit_valid;
    logic [ROB_TAG_WIDTH-1:0] trace_commit_rob;
    logic [4:0] trace_commit_rd;
    logic [31:0] trace_commit_data;
    logic trace_commit_is_store;
    logic trace_commit_stall;

    integer checks;
    integer errors;
    integer cycle;
    integer trace_fd;
    integer before_count;
    integer after_count;
    integer idx;

    tomasulo_rob_lsq_experiment_core #(
        .ROB_ENTRIES(ROB_ENTRIES),
        .LSQ_ENTRIES(LSQ_ENTRIES),
        .MEM_WORDS(256)
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
        .issue_ready(issue_ready),
        .issue_rob_tag(issue_rob_tag),
        .debug_write_valid(debug_write_valid),
        .debug_write_tid(debug_write_tid),
        .debug_write_rd(debug_write_rd),
        .debug_write_data(debug_write_data),
        .debug_mem_write_valid(debug_mem_write_valid),
        .debug_mem_write_addr(debug_mem_write_addr),
        .debug_mem_write_data(debug_mem_write_data),
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
        .rob_commit_count(rob_commit_count),
        .rob_commit_stall_count(rob_commit_stall_count),
        .alu_complete_count(alu_complete_count),
        .memory_uop_count(memory_uop_count),
        .loads_alloc_count(loads_alloc_count),
        .stores_alloc_count(stores_alloc_count),
        .lsq_full_stall_count(lsq_full_stall_count),
        .loads_wait_addr_count(loads_wait_addr_count),
        .stores_wait_addr_count(stores_wait_addr_count),
        .stores_wait_data_count(stores_wait_data_count),
        .load_store_order_stall_count(load_store_order_stall_count),
        .conservative_order_stall_count(conservative_order_stall_count),
        .load_exec_count(load_exec_count),
        .load_complete_count(load_complete_count),
        .store_commit_count(store_commit_count),
        .store_complete_count(store_complete_count),
        .stale_tag_ignored_count(stale_tag_ignored_count),
        .x0_commit_suppressed_count(x0_commit_suppressed_count),
        .unsupported_count(unsupported_count),
        .trace_lsq_alloc_valid(trace_lsq_alloc_valid),
        .trace_lsq_alloc_entry(trace_lsq_alloc_entry),
        .trace_lsq_alloc_is_load(trace_lsq_alloc_is_load),
        .trace_lsq_alloc_rob(trace_lsq_alloc_rob),
        .trace_addr_ready_valid(trace_addr_ready_valid),
        .trace_addr_ready_entry(trace_addr_ready_entry),
        .trace_addr_ready_value(trace_addr_ready_value),
        .trace_store_data_ready_valid(trace_store_data_ready_valid),
        .trace_store_data_ready_entry(trace_store_data_ready_entry),
        .trace_store_data_value(trace_store_data_value),
        .trace_order_stall_valid(trace_order_stall_valid),
        .trace_order_stall_entry(trace_order_stall_entry),
        .trace_load_exec_valid(trace_load_exec_valid),
        .trace_load_exec_entry(trace_load_exec_entry),
        .trace_load_exec_rob(trace_load_exec_rob),
        .trace_load_exec_addr(trace_load_exec_addr),
        .trace_load_exec_data(trace_load_exec_data),
        .trace_store_commit_valid(trace_store_commit_valid),
        .trace_store_commit_entry(trace_store_commit_entry),
        .trace_store_commit_rob(trace_store_commit_rob),
        .trace_store_commit_addr(trace_store_commit_addr),
        .trace_store_commit_data(trace_store_commit_data),
        .trace_commit_valid(trace_commit_valid),
        .trace_commit_rob(trace_commit_rob),
        .trace_commit_rd(trace_commit_rd),
        .trace_commit_data(trace_commit_data),
        .trace_commit_is_store(trace_commit_is_store),
        .trace_commit_stall(trace_commit_stall)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle = cycle + 1;
        #1;
        if (trace_fd != 0) begin
            if (trace_lsq_alloc_valid) begin
                $fdisplay(trace_fd, "LSQ_ALLOC: cycle=%0d entry=%0d type=%s rob=R%0d", cycle, trace_lsq_alloc_entry, trace_lsq_alloc_is_load ? "LOAD" : "STORE", trace_lsq_alloc_rob);
            end
            if (trace_addr_ready_valid) begin
                $fdisplay(trace_fd, "ADDR_READY: cycle=%0d entry=%0d addr=%08x", cycle, trace_addr_ready_entry, trace_addr_ready_value);
            end
            if (trace_store_data_ready_valid) begin
                $fdisplay(trace_fd, "STORE_DATA_READY: cycle=%0d entry=%0d data=%08x", cycle, trace_store_data_ready_entry, trace_store_data_value);
            end
            if (trace_order_stall_valid) begin
                $fdisplay(trace_fd, "LOAD_WAIT: cycle=%0d entry=%0d reason=older_unresolved_store", cycle, trace_order_stall_entry);
            end
            if (trace_load_exec_valid) begin
                $fdisplay(trace_fd, "LOAD_EXEC: cycle=%0d entry=%0d rob=R%0d addr=%08x data=%08x", cycle, trace_load_exec_entry, trace_load_exec_rob, trace_load_exec_addr, trace_load_exec_data);
            end
            if (trace_store_commit_valid) begin
                $fdisplay(trace_fd, "STORE_COMMIT: cycle=%0d entry=%0d rob=R%0d addr=%08x data=%08x", cycle, trace_store_commit_entry, trace_store_commit_rob, trace_store_commit_addr, trace_store_commit_data);
            end
            if (trace_commit_stall) begin
                $fdisplay(trace_fd, "ROB_WAIT: cycle=%0d reason=head_not_committable", cycle);
            end
            if (trace_commit_valid) begin
                $fdisplay(trace_fd, "ROB_COMMIT: cycle=%0d rob=R%0d rd=x%0d data=%08x store=%0d", cycle, trace_commit_rob, trace_commit_rd, trace_commit_data, trace_commit_is_store);
            end
        end
    end

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

    task automatic init_inputs;
        begin
            issue_valid = 1'b0;
            issue_tid = 1'b0;
            issue_op = 4'd0;
            issue_rd = 5'd0;
            issue_rs1 = 5'd0;
            issue_rs2 = 5'd0;
            issue_imm = 32'd0;
            debug_write_valid = 1'b0;
            debug_write_tid = 1'b0;
            debug_write_rd = 5'd0;
            debug_write_data = 32'd0;
            debug_mem_write_valid = 1'b0;
            debug_mem_write_addr = 32'd0;
            debug_mem_write_data = 32'd0;
            debug_set_status_valid = 1'b0;
            debug_set_status_tid = 1'b0;
            debug_set_status_rd = 5'd0;
            debug_set_status_tag = '0;
            debug_cdb_valid = 1'b0;
            debug_cdb_tid = 1'b0;
            debug_cdb_rob_tag = '0;
            debug_cdb_rd = 5'd0;
            debug_cdb_data = 32'd0;
        end
    endtask

    task automatic write_reg(input logic [4:0] rd, input logic [31:0] data);
        begin
            @(negedge clk);
            debug_write_valid = 1'b1;
            debug_write_rd = rd;
            debug_write_data = data;
            @(negedge clk);
            debug_write_valid = 1'b0;
        end
    endtask

    task automatic write_mem(input logic [31:0] addr, input logic [31:0] data);
        begin
            @(negedge clk);
            debug_mem_write_valid = 1'b1;
            debug_mem_write_addr = addr;
            debug_mem_write_data = data;
            @(negedge clk);
            debug_mem_write_valid = 1'b0;
        end
    endtask

    task automatic set_busy(input logic [4:0] rd, input logic [ROB_TAG_WIDTH-1:0] tag);
        begin
            @(negedge clk);
            debug_set_status_valid = 1'b1;
            debug_set_status_rd = rd;
            debug_set_status_tag = tag;
            @(negedge clk);
            debug_set_status_valid = 1'b0;
        end
    endtask

    task automatic cdb(input logic [ROB_TAG_WIDTH-1:0] tag, input logic [4:0] rd, input logic [31:0] data);
        begin
            @(negedge clk);
            debug_cdb_valid = 1'b1;
            debug_cdb_rob_tag = tag;
            debug_cdb_rd = rd;
            debug_cdb_data = data;
            @(negedge clk);
            debug_cdb_valid = 1'b0;
        end
    endtask

    task automatic issue(input logic [3:0] op, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2, input logic [31:0] imm);
        begin
            @(negedge clk);
            issue_valid = 1'b1;
            issue_op = op;
            issue_rd = rd;
            issue_rs1 = rs1;
            issue_rs2 = rs2;
            issue_imm = imm;
            @(negedge clk);
            issue_valid = 1'b0;
            issue_op = 4'd0;
            issue_rd = 5'd0;
            issue_rs1 = 5'd0;
            issue_rs2 = 5'd0;
            issue_imm = 32'd0;
        end
    endtask

    task automatic wait_cycles(input integer count);
        begin
            repeat (count) @(negedge clk);
        end
    endtask

    task automatic wait_for_commits(input integer target, input integer timeout_cycles);
        integer waited;
        begin
            waited = 0;
            while ((rob_commit_count < target) && (waited < timeout_cycles)) begin
                wait_cycles(1);
                waited = waited + 1;
            end
            expect_ge("commit target reached", rob_commit_count, target);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        checks = 0;
        errors = 0;
        cycle = 0;
        trace_fd = 0;
        init_inputs();
        trace_fd = $fopen("reports/sim/lsq_trace.log", "w");
        $dumpfile("sim/phase19_lsq.vcd");
        $dumpvars(0, tb_lsq_experiment);
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        wait_cycles(2);

        write_reg(5'd1, 32'h0000_0100);
        write_reg(5'd2, 32'h0000_002a);
        write_reg(5'd3, 32'h0000_0200);
        write_reg(5'd4, 32'h0000_0063);
        write_mem(32'h0000_0100, 32'h1111_1111);
        write_mem(32'h0000_0104, 32'h2222_2222);
        write_mem(32'h0000_0108, 32'h3333_3333);
        write_mem(32'h0000_0110, 32'h4444_4444);
        write_mem(32'h0000_0120, 32'haaaa_aaaa);

        issue(OP_LW, 5'd5, 5'd1, 5'd0, 32'd0);
        wait_for_commits(1, 20);
        expect32("load ready-base result", dut.regs[0][5], 32'h1111_1111);
        expect_ge("one load allocated", loads_alloc_count, 1);
        expect_ge("load executed", load_exec_count, 1);

        issue(OP_SW, 5'd0, 5'd1, 5'd2, 32'd4);
        wait_for_commits(2, 20);
        expect32("store commits to memory", dut.mem[65], 32'h0000_002a);
        expect_ge("one store allocated", stores_alloc_count, 1);
        expect_ge("store committed", store_commit_count, 1);

        issue(OP_LW, 5'd6, 5'd1, 5'd0, 32'd4);
        wait_for_commits(3, 20);
        expect32("load sees committed store", dut.regs[0][6], 32'h0000_002a);

        set_busy(5'd10, 3'd7);
        before_count = loads_wait_addr_count;
        issue(OP_LW, 5'd7, 5'd10, 5'd0, 32'd8);
        wait_cycles(2);
        expect_bit("load address waits", dut.lsq_addr_ready[0], 1'b0);
        expect_ge("load address wait counted", loads_wait_addr_count, before_count + 1);
        before_count = stale_tag_ignored_count;
        cdb(3'd6, 5'd10, 32'h0000_0100);
        wait_cycles(1);
        expect_bit("wrong tag does not wake address", dut.lsq_addr_ready[0], 1'b0);
        expect_ge("wrong tag counted stale", stale_tag_ignored_count, before_count + 1);
        cdb(3'd7, 5'd10, 32'h0000_0100);
        wait_for_commits(4, 30);
        expect32("load address wakes and completes", dut.regs[0][7], 32'h3333_3333);

        set_busy(5'd11, 3'd6);
        before_count = stores_wait_data_count;
        issue(OP_SW, 5'd0, 5'd1, 5'd11, 32'd12);
        wait_cycles(4);
        expect_ge("store data wait counted", stores_wait_data_count, before_count + 1);
        expect32("store does not update before data ready", dut.mem[67], 32'd0);
        cdb(3'd5, 5'd11, 32'h0000_0055);
        wait_cycles(2);
        expect32("wrong tag does not update store data", dut.mem[67], 32'd0);
        cdb(3'd6, 5'd11, 32'h0000_0055);
        wait_for_commits(5, 30);
        expect32("store data wakes and commits", dut.mem[67], 32'h0000_0055);

        set_busy(5'd12, 3'd7);
        before_count = load_store_order_stall_count;
        issue(OP_SW, 5'd0, 5'd1, 5'd12, 32'd16);
        issue(OP_LW, 5'd8, 5'd1, 5'd0, 32'd16);
        wait_cycles(5);
        expect_ge("load waits behind older store", load_store_order_stall_count, before_count + 1);
        expect32("younger load has not bypassed store", dut.regs[0][8], 32'd0);
        cdb(3'd7, 5'd12, 32'h0000_0abc);
        wait_for_commits(7, 40);
        expect32("load after older store sees store data", dut.regs[0][8], 32'h0000_0abc);
        expect32("older store wrote memory", dut.mem[68], 32'h0000_0abc);

        set_busy(5'd13, 3'd7);
        before_count = lsq_full_stall_count;
        issue(OP_SW, 5'd0, 5'd13, 5'd2, 32'd0);
        issue(OP_SW, 5'd0, 5'd13, 5'd2, 32'd4);
        issue(OP_SW, 5'd0, 5'd13, 5'd2, 32'd8);
        issue(OP_SW, 5'd0, 5'd13, 5'd2, 32'd12);
        issue(OP_LW, 5'd9, 5'd1, 5'd0, 32'd0);
        wait_cycles(2);
        expect_ge("lsq full stall counted", lsq_full_stall_count, before_count + 1);
        cdb(3'd7, 5'd13, 32'h0000_0120);
        wait_for_commits(11, 80);
        issue(OP_LW, 5'd9, 5'd1, 5'd0, 32'd0);
        wait_for_commits(12, 30);
        expect32("freed lsq entry reused", dut.regs[0][9], 32'h1111_1111);

        issue(OP_ADDI, 5'd20, 5'd0, 5'd0, 32'd7);
        wait_for_commits(13, 20);
        expect32("ADDI through ROB commit", dut.regs[0][20], 32'd7);
        issue(OP_ADD, 5'd21, 5'd20, 5'd2, 32'd0);
        wait_for_commits(14, 20);
        expect32("ADD through ROB commit", dut.regs[0][21], 32'd49);
        issue(OP_SUB, 5'd22, 5'd21, 5'd2, 32'd0);
        wait_for_commits(15, 20);
        expect32("SUB through ROB commit", dut.regs[0][22], 32'd7);
        issue(OP_ADDI, 5'd0, 5'd0, 5'd0, 32'd123);
        wait_for_commits(16, 20);
        expect32("x0 remains zero", dut.regs[0][0], 32'd0);
        expect_ge("x0 suppression counted", x0_commit_suppressed_count, 1);

        before_count = unsupported_count;
        issue(4'd15, 5'd23, 5'd0, 5'd0, 32'd0);
        wait_cycles(2);
        expect_ge("unsupported op counted", unsupported_count, before_count + 1);

        expect_ge("memory uops decoded", memory_uop_count, 12);
        expect_ge("loads allocated total", loads_alloc_count, 5);
        expect_ge("stores allocated total", stores_alloc_count, 7);
        expect_ge("conservative stalls counted", conservative_order_stall_count, 1);
        expect_ge("ROB commits counted", rob_commit_count, 16);
        expect_ge("ALU complete counted", alu_complete_count, 4);
        expect_bit("all LSQ entries eventually free entry0", dut.lsq_valid[0], 1'b0);
        expect_bit("all LSQ entries eventually free entry1", dut.lsq_valid[1], 1'b0);
        expect_bit("all LSQ entries eventually free entry2", dut.lsq_valid[2], 1'b0);
        expect_bit("all LSQ entries eventually free entry3", dut.lsq_valid[3], 1'b0);
        expect_ge("load completions not below loads executed", load_complete_count, load_exec_count);
        expect_ge("store completions not below commits", store_complete_count, store_commit_count);

        $display("LSQPERF: test=phase19_lsq memory_uops=%0d loads=%0d stores=%0d lsq_full_stalls=%0d addr_waits=%0d store_addr_waits=%0d store_data_waits=%0d load_store_order_stalls=%0d conservative_order_stalls=%0d load_execs=%0d load_completions=%0d store_commits=%0d store_completions=%0d rob_commits=%0d rob_commit_stalls=%0d alu_completes=%0d stale_tag_ignored=%0d x0_commit_suppressed=%0d unsupported=%0d checks=%0d errors=%0d pass=%s",
                 memory_uop_count, loads_alloc_count, stores_alloc_count, lsq_full_stall_count,
                 loads_wait_addr_count, stores_wait_addr_count, stores_wait_data_count,
                 load_store_order_stall_count, conservative_order_stall_count, load_exec_count,
                 load_complete_count, store_commit_count, store_complete_count, rob_commit_count,
                 rob_commit_stall_count, alu_complete_count, stale_tag_ignored_count,
                 x0_commit_suppressed_count, unsupported_count, checks, errors,
                 (errors == 0 && checks >= 20) ? "PASS" : "FAIL");
        if (trace_fd != 0) begin
            $fclose(trace_fd);
        end
        if (errors == 0 && checks >= 20) begin
            $display("PASS: Phase 19 LSQ validation completed with %0d checks", checks);
            $finish;
        end
        $fatal(1, "FAIL: Phase 19 LSQ validation errors=%0d checks=%0d", errors, checks);
    end
endmodule
