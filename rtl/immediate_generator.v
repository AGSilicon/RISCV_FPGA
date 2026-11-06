`timescale 1ns/1ps

module immediate_generator (
    input wire [31:0] instruction,
    input wire [2:0]  imm_sel,

    output reg [31:0] immediate
);

    always @(*) begin

        case (imm_sel)

            // I-type: ADDI, LW, ANDI, ORI
            3'b000:
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

            // S-type: SW
            3'b001:
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };

            // B-type: BEQ, BNE
            3'b010:
                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };

            // U-type: LUI, AUIPC
            3'b011:
                immediate = {
                    instruction[31:12],
                    12'b0
                };

            // J-type: JAL
            3'b100:
                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };

            // Invalid format
            default:
                immediate = 32'h00000000;

        endcase

    end

endmodule
