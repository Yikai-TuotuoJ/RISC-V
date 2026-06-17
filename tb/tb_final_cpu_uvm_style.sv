
`timescale 1ns/1ps

module tb_final_cpu_uvm_style;
    localparam NOP = 32'h00000013;

    logic clk;
    logic rst_n;
    logic imem_req_valid;
    logic [31:0] imem_req_addr;
    logic imem_req_ready;
    logic imem_resp_valid;
    logic [31:0] imem_resp_rdata;
    logic dmem_req_valid;
    logic dmem_req_write;
    logic [31:0] dmem_req_addr;
    logic [31:0] dmem_req_wdata;
    logic dmem_req_ready;
    logic dmem_resp_valid;
    logic [31:0] dmem_resp_rdata;

    logic [31:0] imem [0:511];
    logic [31:0] dmem [0:511];

    integer i;
    integer trace_fd;
    integer summary_fd;
    integer summary_csv_fd;
    integer cache_fd;
    integer checks;
    integer errors;
    integer mon_fetch_seen [0:1];
    integer mon_dispatch_seen [0:1];
    integer mon_issue_seen [0:1];
    integer mon_cdb_seen [0:1];
    integer mon_commit_seen [0:1];
    integer mon_recover_seen [0:1];
    integer mon_cache_seen [0:1];
    integer mon_ucp_seen;

    rv32i_final_cpu_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .imem_req_valid(imem_req_valid),
        .imem_req_addr(imem_req_addr),
        .imem_req_ready(imem_req_ready),
        .imem_resp_valid(imem_resp_valid),
        .imem_resp_rdata(imem_resp_rdata),
        .dmem_req_valid(dmem_req_valid),
        .dmem_req_write(dmem_req_write),
        .dmem_req_addr(dmem_req_addr),
        .dmem_req_wdata(dmem_req_wdata),
        .dmem_req_ready(dmem_req_ready),
        .dmem_resp_valid(dmem_resp_valid),
        .dmem_resp_rdata(dmem_resp_rdata)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function automatic [31:0] enc_r(input [6:0] funct7, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [4:0] rd);
        enc_r = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
    endfunction

    function automatic [31:0] enc_i(input integer imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_i = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] enc_s(input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3);
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
    endfunction

    function automatic [31:0] enc_b(input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3);
        logic [12:0] simm;
        begin
            simm = imm[12:0];
            enc_b = {simm[12], simm[10:5], rs2, rs1, funct3, simm[4:1], simm[11], 7'b1100011};
        end
    endfunction

    function automatic [31:0] enc_j(input integer imm, input [4:0] rd);
        logic [20:0] simm;
        begin
            simm = imm[20:0];
            enc_j = {simm[20], simm[10:1], simm[11], simm[19:12], rd, 7'b1101111};
        end
    endfunction

    task automatic check(input [1023:0] name, input logic cond);
        begin
            checks = checks + 1;
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL: %0s", name);
                $fwrite(trace_fd, "CHECK_FAIL: %0s\n", name);
            end else begin
                $fwrite(trace_fd, "CHECK_PASS: %0s\n", name);
            end
        end
    endtask

    task automatic load_programs;
        begin
            for (i = 0; i < 512; i = i + 1) begin
                imem[i] = NOP;
                dmem[i] = 32'd0;
            end

            imem[0]  = enc_i(5,   5'd0, 3'b000, 5'd1,  7'b0010011);
            imem[1]  = enc_i(7,   5'd0, 3'b000, 5'd2,  7'b0010011);
            imem[2]  = enc_r(7'b0000000, 5'd2,  5'd1, 3'b000, 5'd3);
            imem[3]  = enc_r(7'b0100000, 5'd1,  5'd3, 3'b000, 5'd4);
            imem[4]  = enc_r(7'b0000000, 5'd4,  5'd3, 3'b111, 5'd5);
            imem[5]  = enc_r(7'b0000000, 5'd4,  5'd3, 3'b110, 5'd6);
            imem[6]  = enc_r(7'b0000000, 5'd4,  5'd3, 3'b100, 5'd7);
            imem[7]  = enc_i(99,  5'd0, 3'b000, 5'd0,  7'b0010011);
            imem[8]  = enc_i(64,  5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[9]  = enc_s(0,   5'd3, 5'd10, 3'b010);
            imem[10] = enc_i(0,   5'd10,3'b010, 5'd11, 7'b0000011);
            imem[11] = enc_i(80,  5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[12] = enc_s(0,   5'd4, 5'd10, 3'b010);
            imem[13] = enc_i(0,   5'd10,3'b010, 5'd16, 7'b0000011);
            imem[14] = enc_i(96,  5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[15] = enc_s(0,   5'd1, 5'd10, 3'b010);
            imem[16] = enc_i(0,   5'd10,3'b010, 5'd17, 7'b0000011);
            imem[17] = enc_i(112, 5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[18] = enc_s(0,   5'd2, 5'd10, 3'b010);
            imem[19] = enc_i(0,   5'd10,3'b010, 5'd18, 7'b0000011);
            imem[20] = enc_i(64,  5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[21] = enc_i(0,   5'd10,3'b010, 5'd19, 7'b0000011);
            imem[22] = enc_b(8,   5'd3, 5'd11, 3'b000);
            imem[23] = enc_i(1,   5'd0, 3'b000, 5'd12, 7'b0010011);
            imem[24] = enc_i(2,   5'd0, 3'b000, 5'd12, 7'b0010011);
            imem[25] = enc_b(8,   5'd0, 5'd11, 3'b001);
            imem[26] = enc_i(1,   5'd0, 3'b000, 5'd13, 7'b0010011);
            imem[27] = enc_i(3,   5'd0, 3'b000, 5'd13, 7'b0010011);
            imem[28] = enc_j(8,   5'd14);
            imem[29] = enc_i(1,   5'd0, 3'b000, 5'd15, 7'b0010011);
            imem[30] = enc_i(3,   5'd0, 3'b000, 5'd15, 7'b0010011);
            imem[31] = enc_i(140, 5'd0, 3'b000, 5'd20, 7'b0010011);
            imem[32] = enc_i(0,   5'd20,3'b000, 5'd21, 7'b1100111);
            imem[33] = enc_i(1,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[34] = enc_i(2,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[35] = enc_i(4,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[36] = enc_j(0,   5'd0); // park thread 0

            imem[64] = enc_i(20,  5'd0, 3'b000, 5'd1,  7'b0010011);
            imem[65] = enc_i(1,   5'd0, 3'b000, 5'd2,  7'b0010011);
            imem[66] = enc_r(7'b0000000, 5'd2,  5'd1, 3'b000, 5'd3);
            imem[67] = enc_i(128, 5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[68] = enc_s(0,   5'd3, 5'd10, 3'b010);
            imem[69] = enc_i(0,   5'd10,3'b010, 5'd4,  7'b0000011);
            imem[70] = enc_i(144, 5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[71] = enc_s(0,   5'd1, 5'd10, 3'b010);
            imem[72] = enc_i(0,   5'd10,3'b010, 5'd6,  7'b0000011);
            imem[73] = enc_i(160, 5'd0, 3'b000, 5'd10, 7'b0010011);
            imem[74] = enc_s(0,   5'd2, 5'd10, 3'b010);
            imem[75] = enc_i(0,   5'd10,3'b010, 5'd7,  7'b0000011);
            imem[76] = enc_b(8,   5'd0, 5'd4,  3'b001);
            imem[77] = enc_i(1,   5'd0, 3'b000, 5'd5,  7'b0010011);
            imem[78] = enc_i(5,   5'd0, 3'b000, 5'd5,  7'b0010011);
            imem[79] = enc_b(8,   5'd3, 5'd4,  3'b000);
            imem[80] = enc_i(1,   5'd0, 3'b000, 5'd8,  7'b0010011);
            imem[81] = enc_i(8,   5'd0, 3'b000, 5'd8,  7'b0010011);
            imem[82] = enc_j(8,   5'd9);
            imem[83] = enc_i(1,   5'd0, 3'b000, 5'd12, 7'b0010011);
            imem[84] = enc_i(12,  5'd0, 3'b000, 5'd12, 7'b0010011);
            imem[85] = enc_i(360, 5'd0, 3'b000, 5'd20, 7'b0010011);
            imem[86] = enc_i(0,   5'd20,3'b000, 5'd21, 7'b1100111);
            imem[87] = enc_i(1,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[88] = enc_i(2,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[89] = enc_i(3,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[90] = enc_i(6,   5'd0, 3'b000, 5'd22, 7'b0010011);
            imem[91] = enc_j(0,   5'd0); // park thread 1
        end
    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            imem_resp_valid <= 1'b0;
            imem_resp_rdata <= NOP;
        end else begin
            imem_resp_valid <= imem_req_valid && imem_req_ready;
            if (imem_req_valid && imem_req_ready) begin
                if (imem_req_addr[31:2] < 512) imem_resp_rdata <= imem[imem_req_addr[31:2]];
                else imem_resp_rdata <= NOP;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmem_resp_valid <= 1'b0;
            dmem_resp_rdata <= 32'd0;
        end else begin
            dmem_resp_valid <= dmem_req_valid && dmem_req_ready;
            if (dmem_req_valid && dmem_req_ready) begin
                if (dmem_req_addr[31:2] < 512) begin
                    if (dmem_req_write) begin
                        dmem[dmem_req_addr[31:2]] <= dmem_req_wdata;
                        dmem_resp_rdata <= dmem_req_wdata;
                    end else begin
                        dmem_resp_rdata <= dmem[dmem_req_addr[31:2]];
                    end
                end else begin
                    dmem_resp_rdata <= 32'hbad0_0000;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n) begin
            if (dut.mon_fetch_valid) begin
                mon_fetch_seen[dut.mon_fetch_tid] <= mon_fetch_seen[dut.mon_fetch_tid] + 1;
                $fwrite(trace_fd, "IF: tid=%0d pc=%08x\n", dut.mon_fetch_tid, dut.mon_fetch_pc);
            end
            if (dut.mon_dispatch_valid) begin
                mon_dispatch_seen[dut.mon_dispatch_tid] <= mon_dispatch_seen[dut.mon_dispatch_tid] + 1;
                $fwrite(trace_fd, "DISPATCH: tid=%0d op=%0d\n", dut.mon_dispatch_tid, dut.mon_dispatch_op);
            end
            if (dut.mon_issue_valid) begin
                mon_issue_seen[dut.mon_issue_tid] <= mon_issue_seen[dut.mon_issue_tid] + 1;
                $fwrite(trace_fd, "ISSUE: tid=%0d op=%0d oldest_ready_count=%0d\n", dut.mon_issue_tid, dut.mon_issue_op, dut.rs_oldest_ready_count);
            end
            if (dut.mon_cdb_valid) begin
                mon_cdb_seen[dut.mon_cdb_tid] <= mon_cdb_seen[dut.mon_cdb_tid] + 1;
                $fwrite(trace_fd, "CDB: tid=%0d data=%08x\n", dut.mon_cdb_tid, dut.mon_cdb_data);
            end
            if (dut.mon_commit_valid) begin
                mon_commit_seen[dut.mon_commit_tid] <= mon_commit_seen[dut.mon_commit_tid] + 1;
                $fwrite(trace_fd, "COMMIT: tid=%0d rd=x%0d data=%08x store=%0d total=%0d\n", dut.mon_commit_tid, dut.mon_commit_rd, dut.mon_commit_data, dut.mon_commit_store, dut.commit_count);
            end
            if (dut.mon_recover_valid) begin
                mon_recover_seen[dut.mon_recover_tid] <= mon_recover_seen[dut.mon_recover_tid] + 1;
                $fwrite(trace_fd, "RECOVER: tid=%0d target=%08x\n", dut.mon_recover_tid, dut.mon_recover_target);
            end
            if (dut.mon_cache_access) begin
                mon_cache_seen[dut.mon_cache_tid] <= mon_cache_seen[dut.mon_cache_tid] + 1;
                $fwrite(trace_fd, "CACHE: tid=%0d level=%0d l1_s0=%0d/%0d l1_s1=%0d/%0d l2=%0d/%0d l3=%0d/%0d ucp=%0d/%0d\n",
                    dut.mon_cache_tid, dut.mon_cache_hit_level,
                    dut.l1_hit_count[0], dut.l1_miss_count[0], dut.l1_hit_count[1], dut.l1_miss_count[1],
                    dut.l2_hit_count, dut.l2_miss_count, dut.l3_hit_count, dut.l3_miss_count, dut.ucp_alloc0, dut.ucp_alloc1);
            end
            if (dut.mon_ucp_repartition) begin
                mon_ucp_seen <= mon_ucp_seen + 1;
                $fwrite(trace_fd, "UCP: repartition alloc0=%0d alloc1=%0d count=%0d\n", dut.ucp_alloc0, dut.ucp_alloc1, dut.ucp_repartition_count);
            end
        end
    end

    task automatic write_reports;
        real cpi;
        begin
            cpi = (dut.commit_count == 0) ? 0.0 : (1.0 * mon_fetch_seen[0] + mon_fetch_seen[1]) / dut.commit_count;
            summary_fd = $fopen("reports/perf/final_cpu_summary.md", "w");
            $fwrite(summary_fd, "# Phase 21 Final CPU Summary\n\n");
            $fwrite(summary_fd, "| metric | value |\n|---|---:|\n");
            $fwrite(summary_fd, "| checks | %0d |\n", checks);
            $fwrite(summary_fd, "| errors | %0d |\n", errors);
            $fwrite(summary_fd, "| fetch_thread0 | %0d |\n", mon_fetch_seen[0]);
            $fwrite(summary_fd, "| fetch_thread1 | %0d |\n", mon_fetch_seen[1]);
            $fwrite(summary_fd, "| commits | %0d |\n", dut.commit_count);
            $fwrite(summary_fd, "| branch_count | %0d |\n", dut.branch_count);
            $fwrite(summary_fd, "| mispredicts | %0d |\n", dut.mispredict_count);
            $fwrite(summary_fd, "| rob_dispatches | %0d |\n", dut.dispatch_count);
            $fwrite(summary_fd, "| cdb_broadcasts | %0d |\n", dut.cdb_count);
            $fwrite(summary_fd, "| estimated_cpi_like_fetch_per_commit | %0.3f |\n", cpi);
            $fclose(summary_fd);

            summary_csv_fd = $fopen("reports/perf/final_cpu_summary.csv", "w");
            $fwrite(summary_csv_fd, "test,checks,errors,fetch_t0,fetch_t1,commits,branches,mispredicts,dispatches,cdb\n");
            $fwrite(summary_csv_fd, "phase21_final,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n", checks, errors, mon_fetch_seen[0], mon_fetch_seen[1], dut.commit_count, dut.branch_count, dut.mispredict_count, dut.dispatch_count, dut.cdb_count);
            $fclose(summary_csv_fd);

            cache_fd = $fopen("reports/perf/final_cpu_cache_ucp_summary.md", "w");
            $fwrite(cache_fd, "# Phase 21 Cache/UCP Summary\n\n");
            $fwrite(cache_fd, "| metric | value |\n|---|---:|\n");
            $fwrite(cache_fd, "| l1_stream0_accesses | %0d |\n", dut.l1_access_count[0]);
            $fwrite(cache_fd, "| l1_stream0_hits | %0d |\n", dut.l1_hit_count[0]);
            $fwrite(cache_fd, "| l1_stream0_misses | %0d |\n", dut.l1_miss_count[0]);
            $fwrite(cache_fd, "| l1_stream1_accesses | %0d |\n", dut.l1_access_count[1]);
            $fwrite(cache_fd, "| l1_stream1_hits | %0d |\n", dut.l1_hit_count[1]);
            $fwrite(cache_fd, "| l1_stream1_misses | %0d |\n", dut.l1_miss_count[1]);
            $fwrite(cache_fd, "| l2_accesses | %0d |\n", dut.l2_access_count);
            $fwrite(cache_fd, "| l2_hits | %0d |\n", dut.l2_hit_count);
            $fwrite(cache_fd, "| l2_misses | %0d |\n", dut.l2_miss_count);
            $fwrite(cache_fd, "| l2_pseudo_lru_replacements | %0d |\n", dut.l2_plru_replace_count);
            $fwrite(cache_fd, "| l3_accesses | %0d |\n", dut.l3_access_count);
            $fwrite(cache_fd, "| l3_hits | %0d |\n", dut.l3_hit_count);
            $fwrite(cache_fd, "| l3_misses | %0d |\n", dut.l3_miss_count);
            $fwrite(cache_fd, "| l3_tree_pseudo_lru_replacements | %0d |\n", dut.l3_plru_replace_count);
            $fwrite(cache_fd, "| dynamic_ucp_alloc0 | %0d |\n", dut.ucp_alloc0);
            $fwrite(cache_fd, "| dynamic_ucp_alloc1 | %0d |\n", dut.ucp_alloc1);
            $fwrite(cache_fd, "| dynamic_ucp_repartitions | %0d |\n", dut.ucp_repartition_count);
            $fwrite(cache_fd, "| backing_memory_requests | %0d |\n", dut.dmem_request_count);
            $fclose(cache_fd);
        end
    endtask

    initial begin
        trace_fd = $fopen("reports/sim/final_cpu_trace.log", "w");
        $dumpfile("sim/final_cpu.vcd");
        $dumpvars(0, tb_final_cpu_uvm_style);
        checks = 0;
        errors = 0;
        mon_ucp_seen = 0;
        for (i = 0; i < 2; i = i + 1) begin
            mon_fetch_seen[i] = 0;
            mon_dispatch_seen[i] = 0;
            mon_issue_seen[i] = 0;
            mon_cdb_seen[i] = 0;
            mon_commit_seen[i] = 0;
            mon_recover_seen[i] = 0;
            mon_cache_seen[i] = 0;
        end
        imem_req_ready = 1'b1;
        dmem_req_ready = 1'b1;
        load_programs();

        rst_n = 1'b0;
        repeat (6) @(posedge clk);
        rst_n = 1'b1;
        repeat (500) @(posedge clk);

        check("thread0 ADDI x1", dut.regs[0][1] == 32'd5);
        check("thread0 ADDI x2", dut.regs[0][2] == 32'd7);
        check("thread0 ADD x3", dut.regs[0][3] == 32'd12);
        check("thread0 SUB x4", dut.regs[0][4] == 32'd7);
        check("thread0 AND x5", dut.regs[0][5] == 32'd4);
        check("thread0 OR x6", dut.regs[0][6] == 32'd15);
        check("thread0 XOR x7", dut.regs[0][7] == 32'd11);
        check("thread0 x0 hardwired", dut.regs[0][0] == 32'd0);
        check("thread0 first load", dut.regs[0][11] == 32'd12);
        check("thread0 load 80", dut.regs[0][16] == 32'd7);
        check("thread0 load 96", dut.regs[0][17] == 32'd5);
        check("thread0 load 112", dut.regs[0][18] == 32'd7);
        check("thread0 reload 64", dut.regs[0][19] == 32'd12);
        check("thread0 BEQ skipped wrong path", dut.regs[0][12] == 32'd2);
        check("thread0 BNE skipped wrong path", dut.regs[0][13] == 32'd3);
        check("thread0 JAL link", dut.regs[0][14] == 32'd116);
        check("thread0 JAL target", dut.regs[0][15] == 32'd3);
        check("thread0 JALR link", dut.regs[0][21] == 32'd132);
        check("thread0 JALR target", dut.regs[0][22] == 32'd4);
        check("thread0 memory 64", dmem[16] == 32'd12);
        check("thread0 memory 80", dmem[20] == 32'd7);
        check("thread0 memory 96", dmem[24] == 32'd5);
        check("thread0 memory 112", dmem[28] == 32'd7);

        check("thread1 ADDI x1", dut.regs[1][1] == 32'd20);
        check("thread1 ADDI x2", dut.regs[1][2] == 32'd1);
        check("thread1 ADD x3", dut.regs[1][3] == 32'd21);
        check("thread1 load 128", dut.regs[1][4] == 32'd21);
        check("thread1 load 144", dut.regs[1][6] == 32'd20);
        check("thread1 load 160", dut.regs[1][7] == 32'd1);
        check("thread1 BNE skipped wrong path", dut.regs[1][5] == 32'd5);
        check("thread1 BEQ skipped wrong path", dut.regs[1][8] == 32'd8);
        check("thread1 JAL link", dut.regs[1][9] == 32'd332);
        check("thread1 JAL target", dut.regs[1][12] == 32'd12);
        check("thread1 JALR link", dut.regs[1][21] == 32'd348);
        check("thread1 JALR target", dut.regs[1][22] == 32'd6);
        check("thread1 x0 hardwired", dut.regs[1][0] == 32'd0);
        check("thread1 memory 128", dmem[32] == 32'd21);
        check("thread1 memory 144", dmem[36] == 32'd20);
        check("thread1 memory 160", dmem[40] == 32'd1);

        check("fetch monitor thread0", mon_fetch_seen[0] > 20);
        check("fetch monitor thread1", mon_fetch_seen[1] > 20);
        check("round robin roughly balanced", (mon_fetch_seen[0] + 2 >= mon_fetch_seen[1]) && (mon_fetch_seen[1] + 2 >= mon_fetch_seen[0]));
        check("dispatch monitor thread0", mon_dispatch_seen[0] > 20);
        check("dispatch monitor thread1", mon_dispatch_seen[1] > 20);
        check("issue monitor thread0", mon_issue_seen[0] > 20);
        check("issue monitor thread1", mon_issue_seen[1] > 20);
        check("cdb monitor thread0", mon_cdb_seen[0] > 10);
        check("cdb monitor thread1", mon_cdb_seen[1] > 8);
        check("commit monitor thread0", mon_commit_seen[0] > 20);
        check("commit monitor thread1", mon_commit_seen[1] > 18);
        check("recovery monitor thread0", mon_recover_seen[0] >= 2);
        check("recovery monitor thread1", mon_recover_seen[1] >= 2);

        check("decoded count", dut.decoded_count >= 55);
        check("dispatch count matches decoded", dut.dispatch_count == dut.decoded_count);
        check("issue count matches decoded", dut.issue_count == dut.decoded_count);
        check("ROB tail advanced", dut.rob_tail >= 55);
        check("ROB entries observed", dut.rob_valid[0] || dut.rob_valid[1]);
        check("CDB broadcasts", dut.cdb_count >= 35);
        check("in-order commit count", dut.commit_count >= 55);
        check("thread0 commit count", dut.thread_commit_count[0] >= 25);
        check("thread1 commit count", dut.thread_commit_count[1] >= 24);
        check("oldest-ready RS selections", dut.rs_oldest_ready_count >= 55);
        check("store-at-commit count", dut.lsq_store_commit_count >= 7);
        check("x0 suppressed count", dut.x0_suppressed_count >= 1);

        check("branch and jump count", dut.branch_count >= 8);
        check("mispredict recovery count", dut.mispredict_count >= 4);
        check("wrong path squash count", dut.wrong_path_squash_count >= 4);
        check("gshare ghr changed", dut.ghr_dbg != 4'd0);
        check("gshare index observable", dut.gshare_idx_dbg < 16);

        check("cache monitor thread0", mon_cache_seen[0] >= 8);
        check("cache monitor thread1", mon_cache_seen[1] >= 6);
        check("private L1 thread0 access", dut.l1_access_count[0] >= 8);
        check("private L1 thread1 access", dut.l1_access_count[1] >= 6);
        check("private L1 thread0 consistency", dut.l1_access_count[0] == dut.l1_hit_count[0] + dut.l1_miss_count[0]);
        check("private L1 thread1 consistency", dut.l1_access_count[1] == dut.l1_hit_count[1] + dut.l1_miss_count[1]);
        check("private L1 both banks used", dut.l1_access_count[0] > 0 && dut.l1_access_count[1] > 0);
        check("shared L2 accessed", dut.l2_access_count > 0);
        check("shared L2 consistency", dut.l2_access_count == dut.l2_hit_count + dut.l2_miss_count);
        check("shared L2 pseudo-LRU replacements", dut.l2_plru_replace_count > 0);
        check("shared L3 accessed", dut.l3_access_count > 0);
        check("shared L3 consistency", dut.l3_access_count == dut.l3_hit_count + dut.l3_miss_count);
        check("shared L3 tree pseudo-LRU replacements", dut.l3_plru_replace_count > 0);
        check("dynamic UCP repartitions", dut.ucp_repartition_count > 0);
        check("dynamic UCP monitor events", mon_ucp_seen > 0);
        check("dynamic UCP allocation sum", dut.ucp_alloc0 + dut.ucp_alloc1 == 32'd4);
        check("dynamic UCP allocation min stream0", dut.ucp_alloc0 >= 1);
        check("dynamic UCP allocation min stream1", dut.ucp_alloc1 >= 1);
        check("backing memory requests", dut.dmem_request_count >= 7);
        check("cache hit or miss activity", (dut.l1_hit_count[0] + dut.l1_hit_count[1] + dut.l2_hit_count + dut.l3_hit_count + dut.l3_miss_count) > 0);

        check("product imem bus used", mon_fetch_seen[0] + mon_fetch_seen[1] > 40);
        check("product dmem bus used", dut.dmem_request_count > 0);
        check("no active dmem request at end", dmem_req_valid == 1'b0);
        check("no pending dmem at end", dut.dmem_busy == 1'b0);
        check("thread0 pc progressed", dut.pc[0] >= 32'd144);
        check("thread1 pc progressed", dut.pc[1] >= 32'd364);
        check("final check count threshold", checks >= 60);

        write_reports();
        $display("FINALPERF: test=phase21_final checks=%0d errors=%0d commits=%0d fetch_t0=%0d fetch_t1=%0d l1_t0=%0d l1_t1=%0d l2=%0d l3=%0d ucp_reparts=%0d", checks, errors, dut.commit_count, mon_fetch_seen[0], mon_fetch_seen[1], dut.l1_access_count[0], dut.l1_access_count[1], dut.l2_access_count, dut.l3_access_count, dut.ucp_repartition_count);
        if (checks < 60) begin
            $display("FAIL: fewer than 60 final CPU checks were executed (%0d)", checks);
            errors = errors + 1;
        end
        if (errors == 0) begin
            $display("PASS: Phase 21 final CPU validation checks=%0d", checks);
        end else begin
            $display("FAIL: Phase 21 final CPU validation errors=%0d checks=%0d", errors, checks);
        end
        $fclose(trace_fd);
        #10 $finish;
    end
endmodule


