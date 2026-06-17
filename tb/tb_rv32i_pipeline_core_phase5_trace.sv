`timescale 1ns/1ps

module tb_rv32i_pipeline_core_phase5_trace;
    logic clk;
    logic rst_n;
    logic [31:0] pc_dbg;
    logic [31:0] instr_dbg;
    logic illegal_instr_dbg;
    logic trace_if_valid;
    logic [31:0] trace_if_pc;
    logic [31:0] trace_if_instr;
    logic trace_id_valid;
    logic [31:0] trace_id_pc;
    logic [31:0] trace_id_instr;
    logic trace_ex_valid;
    logic [31:0] trace_ex_pc;
    logic [31:0] trace_ex_instr;
    logic trace_mem_valid;
    logic [31:0] trace_mem_pc;
    logic [31:0] trace_mem_instr;
    logic trace_wb_valid;
    logic [31:0] trace_wb_pc;
    logic [31:0] trace_wb_instr;
    logic [4:0] trace_wb_rd;
    logic [31:0] trace_wb_wdata;
    logic trace_wb_we;
    logic trace_stall;
    logic trace_flush;
    logic trace_redirect;
    logic [31:0] trace_redirect_target;

    integer errors;
    integer trace_fd;
    integer trace_log_fd;
    integer cycle;
    integer redirect_count;
    integer wb_count;

    rv32i_pipeline_core #(.IMEM_HEX("tests/phase4_pipeline_basic.hex")) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg),
        .trace_if_valid(trace_if_valid),
        .trace_if_pc(trace_if_pc),
        .trace_if_instr(trace_if_instr),
        .trace_id_valid(trace_id_valid),
        .trace_id_pc(trace_id_pc),
        .trace_id_instr(trace_id_instr),
        .trace_ex_valid(trace_ex_valid),
        .trace_ex_pc(trace_ex_pc),
        .trace_ex_instr(trace_ex_instr),
        .trace_mem_valid(trace_mem_valid),
        .trace_mem_pc(trace_mem_pc),
        .trace_mem_instr(trace_mem_instr),
        .trace_wb_valid(trace_wb_valid),
        .trace_wb_pc(trace_wb_pc),
        .trace_wb_instr(trace_wb_instr),
        .trace_wb_rd(trace_wb_rd),
        .trace_wb_wdata(trace_wb_wdata),
        .trace_wb_we(trace_wb_we),
        .trace_stall(trace_stall),
        .trace_flush(trace_flush),
        .trace_redirect(trace_redirect),
        .trace_redirect_target(trace_redirect_target)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle <= 0;
            redirect_count <= 0;
            wb_count <= 0;
        end else begin
            $fwrite(trace_fd, "%0d,%0d,0x%08x,0x%08x,%0d,0x%08x,0x%08x,%0d,0x%08x,0x%08x,%0d,0x%08x,0x%08x,%0d,0x%08x,0x%08x,%0d,%0d,0x%08x,%0d,%0d,%0d,0x%08x\n",
                cycle,
                trace_if_valid, trace_if_pc, trace_if_instr,
                trace_id_valid, trace_id_pc, trace_id_instr,
                trace_ex_valid, trace_ex_pc, trace_ex_instr,
                trace_mem_valid, trace_mem_pc, trace_mem_instr,
                trace_wb_valid, trace_wb_pc, trace_wb_instr,
                trace_wb_we, trace_wb_rd, trace_wb_wdata,
                trace_stall, trace_flush, trace_redirect, trace_redirect_target);
            $fwrite(trace_log_fd, "CYCLE=%0d\n", cycle);
            $fwrite(trace_log_fd, "IF:  valid=%0d pc=%08x instr=%08x\n", trace_if_valid, trace_if_pc, trace_if_instr);
            $fwrite(trace_log_fd, "ID:  valid=%0d pc=%08x instr=%08x\n", trace_id_valid, trace_id_pc, trace_id_instr);
            $fwrite(trace_log_fd, "EX:  valid=%0d pc=%08x instr=%08x\n", trace_ex_valid, trace_ex_pc, trace_ex_instr);
            $fwrite(trace_log_fd, "MEM: valid=%0d pc=%08x instr=%08x\n", trace_mem_valid, trace_mem_pc, trace_mem_instr);
            $fwrite(trace_log_fd, "WB:  valid=%0d pc=%08x instr=%08x rd=x%0d we=%0d wdata=%08x\n", trace_wb_valid, trace_wb_pc, trace_wb_instr, trace_wb_rd, trace_wb_we, trace_wb_wdata);
            $fwrite(trace_log_fd, "CTRL: stall=%0d flush=%0d taken=%0d target=%08x\n\n", trace_stall, trace_flush, trace_redirect, trace_redirect_target);
            cycle <= cycle + 1;
            if (trace_redirect) redirect_count <= redirect_count + 1;
            if (trace_wb_we) wb_count <= wb_count + 1;
        end
    end

    task expect_reg;
        input [4:0] idx;
        input [31:0] expected;
        begin
            if (dut.u_regfile.regs[idx] !== expected) begin
                $display("FAIL: x%0d expected 0x%08x got 0x%08x", idx, expected, dut.u_regfile.regs[idx]);
                errors = errors + 1;
            end else begin
                $display("PASS: x%0d = 0x%08x", idx, expected);
            end
        end
    endtask

    task expect_dmem;
        input [31:0] byte_addr;
        input [31:0] expected;
        begin
            if (dut.u_dmem.mem[byte_addr[9:2]] !== expected) begin
                $display("FAIL: mem[0x%08x] expected 0x%08x got 0x%08x", byte_addr, expected, dut.u_dmem.mem[byte_addr[9:2]]);
                errors = errors + 1;
            end else begin
                $display("PASS: mem[0x%08x] = 0x%08x", byte_addr, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/phase5_pipeline_trace.vcd");
        $dumpvars(0, tb_rv32i_pipeline_core_phase5_trace);
        trace_fd = $fopen("reports/phase5_pipeline_trace.csv", "w");
        trace_log_fd = $fopen("reports/sim/pipeline_trace.log", "w");
        $fwrite(trace_fd, "cycle,if_valid,if_pc,if_instr,id_valid,id_pc,id_instr,ex_valid,ex_pc,ex_instr,mem_valid,mem_pc,mem_instr,wb_valid,wb_pc,wb_instr,wb_we,wb_rd,wb_wdata,stall,flush,redirect,redirect_target\n");

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (95) @(posedge clk);
        #1;

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end
        if (trace_stall !== 1'b0) begin
            $display("FAIL: Phase 5 baseline unexpectedly reported a stall");
            errors = errors + 1;
        end
        if (redirect_count < 4) begin
            $display("FAIL: expected at least 4 redirects, observed %0d", redirect_count);
            errors = errors + 1;
        end else begin
            $display("PASS: observed %0d redirects", redirect_count);
        end
        if (wb_count < 15) begin
            $display("FAIL: expected multiple writebacks, observed %0d", wb_count);
            errors = errors + 1;
        end else begin
            $display("PASS: observed %0d writebacks", wb_count);
        end

        expect_reg(5'd0, 32'h00000000);
        expect_reg(5'd1, 32'h0000000a);
        expect_reg(5'd2, 32'h00000014);
        expect_reg(5'd3, 32'h0000001e);
        expect_reg(5'd8, 32'h0000001e);
        expect_reg(5'd9, 32'h12345000);
        expect_reg(5'd10, 32'h000010a0);
        expect_reg(5'd14, 32'h000000ec);
        expect_reg(5'd17, 32'h00000118);
        expect_reg(5'd18, 32'h0000000c);
        expect_reg(5'd19, 32'h00000000);
        expect_dmem(32'h00000000, 32'h0000001e);

        if (errors == 0) begin
            $display("PASS: Phase 5 pipeline trace directed test passed");
        end else begin
            $display("FAIL: Phase 5 pipeline trace directed test failed with %0d error(s)", errors);
        end

        $fclose(trace_fd);
        $fclose(trace_log_fd);
        $finish;
    end
endmodule



