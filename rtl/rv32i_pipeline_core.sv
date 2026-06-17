`timescale 1ns/1ps

module rv32i_pipeline_core #(
    parameter IMEM_HEX = "tests/phase4_pipeline_basic.hex",
    parameter BP_MODE = 2,
    parameter DMEM_LATENCY_CYCLES = 1,
    parameter DCACHE_ENABLE = 0,
    parameter DCACHE_LINES = 4,
    parameter DCACHE_MISS_PENALTY_CYCLES = 3,
    parameter L2_ENABLE = 0,
    parameter L2_LINES = 8,
    parameter L2_HIT_LATENCY = 2,
    parameter L2_MISS_PENALTY = 6,
    parameter PRIVATE_L1_ENABLE = 0,
    parameter L1_NUM_CORES = 2,
    parameter L3_ENABLE = 0,
    parameter L3_LINES = 8,
    parameter L3_UCP_ENABLE = 0,
    parameter L3_UCP_POLICY = 0,
    parameter UCP_REPARTITION_INTERVAL = 8,
    parameter STREAM_SPLIT_ADDR = 32'h00001000,
    parameter L3_HIT_LATENCY = 4,
    parameter L3_MISS_PENALTY = 12
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_dbg,
    output logic [31:0] instr_dbg,
    output logic        illegal_instr_dbg,
    output logic        trace_if_valid,
    output logic [31:0] trace_if_pc,
    output logic [31:0] trace_if_instr,
    output logic        trace_id_valid,
    output logic [31:0] trace_id_pc,
    output logic [31:0] trace_id_instr,
    output logic        trace_ex_valid,
    output logic [31:0] trace_ex_pc,
    output logic [31:0] trace_ex_instr,
    output logic        trace_mem_valid,
    output logic [31:0] trace_mem_pc,
    output logic [31:0] trace_mem_instr,
    output logic        trace_wb_valid,
    output logic [31:0] trace_wb_pc,
    output logic [31:0] trace_wb_instr,
    output logic [4:0]  trace_wb_rd,
    output logic [31:0] trace_wb_wdata,
    output logic        trace_wb_we,
    output logic        trace_stall,
    output logic        trace_flush,
    output logic        trace_redirect,
    output logic [31:0] trace_redirect_target,
    output logic        trace_bp_pred_taken,
    output logic [31:0] trace_bp_pred_target,
    output logic        trace_bp_actual_taken,
    output logic [31:0] trace_bp_actual_target,
    output logic        trace_bp_mispredict,
    output logic [1:0]  trace_bp_mode,
    output logic [3:0]  trace_bp_ghr,
    output logic [3:0]  trace_bp_index,
    output logic [31:0] bp_total_branches,
    output logic [31:0] bp_pred_taken_count,
    output logic [31:0] bp_pred_not_taken_count,
    output logic [31:0] bp_actual_taken_count,
    output logic [31:0] bp_actual_not_taken_count,
    output logic [31:0] bp_correct_count,
    output logic [31:0] bp_mispredict_count,
    output logic [31:0] perf_cycle_count,
    output logic [31:0] perf_retired_count,
    output logic [31:0] perf_stall_count,
    output logic [31:0] perf_load_use_stall_count,
    output logic [31:0] perf_flush_count,
    output logic [31:0] perf_branch_jump_flush_count,
    output logic [31:0] perf_load_count,
    output logic [31:0] perf_store_count,
    output logic [31:0] perf_mem_stall_count,
    output logic [31:0] perf_load_stall_count,
    output logic [31:0] perf_store_stall_count,
    output logic        trace_dcache_access,
    output logic        trace_dcache_load,
    output logic        trace_dcache_store,
    output logic        trace_dcache_hit,
    output logic        trace_dcache_miss,
    output logic        trace_dcache_stall,
    output logic        trace_dcache_fill,
    output logic [31:0] trace_dcache_addr,
    output logic [31:0] perf_dcache_access_count,
    output logic [31:0] perf_dcache_load_access_count,
    output logic [31:0] perf_dcache_store_access_count,
    output logic [31:0] perf_dcache_hit_count,
    output logic [31:0] perf_dcache_miss_count,
    output logic [31:0] perf_dcache_miss_stall_count,
    output logic        trace_l2_access,
    output logic        trace_l2_hit,
    output logic        trace_l2_miss,
    output logic        trace_backing_access,
    output logic [31:0] perf_l2_access_count,
    output logic [31:0] perf_l2_hit_count,
    output logic [31:0] perf_l2_miss_count,
    output logic [31:0] perf_backing_access_count,
    output logic        trace_l3_access,
    output logic        trace_l3_hit,
    output logic        trace_l3_miss,
    output logic        trace_ucp_stream_id,
    output logic [1:0]  trace_cache_hit_level,
    output logic [31:0] perf_l1_core0_access_count,
    output logic [31:0] perf_l1_core0_hit_count,
    output logic [31:0] perf_l1_core0_miss_count,
    output logic [31:0] perf_l1_core1_access_count,
    output logic [31:0] perf_l1_core1_hit_count,
    output logic [31:0] perf_l1_core1_miss_count,
    output logic [31:0] perf_l3_access_count,
    output logic [31:0] perf_l3_hit_count,
    output logic [31:0] perf_l3_miss_count,
    output logic [31:0] perf_l3_stream0_access_count,
    output logic [31:0] perf_l3_stream0_hit_count,
    output logic [31:0] perf_l3_stream0_miss_count,
    output logic [31:0] perf_l3_stream1_access_count,
    output logic [31:0] perf_l3_stream1_hit_count,
    output logic [31:0] perf_l3_stream1_miss_count,
    output logic [31:0] perf_l3_stream0_alloc_lines,
    output logic [31:0] perf_l3_stream1_alloc_lines,
    output logic [31:0] perf_l3_ucp_repartition_count,
    output logic [31:0] perf_l3_ucp_interval_count
);
    localparam WB_ALU = 2'd0;
    localparam WB_MEM = 2'd1;
    localparam WB_PC4 = 2'd2;
    localparam WB_IMM = 2'd3;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_STORE = 7'b0100011;
    localparam OPCODE_OP = 7'b0110011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JALR = 7'b1100111;
    localparam BP_MODE_NONE = 0;
    localparam BP_MODE_SIMPLE = 1;
    localparam BP_MODE_GSHARE = 2;

    logic [31:0] pc;

    logic [31:0] if_instr;
    logic [31:0] if_pc_plus4;
    logic if_is_branch;
    logic [31:0] if_branch_imm;
    logic [31:0] if_pred_target;
    logic if_bp_taken_raw;
    logic if_bp_simple_taken;
    logic if_bp_gshare_taken;
    logic [3:0] if_bp_gshare_ghr;
    logic [3:0] if_bp_gshare_index;
    logic if_pred_taken;
    logic [31:0] if_next_pc;

    logic        if_id_valid;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_pc_plus4;
    logic [31:0] if_id_instr;
    logic        if_id_pred_taken;
    logic [31:0] if_id_pred_target;

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] id_rd;
    logic [31:0] id_imm;
    logic [2:0] id_alu_op;
    logic id_alu_src_imm;
    logic id_reg_write;
    logic id_mem_write;
    logic [1:0] id_wb_sel;
    logic id_branch;
    logic id_branch_ne;
    logic id_jump;
    logic id_jump_reg;
    logic id_alu_src_pc;
    logic id_illegal_instr;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;

    logic        id_ex_valid;
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_pc_plus4;
    logic [31:0] id_ex_instr;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [4:0]  id_ex_rd;
    logic [2:0]  id_ex_alu_op;
    logic        id_ex_alu_src_imm;
    logic        id_ex_reg_write;
    logic        id_ex_mem_write;
    logic [1:0]  id_ex_wb_sel;
    logic        id_ex_branch;
    logic        id_ex_branch_ne;
    logic        id_ex_jump;
    logic        id_ex_jump_reg;
    logic        id_ex_alu_src_pc;
    logic        id_ex_illegal_instr;
    logic        id_ex_pred_taken;
    logic [31:0] id_ex_pred_target;

    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_y;
    logic ex_branch_equal;
    logic ex_branch_actual_taken;
    logic ex_branch_mispredict;
    logic ex_jump_redirect;
    logic ex_redirect;
    logic [31:0] ex_branch_target;
    logic [31:0] ex_jalr_target;
    logic [31:0] ex_redirect_target;
    logic bp_update_en;

    logic [31:0] bp_total_branches_r;
    logic [31:0] bp_pred_taken_count_r;
    logic [31:0] bp_pred_not_taken_count_r;
    logic [31:0] bp_actual_taken_count_r;
    logic [31:0] bp_actual_not_taken_count_r;
    logic [31:0] bp_correct_count_r;
    logic [31:0] bp_mispredict_count_r;
    logic [31:0] perf_cycle_count_r;
    logic [31:0] perf_retired_count_r;
    logic [31:0] perf_stall_count_r;
    logic [31:0] perf_load_use_stall_count_r;
    logic [31:0] perf_flush_count_r;
    logic [31:0] perf_branch_jump_flush_count_r;
    logic [31:0] perf_load_count_r;
    logic [31:0] perf_store_count_r;
    logic [31:0] perf_mem_stall_count_r;
    logic [31:0] perf_load_stall_count_r;
    logic [31:0] perf_store_stall_count_r;

    logic        ex_mem_valid;
    logic [31:0] ex_mem_pc;
    logic [31:0] ex_mem_instr;
    logic [31:0] ex_mem_alu_y;
    logic [31:0] ex_mem_rs2_data;
    logic [31:0] ex_mem_pc_plus4;
    logic [31:0] ex_mem_imm;
    logic [4:0]  ex_mem_rd;
    logic        ex_mem_reg_write;
    logic        ex_mem_mem_write;
    logic [1:0]  ex_mem_wb_sel;
    logic        ex_mem_illegal_instr;

    logic [31:0] mem_dmem_rdata;
    logic dcache_stall;
    logic dcache_access_event;
    logic dcache_load_event;
    logic dcache_store_event;
    logic dcache_hit_event;
    logic dcache_miss_event;
    logic dcache_fill_event;
    logic [31:0] dcache_trace_addr;
    logic [31:0] dcache_access_count;
    logic [31:0] dcache_load_access_count;
    logic [31:0] dcache_store_access_count;
    logic [31:0] dcache_hit_count;
    logic [31:0] dcache_miss_count;
    logic [31:0] dcache_miss_stall_count;
    logic l2_access_event;
    logic l2_hit_event;
    logic l2_miss_event;
    logic backing_access_event;
    logic [31:0] l2_access_count;
    logic [31:0] l2_hit_count;
    logic [31:0] l2_miss_count;
    logic l3_access_event;
    logic l3_hit_event;
    logic l3_miss_event;
    logic ucp_stream_id_event;
    logic [1:0] cache_hit_level_event;
    logic [31:0] l1_core0_access_count;
    logic [31:0] l1_core0_hit_count;
    logic [31:0] l1_core0_miss_count;
    logic [31:0] l1_core1_access_count;
    logic [31:0] l1_core1_hit_count;
    logic [31:0] l1_core1_miss_count;
    logic [31:0] l3_access_count;
    logic [31:0] l3_hit_count;
    logic [31:0] l3_miss_count;
    logic [31:0] l3_stream0_access_count;
    logic [31:0] l3_stream0_hit_count;
    logic [31:0] l3_stream0_miss_count;
    logic [31:0] l3_stream1_access_count;
    logic [31:0] l3_stream1_hit_count;
    logic [31:0] l3_stream1_miss_count;
    logic [31:0] l3_stream0_alloc_lines;
    logic [31:0] l3_stream1_alloc_lines;
    logic [31:0] l3_ucp_repartition_count;
    logic [31:0] l3_ucp_interval_count;
    logic [31:0] backing_access_count;
    logic mem_retired_load;
    logic mem_retired_store;
    logic id_uses_rs1;
    logic id_uses_rs2;
    logic raw_hazard_id_ex;
    logic raw_hazard_ex_mem;
    logic raw_hazard_mem_wb;
    logic raw_stall;
    logic raw_load_stall;
    logic ex_mem_is_load;
    logic ex_mem_is_store;
    logic ex_mem_memory_access;
    logic mem_stall;
    logic pipeline_stall;
    logic control_redirect;
    logic [31:0] mem_wait_count;

    logic        mem_wb_valid;
    logic [31:0] mem_wb_pc;
    logic [31:0] mem_wb_instr;
    logic [31:0] mem_wb_alu_y;
    logic [31:0] mem_wb_dmem_rdata;
    logic [31:0] mem_wb_pc_plus4;
    logic [31:0] mem_wb_imm;
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_reg_write;
    logic [1:0]  mem_wb_wb_sel;
    logic        mem_wb_illegal_instr;

    logic [31:0] wb_data;
    logic wb_we;

    assign pc_dbg = pc;
    assign instr_dbg = if_id_instr;
    assign illegal_instr_dbg = (if_id_valid && id_illegal_instr) ||
                               (id_ex_valid && id_ex_illegal_instr) ||
                               (ex_mem_valid && ex_mem_illegal_instr) ||
                               (mem_wb_valid && mem_wb_illegal_instr);

    assign if_pc_plus4 = pc + 32'd4;
    assign if_is_branch = (if_instr[6:0] == OPCODE_BRANCH);
    assign if_branch_imm = {{19{if_instr[31]}}, if_instr[31], if_instr[7], if_instr[30:25], if_instr[11:8], 1'b0};
    assign if_pred_target = pc + if_branch_imm;
    assign if_bp_taken_raw = (BP_MODE == BP_MODE_NONE) ? 1'b0 :
                             (BP_MODE == BP_MODE_SIMPLE) ? if_bp_simple_taken :
                             (BP_MODE == BP_MODE_GSHARE) ? if_bp_gshare_taken :
                             1'b0;
    assign if_pred_taken = if_is_branch && if_bp_taken_raw;
    assign if_next_pc = if_pred_taken ? if_pred_target : if_pc_plus4;
    assign wb_we = mem_wb_valid && mem_wb_reg_write && !mem_wb_illegal_instr;

    assign trace_if_valid = 1'b1;
    assign trace_if_pc = pc;
    assign trace_if_instr = if_instr;
    assign trace_id_valid = if_id_valid;
    assign trace_id_pc = if_id_pc;
    assign trace_id_instr = if_id_instr;
    assign trace_ex_valid = id_ex_valid;
    assign trace_ex_pc = id_ex_pc;
    assign trace_ex_instr = id_ex_instr;
    assign trace_mem_valid = ex_mem_valid;
    assign trace_mem_pc = ex_mem_pc;
    assign trace_mem_instr = ex_mem_instr;
    assign trace_wb_valid = mem_wb_valid;
    assign trace_wb_pc = mem_wb_pc;
    assign trace_wb_instr = mem_wb_instr;
    assign trace_wb_rd = mem_wb_rd;
    assign trace_wb_wdata = wb_data;
    assign trace_wb_we = wb_we;
    assign trace_stall = pipeline_stall;
    assign trace_flush = control_redirect;
    assign trace_redirect = control_redirect;
    assign trace_redirect_target = ex_redirect_target;
    assign trace_bp_pred_taken = id_ex_pred_taken;
    assign trace_bp_pred_target = id_ex_pred_target;
    assign trace_bp_actual_taken = ex_branch_actual_taken;
    assign trace_bp_actual_target = ex_branch_actual_taken ? ex_branch_target : id_ex_pc_plus4;
    assign trace_bp_mispredict = ex_branch_mispredict;
    assign trace_bp_mode = BP_MODE[1:0];
    assign trace_bp_ghr = if_bp_gshare_ghr;
    assign trace_bp_index = if_bp_gshare_index;
    assign bp_total_branches = bp_total_branches_r;
    assign bp_pred_taken_count = bp_pred_taken_count_r;
    assign bp_pred_not_taken_count = bp_pred_not_taken_count_r;
    assign bp_actual_taken_count = bp_actual_taken_count_r;
    assign bp_actual_not_taken_count = bp_actual_not_taken_count_r;
    assign bp_correct_count = bp_correct_count_r;
    assign bp_mispredict_count = bp_mispredict_count_r;
    assign perf_cycle_count = perf_cycle_count_r;
    assign perf_retired_count = perf_retired_count_r;
    assign perf_stall_count = perf_stall_count_r;
    assign perf_load_use_stall_count = perf_load_use_stall_count_r;
    assign perf_flush_count = perf_flush_count_r;
    assign perf_branch_jump_flush_count = perf_branch_jump_flush_count_r;
    assign perf_load_count = perf_load_count_r;
    assign perf_store_count = perf_store_count_r;
    assign perf_mem_stall_count = perf_mem_stall_count_r;
    assign perf_load_stall_count = perf_load_stall_count_r;
    assign perf_store_stall_count = perf_store_stall_count_r;
    assign trace_dcache_access = dcache_access_event;
    assign trace_dcache_load = dcache_load_event;
    assign trace_dcache_store = dcache_store_event;
    assign trace_dcache_hit = dcache_hit_event;
    assign trace_dcache_miss = dcache_miss_event;
    assign trace_dcache_stall = dcache_stall;
    assign trace_dcache_fill = dcache_fill_event;
    assign trace_dcache_addr = dcache_trace_addr;
    assign perf_dcache_access_count = dcache_access_count;
    assign perf_dcache_load_access_count = dcache_load_access_count;
    assign perf_dcache_store_access_count = dcache_store_access_count;
    assign perf_dcache_hit_count = dcache_hit_count;
    assign perf_dcache_miss_count = dcache_miss_count;
    assign perf_dcache_miss_stall_count = dcache_miss_stall_count;
    assign trace_l2_access = l2_access_event;
    assign trace_l2_hit = l2_hit_event;
    assign trace_l2_miss = l2_miss_event;
    assign trace_backing_access = backing_access_event;
    assign perf_l2_access_count = l2_access_count;
    assign perf_l2_hit_count = l2_hit_count;
    assign perf_l2_miss_count = l2_miss_count;
    assign perf_backing_access_count = backing_access_count;
    assign trace_l3_access = l3_access_event;
    assign trace_l3_hit = l3_hit_event;
    assign trace_l3_miss = l3_miss_event;
    assign trace_ucp_stream_id = ucp_stream_id_event;
    assign trace_cache_hit_level = cache_hit_level_event;
    assign perf_l1_core0_access_count = l1_core0_access_count;
    assign perf_l1_core0_hit_count = l1_core0_hit_count;
    assign perf_l1_core0_miss_count = l1_core0_miss_count;
    assign perf_l1_core1_access_count = l1_core1_access_count;
    assign perf_l1_core1_hit_count = l1_core1_hit_count;
    assign perf_l1_core1_miss_count = l1_core1_miss_count;
    assign perf_l3_access_count = l3_access_count;
    assign perf_l3_hit_count = l3_hit_count;
    assign perf_l3_miss_count = l3_miss_count;
    assign perf_l3_stream0_access_count = l3_stream0_access_count;
    assign perf_l3_stream0_hit_count = l3_stream0_hit_count;
    assign perf_l3_stream0_miss_count = l3_stream0_miss_count;
    assign perf_l3_stream1_access_count = l3_stream1_access_count;
    assign perf_l3_stream1_hit_count = l3_stream1_hit_count;
    assign perf_l3_stream1_miss_count = l3_stream1_miss_count;
    assign perf_l3_stream0_alloc_lines = l3_stream0_alloc_lines;
    assign perf_l3_stream1_alloc_lines = l3_stream1_alloc_lines;
    assign perf_l3_ucp_repartition_count = l3_ucp_repartition_count;
    assign perf_l3_ucp_interval_count = l3_ucp_interval_count;

    branch_predictor u_branch_predictor (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_pc(pc),
        .predict_taken(if_bp_simple_taken),
        .update_en(bp_update_en && (BP_MODE == BP_MODE_SIMPLE)),
        .update_pc(id_ex_pc),
        .actual_taken(ex_branch_actual_taken)
    );

    gshare_branch_predictor u_gshare_branch_predictor (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_pc(pc),
        .predict_taken(if_bp_gshare_taken),
        .fetch_ghr(if_bp_gshare_ghr),
        .fetch_index(if_bp_gshare_index),
        .update_en(bp_update_en && (BP_MODE == BP_MODE_GSHARE)),
        .update_pc(id_ex_pc),
        .actual_taken(ex_branch_actual_taken)
    );

    imem #(.HEX_FILE(IMEM_HEX)) u_imem (
        .addr(pc),
        .instr(if_instr)
    );

    decoder u_decoder (
        .instr(if_id_instr),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .imm(id_imm),
        .alu_op(id_alu_op),
        .alu_src_imm(id_alu_src_imm),
        .reg_write(id_reg_write),
        .mem_write(id_mem_write),
        .wb_sel(id_wb_sel),
        .branch(id_branch),
        .branch_ne(id_branch_ne),
        .jump(id_jump),
        .jump_reg(id_jump_reg),
        .alu_src_pc(id_alu_src_pc),
        .illegal_instr(id_illegal_instr)
    );

    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(wb_we),
        .raddr1(id_rs1),
        .raddr2(id_rs2),
        .waddr(mem_wb_rd),
        .wdata(wb_data),
        .rdata1(id_rs1_data),
        .rdata2(id_rs2_data)
    );

    assign ex_alu_a = id_ex_alu_src_pc ? id_ex_pc : id_ex_rs1_data;
    assign ex_alu_b = id_ex_alu_src_imm ? id_ex_imm : id_ex_rs2_data;
    assign ex_branch_equal = (id_ex_rs1_data == id_ex_rs2_data);
    assign ex_branch_actual_taken = id_ex_branch && (id_ex_branch_ne ? !ex_branch_equal : ex_branch_equal);
    assign ex_branch_target = id_ex_pc + id_ex_imm;
    assign ex_jalr_target = (id_ex_rs1_data + id_ex_imm) & 32'hfffffffe;
    assign ex_branch_mispredict = id_ex_valid && !id_ex_illegal_instr && id_ex_branch &&
                                  ((id_ex_pred_taken != ex_branch_actual_taken) ||
                                   (ex_branch_actual_taken && (id_ex_pred_target != ex_branch_target)));
    assign ex_jump_redirect = id_ex_valid && !id_ex_illegal_instr && id_ex_jump;
    assign ex_redirect = ex_jump_redirect || ex_branch_mispredict;
    assign control_redirect = ex_redirect && !mem_stall;
    assign ex_redirect_target = ex_jump_redirect ? (id_ex_jump_reg ? ex_jalr_target : ex_branch_target) :
                                (ex_branch_actual_taken ? ex_branch_target : id_ex_pc_plus4);
    assign bp_update_en = id_ex_valid && !id_ex_illegal_instr && id_ex_branch && !mem_stall;
    assign mem_retired_load = mem_wb_valid && !mem_wb_illegal_instr && (mem_wb_wb_sel == WB_MEM);
    assign mem_retired_store = ex_mem_valid && !ex_mem_illegal_instr && ex_mem_mem_write;
    assign id_uses_rs1 = if_id_valid && ((if_id_instr[6:0] == OPCODE_OP) ||
                                         (if_id_instr[6:0] == OPCODE_OP_IMM) ||
                                         (if_id_instr[6:0] == OPCODE_LOAD) ||
                                         (if_id_instr[6:0] == OPCODE_STORE) ||
                                         (if_id_instr[6:0] == OPCODE_BRANCH) ||
                                         (if_id_instr[6:0] == OPCODE_JALR));
    assign id_uses_rs2 = if_id_valid && ((if_id_instr[6:0] == OPCODE_OP) ||
                                         (if_id_instr[6:0] == OPCODE_STORE) ||
                                         (if_id_instr[6:0] == OPCODE_BRANCH));
    assign raw_hazard_id_ex = id_ex_valid && id_ex_reg_write && (id_ex_rd != 5'd0) &&
                              ((id_uses_rs1 && (id_ex_rd == id_rs1)) ||
                               (id_uses_rs2 && (id_ex_rd == id_rs2)));
    assign raw_hazard_ex_mem = ex_mem_valid && ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
                               ((id_uses_rs1 && (ex_mem_rd == id_rs1)) ||
                                (id_uses_rs2 && (ex_mem_rd == id_rs2)));
    assign raw_hazard_mem_wb = mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
                               ((id_uses_rs1 && (mem_wb_rd == id_rs1)) ||
                                (id_uses_rs2 && (mem_wb_rd == id_rs2)));
    assign raw_stall = !mem_stall && !ex_redirect && (raw_hazard_id_ex || raw_hazard_ex_mem || raw_hazard_mem_wb);
    assign raw_load_stall = raw_stall && (((raw_hazard_id_ex && (id_ex_wb_sel == WB_MEM))) ||
                                          ((raw_hazard_ex_mem && (ex_mem_wb_sel == WB_MEM))) ||
                                          ((raw_hazard_mem_wb && (mem_wb_wb_sel == WB_MEM))));
    assign ex_mem_is_load = ex_mem_valid && !ex_mem_illegal_instr && (ex_mem_wb_sel == WB_MEM);
    assign ex_mem_is_store = ex_mem_valid && !ex_mem_illegal_instr && ex_mem_mem_write;
    assign ex_mem_memory_access = ex_mem_is_load || ex_mem_is_store;
    assign mem_stall = dcache_stall;
    assign pipeline_stall = mem_stall || raw_stall;

    alu u_alu (
        .a(ex_alu_a),
        .b(ex_alu_b),
        .alu_op(id_ex_alu_op),
        .y(ex_alu_y)
    );

    direct_mapped_dcache #(
        .CACHE_ENABLE(DCACHE_ENABLE),
        .CACHE_LINES(DCACHE_LINES),
        .L2_ENABLE(L2_ENABLE),
        .L2_LINES(L2_LINES),
        .BASE_LATENCY_CYCLES(DMEM_LATENCY_CYCLES),
        .MISS_PENALTY_CYCLES(DCACHE_MISS_PENALTY_CYCLES),
        .L2_HIT_LATENCY(L2_HIT_LATENCY),
        .L2_MISS_PENALTY(L2_MISS_PENALTY),
        .PRIVATE_L1_ENABLE(PRIVATE_L1_ENABLE),
        .L1_NUM_CORES(L1_NUM_CORES),
        .L3_ENABLE(L3_ENABLE),
        .L3_LINES(L3_LINES),
        .L3_UCP_ENABLE(L3_UCP_ENABLE),
        .L3_UCP_POLICY(L3_UCP_POLICY),
        .UCP_REPARTITION_INTERVAL(UCP_REPARTITION_INTERVAL),
        .STREAM_SPLIT_ADDR(STREAM_SPLIT_ADDR),
        .STREAM_ID_MODE(0),
        .L3_HIT_LATENCY(L3_HIT_LATENCY),
        .L3_MISS_PENALTY(L3_MISS_PENALTY)
    ) u_dmem (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(ex_mem_memory_access),
        .req_load(ex_mem_is_load),
        .req_store(ex_mem_is_store),
        .req_thread_id(1'b0),
        .addr(ex_mem_alu_y),
        .wdata(ex_mem_rs2_data),
        .rdata(mem_dmem_rdata),
        .stall(dcache_stall),
        .trace_access(dcache_access_event),
        .trace_load(dcache_load_event),
        .trace_store(dcache_store_event),
        .trace_hit(dcache_hit_event),
        .trace_miss(dcache_miss_event),
        .trace_fill(dcache_fill_event),
        .trace_addr(dcache_trace_addr),
        .trace_l2_access(l2_access_event),
        .trace_l2_hit(l2_hit_event),
        .trace_l2_miss(l2_miss_event),
        .trace_l3_access(l3_access_event),
        .trace_l3_hit(l3_hit_event),
        .trace_l3_miss(l3_miss_event),
        .trace_backing_access(backing_access_event),
        .trace_stream_id(ucp_stream_id_event),
        .trace_hit_level(cache_hit_level_event),
        .access_count(dcache_access_count),
        .load_access_count(dcache_load_access_count),
        .store_access_count(dcache_store_access_count),
        .hit_count(dcache_hit_count),
        .miss_count(dcache_miss_count),
        .miss_stall_count(dcache_miss_stall_count),
        .l1_core0_access_count(l1_core0_access_count),
        .l1_core0_hit_count(l1_core0_hit_count),
        .l1_core0_miss_count(l1_core0_miss_count),
        .l1_core1_access_count(l1_core1_access_count),
        .l1_core1_hit_count(l1_core1_hit_count),
        .l1_core1_miss_count(l1_core1_miss_count),
        .l2_access_count(l2_access_count),
        .l2_hit_count(l2_hit_count),
        .l2_miss_count(l2_miss_count),
        .l3_access_count(l3_access_count),
        .l3_hit_count(l3_hit_count),
        .l3_miss_count(l3_miss_count),
        .l3_stream0_access_count(l3_stream0_access_count),
        .l3_stream0_hit_count(l3_stream0_hit_count),
        .l3_stream0_miss_count(l3_stream0_miss_count),
        .l3_stream1_access_count(l3_stream1_access_count),
        .l3_stream1_hit_count(l3_stream1_hit_count),
        .l3_stream1_miss_count(l3_stream1_miss_count),
        .l3_stream0_alloc_lines(l3_stream0_alloc_lines),
        .l3_stream1_alloc_lines(l3_stream1_alloc_lines),
        .l3_ucp_repartition_count(l3_ucp_repartition_count),
        .l3_ucp_interval_count(l3_ucp_interval_count),
        .backing_access_count(backing_access_count)
    );

    always_comb begin
        case (mem_wb_wb_sel)
            WB_ALU: wb_data = mem_wb_alu_y;
            WB_MEM: wb_data = mem_wb_dmem_rdata;
            WB_PC4: wb_data = mem_wb_pc_plus4;
            WB_IMM: wb_data = mem_wb_imm;
            default: wb_data = mem_wb_alu_y;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00000000;
            if_id_valid <= 1'b0;
            if_id_pc <= 32'h00000000;
            if_id_pc_plus4 <= 32'h00000000;
            if_id_instr <= 32'h00000013;
            if_id_pred_taken <= 1'b0;
            if_id_pred_target <= 32'h00000000;
            id_ex_valid <= 1'b0;
            id_ex_pc <= 32'h00000000;
            id_ex_pc_plus4 <= 32'h00000000;
            id_ex_instr <= 32'h00000013;
            id_ex_rs1_data <= 32'h00000000;
            id_ex_rs2_data <= 32'h00000000;
            id_ex_imm <= 32'h00000000;
            id_ex_rd <= 5'd0;
            id_ex_alu_op <= 3'd0;
            id_ex_alu_src_imm <= 1'b0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_wb_sel <= WB_ALU;
            id_ex_branch <= 1'b0;
            id_ex_branch_ne <= 1'b0;
            id_ex_jump <= 1'b0;
            id_ex_jump_reg <= 1'b0;
            id_ex_alu_src_pc <= 1'b0;
            id_ex_illegal_instr <= 1'b0;
            id_ex_pred_taken <= 1'b0;
            id_ex_pred_target <= 32'h00000000;
            ex_mem_valid <= 1'b0;
            ex_mem_pc <= 32'h00000000;
            ex_mem_instr <= 32'h00000013;
            ex_mem_alu_y <= 32'h00000000;
            ex_mem_rs2_data <= 32'h00000000;
            ex_mem_pc_plus4 <= 32'h00000000;
            ex_mem_imm <= 32'h00000000;
            ex_mem_rd <= 5'd0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_wb_sel <= WB_ALU;
            ex_mem_illegal_instr <= 1'b0;
            mem_wb_valid <= 1'b0;
            mem_wb_pc <= 32'h00000000;
            mem_wb_instr <= 32'h00000013;
            mem_wb_alu_y <= 32'h00000000;
            mem_wb_dmem_rdata <= 32'h00000000;
            mem_wb_pc_plus4 <= 32'h00000000;
            mem_wb_imm <= 32'h00000000;
            mem_wb_rd <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_wb_sel <= WB_ALU;
            mem_wb_illegal_instr <= 1'b0;
            bp_total_branches_r <= 32'h00000000;
            bp_pred_taken_count_r <= 32'h00000000;
            bp_pred_not_taken_count_r <= 32'h00000000;
            bp_actual_taken_count_r <= 32'h00000000;
            bp_actual_not_taken_count_r <= 32'h00000000;
            bp_correct_count_r <= 32'h00000000;
            bp_mispredict_count_r <= 32'h00000000;
            perf_cycle_count_r <= 32'h00000000;
            perf_retired_count_r <= 32'h00000000;
            perf_stall_count_r <= 32'h00000000;
            perf_load_use_stall_count_r <= 32'h00000000;
            perf_flush_count_r <= 32'h00000000;
            perf_branch_jump_flush_count_r <= 32'h00000000;
            perf_load_count_r <= 32'h00000000;
            perf_store_count_r <= 32'h00000000;
            perf_mem_stall_count_r <= 32'h00000000;
            perf_load_stall_count_r <= 32'h00000000;
            perf_store_stall_count_r <= 32'h00000000;
            mem_wait_count <= 32'h00000000;
        end else begin
            perf_cycle_count_r <= perf_cycle_count_r + 32'd1;
            if (mem_wb_valid && !mem_wb_illegal_instr) perf_retired_count_r <= perf_retired_count_r + 32'd1;
            if (pipeline_stall) perf_stall_count_r <= perf_stall_count_r + 32'd1;
            if (raw_load_stall) perf_load_use_stall_count_r <= perf_load_use_stall_count_r + 32'd1;
            if (mem_stall) begin
                perf_mem_stall_count_r <= perf_mem_stall_count_r + 32'd1;
                if (ex_mem_is_load) perf_load_stall_count_r <= perf_load_stall_count_r + 32'd1;
                if (ex_mem_is_store) perf_store_stall_count_r <= perf_store_stall_count_r + 32'd1;
            end
            if (control_redirect) begin
                perf_flush_count_r <= perf_flush_count_r + 32'd1;
                perf_branch_jump_flush_count_r <= perf_branch_jump_flush_count_r + 32'd1;
            end
            if (mem_retired_load) perf_load_count_r <= perf_load_count_r + 32'd1;
            if (mem_retired_store) perf_store_count_r <= perf_store_count_r + 32'd1;

            if (mem_stall) begin
                mem_wait_count <= mem_wait_count + 32'd1;
                pc <= pc;
                if_id_valid <= if_id_valid;
                if_id_pc <= if_id_pc;
                if_id_pc_plus4 <= if_id_pc_plus4;
                if_id_instr <= if_id_instr;
                if_id_pred_taken <= if_id_pred_taken;
                if_id_pred_target <= if_id_pred_target;
                id_ex_valid <= id_ex_valid;
                id_ex_pc <= id_ex_pc;
                id_ex_pc_plus4 <= id_ex_pc_plus4;
                id_ex_instr <= id_ex_instr;
                id_ex_rs1_data <= id_ex_rs1_data;
                id_ex_rs2_data <= id_ex_rs2_data;
                id_ex_imm <= id_ex_imm;
                id_ex_rd <= id_ex_rd;
                id_ex_alu_op <= id_ex_alu_op;
                id_ex_alu_src_imm <= id_ex_alu_src_imm;
                id_ex_reg_write <= id_ex_reg_write;
                id_ex_mem_write <= id_ex_mem_write;
                id_ex_wb_sel <= id_ex_wb_sel;
                id_ex_branch <= id_ex_branch;
                id_ex_branch_ne <= id_ex_branch_ne;
                id_ex_jump <= id_ex_jump;
                id_ex_jump_reg <= id_ex_jump_reg;
                id_ex_alu_src_pc <= id_ex_alu_src_pc;
                id_ex_illegal_instr <= id_ex_illegal_instr;
                id_ex_pred_taken <= id_ex_pred_taken;
                id_ex_pred_target <= id_ex_pred_target;
                ex_mem_valid <= ex_mem_valid;
                ex_mem_pc <= ex_mem_pc;
                ex_mem_instr <= ex_mem_instr;
                ex_mem_alu_y <= ex_mem_alu_y;
                ex_mem_rs2_data <= ex_mem_rs2_data;
                ex_mem_pc_plus4 <= ex_mem_pc_plus4;
                ex_mem_imm <= ex_mem_imm;
                ex_mem_rd <= ex_mem_rd;
                ex_mem_reg_write <= ex_mem_reg_write;
                ex_mem_mem_write <= ex_mem_mem_write;
                ex_mem_wb_sel <= ex_mem_wb_sel;
                ex_mem_illegal_instr <= ex_mem_illegal_instr;
                mem_wb_valid <= 1'b0;
                mem_wb_pc <= 32'h00000000;
                mem_wb_instr <= 32'h00000013;
                mem_wb_alu_y <= 32'h00000000;
                mem_wb_dmem_rdata <= 32'h00000000;
                mem_wb_pc_plus4 <= 32'h00000000;
                mem_wb_imm <= 32'h00000000;
                mem_wb_rd <= 5'd0;
                mem_wb_reg_write <= 1'b0;
                mem_wb_wb_sel <= WB_ALU;
                mem_wb_illegal_instr <= 1'b0;
            end else begin
                mem_wait_count <= 32'h00000000;
                pc <= control_redirect ? ex_redirect_target : (raw_stall ? pc : if_next_pc);

                if_id_valid <= control_redirect ? 1'b0 : (raw_stall ? if_id_valid : 1'b1);
                if_id_pc <= raw_stall ? if_id_pc : pc;
                if_id_pc_plus4 <= raw_stall ? if_id_pc_plus4 : if_pc_plus4;
                if_id_instr <= control_redirect ? 32'h00000013 : (raw_stall ? if_id_instr : if_instr);
                if_id_pred_taken <= control_redirect ? 1'b0 : (raw_stall ? if_id_pred_taken : if_pred_taken);
                if_id_pred_target <= control_redirect ? 32'h00000000 : (raw_stall ? if_id_pred_target : if_pred_target);

                id_ex_valid <= (control_redirect || raw_stall) ? 1'b0 : if_id_valid;
                id_ex_pc <= raw_stall ? 32'h00000000 : if_id_pc;
                id_ex_pc_plus4 <= raw_stall ? 32'h00000000 : if_id_pc_plus4;
                id_ex_instr <= raw_stall ? 32'h00000013 : if_id_instr;
                id_ex_rs1_data <= raw_stall ? 32'h00000000 : id_rs1_data;
                id_ex_rs2_data <= raw_stall ? 32'h00000000 : id_rs2_data;
                id_ex_imm <= raw_stall ? 32'h00000000 : id_imm;
                id_ex_rd <= raw_stall ? 5'd0 : id_rd;
                id_ex_alu_op <= raw_stall ? 3'd0 : id_alu_op;
                id_ex_alu_src_imm <= raw_stall ? 1'b0 : id_alu_src_imm;
                id_ex_reg_write <= raw_stall ? 1'b0 : id_reg_write;
                id_ex_mem_write <= raw_stall ? 1'b0 : id_mem_write;
                id_ex_wb_sel <= raw_stall ? WB_ALU : id_wb_sel;
                id_ex_branch <= raw_stall ? 1'b0 : id_branch;
                id_ex_branch_ne <= raw_stall ? 1'b0 : id_branch_ne;
                id_ex_jump <= raw_stall ? 1'b0 : id_jump;
                id_ex_jump_reg <= raw_stall ? 1'b0 : id_jump_reg;
                id_ex_alu_src_pc <= raw_stall ? 1'b0 : id_alu_src_pc;
                id_ex_illegal_instr <= raw_stall ? 1'b0 : id_illegal_instr;
                id_ex_pred_taken <= (control_redirect || raw_stall) ? 1'b0 : if_id_pred_taken;
                id_ex_pred_target <= (control_redirect || raw_stall) ? 32'h00000000 : if_id_pred_target;

                ex_mem_valid <= id_ex_valid;
                ex_mem_pc <= id_ex_pc;
                ex_mem_instr <= id_ex_instr;
                ex_mem_alu_y <= ex_alu_y;
                ex_mem_rs2_data <= id_ex_rs2_data;
                ex_mem_pc_plus4 <= id_ex_pc_plus4;
                ex_mem_imm <= id_ex_imm;
                ex_mem_rd <= id_ex_rd;
                ex_mem_reg_write <= id_ex_reg_write;
                ex_mem_mem_write <= id_ex_mem_write;
                ex_mem_wb_sel <= id_ex_wb_sel;
                ex_mem_illegal_instr <= id_ex_illegal_instr;

                mem_wb_valid <= ex_mem_valid;
                mem_wb_pc <= ex_mem_pc;
                mem_wb_instr <= ex_mem_instr;
                mem_wb_alu_y <= ex_mem_alu_y;
                mem_wb_dmem_rdata <= mem_dmem_rdata;
                mem_wb_pc_plus4 <= ex_mem_pc_plus4;
                mem_wb_imm <= ex_mem_imm;
                mem_wb_rd <= ex_mem_rd;
                mem_wb_reg_write <= ex_mem_reg_write;
                mem_wb_wb_sel <= ex_mem_wb_sel;
                mem_wb_illegal_instr <= ex_mem_illegal_instr;
            end

            if (bp_update_en) begin
                bp_total_branches_r <= bp_total_branches_r + 32'd1;
                if (id_ex_pred_taken) bp_pred_taken_count_r <= bp_pred_taken_count_r + 32'd1;
                else bp_pred_not_taken_count_r <= bp_pred_not_taken_count_r + 32'd1;
                if (ex_branch_actual_taken) bp_actual_taken_count_r <= bp_actual_taken_count_r + 32'd1;
                else bp_actual_not_taken_count_r <= bp_actual_not_taken_count_r + 32'd1;
                if (ex_branch_mispredict) bp_mispredict_count_r <= bp_mispredict_count_r + 32'd1;
                else bp_correct_count_r <= bp_correct_count_r + 32'd1;
            end
        end
    end
endmodule













