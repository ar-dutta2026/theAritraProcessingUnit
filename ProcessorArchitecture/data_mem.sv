import definitions::*;

module data_mem (
    input  logic              clk,
    input  logic              mem_write,
    input  logic [7:0]        addr,
    input  logic [D_WIDTH-1:0] write_data,
    output logic [D_WIDTH-1:0] read_data
);

    // 256 x 8-bit memory
    logic [D_WIDTH-1:0] core_memory [255:0];

    // async read 
    assign read_data = core_memory[addr];

    // sync write
    always_ff @(posedge clk) begin
        if (mem_write)
            core_memory[addr] <= write_data;
    end

endmodule
