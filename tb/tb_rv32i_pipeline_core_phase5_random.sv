`timescale 1ns/1ps

module tb_rv32i_pipeline_core_phase5_random;
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

    logic [31:0] expected_regs [0:31];
    logic [31:0] expected_dmem [0:15];
    integer errors;
    integer i;
    integer wb_count;

    rv32i_pipeline_core #(.IMEM_HEX("tests/phase5_random.hex")) dut (
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
            wb_count <= 0;
        end else if (trace_wb_we) begin
            wb_count <= wb_count + 1;
        end
    end

    initial begin
        $dumpfile("sim/phase5_random.vcd");
        $dumpvars(0, tb_rv32i_pipeline_core_phase5_random);
        $readmemh("tests/phase5_random_expected_regs.hex", expected_regs);
        $readmemh("tests/phase5_random_expected_dmem.hex", expected_dmem);

        errors = 0;
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        repeat (245) @(posedge clk);

        if (illegal_instr_dbg) begin
            $display("FAIL: illegal instruction observed at pc=0x%08x instr=0x%08x", pc_dbg, instr_dbg);
            errors = errors + 1;
        end
        if (trace_stall !== 1'b0) begin
            $display("FAIL: randomized hazard-free test unexpectedly reported a stall");
            errors = errors + 1;
        end

        for (i = 0; i < 32; i = i + 1) begin
            if (dut.u_regfile.regs[i] !== expected_regs[i]) begin
                $display("FAIL: x%0d expected 0x%08x got 0x%08x", i, expected_regs[i], dut.u_regfile.regs[i]);
                errors = errors + 1;
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            if (dut.u_dmem.mem[i] !== expected_dmem[i]) begin
                $display("FAIL: mem[%0d] expected 0x%08x got 0x%08x", i, expected_dmem[i], dut.u_dmem.mem[i]);
                errors = errors + 1;
            end
        end

        if (wb_count < 20) begin
            $display("FAIL: expected at least 20 writebacks, observed %0d", wb_count);
            errors = errors + 1;
        end else begin
            $display("PASS: observed %0d randomized writebacks", wb_count);
        end

        if (errors == 0) begin
            $display("PASS: Phase 5 randomized pipeline test matched reference model");
        end else begin
            $display("FAIL: Phase 5 randomized pipeline test failed with %0d error(s)", errors);
        end
        $finish;
    end
endmodule

