# Design of a Processor based on Harvard Architecture

## Project Description
This repository contains the RTL design and implementation of a custom 16-bit multi-cycle microprocessor built entirely in Verilog HDL. Based on the Harvard architecture, the processor features physically separate program and data memories to optimize instruction execution and data handling without bus contention. 

At the core of the design is a custom 6-state Finite State Machine (FSM) control unit that orchestrates the fetch-decode-execute cycle across 32 general-purpose registers. The processor executes a custom 32-bit Instruction Set Architecture (ISA) containing over 25 instructions, including arithmetic operations, bitwise logic, and dynamic jump instructions triggered by hardware-level ALU status flags (Sign, Zero, Carry, Overflow). 

The processor's logic was rigorously verified using Xilinx Vivado. Testbenches were designed to execute custom assembly software routines—such as calculating multiplication through repeated addition loops—proving accurate cycle timing, branching resolution, and external I/O data routing.

---

## Core Specifications

| Component | Specification |
| :--- | :--- |
| **Architecture** | Harvard (Separate 32-bit Instruction and 16-bit Data Memory) |
| **Datapath** | 16-bit |
| **Instruction Format**| 32-bit Fixed Length |
| **Registers** | 32 General Purpose Registers (16-bit) + 1 Special Register (32-bit MSB) |
| **Control Unit** | 6-State FSM (`idle`, `fetch_inst`, `decode_execute`, `delay`, `next`, `halt`) |

---

## Instruction Set Architecture (ISA)

The processor uses a 32-bit fixed-length instruction format. The bits are allocated as follows:

| Bit Range | Field Name | Description |
| :--- | :--- | :--- |
| **31:27** | Opcode | 5-bit operation code (allows up to 32 unique operations). |
| **26:22** | Destination Reg | 5-bit address for the destination General Purpose Register. |
| **21:17** | Source Reg 1 | 5-bit address for the primary operand register. |
| **16** | Mode Selection | 1-bit toggle: `0` for Register Mode, `1` for Immediate Mode. |
| **15:11** | Source Reg 2 | 5-bit address for the secondary operand register (used if Mode = 0). |
| **15:0** | Immediate Data | 16-bit constant data (used if Mode = 1). |

### Supported Instructions

| Category | Opcode (Binary) | Assembly Example | Description |
| :--- | :--- | :--- | :--- |
| **Arithmetic** | `00000` | `MOVSGPR R1` | Move MSB of multiplication result (from SGPR) to R1. |
| | `00001` | `MOV R1, #10` | Load immediate or register value into R1. |
| | `00010` | `ADD R1, R2, R3` | Add R2 and R3; store in R1. |
| | `00011` | `SUB R1, R2, #5` | Subtract 5 from R2; store in R1. |
| | `00100` | `MUL R1, R2, R3` | Multiply R2 and R3; Lower 16-bits in R1, Upper in SGPR. |
| **Logical** | `00101` | `AND R1, R2, R3` | Bitwise AND (Opcode defined as `rand`). |
| | `00110` - `01011` | `OR`, `XOR`, `XNOR`, etc. | Standard bitwise operations. |
| **Memory & I/O** | `01100` | `STOREREG R1, DM[2]` | Store R1 into Data Memory at index 2. |
| | `01101` | `STOREDIN DM[3]` | Read external `din` port directly into Data Memory. |
| | `01110` | `SENDDOUT DM[2]` | Send Data Memory value to external `dout` port. |
| | `01111` | `SENDREG R1, DM[2]` | Load data from Data Memory into R1. |
| **Branching** | `10000` | `JUMP #20` | Unconditional jump to PC address 20. |
| | `10001` - `11000` | `JZERO`, `JNOZERO`, etc.| Conditional jumps based on ALU flags. |
| **System** | `11001` | `HALT` | Stop execution and wait for reset. |

---

## ALU Condition Flags

The Arithmetic Logic Unit (ALU) automatically evaluates operations and sets the following status flags to enable conditional branching:

| Flag | Symbol | Condition |
| :--- | :---: | :--- |
| **Sign** | S | Evaluates to `1` if the MSB of the result is 1 (Negative). |
| **Zero** | Z | Evaluates to `1` if the entire result evaluates to exactly 0. |
| **Carry** | C | Evaluates to `1` if an addition operation produces a carry-out. |
| **Overflow** | OV | Evaluates to `1` if a signed arithmetic overflow occurs. |

---

## Simulation and Verification

The design was synthesized and simulated using Xilinx Vivado. Custom assembly programs were written and loaded into the instruction memory via the `$readmemb` system task to verify RTL logic across multiple clock cycles. 

**Test Case: Multiplication via Repeated Addition & I/O Handling**
A custom software routine was written to calculate `2 x 3 = 6` using a `do-while` loop utilizing the `SUB` and `JNOZERO` instructions. A secondary hardware multiplication test successfully calculated `din * 10 = dout`.

![Simulation Waveform](img/image_5218a0.png)
*Waveform showing multi-cycle execution: the processor successfully outputs `0006` (hex) for the repeated addition, reads external input `din` (`000C`), and outputs the hardware multiplication result `0078`.*

---

## Repository Structure

*   `src/`: Contains the Verilog source code (`top.v`).
*   `mem/`: Contains the `.mem` files used for initializing the instruction block RAM.
*   `img/`: Contains architecture diagrams and Vivado simulation waveforms.

## How to Run

1. Clone this repository.
2. Open a new project in Xilinx Vivado (or your preferred EDA tool).
3. Import the Verilog files from the `src/` directory.
4. Ensure the `.mem` file paths in the `initial` block of `top.v` point to the correct absolute or relative path on your local machine.
5. Run the behavioral simulation to view the cycle-accurate waveforms.
