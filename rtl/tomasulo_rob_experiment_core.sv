`timescale 1ns/1ps

module tomasulo_rob_experiment_core #(
    parameter NUM_THREADS = 2,
    parameter RS_ENTRIES = 4,
    parameter ROB_ENTRIES = 4,
    parameter ALU_LATENCY = 1
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
    input  logic                 issue_src1_needed,
    input  logic                 issue_src2_needed,
    input  logic                 issue_src2_is_imm,
    output logic                 issue_ready,
    output logic [$clog2(ROB_ENTRIES)-1:0] issue_rob_tag,

    input  logic                 debug_write_valid,
    input  logic                 debug_write_tid,
    input  logic [4:0]           debug_write_rd,
    input  logic [31:0]          debug_write_data,
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
    output logic [31:0] rs_alloc_count,
    output logic [31:0] rs_full_stall_count,
    output logic [31:0] issued_count,
    output logic [31:0] ooo_issue_count,
    output logic [31:0] completed_count,
    output logic [31:0] broadcast_count,
    output logic [31:0] wakeup_count,
    output logic [31:0] commit_count,
    output logic [31:0] commit_stall_count,
    output logic [31:0] younger_done_waiting_count,
    output logic [31:0] stale_tag_ignored_count,
    output logic [31:0] x0_commit_suppressed_count,
    output logic [31:0] unsupported_count,
    output logic [31:0] thread0_commit_count,
    output logic [31:0] thread1_commit_count,

    output logic                 trace_dispatch_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_dispatch_rob,
    output logic [$clog2(RS_ENTRIES)-1:0]  trace_dispatch_rs,
    output logic [3:0]           trace_dispatch_op,
    output logic [4:0]           trace_dispatch_rd,
    output logic                 trace_issue_valid,
    output logic [$clog2(RS_ENTRIES)-1:0]  trace_issue_rs,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_issue_rob,
    output logic                 trace_cdb_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_cdb_rob,
    output logic [4:0]           trace_cdb_rd,
    output logic [31:0]          trace_cdb_data,
    output logic [3:0]           trace_wakeup_count,
    output logic                 trace_commit_valid,
    output logic [$clog2(ROB_ENTRIES)-1:0] trace_commit_rob,
    output logic [4:0]           trace_commit_rd,
    output logic [31:0]          trace_commit_data,
    output logic                 trace_commit_stall
);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;
    localparam RS_INDEX_WIDTH = $clog2(RS_ENTRIES);
    localparam ROB_INDEX_WIDTH = $clog2(ROB_ENTRIES);

    logic [31:0] regs [0:NUM_THREADS-1][0:31];
    logic reg_busy [0:NUM_THREADS-1][0:31];
    logic [ROB_INDEX_WIDTH-1:0] reg_tag [0:NUM_THREADS-1][0:31];

    logic rs_valid [0:RS_ENTRIES-1];
    logic rs_issued [0:RS_ENTRIES-1];
    logic rs_tid [0:RS_ENTRIES-1];
    logic [3:0] rs_op [0:RS_ENTRIES-1];
    logic [4:0] rs_rd [0:RS_ENTRIES-1];
    logic [31:0] rs_v1 [0:RS_ENTRIES-1];
    logic [31:0] rs_v2 [0:RS_ENTRIES-1];
    logic rs_q1_ready [0:RS_ENTRIES-1];
    logic rs_q2_ready [0:RS_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] rs_q1_tag [0:RS_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] rs_q2_tag [0:RS_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] rs_dst_tag [0:RS_ENTRIES-1];
    logic [7:0] rs_seq [0:RS_ENTRIES-1];

    logic rob_valid [0:ROB_ENTRIES-1];
    logic rob_ready [0:ROB_ENTRIES-1];
    logic rob_tid [0:ROB_ENTRIES-1];
    logic [4:0] rob_rd [0:ROB_ENTRIES-1];
    logic rob_dest_valid [0:ROB_ENTRIES-1];
    logic [31:0] rob_value [0:ROB_ENTRIES-1];
    logic [7:0] rob_seq [0:ROB_ENTRIES-1];
    logic [ROB_INDEX_WIDTH-1:0] rob_head;
    logic [ROB_INDEX_WIDTH-1:0] rob_tail;
    logic [31:0] rob_count;

    logic [7:0] next_seq;
    logic free_rs_found;
    logic [RS_INDEX_WIDTH-1:0] free_rs_entry;
    logic rob_has_space;
    logic issue_op_supported;
    logic alloc_src1_ready;
    logic alloc_src2_ready;
    logic [31:0] alloc_src1_value;
    logic [31:0] alloc_src2_value;
    logic [ROB_INDEX_WIDTH-1:0] alloc_src1_tag;
    logic [ROB_INDEX_WIDTH-1:0] alloc_src2_tag;

    logic selected_found;
    logic [RS_INDEX_WIDTH-1:0] selected_entry;
    logic [7:0] selected_seq;
    logic older_waiting_found;

    logic exec_valid;
    logic [RS_INDEX_WIDTH-1:0] exec_entry;
    logic exec_tid;
    logic [3:0] exec_op;
    logic [4:0] exec_rd;
    logic [31:0] exec_v1;
    logic [31:0] exec_v2;
    logic [ROB_INDEX_WIDTH-1:0] exec_rob_tag;
    logic [31:0] exec_cycles_left;
    logic [31:0] alu_result;
    /* verilator lint_off UNUSEDSIGNAL */
    logic alu_supported;
    /* verilator lint_on UNUSEDSIGNAL */

    logic cdb_fire;
    logic cdb_tid;
    logic [ROB_INDEX_WIDTH-1:0] cdb_rob_tag;
    logic [4:0] cdb_rd;
    logic [31:0] cdb_data;
    logic [3:0] wake_events;

    integer reset_t;
    integer reset_r;
    integer reset_s;
    integer reset_b;
    integer wake_i;
    integer younger_i;

    function automatic [RS_INDEX_WIDTH-1:0] to_rs_index(input integer value);
        begin
            case (value)
                0: to_rs_index = '0;
                1: to_rs_index = 2'd1;
                2: to_rs_index = 2'd2;
                default: to_rs_index = 2'd3;
            endcase
        end
    endfunction

    function automatic [ROB_INDEX_WIDTH-1:0] inc_rob(input [ROB_INDEX_WIDTH-1:0] value);
        begin
            if (value == ROB_ENTRIES[ROB_INDEX_WIDTH-1:0] - {{(ROB_INDEX_WIDTH-1){1'b0}}, 1'b1}) begin
                inc_rob = '0;
            end else begin
                inc_rob = value + {{(ROB_INDEX_WIDTH-1){1'b0}}, 1'b1};
            end
        end
    endfunction

    tomasulo_alu_model u_alu (
        .op(exec_op),
        .src1(exec_v1),
        .src2(exec_v2),
        .result(alu_result),
        .supported(alu_supported)
    );

    always_comb begin
        free_rs_found = 1'b0;
        free_rs_entry = '0;
        for (int free_i = 0; free_i < RS_ENTRIES; free_i = free_i + 1) begin
            if (!free_rs_found && !rs_valid[free_i]) begin
                free_rs_found = 1'b1;
                free_rs_entry = to_rs_index(free_i);
            end
        end

        rob_has_space = (rob_count < ROB_ENTRIES);
        issue_op_supported = (issue_op == OP_ADD) || (issue_op == OP_SUB) ||
                             (issue_op == OP_AND) || (issue_op == OP_OR) ||
                             (issue_op == OP_XOR) || (issue_op == OP_ADDI);
        issue_ready = free_rs_found && rob_has_space && issue_op_supported;
        issue_rob_tag = rob_tail;

        alloc_src1_ready = 1'b1;
        alloc_src1_value = 32'd0;
        alloc_src1_tag = '0;
        if (issue_src1_needed && (issue_rs1 != 5'd0)) begin
            if (!reg_busy[issue_tid][issue_rs1]) begin
                alloc_src1_ready = 1'b1;
                alloc_src1_value = regs[issue_tid][issue_rs1];
            end else if (rob_valid[reg_tag[issue_tid][issue_rs1]] && rob_ready[reg_tag[issue_tid][issue_rs1]] &&
                         (rob_tid[reg_tag[issue_tid][issue_rs1]] == issue_tid)) begin
                alloc_src1_ready = 1'b1;
                alloc_src1_value = rob_value[reg_tag[issue_tid][issue_rs1]];
            end else begin
                alloc_src1_ready = 1'b0;
                alloc_src1_tag = reg_tag[issue_tid][issue_rs1];
            end
        end

        if (issue_src2_is_imm) begin
            alloc_src2_ready = 1'b1;
            alloc_src2_value = issue_imm;
            alloc_src2_tag = '0;
        end else begin
            alloc_src2_ready = 1'b1;
            alloc_src2_value = 32'd0;
            alloc_src2_tag = '0;
            if (issue_src2_needed && (issue_rs2 != 5'd0)) begin
                if (!reg_busy[issue_tid][issue_rs2]) begin
                    alloc_src2_ready = 1'b1;
                    alloc_src2_value = regs[issue_tid][issue_rs2];
                end else if (rob_valid[reg_tag[issue_tid][issue_rs2]] && rob_ready[reg_tag[issue_tid][issue_rs2]] &&
                             (rob_tid[reg_tag[issue_tid][issue_rs2]] == issue_tid)) begin
                    alloc_src2_ready = 1'b1;
                    alloc_src2_value = rob_value[reg_tag[issue_tid][issue_rs2]];
                end else begin
                    alloc_src2_ready = 1'b0;
                    alloc_src2_tag = reg_tag[issue_tid][issue_rs2];
                end
            end
        end

        selected_found = 1'b0;
        selected_entry = '0;
        selected_seq = 8'hff;
        older_waiting_found = 1'b0;
        for (int select_i = 0; select_i < RS_ENTRIES; select_i = select_i + 1) begin
            if (rs_valid[select_i] && !rs_issued[select_i] && rs_q1_ready[select_i] && rs_q2_ready[select_i]) begin
                if (!selected_found || (rs_seq[select_i] < selected_seq)) begin
                    selected_found = 1'b1;
                    selected_entry = to_rs_index(select_i);
                    selected_seq = rs_seq[select_i];
                end
            end
        end
        if (selected_found) begin
            for (int older_i = 0; older_i < RS_ENTRIES; older_i = older_i + 1) begin
                if (rs_valid[older_i] && !rs_issued[older_i] && (rs_seq[older_i] < selected_seq) &&
                    !(rs_q1_ready[older_i] && rs_q2_ready[older_i])) begin
                    older_waiting_found = 1'b1;
                end
            end
        end
    end

    always_comb begin
        cdb_fire = 1'b0;
        cdb_tid = 1'b0;
        cdb_rob_tag = '0;
        cdb_rd = 5'd0;
        cdb_data = 32'd0;
        if (exec_valid && (exec_cycles_left <= 32'd1)) begin
            cdb_fire = 1'b1;
            cdb_tid = exec_tid;
            cdb_rob_tag = exec_rob_tag;
            cdb_rd = exec_rd;
            cdb_data = alu_result;
        end else if (debug_cdb_valid) begin
            cdb_fire = 1'b1;
            cdb_tid = debug_cdb_tid;
            cdb_rob_tag = debug_cdb_rob_tag;
            cdb_rd = debug_cdb_rd;
            cdb_data = debug_cdb_data;
        end
    end

    always_comb begin
        wake_events = 4'd0;
        if (cdb_fire) begin
            for (int wake_check_i = 0; wake_check_i < RS_ENTRIES; wake_check_i = wake_check_i + 1) begin
                if (rs_valid[wake_check_i] && (rs_tid[wake_check_i] == cdb_tid)) begin
                    if (!rs_q1_ready[wake_check_i] && (rs_q1_tag[wake_check_i] == cdb_rob_tag)) wake_events = wake_events + 4'd1;
                    if (!rs_q2_ready[wake_check_i] && (rs_q2_tag[wake_check_i] == cdb_rob_tag)) wake_events = wake_events + 4'd1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rob_head <= '0;
            rob_tail <= '0;
            rob_count <= 32'd0;
            next_seq <= 8'd0;
            exec_valid <= 1'b0;
            exec_entry <= '0;
            exec_tid <= 1'b0;
            exec_op <= OP_ADD;
            exec_rd <= 5'd0;
            exec_v1 <= 32'd0;
            exec_v2 <= 32'd0;
            exec_rob_tag <= '0;
            exec_cycles_left <= 32'd0;
            dispatched_count <= 32'd0;
            rob_alloc_count <= 32'd0;
            rob_full_stall_count <= 32'd0;
            rs_alloc_count <= 32'd0;
            rs_full_stall_count <= 32'd0;
            issued_count <= 32'd0;
            ooo_issue_count <= 32'd0;
            completed_count <= 32'd0;
            broadcast_count <= 32'd0;
            wakeup_count <= 32'd0;
            commit_count <= 32'd0;
            commit_stall_count <= 32'd0;
            younger_done_waiting_count <= 32'd0;
            stale_tag_ignored_count <= 32'd0;
            x0_commit_suppressed_count <= 32'd0;
            unsupported_count <= 32'd0;
            thread0_commit_count <= 32'd0;
            thread1_commit_count <= 32'd0;
            trace_dispatch_valid <= 1'b0;
            trace_dispatch_rob <= '0;
            trace_dispatch_rs <= '0;
            trace_dispatch_op <= OP_ADD;
            trace_dispatch_rd <= 5'd0;
            trace_issue_valid <= 1'b0;
            trace_issue_rs <= '0;
            trace_issue_rob <= '0;
            trace_cdb_valid <= 1'b0;
            trace_cdb_rob <= '0;
            trace_cdb_rd <= 5'd0;
            trace_cdb_data <= 32'd0;
            trace_wakeup_count <= 4'd0;
            trace_commit_valid <= 1'b0;
            trace_commit_rob <= '0;
            trace_commit_rd <= 5'd0;
            trace_commit_data <= 32'd0;
            trace_commit_stall <= 1'b0;
            for (reset_t = 0; reset_t < NUM_THREADS; reset_t = reset_t + 1) begin
                for (reset_r = 0; reset_r < 32; reset_r = reset_r + 1) begin
                    regs[reset_t][reset_r] <= 32'd0;
                    reg_busy[reset_t][reset_r] <= 1'b0;
                    reg_tag[reset_t][reset_r] <= '0;
                end
            end
            for (reset_s = 0; reset_s < RS_ENTRIES; reset_s = reset_s + 1) begin
                rs_valid[reset_s] <= 1'b0;
                rs_issued[reset_s] <= 1'b0;
                rs_tid[reset_s] <= 1'b0;
                rs_op[reset_s] <= OP_ADD;
                rs_rd[reset_s] <= 5'd0;
                rs_v1[reset_s] <= 32'd0;
                rs_v2[reset_s] <= 32'd0;
                rs_q1_ready[reset_s] <= 1'b0;
                rs_q2_ready[reset_s] <= 1'b0;
                rs_q1_tag[reset_s] <= '0;
                rs_q2_tag[reset_s] <= '0;
                rs_dst_tag[reset_s] <= '0;
                rs_seq[reset_s] <= 8'd0;
            end
            for (reset_b = 0; reset_b < ROB_ENTRIES; reset_b = reset_b + 1) begin
                rob_valid[reset_b] <= 1'b0;
                rob_ready[reset_b] <= 1'b0;
                rob_tid[reset_b] <= 1'b0;
                rob_rd[reset_b] <= 5'd0;
                rob_dest_valid[reset_b] <= 1'b0;
                rob_value[reset_b] <= 32'd0;
                rob_seq[reset_b] <= 8'd0;
            end
        end else begin
            trace_dispatch_valid <= 1'b0;
            trace_issue_valid <= 1'b0;
            trace_cdb_valid <= 1'b0;
            trace_wakeup_count <= 4'd0;
            trace_commit_valid <= 1'b0;
            trace_commit_stall <= 1'b0;
            regs[0][0] <= 32'd0;
            regs[1][0] <= 32'd0;
            reg_busy[0][0] <= 1'b0;
            reg_busy[1][0] <= 1'b0;

            if (debug_write_valid && (debug_write_rd != 5'd0)) begin
                regs[debug_write_tid][debug_write_rd] <= debug_write_data;
                reg_busy[debug_write_tid][debug_write_rd] <= 1'b0;
                reg_tag[debug_write_tid][debug_write_rd] <= '0;
            end
            if (debug_set_status_valid && (debug_set_status_rd != 5'd0)) begin
                reg_busy[debug_set_status_tid][debug_set_status_rd] <= 1'b1;
                reg_tag[debug_set_status_tid][debug_set_status_rd] <= debug_set_status_tag;
            end

            if (cdb_fire) begin
                trace_cdb_valid <= 1'b1;
                trace_cdb_rob <= cdb_rob_tag;
                trace_cdb_rd <= cdb_rd;
                trace_cdb_data <= cdb_data;
                trace_wakeup_count <= wake_events;
                broadcast_count <= broadcast_count + 32'd1;
                wakeup_count <= wakeup_count + {28'd0, wake_events};

                for (wake_i = 0; wake_i < RS_ENTRIES; wake_i = wake_i + 1) begin
                    if (rs_valid[wake_i] && (rs_tid[wake_i] == cdb_tid)) begin
                        if (!rs_q1_ready[wake_i] && (rs_q1_tag[wake_i] == cdb_rob_tag)) begin
                            rs_q1_ready[wake_i] <= 1'b1;
                            rs_v1[wake_i] <= cdb_data;
                        end
                        if (!rs_q2_ready[wake_i] && (rs_q2_tag[wake_i] == cdb_rob_tag)) begin
                            rs_q2_ready[wake_i] <= 1'b1;
                            rs_v2[wake_i] <= cdb_data;
                        end
                    end
                end

                if (rob_valid[cdb_rob_tag] && (rob_tid[cdb_rob_tag] == cdb_tid)) begin
                    rob_ready[cdb_rob_tag] <= 1'b1;
                    rob_value[cdb_rob_tag] <= cdb_data;
                end else begin
                    stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                end

                if (exec_valid && (exec_cycles_left <= 32'd1)) begin
                    rs_valid[exec_entry] <= 1'b0;
                    rs_issued[exec_entry] <= 1'b0;
                    exec_valid <= 1'b0;
                    completed_count <= completed_count + 32'd1;
                end
            end

            if ((rob_count != 0) && rob_valid[rob_head]) begin
                if (rob_ready[rob_head]) begin
                    trace_commit_valid <= 1'b1;
                    trace_commit_rob <= rob_head;
                    trace_commit_rd <= rob_rd[rob_head];
                    trace_commit_data <= rob_value[rob_head];
                    if (rob_dest_valid[rob_head] && (rob_rd[rob_head] != 5'd0)) begin
                        regs[rob_tid[rob_head]][rob_rd[rob_head]] <= rob_value[rob_head];
                        if (reg_busy[rob_tid[rob_head]][rob_rd[rob_head]] &&
                            (reg_tag[rob_tid[rob_head]][rob_rd[rob_head]] == rob_head)) begin
                            reg_busy[rob_tid[rob_head]][rob_rd[rob_head]] <= 1'b0;
                            reg_tag[rob_tid[rob_head]][rob_rd[rob_head]] <= '0;
                        end else if (reg_busy[rob_tid[rob_head]][rob_rd[rob_head]]) begin
                            stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                        end
                    end else if (rob_dest_valid[rob_head] && (rob_rd[rob_head] == 5'd0)) begin
                        x0_commit_suppressed_count <= x0_commit_suppressed_count + 32'd1;
                    end
                    rob_valid[rob_head] <= 1'b0;
                    rob_ready[rob_head] <= 1'b0;
                    if (!(issue_valid && issue_op_supported && free_rs_found && rob_has_space)) begin
                        rob_count <= rob_count - 32'd1;
                    end
                    rob_head <= inc_rob(rob_head);
                    commit_count <= commit_count + 32'd1;
                    if (rob_tid[rob_head]) thread1_commit_count <= thread1_commit_count + 32'd1;
                    else thread0_commit_count <= thread0_commit_count + 32'd1;
                end else begin
                    trace_commit_stall <= 1'b1;
                    commit_stall_count <= commit_stall_count + 32'd1;
                    for (younger_i = 0; younger_i < ROB_ENTRIES; younger_i = younger_i + 1) begin
                        if (rob_valid[younger_i] && rob_ready[younger_i] && (rob_seq[younger_i] > rob_seq[rob_head])) begin
                            younger_done_waiting_count <= younger_done_waiting_count + 32'd1;
                        end
                    end
                end
            end

            if (exec_valid && (exec_cycles_left > 32'd1)) begin
                exec_cycles_left <= exec_cycles_left - 32'd1;
            end else if (!exec_valid && selected_found) begin
                exec_valid <= 1'b1;
                exec_entry <= selected_entry;
                exec_tid <= rs_tid[selected_entry];
                exec_op <= rs_op[selected_entry];
                exec_rd <= rs_rd[selected_entry];
                exec_v1 <= rs_v1[selected_entry];
                exec_v2 <= rs_v2[selected_entry];
                exec_rob_tag <= rs_dst_tag[selected_entry];
                exec_cycles_left <= (ALU_LATENCY < 1) ? 32'd1 : ALU_LATENCY[31:0];
                rs_issued[selected_entry] <= 1'b1;
                issued_count <= issued_count + 32'd1;
                trace_issue_valid <= 1'b1;
                trace_issue_rs <= selected_entry;
                trace_issue_rob <= rs_dst_tag[selected_entry];
                if (older_waiting_found) begin
                    ooo_issue_count <= ooo_issue_count + 32'd1;
                end
            end

            if (issue_valid && !issue_op_supported) begin
                unsupported_count <= unsupported_count + 32'd1;
            end else if (issue_valid && issue_op_supported && free_rs_found && rob_has_space) begin
                rob_valid[rob_tail] <= 1'b1;
                rob_ready[rob_tail] <= 1'b0;
                rob_tid[rob_tail] <= issue_tid;
                rob_rd[rob_tail] <= issue_rd;
                rob_dest_valid[rob_tail] <= 1'b1;
                rob_value[rob_tail] <= 32'd0;
                rob_seq[rob_tail] <= next_seq;

                rs_valid[free_rs_entry] <= 1'b1;
                rs_issued[free_rs_entry] <= 1'b0;
                rs_tid[free_rs_entry] <= issue_tid;
                rs_op[free_rs_entry] <= issue_op;
                rs_rd[free_rs_entry] <= issue_rd;
                rs_v1[free_rs_entry] <= alloc_src1_value;
                rs_v2[free_rs_entry] <= alloc_src2_value;
                rs_q1_ready[free_rs_entry] <= alloc_src1_ready;
                rs_q2_ready[free_rs_entry] <= alloc_src2_ready;
                rs_q1_tag[free_rs_entry] <= alloc_src1_tag;
                rs_q2_tag[free_rs_entry] <= alloc_src2_tag;
                rs_dst_tag[free_rs_entry] <= rob_tail;
                rs_seq[free_rs_entry] <= next_seq;

                if (issue_rd != 5'd0) begin
                    reg_busy[issue_tid][issue_rd] <= 1'b1;
                    reg_tag[issue_tid][issue_rd] <= rob_tail;
                end

                trace_dispatch_valid <= 1'b1;
                trace_dispatch_rob <= rob_tail;
                trace_dispatch_rs <= free_rs_entry;
                trace_dispatch_op <= issue_op;
                trace_dispatch_rd <= issue_rd;
                dispatched_count <= dispatched_count + 32'd1;
                rob_alloc_count <= rob_alloc_count + 32'd1;
                rs_alloc_count <= rs_alloc_count + 32'd1;
                rob_tail <= inc_rob(rob_tail);
                if ((rob_count != 0) && rob_valid[rob_head] && rob_ready[rob_head]) begin
                    rob_count <= rob_count;
                end else begin
                    rob_count <= rob_count + 32'd1;
                end
                next_seq <= next_seq + 8'd1;
            end else if (issue_valid && issue_op_supported && !rob_has_space) begin
                rob_full_stall_count <= rob_full_stall_count + 32'd1;
            end else if (issue_valid && issue_op_supported && !free_rs_found) begin
                rs_full_stall_count <= rs_full_stall_count + 32'd1;
            end
        end
    end
endmodule





