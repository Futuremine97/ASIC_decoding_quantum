module ahb_lite_regs #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter COUNT_W = 16,
    parameter BURST_W = 8,
    parameter FIFO_LEVEL_W = 5,
    parameter BASE_ADDR = 32'h2000_0000,
    parameter ADDR_MASK = 32'hFFFF_F000
) (
    input  wire                   hclk,
    input  wire                   hresetn,

    // AHB-Lite slave
    input  wire [ADDR_W-1:0]      haddr,
    input  wire                   hwrite,
    input  wire [1:0]             htrans,
    input  wire                   hsel,
    input  wire                   hready,
    input  wire [DATA_W-1:0]      hwdata,
    output reg  [DATA_W-1:0]      hrdata,
    output wire                   hreadyout,
    output wire                   hresp,

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

    reg [ADDR_W-1:0] addr_r;
    reg              write_r;
    reg              valid_r;
    reg              done_sticky;

    wire hit;
    wire trans_valid;
    wire [11:0] addr_off;

    assign hit = ((haddr & ADDR_MASK) == BASE_ADDR);
    assign trans_valid = hsel & hready & htrans[1] & hit;
    assign addr_off = addr_r[11:0];

    assign hreadyout = 1'b1; // zero-wait
    assign hresp = 1'b0;     // OKAY

    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            addr_r  <= {ADDR_W{1'b0}};
            write_r <= 1'b0;
            valid_r <= 1'b0;
        end else if (hready) begin
            addr_r  <= haddr;
            write_r <= hwrite;
            valid_r <= trans_valid;
        end
    end

    // Read mux (data phase)
    always @* begin
        hrdata = {DATA_W{1'b0}};
        if (valid_r && !write_r) begin
            case (addr_off)
                `CSR_STATUS: begin
                    hrdata = { {(DATA_W-4){1'b0}}, store_done, fetch_done, done_sticky, busy };
                end
                `CSR_DESC_BASE: begin
                    hrdata = desc_base;
                end
                `CSR_DESC_COUNT: begin
                    hrdata = { {(DATA_W-COUNT_W){1'b0}}, desc_count };
                end
                `CSR_RD_BURST: begin
                    hrdata = { {(DATA_W-BURST_W){1'b0}}, rd_burst_len };
                end
                `CSR_RESULT_BASE: begin
                    hrdata = result_base;
                end
                `CSR_EVEN_LEVEL: begin
                    hrdata = { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_even_level };
                end
                `CSR_ODD_LEVEL: begin
                    hrdata = { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_odd_level };
                end
                default: begin
                    hrdata = {DATA_W{1'b0}};
                end
            endcase
        end
    end

    // Write / control (data phase)
    always @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
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

            if (valid_r && write_r) begin
                case (addr_off)
                    `CSR_CTRL: begin
                        if (hwdata[`CSR_CTRL_START] && ~busy)
                            start_pulse <= 1'b1;
                        if (hwdata[`CSR_CTRL_CLR_DONE])
                            done_sticky <= 1'b0;
                        if (hwdata[`CSR_CTRL_SOFT_RESET]) begin
                            soft_reset_pulse <= 1'b1;
                            done_sticky <= 1'b0;
                        end
                    end
                    `CSR_DESC_BASE: begin
                        desc_base <= hwdata;
                    end
                    `CSR_DESC_COUNT: begin
                        desc_count <= hwdata[COUNT_W-1:0];
                    end
                    `CSR_RD_BURST: begin
                        rd_burst_len <= hwdata[BURST_W-1:0];
                    end
                    `CSR_RESULT_BASE: begin
                        result_base <= hwdata;
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
