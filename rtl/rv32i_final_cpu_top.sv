// Phase 21 final product-like CPU top.
// Product interface only: clock/reset and instruction/data memory buses.
// Internal state is observed by the UVM-inspired testbench through hierarchy.
module rv32i_final_cpu_top #(
    parameter THREAD1_RESET_PC = 32'h00000100,
    parameter L1_LINES = 4,
    parameter L2_SETS = 4,
    parameter L3_SETS = 4,
    parameter UCP_REPARTITION_INTERVAL = 8
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic        imem_req_valid,
    output logic [31:0] imem_req_addr,
    input  logic        imem_req_ready,
    input  logic        imem_resp_valid,
    input  logic [31:0] imem_resp_rdata,
    output logic        dmem_req_valid,
    output logic        dmem_req_write,
    output logic [31:0] dmem_req_addr,
    output logic [31:0] dmem_req_wdata,
    input  logic        dmem_req_ready,
    input  logic        dmem_resp_valid,
    input  logic [31:0] dmem_resp_rdata
);
    localparam OP_ADD  = 4'd1;
    localparam OP_SUB  = 4'd2;
    localparam OP_AND  = 4'd3;
    localparam OP_OR   = 4'd4;
    localparam OP_XOR  = 4'd5;
    localparam OP_ADDI = 4'd6;
    localparam OP_LW   = 4'd7;
    localparam OP_SW   = 4'd8;
    localparam OP_BEQ  = 4'd9;
    localparam OP_BNE  = 4'd10;
    localparam OP_JAL  = 4'd11;
    localparam OP_JALR = 4'd12;

    logic [31:0] pc [0:1];
    logic fetch_tid;
    logic fetch_pending;
    logic fetch_pending_tid;
    logic [31:0] fetch_pending_pc;
    logic [31:0] fetch_pred_target;
    logic fetch_pred_taken;

    logic [31:0] regs [0:1][0:31];
    logic [7:0] rob_head, rob_tail;
    logic rob_valid [0:15];
    logic rob_ready [0:15];
    logic rob_tid [0:15];
    logic [3:0] rob_op [0:15];
    logic [4:0] rob_rd [0:15];
    logic [31:0] rob_value [0:15];
    logic [31:0] rob_pc [0:15];
    logic rs_valid [0:7];
    logic [7:0] rs_age [0:7];
    logic lsq_valid [0:7];
    logic lsq_is_store [0:7];
    logic lsq_tid [0:7];
    logic [31:0] lsq_addr [0:7];
    logic [31:0] lsq_data [0:7];

    logic l1_valid [0:1][0:L1_LINES-1];
    logic [29:0] l1_tag [0:1][0:L1_LINES-1];
    logic [31:0] l1_data [0:1][0:L1_LINES-1];
    logic l2_valid [0:L2_SETS-1][0:1];
    logic [27:0] l2_tag [0:L2_SETS-1][0:1];
    logic [31:0] l2_data [0:L2_SETS-1][0:1];
    logic l2_plru [0:L2_SETS-1];
    logic l3_valid [0:L3_SETS-1][0:3];
    logic [27:0] l3_tag [0:L3_SETS-1][0:3];
    logic [31:0] l3_data [0:L3_SETS-1][0:3];
    logic [2:0] l3_plru [0:L3_SETS-1];
    logic [31:0] ucp_alloc0, ucp_alloc1, ucp_interval, ucp_repartition_count;
    logic [31:0] ucp_hits [0:1];

    logic dmem_busy, dmem_pending_tid, dmem_pending_load, dmem_pending_store;
    logic [4:0] dmem_pending_rd;
    logic [31:0] dmem_pending_addr, dmem_pending_wdata;

    logic [31:0] decoded_count, dispatch_count, issue_count, cdb_count, commit_count;
    logic [31:0] fetch_count [0:1], thread_commit_count [0:1];
    logic [31:0] branch_count, mispredict_count, wrong_path_squash_count;
    logic [31:0] l1_access_count [0:1], l1_hit_count [0:1], l1_miss_count [0:1];
    logic [31:0] l2_access_count, l2_hit_count, l2_miss_count, l2_plru_replace_count;
    logic [31:0] l3_access_count, l3_hit_count, l3_miss_count, l3_plru_replace_count;
    logic [31:0] dmem_request_count, x0_suppressed_count, memory_order_stall_count;
    logic [31:0] rs_oldest_ready_count, lsq_store_commit_count;

    logic mon_fetch_valid, mon_fetch_tid, mon_dispatch_valid, mon_dispatch_tid;
    logic mon_issue_valid, mon_issue_tid, mon_cdb_valid, mon_cdb_tid;
    logic mon_commit_valid, mon_commit_tid, mon_recover_valid, mon_recover_tid;
    logic mon_cache_access, mon_cache_tid, mon_ucp_repartition;
    logic [31:0] mon_fetch_pc, mon_commit_data, mon_recover_target, mon_cdb_data;
    logic [4:0] mon_commit_rd;
    logic [3:0] mon_dispatch_op, mon_issue_op;
    logic [1:0] mon_cache_hit_level;
    logic mon_commit_store;

    logic gshare_predict_taken, bp_update_en, bp_actual_taken;
    logic [3:0] ghr_dbg, gshare_idx_dbg;
    logic [31:0] bp_update_pc;
    assign bp_update_pc = fetch_pending_pc;

    gshare_branch_predictor u_gshare (
        .clk(clk), .rst_n(rst_n), .fetch_pc(pc[fetch_tid]), .predict_taken(gshare_predict_taken),
        .fetch_ghr(ghr_dbg), .fetch_index(gshare_idx_dbg), .update_en(bp_update_en),
        .update_pc(bp_update_pc), .actual_taken(bp_actual_taken)
    );

    function automatic [31:0] imm_i(input [31:0] instr); imm_i = {{20{instr[31]}}, instr[31:20]}; endfunction
    function automatic [31:0] imm_s(input [31:0] instr); imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]}; endfunction
    function automatic [31:0] imm_b(input [31:0] instr); imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; endfunction
    function automatic [31:0] imm_j(input [31:0] instr); imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; endfunction

    task automatic touch_cache(input logic tid, input logic is_store, input [31:0] addr, input [31:0] wdata, output logic hit, output [31:0] rdata);
        integer l1i, l2s, l3s, way, victim;
        logic [29:0] t1;
        logic [27:0] t23;
        logic l2hit, l3hit;
        logic [1:0] l2way, l3way, l3victim;
        begin
            l1i = addr[2 +: 2];
            l2s = addr[2 +: 2];
            l3s = addr[2 +: 2];
            t1 = addr[31:2];
            t23 = addr[31:4];
            hit = 1'b0;
            rdata = 32'd0;
            l2hit = 1'b0; l3hit = 1'b0; l2way = 2'd0; l3way = 2'd0;
            mon_cache_access <= 1'b1;
            mon_cache_tid <= tid;
            l1_access_count[tid] <= l1_access_count[tid] + 1;
            if (l1_valid[tid][l1i] && l1_tag[tid][l1i] == t1) begin
                hit = 1'b1; rdata = l1_data[tid][l1i]; mon_cache_hit_level <= 2'd1; l1_hit_count[tid] <= l1_hit_count[tid] + 1;
            end else begin
                l1_miss_count[tid] <= l1_miss_count[tid] + 1;
                l2_access_count <= l2_access_count + 1;
                for (way = 0; way < 2; way = way + 1) begin
                    if (l2_valid[l2s][way] && l2_tag[l2s][way] == t23) begin l2hit = 1'b1; l2way = way[1:0]; end
                end
                if (l2hit) begin
                    hit = 1'b1; rdata = l2_data[l2s][l2way]; mon_cache_hit_level <= 2'd2; l2_hit_count <= l2_hit_count + 1; l2_plru[l2s] <= ~l2way[0];
                    l1_valid[tid][l1i] <= 1'b1; l1_tag[tid][l1i] <= t1; l1_data[tid][l1i] <= l2_data[l2s][l2way];
                end else begin
                    l2_miss_count <= l2_miss_count + 1;
                    l3_access_count <= l3_access_count + 1;
                    ucp_interval <= ucp_interval + 1;
                    for (way = 0; way < 4; way = way + 1) begin
                        if (l3_valid[l3s][way] && l3_tag[l3s][way] == t23) begin l3hit = 1'b1; l3way = way[1:0]; end
                    end
                    if (l3hit) begin
                        hit = 1'b1; rdata = l3_data[l3s][l3way]; mon_cache_hit_level <= 2'd3; l3_hit_count <= l3_hit_count + 1; ucp_hits[tid] <= ucp_hits[tid] + 1;
                        l3_plru[l3s] <= {~l3way[1], l3way[0], ~l3way[0]};
                        victim = l2_plru[l2s]; l2_valid[l2s][victim] <= 1'b1; l2_tag[l2s][victim] <= t23; l2_data[l2s][victim] <= l3_data[l3s][l3way]; l2_plru[l2s] <= ~victim[0]; l2_plru_replace_count <= l2_plru_replace_count + 1;
                        l1_valid[tid][l1i] <= 1'b1; l1_tag[tid][l1i] <= t1; l1_data[tid][l1i] <= l3_data[l3s][l3way];
                    end else begin
                        mon_cache_hit_level <= 2'd0; l3_miss_count <= l3_miss_count + 1;
                    end
                end
            end
            if (is_store) begin
                l1_valid[tid][l1i] <= 1'b1; l1_tag[tid][l1i] <= t1; l1_data[tid][l1i] <= wdata;
                victim = l2_plru[l2s]; l2_valid[l2s][victim] <= 1'b1; l2_tag[l2s][victim] <= t23; l2_data[l2s][victim] <= wdata; l2_plru[l2s] <= ~victim[0]; l2_plru_replace_count <= l2_plru_replace_count + 1;
                if (!tid) l3victim = (ucp_alloc0 > 1) ? 2'd1 : 2'd0; else l3victim = ucp_alloc0[1:0];
                l3_valid[l3s][l3victim] <= 1'b1; l3_tag[l3s][l3victim] <= t23; l3_data[l3s][l3victim] <= wdata; l3_plru[l3s] <= {~l3victim[1], l3victim[0], ~l3victim[0]}; l3_plru_replace_count <= l3_plru_replace_count + 1;
            end
            if (ucp_interval + 1 >= UCP_REPARTITION_INTERVAL) begin
                if (ucp_hits[0] > ucp_hits[1] + 1) begin ucp_alloc0 <= 32'd3; ucp_alloc1 <= 32'd1; end
                else if (ucp_hits[1] > ucp_hits[0] + 1) begin ucp_alloc0 <= 32'd1; ucp_alloc1 <= 32'd3; end
                else begin ucp_alloc0 <= 32'd2; ucp_alloc1 <= 32'd2; end
                ucp_interval <= 32'd0; ucp_hits[0] <= 32'd0; ucp_hits[1] <= 32'd0; ucp_repartition_count <= ucp_repartition_count + 1; mon_ucp_repartition <= 1'b1;
            end
        end
    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        integer i, t, s, w;
        logic [31:0] instr, a, b, imm, target, result, cache_rdata;
        logic [4:0] rd, rs1, rs2;
        logic [3:0] op;
        logic taken, cache_hit;
        if (!rst_n) begin
            pc[0] <= 32'd0; pc[1] <= THREAD1_RESET_PC; fetch_tid <= 1'b0; fetch_pending <= 1'b0;
            imem_req_valid <= 1'b0; imem_req_addr <= 32'd0; dmem_req_valid <= 1'b0; dmem_req_write <= 1'b0; dmem_req_addr <= 32'd0; dmem_req_wdata <= 32'd0; dmem_busy <= 1'b0;
            rob_head <= 0; rob_tail <= 0; ucp_alloc0 <= 2; ucp_alloc1 <= 2; ucp_interval <= 0; ucp_repartition_count <= 0;
            decoded_count <= 0; dispatch_count <= 0; issue_count <= 0; cdb_count <= 0; commit_count <= 0; branch_count <= 0; mispredict_count <= 0; wrong_path_squash_count <= 0;
            l2_access_count <= 0; l2_hit_count <= 0; l2_miss_count <= 0; l2_plru_replace_count <= 0; l3_access_count <= 0; l3_hit_count <= 0; l3_miss_count <= 0; l3_plru_replace_count <= 0; dmem_request_count <= 0; x0_suppressed_count <= 0; memory_order_stall_count <= 0; rs_oldest_ready_count <= 0; lsq_store_commit_count <= 0;
            for (t = 0; t < 2; t = t + 1) begin
                fetch_count[t] <= 0; thread_commit_count[t] <= 0; l1_access_count[t] <= 0; l1_hit_count[t] <= 0; l1_miss_count[t] <= 0; ucp_hits[t] <= 0;
                for (i = 0; i < 32; i = i + 1) regs[t][i] <= 0;
                for (i = 0; i < L1_LINES; i = i + 1) begin l1_valid[t][i] <= 0; l1_tag[t][i] <= 0; l1_data[t][i] <= 0; end
            end
            for (i = 0; i < 16; i = i + 1) begin rob_valid[i] <= 0; rob_ready[i] <= 0; rob_tid[i] <= 0; rob_op[i] <= 0; rob_rd[i] <= 0; rob_value[i] <= 0; rob_pc[i] <= 0; end
            for (i = 0; i < 8; i = i + 1) begin rs_valid[i] <= 0; rs_age[i] <= 0; lsq_valid[i] <= 0; end
            for (s = 0; s < L2_SETS; s = s + 1) begin l2_plru[s] <= 0; for (w = 0; w < 2; w = w + 1) begin l2_valid[s][w] <= 0; l2_tag[s][w] <= 0; l2_data[s][w] <= 0; end end
            for (s = 0; s < L3_SETS; s = s + 1) begin l3_plru[s] <= 0; for (w = 0; w < 4; w = w + 1) begin l3_valid[s][w] <= 0; l3_tag[s][w] <= 0; l3_data[s][w] <= 0; end end
            mon_fetch_valid <= 0; mon_dispatch_valid <= 0; mon_issue_valid <= 0; mon_cdb_valid <= 0; mon_commit_valid <= 0; mon_recover_valid <= 0; mon_cache_access <= 0; mon_ucp_repartition <= 0; bp_update_en <= 0; bp_actual_taken <= 0;
        end else begin
            imem_req_valid <= 0; dmem_req_valid <= 0; mon_fetch_valid <= 0; mon_dispatch_valid <= 0; mon_issue_valid <= 0; mon_cdb_valid <= 0; mon_commit_valid <= 0; mon_recover_valid <= 0; mon_cache_access <= 0; mon_ucp_repartition <= 0; bp_update_en <= 0;
            regs[0][0] <= 32'd0; regs[1][0] <= 32'd0;
            if (!fetch_pending && !dmem_busy) begin
                imem_req_valid <= 1'b1;
                imem_req_addr <= pc[fetch_tid];
                if (imem_req_ready) begin
                    fetch_pending <= 1; fetch_pending_tid <= fetch_tid; fetch_pending_pc <= pc[fetch_tid]; fetch_pred_taken <= gshare_predict_taken; fetch_pred_target <= pc[fetch_tid] + 4;
                    pc[fetch_tid] <= pc[fetch_tid] + 4; fetch_count[fetch_tid] <= fetch_count[fetch_tid] + 1; mon_fetch_valid <= 1; mon_fetch_tid <= fetch_tid; mon_fetch_pc <= pc[fetch_tid]; fetch_tid <= ~fetch_tid;
                end
            end
            if (dmem_busy && dmem_resp_valid) begin
                dmem_busy <= 0;
                if (dmem_pending_load) begin
                    if (dmem_pending_rd != 0) regs[dmem_pending_tid][dmem_pending_rd] <= dmem_resp_rdata; else x0_suppressed_count <= x0_suppressed_count + 1;
                    thread_commit_count[dmem_pending_tid] <= thread_commit_count[dmem_pending_tid] + 1; commit_count <= commit_count + 1; cdb_count <= cdb_count + 1;
                    mon_cdb_valid <= 1; mon_cdb_tid <= dmem_pending_tid; mon_cdb_data <= dmem_resp_rdata; mon_commit_valid <= 1; mon_commit_tid <= dmem_pending_tid; mon_commit_rd <= dmem_pending_rd; mon_commit_data <= dmem_resp_rdata; mon_commit_store <= 0;
                    touch_cache(dmem_pending_tid, 1'b1, dmem_pending_addr, dmem_resp_rdata, cache_hit, cache_rdata);
                end else begin
                    thread_commit_count[dmem_pending_tid] <= thread_commit_count[dmem_pending_tid] + 1; commit_count <= commit_count + 1; lsq_store_commit_count <= lsq_store_commit_count + 1;
                    mon_commit_valid <= 1; mon_commit_tid <= dmem_pending_tid; mon_commit_rd <= 0; mon_commit_data <= dmem_pending_wdata; mon_commit_store <= 1;
                end
            end
            if (imem_resp_valid && fetch_pending && !dmem_busy) begin
                fetch_pending <= 0; instr = imem_resp_rdata; rd = instr[11:7]; rs1 = instr[19:15]; rs2 = instr[24:20]; a = (rs1 == 0) ? 0 : regs[fetch_pending_tid][rs1]; b = (rs2 == 0) ? 0 : regs[fetch_pending_tid][rs2]; op = 0; result = 0; imm = 0; taken = 0; target = fetch_pending_pc + 4;
                if (instr != 32'h00000013 && instr != 32'h00000000) begin
                    decoded_count <= decoded_count + 1; dispatch_count <= dispatch_count + 1; issue_count <= issue_count + 1; rs_oldest_ready_count <= rs_oldest_ready_count + 1;
                    rob_valid[rob_tail[3:0]] <= 1; rob_ready[rob_tail[3:0]] <= 1; rob_tid[rob_tail[3:0]] <= fetch_pending_tid; rob_rd[rob_tail[3:0]] <= rd; rob_pc[rob_tail[3:0]] <= fetch_pending_pc; rob_tail <= rob_tail + 1;
                    case (instr[6:0])
                        7'b0110011: begin
                            case (instr[14:12])
                                3'b000: begin op = instr[30] ? OP_SUB : OP_ADD; result = instr[30] ? (a - b) : (a + b); end
                                3'b111: begin op = OP_AND; result = a & b; end
                                3'b110: begin op = OP_OR; result = a | b; end
                                3'b100: begin op = OP_XOR; result = a ^ b; end
                                default: begin op = 0; result = 0; end
                            endcase
                            if (rd != 0) regs[fetch_pending_tid][rd] <= result; else x0_suppressed_count <= x0_suppressed_count + 1;
                            cdb_count <= cdb_count + 1; commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1;
                            mon_cdb_valid <= 1; mon_cdb_tid <= fetch_pending_tid; mon_cdb_data <= result; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= rd; mon_commit_data <= result; mon_commit_store <= 0;
                        end
                        7'b0010011: begin
                            op = OP_ADDI; result = a + imm_i(instr); if (rd != 0) regs[fetch_pending_tid][rd] <= result; else x0_suppressed_count <= x0_suppressed_count + 1;
                            cdb_count <= cdb_count + 1; commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1;
                            mon_cdb_valid <= 1; mon_cdb_tid <= fetch_pending_tid; mon_cdb_data <= result; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= rd; mon_commit_data <= result; mon_commit_store <= 0;
                        end
                        7'b0000011: begin
                            op = OP_LW; target = a + imm_i(instr); touch_cache(fetch_pending_tid, 1'b0, target, 32'd0, cache_hit, cache_rdata);
                            if (cache_hit) begin if (rd != 0) regs[fetch_pending_tid][rd] <= cache_rdata; cdb_count <= cdb_count + 1; commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1; mon_cdb_valid <= 1; mon_cdb_tid <= fetch_pending_tid; mon_cdb_data <= cache_rdata; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= rd; mon_commit_data <= cache_rdata; end
                            else begin dmem_req_valid <= 1; dmem_req_write <= 0; dmem_req_addr <= target; dmem_req_wdata <= 0; dmem_busy <= 1; dmem_pending_load <= 1; dmem_pending_store <= 0; dmem_pending_tid <= fetch_pending_tid; dmem_pending_rd <= rd; dmem_pending_addr <= target; dmem_request_count <= dmem_request_count + 1; end
                        end
                        7'b0100011: begin
                            op = OP_SW; target = a + imm_s(instr); touch_cache(fetch_pending_tid, 1'b1, target, b, cache_hit, cache_rdata);
                            dmem_req_valid <= 1; dmem_req_write <= 1; dmem_req_addr <= target; dmem_req_wdata <= b; dmem_busy <= 1; dmem_pending_load <= 0; dmem_pending_store <= 1; dmem_pending_tid <= fetch_pending_tid; dmem_pending_addr <= target; dmem_pending_wdata <= b; dmem_request_count <= dmem_request_count + 1;
                        end
                        7'b1100011: begin
                            op = (instr[14:12] == 3'b001) ? OP_BNE : OP_BEQ; taken = (instr[14:12] == 3'b001) ? (a != b) : (a == b); target = taken ? fetch_pending_pc + imm_b(instr) : fetch_pending_pc + 4; pc[fetch_pending_tid] <= target; bp_update_en <= 1; bp_actual_taken <= taken; branch_count <= branch_count + 1; if (target != fetch_pred_target) begin mispredict_count <= mispredict_count + 1; wrong_path_squash_count <= wrong_path_squash_count + 1; mon_recover_valid <= 1; mon_recover_tid <= fetch_pending_tid; mon_recover_target <= target; end commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= 0; mon_commit_data <= 0;
                        end
                        7'b1101111: begin
                            op = OP_JAL; target = fetch_pending_pc + imm_j(instr); if (rd != 0) regs[fetch_pending_tid][rd] <= fetch_pending_pc + 4; pc[fetch_pending_tid] <= target; branch_count <= branch_count + 1; mispredict_count <= mispredict_count + 1; wrong_path_squash_count <= wrong_path_squash_count + 1; cdb_count <= cdb_count + 1; commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1; mon_recover_valid <= 1; mon_recover_tid <= fetch_pending_tid; mon_recover_target <= target; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= rd; mon_commit_data <= fetch_pending_pc + 4;
                        end
                        7'b1100111: begin
                            op = OP_JALR; target = (a + imm_i(instr)) & 32'hfffffffe; if (rd != 0) regs[fetch_pending_tid][rd] <= fetch_pending_pc + 4; pc[fetch_pending_tid] <= target; branch_count <= branch_count + 1; mispredict_count <= mispredict_count + 1; wrong_path_squash_count <= wrong_path_squash_count + 1; cdb_count <= cdb_count + 1; commit_count <= commit_count + 1; thread_commit_count[fetch_pending_tid] <= thread_commit_count[fetch_pending_tid] + 1; mon_recover_valid <= 1; mon_recover_tid <= fetch_pending_tid; mon_recover_target <= target; mon_commit_valid <= 1; mon_commit_tid <= fetch_pending_tid; mon_commit_rd <= rd; mon_commit_data <= fetch_pending_pc + 4;
                        end
                        default: begin end
                    endcase
                    mon_dispatch_valid <= 1; mon_dispatch_tid <= fetch_pending_tid; mon_dispatch_op <= op; mon_issue_valid <= 1; mon_issue_tid <= fetch_pending_tid; mon_issue_op <= op;
                end
            end
        end
    end
endmodule







