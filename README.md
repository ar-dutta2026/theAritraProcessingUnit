# theAritraProcessingUnit (tAPU)

**The Aritra Processing Unit (tAPU)** is a custom, lightweight soft-core processor designed for the **Intel Arria II GX FPGA** family. It features a complete hardware-software co-design workflow, including a custom SystemVerilog architecture, a Python-based assembler, and a suite of pre-installed programs for complex arithmetic and logic operations.

## 🏗 Hardware Architecture

The tAPU is a Harvard-style RISC processor built with modular SystemVerilog components. It is designed to be synthesized on **Quartus Prime** and simulated using **QuestaSim**.

### Core Specifications

| Feature | Specification | Description |
| :--- | :--- | :--- |
| **Instruction Width** | 9-bit | Highly compact instruction set. |
| **Data Width** | 8-bit | Native byte-level processing. |
| **Address Space** | 12-bit PC | Supports instruction memory up to 4096 lines. |
| **Registers** | 4 (R0–R3) | [cite_start]General Purpose Registers[cite: 1, 2]. |
| **Branching** | LUT-Based | Uses a 64-entry Look-Up Table for long jumps. |

### Instruction Set Architecture (ISA)
The processor supports a focused set of instructions defined in `definitions.sv`.

| Opcode | Mnemonic | Type | Function |
| :--- | :--- | :--- | :--- |
| `000` | **ADD** | R-Type | `Rd = Rs + Rt` |
| `000` | **SUB** | R-Type | `Rd = Rs - Rt` |
| `000` | **XOR** | R-Type | `Rd = Rs ^ Rt` |
| `000` | **AND** | R-Type | `Rd = Rs & Rt` |
| `001` | **LI** | I-Type | `Rd = Immediate` (4-bit imm) |
| `010` | **LW** | Mem | `Rd = Mem[Base + Offset]` |
| `011` | **SW** | Mem | `Mem[Base + Offset] = Rs` |
| `100` | **BNEZ** | Branch | Branch to label if `Rs != 0` |
| `101` | **SLL** | Shift | `Rd = Rs << 1` (Logical Left) |
| `101` | **SRL** | Shift | `Rd = Rs >> 1` (Logical Right) |
| `110` | **J / JUMP**| Jump | Unconditional Jump (Uses LUT) |
| `111` | **JAL** | Jump | Jump and Link (Stores return addr) |

### Key Components
1.  **Register File (`reg_file.sv`):** Contains 4 general-purpose registers (`R0` through `R3`).
2.  **Fetch Unit (`fetch_unit.sv`):** Manages the Program Counter. Because the instruction width (9 bits) is too small to encode full 12-bit jump addresses, the Fetch Unit utilizes a **Look-Up Table (LUT)** to map 6-bit jump targets to 12-bit physical addresses.
3.  **ALU (`alu.sv`):** Handles arithmetic, logic, and shift operations. It generates flags (Zero, Carry, Overflow) stored in `flag_reg.sv`.
4.  **Data Memory (`data_mem.sv`):** A 256-byte RAM for data storage.

---

## 🛠️ Software Toolchain: The Assembler

Located in the `Assembler/` directory, the `assembler.py` script serves as the bridge between human-readable assembly and the hardware.

* **Function:** Parses `.txt` assembly files, validates instruction syntax, and checks immediate value limits.
* **LUT Generation:** Automatically identifies labels used in `JUMP` instructions and generates the necessary Look-Up Table entries.
* **Output:** Generates two essential files for the hardware:
    1.  `programX_machinecode.txt` → Loaded into `inst_rom.sv`.
    2.  `lut_pX.mem` → Loaded into `fetch_unit.sv`.

---

## 🚀 Simulation & Synthesis Guide

### 1. Compilation Order (Crucial)
You **must** compile the definitions file before any other hardware files, as it defines the widths and opcodes used throughout the system.
1.  `definitions.sv`
2.  All hardware files (`alu.sv`, `reg_file.sv`, `top_level.sv`, etc.)
3.  `test_bench.sv`

### 2. Running Simulation (QuestaSim)
To run a specific program (e.g., Program 3):
1.  **Load Files:** Ensure `inst_rom.sv` points to `program3_machinecode.txt` and `fetch_unit.sv` points to `lut_p3.mem`.
2.  **Launch QuestaSim:** Load `work.test_bench`.
3.  **Suppress Error 7061:** The testbench reads memory directly to verify results. Questa flags this as a violation by default. To bypass this, run:
    ```tcl
    vsim -suppress 7061 work.test_bench
    ```
4.  **Run:**
    ```tcl
    run -all
    ```

### 3. Synthesis (Quartus Prime)
To synthesize the design for the FPGA:
1.  **Select Device:** Set the device family to **Intel Arria II GX**.
2.  **Select Program:** Open `inst_rom.sv` and `fetch_unit.sv`.
    * **Uncomment** the lines for the program you wish to run (e.g., `program3_machinecode.txt` and `lut_p3.mem`).
    * **Comment out** the other programs.
3.  **Synthesize:** Run **Analysis & Synthesis** from the Quartus toolbar.

---

## 💾 Example Programs

The processor includes three pre-verified programs demonstrating its capabilities.

### Program 1: Hamming Distance
**Goal:** Calculate the number of differing bits between two byte-arrays.
* **Logic:**
    1.  Iterates through two arrays stored in memory.
    2.  Loads two bytes and performs an **XOR** (`^`) operation. This sets bits to `1` only where the input bits differ.
    3.  **Popcount Loop:** To count the 1s, it uses a loop that checks the LSB (Least Significant Bit), adds it to a counter, and right-shifts the data until it equals zero.
    4.  Updates memory with the minimum and maximum Hamming distances found.

### Program 2: Multiply A * B (Signed)
**Goal:** Multiply two 8-bit signed numbers to produce a 16-bit signed result.
* **Logic:**
    1.  **Sign Extraction:** Determines the final sign of the result by XORing the sign bits of A and B.
    2.  **Absolute Value:** Converts both A and B to positive magnitudes using conditional logic (Two's Complement).
    3.  **Shift-and-Add:** Implements multiplication using a standard software algorithm:
        * Iterates through the bits of the multiplier.
        * If the bit is 1, adds the multiplicand to the product.
        * Shifts multiplicand left and multiplier right.
    4.  **Sign Correction:** If the calculated sign was negative, converts the final 16-bit product back to a negative value.

### Program 3: Multiply A * B * C (24-bit Output)
**Goal:** Compute the product of three 8-bit signed numbers, resulting in a 24-bit signed answer (stored across 3 bytes).
* **Logic:**
    1.  **Initialization:** Clears a 24-bit accumulator in memory (Low, Mid, High bytes).
    2.  **Pre-processing:** Extracts the sign (`SignA ^ SignB ^ SignC`) and converts all inputs (A, B, C) to absolute values.
    3.  **Triple Nested Loop:**
        * Uses a counting approach to handle the high-precision result.
        * **Loop A** runs `|A|` times.
        * **Loop B** runs `|B|` times.
        * **Loop C** runs `|C|` times.
        * **Inner Body:** Increments the 24-bit result by 1. Handles carry propagation from Low Byte → Mid Byte → High Byte manually in software.
    4.  **Finalize:** Applies the sign to the 24-bit result (Two's Complement negation across 3 bytes) if necessary.
