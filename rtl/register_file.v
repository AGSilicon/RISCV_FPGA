`timescale 1ns/1ps

module register_file (
    input wire clk,

    // Read port 1
    input wire [4:0] read_addr1,
    output wire [31:0] read_data1,

    // Read port 2
    input wire [4:0] read_addr2,
    output wire [31:0] read_data2,

    // Write port
    input wire write_enable,
    input wire [4:0] write_addr,
    input wire [31:0] write_data
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    // Synchronous write
    always @(posedge clk) begin
        if (write_enable && (write_addr != 5'd0))
            registers[write_addr] <= write_data;
    end

    // Asynchronous read port 1
    assign read_data1 =
        (read_addr1 == 5'd0) ? 32'd0 : registers[read_addr1];

    // Asynchronous read port 2
    assign read_data2 =
        (read_addr2 == 5'd0) ? 32'd0 : registers[read_addr2];

endmodule
