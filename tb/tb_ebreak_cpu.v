
`timescale 1ns/1ps

module tb_ebreak_cpu;

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
        .PROGRAM_FILE("programs/ebreak_test.hex")
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

        $display("\n===== EBREAK CPU TEST =====");

        #20;
        reset = 0;

        repeat (20) begin
            @(posedge clk);
            #1;
            $display("PC=%h INST=%h", pc_debug, instruction_debug);
        end

        $display("\n----- CHECKING RESULTS -----");

        check(uut.mtvec == 32'h20, "MTVEC configured");
        check(uut.mcause == 32'd3, "EBREAK cause equals 3");
        check(uut.mepc == 32'd12, "MEPC advanced by handler");
        check(uut.register_file_inst.registers[6] == 32'd3,
              "Handler reads breakpoint cause");
        check(uut.register_file_inst.registers[7] == 32'd12,
              "Handler reads and updates MEPC");
        check(uut.register_file_inst.registers[5] == 32'd99,
              "Execution resumes after EBREAK");
        check(uut.mtval == 32'd0, "EBREAK MTVAL equals zero");
        check(pc_debug == 32'h10, "CPU reaches expected loop");

        $display("\nPASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL EBREAK TESTS PASSED");
        else
            $display("EBREAK TESTS FAILED");

        $finish;
    end

endmodule
