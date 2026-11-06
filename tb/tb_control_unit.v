`timescale 1ns/1ps

module tb_control_unit;

    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire alu_a_src;

    wire [3:0] alu_control;
    wire [2:0] imm_sel;

    wire branch;
    wire branch_ne;
    wire jump;

    wire [1:0] result_src;
    wire illegal;

    integer passed;
    integer failed;

    // Control Unit instantiation
    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .alu_src(alu_src),
        .alu_a_src(alu_a_src),

        .alu_control(alu_control),
        .imm_sel(imm_sel),

        .branch(branch),
        .branch_ne(branch_ne),
        .jump(jump),

        .result_src(result_src),
        .illegal(illegal)
    );

    // Check all 18 output bits together
    task check_instruction;

        input [80*8-1:0] instruction_name;
        input [6:0] op;
        input [2:0] f3;
        input [6:0] f7;
        input [17:0] expected;

        reg [17:0] actual;

        begin

            opcode = op;
            funct3 = f3;
            funct7 = f7;

            #10;

            actual = {
                reg_write,
                mem_read,
                mem_write,
                alu_src,
                alu_a_src,
                alu_control,
                imm_sel,
                branch,
                branch_ne,
                jump,
                result_src,
                illegal
            };

            if (actual === expected) begin

                $display(
                    "PASS | %0s | OPCODE=%b | ALU=%b | IMM=%b",
                    instruction_name,
                    opcode,
                    alu_control,
                    imm_sel
                );

                passed = passed + 1;

            end
            else begin

                $display(
                    "FAIL | %0s | EXPECTED=%b | ACTUAL=%b",
                    instruction_name,
                    expected,
                    actual
                );

                failed = failed + 1;

            end

        end

    endtask

    initial begin

        $dumpfile("wave/control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        passed = 0;
        failed = 0;

        opcode = 0;
        funct3 = 0;
        funct7 = 0;

        $display("------------------------------------------");
        $display("       CONTROL UNIT TEST STARTED");
        $display("------------------------------------------");

        // R-type ADD
        check_instruction(
            "ADD",
            7'b0110011, 3'b000, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // R-type SUB
        check_instruction(
            "SUB",
            7'b0110011, 3'b000, 7'b0100000,
            {1'b1,1'b0,1'b0,1'b0,1'b0,
             4'b0001,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // R-type AND
        check_instruction(
            "AND",
            7'b0110011, 3'b111, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b0,1'b0,
             4'b0010,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // I-type ADDI
        check_instruction(
            "ADDI",
            7'b0010011, 3'b000, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b1,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // I-type ANDI
        check_instruction(
            "ANDI",
            7'b0010011, 3'b111, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b1,1'b0,
             4'b0010,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // LW
        check_instruction(
            "LW",
            7'b0000011, 3'b010, 7'b0000000,
            {1'b1,1'b1,1'b0,1'b1,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b01,1'b0}
        );

        // SW
        check_instruction(
            "SW",
            7'b0100011, 3'b010, 7'b0000000,
            {1'b0,1'b0,1'b1,1'b1,1'b0,
             4'b0000,3'b001,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // BEQ
        check_instruction(
            "BEQ",
            7'b1100011, 3'b000, 7'b0000000,
            {1'b0,1'b0,1'b0,1'b0,1'b0,
             4'b0001,3'b010,1'b1,1'b0,1'b0,
             2'b00,1'b0}
        );

        // BNE
        check_instruction(
            "BNE",
            7'b1100011, 3'b001, 7'b0000000,
            {1'b0,1'b0,1'b0,1'b0,1'b0,
             4'b0001,3'b010,1'b1,1'b1,1'b0,
             2'b00,1'b0}
        );

        // LUI
        check_instruction(
            "LUI",
            7'b0110111, 3'b000, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b011,1'b0,1'b0,1'b0,
             2'b10,1'b0}
        );

        // AUIPC
        check_instruction(
            "AUIPC",
            7'b0010111, 3'b000, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b1,1'b1,
             4'b0000,3'b011,1'b0,1'b0,1'b0,
             2'b00,1'b0}
        );

        // JAL
        check_instruction(
            "JAL",
            7'b1101111, 3'b000, 7'b0000000,
            {1'b1,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b100,1'b0,1'b0,1'b1,
             2'b11,1'b0}
        );

        // Invalid opcode
        check_instruction(
            "INVALID OPCODE",
            7'b1111111, 3'b000, 7'b0000000,
            {1'b0,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b1}
        );

        // Invalid load width
        check_instruction(
            "INVALID LOAD",
            7'b0000011, 3'b000, 7'b0000000,
            {1'b0,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b1}
        );

        // Invalid R-type funct7
        check_instruction(
            "INVALID R-TYPE",
            7'b0110011, 3'b000, 7'b0000001,
            {1'b0,1'b0,1'b0,1'b0,1'b0,
             4'b0000,3'b000,1'b0,1'b0,1'b0,
             2'b00,1'b1}
        );

        $display("------------------------------------------");
        $display("CONTROL UNIT TEST SUMMARY");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("------------------------------------------");

        if (failed == 0)
            $display("ALL CONTROL UNIT TESTS PASSED");
        else
            $display("CONTROL UNIT TEST FAILED");

        $finish;

    end

endmodule
