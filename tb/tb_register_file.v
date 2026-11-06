`timescale 1ns/1ps

module tb_register_file;

    reg clk;

    reg [4:0] read_addr1;
    reg [4:0] read_addr2;

    reg write_enable;
    reg [4:0] write_addr;
    reg [31:0] write_data;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    integer passed;
    integer failed;

    // Register File instantiation
    register_file uut (
        .clk(clk),

        .read_addr1(read_addr1),
        .read_data1(read_data1),

        .read_addr2(read_addr2),
        .read_data2(read_data2),

        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    // 10 ns clock period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Write operation
    task write_register;
        input [4:0] address;
        input [31:0] data;
        begin
            @(negedge clk);
            write_enable = 1;
            write_addr = address;
            write_data = data;

            @(posedge clk);
            #1;
            write_enable = 0;
        end
    endtask

    // Read and check both ports
    task check_read;
        input [4:0] address1;
        input [4:0] address2;
        input [31:0] expected1;
        input [31:0] expected2;

        begin
            read_addr1 = address1;
            read_addr2 = address2;

            #1;

            if ((read_data1 === expected1) &&
                (read_data2 === expected2)) begin

                $display(
                    "PASS | R1=x%0d DATA1=%h | R2=x%0d DATA2=%h",
                    address1, read_data1,
                    address2, read_data2
                );

                passed = passed + 1;
            end
            else begin

                $display(
                    "FAIL | R1=x%0d EXPECTED=%h ACTUAL=%h | R2=x%0d EXPECTED=%h ACTUAL=%h",
                    address1, expected1, read_data1,
                    address2, expected2, read_data2
                );

                failed = failed + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("wave/register_file.vcd");
        $dumpvars(0, tb_register_file);

        passed = 0;
        failed = 0;

        clk = 0;
        read_addr1 = 0;
        read_addr2 = 0;
        write_enable = 0;
        write_addr = 0;
        write_data = 0;

        $display("------------------------------------------");
        $display("     REGISTER FILE TEST STARTED");
        $display("------------------------------------------");

        // Test 1: x0 must always return zero
        check_read(5'd0, 5'd0, 32'd0, 32'd0);

        // Test 2: Write 10 into x1
        write_register(5'd1, 32'd10);
        check_read(5'd1, 5'd0, 32'd10, 32'd0);

        // Test 3: Write 20 into x2
        write_register(5'd2, 32'd20);
        check_read(5'd1, 5'd2, 32'd10, 32'd20);

        // Test 4: Write 30 into x3
        write_register(5'd3, 32'd30);
        check_read(5'd3, 5'd1, 32'd30, 32'd10);

        // Test 5: Attempt to write 100 into x0
        write_register(5'd0, 32'd100);
        check_read(5'd0, 5'd1, 32'd0, 32'd10);

        // Test 6: Overwrite x1 with 50
        write_register(5'd1, 32'd50);
        check_read(5'd1, 5'd2, 32'd50, 32'd20);

        // Test 7: Write to x31
        write_register(5'd31, 32'hABCDEF12);
        check_read(5'd31, 5'd3,
                   32'hABCDEF12, 32'd30);

        // Test 8: Write disabled - x2 must remain unchanged
        @(negedge clk);
        write_enable = 0;
        write_addr = 5'd2;
        write_data = 32'd999;

        @(posedge clk);
        #1;

        check_read(5'd2, 5'd31,
                   32'd20, 32'hABCDEF12);

        $display("------------------------------------------");
        $display("REGISTER FILE TEST SUMMARY");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("------------------------------------------");

        if (failed == 0)
            $display("ALL REGISTER FILE TESTS PASSED");
        else
            $display("REGISTER FILE TEST FAILED");

        $finish;

    end

endmodule
