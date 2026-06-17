`timescale 1ns/1ps

module tomasulo_rob_lsq_experiment_core #(
    parameter NUM_THREADS = 2,
    parameter ROB_ENTRIES = 8,
    parameter LSQ_ENTRIES = 4,
    parameter MEM_WORDS = 256
)(
    input  logic clk,
    input  logic rst_n,

    input  logic                 issue_valid,
    input  logic                 issue_tid,
    input  logic [3:0]           issue_op,
    input  logic [4:0]           issue_rd,
    input  logic [4:0]           issue_rs1,
    input  logic [4:0]           issue_rs2,
    input  logic [31:0]          issue_imm,
    output logic                 issue_ready,
    output logic [$clog2(ROB_ENTRIES)-1:0] issue_rob_tag,

    input  logic                 debug_write_valid,
    input  logic                 debug_write_tid,
    input  logic [4:0]           debug_write_rd,
    input  logic [31:0]          debug_write_data,
    input  logic                 debug_mem_write_valid,
    input  logic [31:0]          debug_mem_write_addr,
    input  logic [31:0]          debug_mem_write_data,
    input  logic                 debug_set_status_valid,
    input  logic                 debug_set_status_tid,
    input  logic [4:0]           debug_set_status_rd,
    input  logic [$clog2(ROB_ENTRIES)-1:0] debug_set_status_tag,
    input  logic                 debug_cdb_valid,
    input  logic                 debug_cdb_tid,
    input  logic [$clog2(ROB_ENTRIES)-1:0] debug_cdb_rob_tag,
    input  logic [4:0]           debug_cdb_rd,
    input  logic [31:0]          debug_cdb_data,

    output logic [31:0] dispatched_count,
    output logic [31:0] rob_alloc_count,
    output logic [31:0] rob_full_stall_count,
    output logic [31:0] rob_commit_count,
    output logic [31:0] rob_commit_stall_count,
    output logic [31:0] alu_complete_count,
    output logic [31:0] memory_uop_count,
    output logic [31:0] loads_alloc_count,
    output logic [31:0] stores_alloc_count,
    output logic [31:0] lsq_full_stall_count,
    output logic [31:0] loads_wait_addr_count,
    output logic [31:0] stores_wait_addr_count,
    output logic [31:0] stores_wait_data_count,
    output logic [31:0] load_store_order_stall_count,
    output logic [31:0] conservative_order_stall_count,
    output logic [31:0] load_exec_count,
    output logic [31:0] load_complete_count,
    output logic [31:0] store_commit_count,
    output logic [31:0] store_complete_count,
    output logic [31:0] stale_tag_ignored_count,
    output logic [31:0] x0_commit_suppressed_count,
    output logic [31:0] unsupported_count,

    output logic                 trace_lsq_alloc_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_lsq_alloc_entry,
    output logic                 trace_lsq_alloc_is_load,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_lsq_alloc_rob,
    output logic                 trace_addr_ready_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_addr_ready_entry,
    output logic [31:0]          trace_addr_ready_value,
    output logic                 trace_store_data_ready_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_store_data_ready_entry,
    output logic [31:0]          trace_store_data_value,
    output logic                 trace_order_stall_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_order_stall_entry,
    output logic                 trace_load_exec_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_load_exec_entry,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_load_exec_rob,
    output logic [31:0]          trace_load_exec_addr,
    output logic [31:0]          trace_load_exec_data,
    output logic                 trace_store_commit_valid,
    output logic [$clog2(LSQ_ENTRIES)-1:0] trace_store_commit_entry,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_store_commit_rob,
    output logic [31:0]          trace_store_commit_addr,
    output logic [31:0]          trace_store_commit_data,
    output logic                 trace_commit_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_commit_rob,
    output logic [4:0]           trace_commit_rd,
    output logic [31:0]          trace_commit_data,
    output logic                 trace_commit_is_store,
    output logic                 trace_commit_stall
);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_ADDI = 4'd5;
    localparam OP_LW   = 4'd6;
    localparam OP_SW   = 4'd7;

    localparam ROB_INDEX_WIDTH = $clog2(ROB_ENTRIES);
    localparam LSQ_INDEX_WIDTH = $clog2(LSQ_ENTRIES);

    logic [31:0] regs [0:NUM_THREADS-1][0:31];
    logic reg_busy [0:NUM_THREADS-1][0:31];
    logic [ROB_INDEX_WIDTH-1:0] reg_tag [0:NUM_THREADS-1][0:31];
    logic [31:0] mem [0:MEM_WORDS-1];

    logic rob_valid [0:ROB_ENTRIES-1];
    logic rob_ready [0:ROB_ENTRIES-1];
    logic rob_tid [0:ROB_ENTRIES-1];
    logic [4:0] rob_rd [0:ROB_ENTRIES-1];
    logic rob_dest_valid [0:ROB_ENTRIES-1];
    logic rob_is_store [0:ROB_ENTRIES-1];
    logic [31:0] rob_value [0:ROB_ENTRIES-1];
    logic [7:0] rob_seq [0:ROB_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] rob_head;
    logic [ROB_INDEX_WIDTH-1:0] rob_tail;
    logic [31:0] rob_count;

    logic lsq_valid [0:LSQ_ENTRIES-1];
    logic lsq_is_load [0:LSQ_ENTRIES-1];
    logic lsq_is_store [0:LSQ_ENTRIES-1];
    logic lsq_tid [0:LSQ_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] lsq_rob_tag [0:LSQ_ENTRIES-1];
    logic [7:0] lsq_seq [0:LSQ_ENTRIES-1];
    logic lsq_addr_ready [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_addr_value [0:LSQ_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] lsq_addr_tag [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_addr_imm [0:LSQ_ENTRIES-1];
    logic lsq_data_ready [0:LSQ_ENTRIES-1];
    logic [31:0] lsq_data_value [0:LSQ_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] lsq_data_tag [0:LSQ_ENTRIES-1];
    logic lsq_completed [0:LSQ_ENTRIES-1];

    logic [7:0] next_seq;
    logic free_lsq_found;
    logic [LSQ_INDEX_WIDTH-1:0] free_lsq_entry;
    logic rob_has_space;
    logic is_memory_op;
    logic is_load_op;
    logic is_store_op;
    logic issue_op_supported;
    logic base_ready;
    logic [31:0] base_value;
    logic [ROB_INDEX_WIDTH-1:0] base_tag;
    logic store_data_ready;
    logic [31:0] store_data_value;
    logic [ROB_INDEX_WIDTH-1:0] store_data_tag;

    logic load_candidate_found;
    logic [LSQ_INDEX_WIDTH-1:0] load_candidate_entry;
    logic load_candidate_blocked;
    logic [31:0] load_word_addr;
    logic [31:0] load_data_value;

    logic store_head_found;
    logic [LSQ_INDEX_WIDTH-1:0] store_head_entry;
    logic [31:0] store_word_addr;

    integer i;
    integer j;

    function automatic [ROB_INDEX_WIDTH-1:0] inc_rob(input [ROB_INDEX_WIDTH-1:0] value);
        begin
            if (value == ROB_ENTRIES - 1) begin
                inc_rob = '0;
            end else begin
                inc_rob = value + 1'b1;
            end
        end
    endfunction

    function automatic [31:0] alu_compute(input logic [3:0] op, input logic [31:0] a, input logic [31:0] b);
        begin
            case (op)
                OP_ADD:  alu_compute = a + b;
                OP_SUB:  alu_compute = a - b;
                OP_ADDI: alu_compute = a + b;
                default: alu_compute = 32'd0;
            endcase
        end
    endfunction

    always_comb begin
        free_lsq_found = 1'b0;
        free_lsq_entry = '0;
        for (int free_i = 0; free_i < LSQ_ENTRIES; free_i = free_i + 1) begin
            if (!free_lsq_found && !lsq_valid[free_i]) begin
                free_lsq_found = 1'b1;
                free_lsq_entry = free_i[LSQ_INDEX_WIDTH-1:0];
            end
        end

        is_load_op = (issue_op == OP_LW);
        is_store_op = (issue_op == OP_SW);
        is_memory_op = is_load_op || is_store_op;
        issue_op_supported = (issue_op == OP_ADD) || (issue_op == OP_SUB) ||
                             (issue_op == OP_ADDI) || is_memory_op;
        rob_has_space = (rob_count < ROB_ENTRIES);
        issue_ready = issue_op_supported && rob_has_space && (!is_memory_op || free_lsq_found);
        issue_rob_tag = rob_tail;

        base_ready = 1'b1;
        base_value = 32'd0;
        base_tag = '0;
        if (issue_rs1 != 5'd0) begin
            if (!reg_busy[issue_tid][issue_rs1]) begin
                base_ready = 1'b1;
                base_value = regs[issue_tid][issue_rs1];
            end else if (rob_valid[reg_tag[issue_tid][issue_rs1]] && rob_ready[reg_tag[issue_tid][issue_rs1]] &&
                         (rob_tid[reg_tag[issue_tid][issue_rs1]] == issue_tid)) begin
                base_ready = 1'b1;
                base_value = rob_value[reg_tag[issue_tid][issue_rs1]];
            end else begin
                base_ready = 1'b0;
                base_tag = reg_tag[issue_tid][issue_rs1];
            end
        end

        store_data_ready = 1'b1;
        store_data_value = 32'd0;
        store_data_tag = '0;
        if (is_store_op && (issue_rs2 != 5'd0)) begin
            if (!reg_busy[issue_tid][issue_rs2]) begin
                store_data_ready = 1'b1;
                store_data_value = regs[issue_tid][issue_rs2];
            end else if (rob_valid[reg_tag[issue_tid][issue_rs2]] && rob_ready[reg_tag[issue_tid][issue_rs2]] &&
                         (rob_tid[reg_tag[issue_tid][issue_rs2]] == issue_tid)) begin
                store_data_ready = 1'b1;
                store_data_value = rob_value[reg_tag[issue_tid][issue_rs2]];
            end else begin
                store_data_ready = 1'b0;
                store_data_tag = reg_tag[issue_tid][issue_rs2];
            end
        end
    end

    always_comb begin
        load_candidate_found = 1'b0;
        load_candidate_entry = '0;
        load_candidate_blocked = 1'b0;
        load_word_addr = 32'd0;
        load_data_value = 32'd0;
        for (int load_i = 0; load_i < LSQ_ENTRIES; load_i = load_i + 1) begin
            if (!load_candidate_found && lsq_valid[load_i] && lsq_is_load[load_i] &&
                lsq_addr_ready[load_i] && !lsq_completed[load_i]) begin
                load_candidate_found = 1'b1;
                load_candidate_entry = load_i[LSQ_INDEX_WIDTH-1:0];
            end
        end
        if (load_candidate_found) begin
            for (int store_i = 0; store_i < LSQ_ENTRIES; store_i = store_i + 1) begin
                if (lsq_valid[store_i] && lsq_is_store[store_i] && !lsq_completed[store_i] &&
                    (lsq_seq[store_i] < lsq_seq[load_candidate_entry])) begin
                    load_candidate_blocked = 1'b1;
                end
            end
            load_word_addr = {2'b00, lsq_addr_value[load_candidate_entry][31:2]};
            if (load_word_addr < MEM_WORDS) begin
                load_data_value = mem[load_word_addr];
            end else begin
                load_data_value = 32'hbad0_0000;
            end
        end
    end

    always_comb begin
        store_head_found = 1'b0;
        store_head_entry = '0;
        store_word_addr = 32'd0;
        for (int store_head_i = 0; store_head_i < LSQ_ENTRIES; store_head_i = store_head_i + 1) begin
            if (!store_head_found && lsq_valid[store_head_i] && lsq_is_store[store_head_i] &&
                (lsq_rob_tag[store_head_i] == rob_head)) begin
                store_head_found = 1'b1;
                store_head_entry = store_head_i[LSQ_INDEX_WIDTH-1:0];
            end
        end
        if (store_head_found) begin
            store_word_addr = {2'b00, lsq_addr_value[store_head_entry][31:2]};
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_THREADS; i = i + 1) begin
                for (j = 0; j < 32; j = j + 1) begin
                    regs[i][j] <= 32'd0;
                    reg_busy[i][j] <= 1'b0;
                    reg_tag[i][j] <= '0;
                end
            end
            for (i = 0; i < MEM_WORDS; i = i + 1) begin
                mem[i] <= 32'd0;
            end
            for (i = 0; i < ROB_ENTRIES; i = i + 1) begin
                rob_valid[i] <= 1'b0;
                rob_ready[i] <= 1'b0;
                rob_tid[i] <= 1'b0;
                rob_rd[i] <= 5'd0;
                rob_dest_valid[i] <= 1'b0;
                rob_is_store[i] <= 1'b0;
                rob_value[i] <= 32'd0;
                rob_seq[i] <= 8'd0;
            end
            for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                lsq_valid[i] <= 1'b0;
                lsq_is_load[i] <= 1'b0;
                lsq_is_store[i] <= 1'b0;
                lsq_tid[i] <= 1'b0;
                lsq_rob_tag[i] <= '0;
                lsq_seq[i] <= 8'd0;
                lsq_addr_ready[i] <= 1'b0;
                lsq_addr_value[i] <= 32'd0;
                lsq_addr_tag[i] <= '0;
                lsq_addr_imm[i] <= 32'd0;
                lsq_data_ready[i] <= 1'b0;
                lsq_data_value[i] <= 32'd0;
                lsq_data_tag[i] <= '0;
                lsq_completed[i] <= 1'b0;
            end
            rob_head <= '0;
            rob_tail <= '0;
            rob_count <= 32'd0;
            next_seq <= 8'd0;
            dispatched_count <= 32'd0;
            rob_alloc_count <= 32'd0;
            rob_full_stall_count <= 32'd0;
            rob_commit_count <= 32'd0;
            rob_commit_stall_count <= 32'd0;
            alu_complete_count <= 32'd0;
            memory_uop_count <= 32'd0;
            loads_alloc_count <= 32'd0;
            stores_alloc_count <= 32'd0;
            lsq_full_stall_count <= 32'd0;
            loads_wait_addr_count <= 32'd0;
            stores_wait_addr_count <= 32'd0;
            stores_wait_data_count <= 32'd0;
            load_store_order_stall_count <= 32'd0;
            conservative_order_stall_count <= 32'd0;
            load_exec_count <= 32'd0;
            load_complete_count <= 32'd0;
            store_commit_count <= 32'd0;
            store_complete_count <= 32'd0;
            stale_tag_ignored_count <= 32'd0;
            x0_commit_suppressed_count <= 32'd0;
            unsupported_count <= 32'd0;
            trace_lsq_alloc_valid <= 1'b0;
            trace_addr_ready_valid <= 1'b0;
            trace_store_data_ready_valid <= 1'b0;
            trace_order_stall_valid <= 1'b0;
            trace_load_exec_valid <= 1'b0;
            trace_store_commit_valid <= 1'b0;
            trace_commit_valid <= 1'b0;
            trace_commit_stall <= 1'b0;
        end else begin
            trace_lsq_alloc_valid <= 1'b0;
            trace_addr_ready_valid <= 1'b0;
            trace_store_data_ready_valid <= 1'b0;
            trace_order_stall_valid <= 1'b0;
            trace_load_exec_valid <= 1'b0;
            trace_store_commit_valid <= 1'b0;
            trace_commit_valid <= 1'b0;
            trace_commit_stall <= 1'b0;

            if (debug_write_valid && (debug_write_rd != 5'd0)) begin
                regs[debug_write_tid][debug_write_rd] <= debug_write_data;
                reg_busy[debug_write_tid][debug_write_rd] <= 1'b0;
            end
            if (debug_mem_write_valid) begin
                mem[{2'b00, debug_mem_write_addr[31:2]}] <= debug_mem_write_data;
            end
            if (debug_set_status_valid && (debug_set_status_rd != 5'd0)) begin
                reg_busy[debug_set_status_tid][debug_set_status_rd] <= 1'b1;
                reg_tag[debug_set_status_tid][debug_set_status_rd] <= debug_set_status_tag;
            end

            if (issue_valid && !issue_op_supported) begin
                unsupported_count <= unsupported_count + 32'd1;
            end else if (issue_valid && issue_op_supported && !rob_has_space) begin
                rob_full_stall_count <= rob_full_stall_count + 32'd1;
            end else if (issue_valid && issue_op_supported && is_memory_op && !free_lsq_found) begin
                lsq_full_stall_count <= lsq_full_stall_count + 32'd1;
            end

            if (issue_valid && issue_ready) begin
                dispatched_count <= dispatched_count + 32'd1;
                rob_alloc_count <= rob_alloc_count + 32'd1;
                rob_valid[rob_tail] <= 1'b1;
                rob_tid[rob_tail] <= issue_tid;
                rob_rd[rob_tail] <= issue_rd;
                rob_dest_valid[rob_tail] <= (issue_op != OP_SW) && (issue_rd != 5'd0);
                rob_is_store[rob_tail] <= is_store_op;
                rob_seq[rob_tail] <= next_seq;
                rob_value[rob_tail] <= 32'd0;
                rob_ready[rob_tail] <= 1'b0;

                if ((issue_op == OP_ADD) || (issue_op == OP_SUB) || (issue_op == OP_ADDI)) begin
                    rob_ready[rob_tail] <= 1'b1;
                    rob_value[rob_tail] <= alu_compute(issue_op, base_value, (issue_op == OP_ADDI) ? issue_imm : regs[issue_tid][issue_rs2]);
                    alu_complete_count <= alu_complete_count + 32'd1;
                end

                if ((issue_op != OP_SW) && (issue_rd != 5'd0)) begin
                    reg_busy[issue_tid][issue_rd] <= 1'b1;
                    reg_tag[issue_tid][issue_rd] <= rob_tail;
                end else if ((issue_op != OP_SW) && (issue_rd == 5'd0)) begin
                    x0_commit_suppressed_count <= x0_commit_suppressed_count + 32'd1;
                end

                if (is_memory_op) begin
                    memory_uop_count <= memory_uop_count + 32'd1;
                    lsq_valid[free_lsq_entry] <= 1'b1;
                    lsq_is_load[free_lsq_entry] <= is_load_op;
                    lsq_is_store[free_lsq_entry] <= is_store_op;
                    lsq_tid[free_lsq_entry] <= issue_tid;
                    lsq_rob_tag[free_lsq_entry] <= rob_tail;
                    lsq_seq[free_lsq_entry] <= next_seq;
                    lsq_addr_ready[free_lsq_entry] <= base_ready;
                    lsq_addr_value[free_lsq_entry] <= base_value + issue_imm;
                    lsq_addr_tag[free_lsq_entry] <= base_tag;
                    lsq_addr_imm[free_lsq_entry] <= issue_imm;
                    lsq_data_ready[free_lsq_entry] <= is_load_op ? 1'b1 : store_data_ready;
                    lsq_data_value[free_lsq_entry] <= store_data_value;
                    lsq_data_tag[free_lsq_entry] <= store_data_tag;
                    lsq_completed[free_lsq_entry] <= 1'b0;
                    if (is_load_op) begin
                        loads_alloc_count <= loads_alloc_count + 32'd1;
                        if (!base_ready) begin
                            loads_wait_addr_count <= loads_wait_addr_count + 32'd1;
                        end
                    end else begin
                        stores_alloc_count <= stores_alloc_count + 32'd1;
                        if (!base_ready) begin
                            stores_wait_addr_count <= stores_wait_addr_count + 32'd1;
                        end
                        if (!store_data_ready) begin
                            stores_wait_data_count <= stores_wait_data_count + 32'd1;
                        end
                    end
                    trace_lsq_alloc_valid <= 1'b1;
                    trace_lsq_alloc_entry <= free_lsq_entry;
                    trace_lsq_alloc_is_load <= is_load_op;
                    trace_lsq_alloc_rob <= rob_tail;
                end
                next_seq <= next_seq + 8'd1;
                rob_tail <= inc_rob(rob_tail);
                rob_count <= rob_count + 32'd1;
            end

            if (debug_cdb_valid) begin
                if (rob_valid[debug_cdb_rob_tag] && (rob_tid[debug_cdb_rob_tag] == debug_cdb_tid) && !rob_ready[debug_cdb_rob_tag]) begin
                    rob_ready[debug_cdb_rob_tag] <= 1'b1;
                    rob_value[debug_cdb_rob_tag] <= debug_cdb_data;
                end else begin
                    stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                end
                for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                    if (lsq_valid[i] && (lsq_tid[i] == debug_cdb_tid) && !lsq_addr_ready[i] && (lsq_addr_tag[i] == debug_cdb_rob_tag)) begin
                        lsq_addr_ready[i] <= 1'b1;
                        lsq_addr_value[i] <= debug_cdb_data + lsq_addr_imm[i];
                        trace_addr_ready_valid <= 1'b1;
                        trace_addr_ready_entry <= i[LSQ_INDEX_WIDTH-1:0];
                        trace_addr_ready_value <= debug_cdb_data + lsq_addr_imm[i];
                    end
                    if (lsq_valid[i] && (lsq_tid[i] == debug_cdb_tid) && lsq_is_store[i] && !lsq_data_ready[i] && (lsq_data_tag[i] == debug_cdb_rob_tag)) begin
                        lsq_data_ready[i] <= 1'b1;
                        lsq_data_value[i] <= debug_cdb_data;
                        trace_store_data_ready_valid <= 1'b1;
                        trace_store_data_ready_entry <= i[LSQ_INDEX_WIDTH-1:0];
                        trace_store_data_value <= debug_cdb_data;
                    end
                end
            end

            if (load_candidate_found && load_candidate_blocked) begin
                load_store_order_stall_count <= load_store_order_stall_count + 32'd1;
                conservative_order_stall_count <= conservative_order_stall_count + 32'd1;
                trace_order_stall_valid <= 1'b1;
                trace_order_stall_entry <= load_candidate_entry;
            end else if (load_candidate_found && !load_candidate_blocked) begin
                lsq_completed[load_candidate_entry] <= 1'b1;
                rob_ready[lsq_rob_tag[load_candidate_entry]] <= 1'b1;
                rob_value[lsq_rob_tag[load_candidate_entry]] <= load_data_value;
                load_exec_count <= load_exec_count + 32'd1;
                load_complete_count <= load_complete_count + 32'd1;
                trace_load_exec_valid <= 1'b1;
                trace_load_exec_entry <= load_candidate_entry;
                trace_load_exec_rob <= lsq_rob_tag[load_candidate_entry];
                trace_load_exec_addr <= lsq_addr_value[load_candidate_entry];
                trace_load_exec_data <= load_data_value;
            end

            if (rob_valid[rob_head]) begin
                if (rob_is_store[rob_head]) begin
                    if (store_head_found && lsq_addr_ready[store_head_entry] && lsq_data_ready[store_head_entry]) begin
                        if (store_word_addr < MEM_WORDS) begin
                            mem[store_word_addr] <= lsq_data_value[store_head_entry];
                        end
                        lsq_completed[store_head_entry] <= 1'b1;
                        lsq_valid[store_head_entry] <= 1'b0;
                        rob_valid[rob_head] <= 1'b0;
                        rob_ready[rob_head] <= 1'b0;
                        rob_head <= inc_rob(rob_head);
                        rob_count <= rob_count - 32'd1;
                        rob_commit_count <= rob_commit_count + 32'd1;
                        store_commit_count <= store_commit_count + 32'd1;
                        store_complete_count <= store_complete_count + 32'd1;
                        trace_store_commit_valid <= 1'b1;
                        trace_store_commit_entry <= store_head_entry;
                        trace_store_commit_rob <= rob_head;
                        trace_store_commit_addr <= lsq_addr_value[store_head_entry];
                        trace_store_commit_data <= lsq_data_value[store_head_entry];
                        trace_commit_valid <= 1'b1;
                        trace_commit_rob <= rob_head;
                        trace_commit_rd <= 5'd0;
                        trace_commit_data <= lsq_data_value[store_head_entry];
                        trace_commit_is_store <= 1'b1;
                    end else begin
                        rob_commit_stall_count <= rob_commit_stall_count + 32'd1;
                        trace_commit_stall <= 1'b1;
                    end
                end else if (rob_ready[rob_head]) begin
                    if (rob_dest_valid[rob_head]) begin
                        regs[rob_tid[rob_head]][rob_rd[rob_head]] <= rob_value[rob_head];
                        if (reg_busy[rob_tid[rob_head]][rob_rd[rob_head]] && (reg_tag[rob_tid[rob_head]][rob_rd[rob_head]] == rob_head)) begin
                            reg_busy[rob_tid[rob_head]][rob_rd[rob_head]] <= 1'b0;
                        end else if (reg_busy[rob_tid[rob_head]][rob_rd[rob_head]]) begin
                            stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                        end
                    end
                    for (i = 0; i < LSQ_ENTRIES; i = i + 1) begin
                        if (lsq_valid[i] && lsq_is_load[i] && (lsq_rob_tag[i] == rob_head)) begin
                            lsq_valid[i] <= 1'b0;
                        end
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
                    rob_commit_stall_count <= rob_commit_stall_count + 32'd1;
                    trace_commit_stall <= 1'b1;
                end
            end
        end
    end
endmodule
