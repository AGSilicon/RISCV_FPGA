
`timescale 1ns/1ps

module system_instruction_unit (
    input  wire [31:0] instruction,

    output reg         is_system,
    output reg         is_csr,
    output reg         ecall,
    output reg         ebreak,
    output reg         mret,
    output reg         fence,
    output reg         illegal
);

    localparam OP_SYSTEM = 7'b1110011;
    localparam OP_FENCE  = 7'b0001111;

    always @(*) begin
        is_system = 1'b0;
        is_csr    = 1'b0;
        ecall     = 1'b0;
        ebreak    = 1'b0;
        mret      = 1'b0;
        fence     = 1'b0;
        illegal   = 1'b0;

        case (instruction[6:0])

            OP_SYSTEM: begin
                is_system = 1'b1;

                if (instruction[14:12] != 3'b000) begin
                    // CSR instructions are decoded by csr_instruction_unit.
                    is_csr = 1'b1;
                end
                else begin
                    case (instruction)
                        32'h00000073: ecall  = 1'b1;
                        32'h00100073: ebreak = 1'b1;
                        32'h30200073: mret   = 1'b1;

                        default: illegal = 1'b1;
                    endcase
                end
            end

            OP_FENCE: begin
                // Base FENCE: funct3=000, rd=0, rs1=0, fm=0000.
                // pred and succ fields may contain any ordering bits.
                if ((instruction[14:12] == 3'b000) &&
                    (instruction[11:7]  == 5'd0)   &&
                    (instruction[19:15] == 5'd0)   &&
                    (instruction[31:28] == 4'b0000)) begin
                    fence = 1'b1;
                end
                else begin
                    illegal = 1'b1;
                end
            end

            default: begin
                // Not a SYSTEM or FENCE instruction.
            end

        endcase
    end

endmodule
