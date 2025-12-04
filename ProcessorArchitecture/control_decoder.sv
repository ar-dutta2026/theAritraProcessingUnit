import definitions::*;

module control_decoder (
    input logic [2:0] opcode,
    output logic reg_write,
    output logic alu_src_imm,  // 0 = Reg, 1 = Immediate
    output logic mem_write,
    output logic mem_to_reg,   // 1 = Load from Mem
    output logic branch,       // BNEZ signal
    output logic is_jal,       // 1 if JAL
    output logic jump,         // 1 if J or JAL
    output logic update_flags  // 1 if we should save status flags
);

    always_comb begin
        // Defaults
        reg_write    = 0;
        alu_src_imm  = 0;
        mem_write    = 0;
        mem_to_reg   = 0;
        branch       = 0;
        is_jal       = 0;
        jump         = 0;
        update_flags = 0;

        case (opcode)
            OP_R_TYPE: begin
                reg_write = 1;
                update_flags = 1;
            end
            OP_LI: begin
                reg_write = 1;
                alu_src_imm = 1;
            end
            OP_LW: begin
                reg_write = 1;
                alu_src_imm = 1;
                mem_to_reg = 1;
            end
            OP_SW: begin
                mem_write = 1;
                alu_src_imm = 1;
            end
            OP_BNEZ: begin
                branch = 1;
            end
            OP_SHIFT: begin
                reg_write = 1;
                update_flags = 1;
            end
            OP_J: begin
                jump = 1;
            end
            OP_JAL: begin
                jump = 1;
                is_jal = 1;
                reg_write = 1;
            end
        endcase
    end

endmodule