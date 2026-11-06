
`timescale 1ns/1ps

module instruction_memory #(
    parameter DEPTH = 64,
    parameter INIT_WORDS = 4,
    parameter INIT_FILE = "programs/test_program.hex"
)(
    input wire [31:0] address,

    output reg [31:0] instruction,
    output reg instruction_valid
);

    // 64 locations, each 32 bits
    reg [31:0] memory [0:DEPTH-1];

    integer i;

    // Initialize memory
    initial begin

        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'h00000013;

        // Load program instructions
        $readmemh(INIT_FILE, memory, 0, INIT_WORDS-1);

    end

    // Asynchronous instruction fetch
    always @(*) begin

        if ((address[1:0] == 2'b00) &&
            (address[31:2] < DEPTH)) begin

            instruction = memory[address[31:2]];
            instruction_valid = 1'b1;

        end
        else begin

            instruction = 32'h00000013;
            instruction_valid = 1'b0;

        end

    end

endmodule
