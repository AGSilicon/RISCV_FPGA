`timescale 1ns/1ps

module tb_branch_unit;

    reg clk;
    reg reset;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire instruction_valid_debug;
    wire illegal_instruction;

    integer passed;
    integer failed;
    integer i;

    riscv_cpu #(
        .IMEM_DEPTH(64),
        .DMEM_DEPTH(256),
        .PROGRAM_WORDS(40),
        .PROGRAM_FILE("programs/branch_test.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .instruction_valid_debug(instruction_valid_debug),
        .illegal_instruction(illegal_instruction)
    );

    always #5 clk = ~clk;

    task check;
        input [255:0] test_name;
        input [31:0] actual;
        input [31:0] expected;

        begin
            if (actual === expected) begin
                $display("PASS: %0s | Actual = %h",
                         test_name, actual);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | Actual = %h Expected = %h",
                         test_name, actual, expected);
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;

        passed = 0;
        failed = 0;

        $dumpfile("wave/branch_unit.vcd");
        $dumpvars(0, tb_branch_unit);

        // Reset
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;

        // 34 executed instructions:
        // 6 initializers
        // 4 CPU setup instructions
        // 12 taken-branch execution cycles
        // 12 not-taken-branch execution cycles

        repeat (34) @(posedge clk);

        #1;

        $display("\n==================================");
        $display("       BRANCH UNIT RESULTS");
        $display("==================================");

        // 1. Six taken branch target results

        for (i = 0; i < 6; i = i + 1) begin

            check("Taken branch target result",
                  dut.register_file_inst.registers[16+i],
                  32'd10+i);

        end

        // 2. Six skipped instructions
        // Their initialized value must remain zero.

        for (i = 0; i < 6; i = i + 1) begin

            check("Taken branch skipped instruction",
                  dut.register_file_inst.registers[10+i],
                  32'd0);

        end

        // 3. Six not-taken branches
        // Their following instructions must execute.

        for (i = 0; i < 6; i = i + 1) begin

            check("Not-taken branch execution",
                  dut.register_file_inst.registers[22+i],
                  32'd99);

        end

        // 4. Final PC

        check("Final PC",
              pc_debug,
              32'h000000A0);

        // 5. Illegal instruction

        check("No illegal instruction",
              {31'b0, illegal_instruction},
              32'd0);

        // Summary

        $display("\n==================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("==================================");

        if (failed == 0)
            $display("ALL BRANCH TESTS PASSED");
        else
            $display("BRANCH TESTS FAILED");

        $finish;

    end

endmodule
