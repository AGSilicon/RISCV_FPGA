`timescale 1ns/1ps

module tb_alu;

    reg [31:0] A;
    reg [31:0] B;
    reg [3:0] alu_control;

    wire [31:0] result;
    wire zero;

    integer passed;
    integer failed;

    // ALU instantiation
    alu uut (
        .A(A),
        .B(B),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    // Task for checking ALU output
    task check_result;
        input [3:0]  operation;
        input [31:0] operand_a;
        input [31:0] operand_b;
        input [31:0] expected;

        begin
            A = operand_a;
            B = operand_b;
            alu_control = operation;

            #10;

            if (result === expected) begin
                $display("PASS | OP=%b | A=%h | B=%h | RESULT=%h | ZERO=%b",
                         operation, A, B, result, zero);
                passed = passed + 1;
            end
            else begin
                $display("FAIL | OP=%b | A=%h | B=%h | EXPECTED=%h | ACTUAL=%h",
                         operation, A, B, expected, result);
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("wave/alu.vcd");
        $dumpvars(0, tb_alu);

        passed = 0;
        failed = 0;

        $display("---------------------------------------------");
        $display("         RISC-V ALU TEST STARTED");
        $display("---------------------------------------------");

        // 1. ADD: 10 + 5 = 15
        check_result(4'b0000, 32'd10, 32'd5, 32'd15);

        // 2. SUB: 10 - 5 = 5
        check_result(4'b0001, 32'd10, 32'd5, 32'd5);

        // 3. AND
        check_result(4'b0010, 32'h0000000A,
                     32'h0000000C, 32'h00000008);

        // 4. OR
        check_result(4'b0011, 32'h0000000A,
                     32'h0000000C, 32'h0000000E);

        // 5. XOR
        check_result(4'b0100, 32'h0000000A,
                     32'h0000000C, 32'h00000006);

        // 6. SLT: 5 < 10
        check_result(4'b0101, 32'd5, 32'd10, 32'd1);

        // 7. SLT: -5 < 3
        check_result(4'b0101, 32'hFFFFFFFB,
                     32'd3, 32'd1);

        // 8. SLL: 3 << 2 = 12
        check_result(4'b0110, 32'd3, 32'd2, 32'd12);

        // 9. SRL: 16 >> 2 = 4
        check_result(4'b0111, 32'd16, 32'd2, 32'd4);

        // 10. SRA: -16 >>> 2 = -4
        check_result(4'b1000, 32'hFFFFFFF0,
                     32'd2, 32'hFFFFFFFC);

        // 11. Zero flag test: 5 - 5 = 0
        check_result(4'b0001, 32'd5, 32'd5, 32'd0);

        // 12. Default operation
        check_result(4'b1111, 32'd10, 32'd5, 32'd0);

        $display("---------------------------------------------");
        $display("ALU TEST SUMMARY");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("---------------------------------------------");

        if (failed == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $display("ALU TEST FAILED");

        $finish;

    end

endmodule
