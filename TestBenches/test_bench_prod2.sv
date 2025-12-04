// program 2    CSE141L   product C = OpA * OpB  
// operands are 8-bit two's comp integers, product is 16-bit two's comp integer
// revised 2025.11.12 to resolve big/little endian question -- now conforms to the assignment writeup
//   revision also adds reset port and connection to the DUT, again to conform to the assignment writeup
module test_bench;

// connections to DUT: clk (clock), reset, start (request), done (acknowledge) 
  bit  clk,
       reset = 'b1,              // should set your PC = 0
       start = 'b1;              // falling edge should initiate the program
  wire done;                     // you return 1 when finished

  logic signed [7:0]  OpA, OpB;
  logic signed [15:0] Prod;      // holds 2-byte product

  // *** Set this to the LAST PC index for Program 2 (from your assembler) ***
  localparam int PROG2_LENGTH = 119;  // <-- FILL IN (e.g., 130)

  // Your DUT
  top_level #(.PROG_LENGTH(PROG2_LENGTH)) D1 (
      .clk  (clk),
      .reset(reset),
      .start(start),
      .done (done)
  );

  // clock
  always begin
    #50ns clk = 'b1;
    #50ns clk = 'b0;
  end

  initial begin
    #100ns;

    // generate operands (you can later wrap this in a for-loop over many cases)
    OpA =  2;          
    OpB = -4;

    // load values into data memory
    D1.my_data_mem.core_memory[0] = OpA;
    D1.my_data_mem.core_memory[1] = OpB;

    #10ns $display("%0d, %0d", OpA, OpB);

    // compute golden product in testbench
    #10ns Prod = OpA * OpB;

    // release reset/start to let DUT run
    #10ns reset = 'b0;
    #10ns start = 'b0;

    // avoid false done signals on startup
    #200ns wait (done);

    // Check: DUT must store low byte at mem[2], high byte at mem[3]
    if ({D1.my_data_mem.core_memory[3],
         D1.my_data_mem.core_memory[2]} == Prod)
      $display("Yes! %0d * %0d = %0d", OpA, OpB, Prod);
    else
      $display("Boo! %0d * %0d should = %0d", OpA, OpB, Prod);

    // re-assert start/reset and stop sim
    #20ns start = 'b1;
    #10ns reset = 'b1;
    $stop;
  end

endmodule
