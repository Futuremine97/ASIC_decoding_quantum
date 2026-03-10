module apb_regs #(
    parameter ADDR_W = 12,
    parameter DATA_W = 32,
    parameter COUNT_W = 16,
    parameter BURST_W = 8,
    parameter FIFO_LEVEL_W = 5
) (
    input  wire                   pclk,
    input  wire                   presetn,

    // APB3 slave
    input  wire [ADDR_W-1:0]      paddr,
    input  wire                   psel,
    input  wire                   penable,
    input  wire                   pwrite,
    input  wire [DATA_W-1:0]      pwdata,
    output reg  [DATA_W-1:0]      prdata,
    output reg                    pready,
    output reg                    pslverr,

    // Core control / status
    output reg  [31:0]            desc_base,
    output reg  [COUNT_W-1:0]     desc_count,
    output reg  [BURST_W-1:0]     rd_burst_len,
    output reg  [31:0]            result_base,
    output reg                    start_pulse,
    output reg                    soft_reset_pulse,
    input  wire                   busy,
    input  wire                   done,
    input  wire                   fetch_done,
    input  wire                   store_done,
    input  wire [FIFO_LEVEL_W:0]  fifo_even_level,
    input  wire [FIFO_LEVEL_W:0]  fifo_odd_level
);
`include "csr_map.vh"

    reg done_sticky;

    wire apb_write;
    wire apb_read;

    assign apb_write = psel & penable & pwrite;
    assign apb_read  = psel & penable & ~pwrite;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready <= 1'b0;
            pslverr <= 1'b0;
        end else begin
            pready <= psel; // single-cycle response
            pslverr <= 1'b0;
        end
    end

    // Read mux
    always @* begin
        prdata = {DATA_W{1'b0}};
        case (paddr)
            `CSR_STATUS: begin
                prdata = { {(DATA_W-4){1'b0}}, store_done, fetch_done, done_sticky, busy };
            end
            `CSR_DESC_BASE: begin
                prdata = desc_base;
            end
            `CSR_DESC_COUNT: begin
                prdata = { {(DATA_W-COUNT_W){1'b0}}, desc_count };
            end
            `CSR_RD_BURST: begin
                prdata = { {(DATA_W-BURST_W){1'b0}}, rd_burst_len };
            end
            `CSR_RESULT_BASE: begin
                prdata = result_base;
            end
            `CSR_EVEN_LEVEL: begin
                prdata = { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_even_level };
            end
            `CSR_ODD_LEVEL: begin
                prdata = { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_odd_level };
            end
            default: begin
                prdata = {DATA_W{1'b0}};
            end
        endcase
    end

    // Write / control
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            desc_base        <= 32'd0;
            desc_count       <= {COUNT_W{1'b0}};
            rd_burst_len     <= {BURST_W{1'b0}};
            result_base      <= 32'd0;
            start_pulse      <= 1'b0;
            soft_reset_pulse <= 1'b0;
            done_sticky      <= 1'b0;
        end else begin
            start_pulse      <= 1'b0;
            soft_reset_pulse <= 1'b0;

            if (done)
                done_sticky <= 1'b1;

            if (apb_write) begin
                case (paddr)
                    `CSR_CTRL: begin
                        if (pwdata[`CSR_CTRL_START] && ~busy)
                            start_pulse <= 1'b1;
                        if (pwdata[`CSR_CTRL_CLR_DONE])
                            done_sticky <= 1'b0;
                        if (pwdata[`CSR_CTRL_SOFT_RESET]) begin
                            soft_reset_pulse <= 1'b1;
                            done_sticky <= 1'b0;
                        end
                    end
                    `CSR_DESC_BASE: begin
                        desc_base <= pwdata;
                    end
                    `CSR_DESC_COUNT: begin
                        desc_count <= pwdata[COUNT_W-1:0];
                    end
                    `CSR_RD_BURST: begin
                        rd_burst_len <= pwdata[BURST_W-1:0];
                    end
                    `CSR_RESULT_BASE: begin
                        result_base <= pwdata;
                    end
                    default: begin
                        // no-op
                    end
                endcase
            end

            if (soft_reset_pulse) begin
                desc_count   <= {COUNT_W{1'b0}};
                rd_burst_len <= {BURST_W{1'b0}};
            end
        end
    end
endmodule
