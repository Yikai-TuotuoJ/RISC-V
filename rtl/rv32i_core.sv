`timescale 1ns/1ps

module rv32i_core #(
    parameter IMEM_HEX = "tests/phase1_basic.hex"
)(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] pc_dbg,
    output logic [31:0] instr_dbg,
    output logic        illegal_instr_dbg
);
    logic [31:0] pc;

    logic [31:0] instr;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [31:0] imm;
    logic [2:0] alu_op;
    logic alu_src_imm;
    logic reg_write;
    logic mem_write;
    logic [1:0] wb_sel;
    logic branch;
    logic branch_ne;
    logic jump;
    logic jump_reg;
    logic alu_src_pc;
    logic illegal_instr;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_y;
    logic [31:0] dmem_rdata;
    logic  [31:0] wb_data;
    logic branch_equal;
    logic branch_taken;
    logic [31:0] pc_plus4;
    logic [31:0] branch_target;
    logic [31:0] jalr_target;
    logic [31:0] pc_next;

    localparam WB_ALU = 2'd0;
    localparam WB_MEM = 2'd1;
    localparam WB_PC4 = 2'd2;
    localparam WB_IMM = 2'd3;

    assign pc_dbg = pc;
    assign instr_dbg = instr;
    assign illegal_instr_dbg = illegal_instr;
    assign alu_a = alu_src_pc ? pc : rs1_data;
    assign alu_b = alu_src_imm ? imm : rs2_data;
    assign branch_equal = (rs1_data == rs2_data);
    assign branch_taken = branch && (branch_ne ? !branch_equal : branch_equal) && !illegal_instr;
    assign pc_plus4 = pc + 32'd4;
    assign branch_target = pc + imm;
    assign jalr_target = (rs1_data + imm) & 32'hfffffffe;
    assign pc_next = illegal_instr ? pc_plus4 :
                     jump ? (jump_reg ? jalr_target : branch_target) :
                     branch_taken ? branch_target : pc_plus4;

    always_comb begin
        case (wb_sel)
            WB_ALU: wb_data = alu_y;
            WB_MEM: wb_data = dmem_rdata;
            WB_PC4: wb_data = pc_plus4;
            WB_IMM: wb_data = imm;
            default: wb_data = alu_y;
        endcase
    end

    imem #(.HEX_FILE(IMEM_HEX)) u_imem (
        .addr(pc),
        .instr(instr)
    );

    decoder u_decoder (
        .instr(instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .alu_op(alu_op),
        .alu_src_imm(alu_src_imm),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .wb_sel(wb_sel),
        .branch(branch),
        .branch_ne(branch_ne),
        .jump(jump),
        .jump_reg(jump_reg),
        .alu_src_pc(alu_src_pc),
        .illegal_instr(illegal_instr)
    );

    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_write && !illegal_instr),
        .raddr1(rs1),
        .raddr2(rs2),
        .waddr(rd),
        .wdata(wb_data),
        .rdata1(rs1_data),
        .rdata2(rs2_data)
    );

    alu u_alu (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .y(alu_y)
    );

    dmem_stub u_dmem (
        .clk(clk),
        .we(mem_write && !illegal_instr),
        .addr(alu_y),
        .wdata(rs2_data),
        .rdata(dmem_rdata)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00000000;
        end else begin
            pc <= pc_next;
        end
    end
endmodule

