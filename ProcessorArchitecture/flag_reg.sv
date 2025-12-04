import definitions::*;

module flag_reg (
    input logic clk,
    input logic reset,
    input logic update_flags, // Only update on Math/Shift ops
    input logic c_in,         // Carry from ALU
    input logic v_in,         // Overflow from ALU
    input logic z_in,         // Zero from ALU
    output logic c_out,       // Saved Carry
    output logic v_out,       // Saved Overflow
    output logic z_out        // Saved Zero
);

    always_ff @(posedge clk) begin
        if (reset) begin
            c_out <= 0;
            v_out <= 0;
            z_out <= 0;
        end else if (update_flags) begin
            c_out <= c_in;
            v_out <= v_in;
            z_out <= z_in;
        end
    end

endmodule