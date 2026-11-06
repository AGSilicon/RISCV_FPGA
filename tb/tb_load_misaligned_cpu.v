
`timescale 1ns/1ps

module tb_load_misaligned_cpu;

    reg clk;
    reg reset;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire instruction_valid_debug;
    wire illegal_instruction;

    integer passed;
    integer failed;

    riscv_cpu #(
        .IMEM_DEPTH(64),
        .DMEM_DEPTH(256),
        .PROGRAM_WORDS(21),
        .PROGRAM_FILE("programs/load_misaligned_test.hex")
    ) uut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .instruction_valid_debug(instruction_valid_debug),
        .illegal_instruction(illegal_instruction)
    );

    always #5 clk = ~clk;

    task check;
        input condition;
        input [8*60-1:0] test_name;
        begin
            if (condition === 1'b1) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        passed = 0;
        failed = 0;

        // Initialize destination register with a known value.
        // The misaligned load must not overwrite this value.
        uut.register_file_inst.registers[2] = 32'h12345678;

        $display("\n===== LOAD MISALIGNED CPU TEST =====");

        #20;
        reset = 0;

        // Execute the program and print the CPU trace.
        repeat (22) begin
            @(posedge clk);
            #1;
            $display("PC=%h INST=%h", pc_debug, instruction_debug);
        end

        $display("\n--------- CHECKING RESULTS ---------");

        check(
            uut.mtvec == 32'h40,
            "MTVEC configured"
        );

        check(
            uut.mcause == 32'd4,
            "Load misaligned cause equals 4"
        );

        check(
            uut.mtval == 32'h41,
            "MTVAL contains faulting address"
        );

        check(
            uut.mepc == 32'h10,
            "MEPC updated by handler to 0x10"
        );

        check(
            uut.register_file_inst.registers[2] == 32'h12345678,
            "Faulting load preserves destination register"
        );

        check(
            uut.register_file_inst.registers[6] == 32'd4,
            "Handler reads load fault cause"
        );

        check(
            uut.register_file_inst.registers[5] == 32'd99,
            "Execution resumes after fault"
        );

        check(
            pc_debug == 32'h14,
            "CPU reaches expected loop at 0x14"
        );

        $display("\n====================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("====================================");

        if (failed == 0)
            $display("ALL LOAD MISALIGNED TESTS PASSED");
        else
            $display("LOAD MISALIGNED TESTS FAILED");

        $finish;
    end

endmodule
