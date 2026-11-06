
`timescale 1ns/1ps

module csr_instruction_unit (

    input wire [31:0] instruction,
    input wire [31:0] rs1_data,
    input wire [31:0] csr_read_data,
    input wire csr_valid,

    output reg [11:0] csr_addr,
    output reg csr_read_enable,
    output reg csr_write_enable,
    output reg [31:0] csr_write_data,

    output reg rd_write_enable,
    output reg [31:0] rd_write_data,

    output reg illegal

);

    localparam OP_SYSTEM = 7'b1110011;

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [11:0] csr;

    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign csr = instruction[31:20];

    reg [31:0] source_value;
    reg write_requested;

    always @(*) begin

        csr_addr = csr;

        csr_read_enable = 1'b0;
        csr_write_enable = 1'b0;
        csr_write_data = 32'h00000000;

        rd_write_enable = 1'b0;
        rd_write_data = 32'h00000000;

        source_value = rs1_data;
        write_requested = 1'b0;

        illegal = 1'b0;

        if (opcode == OP_SYSTEM) begin

            case (funct3)

                // CSRRW
                3'b001: begin
                    source_value = rs1_data;
                    write_requested = 1'b1;
                end

                // CSRRS
                3'b010: begin
                    source_value = rs1_data;
                    write_requested = (rs1 != 5'd0);
                end

                // CSRRC
                3'b011: begin
                    source_value = rs1_data;
                    write_requested = (rs1 != 5'd0);
                end

                // CSRRWI
                3'b101: begin
                    source_value = {27'b0, rs1};
                    write_requested = 1'b1;
                end

                // CSRRSI
                3'b110: begin
                    source_value = {27'b0, rs1};
                    write_requested = (rs1 != 5'd0);
                end

                // CSRRCI
                3'b111: begin
                    source_value = {27'b0, rs1};
                    write_requested = (rs1 != 5'd0);
                end

                default: begin
                    illegal = 1'b1;
                end

            endcase

            // Check CSR existence and machine privilege
            if (!csr_valid || csr[9:8] != 2'b11)
                illegal = 1'b1;

            // Implemented CSRs are writable.
            // Reject writes to architecturally read-only CSRs.
            if (write_requested && csr[11:10] == 2'b11)
                illegal = 1'b1;

            if (!illegal) begin

                // CSR read
                csr_read_enable = (rd != 5'd0);

                // Destination register receives old CSR value
                rd_write_enable = (rd != 5'd0);
                rd_write_data = csr_read_data;

                // CSR write
                if (write_requested) begin

                    csr_write_enable = 1'b1;

                    case (funct3)

                        // CSRRW / CSRRWI
                        3'b001,
                        3'b101:
                            csr_write_data = source_value;

                        // CSRRS / CSRRSI
                        3'b010,
                        3'b110:
                            csr_write_data =
                                csr_read_data | source_value;

                        // CSRRC / CSRRCI
                        3'b011,
                        3'b111:
                            csr_write_data =
                                csr_read_data & ~source_value;

                        default:
                            csr_write_data = csr_read_data;

                    endcase

                end

            end

        end

    end

endmodule
