
# RV32I RISC-V CPU — Verilog RTL on FPGA

A 32-bit RISC-V single-cycle CPU implemented in synthesizable Verilog, developed from individual hardware modules and integrated through simulation-driven verification.

**Repository:** [AGSilicon/RISCV_FPGA](https://github.com/AGSilicon/RISCV_FPGA)

## Project Overview

This project implements a 32-bit RISC-V processor with a single-cycle datapath, control logic, memory interface, machine-mode CSR support, and synchronous exception handling.

The development approach is modular:
- Design individual RTL modules.
- Verify modules using dedicated Verilog testbenches.
- Integrate the modules into the CPU.
- Validate instruction execution and exception handling through simulation.

## Architecture

The CPU consists of:

- Program Counter (PC)
- Instruction Memory
- Control Unit
- Register File (32 × 32-bit)
- Immediate Generator
- Arithmetic Logic Unit (ALU)
- Data Memory
- CSR File
- CSR Instruction Unit
- System Instruction Unit
- Trap Controller

## Implemented Features

### Base CPU and instruction support

- Integer arithmetic and logical operations
- Shift operations
- Immediate arithmetic and logical operations
- Conditional branches
- JAL and JALR
- Load and store operations
- LUI and AUIPC

### Machine-mode system support

- Machine CSR registers: `mstatus`, `mtvec`, `mepc`, `mcause`, `mtval`
- CSR instructions: CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
- ECALL, EBREAK and MRET
- Base FENCE instruction

### Exception handling

- Instruction address misaligned
- Instruction access fault
- Illegal instruction
- Breakpoint
- Environment call from machine mode
- Load address misaligned
- Load access fault
- Store address misaligned
- Store access fault

The implementation currently focuses on synchronous machine-mode exceptions. Interrupt handling, privilege transitions beyond machine mode, and other advanced RISC-V extensions are not yet implemented.

## Repository Structure

```text
RISCV_FPGA/
├── rtl/          # Synthesizable Verilog modules
├── tb/           # Verilog testbenches
├── programs/     # HEX test programs
├── sim/          # Simulation output (generated files ignored)
├── wave/         # Waveform output (generated files ignored)
├── reports/      # Verification and design reports
├── README.md
└── .gitignore
```

## Tools and Environment

- Verilog HDL
- Icarus Verilog
- GTKWave
- Ubuntu 22.04 / WSL
- Xilinx ISE 14.7 for FPGA implementation workflow
- Target FPGA board: Digilent Nexys 2 (Spartan-3E XC3S500E)

## Simulation

Install Icarus Verilog and GTKWave.

From the project root, compile the CPU testbench:

```bash
iverilog -g2005 -Wall -o sim/cpu_test \
rtl/program_counter.v \
rtl/alu.v \
rtl/register_file.v \
rtl/immediate_generator.v \
rtl/control_unit.v \
rtl/instruction_memory.v \
rtl/data_memory.v \
rtl/csr_file.v \
rtl/csr_instruction_unit.v \
rtl/system_instruction_unit.v \
rtl/trap_controller.v \
rtl/riscv_cpu.v \
tb/tb_riscv_cpu.v
```

Run:

```bash
vvp sim/cpu_test
```

Individual testbenches are available in the `tb/` directory. Test programs are stored in `programs/`.

Run simulation commands from the repository root so that HEX file paths resolve correctly.

## Verification

The project has been verified through individual module-level and integrated CPU testbenches.

Reported test coverage includes:

- ALU and register-file operations
- Immediate generation and instruction decoding
- Branch and jump execution
- Load/store operations
- CSR instruction execution
- ECALL, EBREAK and illegal-instruction traps
- Misaligned load and store exceptions

The latest reported load-misaligned CPU test passes **8/8 checks**, including verification that the faulting load does not modify its destination register.

See the testbenches in `tb/` and HEX programs in `programs/` for the test cases. Individual test results are not a substitute for a fresh full-regression run.

## FPGA Implementation

The intended target board is the Digilent Nexys 2 with a Xilinx Spartan-3E XC3S500E FPGA.

The current milestone focuses on RTL development and simulation verification. FPGA pin constraints, synthesis, timing analysis, and on-board validation are separate implementation steps.

## Development Status

**Current milestone:** Single-cycle CPU RTL with machine-mode CSR and synchronous exception handling.

Planned future work:

- Full regression automation
- FPGA synthesis and implementation
- Nexys 2 pin constraints and clock/reset integration
- On-board instruction execution demo
- Additional verification and timing analysis

## Author

**AGSilicon**

GitHub: https://github.com/AGSilicon
