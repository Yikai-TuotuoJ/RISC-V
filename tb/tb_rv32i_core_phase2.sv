`timescale 1ns/1ps

module tb_rv32i_core_phase2;
    logic clk;
    logic rst_n;
    logic [31:0] pc_dbg;
    logic [31:0] instr_dbg;
    logic illegal_instr_dbg;

    integer errors;

    rv32i_core #(.IMEM_HEX("tests/phase2_mem_branch.hex")) dut (
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
        $dumpfile("sim/phase2_mem_branch.vcd");
        $dumpvars(0, tb_rv32i_core_phase2);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (26) @(posedge clk);

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end

        expect_reg(5'd0, 32'h00000000);
        expect_reg(5'd1, 32'h00000064);
        expect_reg(5'd2, 32'h0000002a);
        expect_reg(5'd3, 32'h0000002a);
        expect_reg(5'd4, 32'h00000002);
        expect_reg(5'd5, 32'h00000003);
        expect_reg(5'd6, 32'h00000006);
        expect_reg(5'd7, 32'h00000007);
        expect_reg(5'd10, 32'h0000008e);
        expect_reg(5'd11, 32'h00000064);
        expect_reg(5'd12, 32'h00000020);
        expect_reg(5'd13, 32'h0000006e);
        expect_reg(5'd14, 32'h0000004e);
        expect_dmem(32'h00000064, 32'h0000002a);

        if (errors == 0) begin
            $display("PASS: Phase 2 RV32I memory/branch directed test passed");
        end else begin
            $display("FAIL: Phase 2 RV32I memory/branch directed test failed with %0d error(s)", errors);
        end

        $finish;
    end
endmodule

