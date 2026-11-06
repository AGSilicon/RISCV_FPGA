`timescale 1ns/1ps

module program_counter (
    input wire clk,
    input wire reset,
    input wire [31:0] next_pc,

    output reg [31:0] pc
);

    always @(posedge clk) begin
        if (reset)
            pc <= 32'h00000000;
        else
            pc <= next_pc;
    end

endmodule
