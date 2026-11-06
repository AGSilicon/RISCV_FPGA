
`timescale 1ns/1ps

module tb_csr_file;

    reg clk;
    reg reset;

    reg [11:0] csr_addr;
    wire [31:0] csr_read_data;
    wire csr_valid;

    reg csr_write_enable;
    reg [31:0] csr_write_data;

    reg trap_enter;
    reg [31:0] trap_pc;
    reg [31:0] trap_cause;
    reg [31:0] trap_value;

    reg mret;

    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire [31:0] mcause;
    wire [31:0] mtval;
    wire [31:0] mstatus;

    integer passed;
    integer failed;

    // -----------------------------------------
    // DUT
    // -----------------------------------------

    csr_file uut (
        .clk(clk),
        .reset(reset),

        .csr_addr(csr_addr),
        .csr_read_data(csr_read_data),
        .csr_valid(csr_valid),

        .csr_write_enable(csr_write_enable),
        .csr_write_data(csr_write_data),

        .trap_enter(trap_enter),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),
        .trap_value(trap_value),

        .mret(mret),

        .mtvec(mtvec),
        .mepc(mepc),
        .mcause(mcause),
        .mtval(mtval),
        .mstatus(mstatus)
    );

    always #5 clk = ~clk;

    // -----------------------------------------
    // CHECK TASK
    // -----------------------------------------

    task check_value;

        input [31:0] actual;
        input [31:0] expected;
        input [8*40-1:0] test_name;

        begin

            if (actual === expected) begin

                $display("PASS: %0s", test_name);
                passed = passed + 1;

            end
            else begin

                $display(
                    "FAIL: %0s | Expected=%h Actual=%h",
                    test_name,
                    expected,
                    actual
                );

                failed = failed + 1;

            end

        end

    endtask

    // -----------------------------------------
    // CSR WRITE TASK
    // -----------------------------------------

    task write_csr;

        input [11:0] address;
        input [31:0] value;

        begin

            @(negedge clk);

            csr_addr = address;
            csr_write_data = value;
            csr_write_enable = 1'b1;

            @(posedge clk);
            #1;

            csr_write_enable = 1'b0;

        end

    endtask

    // -----------------------------------------
    // TEST SEQUENCE
    // -----------------------------------------

    initial begin

        clk = 0;
        reset = 1;

        csr_addr = 0;
        csr_write_enable = 0;
        csr_write_data = 0;

        trap_enter = 0;
        trap_pc = 0;
        trap_cause = 0;
        trap_value = 0;

        mret = 0;

        passed = 0;
        failed = 0;

        #12;
        reset = 0;

        $display("\n====================================");
        $display("       CSR FILE TEST START");
        $display("====================================");

        // -------------------------------------
        // TEST 1: RESET VALUES
        // -------------------------------------

        check_value(
            mtvec,
            32'h00000000,
            "MTVEC reset"
        );

        check_value(
            mepc,
            32'h00000000,
            "MEPC reset"
        );

        check_value(
            mstatus,
            32'h00001800,
            "MSTATUS reset"
        );

        // -------------------------------------
        // TEST 2: MTVEC WRITE
        // -------------------------------------

        write_csr(
            12'h305,
            32'h00000101
        );

        check_value(
            mtvec,
            32'h00000101,
            "MTVEC write"
        );

        // -------------------------------------
        // TEST 3: MEPC WRITE
        // -------------------------------------

        write_csr(
            12'h341,
            32'h00000024
        );

        check_value(
            mepc,
            32'h00000024,
            "MEPC write"
        );

        // -------------------------------------
        // TEST 4: MCAUSE WRITE
        // -------------------------------------

        write_csr(
            12'h342,
            32'd11
        );

        check_value(
            mcause,
            32'd11,
            "MCAUSE write"
        );

        // -------------------------------------
        // TEST 5: MTVAL WRITE
        // -------------------------------------

        write_csr(
            12'h343,
            32'hFFFFFFFF
        );

        check_value(
            mtval,
            32'hFFFFFFFF,
            "MTVAL write"
        );

        // -------------------------------------
        // TEST 6: CSR READ
        // -------------------------------------

        @(negedge clk);

        csr_addr = 12'h305;

        #1;

        check_value(
            csr_read_data,
            32'h00000101,
            "CSR read MTVEC"
        );

        // -------------------------------------
        // TEST 7: VALID CSR ADDRESS
        // -------------------------------------

        if (csr_valid === 1'b1) begin

            $display("PASS: Valid CSR address");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Valid CSR address");
            failed = failed + 1;

        end

        // -------------------------------------
        // TEST 8: INVALID CSR ADDRESS
        // -------------------------------------

        csr_addr = 12'h777;

        #1;

        if (csr_valid === 1'b0) begin

            $display("PASS: Invalid CSR rejected");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Invalid CSR accepted");
            failed = failed + 1;

        end

        // -------------------------------------
        // TEST 9: ENABLE MIE AND MPIE
        // -------------------------------------

        write_csr(
            12'h300,
            32'h00000088
        );

        // -------------------------------------
        // TEST 10: TRAP ENTRY
        // -------------------------------------

        @(negedge clk);

        trap_pc = 32'h00000040;
        trap_cause = 32'd11;
        trap_value = 32'h00000073;

        trap_enter = 1'b1;

        @(posedge clk);
        #1;

        trap_enter = 1'b0;

        check_value(
            mepc,
            32'h00000040,
            "Trap saves MEPC"
        );

        check_value(
            mcause,
            32'd11,
            "Trap saves MCAUSE"
        );

        check_value(
            mtval,
            32'h00000073,
            "Trap saves MTVAL"
        );

        // -------------------------------------
        // TEST 11: TRAP DISABLES MIE
        // -------------------------------------

        check_value(
            {31'b0, mstatus[3]},
            32'h00000000,
            "Trap disables MIE"
        );

        // -------------------------------------
        // TEST 12: TRAP SAVES MPIE
        // -------------------------------------

        check_value(
            {31'b0, mstatus[7]},
            32'h00000001,
            "Trap saves MPIE"
        );

        // -------------------------------------
        // TEST 13: MRET RESTORES MIE
        // -------------------------------------

        @(negedge clk);

        mret = 1'b1;

        @(posedge clk);
        #1;

        mret = 1'b0;

        check_value(
            {31'b0, mstatus[3]},
            32'h00000001,
            "MRET restores MIE"
        );

        // -------------------------------------
        // TEST 14: MRET SETS MPIE
        // -------------------------------------

        check_value(
            {31'b0, mstatus[7]},
            32'h00000001,
            "MRET sets MPIE"
        );

        // -------------------------------------
        // FINAL SUMMARY
        // -------------------------------------

        $display("\n====================================");
        $display("         CSR FILE RESULTS");
        $display("====================================");

        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL CSR FILE TESTS PASSED");
        else
            $display("CSR FILE TESTS FAILED");

        $display("====================================");

        $finish;

    end

endmodule
