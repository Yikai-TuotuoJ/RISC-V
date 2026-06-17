`timescale 1ns/1ps

module tb_rv32i_pipeline_core_phase4;
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
        $dumpfile("sim/phase4_pipeline_basic.vcd");
        $dumpvars(0, tb_rv32i_pipeline_core_phase4);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (95) @(posedge clk);

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end

        expect_reg(5'd0, 32'h00000000);
        expect_reg(5'd1, 32'h0000000a);
        expect_reg(5'd2, 32'h00000014);
        expect_reg(5'd3, 32'h0000001e);
        expect_reg(5'd4, 32'h00000014);
        expect_reg(5'd5, 32'h00000014);
        expect_reg(5'd6, 32'h0000001e);
        expect_reg(5'd7, 32'h0000001e);
        expect_reg(5'd8, 32'h0000001e);
        expect_reg(5'd9, 32'h12345000);
        expect_reg(5'd10, 32'h000010a0);
        expect_reg(5'd11, 32'h00000003);
        expect_reg(5'd12, 32'h00000006);
        expect_reg(5'd13, 32'h00000009);
        expect_reg(5'd14, 32'h000000ec);
        expect_reg(5'd15, 32'h00000000);
        expect_reg(5'd16, 32'h00000120);
        expect_reg(5'd17, 32'h00000118);
        expect_reg(5'd18, 32'h0000000c);
        expect_reg(5'd19, 32'h00000000);
        expect_dmem(32'h00000000, 32'h0000001e);

        if (errors == 0) begin
            $display("PASS: Phase 4 5-stage pipeline baseline directed test passed");
        end else begin
            $display("FAIL: Phase 4 5-stage pipeline baseline directed test failed with %0d error(s)", errors);
        end

        $finish;
    end
endmodule


