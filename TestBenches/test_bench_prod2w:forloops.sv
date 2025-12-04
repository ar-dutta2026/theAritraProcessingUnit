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
  localparam int PROG2_LENGTH = 119;

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

    // Sweep OpA, OpB from -64 to +63
    for (int a = -64; a < 64; a++) begin
      for (int b = -64; b < 64; b++) begin

        // 1) Put core into a known idle/reset state
        reset = 1'b1;
        start = 1'b1;
        @(posedge clk);  // let PC sample reset=1

        // 2) Set operands
        OpA = a;
        OpB = b;

        D1.my_data_mem.core_memory[0] = OpA;
        D1.my_data_mem.core_memory[1] = OpB;

        $display("%0d, %0d", OpA, OpB);

        // Golden product
        Prod = OpA * OpB;

        // 3) Start program: falling edge of start while reset deasserts
        @(negedge clk);
        reset = 1'b0;
        start = 1'b0;

        // 4) Wait for this run to finish
        @(posedge done);

        // 5) Check: DUT must store low byte at mem[2], high byte at mem[3]
        if ({D1.my_data_mem.core_memory[3],
             D1.my_data_mem.core_memory[2]} == Prod) begin
          $display("Yes! %0d * %0d = %0d", OpA, OpB, Prod);
        end else begin
          $display("Boo! %0d * %0d should = %0d", OpA, OpB, Prod);
          $display("     DUT gave: %0d (0x%h)",
                   $signed({D1.my_data_mem.core_memory[3],
                            D1.my_data_mem.core_memory[2]}),
                   {D1.my_data_mem.core_memory[3],
                    D1.my_data_mem.core_memory[2]});
          $stop;  // stop on first failure
        end

        // 6) Re-assert reset/start to cleanly finish this run and
        //    force done low before the next pair.
        @(negedge clk);
        start = 1'b1;
        reset = 1'b1;

        // Wait for done to deassert so next @(posedge done) isn't satisfied immediately
        if (done) @(negedge done);

      end
    end

    $display("\n*** ALL TESTS PASSED (-64..63) ***");
    $stop;
  end

endmodule
