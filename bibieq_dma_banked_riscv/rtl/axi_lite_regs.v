module axi_lite_regs #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter COUNT_W = 16,
    parameter BURST_W = 8,
    parameter FIFO_LEVEL_W = 5
) (
    input  wire                   clk,
    input  wire                   aresetn,

    // AXI4-Lite slave
    input  wire [ADDR_W-1:0]      s_axi_awaddr,
    input  wire [2:0]             s_axi_awprot,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,
    input  wire [DATA_W-1:0]      s_axi_wdata,
    input  wire [(DATA_W/8)-1:0]  s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,
    input  wire [ADDR_W-1:0]      s_axi_araddr,
    input  wire [2:0]             s_axi_arprot,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,
    output reg  [DATA_W-1:0]      s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // Core control / status
    output reg  [ADDR_W-1:0]      desc_base,
    output reg  [COUNT_W-1:0]     desc_count,
    output reg  [BURST_W-1:0]     rd_burst_len,
    output reg  [ADDR_W-1:0]      result_base,
    output reg                    start_pulse,
    output reg                    soft_reset_pulse,
    input  wire                   busy,
    input  wire                   done,
    input  wire                   fetch_done,
    input  wire                   store_done,
    input  wire [FIFO_LEVEL_W:0]  fifo_even_level,
    input  wire [FIFO_LEVEL_W:0]  fifo_odd_level
);
    localparam [7:0] REG_CTRL       = 8'h00;
    localparam [7:0] REG_STATUS     = 8'h04;
    localparam [7:0] REG_DESC_BASE  = 8'h08;
    localparam [7:0] REG_DESC_COUNT = 8'h0C;
    localparam [7:0] REG_RD_BURST   = 8'h10;
    localparam [7:0] REG_RESULT_BASE= 8'h14;
    localparam [7:0] REG_EVEN_LEVEL = 8'h18;
    localparam [7:0] REG_ODD_LEVEL  = 8'h1C;

    reg [ADDR_W-1:0] awaddr_hold;
    reg              aw_hold;
    reg [DATA_W-1:0] wdata_hold;
    reg [(DATA_W/8)-1:0] wstrb_hold;
    reg              w_hold;

    reg [ADDR_W-1:0] araddr_hold;

    reg              done_sticky;

    wire write_fire;
    wire read_fire;

    // Ready signals
    assign s_axi_awready = ~aw_hold & ~s_axi_bvalid;
    assign s_axi_wready  = ~w_hold & ~s_axi_bvalid;
    assign s_axi_arready = ~s_axi_rvalid;

    assign write_fire = aw_hold & w_hold & ~s_axi_bvalid;
    assign read_fire  = s_axi_arready & s_axi_arvalid;

    // Byte enable mask
    wire [DATA_W-1:0] wmask;
    assign wmask = { {8{wstrb_hold[3]}}, {8{wstrb_hold[2]}}, {8{wstrb_hold[1]}}, {8{wstrb_hold[0]}} };

    // Write address/data capture
    always @(posedge clk) begin
        if (!aresetn) begin
            aw_hold <= 1'b0;
            w_hold  <= 1'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid) begin
                aw_hold     <= 1'b1;
                awaddr_hold <= s_axi_awaddr;
            end
            if (s_axi_wready && s_axi_wvalid) begin
                w_hold     <= 1'b1;
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
            end
            if (write_fire) begin
                aw_hold <= 1'b0;
                w_hold  <= 1'b0;
            end
        end
    end

    // Write response
    always @(posedge clk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (write_fire) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address capture / response
    always @(posedge clk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_W{1'b0}};
        end else begin
            if (read_fire) begin
                araddr_hold <= s_axi_araddr;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                case (s_axi_araddr[7:0])
                    REG_STATUS: begin
                        s_axi_rdata <= { { (DATA_W-4){1'b0} }, store_done, fetch_done, done_sticky, busy };
                    end
                    REG_DESC_BASE: begin
                        s_axi_rdata <= desc_base;
                    end
                    REG_DESC_COUNT: begin
                        s_axi_rdata <= { {(DATA_W-COUNT_W){1'b0}}, desc_count };
                    end
                    REG_RD_BURST: begin
                        s_axi_rdata <= { {(DATA_W-BURST_W){1'b0}}, rd_burst_len };
                    end
                    REG_RESULT_BASE: begin
                        s_axi_rdata <= result_base;
                    end
                    REG_EVEN_LEVEL: begin
                        s_axi_rdata <= { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_even_level };
                    end
                    REG_ODD_LEVEL: begin
                        s_axi_rdata <= { {(DATA_W-(FIFO_LEVEL_W+1)){1'b0}}, fifo_odd_level };
                    end
                    default: begin
                        s_axi_rdata <= {DATA_W{1'b0}};
                    end
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Control/register write logic
    wire ctrl_write;
    wire start_req;
    wire clr_done_req;
    wire soft_reset_req;

    assign ctrl_write   = write_fire && (awaddr_hold[7:0] == REG_CTRL) && wmask[0];
    assign start_req    = ctrl_write && wdata_hold[0] && ~busy;
    assign clr_done_req = ctrl_write && wdata_hold[1];
    assign soft_reset_req = ctrl_write && wdata_hold[2];

    always @(posedge clk) begin
        if (!aresetn) begin
            desc_base        <= {ADDR_W{1'b0}};
            desc_count       <= {COUNT_W{1'b0}};
            rd_burst_len     <= {BURST_W{1'b0}};
            result_base      <= {ADDR_W{1'b0}};
            start_pulse      <= 1'b0;
            soft_reset_pulse <= 1'b0;
            done_sticky      <= 1'b0;
        end else begin
            // default pulses
            start_pulse      <= 1'b0;
            soft_reset_pulse <= 1'b0;

            // latch done sticky
            if (done)
                done_sticky <= 1'b1;

            // control pulses
            if (start_req)
                start_pulse <= 1'b1;
            if (soft_reset_req)
                soft_reset_pulse <= 1'b1;

            if (clr_done_req || soft_reset_req)
                done_sticky <= 1'b0;

            if (write_fire) begin
                case (awaddr_hold[7:0])
                    REG_DESC_BASE: begin
                        desc_base <= (desc_base & ~wmask) | (wdata_hold & wmask);
                    end
                    REG_DESC_COUNT: begin
                        desc_count <= (desc_count & ~wmask[COUNT_W-1:0]) | (wdata_hold[COUNT_W-1:0] & wmask[COUNT_W-1:0]);
                    end
                    REG_RD_BURST: begin
                        rd_burst_len <= (rd_burst_len & ~wmask[BURST_W-1:0]) | (wdata_hold[BURST_W-1:0] & wmask[BURST_W-1:0]);
                    end
                    REG_RESULT_BASE: begin
                        result_base <= (result_base & ~wmask) | (wdata_hold & wmask);
                    end
                    default: begin
                        // no-op
                    end
                endcase
            end

            if (soft_reset_req) begin
                desc_count   <= {COUNT_W{1'b0}};
                rd_burst_len <= {BURST_W{1'b0}};
            end
        end
    end
endmodule
