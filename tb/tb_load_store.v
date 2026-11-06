
`timescale 1ns/1ps

module tb_load_store;

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
        .PROGRAM_WORDS(17),
        .PROGRAM_FILE("programs/load_store_test.hex")
    ) uut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .instruction_valid_debug(instruction_valid_debug),
        .illegal_instruction(illegal_instruction)
    );

    always #5 clk = ~clk;

    task check_register;
        input integer reg_num;
        input [31:0] expected;
        input [8*40-1:0] test_name;

        begin
            if (uut.register_file_inst.registers[reg_num] === expected) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | Expected=%h Actual=%h",
                    test_name,
                    expected,
                    uut.register_file_inst.registers[reg_num]);
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;
        passed = 0;
        failed = 0;

        #20;
        reset = 0;

        // Execute 17 instructions
        for (i = 0; i < 17; i = i + 1)
            @(posedge clk);

        #1;

        $display("\n======= INTEGRATED LOAD/STORE TEST =======");

        // Initial full word load
        check_register(2, 32'hA1B2C3D4, "Initialize source word");

        // LB
        check_register(3, 32'hFFFFFFD4, "LB signed byte");

        // LBU
        check_register(4, 32'h000000D4, "LBU unsigned byte");

        // LB at byte offset 1
        check_register(5, 32'hFFFFFFC3, "LB byte offset 1");

        // LH
        check_register(6, 32'hFFFFC3D4, "LH signed halfword");

        // LHU
        check_register(7, 32'h0000A1B2, "LHU unsigned halfword");

        // LW
        check_register(8, 32'hA1B2C3D4, "LW full word");

        // SB source
        check_register(9, 32'h0000007E, "Prepare SB data");

        // Updated word after SB and SH
        check_register(11, 32'hC3D47ED4, "LW after SB and SH");

        // LB after byte update
        check_register(12, 32'hFFFFFFD4, "LB after stores");

        // LBU at byte offset 1
        check_register(13, 32'h0000007E, "LBU after SB");

        // LH at offset 2
        check_register(14, 32'hFFFFC3D4, "LH after SH");

        // Direct memory verification
        if (uut.data_memory_inst.memory[0] === 32'hC3D47ED4) begin
            $display("PASS: Data memory word updated correctly");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Data memory expected C3D47ED4, got %h",
                uut.data_memory_inst.memory[0]);
            failed = failed + 1;
        end

        // Final PC = 17 * 4 = 68
        if (pc_debug === 32'd68) begin
            $display("PASS: All 17 instructions executed");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: Final PC expected 68, got %0d", pc_debug);
            failed = failed + 1;
        end

        $display("\n======= FINAL RESULTS =======");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL INTEGRATED LOAD/STORE TESTS PASSED");
        else
            $display("LOAD/STORE TESTS FAILED");

        $finish;

    end

endmodule
