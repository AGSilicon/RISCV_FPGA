
`timescale 1ns/1ps

module data_memory #(
    parameter DEPTH = 256
)(
    input wire clk,

    input wire mem_read,
    input wire mem_write,

    input wire [31:0] address,
    input wire [31:0] write_data,

    // 00 = BYTE, 01 = HALFWORD, 10 = WORD
    input wire [1:0] mem_size,

    // 1 = unsigned load, 0 = signed load
    input wire load_unsigned,

    output reg [31:0] read_data,
    output wire address_valid
);

    // DEPTH words, each word contains 4 bytes
    reg [31:0] memory [0:DEPTH-1];

    integer i;

    // Initialize memory
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'h00000000;
    end

    // Check memory range and alignment
    assign address_valid =
        (address[31:2] < DEPTH) &&
        (
            (mem_size == 2'b00) ||
            (mem_size == 2'b01 && address[0] == 1'b0) ||
            (mem_size == 2'b10 && address[1:0] == 2'b00)
        );

    // -----------------------------------------
    // READ LOGIC
    // -----------------------------------------

    reg [31:0] selected_word;
    reg [31:0] shifted_word;

    always @(*) begin

        read_data = 32'h00000000;
        selected_word = 32'h00000000;
        shifted_word = 32'h00000000;

        if (mem_read && address_valid) begin

            selected_word = memory[address[31:2]];

            // Select addressed byte lane
            shifted_word =
                selected_word >> (address[1:0] * 8);

            case (mem_size)

                // LB / LBU
                2'b00: begin
                    if (load_unsigned)
                        read_data = {24'b0, shifted_word[7:0]};
                    else
                        read_data = {
                            {24{shifted_word[7]}},
                            shifted_word[7:0]
                        };
                end

                // LH / LHU
                2'b01: begin
                    if (load_unsigned)
                        read_data = {16'b0, shifted_word[15:0]};
                    else
                        read_data = {
                            {16{shifted_word[15]}},
                            shifted_word[15:0]
                        };
                end

                // LW
                2'b10: begin
                    read_data = selected_word;
                end

                default: begin
                    read_data = 32'h00000000;
                end

            endcase

        end

    end

    // -----------------------------------------
    // WRITE LOGIC
    // -----------------------------------------

    always @(posedge clk) begin

        if (mem_write && address_valid) begin

            case (mem_size)

                // SB
                2'b00: begin
                    memory[address[31:2]]
                         [address[1:0]*8 +: 8]
                         <= write_data[7:0];
                end

                // SH
                2'b01: begin
                    memory[address[31:2]]
                         [address[1:0]*8 +: 16]
                         <= write_data[15:0];
                end

                // SW
                2'b10: begin
                    memory[address[31:2]]
                         <= write_data;
                end

                default: begin
                    // No operation
                end

            endcase

        end

    end

endmodule
