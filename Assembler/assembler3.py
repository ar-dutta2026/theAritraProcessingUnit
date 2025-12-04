import sys
import os

# --------------------
# CSE 141L Assembler 
# --------------------

OPCODES = {
    'ADD': '000', 'SUB': '000', 'XOR': '000', 'AND': '000',
    'LI': '001', 'LW': '010', 'SW': '011',
    'BNEZ': '100', 'SLL': '101', 'SRL': '101',
    'J': '110', 'JAL': '111', 'JUMP': '110'
}

FUNCT = {
    'ADD': '00', 'SUB': '01', 'XOR': '10', 'AND': '11',
    'SLL': '01', 'SRL': '10'
}

REGISTERS = {'R0': '00', 'R1': '01', 'R2': '10', 'R3': '11'}

def to_bin(val, bits):
    val = int(val)
    if val < 0:
        val = (1 << bits) + val
    return format(val & ((1 << bits) - 1), f'0{bits}b')

def parse_line(line):
    line = line.split('//')[0].strip()
    line = line.replace(',', ' ')
    return line

def convert_fixed(inFile, outFileMachine, outFileLut, outFileDebug, lutMemFile):
    with open(inFile, 'r') as f:
        lines = f.readlines()

    machine_code = []
    debug_output = []
    lut_map = {}   # label -> LUT index
    labels  = {}   # label -> PC
    
    # ------------------------
    # Pass 1: Find Labels
    # ------------------------
    pc = 0
    lut_index = 0
    clean_lines = []
    
    for line in lines:
        cleaned = parse_line(line)
        if not cleaned:
            continue
        
        if cleaned.endswith(':'):
            label_name = cleaned[:-1]
            labels[label_name] = pc
            if label_name not in lut_map:
                lut_map[label_name] = lut_index
                lut_index += 1
            continue
            
        clean_lines.append((pc, cleaned, line.strip()))
        pc += 1

    # -------------------------------------------------------------------------
    # Pass 2: Generate Machine Code
    # -------------------------------------------------------------------------
    for pc, parts_str, original_line in clean_lines:
        parts = parts_str.split()
        op = parts[0].upper()
        
        try:
            if op not in OPCODES:
                print(f"ERROR [PC {pc}]: Unknown Opcode {op}")
                continue

            bin_instr = ""

            # --- R-TYPE (STRICT 2-ARG CHECK) ---
            if op in ['ADD', 'SUB', 'XOR', 'AND']:
                if len(parts) > 3:
                    raise ValueError(
                        f"Too many arguments for {op}! "
                        f"Your hardware only supports 2 (e.g., '{op} R1, R2'). "
                        f"You wrote: '{original_line}'"
                    )
                
                rd = REGISTERS[parts[1].upper()]
                rs = REGISTERS[parts[2].upper()]
                bin_instr = f"{OPCODES[op]}{FUNCT[op]}{rd}{rs}"

            # --- I-TYPE ---
            elif op == 'LI':
                rd = REGISTERS[parts[1].upper()]
                imm = parts[2]
                bin_instr = f"{OPCODES[op]}{rd}{to_bin(imm, 4)}"

            # --- MEMORY ---
            elif op in ['LW', 'SW']:
                rt = REGISTERS[parts[1].upper()]
                if '(' in parts[2]:
                    offset_str, rs_str = parts[2].split('(')
                    rs = REGISTERS[rs_str.strip(')').upper()]
                    offset = int(offset_str)
                else:
                    rs = REGISTERS[parts[2].upper()]
                    offset = int(parts[3])
                
                if offset > 3 or offset < 0:
                    print(f"ERROR [PC {pc}]: Offset {offset} too large for 2 bits (Max 3)")
                
                bin_instr = f"{OPCODES[op]}{rt}{rs}{to_bin(offset, 2)}"

            # --- BRANCH ---
            elif op == 'BNEZ':
                rs = REGISTERS[parts[1].upper()]
                target = parts[2]
                offset = (labels[target] - pc) if target in labels else int(target)
                bin_instr = f"{OPCODES[op]}{rs}{to_bin(offset, 4)}"

            # --- SHIFT ---
            elif op in ['SLL', 'SRL']:
                rd = REGISTERS[parts[1].upper()]
                rs = REGISTERS[parts[2].upper()] if len(parts) > 2 else rd
                bin_instr = f"{OPCODES[op]}{FUNCT[op]}{rd}{rs}"

            # --- JUMP / JAL / JUMP (via LUT index) ---
            elif op in ['J', 'JAL', 'JUMP']:
                target = parts[1]
                idx = lut_map[target] if target in lut_map else int(target)
                op_code = OPCODES[op]
                bin_instr = f"{op_code}{to_bin(idx, 6)}"

            machine_code.append(bin_instr)
            debug_output.append(f"12'd{pc}: instruction = 9'b{bin_instr}; // {original_line}")

        except Exception as e:
            print(f"CRITICAL ERROR at PC {pc}: {e}")
            return  # Stop processing on error

    # ------------------------------------------
    # Write machine code and debug ROM listing
    # -----------------------------------------
    with open(outFileMachine, 'w') as f:
        f.write('\n'.join(machine_code))

    with open(outFileDebug, 'w') as f:
        f.write('\n'.join(debug_output))

    # ------------------------------------------------------------------
    # Write LUT as a .mem file (binary PCs for $readmemb in fetch_unit)
    # ------------------------------------------------------------------
    if lut_map:
        max_idx = max(lut_map.values())
    else:
        max_idx = -1

    with open(outFileLut, 'w') as f:
        for idx in range(max_idx + 1):
            # Find the label for this LUT index
            label_for_idx = None
            for label, lut_idx in lut_map.items():
                if lut_idx == idx:
                    label_for_idx = label
                    break

            if label_for_idx is None:
                # Shouldn't happen if lut_map is contiguous 0..max_idx
                pc_val = 0
            else:
                pc_val = labels[label_for_idx]

            # Write 12-bit binary PC (matches P_WIDTH=12)
            f.write(to_bin(pc_val, 12) + '\n')

    # -----------------------------------------------------
    # Write fetch_lut.sv-style initial block for debugging
    # -----------------------------------------------------
    with open(lutMemFile, 'w') as f:
        f.write("// Paste into fetch_unit.sv if you want hard-coded LUT\n")
        f.write("initial begin\n")
        for label, idx in lut_map.items():
            f.write(f"    branch_lut[{idx}] = {labels[label]}; // {label}\n")
        f.write("end\n")

    print(f"-> Done. Generated {len(machine_code)} instructions.")

if __name__ == "__main__":

    # Uncomment out the program you want to generate and comment out the rest

    # convert_fixed( "program1_assembly.txt", "program1_machinecode.txt", "lut_p1.mem",  "rom_content_1.sv","fetch_lut_1.sv")

    # convert_fixed( "program2_assembly.txt", "program2_machinecode.txt", "lut_p2.mem",  "rom_content_2.sv","fetch_lut_2.sv")

    convert_fixed( "program3_assembly.txt", "program3_machinecode.txt", "lut_p3.mem",  "rom_content_3.sv","fetch_lut_3.sv")

