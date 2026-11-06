`timescale 1ns/1ps

module tb_immediate_generator;

    reg [31:0] instruction;
    reg [2:0] imm_sel;

    wire [31:0] immediate;

    integer passed;
    integer failed;

    immediate_generator uut (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    // Build an I-type instruction and check its immediate
    task test_I;
        input [31:0] imm;
        input [31:0] expected;
        begin
            instruction = {
                imm[11:0], 5'd1, 3'b000, 5'd2, 7'b0010011
            };
            imm_sel = 3'b000;
            check_result("I-TYPE", expected);
        end
    endtask

    // Build an S-type instruction and check its immediate
    task test_S;
        input [31:0] imm;
        input [31:0] expected;
        begin
            instruction = {
                imm[11:5], 5'd1, 5'd2, 3'b010,
                imm[4:0], 7'b0100011
            };
            imm_sel = 3'b001;
            check_result("S-TYPE", expected);
        end
    endtask

    // Build a B-type instruction and check its immediate
    task test_B;
        input [31:0] imm;
        input [31:0] expected;
        begin
            instruction = {
                imm[12], imm[10:5], 5'd1, 5'd2, 3'b000,
                imm[4:1], imm[11], 7'b1100011
            };
            imm_sel = 3'b010;
            check_result("B-TYPE", expected);
        end
    endtask

    // Build a U-type instruction and check its immediate
    task test_U;
        input [31:0] imm;
        input [31:0] expected;
        begin
            instruction = {
                imm[31:12], 12'b0
            };
            imm_sel = 3'b011;
            check_result("U-TYPE", expected);
        end
    endtask

    // Build a J-type instruction and check its immediate
    task test_J;
        input [31:0] imm;
        input [31:0] expected;
        begin
            instruction = {
                imm[20], imm[10:1], imm[11],
                imm[19:12], 5'd1, 7'b1101111
            };
            imm_sel = 3'b100;
            check_result("J-TYPE", expected);
        end
    endtask

    // Common result checker
    task check_result;
        input [80*8-1:0] format_name;
        input [31:0] expected;

        begin
            #5;

            if (immediate === expected) begin
                $display(
                    "PASS | %0s | SEL=%b | IMM=%h",
                    format_name, imm_sel, immediate
                );
                passed = passed + 1;
            end
            else begin
                $display(
                    "FAIL | %0s | SEL=%b | EXPECTED=%h | ACTUAL=%h",
                    format_name, imm_sel, expected, immediate
                );
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("wave/immediate_generator.vcd");
        $dumpvars(0, tb_immediate_generator);

        passed = 0;
        failed = 0;
        instruction = 0;
        imm_sel = 0;

        $display("------------------------------------------");
        $display(" IMMEDIATE GENERATOR TEST STARTED");
        $display("------------------------------------------");

        // I-type
        test_I(32'd10, 32'h0000000A);
        test_I(-32'sd5, 32'hFFFFFFFB);

        // S-type
        test_S(32'd20, 32'h00000014);
        test_S(-32'sd8, 32'hFFFFFFF8);

        // B-type (offsets are even)
        test_B(32'd16, 32'h00000010);
        test_B(-32'sd4, 32'hFFFFFFFC);

        // U-type
        test_U(32'h12345000, 32'h12345000);
        test_U(32'hABCDE000, 32'hABCDE000);

        // J-type (offsets are even)
        test_J(32'd2048, 32'h00000800);
        test_J(-32'sd2048, 32'hFFFFF800);

        // Invalid format
        instruction = 32'hFFFFFFFF;
        imm_sel = 3'b111;
        check_result("INVALID", 32'h00000000);

        $display("------------------------------------------");
        $display("IMMEDIATE GENERATOR TEST SUMMARY");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("------------------------------------------");

        if (failed == 0)
            $display("ALL IMMEDIATE GENERATOR TESTS PASSED");
        else
            $display("IMMEDIATE GENERATOR TEST FAILED");

        $finish;

    end

endmodule
