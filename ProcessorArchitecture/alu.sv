import definitions::*;

module alu (
    input  logic [D_WIDTH-1:0] src_a,
    input  logic [D_WIDTH-1:0] src_b,
    input  logic [2:0]         opcode,
    input  logic [1:0]         funct,
    output logic [D_WIDTH-1:0] alu_result,
    output logic               zero_flag,
    output logic               carry_out,
    output logic               overflow_flag
);

    logic [D_WIDTH:0] temp_sum;  // one extra bit for carry

    always_comb begin
        // Safe defaults
        alu_result    = '0;
        carry_out     = 1'b0;
        overflow_flag = 1'b0;
        temp_sum      = '0;

        unique case (opcode)

            // -----------------------------
            // R-type: ADD, SUB, XOR, AND
            // opcode = OP_R_TYPE (3'b000)
            // funct  = 00 (ADD), 01 (SUB), 10 (XOR), 11 (AND)
            // -----------------------------
            OP_R_TYPE: begin
                unique case (funct)
                    FUNCT_ADD: begin
                        temp_sum   = {1'b0, src_a} + {1'b0, src_b};
                        alu_result = temp_sum[D_WIDTH-1:0];
                        carry_out  = temp_sum[D_WIDTH];
                        // signed overflow detection:
                        overflow_flag =
                            (src_a[D_WIDTH-1] == src_b[D_WIDTH-1]) &&
                            (alu_result[D_WIDTH-1] != src_a[D_WIDTH-1]);
                    end

                    FUNCT_SUB: begin
                        temp_sum   = {1'b0, src_a} - {1'b0, src_b};
                        alu_result = temp_sum[D_WIDTH-1:0];
                        carry_out  = temp_sum[D_WIDTH];
                        // signed overflow detection for subtraction
                        overflow_flag =
                            (src_a[D_WIDTH-1] != src_b[D_WIDTH-1]) &&
                            (alu_result[D_WIDTH-1] != src_a[D_WIDTH-1]);
                    end

                    FUNCT_XOR: begin
                        alu_result = src_a ^ src_b;
                    end

                    FUNCT_AND: begin
                        // *** IMPORTANT FIX: this must be src_a & src_b ***
                        alu_result = src_a & src_b;
                    end

                    default: begin
                        // If funct is invalid, just pass through src_a
                        alu_result = src_a;
                    end
                endcase
            end

            // -----------------------------
            // LI: Load Immediate
            // opcode = OP_LI (3'b001)
            // src_b carries the zero-extended imm[3:0]
            // -----------------------------
            OP_LI: begin
                alu_result = src_b;  // immediate value
            end

            // -----------------------------
            // LW / SW: address calculation
            // opcode = 010 / 011
            // address = src_a + src_b (base + offset)
            // -----------------------------
            OP_LW,
            OP_SW: begin
                temp_sum   = {1'b0, src_a} + {1'b0, src_b};
                alu_result = temp_sum[D_WIDTH-1:0];  // effective address
                carry_out  = temp_sum[D_WIDTH];
            end

            // -----------------------------
            // SHIFT: SLL / SRL
            // opcode = OP_SHIFT (3'b101)
            // funct  = FUNCT_SLL (01), FUNCT_SRL (10)
            // -----------------------------
            OP_SHIFT: begin
                unique case (funct)
                    FUNCT_SLL: begin
                        carry_out  = src_a[D_WIDTH-1];     // bit shifted out
                        alu_result = src_a << 1;
                    end
                    FUNCT_SRL: begin
                        carry_out  = src_a[0];
                        alu_result = src_a >> 1;
                    end
                    default: begin
                        alu_result = src_a;
                    end
                endcase
            end

            // -----------------------------
            // BNEZ: we don't actually "compute" anything,
            // we just pass src_a through so zero_flag
            // is computed from the register value.
            // -----------------------------
            OP_BNEZ: begin
                alu_result = src_a;
            end

            // -----------------------------
            // J / JAL: ALU result unused for jump target
            // (PC comes from fetch_unit / branch_lut),
            // but keep something deterministic
            // -----------------------------
            OP_J,
            OP_JAL: begin
                alu_result = src_a;  // arbitrary but harmless
            end

            default: begin
                alu_result = '0;
            end
        endcase
    end

    // Zero flag is always derived from the result value
    assign zero_flag = (alu_result == '0);

endmodule
