
`timescale 1ns/1ps

module tb_illegal_instruction_cpu;

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
        .PROGRAM_WORDS(13),
        .PROGRAM_FILE("programs/illegal_instruction_test.hex")
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
        input [8*45-1:0] test_name;
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

        $display("\n===== ILLEGAL INSTRUCTION CPU TEST =====");

        #20;
        reset = 0;

        repeat (20) begin
            @(posedge clk);
            #1;
            $display(
                "PC=%h INST=%h ILLEGAL=%b",
                pc_debug,
                instruction_debug,
                illegal_instruction
            );
        end

        $display("\n--------- CHECKING RESULTS ---------");

        check(uut.mtvec == 32'h20,
              "MTVEC configured");

        check(uut.mcause == 32'd2,
              "Illegal instruction cause equals 2");

        check(uut.mtval == 32'hFFFFFFFF,
              "MTVAL contains offending instruction");

        check(uut.mepc == 32'd12,
              "MEPC advanced by handler");

        check(uut.register_file_inst.registers[6] == 32'd2,
              "Handler reads illegal instruction cause");

        check(uut.register_file_inst.registers[7] == 32'd12,
              "Handler calculates return address");

        check(uut.register_file_inst.registers[5] == 32'd99,
              "Execution resumes after illegal instruction");

        check(pc_debug == 32'h10,
              "CPU reaches expected loop");

        $display("\n====================================");
        $display(" ILLEGAL INSTRUCTION TEST RESULTS");
        $display("====================================");

        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL ILLEGAL INSTRUCTION TESTS PASSED");
        else
            $display("ILLEGAL INSTRUCTION TEST FAILED");

        $finish;

    end

endmodule
