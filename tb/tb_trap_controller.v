`timescale 1ns/1ps


module tb_trap_controller;

reg [31:0] current_pc;
reg [31:0] instruction;
reg [31:0] fault_address;

reg instruction_misaligned;
reg instruction_access_fault;
reg illegal_instruction;
reg breakpoint_exception;
reg load_misaligned;
reg load_access_fault;
reg store_misaligned;
reg store_access_fault;
reg ecall_m_exception;

wire trap_enter;
wire [31:0] trap_pc;
wire [31:0] trap_cause;
wire [31:0] trap_value;

integer passed;
integer failed;

trap_controller uut (
.current_pc(current_pc),
.instruction(instruction),
.fault_address(fault_address),

.instruction_misaligned(instruction_misaligned),
.instruction_access_fault(instruction_access_fault),
.illegal_instruction(illegal_instruction),
.breakpoint_exception(breakpoint_exception),
.load_misaligned(load_misaligned),
.load_access_fault(load_access_fault),
.store_misaligned(store_misaligned),
.store_access_fault(store_access_fault),
.ecall_m_exception(ecall_m_exception),

.trap_enter(trap_enter),
.trap_pc(trap_pc),
.trap_cause(trap_cause),
.trap_value(trap_value)
);

task clear_exceptions;
begin
instruction_misaligned = 0;
instruction_access_fault = 0;
illegal_instruction = 0;
breakpoint_exception = 0;
load_misaligned = 0;
load_access_fault = 0;
store_misaligned = 0;
store_access_fault = 0;
ecall_m_exception = 0;
end
endtask

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

current_pc = 32'h00000100;
instruction = 32'h002081B3;
fault_address = 32'h00000003;

clear_exceptions();
#1;

$display("\n====================================");
$display("     TRAP CONTROLLER TEST START");
$display("====================================");

check(!trap_enter, "No exception means no trap");

// Cause 0: instruction address misaligned
instruction_misaligned = 1;
#1;
check(trap_enter && trap_cause == 0 &&
trap_value == fault_address,
"Instruction address misaligned");
check(trap_pc == current_pc, "Instruction misaligned saves PC");
clear_exceptions();

// Cause 1: instruction access fault
instruction_access_fault = 1;
#1;
check(trap_enter && trap_cause == 1 &&
trap_value == fault_address,
"Instruction access fault");
clear_exceptions();

// Cause 2: illegal instruction
illegal_instruction = 1;
instruction = 32'hFFFFFFFF;
#1;
check(trap_enter && trap_cause == 2 &&
trap_value == instruction,
"Illegal instruction");

clear_exceptions();

// Cause 3: breakpoint
breakpoint_exception = 1;
#1;
check(trap_enter && trap_cause == 3 &&
trap_value == 0,
"Breakpoint exception");

clear_exceptions();

// Cause 4: load address misaligned
load_misaligned = 1;
#1;
check(trap_enter && trap_cause == 4 &&
trap_value == fault_address,
"Load address misaligned");

clear_exceptions();

// Cause 5: load access fault
load_access_fault = 1;
#1;
check(trap_enter && trap_cause == 5 &&
trap_value == fault_address,
"Load access fault");

clear_exceptions();

// Cause 6: store address misaligned
store_misaligned = 1;
#1;
check(trap_enter && trap_cause == 6 &&
trap_value == fault_address,
"Store address misaligned");

clear_exceptions();

// Cause 7: store access fault
store_access_fault = 1;
#1;
check(trap_enter && trap_cause == 7 &&
trap_value == fault_address,
"Store access fault");

clear_exceptions();

// Cause 11: ECALL from M-mode
ecall_m_exception = 1;
#1;
check(trap_enter && trap_cause == 11 &&
trap_value == 0,
"ECALL from M-mode");

clear_exceptions();

// Priority test: instruction misaligned over illegal
instruction_misaligned = 1;
illegal_instruction = 1;
#1;
check(trap_enter && trap_cause == 0,
"Exception priority selection");

clear_exceptions();

$display("\n====================================");
$display("      TRAP CONTROLLER RESULTS");
$display("====================================");
$display("PASSED = %0d", passed);
$display("FAILED = %0d", failed);

if (failed == 0)
$display("ALL TRAP CONTROLLER TESTS PASSED");
else
$display("TRAP CONTROLLER TESTS FAILED");

$display("====================================");
$finish;
end

endmodule
