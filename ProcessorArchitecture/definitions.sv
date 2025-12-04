package definitions;
    // Instruction Widths
    parameter I_WIDTH = 9;  // Instruction width
    parameter D_WIDTH = 8;  // Data width
    parameter A_WIDTH = 8;  // Address width (Data Mem)
    parameter P_WIDTH = 12; // PC width (Instruction Mem size 2^12)

    // Opcodes 
    typedef enum logic [2:0] {
        OP_R_TYPE = 3'b000, // add, sub, xor, and
        OP_LI     = 3'b001, // Load Immediate
        OP_LW     = 3'b010, // Load Word
        OP_SW     = 3'b011, // Store Word
        OP_BNEZ   = 3'b100, // Branch Not Equal Zero
        OP_SHIFT  = 3'b101, // sll, srl
        OP_J      = 3'b110, // Jump
        OP_JAL    = 3'b111  // Jump and Link
    } op_mne;

    // ALU Functions 
    parameter FUNCT_ADD = 2'b00;
    parameter FUNCT_SUB = 2'b01;
    parameter FUNCT_XOR = 2'b10;
    parameter FUNCT_AND = 2'b11;

    // Shift Functions
    parameter FUNCT_SLL = 2'b01;
    parameter FUNCT_SRL = 2'b10;

endpackage // definitions