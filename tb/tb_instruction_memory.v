`timescale 1ns/1ps


module tb_instruction_memory;

reg [31:0] address;

wire [31:0] instruction;
wire instruction_valid;

integer passed;
integer failed;

instruction_memory #(
.DEPTH(64),
.INIT_WORDS(4),
.INIT_FILE("programs/test_program.hex")
) uut (
.address(address),
.instruction(instruction),
.instruction_valid(instruction_valid)
);

task check_instruction;

input [31:0] test_address;
input [31:0] expected_instruction;
input expected_valid;

begin

address = test_address;
#5;

if ((instruction === expected_instruction) &&
(instruction_valid === expected_valid)) begin

$display(
"PASS | PC=%h | INSTRUCTION=%h | VALID=%b",
address, instruction, instruction_valid
);

passed = passed + 1;

end
else begin

$display(
"FAIL | PC=%h | EXPECTED=%h | ACTUAL=%h | VALID=%b",
address, expected_instruction,
instruction, instruction_valid
);

failed = failed + 1;

end

end

endtask

initial begin

$dumpfile("wave/instruction_memory.vcd");
$dumpvars(0, tb_instruction_memory);

passed = 0;
failed = 0;
address = 0;

$display("------------------------------------------");
$display(" INSTRUCTION MEMORY TEST STARTED");
$display("------------------------------------------");

check_instruction(
32'h00000000, 32'h00A00093, 1'b1
);

check_instruction(
32'h00000004, 32'h01400113, 1'b1
);

check_instruction(
32'h00000008, 32'h002081B3, 1'b1
);

check_instruction(
32'h0000000C, 32'h40110233, 1'b1
);

check_instruction(
32'h00000010, 32'h00000013, 1'b1
);

check_instruction(
32'h00000002, 32'h00000013, 1'b0
);

check_instruction(
32'h00000100, 32'h00000013, 1'b0
);

$display("------------------------------------------");
$display("INSTRUCTION MEMORY TEST SUMMARY");
$display("PASSED = %0d", passed);
$display("FAILED = %0d", failed);
$display("------------------------------------------");

if (failed == 0)
$display("ALL INSTRUCTION MEMORY TESTS PASSED");
else
$display("INSTRUCTION MEMORY TEST FAILED");

$finish;

end

endmodule
