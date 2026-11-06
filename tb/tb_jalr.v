`timescale 1ns/1ps

module tb_jalr;

    reg clk;
    reg reset;

    integer passed;
    integer failed;
    integer i;

    riscv_cpu uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        passed = 0;
        failed = 0;

        // Load JALR test program
        $readmemh("programs/jalr_test.hex",
                  uut.instruction_memory_inst.memory);

        // Reset CPU
        #20;
        reset = 0;

        // Execute 9 instructions
        for (i = 0; i < 9; i = i + 1)
            @(posedge clk);

        #1;

        $display("\n========== JALR TEST RESULTS ==========");

        // x1 = 45
        if (uut.register_file_inst.registers[1] === 32'd45) begin
            $display("PASS: x1 = 45");
            passed = passed + 1;
        end else begin
            $display("FAIL: x1 expected 45, got %0d",
                     uut.register_file_inst.registers[1]);
            failed = failed + 1;
        end

        // x2 remains 7 because instruction was skipped
        if (uut.register_file_inst.registers[2] === 32'd7) begin
            $display("PASS: First JALR skipped instruction");
            passed = passed + 1;
        end else begin
            $display("FAIL: x2 expected 7, got %0d",
                     uut.register_file_inst.registers[2]);
            failed = failed + 1;
        end

        // First JALR link address = 0x10
        if (uut.register_file_inst.registers[5] === 32'd16) begin
            $display("PASS: First JALR link address = 16");
            passed = passed + 1;
        end else begin
            $display("FAIL: x5 expected 16, got %0d",
                     uut.register_file_inst.registers[5]);
            failed = failed + 1;
        end

        // First JALR target = 45 & ~1 = 44
        if (uut.register_file_inst.registers[6] === 32'd42) begin
            $display("PASS: First JALR target = 44");
            passed = passed + 1;
        end else begin
            $display("FAIL: x6 expected 42, got %0d",
                     uut.register_file_inst.registers[6]);
            failed = failed + 1;
        end

        // x8 = 64
        if (uut.register_file_inst.registers[8] === 32'd64) begin
            $display("PASS: x8 = 64");
            passed = passed + 1;
        end else begin
            $display("FAIL: x8 expected 64, got %0d",
                     uut.register_file_inst.registers[8]);
            failed = failed + 1;
        end

        // Second JALR link address = 0x38
        if (uut.register_file_inst.registers[9] === 32'd56) begin
            $display("PASS: Second JALR link address = 56");
            passed = passed + 1;
        end else begin
            $display("FAIL: x9 expected 56, got %0d",
                     uut.register_file_inst.registers[9]);
            failed = failed + 1;
        end

        // x10 remains 8 because instruction was skipped
        if (uut.register_file_inst.registers[10] === 32'd8) begin
            $display("PASS: Second JALR skipped instruction");
            passed = passed + 1;
        end else begin
            $display("FAIL: x10 expected 8, got %0d",
                     uut.register_file_inst.registers[10]);
            failed = failed + 1;
        end

        // Final instruction writes x11 = 77
        if (uut.register_file_inst.registers[11] === 32'd77) begin
            $display("PASS: Second JALR target executed");
            passed = passed + 1;
        end else begin
            $display("FAIL: x11 expected 77, got %0d",
                     uut.register_file_inst.registers[11]);
            failed = failed + 1;
        end

        // Final PC = 0x44 = 68
        if (uut.pc === 32'd68) begin
            $display("PASS: Final PC = 0x44");
            passed = passed + 1;
        end else begin
            $display("FAIL: Final PC expected 68, got %0d",
                     uut.pc);
            failed = failed + 1;
        end

        // No illegal instruction
        if (uut.control_illegal === 1'b0) begin
            $display("PASS: No illegal instruction");
            passed = passed + 1;
        end else begin
            $display("FAIL: Illegal instruction detected");
            failed = failed + 1;
        end

        $display("\nPASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL JALR TESTS PASSED");
        else
            $display("JALR TESTS FAILED");

        $finish;
    end

endmodule
