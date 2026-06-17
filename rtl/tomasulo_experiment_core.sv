`timescale 1ns/1ps

module tomasulo_experiment_core #(
    parameter NUM_THREADS = 2,
    parameter RS_ENTRIES = 4,
    parameter TAG_WIDTH = 8,
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
    output logic [TAG_WIDTH-1:0] issue_dst_tag,

    input  logic                 debug_write_valid,
    input  logic                 debug_write_tid,
    input  logic [4:0]           debug_write_rd,
    input  logic [31:0]          debug_write_data,
    input  logic                 debug_set_busy_valid,
    input  logic                 debug_set_busy_tid,
    input  logic [4:0]           debug_set_busy_rd,
    input  logic [TAG_WIDTH-1:0] debug_set_busy_tag,
    input  logic                 debug_cdb_valid,
    input  logic                 debug_cdb_tid,
    input  logic [4:0]           debug_cdb_rd,
    input  logic [TAG_WIDTH-1:0] debug_cdb_tag,
    input  logic [31:0]          debug_cdb_data,

    output logic [31:0] accepted_count,
    output logic [31:0] rs_alloc_count,
    output logic [31:0] rs_full_stall_count,
    output logic [31:0] ready_observed_count,
    output logic [31:0] issued_count,
    output logic [31:0] ooo_issue_count,
    output logic [31:0] broadcast_count,
    output logic [31:0] wakeup_count,
    output logic [31:0] stale_tag_ignored_count,
    output logic [31:0] completed_count,
    output logic [31:0] unsupported_count,
    output logic [31:0] thread0_accepted_count,
    output logic [31:0] thread1_accepted_count,
    output logic [31:0] thread0_issued_count,
    output logic [31:0] thread1_issued_count,
    output logic [31:0] thread0_completed_count,
    output logic [31:0] thread1_completed_count,

    output logic                 trace_alloc_valid,
    output logic [$clog2(RS_ENTRIES)-1:0] trace_alloc_entry,
    output logic [TAG_WIDTH-1:0] trace_alloc_tag,
    output logic                 trace_issue_valid,
    output logic [$clog2(RS_ENTRIES)-1:0] trace_issue_entry,
    output logic [TAG_WIDTH-1:0] trace_issue_tag,
    output logic                 trace_cdb_valid,
    output logic [TAG_WIDTH-1:0] trace_cdb_tag,
    output logic [4:0]           trace_cdb_rd,
    output logic [31:0]          trace_cdb_data,
    output logic [3:0]           trace_wakeup_count
);
    localparam OP_ADD  = 4'd0;
    localparam OP_SUB  = 4'd1;
    localparam OP_AND  = 4'd2;
    localparam OP_OR   = 4'd3;
    localparam OP_XOR  = 4'd4;
    localparam OP_ADDI = 4'd5;
    localparam RS_INDEX_WIDTH = $clog2(RS_ENTRIES);

    logic [31:0] regs [0:NUM_THREADS-1][0:31];
    logic reg_busy [0:NUM_THREADS-1][0:31];
    logic [TAG_WIDTH-1:0] reg_tag [0:NUM_THREADS-1][0:31];

    logic rs_valid [0:RS_ENTRIES-1];
    logic rs_issued [0:RS_ENTRIES-1];
    logic rs_tid [0:RS_ENTRIES-1];
    logic [3:0] rs_op [0:RS_ENTRIES-1];
    logic [4:0] rs_rd [0:RS_ENTRIES-1];
    logic [31:0] rs_v1 [0:RS_ENTRIES-1];
    logic [31:0] rs_v2 [0:RS_ENTRIES-1];
    logic rs_q1_ready [0:RS_ENTRIES-1];
    logic rs_q2_ready [0:RS_ENTRIES-1];
    logic [TAG_WIDTH-1:0] rs_q1_tag [0:RS_ENTRIES-1];
    logic [TAG_WIDTH-1:0] rs_q2_tag [0:RS_ENTRIES-1];
    logic [TAG_WIDTH-1:0] rs_dst_tag [0:RS_ENTRIES-1];
    logic [TAG_WIDTH-1:0] rs_seq [0:RS_ENTRIES-1];

    logic [TAG_WIDTH-1:0] next_tag;
    logic [TAG_WIDTH-1:0] next_seq;
    logic free_found;
    logic [$clog2(RS_ENTRIES)-1:0] free_entry;
    logic selected_found;
    logic [$clog2(RS_ENTRIES)-1:0] selected_entry;
    logic older_waiting_found;
    logic issue_op_supported;
    logic alloc_src1_ready;
    logic alloc_src2_ready;
    logic [31:0] alloc_src1_value;
    logic [31:0] alloc_src2_value;
    logic [TAG_WIDTH-1:0] alloc_src1_tag;
    logic [TAG_WIDTH-1:0] alloc_src2_tag;
    logic [31:0] ready_this_cycle;

    logic exec_valid;
    logic [$clog2(RS_ENTRIES)-1:0] exec_entry;
    logic exec_tid;
    logic [3:0] exec_op;
    logic [4:0] exec_rd;
    logic [31:0] exec_v1;
    logic [31:0] exec_v2;
    logic [TAG_WIDTH-1:0] exec_tag;
    logic [31:0] exec_cycles_left;
    logic [31:0] alu_result;
    /* verilator lint_off UNUSEDSIGNAL */
    logic alu_supported;
    /* verilator lint_on UNUSEDSIGNAL */

    logic cdb_fire;
    logic cdb_tid;
    logic [4:0] cdb_rd;
    logic [TAG_WIDTH-1:0] cdb_tag;
    logic [31:0] cdb_data;
    logic [3:0] wake_events;

    integer free_i;
    integer select_i;
    integer reset_t;
    integer reset_r;
    integer reset_s;
    integer update_s;

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

    tomasulo_alu_model u_alu (
        .op(exec_op),
        .src1(exec_v1),
        .src2(exec_v2),
        .result(alu_result),
        .supported(alu_supported)
    );

    always_comb begin
        free_found = 1'b0;
        free_entry = '0;
        for (free_i = 0; free_i < RS_ENTRIES; free_i = free_i + 1) begin
            if (!free_found && !rs_valid[free_i]) begin
                free_found = 1'b1;
                free_entry = to_rs_index(free_i);
            end
        end

        issue_op_supported = (issue_op == OP_ADD) || (issue_op == OP_SUB) ||
                             (issue_op == OP_AND) || (issue_op == OP_OR) ||
                             (issue_op == OP_XOR) || (issue_op == OP_ADDI);
        issue_ready = free_found && issue_op_supported;
        issue_dst_tag = next_tag;

        alloc_src1_ready = !issue_src1_needed || (issue_rs1 == 5'd0) ||
                           !reg_busy[issue_tid][issue_rs1];
        alloc_src1_value = (issue_rs1 == 5'd0) ? 32'd0 : regs[issue_tid][issue_rs1];
        alloc_src1_tag = reg_tag[issue_tid][issue_rs1];

        if (issue_src2_is_imm) begin
            alloc_src2_ready = 1'b1;
            alloc_src2_value = issue_imm;
            alloc_src2_tag = '0;
        end else begin
            alloc_src2_ready = !issue_src2_needed || (issue_rs2 == 5'd0) ||
                               !reg_busy[issue_tid][issue_rs2];
            alloc_src2_value = (issue_rs2 == 5'd0) ? 32'd0 : regs[issue_tid][issue_rs2];
            alloc_src2_tag = reg_tag[issue_tid][issue_rs2];
        end

        selected_found = 1'b0;
        selected_entry = '0;
        older_waiting_found = 1'b0;
        ready_this_cycle = 32'd0;
        for (select_i = 0; select_i < RS_ENTRIES; select_i = select_i + 1) begin
            if (rs_valid[select_i] && !rs_issued[select_i] && rs_q1_ready[select_i] && rs_q2_ready[select_i]) begin
                ready_this_cycle = ready_this_cycle + 32'd1;
                if (!selected_found) begin
                    selected_found = 1'b1;
                    selected_entry = to_rs_index(select_i);
                end
            end
        end

        if (selected_found) begin
            if ((RS_ENTRIES > 0) && rs_valid[0] && !rs_issued[0] && (rs_seq[0] < rs_seq[selected_entry]) &&
                !(rs_q1_ready[0] && rs_q2_ready[0])) begin
                older_waiting_found = 1'b1;
            end
            if ((RS_ENTRIES > 1) && rs_valid[1] && !rs_issued[1] && (rs_seq[1] < rs_seq[selected_entry]) &&
                !(rs_q1_ready[1] && rs_q2_ready[1])) begin
                older_waiting_found = 1'b1;
            end
            if ((RS_ENTRIES > 2) && rs_valid[2] && !rs_issued[2] && (rs_seq[2] < rs_seq[selected_entry]) &&
                !(rs_q1_ready[2] && rs_q2_ready[2])) begin
                older_waiting_found = 1'b1;
            end
            if ((RS_ENTRIES > 3) && rs_valid[3] && !rs_issued[3] && (rs_seq[3] < rs_seq[selected_entry]) &&
                !(rs_q1_ready[3] && rs_q2_ready[3])) begin
                older_waiting_found = 1'b1;
            end
        end
    end

    always_comb begin
        cdb_fire = 1'b0;
        cdb_tid = 1'b0;
        cdb_rd = 5'd0;
        cdb_tag = '0;
        cdb_data = 32'd0;
        if (exec_valid && (exec_cycles_left <= 32'd1)) begin
            cdb_fire = 1'b1;
            cdb_tid = exec_tid;
            cdb_rd = exec_rd;
            cdb_tag = exec_tag;
            cdb_data = alu_result;
        end else if (debug_cdb_valid) begin
            cdb_fire = 1'b1;
            cdb_tid = debug_cdb_tid;
            cdb_rd = debug_cdb_rd;
            cdb_tag = debug_cdb_tag;
            cdb_data = debug_cdb_data;
        end
    end

    always_comb begin
        wake_events = 4'd0;
        if (cdb_fire) begin
            if ((RS_ENTRIES > 0) && rs_valid[0] && (rs_tid[0] == cdb_tid)) begin
                if (!rs_q1_ready[0] && (rs_q1_tag[0] == cdb_tag)) wake_events = wake_events + 4'd1;
                if (!rs_q2_ready[0] && (rs_q2_tag[0] == cdb_tag)) wake_events = wake_events + 4'd1;
            end
            if ((RS_ENTRIES > 1) && rs_valid[1] && (rs_tid[1] == cdb_tid)) begin
                if (!rs_q1_ready[1] && (rs_q1_tag[1] == cdb_tag)) wake_events = wake_events + 4'd1;
                if (!rs_q2_ready[1] && (rs_q2_tag[1] == cdb_tag)) wake_events = wake_events + 4'd1;
            end
            if ((RS_ENTRIES > 2) && rs_valid[2] && (rs_tid[2] == cdb_tid)) begin
                if (!rs_q1_ready[2] && (rs_q1_tag[2] == cdb_tag)) wake_events = wake_events + 4'd1;
                if (!rs_q2_ready[2] && (rs_q2_tag[2] == cdb_tag)) wake_events = wake_events + 4'd1;
            end
            if ((RS_ENTRIES > 3) && rs_valid[3] && (rs_tid[3] == cdb_tid)) begin
                if (!rs_q1_ready[3] && (rs_q1_tag[3] == cdb_tag)) wake_events = wake_events + 4'd1;
                if (!rs_q2_ready[3] && (rs_q2_tag[3] == cdb_tag)) wake_events = wake_events + 4'd1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_tag <= {{(TAG_WIDTH-1){1'b0}}, 1'b1};
            next_seq <= '0;
            exec_valid <= 1'b0;
            exec_entry <= '0;
            exec_tid <= 1'b0;
            exec_op <= OP_ADD;
            exec_rd <= 5'd0;
            exec_v1 <= 32'd0;
            exec_v2 <= 32'd0;
            exec_tag <= '0;
            exec_cycles_left <= 32'd0;
            accepted_count <= 32'd0;
            rs_alloc_count <= 32'd0;
            rs_full_stall_count <= 32'd0;
            ready_observed_count <= 32'd0;
            issued_count <= 32'd0;
            ooo_issue_count <= 32'd0;
            broadcast_count <= 32'd0;
            wakeup_count <= 32'd0;
            stale_tag_ignored_count <= 32'd0;
            completed_count <= 32'd0;
            unsupported_count <= 32'd0;
            thread0_accepted_count <= 32'd0;
            thread1_accepted_count <= 32'd0;
            thread0_issued_count <= 32'd0;
            thread1_issued_count <= 32'd0;
            thread0_completed_count <= 32'd0;
            thread1_completed_count <= 32'd0;
            trace_alloc_valid <= 1'b0;
            trace_alloc_entry <= '0;
            trace_alloc_tag <= '0;
            trace_issue_valid <= 1'b0;
            trace_issue_entry <= '0;
            trace_issue_tag <= '0;
            trace_cdb_valid <= 1'b0;
            trace_cdb_tag <= '0;
            trace_cdb_rd <= 5'd0;
            trace_cdb_data <= 32'd0;
            trace_wakeup_count <= 4'd0;
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
                rs_seq[reset_s] <= '0;
            end
        end else begin
            trace_alloc_valid <= 1'b0;
            trace_issue_valid <= 1'b0;
            trace_cdb_valid <= 1'b0;
            trace_wakeup_count <= 4'd0;
            reg_busy[0][0] <= 1'b0;
            reg_busy[1][0] <= 1'b0;
            regs[0][0] <= 32'd0;
            regs[1][0] <= 32'd0;

            if (ready_this_cycle != 0) begin
                ready_observed_count <= ready_observed_count + ready_this_cycle;
            end

            if (debug_write_valid && (debug_write_rd != 5'd0)) begin
                regs[debug_write_tid][debug_write_rd] <= debug_write_data;
                reg_busy[debug_write_tid][debug_write_rd] <= 1'b0;
                reg_tag[debug_write_tid][debug_write_rd] <= '0;
            end

            if (debug_set_busy_valid && (debug_set_busy_rd != 5'd0)) begin
                reg_busy[debug_set_busy_tid][debug_set_busy_rd] <= 1'b1;
                reg_tag[debug_set_busy_tid][debug_set_busy_rd] <= debug_set_busy_tag;
            end

            if (cdb_fire) begin
                trace_cdb_valid <= 1'b1;
                trace_cdb_tag <= cdb_tag;
                trace_cdb_rd <= cdb_rd;
                trace_cdb_data <= cdb_data;
                trace_wakeup_count <= wake_events;
                broadcast_count <= broadcast_count + 32'd1;
                wakeup_count <= wakeup_count + {28'd0, wake_events};

                for (update_s = 0; update_s < RS_ENTRIES; update_s = update_s + 1) begin
                    if (rs_valid[update_s] && (rs_tid[update_s] == cdb_tid)) begin
                        if (!rs_q1_ready[update_s] && (rs_q1_tag[update_s] == cdb_tag)) begin
                            rs_q1_ready[update_s] <= 1'b1;
                            rs_v1[update_s] <= cdb_data;
                        end
                        if (!rs_q2_ready[update_s] && (rs_q2_tag[update_s] == cdb_tag)) begin
                            rs_q2_ready[update_s] <= 1'b1;
                            rs_v2[update_s] <= cdb_data;
                        end
                    end
                end

                if (cdb_rd != 5'd0) begin
                    if (reg_busy[cdb_tid][cdb_rd] && (reg_tag[cdb_tid][cdb_rd] == cdb_tag)) begin
                        regs[cdb_tid][cdb_rd] <= cdb_data;
                        reg_busy[cdb_tid][cdb_rd] <= 1'b0;
                        reg_tag[cdb_tid][cdb_rd] <= '0;
                    end else begin
                        stale_tag_ignored_count <= stale_tag_ignored_count + 32'd1;
                    end
                end

                if (exec_valid && (exec_cycles_left <= 32'd1)) begin
                    rs_valid[exec_entry] <= 1'b0;
                    rs_issued[exec_entry] <= 1'b0;
                    exec_valid <= 1'b0;
                    completed_count <= completed_count + 32'd1;
                    if (exec_tid) thread1_completed_count <= thread1_completed_count + 32'd1;
                    else thread0_completed_count <= thread0_completed_count + 32'd1;
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
                exec_tag <= rs_dst_tag[selected_entry];
                exec_cycles_left <= (ALU_LATENCY < 1) ? 32'd1 : ALU_LATENCY[31:0];
                rs_issued[selected_entry] <= 1'b1;
                issued_count <= issued_count + 32'd1;
                trace_issue_valid <= 1'b1;
                trace_issue_entry <= selected_entry;
                trace_issue_tag <= rs_dst_tag[selected_entry];
                if (older_waiting_found) begin
                    ooo_issue_count <= ooo_issue_count + 32'd1;
                end
                if (rs_tid[selected_entry]) thread1_issued_count <= thread1_issued_count + 32'd1;
                else thread0_issued_count <= thread0_issued_count + 32'd1;
            end

            if (issue_valid && !issue_op_supported) begin
                unsupported_count <= unsupported_count + 32'd1;
            end else if (issue_valid && issue_op_supported && free_found) begin
                rs_valid[free_entry] <= 1'b1;
                rs_issued[free_entry] <= 1'b0;
                rs_tid[free_entry] <= issue_tid;
                rs_op[free_entry] <= issue_op;
                rs_rd[free_entry] <= issue_rd;
                rs_v1[free_entry] <= alloc_src1_value;
                rs_v2[free_entry] <= alloc_src2_value;
                rs_q1_ready[free_entry] <= alloc_src1_ready;
                rs_q2_ready[free_entry] <= alloc_src2_ready;
                rs_q1_tag[free_entry] <= alloc_src1_tag;
                rs_q2_tag[free_entry] <= alloc_src2_tag;
                rs_dst_tag[free_entry] <= next_tag;
                rs_seq[free_entry] <= next_seq;
                trace_alloc_valid <= 1'b1;
                trace_alloc_entry <= free_entry;
                trace_alloc_tag <= next_tag;
                accepted_count <= accepted_count + 32'd1;
                rs_alloc_count <= rs_alloc_count + 32'd1;
                if (issue_tid) thread1_accepted_count <= thread1_accepted_count + 32'd1;
                else thread0_accepted_count <= thread0_accepted_count + 32'd1;
                if (issue_rd != 5'd0) begin
                    reg_busy[issue_tid][issue_rd] <= 1'b1;
                    reg_tag[issue_tid][issue_rd] <= next_tag;
                end
                next_tag <= next_tag + {{(TAG_WIDTH-1){1'b0}}, 1'b1};
                next_seq <= next_seq + {{(TAG_WIDTH-1){1'b0}}, 1'b1};
            end else if (issue_valid && issue_op_supported && !free_found) begin
                rs_full_stall_count <= rs_full_stall_count + 32'd1;
            end
        end
    end
endmodule
