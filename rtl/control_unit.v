`timescale 1ns/1ps


module control_unit (

input wire [6:0] opcode,
input wire [2:0] funct3,
input wire [6:0] funct7,

output reg reg_write,
output reg mem_read,
output reg mem_write,

output reg alu_src,
output reg alu_a_src,

output reg [3:0] alu_control,
output reg [2:0] imm_sel,

output reg branch,
output reg branch_ne,
output reg jump,
output reg jalr,

output reg [1:0] result_src,

output reg [1:0] mem_size,
output reg load_unsigned,

output reg illegal

);

localparam OP_R_TYPE = 7'b0110011;
localparam OP_I_TYPE = 7'b0010011;
localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_LUI    = 7'b0110111;
localparam OP_AUIPC  = 7'b0010111;
localparam OP_JAL    = 7'b1101111;
localparam OP_JALR   = 7'b1100111;

localparam ALU_ADD = 4'b0000;
localparam ALU_SUB = 4'b0001;
localparam ALU_AND = 4'b0010;
localparam ALU_OR  = 4'b0011;
localparam ALU_XOR = 4'b0100;
localparam ALU_SLT = 4'b0101;
localparam ALU_SLL = 4'b0110;
localparam ALU_SRL = 4'b0111;
localparam ALU_SRA = 4'b1000;

always @(*) begin

// Safe defaults
reg_write = 0;
mem_read = 0;
mem_write = 0;

alu_src = 0;
alu_a_src = 0;

alu_control = ALU_ADD;
imm_sel = 3'b000;

branch = 0;
branch_ne = 0;
jump = 0;
jalr = 0;

result_src = 2'b00;

mem_size = 2'b10;
load_unsigned = 0;

illegal = 1;

case (opcode)

// --------------------------------
// R TYPE
// --------------------------------

OP_R_TYPE: begin

case (funct3)

3'b000: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_ADD;
illegal = 0;
end
else if (funct7 == 7'b0100000) begin
alu_control = ALU_SUB;
illegal = 0;
end
end

3'b111: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_AND;
illegal = 0;
end
end

3'b110: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_OR;
illegal = 0;
end
end

3'b100: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_XOR;
illegal = 0;
end
end

3'b010: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_SLT;
illegal = 0;
end
end

3'b001: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_SLL;
illegal = 0;
end
end

3'b101: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_SRL;
illegal = 0;
end
else if (funct7 == 7'b0100000) begin
alu_control = ALU_SRA;
illegal = 0;
end
end

default: illegal = 1;

endcase

if (!illegal)
reg_write = 1;

end

// --------------------------------
// I TYPE
// --------------------------------

OP_I_TYPE: begin

imm_sel = 3'b000;
alu_src = 1;

case (funct3)

3'b000: begin
alu_control = ALU_ADD;
illegal = 0;
end

3'b111: begin
alu_control = ALU_AND;
illegal = 0;
end

3'b110: begin
alu_control = ALU_OR;
illegal = 0;
end

3'b100: begin
alu_control = ALU_XOR;
illegal = 0;
end

3'b010: begin
alu_control = ALU_SLT;
illegal = 0;
end

3'b001: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_SLL;
illegal = 0;
end
end

3'b101: begin
if (funct7 == 7'b0000000) begin
alu_control = ALU_SRL;
illegal = 0;
end
else if (funct7 == 7'b0100000) begin
alu_control = ALU_SRA;
illegal = 0;
end
end

default: illegal = 1;

endcase

if (!illegal)
reg_write = 1;

end

// --------------------------------
// LOAD: LB, LH, LW, LBU, LHU
// --------------------------------

OP_LOAD: begin

alu_src = 1;
imm_sel = 3'b000;
alu_control = ALU_ADD;
result_src = 2'b01;

case (funct3)

// LB
3'b000: begin
mem_size = 2'b00;
load_unsigned = 0;
illegal = 0;
end

// LH
3'b001: begin
mem_size = 2'b01;
load_unsigned = 0;
illegal = 0;
end

// LW
3'b010: begin
mem_size = 2'b10;
load_unsigned = 0;
illegal = 0;
end

// LBU
3'b100: begin
mem_size = 2'b00;
load_unsigned = 1;
illegal = 0;
end

// LHU
3'b101: begin
mem_size = 2'b01;
load_unsigned = 1;
illegal = 0;
end

default: illegal = 1;

endcase

if (!illegal) begin
mem_read = 1;
reg_write = 1;
end

end

// --------------------------------
// STORE: SB, SH, SW
// --------------------------------

OP_STORE: begin

alu_src = 1;
imm_sel = 3'b001;
alu_control = ALU_ADD;

case (funct3)

// SB
3'b000: begin
mem_size = 2'b00;
illegal = 0;
end

// SH
3'b001: begin
mem_size = 2'b01;
illegal = 0;
end

// SW
3'b010: begin
mem_size = 2'b10;
illegal = 0;
end

default: illegal = 1;

endcase

if (!illegal)
mem_write = 1;

end

// --------------------------------
// BRANCH
// --------------------------------

OP_BRANCH: begin

case (funct3)

3'b000,
3'b001,
3'b100,
3'b101,
3'b110,
3'b111: begin
branch = 1;
alu_control = ALU_SUB;
imm_sel = 3'b010;
illegal = 0;

if (funct3 == 3'b001)
branch_ne = 1;
end

default: illegal = 1;

endcase

end

// --------------------------------
// LUI
// --------------------------------

OP_LUI: begin
reg_write = 1;
imm_sel = 3'b011;
result_src = 2'b10;
illegal = 0;
end

// --------------------------------
// AUIPC
// --------------------------------

OP_AUIPC: begin
reg_write = 1;
alu_src = 1;
alu_a_src = 1;
imm_sel = 3'b011;
alu_control = ALU_ADD;
illegal = 0;
end

// --------------------------------
// JAL
// --------------------------------

OP_JAL: begin
reg_write = 1;
jump = 1;
imm_sel = 3'b100;
result_src = 2'b11;
illegal = 0;
end

// --------------------------------
// JALR
// --------------------------------

OP_JALR: begin

if (funct3 == 3'b000) begin
reg_write = 1;
alu_src = 1;
alu_control = ALU_ADD;
imm_sel = 3'b000;
jump = 1;
jalr = 1;
result_src = 2'b11;
illegal = 0;
end

end

default: illegal = 1;

endcase

end

endmodule
