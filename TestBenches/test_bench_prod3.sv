// program 3    CSE141L   product D = OpA * OpB * OpC  
// operands are 8-bit two's comp integers, product is 24-bit two's comp integer
// D is stored little-endian in data memory as:
//   mem[3] = low  byte
//   mem[4] = mid  byte
//   mem[5] = high byte
module test_bench;

// connections to DUT: clk (clock), reset, start (request), done (acknowledge) 
  bit  clk,
       reset = 'b1,              // should set your PC = 0
       start = 'b1;              // falling edge should initiate the program
  wire done;                     // you return 1 when finished

  logic signed [7:0]  OpA, OpB, OpC;
  logic signed [23:0] Prod;      // 24-bit product

  // pc + 1 (done flag)
  localparam int PROG3_LENGTH = 192;   

  // Your DUT
  top_level #(.PROG_LENGTH(PROG3_LENGTH)) D1 (
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

    // ---- SINGLE TEST CASE (you can wrap this in loops later) ----
    OpA =  -63;        
    OpB = -44;
    OpC =  -62;

    // load values into data memory
    D1.my_data_mem.core_memory[0] = OpA;
    D1.my_data_mem.core_memory[1] = OpB;
    D1.my_data_mem.core_memory[2] = OpC;

    #10ns $display("Operands: %0d, %0d, %0d", OpA, OpB, OpC);

    // compute golden product in testbench
    #10ns Prod = OpA * OpB * OpC;

    // release reset/start to let DUT run
    #10ns reset = 1'b0;
    #10ns start = 1'b0;

    // avoid false done signals on startup
    #200ns wait (done);

   // $display("mem[3..11] at DONE:");
   // $display("mem[3]=%0d mem[4]=%0d mem[5]=%0d", 
          //    D1.my_data_mem.core_memory[3],
           //   D1.my_data_mem.core_memory[4],
           //   D1.my_data_mem.core_memory[5]);
 //   $display("A_count(mem[8])=%0d B_base(mem[9])=%0d C_base(mem[10])=%0d B_count(mem[11])=%0d",
            //  D1.my_data_mem.core_memory[8],
            //  D1.my_data_mem.core_memory[9],
            //  D1.my_data_mem.core_memory[10],
            //  D1.my_data_mem.core_memory[11]);

    // Check: DUT must store bytes at mem[3], [4], [5]
    if ({D1.my_data_mem.core_memory[5],
         D1.my_data_mem.core_memory[4],
         D1.my_data_mem.core_memory[3]} == Prod)
      $display("Yes! %0d * %0d * %0d = %0d",
               OpA, OpB, OpC, Prod);
    else
      $display("Boo! %0d * %0d * %0d should = %0d, got 0x%h%h%h",
               OpA, OpB, OpC, Prod,
               D1.my_data_mem.core_memory[5],
               D1.my_data_mem.core_memory[4],
               D1.my_data_mem.core_memory[3]);

    // re-assert start/reset and stop sim
    #20ns start = 1'b1;
    #10ns reset = 1'b1;
    $stop;
  end

endmodule
