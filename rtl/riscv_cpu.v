
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

    // =====================================================
    // 1. PROGRAM COUNTER
    // =====================================================

    reg [31:0] next_pc;
    wire [31:0] pc;

    program_counter pc_inst (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    assign pc_debug = pc;

    // =====================================================
    // 2. INSTRUCTION MEMORY
    // =====================================================

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

    // =====================================================
    // 3. INSTRUCTION FIELDS
    // =====================================================

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

    // =====================================================
    // 4. NORMAL CONTROL UNIT
    // =====================================================

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

    // =====================================================
    // 5. SYSTEM INSTRUCTION DECODER
    // =====================================================

    wire is_system;
    wire is_csr;
    wire ecall;
    wire ebreak;
    wire mret;
    wire fence;
    wire system_illegal;

    system_instruction_unit system_instruction_inst (
        .instruction(instruction),

        .is_system(is_system),
        .is_csr(is_csr),
        .ecall(ecall),
        .ebreak(ebreak),
        .mret(mret),
        .fence(fence),
        .illegal(system_illegal)
    );

    // =====================================================
    // 6. REGISTER FILE
    // =====================================================

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    reg [31:0] writeback_data;
    wire register_write_enable;

    // =====================================================
    // 7. IMMEDIATE GENERATOR
    // =====================================================

    wire [31:0] immediate;

    immediate_generator immediate_generator_inst (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    // =====================================================
    // 8. ALU
    // =====================================================

    wire [31:0] alu_a;
    wire [31:0] alu_b;

    assign alu_a = alu_a_src ? pc : rs1_data;
    assign alu_b = alu_src ? immediate : rs2_data;

    wire [31:0] alu_result;
    wire alu_zero;

    alu alu_inst (
        .A(alu_a),
        .B(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    // =====================================================
    // 9. CSR FILE
    // =====================================================

    wire [11:0] csr_addr;
    wire [31:0] csr_read_data;
    wire csr_valid;

    wire csr_write_enable_raw;
    wire [31:0] csr_write_data;

    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire [31:0] mcause;
    wire [31:0] mtval;
    wire [31:0] mstatus;

    wire csr_rd_write_enable;
    wire [31:0] csr_rd_write_data;

    wire csr_decoder_illegal;

    wire csr_write_enable;
    wire mret_execute;

    // =====================================================
    // 10. CSR INSTRUCTION UNIT
    // =====================================================

    csr_instruction_unit csr_instruction_inst (
        .instruction(instruction),
        .rs1_data(rs1_data),
        .csr_read_data(csr_read_data),
        .csr_valid(csr_valid),

        .csr_addr(csr_addr),
        .csr_read_enable(),
        .csr_write_enable(csr_write_enable_raw),
        .csr_write_data(csr_write_data),

        .rd_write_enable(csr_rd_write_enable),
        .rd_write_data(csr_rd_write_data),

        .illegal(csr_decoder_illegal)
    );

    // =====================================================
    // 11. BRANCH COMPARATOR
    // =====================================================

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
                branch_condition = 1'b0;

        endcase
    end

    // =====================================================
    // 12. PC TARGET CALCULATIONS
    // =====================================================

    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;
    wire [31:0] jalr_target;

    assign pc_plus_4 = pc + 32'd4;
    assign branch_target = pc + immediate;

    // RISC-V JALR clears bit zero.
    assign jalr_target =
        (rs1_data + immediate) & 32'hFFFFFFFE;

    wire branch_taken;

    assign branch_taken =
        branch &&
        branch_condition &&
        instruction_valid;

    wire control_transfer;
    wire [31:0] control_target;

    assign control_transfer =
        (jump && !jalr) ||
        (jump && jalr) ||
        branch_taken;

    assign control_target =
        (jump && jalr) ? jalr_target : branch_target;

    wire target_misaligned;

    assign target_misaligned =
        control_transfer &&
        (control_target[1:0] != 2'b00);

    // =====================================================
    // 13. DATA MEMORY AND FAULT DETECTION
    // =====================================================

    wire [31:0] memory_read_data;
    wire memory_address_valid;

    wire data_range_valid;
    reg data_misaligned;

    wire memory_access_valid;

    wire data_mem_read_enable;
    wire data_mem_write_enable;

    assign data_range_valid =
        (alu_result[31:2] < DMEM_DEPTH);

    always @(*) begin
        data_misaligned = 1'b0;

        case (mem_size)

            2'b00:
                data_misaligned = 1'b0;

            2'b01:
                data_misaligned = alu_result[0];

            2'b10:
                data_misaligned = (alu_result[1:0] != 2'b00);

            default:
                data_misaligned = 1'b1;

        endcase
    end

    assign memory_access_valid =
        !(mem_read || mem_write) ||
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

    // =====================================================
    // 14. EXCEPTION CLASSIFICATION
    // =====================================================

    wire is_fence_opcode;

    assign is_fence_opcode =
        (opcode == 7'b0001111);

    wire decoded_illegal;

    assign decoded_illegal =
        is_system
            ? (is_csr ? csr_decoder_illegal : system_illegal)
            : (is_fence_opcode ? system_illegal : control_illegal);

    wire fetch_misaligned;
    wire fetch_access_fault;

    assign fetch_misaligned =
        (pc[1:0] != 2'b00);

    assign fetch_access_fault =
        instruction_valid == 1'b0 &&
        !fetch_misaligned;

    wire illegal_exception;

    assign illegal_exception =
        instruction_valid &&
        decoded_illegal;

    wire breakpoint_exception;
    wire ecall_exception;

    assign breakpoint_exception =
        instruction_valid &&
        ebreak &&
        !system_illegal;

    assign ecall_exception =
        instruction_valid &&
        ecall &&
        !system_illegal;

    wire load_misaligned_exception;
    wire load_access_exception;
    wire store_misaligned_exception;
    wire store_access_exception;

    assign load_misaligned_exception =
        instruction_valid &&
        !decoded_illegal &&
        mem_read &&
        data_misaligned;

    assign load_access_exception =
        instruction_valid &&
        !decoded_illegal &&
        mem_read &&
        !data_misaligned &&
        !data_range_valid;

    assign store_misaligned_exception =
        instruction_valid &&
        !decoded_illegal &&
        mem_write &&
        data_misaligned;

    assign store_access_exception =
        instruction_valid &&
        !decoded_illegal &&
        mem_write &&
        !data_misaligned &&
        !data_range_valid;

    // =====================================================
    // 15. TRAP CONTROLLER
    // =====================================================

    wire trap_enter_raw;

    wire [31:0] trap_pc;
    wire [31:0] trap_cause;
    wire [31:0] trap_value;

    wire [31:0] fault_address;

    // For a bad branch/jump target, mtval is the target.
    // For an instruction-fetch fault, mtval is the current PC.
    assign fault_address =
    target_misaligned
        ? control_target
        : (
            (load_misaligned_exception ||
             load_access_exception ||
             store_misaligned_exception ||
             store_access_exception)
                ? alu_result
                : pc
          );

    trap_controller trap_controller_inst (
        .current_pc(pc),
        .instruction(instruction),
        .fault_address(fault_address),

        .instruction_misaligned(
            fetch_misaligned || target_misaligned
        ),

        .instruction_access_fault(fetch_access_fault),

        .illegal_instruction(illegal_exception),

        .breakpoint_exception(breakpoint_exception),

        .load_misaligned(load_misaligned_exception),
        .load_access_fault(load_access_exception),

        .store_misaligned(store_misaligned_exception),
        .store_access_fault(store_access_exception),

        .ecall_m_exception(ecall_exception),

        .trap_enter(trap_enter_raw),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),
        .trap_value(trap_value)
    );

    wire trap_enter;

    assign trap_enter = trap_enter_raw && !reset;

    // =====================================================
    // 16. CSR FILE CONNECTION
    // =====================================================

    assign csr_write_enable =
        csr_write_enable_raw &&
        instruction_valid &&
        !decoded_illegal &&
        !trap_enter &&
        !reset;

    assign mret_execute =
        instruction_valid &&
        mret &&
        !system_illegal &&
        !trap_enter &&
        !reset;

    csr_file csr_file_inst (
        .clk(clk),
        .reset(reset),

        .csr_addr(instruction[31:20]),
        .csr_read_data(csr_read_data),
        .csr_valid(csr_valid),

        .csr_write_enable(csr_write_enable),
        .csr_write_data(csr_write_data),

        .trap_enter(trap_enter),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),
        .trap_value(trap_value),

        .mret(mret_execute),

        .mtvec(mtvec),
        .mepc(mepc),
        .mcause(mcause),
        .mtval(mtval),
        .mstatus(mstatus)
    );

    // =====================================================
    // 17. REGISTER FILE WRITEBACK
    // =====================================================

    wire normal_register_write;

    assign normal_register_write =
        reg_write &&
        instruction_valid &&
        !decoded_illegal &&
        memory_access_valid;

    assign register_write_enable =
        (normal_register_write || csr_rd_write_enable) &&
        !trap_enter &&
        !reset;

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

    // =====================================================
    // 18. WRITEBACK MUX
    // =====================================================

    always @(*) begin

        if (is_csr) begin
            writeback_data = csr_rd_write_data;
        end
        else begin
            case (result_src)

                2'b00:
                    writeback_data = alu_result;

                2'b01:
                    writeback_data = memory_read_data;

                2'b10:
                    writeback_data = immediate;

                2'b11:
                    writeback_data = pc_plus_4;

                default:
                    writeback_data = 32'h00000000;

            endcase
        end

    end

    // =====================================================
    // 19. DATA MEMORY WRITE PROTECTION
    // =====================================================

    assign data_mem_read_enable =
        mem_read &&
        instruction_valid &&
        !decoded_illegal &&
        memory_address_valid &&
        !trap_enter &&
        !reset;

    assign data_mem_write_enable =
        mem_write &&
        instruction_valid &&
        !decoded_illegal &&
        memory_address_valid &&
        !trap_enter &&
        !reset;

    // =====================================================
    // 20. NEXT PC LOGIC
    // =====================================================

    wire [31:0] mtvec_base;

    assign mtvec_base = {mtvec[31:2], 2'b00};

    always @(*) begin

        if (reset) begin
            next_pc = 32'h00000000;
        end

        // Synchronous exception: enter machine trap handler.
        else if (trap_enter) begin
            next_pc = mtvec_base;
        end

        // Machine return: restore PC from MEPC.
        else if (mret_execute) begin
            next_pc = mepc;
        end

        else if (!instruction_valid) begin
            next_pc = pc_plus_4;
        end

        else if (jump && jalr) begin
            next_pc = jalr_target;
        end

        else if (jump) begin
            next_pc = branch_target;
        end

        else if (branch_taken) begin
            next_pc = branch_target;
        end

        else begin
            next_pc = pc_plus_4;
        end

    end

    // =====================================================
    // 21. EXCEPTION STATUS OUTPUT
    // =====================================================

    assign illegal_instruction =
        trap_enter_raw;

endmodule
