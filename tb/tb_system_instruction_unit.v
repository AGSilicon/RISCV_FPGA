`timescale 1ns/1ps


module tb_system_instruction_unit;

reg [31:0] instruction;

wire is_system;
wire is_csr;
wire ecall;
wire ebreak;
wire mret;
wire fence;
wire illegal;

integer passed;
integer failed;

system_instruction_unit uut (
.instruction(instruction),
.is_system(is_system),
.is_csr(is_csr),
.ecall(ecall),
.ebreak(ebreak),
.mret(mret),
.fence(fence),
.illegal(illegal)
);

task check;
input condition;
input [8*45-1:0] test_name;
begin
if (condition === 1'b1) begin
$display("PASS: %0s", test_name);
passed = passed + 1;
end
else begin
$display("FAIL: %0s", test_name);
failed = failed + 1;
end
end
endtask

initial begin
passed = 0;
failed = 0;

$display("\n====================================");
$display(" SYSTEM INSTRUCTION UNIT TEST START");
$display("====================================");

// ECALL
instruction = 32'h00000073;
#1;
check(is_system && ecall && !illegal, "ECALL decoded");

// EBREAK
instruction = 32'h00100073;
#1;
check(is_system && ebreak && !illegal, "EBREAK decoded");

// MRET
instruction = 32'h30200073;
#1;
check(is_system && mret && !illegal, "MRET decoded");

// FENCE with empty predecessor/successor fields
instruction = 32'h0000000F;
#1;
check(fence && !illegal, "FENCE decoded");

// FENCE with predecessor and successor bits set
instruction = 32'h0FF0000F;
#1;
check(fence && !illegal, "FENCE ordering fields accepted");

// Unsupported SYSTEM instruction (WFI)
instruction = 32'h10500073;
#1;
check(is_system && illegal, "Unsupported SYSTEM instruction rejected");

// CSR instruction must be routed to CSR decoder
instruction = 32'h305092F3;
#1;
check(is_system && is_csr && !illegal, "CSR instruction identified");

// FENCE.I is not supported
instruction = 32'h0000100F;
#1;
check(illegal && !fence, "FENCE.I rejected");

// Malformed FENCE with nonzero rd
instruction = 32'h0000008F;
#1;
check(illegal && !fence, "Malformed FENCE rejected");

// Normal ADD instruction must not trigger system controls
instruction = 32'h002081B3;
#1;
check(!is_system && !is_csr && !ecall &&
!ebreak && !mret && !fence && !illegal,
"Normal ADD has no system control");

$display("\n====================================");
$display(" SYSTEM INSTRUCTION UNIT RESULTS");
$display("====================================");
$display("PASSED = %0d", passed);
$display("FAILED = %0d", failed);

if (failed == 0)
$display("ALL SYSTEM INSTRUCTION TESTS PASSED");
else
$display("SYSTEM INSTRUCTION TESTS FAILED");

$display("====================================");
$finish;
end

endmodule
