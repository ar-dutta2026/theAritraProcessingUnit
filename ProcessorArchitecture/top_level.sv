import definitions::*;

module top_level #(parameter PROG_LENGTH = 0) (
    input logic clk,
    input logic reset,
    input logic start,
    output logic done // Ack signal
);

    // Wires
    logic [P_WIDTH-1:0] pc;
    logic [I_WIDTH-1:0] instr;
    
    // Control Signals
    logic reg_write, alu_src_imm, mem_write, mem_to_reg, branch, is_jal, jump, update_flags;
    
    // Decoded Instruction Parts
    logic [2:0] opcode;
    logic [1:0] funct;
    logic [1:0] rd_rs1;  
    logic [1:0] rs2_rt;  
    logic [1:0] rs_b;    
    logic [3:0] imm4;    
    logic [5:0] jump_target; 
    
    // Data Wires
    logic [D_WIDTH-1:0] reg_rdata_1, reg_rdata_2;
    logic [D_WIDTH-1:0] alu_in_b;
    logic [D_WIDTH-1:0] alu_result;
    logic [D_WIDTH-1:0] mem_rdata;
    logic [D_WIDTH-1:0] wb_data; 
    
    // Flag Wires
    logic zero_flag, carry_out, overflow_flag;
    logic saved_c, saved_v, saved_z;
    logic branch_taken;
    
    // Address Muxing Wires
    logic [1:0] reg_read_addr_1;
    logic [1:0] reg_read_addr_2;
    logic [1:0] reg_write_addr;

    // --- Bit Slicing ---
    assign opcode      = instr[8:6];
    assign funct       = instr[5:4]; 
    assign rs_b        = instr[5:4]; 
    assign rd_rs1      = instr[3:2]; 
    assign rs2_rt      = instr[1:0]; 
    assign imm4        = instr[3:0]; 
    assign jump_target = instr[5:0]; 

    // --- Instantiations ---

    fetch_unit my_fetch (
        .clk(clk),
        .reset(reset),
        .start(start),
        .branch_taken(branch_taken),
        .jump_taken(jump),
        .branch_imm(imm4),
        .jump_target(jump_target),
        .pc_out(pc)
    );

    inst_rom my_rom (
        .addr(pc),
        .instruction(instr)
    );

    control_decoder my_control (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src_imm(alu_src_imm),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .is_jal(is_jal),
        .jump(jump),
        .update_flags(update_flags)
    );

    // --- Muxing Logic ---
    
    // Read Address 1 Mux
    always_comb begin
        if (opcode == OP_SHIFT) reg_read_addr_1 = rs2_rt; 
        else if (opcode == OP_BNEZ) reg_read_addr_1 = rs_b;   
        else if (opcode == OP_LW || opcode == OP_SW) reg_read_addr_1 = rd_rs1; 
        else reg_read_addr_1 = rd_rs1; 
    end

    // Read Address 2 Mux
    assign reg_read_addr_2 = (opcode == OP_SW) ? rs_b : rs2_rt; 

    // Write Address Mux
    always_comb begin
        if (is_jal) reg_write_addr = 2'b11; 
        else if (opcode == OP_LI || opcode == OP_LW) reg_write_addr = rs_b;  
        else reg_write_addr = rd_rs1; 
    end

    reg_file my_regfile (
        .clk(clk),
        .write_en(reg_write),
	.reset(reset), 
        .read_addr_1(reg_read_addr_1),
        .read_addr_2(reg_read_addr_2),
        .write_addr(reg_write_addr),
        .write_data(wb_data),
        .read_data_1(reg_rdata_1),
        .read_data_2(reg_rdata_2)
    );

    // ALU Src Mux
    logic [7:0] imm_val;
    always_comb begin
        if (opcode == OP_LW || opcode == OP_SW) imm_val = {6'b000000, rs2_rt}; 
        else imm_val = {4'b0000, imm4};     
    end
    assign alu_in_b = (alu_src_imm) ? imm_val : reg_rdata_2;

    alu my_alu (
        .src_a(reg_rdata_1),
        .src_b(alu_in_b),
        .opcode(opcode),
        .funct(funct),
        .alu_result(alu_result),
        .zero_flag(zero_flag),
        .carry_out(carry_out),
        .overflow_flag(overflow_flag)
    );

    flag_reg my_flags (
        .clk(clk),
        .reset(reset),
        .update_flags(update_flags),
        .c_in(carry_out),
        .v_in(overflow_flag),
        .z_in(zero_flag),
        .c_out(saved_c),
        .v_out(saved_v),
        .z_out(saved_z)
    );

    // Branch Logic: Check if Zero Flag is LOW
    assign branch_taken = branch && !zero_flag;

    data_mem my_data_mem (
        .clk(clk),
        .mem_write(mem_write),
        .addr(alu_result), 
        .write_data(reg_rdata_2), 
        .read_data(mem_rdata)
    );

    // Write Back Mux
    always_comb begin
        if (is_jal) wb_data = pc + 1; 
        else if (mem_to_reg) wb_data = mem_rdata;
        else wb_data = alu_result;
    end
    
    // ----------------------------------------------------------------
    // DONE / HALT LOGIC
    // ----------------------------------------------------------------
    
    localparam logic [P_WIDTH-1:0] HALT_PC = PROG_LENGTH - 1;

    // Assert 'done' whenever we reach the HALT_PC
    assign done = (pc == HALT_PC);



// --- DEBUGGING BLOCK ---
   // always @(posedge clk) begin
      //  if (!reset && !start) begin
        //    $display("Time:%0t | PC:%d | Instr:%b | R0:%d R1:%d R2:%d R3:%d", 
               //      $time, pc, instr, 
                  //   my_regfile.registers[0], 
                  //   my_regfile.registers[1], 
                  //   my_regfile.registers[2], 
                  //  my_regfile.registers[3]);
      //  end
   // end
endmodule