`timescale 1ns/1ps

module tb_program_counter;

    reg clk;
    reg reset;
    reg [31:0] next_pc;

    wire [31:0] pc;

    // Instantiate Program Counter
    program_counter uut (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        $dumpfile("wave/pc.vcd");
        $dumpvars(0, tb_program_counter);

        $monitor("Time=%0t | Reset=%b | Next_PC=%h | PC=%h",
                 $time, reset, next_pc, pc);

        // Test 1: Reset
        reset = 1;
        next_pc = 32'h00000000;
        #12;

        // Test 2: First instruction
        reset = 0;
        next_pc = 32'h00000004;
        #10;

        // Test 3: Second instruction
        next_pc = 32'h00000008;
        #10;

        // Test 4: Third instruction
        next_pc = 32'h0000000C;
        #10;

        // Test 5: Branch target
        next_pc = 32'h00000020;
        #10;

        // Test 6: Jump target
        next_pc = 32'h00000100;
        #10;

        $display("PC TEST COMPLETED");
        $finish;
    end

endmodule
