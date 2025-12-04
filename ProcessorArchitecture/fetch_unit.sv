import definitions::*;

module fetch_unit (
    input  logic clk, 
    input  logic reset,
    input  logic start,
    input  logic branch_taken,
    input  logic jump_taken,
    input  logic [3:0] branch_imm,
    input  logic [5:0] jump_target,
    output logic [P_WIDTH-1:0] pc_out
);
    logic [P_WIDTH-1:0] pc_next;

    // 64-entry branch LUT
    logic [P_WIDTH-1:0] branch_lut [0:63];

    // Parameter: LUT file name (Uncomment the program you want to run and comment out the others)
    // parameter LUT_FILE = "lut_p1.mem";
    // parameter LUT_FILE = "lut_p2.mem";
    parameter LUT_FILE = "lut_p3.mem";


    // Load LUT from file
    initial begin
        integer i;
        // Default all entries to 0
        for (i = 0; i < 64; i++) begin
            branch_lut[i] = '0;
        end

        $readmemb(LUT_FILE, branch_lut);
    end

    always_ff @(posedge clk) begin
        if (reset)       pc_out <= '0;
        else if (!start) pc_out <= pc_next;
    end

    always_comb begin
        pc_next = pc_out + 1;
        if (jump_taken)
            pc_next = branch_lut[jump_target];
        else if (branch_taken)
            pc_next = pc_out + {{(P_WIDTH-4){branch_imm[3]}}, branch_imm};
    end

endmodule
