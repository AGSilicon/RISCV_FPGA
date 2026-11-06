
`timescale 1ns/1ps

module tb_csr_trap_cpu;

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
        .PROGRAM_WORDS(20),
        .PROGRAM_FILE("programs/csr_trap_test.hex")
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

        $dumpfile("wave/csr_trap_cpu.vcd");
        $dumpvars(0, tb_csr_trap_cpu);

        $display("\n====================================");
        $display(" CSR + TRAP CPU INTEGRATION TEST");
        $display("====================================");

        #20;
        reset = 0;

        // Allow program, trap handler and MRET to execute.
        repeat (25) begin
            @(posedge clk);
            #1;
            $display(
                "PC=%h INST=%h",
                pc_debug,
                instruction_debug
            );
        end

        $display("\n--------- CHECKING RESULTS ---------");

        check(
            uut.register_file_inst.registers[1] == 32'h40,
            "x1 contains mtvec address"
        );

        check(
            uut.mtvec == 32'h40,
            "MTVEC configured correctly"
        );

        check(
            uut.mcause == 32'd11,
            "ECALL cause is 11"
        );

        check(
            uut.register_file_inst.registers[6] == 32'd11,
            "Handler reads mcause into x6"
        );

        check(
            uut.register_file_inst.registers[7] == 32'd12,
            "Handler prepares return address"
        );

        check(
            uut.mepc == 32'd12,
            "MEPC updated to return address"
        );

        check(
            uut.register_file_inst.registers[5] == 32'd99,
            "Execution resumes after MRET"
        );

        check(
            uut.mtval == 32'd0,
            "ECALL mtval is zero"
        );

        check(
            pc_debug == 32'h10,
            "CPU reaches post-MRET infinite loop"
        );

        check(
            uut.mstatus[7] == 1'b1,
            "MRET sets MPIE"
        );

        check(
            uut.mstatus[3] == 1'b0,
            "MRET restores MIE from MPIE"
        );

        $display("\n====================================");
        $display(" CSR + TRAP CPU TEST RESULTS");
        $display("====================================");

        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL CSR + TRAP CPU TESTS PASSED");
        else
            $display("CSR + TRAP CPU TEST FAILED");

        $display("====================================");

        $finish;

    end

endmodule
