
`timescale 1ns/1ps

module trap_controller (
    input wire [31:0] current_pc,
    input wire [31:0] instruction,
    input wire [31:0] fault_address,

    input wire instruction_misaligned,
    input wire instruction_access_fault,
    input wire illegal_instruction,
    input wire breakpoint_exception,
    input wire load_misaligned,
    input wire load_access_fault,
    input wire store_misaligned,
    input wire store_access_fault,
    input wire ecall_m_exception,

    output reg trap_enter,
    output reg [31:0] trap_pc,
    output reg [31:0] trap_cause,
    output reg [31:0] trap_value
);

    always @(*) begin
        trap_enter = 1'b0;
        trap_pc    = current_pc;
        trap_cause = 32'd0;
        trap_value = 32'd0;

        // Priority selection. Normally only one synchronous
        // exception should be active for an instruction.

        if (instruction_misaligned) begin
            trap_enter = 1'b1;
            trap_cause = 32'd0;
            trap_value = fault_address;
        end
        else if (instruction_access_fault) begin
            trap_enter = 1'b1;
            trap_cause = 32'd1;
            trap_value = fault_address;
        end
        else if (illegal_instruction) begin
            trap_enter = 1'b1;
            trap_cause = 32'd2;
            trap_value = instruction;
        end
        else if (breakpoint_exception) begin
            trap_enter = 1'b1;
            trap_cause = 32'd3;
            trap_value = 32'd0;
        end
        else if (load_misaligned) begin
            trap_enter = 1'b1;
            trap_cause = 32'd4;
            trap_value = fault_address;
        end
        else if (load_access_fault) begin
            trap_enter = 1'b1;
            trap_cause = 32'd5;
            trap_value = fault_address;
        end
        else if (store_misaligned) begin
            trap_enter = 1'b1;
            trap_cause = 32'd6;
            trap_value = fault_address;
        end
        else if (store_access_fault) begin
            trap_enter = 1'b1;
            trap_cause = 32'd7;
            trap_value = fault_address;
        end
        else if (ecall_m_exception) begin
            trap_enter = 1'b1;
            trap_cause = 32'd11;
            trap_value = 32'd0;
        end
    end

endmodule
