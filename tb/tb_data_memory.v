
`timescale 1ns/1ps

module tb_data_memory;

    reg clk;
    reg mem_read;
    reg mem_write;
    reg [31:0] address;
    reg [31:0] write_data;
    reg [1:0] mem_size;
    reg load_unsigned;

    wire [31:0] read_data;
    wire address_valid;

    integer passed;
    integer failed;

    data_memory #(
        .DEPTH(256)
    ) uut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned),
        .read_data(read_data),
        .address_valid(address_valid)
    );

    always #5 clk = ~clk;

    task write_mem;
        input [31:0] addr;
        input [31:0] data;
        input [1:0] size;

        begin
            @(negedge clk);
            address = addr;
            write_data = data;
            mem_size = size;
            mem_write = 1;
            mem_read = 0;

            @(posedge clk);
            #1;
            mem_write = 0;
        end
    endtask

    task check_read;
        input [31:0] addr;
        input [1:0] size;
        input unsigned_mode;
        input [31:0] expected;
        input [8*40-1:0] test_name;

        begin
            @(negedge clk);
            address = addr;
            mem_size = size;
            load_unsigned = unsigned_mode;
            mem_read = 1;
            mem_write = 0;

            #1;

            if (read_data === expected && address_valid) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | Expected=%h Actual=%h Valid=%b",
                         test_name, expected, read_data, address_valid);
                failed = failed + 1;
            end

            mem_read = 0;
        end
    endtask

    task check_invalid;
        input [31:0] addr;
        input [1:0] size;
        input [8*40-1:0] test_name;

        begin
            @(negedge clk);
            address = addr;
            mem_size = size;
            mem_read = 1;
            mem_write = 0;

            #1;

            if (!address_valid && read_data === 32'h00000000) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | Valid=%b Data=%h",
                         test_name, address_valid, read_data);
                failed = failed + 1;
            end

            mem_read = 0;
        end
    endtask

    initial begin

        clk = 0;
        mem_read = 0;
        mem_write = 0;
        address = 0;
        write_data = 0;
        mem_size = 2'b10;
        load_unsigned = 0;

        passed = 0;
        failed = 0;

        #10;

        $display("\n======= DATA MEMORY TEST START =======");

        // Initialize word 0
        write_mem(32'd0, 32'hA1B2C3D4, 2'b10);

        // LB and LBU
        check_read(0, 2'b00, 0, 32'hFFFFFFD4, "LB byte 0 signed");
        check_read(0, 2'b00, 1, 32'h000000D4, "LBU byte 0 unsigned");
        check_read(1, 2'b00, 0, 32'hFFFFFFC3, "LB byte 1 signed");
        check_read(2, 2'b00, 1, 32'h000000B2, "LBU byte 2 unsigned");
        check_read(3, 2'b00, 1, 32'h000000A1, "LBU byte 3 unsigned");

        // LH and LHU
        check_read(0, 2'b01, 0, 32'hFFFFC3D4, "LH lower half signed");
        check_read(2, 2'b01, 1, 32'h0000A1B2, "LHU upper half unsigned");

        // LW
        check_read(0, 2'b10, 0, 32'hA1B2C3D4, "LW full word");

        // SB: replace byte 1 with 0x7E
        write_mem(1, 32'h0000007E, 2'b00);
        check_read(0, 2'b10, 0, 32'hA1B27ED4, "SB byte lane update");

        // SH: replace upper halfword with 0x5566
        write_mem(2, 32'h00005566, 2'b01);
        check_read(0, 2'b10, 0, 32'h55667ED4, "SH halfword update");

        // Store another word
        write_mem(4, 32'h80017FFF, 2'b10);
        check_read(4, 2'b10, 0, 32'h80017FFF, "SW second word");

        // Signed halfword checks
        check_read(4, 2'b01, 0, 32'h00007FFF, "LH positive halfword");
        check_read(6, 2'b01, 0, 32'hFFFF8001, "LH negative halfword");

        // Alignment checks
        check_invalid(1, 2'b01, "Reject misaligned LH");
        check_invalid(2, 2'b10, "Reject misaligned LW");

        // Out-of-range check
        check_invalid(1024, 2'b10, "Reject out-of-range LW");

        $display("\n======= DATA MEMORY RESULTS =======");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);

        if (failed == 0)
            $display("ALL DATA MEMORY TESTS PASSED");
        else
            $display("DATA MEMORY TESTS FAILED");

        $finish;

    end

endmodule
