`timescale 1ns/1ps

module alu (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  alu_control,

    output reg  [31:0] result,
    output wire        zero
);

    always @(*) begin

        case (alu_control)

            // ADD
            4'b0000: result = A + B;

            // SUB
            4'b0001: result = A - B;

            // AND
            4'b0010: result = A & B;

            // OR
            4'b0011: result = A | B;

            // XOR
            4'b0100: result = A ^ B;

            // SLT: Signed less-than
            4'b0101:
                result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

            // SLL: Shift left logical
            4'b0110: result = A << B[4:0];

            // SRL: Shift right logical
            4'b0111: result = A >> B[4:0];

            // SRA: Shift right arithmetic
            4'b1000: result = $signed(A) >>> B[4:0];

            // Default
            default: result = 32'h00000000;

        endcase

    end

    // Zero flag
    assign zero = (result == 32'h00000000);

endmodule
