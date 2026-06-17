`timescale 1ns/1ps

module ooo_experiment_core #(
    parameter ROB_ENTRIES = 8,
    parameter RS_ENTRIES = 4,
    parameter LSQ_ENTRIES = 4,
    parameter MEM_WORDS = 256
)(
    input  logic clk,
    input  logic rst_n,

    input  logic                 issue_valid,
    input  logic [3:0]           issue_op,
    input  logic [4:0]           issue_rd,
    input  logic [4:0]           issue_rs1,
    input  logic [4:0]           issue_rs2,
    input  logic [31:0]          issue_imm,
    output logic                 issue_ready,
    output logic [$clog2(ROB_ENTRIES)-1:0] issue_rob_tag,

    input  logic                 debug_write_valid,
    input  logic [4:0]           debug_write_rd,
    input  logic [31:0]          debug_write_data,
    input  logic                 debug_mem_write_valid,
    input  logic [31:0]          debug_mem_write_addr,
    input  logic [31:0]          debug_mem_write_data,
    input  logic                 debug_set_status_valid,
    input  logic [4:0]           debug_set_status_rd,
    input  logic [$clog2(ROB_ENTRIES)-1:0] debug_set_status_tag,
    input  logic                 debug_cdb_valid,
    input  logic [$clog2(ROB_ENTRIES)-1:0] debug_cdb_rob_tag,
    input  logic [4:0]           debug_cdb_rd,
    input  logic [31:0]          debug_cdb_data,

    output logic [31:0] decoded_count,
    output logic [31:0] dispatched_count,
    output logic [31:0] rob_alloc_count,
    output logic [31:0] rob_full_stall_count,
    output logic [31:0] rs_alloc_count,
    output logic [31:0] rs_full_stall_count,
    output logic [31:0] lsq_alloc_count,
    output logic [31:0] lsq_full_stall_count,
    output logic [31:0] alu_issue_count,
    output logic [31:0] load_issue_count,
    output logic [31:0] store_commit_count,
    output logic [31:0] cdb_broadcast_count,
    output logic [31:0] wakeup_count,
    output logic [31:0] completed_count,
    output logic [31:0] rob_commit_count,
    output logic [31:0] commit_stall_count,
    output logic [31:0] younger_done_waiting_count,
    output logic [31:0] memory_order_stall_count,
    output logic [31:0] stale_tag_ignored_count,
    output logic [31:0] x0_commit_suppressed_count,
    output logic [31:0] unsupported_count,

    output logic                 trace_dispatch_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_dispatch_rob,
    output logic [$clog2(RS_ENTRIES)-1:0]  trace_dispatch_rs,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_dispatch_lsq,
    output logic [3:0]           trace_dispatch_op,
    output logic                 trace_issue_valid,
    output logic [$clog2(RS_ENTRIES)-1:0] trace_issue_rs,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_issue_rob,
    output logic [3:0]           trace_issue_op,
    output logic                 trace_cdb_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_cdb_rob,
    output logic [31:0]          trace_cdb_data,
    output logic [3:0]           trace_wakeup_count,
    output logic                 trace_lsq_alloc_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_lsq_alloc_entry,
    output logic                 trace_lsq_alloc_is_load,
    output logic                 trace_load_exec_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_load_exec_entry,
    output logic [31:0]          trace_load_exec_addr,
    output logic [31:0]          trace_load_exec_data,
    output logic                 trace_store_commit_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_store_commit_entry,
    output logic [31:0]          trace_store_commit_addr,
    output logic [31:0]          trace_store_commit_data,
    output logic                 trace_mem_order_stall,
    output logic                 trace_commit_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_commit_rob,
    output logic [4:0]           trace_commit_rd,
    output logic [31:0]          trace_commit_data,
    output logic                 trace_commit_is_store,
    output logic                 trace_commit_stall
);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;
    localparam OP_LW   = 4'd6;
    localparam OP_SW   = 4'd7;
    localparam ROBW = $clog2(ROB_ENTRIES);
    localparam RSW = $clog2(RS_ENTRIES);
    localparam LSQW = $clog2(LSQ_ENTRIES);

    logic [31:0] regs [0:31];
    logic reg_busy [0:31];
    logic [ROBW-1:0] reg_tag [0:31];
    logic [31:0] mem [0:MEM_WORDS-1];

    logic rob_valid [0:ROB_ENTRIES-1];
    logic rob_ready [0:ROB_ENTRIES-1];
    logic [3:0] rob_op [0:ROB_ENTRIES-1];
    logic [4:0] rob_rd [0:ROB_ENTRIES-1];
    logic rob_dest_valid [0:ROB_ENTRIES-1];
    logic rob_is_store [0:ROB_ENTRIES-1];
    logic [31:0] rob_value [0:ROB_ENTRIES-1];
    logic [7:0] rob_seq [0:ROB_ENTRIES-1];
    logic [ROBW-1:0] rob_head;
    logic [ROBW-1:0] rob_tail;
    logic [31:0] rob_count;

    logic rs_valid [0:RS_ENTRIES-1];
    logic [3:0] rs_op [0:RS_ENTRIES-1];
    logic [4:0] rs_rd [0:RS_ENTRIES-1];
    logic [ROBW-1:0] rs_dst_tag [0:RS_ENTRIES-1];
    logic rs_src1_ready [0:RS_ENTRIES-1];
    logic [31:0] rs_src1_value [0:RS_ENTRIES-1];
    logic [ROBW-1:0] rs_src1_tag [0:RS_ENTRIES-1];
    logic rs_src2_ready [0:RS_ENTRIES-1];
    logic [31:0] rs_src2_value [0:RS_ENTRIES-1];
    logic [ROBW-1:0] rs_src2_tag [0:RS_ENTRIES-1];
    logic [7:0] rs_seq [0:RS_ENTRIES-1];

    logic lsq_valid [0:LSQ_ENTRIES-1];
    logic lsq_is_load [0:LSQ_ENTRIES-1];
    logic lsq_is_store [0:LSQ_ENTRIES-1];
    logic [ROBW-1:0] lsq_rob_tag [0:LSQ_ENTRIES-1];
    logic [7:0] lsq_seq [0:LSQ_ENTRIES-1];
    logic lsq_addr_ready [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_addr_value [0:LSQ_ENTRIES-1];
    logic [ROBW-1:0] lsq_addr_tag [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_addr_imm [0:LSQ_ENTRIES-1];
    logic lsq_data_ready [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_data_value [0:LSQ_ENTRIES-1];
    logic [ROBW-1:0] lsq_data_tag [0:LSQ_ENTRIES-1];
    logic lsq_completed [0:LSQ_ENTRIES-1];

    logic [7:0] next_seq;
    logic issue_is_alu;
    logic issue_is_load;
    logic issue_is_store;
    logic issue_is_mem;
    logic issue_supported;
    logic free_rs_found;
    logic [RSW-1:0] free_rs;
    logic free_lsq_found;
    logic [LSQW-1:0] free_lsq;
    logic rob_has_space;

    logic src1_ready;
    logic [31:0] src1_value;
    logic [ROBW-1:0] src1_tag;
    logic src2_ready;
    logic [31:0] src2_value;
    logic [ROBW-1:0] src2_tag;
    logic store_data_ready;
    logic [31:0] store_data_value;
    logic [ROBW-1:0] store_data_tag;

    logic rs_issue_found;
    logic [RSW-1:0] rs_issue_entry;
    logic [31:0] rs_result;
    logic load_found;
    logic [LSQW-1:0] load_entry;
    logic load_blocked;
    logic [31:0] load_word_addr;
    logic [31:0] load_data;
    logic store_head_found;
    logic [LSQW-1:0] store_head_entry;
    logic [31:0] store_word_addr;
    logic internal_cdb_valid;
    logic [ROBW-1:0] internal_cdb_tag;
    logic [4:0] internal_cdb_rd;
    logic [31:0] internal_cdb_data;
    logic cdb_fire;
    logic [ROBW-1:0] cdb_tag;
    logic [4:0] cdb_rd;
    logic [31:0] cdb_data;
    logic [3:0] wake_events;
    logic younger_ready_waiting;

    integer i;
    integer j;

    function automatic [ROBW-1:0] inc_rob(input [ROBW-1:0] value);
        begin
            if (value == ROB_ENTRIES - 1) inc_rob = '0;
            else inc_rob = value + 1'b1;
        end
    endfunction

    function automatic [31:0] alu_compute(input logic [3:0] op, input logic [31:0] a, input logic [31:0] b);
        begin
            case (op)
                OP_ADD:  alu_compute = a + b;
                OP_SUB:  alu_compute = a - b;
                OP_AND:  alu_compute = a & b;
                OP_OR:   alu_compute = a | b;
                OP_XOR:  alu_compute = a ^ b;
                OP_ADDI: alu_compute = a + b;
                default: alu_compute = 32'd0;
            endcase
        end
    endfunction

    always_comb begin
        free_rs_found = 1'b0;
        free_rs = '0;
        for (int k = 0; k < RS_ENTRIES; k = k + 1) begin
            if (!free_rs_found && !rs_valid[k]) begin
                free_rs_found = 1'b1;
                free_rs = k[RSW-1:0];
            end
        end
        free_lsq_found = 1'b0;
        free_lsq = '0;
        for (int k = 0; k < LSQ_ENTRIES; k = k + 1) begin
            if (!free_lsq_found && !lsq_valid[k]) begin
                free_lsq_found = 1'b1;
                free_lsq = k[LSQW-1:0];
            end
        end
        issue_is_alu = (issue_op == OP_ADD) || (issue_op == OP_SUB) || (issue_op == OP_AND) ||
                       (issue_op == OP_OR) || (issue_op == OP_XOR) || (issue_op == OP_ADDI);
        issue_is_load = (issue_op == OP_LW);
        issue_is_store = (issue_op == OP_SW);
        issue_is_mem = issue_is_load || issue_is_store;
        issue_supported = issue_is_alu || issue_is_mem;
        rob_has_space = !rob_valid[rob_tail];
        issue_ready = issue_supported && rob_has_space &&
                      ((!issue_is_alu) || free_rs_found) &&
                      ((!issue_is_mem) || free_lsq_found);
        issue_rob_tag = rob_tail;

        src1_ready = 1'b1;
        src1_value = 32'd0;
        src1_tag = '0;
        if (issue_rs1 != 5'd0) begin
            if (!reg_busy[issue_rs1]) begin
                src1_value = regs[issue_rs1];
            end else if (rob_valid[reg_tag[issue_rs1]] && rob_ready[reg_tag[issue_rs1]]) begin
                src1_value = rob_value[reg_tag[issue_rs1]];
            end else begin
                src1_ready = 1'b0;
                src1_tag = reg_tag[issue_rs1];
            end
        end

        src2_ready = 1'b1;
        src2_value = issue_imm;
        src2_tag = '0;
        if ((issue_op != OP_ADDI) && issue_is_alu && (issue_rs2 != 5'd0)) begin
            if (!reg_busy[issue_rs2]) begin
                src2_value = regs[issue_rs2];
            end else if (rob_valid[reg_tag[issue_rs2]] && rob_ready[reg_tag[issue_rs2]]) begin
                src2_value = rob_value[reg_tag[issue_rs2]];
            end else begin
                src2_ready = 1'b0;
                src2_tag = reg_tag[issue_rs2];
            end
        end

        store_data_ready = 1'b1;
        store_data_value = 32'd0;
        store_data_tag = '0;
        if (issue_is_store && (issue_rs2 != 5'd0)) begin
            if (!reg_busy[issue_rs2]) begin
                store_data_value = regs[issue_rs2];
            end else if (rob_valid[reg_tag[issue_rs2]] && rob_ready[reg_tag[issue_rs2]]) begin
                store_data_value = rob_value[reg_tag[issue_rs2]];
            end else begin
                store_data_ready = 1'b0;
                store_data_tag = reg_tag[issue_rs2];
            end
        end
    end

    always_comb begin
        rs_issue_found = 1'b0;
        rs_issue_entry = '0;
        for (int k = 0; k < RS_ENTRIES; k = k + 1) begin
            if (!rs_issue_found && rs_valid[k] && rs_src1_ready[k] && rs_src2_ready[k]) begin
                rs_issue_found = 1'b1;
                rs_issue_entry = k[RSW-1:0];
            end
        end
        rs_result = alu_compute(rs_op[rs_issue_entry], rs_src1_value[rs_issue_entry], rs_src2_value[rs_issue_entry]);
    end

    always_comb begin
        load_found = 1'b0;
        load_entry = '0;
        load_blocked = 1'b0;
        load_word_addr = 32'd0;
        load_data = 32'd0;
        for (int k = 0; k < LSQ_ENTRIES; k = k + 1) begin
            if (!load_found && lsq_valid[k] && lsq_is_load[k] && lsq_addr_ready[k] && !lsq_completed[k]) begin
                load_found = 1'b1;
                load_entry = k[LSQW-1:0];
            end
        end
        if (load_found) begin
            for (int k = 0; k < LSQ_ENTRIES; k = k + 1) begin
                if (lsq_valid[k] && lsq_is_store[k] && !lsq_completed[k] && (lsq_seq[k] < lsq_seq[load_entry])) begin
                    load_blocked = 1'b1;
                end
            end
            load_word_addr = {2'b00, lsq_addr_value[load_entry][31:2]};
            load_data = (load_word_addr < MEM_WORDS) ? mem[load_word_addr] : 32'hbad0_0000;
        end
    end

    always_comb begin
        store_head_found = 1'b0;
        store_head_entry = '0;
        store_word_addr = 32'd0;
        for (int k = 0; k < LSQ_ENTRIES; k = k + 1) begin
            if (!store_head_found && lsq_valid[k] && lsq_is_store[k] && (lsq_rob_tag[k] == rob_head)) begin
                store_head_found = 1'b1;
                store_head_entry = k[LSQW-1:0];
            end
        end
        if (store_head_found) store_word_addr = {2'b00, lsq_addr_value[store_head_entry][31:2]};
    end

    always_comb begin
        younger_ready_waiting = 1'b0;
        for (int k = 0; k < ROB_ENTRIES; k = k + 1) begin
            if (rob_valid[k] && rob_ready[k] && (k[ROBW-1:0] != rob_head)) younger_ready_waiting = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
                reg_busy[i] <= 1'b0;
                reg_tag[i] <= '0;
            end
            for (i = 0; i < MEM_WORDS; i = i + 1) mem[i] <= 32'd0;
            for (i = 0; i < ROB_ENTRIES; i = i + 1) begin
                rob_valid[i] <= 1'b0; rob_ready[i] <= 1'b0; rob_op[i] <= 4'd0; rob_rd[i] <= 5'd0;
                rob_dest_valid[i] <= 1'b0; rob_is_store[i] <= 1'b0; rob_value[i] <= 32'd0; rob_seq[i] <= 8'd0;
            end
            for (i = 0; i < RS_ENTRIES; i = i + 1) begin
                rs_valid[i] <= 1'b0; rs_op[i] <= 4'd0; rs_rd[i] <= 5'd0; rs_dst_tag[i] <= '0;
                rs_src1_ready[i] <= 1'b0; rs_src1_value[i] <= 32'd0; rs_src1_tag[i] <= '0;
                rs_src2_ready[i] <= 1'b0; rs_src2_value[i] <= 32'd0; rs_src2_tag[i] <= '0; rs_seq[i] <= 8'd0;
            end
            for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                lsq_valid[i] <= 1'b0; lsq_is_load[i] <= 1'b0; lsq_is_store[i] <= 1'b0; lsq_rob_tag[i] <= '0; lsq_seq[i] <= 8'd0;
                lsq_addr_ready[i] <= 1'b0; lsq_addr_value[i] <= 32'd0; lsq_addr_tag[i] <= '0; lsq_addr_imm[i] <= 32'd0;
                lsq_data_ready[i] <= 1'b0; lsq_data_value[i] <= 32'd0; lsq_data_tag[i] <= '0; lsq_completed[i] <= 1'b0;
            end
            rob_head <= '0; rob_tail <= '0; rob_count <= 32'd0; next_seq <= 8'd0;
            decoded_count <= 32'd0; dispatched_count <= 32'd0; rob_alloc_count <= 32'd0; rob_full_stall_count <= 32'd0;
            rs_alloc_count <= 32'd0; rs_full_stall_count <= 32'd0; lsq_alloc_count <= 32'd0; lsq_full_stall_count <= 32'd0;
            alu_issue_count <= 32'd0; load_issue_count <= 32'd0; store_commit_count <= 32'd0; cdb_broadcast_count <= 32'd0;
            wakeup_count <= 32'd0; completed_count <= 32'd0; rob_commit_count <= 32'd0; commit_stall_count <= 32'd0;
            younger_done_waiting_count <= 32'd0; memory_order_stall_count <= 32'd0; stale_tag_ignored_count <= 32'd0;
            x0_commit_suppressed_count <= 32'd0; unsupported_count <= 32'd0;
            trace_dispatch_valid <= 1'b0; trace_issue_valid <= 1'b0; trace_cdb_valid <= 1'b0; trace_lsq_alloc_valid <= 1'b0;
            trace_load_exec_valid <= 1'b0; trace_store_commit_valid <= 1'b0; trace_mem_order_stall <= 1'b0; trace_commit_valid <= 1'b0; trace_commit_stall <= 1'b0;
        end else begin
            trace_dispatch_valid <= 1'b0; trace_issue_valid <= 1'b0; trace_cdb_valid <= 1'b0; trace_lsq_alloc_valid <= 1'b0;
            trace_load_exec_valid <= 1'b0; trace_store_commit_valid <= 1'b0; trace_mem_order_stall <= 1'b0; trace_commit_valid <= 1'b0; trace_commit_stall <= 1'b0;
            internal_cdb_valid = 1'b0; internal_cdb_tag = '0; internal_cdb_rd = 5'd0; internal_cdb_data = 32'd0; wake_events = 4'd0;

            if (debug_write_valid && (debug_write_rd != 5'd0)) begin
                regs[debug_write_rd] <= debug_write_data;
                reg_busy[debug_write_rd] <= 1'b0;
            end
            if (debug_mem_write_valid) mem[{2'b00, debug_mem_write_addr[31:2]}] <= debug_mem_write_data;
            if (debug_set_status_valid && (debug_set_status_rd != 5'd0)) begin
                reg_busy[debug_set_status_rd] <= 1'b1;
                reg_tag[debug_set_status_rd] <= debug_set_status_tag;
            end

            if (issue_valid) decoded_count <= decoded_count + 32'd1;
            if (issue_valid && !issue_supported) unsupported_count <= unsupported_count + 32'd1;
            else if (issue_valid && issue_supported && !rob_has_space) rob_full_stall_count <= rob_full_stall_count + 32'd1;
            else if (issue_valid && issue_is_alu && !free_rs_found) rs_full_stall_count <= rs_full_stall_count + 32'd1;
            else if (issue_valid && issue_is_mem && !free_lsq_found) lsq_full_stall_count <= lsq_full_stall_count + 32'd1;

            if (issue_valid && issue_ready) begin
                dispatched_count <= dispatched_count + 32'd1;
                rob_alloc_count <= rob_alloc_count + 32'd1;
                rob_valid[rob_tail] <= 1'b1;
                rob_ready[rob_tail] <= 1'b0;
                rob_op[rob_tail] <= issue_op;
                rob_rd[rob_tail] <= issue_rd;
                rob_dest_valid[rob_tail] <= !issue_is_store && (issue_rd != 5'd0);
                rob_is_store[rob_tail] <= issue_is_store;
                rob_value[rob_tail] <= 32'd0;
                rob_seq[rob_tail] <= next_seq;
                if (!issue_is_store && (issue_rd != 5'd0)) begin
                    reg_busy[issue_rd] <= 1'b1;
                    reg_tag[issue_rd] <= rob_tail;
                end else if (!issue_is_store && (issue_rd == 5'd0)) begin
                    x0_commit_suppressed_count <= x0_commit_suppressed_count + 32'd1;
                end
                if (issue_is_alu) begin
                    rs_valid[free_rs] <= 1'b1;
                    rs_op[free_rs] <= issue_op;
                    rs_rd[free_rs] <= issue_rd;
                    rs_dst_tag[free_rs] <= rob_tail;
                    rs_src1_ready[free_rs] <= src1_ready;
                    rs_src1_value[free_rs] <= src1_value;
                    rs_src1_tag[free_rs] <= src1_tag;
                    rs_src2_ready[free_rs] <= src2_ready;
                    rs_src2_value[free_rs] <= src2_value;
                    rs_src2_tag[free_rs] <= src2_tag;
                    rs_seq[free_rs] <= next_seq;
                    rs_alloc_count <= rs_alloc_count + 32'd1;
                    trace_dispatch_rs <= free_rs;
                    trace_dispatch_lsq <= '0;
                end
                if (issue_is_mem) begin
                    lsq_valid[free_lsq] <= 1'b1;
                    lsq_is_load[free_lsq] <= issue_is_load;
                    lsq_is_store[free_lsq] <= issue_is_store;
                    lsq_rob_tag[free_lsq] <= rob_tail;
                    lsq_seq[free_lsq] <= next_seq;
                    lsq_addr_ready[free_lsq] <= src1_ready;
                    lsq_addr_value[free_lsq] <= src1_value + issue_imm;
                    lsq_addr_tag[free_lsq] <= src1_tag;
                    lsq_addr_imm[free_lsq] <= issue_imm;
                    lsq_data_ready[free_lsq] <= issue_is_load ? 1'b1 : store_data_ready;
                    lsq_data_value[free_lsq] <= store_data_value;
                    lsq_data_tag[free_lsq] <= store_data_tag;
                    lsq_completed[free_lsq] <= 1'b0;
                    lsq_alloc_count <= lsq_alloc_count + 32'd1;
                    trace_lsq_alloc_valid <= 1'b1;
                    trace_lsq_alloc_entry <= free_lsq;
                    trace_lsq_alloc_is_load <= issue_is_load;
                    trace_dispatch_rs <= '0;
                    trace_dispatch_lsq <= free_lsq;
                end
                trace_dispatch_valid <= 1'b1;
                trace_dispatch_rob <= rob_tail;
                trace_dispatch_op <= issue_op;
                rob_tail <= inc_rob(rob_tail);
                rob_count <= rob_count + 32'd1;
                next_seq <= next_seq + 8'd1;
            end

            if (rs_issue_found) begin
                rs_valid[rs_issue_entry] <= 1'b0;
                internal_cdb_valid = 1'b1;
                internal_cdb_tag = rs_dst_tag[rs_issue_entry];
                internal_cdb_rd = rs_rd[rs_issue_entry];
                internal_cdb_data = rs_result;
                alu_issue_count <= alu_issue_count + 32'd1;
                trace_issue_valid <= 1'b1;
                trace_issue_rs <= rs_issue_entry;
                trace_issue_rob <= rs_dst_tag[rs_issue_entry];
                trace_issue_op <= rs_op[rs_issue_entry];
            end else if (load_found && load_blocked) begin
                memory_order_stall_count <= memory_order_stall_count + 32'd1;
                trace_mem_order_stall <= 1'b1;
            end else if (load_found && !load_blocked) begin
                lsq_completed[load_entry] <= 1'b1;
                internal_cdb_valid = 1'b1;
                internal_cdb_tag = lsq_rob_tag[load_entry];
                internal_cdb_rd = rob_rd[lsq_rob_tag[load_entry]];
                internal_cdb_data = load_data;
                load_issue_count <= load_issue_count + 32'd1;
                trace_load_exec_valid <= 1'b1;
                trace_load_exec_entry <= load_entry;
                trace_load_exec_addr <= lsq_addr_value[load_entry];
                trace_load_exec_data <= load_data;
            end

            cdb_fire = debug_cdb_valid || internal_cdb_valid;
            cdb_tag = debug_cdb_valid ? debug_cdb_rob_tag : internal_cdb_tag;
            cdb_rd = debug_cdb_valid ? debug_cdb_rd : internal_cdb_rd;
            cdb_data = debug_cdb_valid ? debug_cdb_data : internal_cdb_data;
            if (cdb_fire) begin
                if (rob_valid[cdb_tag] && !rob_ready[cdb_tag]) begin
                    rob_ready[cdb_tag] <= 1'b1;
                    rob_value[cdb_tag] <= cdb_data;
                    completed_count <= completed_count + 32'd1;
                    cdb_broadcast_count <= cdb_broadcast_count + 32'd1;
                end else begin
                    stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                end
                for (i = 0; i < RS_ENTRIES; i = i + 1) begin
                    if (rs_valid[i] && !rs_src1_ready[i] && (rs_src1_tag[i] == cdb_tag)) begin
                        rs_src1_ready[i] <= 1'b1; rs_src1_value[i] <= cdb_data; wake_events = wake_events + 4'd1;
                    end
                    if (rs_valid[i] && !rs_src2_ready[i] && (rs_src2_tag[i] == cdb_tag)) begin
                        rs_src2_ready[i] <= 1'b1; rs_src2_value[i] <= cdb_data; wake_events = wake_events + 4'd1;
                    end
                end
                for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                    if (lsq_valid[i] && !lsq_addr_ready[i] && (lsq_addr_tag[i] == cdb_tag)) begin
                        lsq_addr_ready[i] <= 1'b1; lsq_addr_value[i] <= cdb_data + lsq_addr_imm[i]; wake_events = wake_events + 4'd1;
                    end
                    if (lsq_valid[i] && lsq_is_store[i] && !lsq_data_ready[i] && (lsq_data_tag[i] == cdb_tag)) begin
                        lsq_data_ready[i] <= 1'b1; lsq_data_value[i] <= cdb_data; wake_events = wake_events + 4'd1;
                    end
                end
                wakeup_count <= wakeup_count + wake_events;
                trace_cdb_valid <= 1'b1;
                trace_cdb_rob <= cdb_tag;
                trace_cdb_data <= cdb_data;
                trace_wakeup_count <= wake_events;
            end

            if (rob_valid[rob_head]) begin
                if (rob_is_store[rob_head]) begin
                    if (store_head_found && lsq_addr_ready[store_head_entry] && lsq_data_ready[store_head_entry]) begin
                        if (store_word_addr < MEM_WORDS) mem[store_word_addr] <= lsq_data_value[store_head_entry];
                        lsq_completed[store_head_entry] <= 1'b1;
                        lsq_valid[store_head_entry] <= 1'b0;
                        rob_valid[rob_head] <= 1'b0;
                        rob_ready[rob_head] <= 1'b0;
                        rob_head <= inc_rob(rob_head);
                        rob_count <= rob_count - 32'd1;
                        rob_commit_count <= rob_commit_count + 32'd1;
                        store_commit_count <= store_commit_count + 32'd1;
                        trace_store_commit_valid <= 1'b1;
                        trace_store_commit_entry <= store_head_entry;
                        trace_store_commit_addr <= lsq_addr_value[store_head_entry];
                        trace_store_commit_data <= lsq_data_value[store_head_entry];
                        trace_commit_valid <= 1'b1;
                        trace_commit_rob <= rob_head;
                        trace_commit_rd <= 5'd0;
                        trace_commit_data <= lsq_data_value[store_head_entry];
                        trace_commit_is_store <= 1'b1;
                    end else begin
                        commit_stall_count <= commit_stall_count + 32'd1;
                        trace_commit_stall <= 1'b1;
                    end
                end else if (rob_ready[rob_head]) begin
                    if (rob_dest_valid[rob_head]) begin
                        regs[rob_rd[rob_head]] <= rob_value[rob_head];
                        if (reg_busy[rob_rd[rob_head]] && (reg_tag[rob_rd[rob_head]] == rob_head)) begin
                            reg_busy[rob_rd[rob_head]] <= 1'b0;
                        end else if (reg_busy[rob_rd[rob_head]]) begin
                            stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                        end
                    end
                    for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                        if (lsq_valid[i] && lsq_is_load[i] && (lsq_rob_tag[i] == rob_head)) lsq_valid[i] <= 1'b0;
                    end
                    rob_valid[rob_head] <= 1'b0;
                    rob_ready[rob_head] <= 1'b0;
                    rob_head <= inc_rob(rob_head);
                    rob_count <= rob_count - 32'd1;
                    rob_commit_count <= rob_commit_count + 32'd1;
                    trace_commit_valid <= 1'b1;
                    trace_commit_rob <= rob_head;
                    trace_commit_rd <= rob_rd[rob_head];
                    trace_commit_data <= rob_value[rob_head];
                    trace_commit_is_store <= 1'b0;
                end else begin
                    commit_stall_count <= commit_stall_count + 32'd1;
                    if (younger_ready_waiting) younger_done_waiting_count <= younger_done_waiting_count + 32'd1;
                    trace_commit_stall <= 1'b1;
                end
            end
        end
    end
endmodule

