`timescale 1ns/1ps

module direct_mapped_dcache #(
    parameter CACHE_ENABLE = 0,
    parameter CACHE_LINES = 4,
    parameter PRIVATE_L1_ENABLE = 0,
    parameter L1_NUM_CORES = 2,
    parameter L2_ENABLE = 0,
    parameter L2_LINES = 8,
    parameter L3_ENABLE = 0,
    parameter L3_LINES = 8,
    parameter L3_UCP_ENABLE = 0,
    parameter L3_UCP_POLICY = 0,
    parameter UCP_REPARTITION_INTERVAL = 8,
    parameter STREAM_SPLIT_ADDR = 32'h00001000,
    parameter STREAM_ID_MODE = 0,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_WORDS = 256,
    parameter BASE_LATENCY_CYCLES = 1,
    parameter MISS_PENALTY_CYCLES = 3,
    parameter L2_HIT_LATENCY = 2,
    parameter L2_MISS_PENALTY = 6,
    parameter L3_HIT_LATENCY = 4,
    parameter L3_MISS_PENALTY = 12
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  req_valid,
    input  logic                  req_load,
    input  logic                  req_store,
    input  logic                  req_thread_id,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  stall,
    output logic                  trace_access,
    output logic                  trace_load,
    output logic                  trace_store,
    output logic                  trace_hit,
    output logic                  trace_miss,
    output logic                  trace_fill,
    output logic [ADDR_WIDTH-1:0] trace_addr,
    output logic                  trace_l2_access,
    output logic                  trace_l2_hit,
    output logic                  trace_l2_miss,
    output logic                  trace_l3_access,
    output logic                  trace_l3_hit,
    output logic                  trace_l3_miss,
    output logic                  trace_backing_access,
    output logic                  trace_stream_id,
    output logic [1:0]            trace_hit_level,
    output logic [31:0]           access_count,
    output logic [31:0]           load_access_count,
    output logic [31:0]           store_access_count,
    output logic [31:0]           hit_count,
    output logic [31:0]           miss_count,
    output logic [31:0]           miss_stall_count,
    output logic [31:0]           l1_core0_access_count,
    output logic [31:0]           l1_core0_hit_count,
    output logic [31:0]           l1_core0_miss_count,
    output logic [31:0]           l1_core1_access_count,
    output logic [31:0]           l1_core1_hit_count,
    output logic [31:0]           l1_core1_miss_count,
    output logic [31:0]           l2_access_count,
    output logic [31:0]           l2_hit_count,
    output logic [31:0]           l2_miss_count,
    output logic [31:0]           l3_access_count,
    output logic [31:0]           l3_hit_count,
    output logic [31:0]           l3_miss_count,
    output logic [31:0]           l3_stream0_access_count,
    output logic [31:0]           l3_stream0_hit_count,
    output logic [31:0]           l3_stream0_miss_count,
    output logic [31:0]           l3_stream1_access_count,
    output logic [31:0]           l3_stream1_hit_count,
    output logic [31:0]           l3_stream1_miss_count,
    output logic [31:0]           l3_stream0_alloc_lines,
    output logic [31:0]           l3_stream1_alloc_lines,
    output logic [31:0]           l3_ucp_repartition_count,
    output logic [31:0]           l3_ucp_interval_count,
    output logic [31:0]           backing_access_count
);
    localparam L1_INDEX_BITS = (CACHE_LINES <= 2) ? 1 :
                               (CACHE_LINES <= 4) ? 2 :
                               (CACHE_LINES <= 8) ? 3 :
                               (CACHE_LINES <= 16) ? 4 : 5;
    localparam L1_TAG_BITS = ADDR_WIDTH - 2 - L1_INDEX_BITS;
    localparam L2_INDEX_BITS = (L2_LINES <= 2) ? 1 :
                               (L2_LINES <= 4) ? 2 :
                               (L2_LINES <= 8) ? 3 :
                               (L2_LINES <= 16) ? 4 : 5;
    localparam L2_TAG_BITS = ADDR_WIDTH - 2 - L2_INDEX_BITS;
    localparam L3_INDEX_BITS = (L3_LINES <= 2) ? 1 :
                               (L3_LINES <= 4) ? 2 :
                               (L3_LINES <= 8) ? 3 :
                               (L3_LINES <= 16) ? 4 : 5;
    localparam L3_TAG_BITS = ADDR_WIDTH - 2;
    localparam integer L3_EQUAL_ALLOC0 = (L3_LINES / 2);
    localparam integer L3_FIXED_ALLOC0_RAW = ((L3_LINES * 3) / 4);
    localparam integer L3_FIXED_ALLOC0 = (L3_FIXED_ALLOC0_RAW < 1) ? 1 : ((L3_FIXED_ALLOC0_RAW >= L3_LINES) ? (L3_LINES - 1) : L3_FIXED_ALLOC0_RAW);

    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    logic                  valid [0:L1_NUM_CORES-1][0:CACHE_LINES-1];
    logic [L1_TAG_BITS-1:0] tag  [0:L1_NUM_CORES-1][0:CACHE_LINES-1];
    logic [DATA_WIDTH-1:0] data [0:L1_NUM_CORES-1][0:CACHE_LINES-1];

    logic                  l2_valid [0:L2_LINES-1];
    logic [L2_TAG_BITS-1:0] l2_tag  [0:L2_LINES-1];
    logic [DATA_WIDTH-1:0] l2_data [0:L2_LINES-1];

    logic                  l3_valid [0:L3_LINES-1];
    logic [L3_TAG_BITS-1:0] l3_tag  [0:L3_LINES-1];
    logic [DATA_WIDTH-1:0] l3_data [0:L3_LINES-1];

    logic                  ucp_shadow_valid [0:1][0:L3_LINES][0:L3_LINES-1];
    logic [L3_TAG_BITS-1:0] ucp_shadow_tag [0:1][0:L3_LINES][0:L3_LINES-1];
    logic [31:0]           ucp_shadow_hit_count [0:1][0:L3_LINES];

    logic stream_id;
    logic l1_bank_id;
    logic [L1_INDEX_BITS-1:0] index;
    logic [L1_TAG_BITS-1:0] req_tag;
    logic [L2_INDEX_BITS-1:0] l2_index;
    logic [L2_TAG_BITS-1:0] l2_req_tag;
    logic [L3_INDEX_BITS-1:0] l3_index;
    logic [L3_TAG_BITS-1:0] l3_req_tag;
    logic [31:0] word_addr;
    logic cache_req;
    logic line_hit;
    logic l2_line_hit;
    logic l3_line_hit;
    logic start_access;
    logic start_hit;
    logic start_miss;
    logic miss_active;
    logic [31:0] miss_wait_count;
    logic [ADDR_WIDTH-1:0] miss_addr;
    logic [DATA_WIDTH-1:0] miss_wdata;
    logic [DATA_WIDTH-1:0] miss_l2_data;
    logic [DATA_WIDTH-1:0] miss_l3_data;
    logic miss_load;
    logic miss_store;
    logic miss_stream_id;
    logic miss_l1_bank_id;
    logic miss_l2_hit;
    logic miss_l3_hit;
    logic miss_uses_l2;
    logic miss_uses_l3;
    logic [L1_INDEX_BITS-1:0] miss_index;
    logic [L1_TAG_BITS-1:0] miss_tag;
    logic [L2_INDEX_BITS-1:0] miss_l2_index;
    logic [L2_TAG_BITS-1:0] miss_l2_tag;
    logic [L3_INDEX_BITS-1:0] miss_l3_index;
    logic [L3_TAG_BITS-1:0] miss_l3_tag;
    logic [31:0] miss_word_addr;
    logic replay_suppress;
    logic fill_pulse;
    logic l2_access_pulse;
    logic l2_hit_pulse;
    logic l2_miss_pulse;
    logic l3_access_pulse;
    logic l3_hit_pulse;
    logic l3_miss_pulse;
    logic backing_access_pulse;
    logic [1:0] hit_level_pulse;
    logic [31:0] base_wait_count;
    logic base_active;
    logic [31:0] l3_alloc0;
    logic [31:0] l3_alloc1;
    logic [31:0] ucp_interval_count;
    logic [31:0] ucp_repartition_count;
    logic [31:0] ucp_best_alloc0;
    logic [31:0] ucp_best_alloc1;
    logic ucp_repartition_pending;

    integer i;
    integer j;
    integer k;
    integer m;
    integer ucp_best_score;
    integer ucp_candidate_score;
    integer ucp_candidate_alloc0;
    integer ucp_candidate_alloc1;

    function automatic [L3_INDEX_BITS-1:0] calc_l3_index(input logic [31:0] waddr, input logic sid, input logic [31:0] alloc0_in, input logic [31:0] alloc1_in);
        logic [31:0] local_index;
        begin
            if (!L3_UCP_ENABLE) begin
                calc_l3_index = waddr[L3_INDEX_BITS-1:0];
            end else if (!sid) begin
                local_index = (alloc0_in == 0) ? 32'd0 : (waddr % alloc0_in);
                calc_l3_index = local_index[L3_INDEX_BITS-1:0];
            end else begin
                local_index = alloc0_in + ((alloc1_in == 0) ? 32'd0 : (waddr % alloc1_in));
                calc_l3_index = local_index[L3_INDEX_BITS-1:0];
            end
        end
    endfunction

    function automatic [31:0] monitor_local_index(input logic [31:0] waddr, input integer alloc_lines);
        begin
            if (alloc_lines <= 1) monitor_local_index = 32'd0;
            else monitor_local_index = waddr % alloc_lines;
        end
    endfunction

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = '0;
        end
    end

    assign cache_req = req_valid && (req_load || req_store);
    assign stream_id = (STREAM_ID_MODE == 1) ? req_thread_id : (addr >= STREAM_SPLIT_ADDR);
    assign l1_bank_id = PRIVATE_L1_ENABLE ? stream_id : 1'b0;
    assign index = addr[2 +: L1_INDEX_BITS];
    assign req_tag = addr[ADDR_WIDTH-1 -: L1_TAG_BITS];
    assign l2_index = addr[2 +: L2_INDEX_BITS];
    assign l2_req_tag = addr[ADDR_WIDTH-1 -: L2_TAG_BITS];
    assign word_addr = {2'b00, addr[31:2]};
    assign l3_index = calc_l3_index(word_addr, stream_id, l3_alloc0, l3_alloc1);
    assign l3_req_tag = addr[ADDR_WIDTH-1:2];
    assign line_hit = CACHE_ENABLE && valid[l1_bank_id][index] && (tag[l1_bank_id][index] == req_tag);
    assign l2_line_hit = L2_ENABLE && l2_valid[l2_index] && (l2_tag[l2_index] == l2_req_tag);
    assign l3_line_hit = L3_ENABLE && l3_valid[l3_index] && (l3_tag[l3_index] == l3_req_tag);
    assign start_access = cache_req && !miss_active && !base_active && !replay_suppress;
    assign start_hit = start_access && CACHE_ENABLE && line_hit;
    assign start_miss = start_access && CACHE_ENABLE && !line_hit;

    always_comb begin
        if (CACHE_ENABLE && line_hit) begin
            rdata = data[l1_bank_id][index];
        end else if (L2_ENABLE && l2_line_hit) begin
            rdata = l2_data[l2_index];
        end else if (L3_ENABLE && l3_line_hit) begin
            rdata = l3_data[l3_index];
        end else if (word_addr < MEM_WORDS) begin
            rdata = mem[word_addr];
        end else begin
            rdata = '0;
        end
    end

    always_comb begin
        if (CACHE_ENABLE) begin
            stall = miss_active || start_miss;
        end else begin
            stall = base_active || (start_access && (BASE_LATENCY_CYCLES > 1));
        end
    end

    assign trace_access = start_access;
    assign trace_load = start_access && req_load;
    assign trace_store = start_access && req_store;
    assign trace_hit = start_hit;
    assign trace_miss = start_miss;
    assign trace_fill = fill_pulse;
    assign trace_addr = start_access ? addr : miss_addr;
    assign trace_l2_access = l2_access_pulse;
    assign trace_l2_hit = l2_hit_pulse;
    assign trace_l2_miss = l2_miss_pulse;
    assign trace_l3_access = l3_access_pulse;
    assign trace_l3_hit = l3_hit_pulse;
    assign trace_l3_miss = l3_miss_pulse;
    assign trace_backing_access = backing_access_pulse;
    assign trace_stream_id = start_access ? stream_id : miss_stream_id;
    assign trace_hit_level = hit_level_pulse;
    assign l3_stream0_alloc_lines = l3_alloc0;
    assign l3_stream1_alloc_lines = l3_alloc1;
    assign l3_ucp_repartition_count = ucp_repartition_count;
    assign l3_ucp_interval_count = ucp_interval_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_count <= 32'h00000000;
            load_access_count <= 32'h00000000;
            store_access_count <= 32'h00000000;
            hit_count <= 32'h00000000;
            miss_count <= 32'h00000000;
            miss_stall_count <= 32'h00000000;
            l1_core0_access_count <= 32'h00000000;
            l1_core0_hit_count <= 32'h00000000;
            l1_core0_miss_count <= 32'h00000000;
            l1_core1_access_count <= 32'h00000000;
            l1_core1_hit_count <= 32'h00000000;
            l1_core1_miss_count <= 32'h00000000;
            l2_access_count <= 32'h00000000;
            l2_hit_count <= 32'h00000000;
            l2_miss_count <= 32'h00000000;
            l3_access_count <= 32'h00000000;
            l3_hit_count <= 32'h00000000;
            l3_miss_count <= 32'h00000000;
            l3_stream0_access_count <= 32'h00000000;
            l3_stream0_hit_count <= 32'h00000000;
            l3_stream0_miss_count <= 32'h00000000;
            l3_stream1_access_count <= 32'h00000000;
            l3_stream1_hit_count <= 32'h00000000;
            l3_stream1_miss_count <= 32'h00000000;
            backing_access_count <= 32'h00000000;
            ucp_interval_count <= 32'h00000000;
            ucp_repartition_count <= 32'h00000000;
            ucp_best_alloc0 <= L3_EQUAL_ALLOC0;
            ucp_best_alloc1 <= L3_LINES - L3_EQUAL_ALLOC0;
            ucp_repartition_pending <= 1'b0;
            if (L3_UCP_POLICY == 2) begin
                l3_alloc0 <= L3_EQUAL_ALLOC0;
                l3_alloc1 <= L3_LINES - L3_EQUAL_ALLOC0;
            end else if (L3_UCP_POLICY == 1) begin
                l3_alloc0 <= L3_FIXED_ALLOC0;
                l3_alloc1 <= L3_LINES - L3_FIXED_ALLOC0;
            end else begin
                l3_alloc0 <= L3_EQUAL_ALLOC0;
                l3_alloc1 <= L3_LINES - L3_EQUAL_ALLOC0;
            end
            miss_active <= 1'b0;
            miss_wait_count <= 32'h00000000;
            miss_addr <= '0;
            miss_wdata <= '0;
            miss_l2_data <= '0;
            miss_l3_data <= '0;
            miss_load <= 1'b0;
            miss_store <= 1'b0;
            miss_stream_id <= 1'b0;
            miss_l1_bank_id <= 1'b0;
            miss_l2_hit <= 1'b0;
            miss_l3_hit <= 1'b0;
            miss_uses_l2 <= 1'b0;
            miss_uses_l3 <= 1'b0;
            miss_index <= '0;
            miss_tag <= '0;
            miss_l2_index <= '0;
            miss_l2_tag <= '0;
            miss_l3_index <= '0;
            miss_l3_tag <= '0;
            miss_word_addr <= 32'h00000000;
            replay_suppress <= 1'b0;
            fill_pulse <= 1'b0;
            l2_access_pulse <= 1'b0;
            l2_hit_pulse <= 1'b0;
            l2_miss_pulse <= 1'b0;
            l3_access_pulse <= 1'b0;
            l3_hit_pulse <= 1'b0;
            l3_miss_pulse <= 1'b0;
            backing_access_pulse <= 1'b0;
            hit_level_pulse <= 2'd0;
            base_wait_count <= 32'h00000000;
            base_active <= 1'b0;
            for (j = 0; j < L1_NUM_CORES; j = j + 1) begin
                for (i = 0; i < CACHE_LINES; i = i + 1) begin
                    valid[j][i] <= 1'b0;
                    tag[j][i] <= '0;
                    data[j][i] <= '0;
                end
            end
            for (i = 0; i < L2_LINES; i = i + 1) begin
                l2_valid[i] <= 1'b0;
                l2_tag[i] <= '0;
                l2_data[i] <= '0;
            end
            for (i = 0; i < L3_LINES; i = i + 1) begin
                l3_valid[i] <= 1'b0;
                l3_tag[i] <= '0;
                l3_data[i] <= '0;
            end
            for (j = 0; j < 2; j = j + 1) begin
                for (k = 0; k <= L3_LINES; k = k + 1) begin
                    ucp_shadow_hit_count[j][k] <= 32'h00000000;
                    for (i = 0; i < L3_LINES; i = i + 1) begin
                        ucp_shadow_valid[j][k][i] <= 1'b0;
                        ucp_shadow_tag[j][k][i] <= '0;
                    end
                end
            end
        end else begin
            fill_pulse <= 1'b0;
            l2_access_pulse <= 1'b0;
            l2_hit_pulse <= 1'b0;
            l2_miss_pulse <= 1'b0;
            l3_access_pulse <= 1'b0;
            l3_hit_pulse <= 1'b0;
            l3_miss_pulse <= 1'b0;
            backing_access_pulse <= 1'b0;
            hit_level_pulse <= 2'd0;

            if (ucp_repartition_pending && !miss_active && !start_access && !replay_suppress) begin
                if ((ucp_best_alloc0 != l3_alloc0) || (ucp_best_alloc1 != l3_alloc1)) begin
                    l3_alloc0 <= ucp_best_alloc0;
                    l3_alloc1 <= ucp_best_alloc1;
                    ucp_repartition_count <= ucp_repartition_count + 32'd1;
                    for (i = 0; i < L3_LINES; i = i + 1) begin
                        l3_valid[i] <= 1'b0;
                        l3_tag[i] <= '0;
                        l3_data[i] <= '0;
                    end
                end
                ucp_interval_count <= 32'h00000000;
                for (j = 0; j < 2; j = j + 1) begin
                    for (k = 0; k <= L3_LINES; k = k + 1) begin
                        ucp_shadow_hit_count[j][k] <= 32'h00000000;
                        for (i = 0; i < L3_LINES; i = i + 1) begin
                            ucp_shadow_valid[j][k][i] <= 1'b0;
                            ucp_shadow_tag[j][k][i] <= '0;
                        end
                    end
                end
                ucp_repartition_pending <= 1'b0;
            end

            if (CACHE_ENABLE) begin
                if (stall) begin
                    miss_stall_count <= miss_stall_count + 32'd1;
                end

                if (start_access) begin
                    access_count <= access_count + 32'd1;
                    if (!stream_id) l1_core0_access_count <= l1_core0_access_count + 32'd1;
                    else l1_core1_access_count <= l1_core1_access_count + 32'd1;
                    if (req_load) load_access_count <= load_access_count + 32'd1;
                    if (req_store) store_access_count <= store_access_count + 32'd1;
                    if (line_hit) begin
                        hit_count <= hit_count + 32'd1;
                        hit_level_pulse <= 2'd1;
                        if (!stream_id) l1_core0_hit_count <= l1_core0_hit_count + 32'd1;
                        else l1_core1_hit_count <= l1_core1_hit_count + 32'd1;
                        if (req_store && (word_addr < MEM_WORDS)) begin
                            mem[word_addr] <= wdata;
                            data[l1_bank_id][index] <= wdata;
                            if (L2_ENABLE && l2_line_hit) l2_data[l2_index] <= wdata;
                            if (L3_ENABLE && l3_line_hit) l3_data[l3_index] <= wdata;
                        end
                    end else begin
                        miss_count <= miss_count + 32'd1;
                        if (!stream_id) l1_core0_miss_count <= l1_core0_miss_count + 32'd1;
                        else l1_core1_miss_count <= l1_core1_miss_count + 32'd1;
                        if (L2_ENABLE) begin
                            l2_access_count <= l2_access_count + 32'd1;
                            l2_access_pulse <= 1'b1;
                            if (l2_line_hit) begin
                                l2_hit_count <= l2_hit_count + 32'd1;
                                l2_hit_pulse <= 1'b1;
                                hit_level_pulse <= 2'd2;
                            end else begin
                                l2_miss_count <= l2_miss_count + 32'd1;
                                l2_miss_pulse <= 1'b1;
                                if (L3_ENABLE) begin
                                    l3_access_count <= l3_access_count + 32'd1;
                                    l3_access_pulse <= 1'b1;
                                    if (!stream_id) l3_stream0_access_count <= l3_stream0_access_count + 32'd1;
                                    else l3_stream1_access_count <= l3_stream1_access_count + 32'd1;
                                    if (L3_UCP_ENABLE && (L3_UCP_POLICY == 2)) begin
                                        ucp_interval_count <= ucp_interval_count + 32'd1;
                                        for (k = 1; k < L3_LINES; k = k + 1) begin
                                            m = monitor_local_index(word_addr, k);
                                            if (ucp_shadow_valid[stream_id][k][m] && (ucp_shadow_tag[stream_id][k][m] == l3_req_tag)) begin
                                                ucp_shadow_hit_count[stream_id][k] <= ucp_shadow_hit_count[stream_id][k] + 32'd1;
                                            end else begin
                                                ucp_shadow_valid[stream_id][k][m] <= 1'b1;
                                                ucp_shadow_tag[stream_id][k][m] <= l3_req_tag;
                                            end
                                        end
                                        if ((UCP_REPARTITION_INTERVAL > 0) && ((ucp_interval_count + 32'd1) >= UCP_REPARTITION_INTERVAL)) begin
                                            ucp_repartition_pending <= 1'b1;
                                            ucp_candidate_alloc0 = l3_alloc0;
                                            ucp_candidate_alloc1 = l3_alloc1;
                                            ucp_best_score = ucp_shadow_hit_count[0][l3_alloc0] + ucp_shadow_hit_count[1][l3_alloc1];
                                            for (k = 1; k < L3_LINES; k = k + 1) begin
                                                ucp_candidate_score = ucp_shadow_hit_count[0][k] + ucp_shadow_hit_count[1][L3_LINES-k];
                                                if (ucp_candidate_score > ucp_best_score) begin
                                                    ucp_best_score = ucp_candidate_score;
                                                    ucp_candidate_alloc0 = k;
                                                    ucp_candidate_alloc1 = L3_LINES - k;
                                                end
                                            end
                                            ucp_best_alloc0 <= ucp_candidate_alloc0;
                                            ucp_best_alloc1 <= ucp_candidate_alloc1;
                                        end
                                    end
                                    if (l3_line_hit) begin
                                        l3_hit_count <= l3_hit_count + 32'd1;
                                        l3_hit_pulse <= 1'b1;
                                        hit_level_pulse <= 2'd3;
                                        if (!stream_id) l3_stream0_hit_count <= l3_stream0_hit_count + 32'd1;
                                        else l3_stream1_hit_count <= l3_stream1_hit_count + 32'd1;
                                    end else begin
                                        l3_miss_count <= l3_miss_count + 32'd1;
                                        l3_miss_pulse <= 1'b1;
                                        backing_access_count <= backing_access_count + 32'd1;
                                        backing_access_pulse <= 1'b1;
                                        if (!stream_id) l3_stream0_miss_count <= l3_stream0_miss_count + 32'd1;
                                        else l3_stream1_miss_count <= l3_stream1_miss_count + 32'd1;
                                    end
                                end else begin
                                    backing_access_count <= backing_access_count + 32'd1;
                                    backing_access_pulse <= 1'b1;
                                end
                            end
                        end else begin
                            backing_access_count <= backing_access_count + 32'd1;
                            backing_access_pulse <= 1'b1;
                        end

                        miss_active <= 1'b1;
                        if (L2_ENABLE && l2_line_hit) begin
                            miss_wait_count <= (L2_HIT_LATENCY <= 1) ? 32'd0 : (L2_HIT_LATENCY - 2);
                        end else if (L3_ENABLE && l3_line_hit) begin
                            miss_wait_count <= (L3_HIT_LATENCY <= 1) ? 32'd0 : (L3_HIT_LATENCY - 2);
                        end else if (L3_ENABLE) begin
                            miss_wait_count <= (L3_MISS_PENALTY <= 1) ? 32'd0 : (L3_MISS_PENALTY - 2);
                        end else if (L2_ENABLE) begin
                            miss_wait_count <= (L2_MISS_PENALTY <= 1) ? 32'd0 : (L2_MISS_PENALTY - 2);
                        end else begin
                            miss_wait_count <= (MISS_PENALTY_CYCLES <= 1) ? 32'd0 : (MISS_PENALTY_CYCLES - 2);
                        end
                        miss_addr <= addr;
                        miss_wdata <= wdata;
                        miss_l2_data <= l2_data[l2_index];
                        miss_l3_data <= l3_data[l3_index];
                        miss_load <= req_load;
                        miss_store <= req_store;
                        miss_stream_id <= stream_id;
                miss_l1_bank_id <= l1_bank_id;
                        miss_l2_hit <= l2_line_hit;
                        miss_l3_hit <= l3_line_hit;
                        miss_uses_l2 <= L2_ENABLE;
                        miss_uses_l3 <= L3_ENABLE;
                        miss_index <= index;
                        miss_tag <= req_tag;
                        miss_l2_index <= l2_index;
                        miss_l2_tag <= l2_req_tag;
                        miss_l3_index <= l3_index;
                        miss_l3_tag <= l3_req_tag;
                        miss_word_addr <= word_addr;
                    end
                end

                if (miss_active) begin
                    if (miss_wait_count == 0) begin
                        miss_active <= 1'b0;
                        replay_suppress <= 1'b1;
                        fill_pulse <= 1'b1;
                        valid[miss_l1_bank_id][miss_index] <= 1'b1;
                        tag[miss_l1_bank_id][miss_index] <= miss_tag;
                        if (miss_store) begin
                            if (miss_word_addr < MEM_WORDS) mem[miss_word_addr] <= miss_wdata;
                            data[miss_l1_bank_id][miss_index] <= miss_wdata;
                            if (miss_uses_l2) begin
                                l2_valid[miss_l2_index] <= 1'b1;
                                l2_tag[miss_l2_index] <= miss_l2_tag;
                                l2_data[miss_l2_index] <= miss_wdata;
                            end
                            if (miss_uses_l3) begin
                                l3_valid[miss_l3_index] <= 1'b1;
                                l3_tag[miss_l3_index] <= miss_l3_tag;
                                l3_data[miss_l3_index] <= miss_wdata;
                            end
                        end else if (miss_load) begin
                            if (miss_uses_l2 && miss_l2_hit) begin
                                data[miss_l1_bank_id][miss_index] <= miss_l2_data;
                            end else if (miss_uses_l3 && miss_l3_hit) begin
                                data[miss_l1_bank_id][miss_index] <= miss_l3_data;
                                if (miss_uses_l2) begin
                                    l2_valid[miss_l2_index] <= 1'b1;
                                    l2_tag[miss_l2_index] <= miss_l2_tag;
                                    l2_data[miss_l2_index] <= miss_l3_data;
                                end
                            end else if (miss_word_addr < MEM_WORDS) begin
                                data[miss_l1_bank_id][miss_index] <= mem[miss_word_addr];
                                if (miss_uses_l2) begin
                                    l2_valid[miss_l2_index] <= 1'b1;
                                    l2_tag[miss_l2_index] <= miss_l2_tag;
                                    l2_data[miss_l2_index] <= mem[miss_word_addr];
                                end
                                if (miss_uses_l3) begin
                                    l3_valid[miss_l3_index] <= 1'b1;
                                    l3_tag[miss_l3_index] <= miss_l3_tag;
                                    l3_data[miss_l3_index] <= mem[miss_word_addr];
                                end
                            end else begin
                                data[miss_l1_bank_id][miss_index] <= '0;
                                if (miss_uses_l2) begin
                                    l2_valid[miss_l2_index] <= 1'b1;
                                    l2_tag[miss_l2_index] <= miss_l2_tag;
                                    l2_data[miss_l2_index] <= '0;
                                end
                                if (miss_uses_l3) begin
                                    l3_valid[miss_l3_index] <= 1'b1;
                                    l3_tag[miss_l3_index] <= miss_l3_tag;
                                    l3_data[miss_l3_index] <= '0;
                                end
                            end
                        end
                    end else begin
                        miss_wait_count <= miss_wait_count - 32'd1;
                    end
                end else if (replay_suppress) begin
                    replay_suppress <= 1'b0;
                end
            end else begin
                if (start_access) begin
                    access_count <= access_count + 32'd1;
                    if (req_load) load_access_count <= load_access_count + 32'd1;
                    if (req_store) store_access_count <= store_access_count + 32'd1;
                    if (req_store && (word_addr < MEM_WORDS) && (BASE_LATENCY_CYCLES <= 1)) mem[word_addr] <= wdata;
                    if (BASE_LATENCY_CYCLES > 1) begin
                        if (BASE_LATENCY_CYCLES <= 2) begin
                            replay_suppress <= 1'b1;
                            if (req_store && (word_addr < MEM_WORDS)) mem[word_addr] <= wdata;
                        end else begin
                            base_active <= 1'b1;
                            base_wait_count <= BASE_LATENCY_CYCLES - 3;
                            miss_addr <= addr;
                            miss_wdata <= wdata;
                            miss_store <= req_store;
                            miss_word_addr <= word_addr;
                        end
                    end
                end

                if (base_active) begin
                    miss_stall_count <= miss_stall_count + 32'd1;
                    if (base_wait_count == 0) begin
                        base_active <= 1'b0;
                        replay_suppress <= 1'b1;
                        if (miss_store && (miss_word_addr < MEM_WORDS)) mem[miss_word_addr] <= miss_wdata;
                    end else begin
                        base_wait_count <= base_wait_count - 32'd1;
                    end
                end else if (replay_suppress) begin
                    replay_suppress <= 1'b0;
                end
            end
        end
    end
endmodule



