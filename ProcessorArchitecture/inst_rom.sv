import definitions::*;

module inst_rom (
    input  logic [P_WIDTH-1:0] addr,
    output logic [I_WIDTH-1:0] instruction
);

    // Parameter so you can swap programs easily, uncomment program you want to use and comment the others out
    // parameter string ROM_FILE = "program1_machinecode.txt";
    // parameter string ROM_FILE = "program2_machinecode.txt";
    parameter string ROM_FILE = "program3_machinecode.txt";

    // Full 2^P_WIDTH-deep ROM (you can shrink if you like)
    logic [I_WIDTH-1:0] rom [0:(1<<P_WIDTH)-1];

    // Initialize from external file
    initial begin
        integer i;
        // Default everything to NOP (or 0)
        for (i = 0; i < (1<<P_WIDTH); i++) begin
            rom[i] = '0;
        end

        // Load 9-bit instructions (one per line) from file
        $readmemb(ROM_FILE, rom);
    end

    // Pure combinational read
    always_comb begin
        instruction = rom[addr];
    end

endmodule
