
`timescale 1ns/1ps

module csr_file (
    input wire clk,
    input wire reset,

    // CSR read interface
    input wire [11:0] csr_addr,
    output reg [31:0] csr_read_data,
    output reg csr_valid,

    // CSR write interface
    input wire csr_write_enable,
    input wire [31:0] csr_write_data,

    // Trap interface
    input wire trap_enter,
    input wire [31:0] trap_pc,
    input wire [31:0] trap_cause,
    input wire [31:0] trap_value,

    // Machine return
    input wire mret,

    // Architectural state outputs
    output wire [31:0] mtvec,
    output wire [31:0] mepc,
    output wire [31:0] mcause,
    output wire [31:0] mtval,
    output wire [31:0] mstatus
);

    // Machine CSR addresses
    localparam CSR_MSTATUS = 12'h300;
    localparam CSR_MTVEC   = 12'h305;
    localparam CSR_MEPC    = 12'h341;
    localparam CSR_MCAUSE  = 12'h342;
    localparam CSR_MTVAL   = 12'h343;

    reg [31:0] mstatus_reg;
    reg [31:0] mtvec_reg;
    reg [31:0] mepc_reg;
    reg [31:0] mcause_reg;
    reg [31:0] mtval_reg;

    assign mstatus = mstatus_reg;
    assign mtvec   = mtvec_reg;
    assign mepc    = mepc_reg;
    assign mcause  = mcause_reg;
    assign mtval   = mtval_reg;

    // -----------------------------------------
    // CSR READ
    // -----------------------------------------

    always @(*) begin

        csr_read_data = 32'h00000000;
        csr_valid = 1'b1;

        case (csr_addr)

            CSR_MSTATUS:
                csr_read_data = mstatus_reg;

            CSR_MTVEC:
                csr_read_data = mtvec_reg;

            CSR_MEPC:
                csr_read_data = mepc_reg;

            CSR_MCAUSE:
                csr_read_data = mcause_reg;

            CSR_MTVAL:
                csr_read_data = mtval_reg;

            default: begin
                csr_read_data = 32'h00000000;
                csr_valid = 1'b0;
            end

        endcase

    end

    // -----------------------------------------
    // CSR WRITE AND TRAP STATE
    // -----------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            mstatus_reg <= 32'h00001800;
            mtvec_reg   <= 32'h00000000;
            mepc_reg    <= 32'h00000000;
            mcause_reg  <= 32'h00000000;
            mtval_reg   <= 32'h00000000;

        end

        // Trap entry has priority
        else if (trap_enter) begin

            mepc_reg   <= {trap_pc[31:2], 2'b00};
            mcause_reg <= trap_cause;
            mtval_reg  <= trap_value;

            // MPIE receives previous MIE
            mstatus_reg[7] <= mstatus_reg[3];

            // Disable machine interrupts
            mstatus_reg[3] <= 1'b0;

            // MPP = Machine mode
            mstatus_reg[12:11] <= 2'b11;

        end

        // Machine-mode return
        else if (mret) begin

            // Restore MIE from MPIE
            mstatus_reg[3] <= mstatus_reg[7];

            // MPIE becomes 1
            mstatus_reg[7] <= 1'b1;

            // Only Machine mode is implemented
            mstatus_reg[12:11] <= 2'b11;

        end

        // Normal CSR write
        else if (csr_write_enable && csr_valid) begin

            case (csr_addr)

                CSR_MSTATUS: begin

                    // Only MIE, MPIE and MPP are implemented
                    mstatus_reg[3] <= csr_write_data[3];
                    mstatus_reg[7] <= csr_write_data[7];

                    // Machine mode only
                    mstatus_reg[12:11] <= 2'b11;

                end

                CSR_MTVEC: begin

                    // Support Direct (00) and Vectored (01)
                    if (csr_write_data[1:0] <= 2'b01)
                        mtvec_reg <= {
                            csr_write_data[31:2],
                            csr_write_data[1:0]
                        };
                    else
                        mtvec_reg <= {
                            csr_write_data[31:2],
                            2'b00
                        };

                end

                CSR_MEPC:
                    mepc_reg <= {
                        csr_write_data[31:2],
                        2'b00
                    };

                CSR_MCAUSE:
                    mcause_reg <= csr_write_data;

                CSR_MTVAL:
                    mtval_reg <= csr_write_data;

                default: begin
                    // Unsupported CSR writes are ignored
                end

            endcase

        end

    end

endmodule
