`timescale 1ns/1ps

module decoder(
    input  logic [31:0] instr,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic  [31:0] imm,
    output logic  [2:0]  alu_op,
    output logic         alu_src_imm,
    output logic         reg_write,
    output logic         mem_write,
    output logic  [1:0]  wb_sel,
    output logic         branch,
    output logic         branch_ne,
    output logic         jump,
    output logic         jump_reg,
    output logic         alu_src_pc,
    output logic         illegal_instr
);
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_OP     = 7'b0110011;
    localparam OPCODE_OP_IMM = 7'b0010011;

    localparam FUNCT3_ADD_SUB = 3'b000;
    localparam FUNCT3_AND     = 3'b111;
    localparam FUNCT3_OR      = 3'b110;
    localparam FUNCT3_XOR     = 3'b100;
    localparam FUNCT3_LW_SW   = 3'b010;
    localparam FUNCT3_BEQ     = 3'b000;
    localparam FUNCT3_BNE     = 3'b001;
    localparam FUNCT3_JALR    = 3'b000;

    localparam FUNCT7_ADD = 7'b0000000;
    localparam FUNCT7_SUB = 7'b0100000;

    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_AND = 3'd2;
    localparam ALU_OR  = 3'd3;
    localparam ALU_XOR = 3'd4;

    localparam WB_ALU  = 2'd0;
    localparam WB_MEM  = 2'd1;
    localparam WB_PC4  = 2'd2;
    localparam WB_IMM  = 2'd3;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    assign rd  = instr[11:7];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];

    always_comb begin
        imm = imm_i;
        alu_op = ALU_ADD;
        alu_src_imm = 1'b0;
        reg_write = 1'b0;
        mem_write = 1'b0;
        wb_sel = WB_ALU;
        branch = 1'b0;
        branch_ne = 1'b0;
        jump = 1'b0;
        jump_reg = 1'b0;
        alu_src_pc = 1'b0;
        illegal_instr = 1'b0;

        case (opcode)
            OPCODE_OP: begin
                reg_write = 1'b1;
                case (funct3)
                    FUNCT3_ADD_SUB: begin
                        if (funct7 == FUNCT7_ADD) begin
                            alu_op = ALU_ADD;
                        end else if (funct7 == FUNCT7_SUB) begin
                            alu_op = ALU_SUB;
                        end else begin
                            reg_write = 1'b0;
                            illegal_instr = 1'b1;
                        end
                    end
                    FUNCT3_AND: begin
                        if (funct7 == FUNCT7_ADD) alu_op = ALU_AND;
                        else begin reg_write = 1'b0; illegal_instr = 1'b1; end
                    end
                    FUNCT3_OR: begin
                        if (funct7 == FUNCT7_ADD) alu_op = ALU_OR;
                        else begin reg_write = 1'b0; illegal_instr = 1'b1; end
                    end
                    FUNCT3_XOR: begin
                        if (funct7 == FUNCT7_ADD) alu_op = ALU_XOR;
                        else begin reg_write = 1'b0; illegal_instr = 1'b1; end
                    end
                    default: begin
                        reg_write = 1'b0;
                        illegal_instr = 1'b1;
                    end
                endcase
            end
            OPCODE_OP_IMM: begin
                imm = imm_i;
                alu_src_imm = 1'b1;
                if (funct3 == FUNCT3_ADD_SUB) begin
                    reg_write = 1'b1;
                    alu_op = ALU_ADD;
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            OPCODE_LOAD: begin
                imm = imm_i;
                alu_src_imm = 1'b1;
                if (funct3 == FUNCT3_LW_SW) begin
                    reg_write = 1'b1;
                    wb_sel = WB_MEM;
                    alu_op = ALU_ADD;
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            OPCODE_STORE: begin
                imm = imm_s;
                alu_src_imm = 1'b1;
                if (funct3 == FUNCT3_LW_SW) begin
                    mem_write = 1'b1;
                    alu_op = ALU_ADD;
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            OPCODE_BRANCH: begin
                imm = imm_b;
                branch = 1'b1;
                if (funct3 == FUNCT3_BEQ) begin
                    branch_ne = 1'b0;
                end else if (funct3 == FUNCT3_BNE) begin
                    branch_ne = 1'b1;
                end else begin
                    branch = 1'b0;
                    illegal_instr = 1'b1;
                end
            end
            OPCODE_JAL: begin
                imm = imm_j;
                reg_write = 1'b1;
                wb_sel = WB_PC4;
                jump = 1'b1;
            end
            OPCODE_JALR: begin
                imm = imm_i;
                alu_src_imm = 1'b1;
                if (funct3 == FUNCT3_JALR) begin
                    reg_write = 1'b1;
                    wb_sel = WB_PC4;
                    jump = 1'b1;
                    jump_reg = 1'b1;
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            OPCODE_LUI: begin
                imm = imm_u;
                reg_write = 1'b1;
                wb_sel = WB_IMM;
            end
            OPCODE_AUIPC: begin
                imm = imm_u;
                alu_src_imm = 1'b1;
                alu_src_pc = 1'b1;
                reg_write = 1'b1;
                wb_sel = WB_ALU;
                alu_op = ALU_ADD;
            end
            default: begin
                illegal_instr = 1'b1;
            end
        endcase
    end
endmodule


