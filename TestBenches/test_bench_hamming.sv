// program 1-2-3    CSE141L   
module test_bench;
// connections to DUT: clock, reset, start (request), done (acknowledge) 
  bit  clk,
       reset = 'b1,				// should set your PC = 0
       start = 'b1;
// falling edge should initiate the program
  wire done;
// you return 1 when finished

  logic[ 3:0] Dist, Min, Max;
// current, min, max Hamming distances
  logic[ 4:0] Min1, Min2;
// addresses of pair w/ smallest Hamming distance
  logic[ 4:0] Max1, Max2;
// addresses of pair w/ largest Hamming distance
  logic[ 7:0] Tmp[16];
// cache of 16 8-bit values assembled from data_mem

  // 1. UPDATE: PROG_LENGTH set to 126 to match your machine code length
  top_level #(.PROG_LENGTH(115)) D1 (	        
     .clk  (clk  ),
     .reset(reset),			
     .start(start),
     .done (done )
  );

  always begin
    #50ns clk = 'b1;
	#50ns clk = 'b0;
  end

  initial begin
// load operands for program 1 into data memory
// 16 8-bit operands go into data_mem [0:15]
// mem[16,17] = min & max Hamming distances among sdata pairs
    #100ns;
    Min = 'd8;						         // start test bench Min at max value
	Max = 'd0;
    // start test bench Max at min value
    
    // 2. FIX: Point to your specific memory instance (my_data_mem) and array (core_memory)
    $readmemb("test1_2.txt", D1.my_data_mem.core_memory);
    
    for(int i=0; i<16; i++) begin
      // 3. FIX: Updated path
      Tmp[i] = {D1.my_data_mem.core_memory[i]};
      $display("%d:  %b",i,Tmp[i]);
	end
	$display();
// line-space
// DUT data memory preloads beyond [15] (next 3 lines of code)

    // 4. FIX: Updated path
    D1.my_data_mem.core_memory[16] = 'd8;
    // preset DUT final Min 
    for(int r=17; r<256; r++)
	  // 5. FIX: Updated path
	  D1.my_data_mem.core_memory[r] = 'd0;
// preset DUT final Max to min possible 
// 	compute correct answers
    for(int j=0; j<16; j++) begin
      for(int k=j+1; k<16; k++) begin
	    #1ns Dist = ham(Tmp[j],Tmp[k]);
        $display("j,kj = [%d,%d] dist=%d",j,k,Dist); 
        if(Dist<Min) begin                   // update Hamming minimum
          Min = Dist;
//   value
		  Min2 = j;							 //	  location of data pair
		  Min1 = k;
//         "
		end  
		if(Dist>Max) begin 			         // update Hamming maximum
		  Max = Dist;						 //   value
		  Max2 = j;							 //   location of data pair
		  Max1 = k;							 //			"
        end
	  end
    end   
    
    // 6. FIX: Updated paths for pre-setting memory
	//D1.my_data_mem.core_memory[16] = Min;
   // D1.my_data_mem.core_memory[17] = Max;
    
	#200ns reset = 'b0;
	#200ns start = 'b0; 
    #200ns wait (done);
// avoid false done signals on startup
								 
// check results in data_mem[64] and [65] (Minimum and Maximum distances, respectively)
// Note: Your program stores Min at 16 and Max at 17.
    
    // 7. FIX: Updated paths for verification
    if(Min == D1.my_data_mem.core_memory[16]) $display("good Min = %d",Min);
    else                      $display("fail Min: Correct = %d; Yours = %d",Min,D1.my_data_mem.core_memory[16]);
    
    $display("Min addr = %d, %d",Min1, Min2);
	$display("Min valu = %b, %b",Tmp[Min1],Tmp[Min2]);

	if(Max == D1.my_data_mem.core_memory[17]) $display("good Max = %d",Max);
    else                      $display("MAD  Max: Correct = %d; Yours = %d",Max,D1.my_data_mem.core_memory[17]);
    
    $display("Max pair = %d, %d",Max1, Max2);
	$display("Max valu = %b, %b",Tmp[Max1],Tmp[Max2]);

    #10ns reset = 1; start = 1; 
	$stop;
  end
     	
// Hamming distance (anticorrelation) between two 16-bit numbers 
  function[3:0] ham(input[15:0] a, b);
    ham = 'b0;
    for(int q=0;q<8;q++)
      if(a[q]^b[q]) ham++;
// count number of bits for which a[i] = !b[i]
  endfunction

// --- WATCHDOG TIMER ---
  // If the 'done' signal fails, this forces a check after 1ms
  initial begin
    #1ms; // Wait 10 millisecond (plenty of time for the CPU to finish)
    
    $display("\n--- WATCHDOG TIMER EXPIRED ---");
    $display("Force-checking results now...");
    
    // Check Min
    if(Min == D1.my_data_mem.core_memory[16]) 
        $display("good Min = %d", Min);
    else 
        $display("fail Min: Correct = %d; Yours = %d", Min, D1.my_data_mem.core_memory[16]);

    // Check Max
    if(Max == D1.my_data_mem.core_memory[17]) 
        $display("good Max = %d", Max);
    else 
        $display("fail Max: Correct = %d; Yours = %d", Max, D1.my_data_mem.core_memory[17]);
        
    $stop; // Force simulation to stop
  end


endmodule