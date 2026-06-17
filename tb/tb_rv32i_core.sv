`timescale 1ns/1ps

module tb_rv32i_core;
    logic clk;
    logic rst_n;
    logic [31:0] pc_dbg;
    logic [31:0] instr_dbg;
    logic illegal_instr_dbg;

    integer errors;

    rv32i_core #(.IMEM_HEX("tests/phase1_basic.hex")) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_dbg(pc_dbg),
        .instr_dbg(instr_dbg),
        .illegal_instr_dbg(illegal_instr_dbg)
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

    initial begin
        $dumpfile("sim/phase1_basic.vcd");
        $dumpvars(0, tb_rv32i_core);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (12) @(posedge clk);

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end

        expect_reg(5'd0, 32'h00000000);
        expect_reg(5'd1, 32'h00000005);
        expect_reg(5'd2, 32'h0000000c);
        expect_reg(5'd3, 32'h00000011);
        expect_reg(5'd4, 32'h00000005);
        expect_reg(5'd5, 32'h00000004);
        expect_reg(5'd6, 32'h0000000d);
        expect_reg(5'd7, 32'h00000009);
        expect_reg(5'd8, 32'hfffffff8);
        expect_reg(5'd9, 32'hfffffff9);

        if (errors == 0) begin
            $display("PASS: Phase 1 RV32I subset directed test passed");
        end else begin
            $display("FAIL: Phase 1 RV32I subset directed test failed with %0d error(s)", errors);
        end

        $finish;
    end
endmodule


