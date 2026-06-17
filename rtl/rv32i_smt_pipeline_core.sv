`timescale 1ns/1ps

module rv32i_smt_pipeline_core #(
    parameter THREAD0_IMEM_HEX = "tests/benchmarks/smt/context_basic_t0.hex",
    parameter THREAD1_IMEM_HEX = "tests/benchmarks/smt/context_basic_t1.hex",
    parameter DMEM_LATENCY_CYCLES = 1,
    parameter DCACHE_ENABLE = 1,
    parameter DCACHE_LINES = 4,
    parameter DCACHE_MISS_PENALTY_CYCLES = 3,
    parameter L2_ENABLE = 1,
    parameter L2_LINES = 8,
    parameter L2_HIT_LATENCY = 2,
    parameter L2_MISS_PENALTY = 6,
    parameter PRIVATE_L1_ENABLE = 1,
    parameter L1_NUM_CORES = 2,
    parameter L3_ENABLE = 1,
    parameter L3_LINES = 8,
    parameter L3_UCP_ENABLE = 1,
    parameter L3_UCP_POLICY = 2,
    parameter UCP_REPARTITION_INTERVAL = 8,
    parameter STREAM_SPLIT_ADDR = 32'h00001000,
    parameter STREAM_ID_MODE = 1,
    parameter L3_HIT_LATENCY = 4,
    parameter L3_MISS_PENALTY = 12
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc0_dbg,
    output logic [31:0] pc1_dbg,
    output logic        fetch_tid_dbg,
    output logic        illegal_instr_dbg,
    output logic        trace_if_valid,
    output logic        trace_if_tid,
    output logic [31:0] trace_if_pc,
    output logic [31:0] trace_if_instr,
    output logic        trace_id_valid,
    output logic        trace_id_tid,
    output logic [31:0] trace_id_pc,
    output logic [31:0] trace_id_instr,
    output logic        trace_ex_valid,
    output logic        trace_ex_tid,
    output logic [31:0] trace_ex_pc,
    output logic [31:0] trace_ex_instr,
    output logic        trace_mem_valid,
    output logic        trace_mem_tid,
    output logic [31:0] trace_mem_pc,
    output logic [31:0] trace_mem_instr,
    output logic        trace_wb_valid,
    output logic        trace_wb_tid,
    output logic [31:0] trace_wb_pc,
    output logic [31:0] trace_wb_instr,
    output logic [4:0]  trace_wb_rd,
    output logic [31:0] trace_wb_wdata,
    output logic        trace_wb_we,
    output logic        trace_stall,
    output logic        trace_flush,
    output logic        trace_redirect,
    output logic        trace_redirect_tid,
    output logic [31:0] trace_redirect_target,
    output logic        trace_raw_stall,
    output logic        trace_mem_stall,
    output logic [31:0] perf_cycle_count,
    output logic [31:0] perf_retired_count,
    output logic [31:0] perf_thread0_fetched_count,
    output logic [31:0] perf_thread1_fetched_count,
    output logic [31:0] perf_thread0_retired_count,
    output logic [31:0] perf_thread1_retired_count,
    output logic [31:0] perf_thread0_stall_count,
    output logic [31:0] perf_thread1_stall_count,
    output logic [31:0] perf_thread0_flush_count,
    output logic [31:0] perf_thread1_flush_count,
    output logic [31:0] perf_thread0_load_count,
    output logic [31:0] perf_thread1_load_count,
    output logic [31:0] perf_thread0_store_count,
    output logic [31:0] perf_thread1_store_count,
    output logic        trace_dcache_access,
    output logic        trace_dcache_load,
    output logic        trace_dcache_store,
    output logic        trace_dcache_hit,
    output logic        trace_dcache_miss,
    output logic        trace_dcache_stall,
    output logic        trace_dcache_fill,
    output logic [31:0] trace_dcache_addr,
    output logic        trace_l2_access,
    output logic        trace_l2_hit,
    output logic        trace_l2_miss,
    output logic        trace_l3_access,
    output logic        trace_l3_hit,
    output logic        trace_l3_miss,
    output logic        trace_backing_access,
    output logic        trace_ucp_stream_id,
    output logic [1:0]  trace_cache_hit_level,
    output logic [31:0] perf_l1_core0_access_count,
    output logic [31:0] perf_l1_core0_hit_count,
    output logic [31:0] perf_l1_core0_miss_count,
    output logic [31:0] perf_l1_core1_access_count,
    output logic [31:0] perf_l1_core1_hit_count,
    output logic [31:0] perf_l1_core1_miss_count,
    output logic [31:0] perf_l2_access_count,
    output logic [31:0] perf_l2_hit_count,
    output logic [31:0] perf_l2_miss_count,
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
    output logic [31:0] perf_l3_ucp_interval_count,
    output logic [31:0] perf_backing_access_count
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
    localparam NOP = 32'h00000013;

    logic [31:0] pc [0:1];
    logic fetch_tid;
    logic [31:0] if_instr0;
    logic [31:0] if_instr1;
    logic [31:0] if_instr;
    logic [31:0] if_pc;
    logic [31:0] if_pc_plus4;

    logic if_id_valid;
    logic if_id_tid;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_pc_plus4;
    logic [31:0] if_id_instr;

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
    logic [31:0] id_rs1_data_raw;
    logic [31:0] id_rs2_data_raw;

    logic id_ex_valid;
    logic id_ex_tid;
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_pc_plus4;
    logic [31:0] id_ex_instr;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [4:0] id_ex_rd;
    logic [2:0] id_ex_alu_op;
    logic id_ex_alu_src_imm;
    logic id_ex_reg_write;
    logic id_ex_mem_write;
    logic [1:0] id_ex_wb_sel;
    logic id_ex_branch;
    logic id_ex_branch_ne;
    logic id_ex_jump;
    logic id_ex_jump_reg;
    logic id_ex_alu_src_pc;
    logic id_ex_illegal_instr;

    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_y;
    logic ex_branch_equal;
    logic ex_branch_taken;
    logic ex_redirect;
    logic [31:0] ex_branch_target;
    logic [31:0] ex_jalr_target;
    logic [31:0] ex_redirect_target;

    logic ex_mem_valid;
    logic ex_mem_tid;
    logic [31:0] ex_mem_pc;
    logic [31:0] ex_mem_instr;
    logic [31:0] ex_mem_alu_y;
    logic [31:0] ex_mem_rs2_data;
    logic [31:0] ex_mem_pc_plus4;
    logic [31:0] ex_mem_imm;
    logic [4:0] ex_mem_rd;
    logic ex_mem_reg_write;
    logic ex_mem_mem_write;
    logic [1:0] ex_mem_wb_sel;
    logic ex_mem_illegal_instr;

    logic mem_wb_valid;
    logic mem_wb_tid;
    logic [31:0] mem_wb_pc;
    logic [31:0] mem_wb_instr;
    logic [31:0] mem_wb_alu_y;
    logic [31:0] mem_wb_dmem_rdata;
    logic [31:0] mem_wb_pc_plus4;
    logic [31:0] mem_wb_imm;
    logic [4:0] mem_wb_rd;
    logic mem_wb_reg_write;
    logic [1:0] mem_wb_wb_sel;
    logic mem_wb_illegal_instr;

    logic [31:0] wb_data;
    logic wb_we;
    logic id_uses_rs1;
    logic id_uses_rs2;
    logic raw_hazard_id_ex;
    logic raw_hazard_ex_mem;
    logic raw_hazard_mem_wb;
    logic raw_stall;
    logic mem_stall;
    logic pipeline_stall;
    logic ex_mem_is_load;
    logic ex_mem_is_store;
    logic ex_mem_memory_access;
    logic [31:0] mem_dmem_rdata;

    logic [31:0] perf_cycle_count_r;
    logic [31:0] perf_thread0_fetched_count_r;
    logic [31:0] perf_thread1_fetched_count_r;
    logic [31:0] perf_thread0_retired_count_r;
    logic [31:0] perf_thread1_retired_count_r;
    logic [31:0] perf_thread0_stall_count_r;
    logic [31:0] perf_thread1_stall_count_r;
    logic [31:0] perf_thread0_flush_count_r;
    logic [31:0] perf_thread1_flush_count_r;
    logic [31:0] perf_thread0_load_count_r;
    logic [31:0] perf_thread1_load_count_r;
    logic [31:0] perf_thread0_store_count_r;
    logic [31:0] perf_thread1_store_count_r;

    logic dcache_access_event;
    logic dcache_load_event;
    logic dcache_store_event;
    logic dcache_hit_event;
    logic dcache_miss_event;
    logic dcache_fill_event;
    logic [31:0] dcache_access_count_unused;
    logic [31:0] dcache_load_count_unused;
    logic [31:0] dcache_store_count_unused;
    logic [31:0] dcache_hit_count_unused;
    logic [31:0] dcache_miss_count_unused;
    logic [31:0] dcache_miss_stall_count_unused;

    assign pc0_dbg = pc[0];
    assign pc1_dbg = pc[1];
    assign fetch_tid_dbg = fetch_tid;
    assign illegal_instr_dbg = (id_ex_valid && id_ex_illegal_instr) || (ex_mem_valid && ex_mem_illegal_instr) || (mem_wb_valid && mem_wb_illegal_instr);
    assign if_pc = pc[fetch_tid];
    assign if_pc_plus4 = if_pc + 32'd4;
    assign if_instr = fetch_tid ? if_instr1 : if_instr0;
    assign trace_if_valid = !pipeline_stall;
    assign trace_if_tid = fetch_tid;
    assign trace_if_pc = if_pc;
    assign trace_if_instr = if_instr;
    assign trace_id_valid = if_id_valid;
    assign trace_id_tid = if_id_tid;
    assign trace_id_pc = if_id_pc;
    assign trace_id_instr = if_id_instr;
    assign trace_ex_valid = id_ex_valid;
    assign trace_ex_tid = id_ex_tid;
    assign trace_ex_pc = id_ex_pc;
    assign trace_ex_instr = id_ex_instr;
    assign trace_mem_valid = ex_mem_valid;
    assign trace_mem_tid = ex_mem_tid;
    assign trace_mem_pc = ex_mem_pc;
    assign trace_mem_instr = ex_mem_instr;
    assign trace_wb_valid = mem_wb_valid;
    assign trace_wb_tid = mem_wb_tid;
    assign trace_wb_pc = mem_wb_pc;
    assign trace_wb_instr = mem_wb_instr;
    assign trace_wb_rd = mem_wb_rd;
    assign trace_wb_wdata = wb_data;
    assign trace_wb_we = wb_we;
    assign trace_stall = pipeline_stall;
    assign trace_flush = ex_redirect && !mem_stall;
    assign trace_redirect = ex_redirect && !mem_stall;
    assign trace_redirect_tid = id_ex_tid;
    assign trace_redirect_target = ex_redirect_target;
    assign trace_raw_stall = raw_stall;
    assign trace_mem_stall = mem_stall;
    assign perf_cycle_count = perf_cycle_count_r;
    assign perf_retired_count = perf_thread0_retired_count_r + perf_thread1_retired_count_r;
    assign perf_thread0_fetched_count = perf_thread0_fetched_count_r;
    assign perf_thread1_fetched_count = perf_thread1_fetched_count_r;
    assign perf_thread0_retired_count = perf_thread0_retired_count_r;
    assign perf_thread1_retired_count = perf_thread1_retired_count_r;
    assign perf_thread0_stall_count = perf_thread0_stall_count_r;
    assign perf_thread1_stall_count = perf_thread1_stall_count_r;
    assign perf_thread0_flush_count = perf_thread0_flush_count_r;
    assign perf_thread1_flush_count = perf_thread1_flush_count_r;
    assign perf_thread0_load_count = perf_thread0_load_count_r;
    assign perf_thread1_load_count = perf_thread1_load_count_r;
    assign perf_thread0_store_count = perf_thread0_store_count_r;
    assign perf_thread1_store_count = perf_thread1_store_count_r;
    assign trace_dcache_access = dcache_access_event;
    assign trace_dcache_load = dcache_load_event;
    assign trace_dcache_store = dcache_store_event;
    assign trace_dcache_hit = dcache_hit_event;
    assign trace_dcache_miss = dcache_miss_event;
    assign trace_dcache_stall = mem_stall;
    assign trace_dcache_fill = dcache_fill_event;

    imem #(.HEX_FILE(THREAD0_IMEM_HEX)) u_imem0 (.addr(pc[0]), .instr(if_instr0));
    imem #(.HEX_FILE(THREAD1_IMEM_HEX)) u_imem1 (.addr(pc[1]), .instr(if_instr1));

    decoder u_decoder (
        .instr(if_id_instr), .rs1(id_rs1), .rs2(id_rs2), .rd(id_rd), .imm(id_imm),
        .alu_op(id_alu_op), .alu_src_imm(id_alu_src_imm), .reg_write(id_reg_write),
        .mem_write(id_mem_write), .wb_sel(id_wb_sel), .branch(id_branch),
        .branch_ne(id_branch_ne), .jump(id_jump), .jump_reg(id_jump_reg),
        .alu_src_pc(id_alu_src_pc), .illegal_instr(id_illegal_instr)
    );

    threaded_regfile u_regfile (
        .clk(clk), .rst_n(rst_n), .we(wb_we), .rtid(if_id_tid), .wtid(mem_wb_tid),
        .raddr1(id_rs1), .raddr2(id_rs2), .waddr(mem_wb_rd), .wdata(wb_data),
        .rdata1(id_rs1_data_raw), .rdata2(id_rs2_data_raw)
    );

    assign id_rs1_data = (wb_we && (mem_wb_tid == if_id_tid) && (mem_wb_rd == id_rs1) && (id_rs1 != 5'd0)) ? wb_data : id_rs1_data_raw;
    assign id_rs2_data = (wb_we && (mem_wb_tid == if_id_tid) && (mem_wb_rd == id_rs2) && (id_rs2 != 5'd0)) ? wb_data : id_rs2_data_raw;

    assign ex_alu_a = id_ex_alu_src_pc ? id_ex_pc : id_ex_rs1_data;
    assign ex_alu_b = id_ex_alu_src_imm ? id_ex_imm : id_ex_rs2_data;
    assign ex_branch_equal = (id_ex_rs1_data == id_ex_rs2_data);
    assign ex_branch_taken = id_ex_branch && (id_ex_branch_ne ? !ex_branch_equal : ex_branch_equal);
    assign ex_branch_target = id_ex_pc + id_ex_imm;
    assign ex_jalr_target = (id_ex_rs1_data + id_ex_imm) & 32'hfffffffe;
    assign ex_redirect = id_ex_valid && !id_ex_illegal_instr && ((id_ex_branch && ex_branch_taken) || id_ex_jump);
    assign ex_redirect_target = id_ex_jump ? (id_ex_jump_reg ? ex_jalr_target : ex_branch_target) : ex_branch_target;
    assign ex_mem_is_load = ex_mem_valid && !ex_mem_illegal_instr && (ex_mem_wb_sel == WB_MEM);
    assign ex_mem_is_store = ex_mem_valid && !ex_mem_illegal_instr && ex_mem_mem_write;
    assign ex_mem_memory_access = ex_mem_is_load || ex_mem_is_store;
    assign pipeline_stall = mem_stall || raw_stall;
    assign wb_we = mem_wb_valid && !mem_wb_illegal_instr && mem_wb_reg_write && (mem_wb_rd != 5'd0);

    assign id_uses_rs1 = if_id_valid && ((if_id_instr[6:0] == OPCODE_OP) ||
                                         (if_id_instr[6:0] == OPCODE_OP_IMM) ||
                                         (if_id_instr[6:0] == OPCODE_LOAD) ||
                                         (if_id_instr[6:0] == OPCODE_STORE) ||
                                         (if_id_instr[6:0] == OPCODE_BRANCH) ||
                                         (if_id_instr[6:0] == OPCODE_JALR));
    assign id_uses_rs2 = if_id_valid && ((if_id_instr[6:0] == OPCODE_OP) ||
                                         (if_id_instr[6:0] == OPCODE_STORE) ||
                                         (if_id_instr[6:0] == OPCODE_BRANCH));
    assign raw_hazard_id_ex = id_ex_valid && id_ex_reg_write && (id_ex_rd != 5'd0) && (id_ex_tid == if_id_tid) &&
                              ((id_uses_rs1 && (id_ex_rd == id_rs1)) || (id_uses_rs2 && (id_ex_rd == id_rs2)));
    assign raw_hazard_ex_mem = ex_mem_valid && ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_tid == if_id_tid) &&
                               ((id_uses_rs1 && (ex_mem_rd == id_rs1)) || (id_uses_rs2 && (ex_mem_rd == id_rs2)));
    assign raw_hazard_mem_wb = mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_tid == if_id_tid) &&
                               ((id_uses_rs1 && (mem_wb_rd == id_rs1)) || (id_uses_rs2 && (mem_wb_rd == id_rs2)));
    assign raw_stall = !mem_stall && !ex_redirect && (raw_hazard_id_ex || raw_hazard_ex_mem || raw_hazard_mem_wb);

    alu u_alu (.a(ex_alu_a), .b(ex_alu_b), .alu_op(id_ex_alu_op), .y(ex_alu_y));

    direct_mapped_dcache #(
        .CACHE_ENABLE(DCACHE_ENABLE), .CACHE_LINES(DCACHE_LINES),
        .PRIVATE_L1_ENABLE(PRIVATE_L1_ENABLE), .L1_NUM_CORES(L1_NUM_CORES),
        .L2_ENABLE(L2_ENABLE), .L2_LINES(L2_LINES), .L3_ENABLE(L3_ENABLE),
        .L3_LINES(L3_LINES), .L3_UCP_ENABLE(L3_UCP_ENABLE), .L3_UCP_POLICY(L3_UCP_POLICY),
        .UCP_REPARTITION_INTERVAL(UCP_REPARTITION_INTERVAL),
        .STREAM_SPLIT_ADDR(STREAM_SPLIT_ADDR), .STREAM_ID_MODE(STREAM_ID_MODE),
        .BASE_LATENCY_CYCLES(DMEM_LATENCY_CYCLES),
        .MISS_PENALTY_CYCLES(DCACHE_MISS_PENALTY_CYCLES),
        .L2_HIT_LATENCY(L2_HIT_LATENCY), .L2_MISS_PENALTY(L2_MISS_PENALTY),
        .L3_HIT_LATENCY(L3_HIT_LATENCY), .L3_MISS_PENALTY(L3_MISS_PENALTY)
    ) u_dmem (
        .clk(clk), .rst_n(rst_n), .req_valid(ex_mem_memory_access),
        .req_load(ex_mem_is_load), .req_store(ex_mem_is_store),
        .req_thread_id(ex_mem_valid ? ex_mem_tid : 1'b0),
        .addr(ex_mem_memory_access ? ex_mem_alu_y : 32'h00000000),
        .wdata(ex_mem_memory_access ? ex_mem_rs2_data : 32'h00000000),
        .rdata(mem_dmem_rdata), .stall(mem_stall),
        .trace_access(dcache_access_event), .trace_load(dcache_load_event),
        .trace_store(dcache_store_event), .trace_hit(dcache_hit_event),
        .trace_miss(dcache_miss_event), .trace_fill(dcache_fill_event),
        .trace_addr(trace_dcache_addr), .trace_l2_access(trace_l2_access),
        .trace_l2_hit(trace_l2_hit), .trace_l2_miss(trace_l2_miss),
        .trace_l3_access(trace_l3_access), .trace_l3_hit(trace_l3_hit),
        .trace_l3_miss(trace_l3_miss), .trace_backing_access(trace_backing_access),
        .trace_stream_id(trace_ucp_stream_id), .trace_hit_level(trace_cache_hit_level),
        .access_count(dcache_access_count_unused), .load_access_count(dcache_load_count_unused),
        .store_access_count(dcache_store_count_unused), .hit_count(dcache_hit_count_unused),
        .miss_count(dcache_miss_count_unused), .miss_stall_count(dcache_miss_stall_count_unused),
        .l1_core0_access_count(perf_l1_core0_access_count),
        .l1_core0_hit_count(perf_l1_core0_hit_count),
        .l1_core0_miss_count(perf_l1_core0_miss_count),
        .l1_core1_access_count(perf_l1_core1_access_count),
        .l1_core1_hit_count(perf_l1_core1_hit_count),
        .l1_core1_miss_count(perf_l1_core1_miss_count),
        .l2_access_count(perf_l2_access_count), .l2_hit_count(perf_l2_hit_count),
        .l2_miss_count(perf_l2_miss_count), .l3_access_count(perf_l3_access_count),
        .l3_hit_count(perf_l3_hit_count), .l3_miss_count(perf_l3_miss_count),
        .l3_stream0_access_count(perf_l3_stream0_access_count),
        .l3_stream0_hit_count(perf_l3_stream0_hit_count),
        .l3_stream0_miss_count(perf_l3_stream0_miss_count),
        .l3_stream1_access_count(perf_l3_stream1_access_count),
        .l3_stream1_hit_count(perf_l3_stream1_hit_count),
        .l3_stream1_miss_count(perf_l3_stream1_miss_count),
        .l3_stream0_alloc_lines(perf_l3_stream0_alloc_lines),
        .l3_stream1_alloc_lines(perf_l3_stream1_alloc_lines),
        .l3_ucp_repartition_count(perf_l3_ucp_repartition_count),
        .l3_ucp_interval_count(perf_l3_ucp_interval_count),
        .backing_access_count(perf_backing_access_count)
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
            pc[0] <= 32'h00000000;
            pc[1] <= 32'h00000000;
            fetch_tid <= 1'b0;
            if_id_valid <= 1'b0;
            if_id_tid <= 1'b0;
            if_id_pc <= 32'h00000000;
            if_id_pc_plus4 <= 32'h00000000;
            if_id_instr <= NOP;
            id_ex_valid <= 1'b0;
            id_ex_tid <= 1'b0;
            id_ex_pc <= 32'h00000000;
            id_ex_pc_plus4 <= 32'h00000000;
            id_ex_instr <= NOP;
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
            ex_mem_valid <= 1'b0;
            ex_mem_tid <= 1'b0;
            ex_mem_pc <= 32'h00000000;
            ex_mem_instr <= NOP;
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
            mem_wb_tid <= 1'b0;
            mem_wb_pc <= 32'h00000000;
            mem_wb_instr <= NOP;
            mem_wb_alu_y <= 32'h00000000;
            mem_wb_dmem_rdata <= 32'h00000000;
            mem_wb_pc_plus4 <= 32'h00000000;
            mem_wb_imm <= 32'h00000000;
            mem_wb_rd <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_wb_sel <= WB_ALU;
            mem_wb_illegal_instr <= 1'b0;
            perf_cycle_count_r <= 32'd0;
            perf_thread0_fetched_count_r <= 32'd0;
            perf_thread1_fetched_count_r <= 32'd0;
            perf_thread0_retired_count_r <= 32'd0;
            perf_thread1_retired_count_r <= 32'd0;
            perf_thread0_stall_count_r <= 32'd0;
            perf_thread1_stall_count_r <= 32'd0;
            perf_thread0_flush_count_r <= 32'd0;
            perf_thread1_flush_count_r <= 32'd0;
            perf_thread0_load_count_r <= 32'd0;
            perf_thread1_load_count_r <= 32'd0;
            perf_thread0_store_count_r <= 32'd0;
            perf_thread1_store_count_r <= 32'd0;
        end else begin
            perf_cycle_count_r <= perf_cycle_count_r + 32'd1;
            if (pipeline_stall) begin
                if (if_id_tid) perf_thread1_stall_count_r <= perf_thread1_stall_count_r + 32'd1;
                else perf_thread0_stall_count_r <= perf_thread0_stall_count_r + 32'd1;
            end
            if (trace_redirect) begin
                if (id_ex_tid) perf_thread1_flush_count_r <= perf_thread1_flush_count_r + 32'd1;
                else perf_thread0_flush_count_r <= perf_thread0_flush_count_r + 32'd1;
            end
            if (mem_wb_valid && !mem_wb_illegal_instr && (mem_wb_instr != NOP)) begin
                if (mem_wb_tid) begin
                    perf_thread1_retired_count_r <= perf_thread1_retired_count_r + 32'd1;
                    if (mem_wb_wb_sel == WB_MEM) perf_thread1_load_count_r <= perf_thread1_load_count_r + 32'd1;
                end else begin
                    perf_thread0_retired_count_r <= perf_thread0_retired_count_r + 32'd1;
                    if (mem_wb_wb_sel == WB_MEM) perf_thread0_load_count_r <= perf_thread0_load_count_r + 32'd1;
                end
            end
            if (ex_mem_valid && !ex_mem_illegal_instr && ex_mem_mem_write) begin
                if (ex_mem_tid) perf_thread1_store_count_r <= perf_thread1_store_count_r + 32'd1;
                else perf_thread0_store_count_r <= perf_thread0_store_count_r + 32'd1;
            end

            if (mem_stall) begin
                pc[0] <= pc[0];
                pc[1] <= pc[1];
                fetch_tid <= fetch_tid;
                if_id_valid <= if_id_valid;
                if_id_tid <= if_id_tid;
                if_id_pc <= if_id_pc;
                if_id_pc_plus4 <= if_id_pc_plus4;
                if_id_instr <= if_id_instr;
                id_ex_valid <= id_ex_valid;
                id_ex_tid <= id_ex_tid;
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
                ex_mem_valid <= ex_mem_valid;
                ex_mem_tid <= ex_mem_tid;
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
                mem_wb_tid <= ex_mem_tid;
                mem_wb_pc <= 32'h00000000;
                mem_wb_instr <= NOP;
                mem_wb_alu_y <= 32'h00000000;
                mem_wb_dmem_rdata <= 32'h00000000;
                mem_wb_pc_plus4 <= 32'h00000000;
                mem_wb_imm <= 32'h00000000;
                mem_wb_rd <= 5'd0;
                mem_wb_reg_write <= 1'b0;
                mem_wb_wb_sel <= WB_ALU;
                mem_wb_illegal_instr <= 1'b0;
            end else begin
                if (ex_redirect) begin
                    pc[id_ex_tid] <= ex_redirect_target;
                end else if (!raw_stall) begin
                    pc[fetch_tid] <= if_pc_plus4;
                    if (fetch_tid) perf_thread1_fetched_count_r <= perf_thread1_fetched_count_r + 32'd1;
                    else perf_thread0_fetched_count_r <= perf_thread0_fetched_count_r + 32'd1;
                    fetch_tid <= ~fetch_tid;
                end

                if_id_valid <= ex_redirect ? 1'b0 : (raw_stall ? if_id_valid : 1'b1);
                if_id_tid <= raw_stall ? if_id_tid : fetch_tid;
                if_id_pc <= raw_stall ? if_id_pc : if_pc;
                if_id_pc_plus4 <= raw_stall ? if_id_pc_plus4 : if_pc_plus4;
                if_id_instr <= ex_redirect ? NOP : (raw_stall ? if_id_instr : if_instr);

                id_ex_valid <= (ex_redirect || raw_stall) ? 1'b0 : if_id_valid;
                id_ex_tid <= raw_stall ? 1'b0 : if_id_tid;
                id_ex_pc <= raw_stall ? 32'h00000000 : if_id_pc;
                id_ex_pc_plus4 <= raw_stall ? 32'h00000000 : if_id_pc_plus4;
                id_ex_instr <= raw_stall ? NOP : if_id_instr;
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

                ex_mem_valid <= id_ex_valid;
                ex_mem_tid <= id_ex_tid;
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
                mem_wb_tid <= ex_mem_tid;
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
        end
    end
endmodule
