`timescale 1ns/1ps


module tb_riscv_cpu;

reg clk;
reg reset;

wire [31:0] pc_debug;
wire [31:0] instruction_debug;
wire instruction_valid_debug;
wire illegal_instruction;

integer passed;
integer failed;

// Instantiate complete RISC-V CPU
riscv_cpu #(
.IMEM_DEPTH(64),
.DMEM_DEPTH(256),
.PROGRAM_WORDS(9),
.PROGRAM_FILE("programs/cpu_test.hex")
) uut (
.clk(clk),
.reset(reset),

.pc_debug(pc_debug),
.instruction_debug(instruction_debug),
.instruction_valid_debug(instruction_valid_debug),
.illegal_instruction(illegal_instruction)
);

// 10 ns clock
initial begin
clk = 0;
forever #5 clk = ~clk;
end

// Check register value
task check_register;

input [4:0] register_number;
input [31:0] expected;

reg [31:0] actual;

begin

actual =
uut.register_file_inst.registers[register_number];

if (actual === expected) begin

$display(
"PASS | x%0d | EXPECTED=%h | ACTUAL=%h",
register_number, expected, actual
);

passed = passed + 1;

end
else begin

$display(
"FAIL | x%0d | EXPECTED=%h | ACTUAL=%h",
register_number, expected, actual
);

failed = failed + 1;

end

end

endtask

// Check Data Memory word
task check_memory;

input [31:0] word_index;
input [31:0] expected;

reg [31:0] actual;

begin

actual =
uut.data_memory_inst.memory[word_index];

if (actual === expected) begin

$display(
"PASS | MEMORY[%0d] | EXPECTED=%h | ACTUAL=%h",
word_index, expected, actual
);

passed = passed + 1;

end
else begin

$display(
"FAIL | MEMORY[%0d] | EXPECTED=%h | ACTUAL=%h",
word_index, expected, actual
);

failed = failed + 1;

end

end

endtask

initial begin

$dumpfile("wave/riscv_cpu.vcd");
$dumpvars(0, tb_riscv_cpu);

passed = 0;
failed = 0;

reset = 1;

$display("==========================================");
$display("     SINGLE-CYCLE RISC-V CPU TEST");
$display("==========================================");

// Keep CPU in reset for two clock edges
repeat (2) @(posedge clk);

@(negedge clk);
reset = 0;

$display("------------------------------------------");
$display("CPU PROGRAM EXECUTION STARTED");
$display("------------------------------------------");

// Execute 8 instructions.
// The BEQ at address 0x18 skips instruction at 0x1C.
repeat (8) begin
@(posedge clk);
#1;

$display(
"PC=%h | INSTRUCTION=%h | ILLEGAL=%b",
pc_debug,
instruction_debug,
illegal_instruction
);
end

$display("------------------------------------------");
$display("CHECKING CPU RESULTS");
$display("------------------------------------------");

// Arithmetic results
check_register(5'd1, 32'd10);
check_register(5'd2, 32'd20);
check_register(5'd3, 32'd30);
check_register(5'd4, 32'd10);

// Load result
check_register(5'd5, 32'd30);

// Branch must skip ADDI x6, x0, 99
check_register(5'd6, 32'd7);

// Check stored data
check_memory(32'd0, 32'd30);

// Branch target should execute at 0x20
if (pc_debug === 32'h00000024) begin
$display("PASS | BRANCH TARGET | PC=%h", pc_debug);
passed = passed + 1;
end
else begin
$display("FAIL | BRANCH TARGET | PC=%h", pc_debug);
failed = failed + 1;
end

$display("==========================================");
$display("RISC-V CPU TEST SUMMARY");
$display("PASSED = %0d", passed);
$display("FAILED = %0d", failed);
$display("==========================================");

if (failed == 0)
$display("RISC-V CPU TEST PASSED");
else
$display("RISC-V CPU TEST FAILED");

$finish;

end

endmodule
