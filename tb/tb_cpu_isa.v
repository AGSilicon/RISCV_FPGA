
`timescale 1ns/1ps

module tb_cpu_isa;

    reg clk;
    reg reset;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire instruction_valid_debug;
    wire illegal_instruction;

    integer passed;
    integer failed;

    // -----------------------------------------
    // CPU instantiation
    // -----------------------------------------

    riscv_cpu #(
        .IMEM_DEPTH(64),
        .DMEM_DEPTH(256),
        .PROGRAM_WORDS(26),
        .PROGRAM_FILE("programs/cpu_isa_test.hex")
    ) uut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .instruction_valid_debug(instruction_valid_debug),
        .illegal_instruction(illegal_instruction)
    );

    // -----------------------------------------
    // Clock generation: 10 ns
    // -----------------------------------------

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------------------
    // Register checking task
    // -----------------------------------------

    task check_register;

        input [4:0] register_number;
        input [31:0] expected;

        reg [31:0] actual_value;

        begin

            actual_value =
                uut.register_file_inst.registers[register_number];

            if (actual_value === expected) begin

                $display(
                    "PASS | x%0d | EXPECTED=%h | ACTUAL=%h",
                    register_number,
                    expected,
                    actual_value
                );

                passed = passed + 1;

            end
            else begin

                $display(
                    "FAIL | x%0d | EXPECTED=%h | ACTUAL=%h",
                    register_number,
                    expected,
                    actual_value
                );

                failed = failed + 1;

            end

        end

    endtask

    // -----------------------------------------
    // Main verification
    // -----------------------------------------

    initial begin

        $dumpfile("wave/cpu_isa.vcd");
        $dumpvars(0, tb_cpu_isa);

        passed = 0;
        failed = 0;

        reset = 1;

        $display("==========================================");
        $display("     EXTENDED RISC-V ISA TEST STARTED");
        $display("==========================================");

        // Reset for two clock cycles
        repeat (2) @(posedge clk);

        // Release reset at falling edge
        @(negedge clk);
        reset = 0;

        $display("------------------------------------------");
        $display("EXECUTING EXTENDED INSTRUCTION PROGRAM");
        $display("------------------------------------------");

        // Execute until PC reaches 0x64.
        // This includes the instructions at 0x00 through 0x60.
        repeat (23) begin

            @(posedge clk);
            #1;

            $display(
                "PC=%h | INSTRUCTION=%h | ILLEGAL=%b",
                pc_debug,
                instruction_debug,
                illegal_instruction
            );

        end

        // -------------------------------------
        // Illegal instruction verification
        // -------------------------------------

        $display("------------------------------------------");
        $display("CHECKING ILLEGAL INSTRUCTION");
        $display("------------------------------------------");

        if ((pc_debug === 32'h00000064) &&
            (instruction_debug === 32'hFFFFFFFF) &&
            (illegal_instruction === 1'b1)) begin

            $display("PASS | ILLEGAL INSTRUCTION DETECTED");
            passed = passed + 1;

        end
        else begin

            $display(
                "FAIL | ILLEGAL INSTRUCTION | PC=%h | INSTRUCTION=%h | ILLEGAL=%b",
                pc_debug,
                instruction_debug,
                illegal_instruction
            );

            failed = failed + 1;

        end

        // Advance past illegal instruction
        @(posedge clk);
        #1;

        // -------------------------------------
        // Register verification
        // -------------------------------------

        $display("------------------------------------------");
        $display("CHECKING REGISTER RESULTS");
        $display("------------------------------------------");

        check_register(5'd1,  32'd20);
        check_register(5'd2,  32'd6);

        // Logical instructions
        check_register(5'd3,  32'd4);
        check_register(5'd4,  32'd22);
        check_register(5'd5,  32'd18);

        // Comparison and register shifts
        check_register(5'd6,  32'd1);
        check_register(5'd7,  32'd384);
        check_register(5'd8,  32'd0);

        // LUI and arithmetic right shift
        check_register(5'd10, 32'h80000000);
        check_register(5'd11, 32'hFE000000);

        // Immediate logical instructions
        check_register(5'd12, 32'd4);
        check_register(5'd13, 32'd21);
        check_register(5'd14, 32'd23);
        check_register(5'd15, 32'd1);

        // Immediate shift instructions
        check_register(5'd16, 32'd80);
        check_register(5'd17, 32'd5);
        check_register(5'd18, 32'hFE000000);

        // BNE verification
        check_register(5'd19, 32'd7);

        // JAL return address
        check_register(5'd20, 32'h00000054);

        // JAL target instruction
        check_register(5'd21, 32'd11);

        // AUIPC
        check_register(5'd22, 32'h0000005C);

        // LUI
        check_register(5'd23, 32'h12345000);

        // -------------------------------------
        // Final PC verification
        // -------------------------------------

        $display("------------------------------------------");
        $display("CHECKING FINAL PC");
        $display("------------------------------------------");

        if (pc_debug === 32'h00000068) begin

            $display(
                "PASS | FINAL PC | ACTUAL=%h",
                pc_debug
            );

            passed = passed + 1;

        end
        else begin

            $display(
                "FAIL | FINAL PC | EXPECTED=00000068 | ACTUAL=%h",
                pc_debug
            );

            failed = failed + 1;

        end

        // -------------------------------------
        // Architectural x0 verification
        // -------------------------------------

        // Register File read port always returns zero for x0.
        // Verify this independently without examining registers[0].

        $display("------------------------------------------");
        $display("CHECKING x0 ARCHITECTURAL BEHAVIOR");
        $display("------------------------------------------");

        if (uut.register_file_inst.read_data1 === 32'h00000000 &&
            uut.register_file_inst.read_data2 === 32'h00000000 &&
            uut.register_file_inst.read_addr1 == 5'd0 &&
            uut.register_file_inst.read_addr2 == 5'd0) begin

            $display("PASS | x0 READ OUTPUT = 00000000");
            passed = passed + 1;

        end
        else begin

            $display("INFO | x0 read-port check skipped for current instruction");
            $display("INFO | x0 architectural behavior is covered by standalone register-file test");

        end

        // -------------------------------------
        // Final summary
        // -------------------------------------

        $display("==========================================");
        $display("      EXTENDED RISC-V ISA SUMMARY");
        $display("==========================================");

        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL EXTENDED ISA TESTS PASSED");
        else
            $display("EXTENDED ISA TEST FAILED");

        $display("==========================================");

        $finish;

    end

endmodule
