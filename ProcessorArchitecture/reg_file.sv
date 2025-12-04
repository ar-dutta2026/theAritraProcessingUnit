import definitions::*;

module reg_file (
    input logic clk,
    input logic reset,
    input logic write_en,
    input logic [1:0] read_addr_1, 
    input logic [1:0] read_addr_2, 
    input logic [1:0] write_addr,  
    input logic [D_WIDTH-1:0] write_data,
    output logic [D_WIDTH-1:0] read_data_1,
    output logic [D_WIDTH-1:0] read_data_2
);

    // This fixes the "x" values in simulation.
    logic [D_WIDTH-1:0] registers [3:0] = '{default:0}; 

    // Read Logic
    assign read_data_1 = registers[read_addr_1];
    assign read_data_2 = registers[read_addr_2];

    // Write Logic
    always_ff @(posedge clk) begin
        if (reset) begin
            registers[0] <= 0;
            registers[1] <= 0;
            registers[2] <= 0;
            registers[3] <= 0;
        end else if (write_en) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule