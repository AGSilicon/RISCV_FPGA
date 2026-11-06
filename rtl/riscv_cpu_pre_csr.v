
`timescale 1ns/1ps

module riscv_cpu #(
    parameter IMEM_DEPTH = 64,
    parameter DMEM_DEPTH = 256,
    parameter PROGRAM_WORDS = 9,
    parameter PROGRAM_FILE = "programs/cpu_test.hex"
)(
    input wire clk,
    input wire reset,

    output wire [31:0] pc_debug,
    output wire [31:0] instruction_debug,
    output wire instruction_valid_debug,
    output wire illegal_instruction
);

    // -----------------------------------------
    // 1. PROGRAM COUNTER
    // -----------------------------------------

    reg [31:0] next_pc;
    wire [31:0] pc;

    program_counter pc_inst (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    assign pc_debug = pc;

    // -----------------------------------------
    // 2. INSTRUCTION MEMORY
    // -----------------------------------------

    wire [31:0] instruction;
    wire instruction_valid;

    instruction_memory #(
        .DEPTH(IMEM_DEPTH),
        .INIT_WORDS(PROGRAM_WORDS),
        .INIT_FILE(PROGRAM_FILE)
    ) instruction_memory_inst (
        .address(pc),
        .instruction(instruction),
        .instruction_valid(instruction_valid)
    );

    assign instruction_debug = instruction;
    assign instruction_valid_debug = instruction_valid;

    // -----------------------------------------
    // 3. INSTRUCTION FIELDS
    // -----------------------------------------

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];

    // -----------------------------------------
    // 4. CONTROL UNIT
    // -----------------------------------------

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
    wire jalr;

    wire [1:0] result_src;

    wire [1:0] mem_size;
    wire load_unsigned;

    wire control_illegal;

    control_unit control_unit_inst (
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
        .jalr(jalr),

        .result_src(result_src),

        .mem_size(mem_size),
        .load_unsigned(load_unsigned),

        .illegal(control_illegal)
    );

    // -----------------------------------------
    // 5. REGISTER FILE
    // -----------------------------------------

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    reg [31:0] writeback_data;
    wire register_write_enable;

    // -----------------------------------------
    // 6. IMMEDIATE GENERATOR
    // -----------------------------------------

    wire [31:0] immediate;

    immediate_generator immediate_generator_inst (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    // -----------------------------------------
    // 7. ALU INPUTS
    // -----------------------------------------

    wire [31:0] alu_a;
    wire [31:0] alu_b;

    assign alu_a = alu_a_src ? pc : rs1_data;
    assign alu_b = alu_src ? immediate : rs2_data;

    // -----------------------------------------
    // 8. ALU
    // -----------------------------------------

    wire [31:0] alu_result;
    wire alu_zero;

    alu alu_inst (
        .A(alu_a),
        .B(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    // -----------------------------------------
    // 9. DATA MEMORY
    // -----------------------------------------

    wire [31:0] memory_read_data;
    wire memory_address_valid;

    wire data_mem_read_enable;
    wire data_mem_write_enable;

    wire memory_access_valid;

    assign memory_access_valid =
        !(mem_read || mem_write) ||
        memory_address_valid;

    assign data_mem_read_enable =
        mem_read &&
        !control_illegal &&
        instruction_valid &&
        memory_address_valid;

    assign data_mem_write_enable =
        mem_write &&
        !control_illegal &&
        instruction_valid &&
        memory_address_valid;

    data_memory #(
        .DEPTH(DMEM_DEPTH)
    ) data_memory_inst (
        .clk(clk),

        .mem_read(data_mem_read_enable),
        .mem_write(data_mem_write_enable),

        .address(alu_result),
        .write_data(rs2_data),

        .mem_size(mem_size),
        .load_unsigned(load_unsigned),

        .read_data(memory_read_data),
        .address_valid(memory_address_valid)
    );

    // -----------------------------------------
    // 10. REGISTER FILE
    // -----------------------------------------

    assign register_write_enable =
        reg_write &&
        !control_illegal &&
        instruction_valid &&
        memory_access_valid;

    register_file register_file_inst (
        .clk(clk),

        .read_addr1(rs1),
        .read_data1(rs1_data),

        .read_addr2(rs2),
        .read_data2(rs2_data),

        .write_enable(register_write_enable),
        .write_addr(rd),
        .write_data(writeback_data)
    );

    // -----------------------------------------
    // 11. WRITEBACK
    // -----------------------------------------

    always @(*) begin

        case (result_src)

            2'b00:
                writeback_data = alu_result;

            2'b01:
                writeback_data = memory_read_data;

            2'b10:
                writeback_data = immediate;

            2'b11:
                writeback_data = pc + 32'd4;

            default:
                writeback_data = 32'h00000000;

        endcase

    end

    // -----------------------------------------
    // 12. BRANCH COMPARATOR
    // -----------------------------------------

    reg branch_condition;

    always @(*) begin

        case (funct3)

            3'b000:
                branch_condition = (rs1_data == rs2_data);

            3'b001:
                branch_condition = (rs1_data != rs2_data);

            3'b100:
                branch_condition =
                    ($signed(rs1_data) < $signed(rs2_data));

            3'b101:
                branch_condition =
                    ($signed(rs1_data) >= $signed(rs2_data));

            3'b110:
                branch_condition = (rs1_data < rs2_data);

            3'b111:
                branch_condition = (rs1_data >= rs2_data);

            default:
                branch_condition = 0;

        endcase

    end

    wire branch_taken;

    assign branch_taken =
        branch &&
        branch_condition &&
        !control_illegal &&
        instruction_valid;

    // -----------------------------------------
    // 13. PC CALCULATIONS
    // -----------------------------------------

    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;
    wire [31:0] jalr_target;

    assign pc_plus_4 = pc + 32'd4;
    assign branch_target = pc + immediate;

    assign jalr_target =
        (rs1_data + immediate) & 32'hFFFFFFFE;

    // -----------------------------------------
    // 14. NEXT PC
    // -----------------------------------------

    always @(*) begin

        if (reset)
            next_pc = 32'h00000000;

        else if (!instruction_valid ||
                 control_illegal ||
                 !memory_access_valid)
            next_pc = pc_plus_4;

        else if (jump && jalr)
            next_pc = jalr_target;

        else if (jump)
            next_pc = branch_target;

        else if (branch_taken)
            next_pc = branch_target;

        else
            next_pc = pc_plus_4;

    end

    // -----------------------------------------
    // 15. ILLEGAL / INVALID ACCESS STATUS
    // -----------------------------------------

    assign illegal_instruction =
        (!instruction_valid) ||
        control_illegal ||
        !memory_access_valid;

endmodule
