`timescale 1ns/1ps


module tb_csr_instruction_unit;

reg [31:0] instruction;
reg [31:0] rs1_data;
reg [31:0] csr_read_data;
reg csr_valid;

wire [11:0] csr_addr;
wire csr_read_enable;
wire csr_write_enable;
wire [31:0] csr_write_data;

wire rd_write_enable;
wire [31:0] rd_write_data;

wire illegal;

integer passed;
integer failed;

csr_instruction_unit uut (
.instruction(instruction),
.rs1_data(rs1_data),
.csr_read_data(csr_read_data),
.csr_valid(csr_valid),

.csr_addr(csr_addr),
.csr_read_enable(csr_read_enable),
.csr_write_enable(csr_write_enable),
.csr_write_data(csr_write_data),

.rd_write_enable(rd_write_enable),
.rd_write_data(rd_write_data),

.illegal(illegal)
);

task check;
input condition;
input [8*45-1:0] name;

begin
if (condition === 1'b1) begin
$display("PASS: %0s", name);
passed = passed + 1;
end
else begin
$display("FAIL: %0s", name);
failed = failed + 1;
end
end
endtask

initial begin

passed = 0;
failed = 0;

rs1_data = 32'h0000000F;
csr_read_data = 32'h000000F0;
csr_valid = 1'b1;

$display("\n======= CSR INSTRUCTION TEST =======");

// CSRRW x5, mtvec, x1
instruction = 32'h305092F3;
#1;

check(!illegal, "CSRRW legal");
check(csr_write_enable, "CSRRW writes CSR");
check(csr_write_data == 32'h0000000F, "CSRRW data");
check(rd_write_enable, "CSRRW writes rd");
check(rd_write_data == 32'h000000F0, "CSRRW old CSR value");

// CSRRS x5, mtvec, x1
instruction = 32'h3050A2F3;
#1;

check(!illegal, "CSRRS legal");
check(csr_write_enable, "CSRRS writes CSR");
check(csr_write_data == 32'h000000FF, "CSRRS OR operation");

// CSRRC x5, mtvec, x1
instruction = 32'h3050B2F3;
#1;

check(!illegal, "CSRRC legal");
check(csr_write_enable, "CSRRC writes CSR");
check(csr_write_data == 32'h000000F0, "CSRRC AND NOT operation");

// CSRRWI x5, mtvec, 3
instruction = 32'h3051D2F3;
#1;

check(!illegal, "CSRRWI legal");
check(csr_write_data == 32'd3, "CSRRWI immediate");

// CSRRSI x5, mtvec, 3
instruction = 32'h3051E2F3;
#1;

check(!illegal, "CSRRSI legal");
check(csr_write_data == 32'h000000F3, "CSRRSI OR immediate");

// CSRRCI x5, mtvec, 3
instruction = 32'h3051F2F3;
#1;

check(!illegal, "CSRRCI legal");
check(csr_write_data == 32'h000000F0, "CSRRCI AND NOT immediate");

// CSRRS with rs1 = x0 must not write
instruction = 32'h3050A2F3;
instruction[19:15] = 5'd0;
#1;

check(!csr_write_enable, "CSRRS x0 suppresses CSR write");

// CSRRW with rd = x0 must suppress rd write
instruction = 32'h30509073;
#1;

check(csr_write_enable, "CSRRW x0 still writes CSR");
check(!rd_write_enable, "CSRRW rd=x0 suppresses rd write");

// Unsupported CSR
csr_valid = 1'b0;
instruction = 32'h777092F3;
#1;

check(illegal, "Unsupported CSR rejected");
check(!csr_write_enable, "Invalid CSR write suppressed");

// Read-only CSR write attempt
csr_valid = 1'b1;
instruction = 32'hC00092F3;
#1;

check(illegal, "Read-only CSR write rejected");

$display("\n======= CSR INSTRUCTION RESULTS =======");
$display("PASSED = %0d", passed);
$display("FAILED = %0d", failed);

if (failed == 0)
$display("ALL CSR INSTRUCTION TESTS PASSED");
else
$display("CSR INSTRUCTION TESTS FAILED");

$finish;

end

endmodule
