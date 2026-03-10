module axi_read_master #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64
) (
    input  wire               clk,
    input  wire               rst,

    // Core read command
    input  wire               rd_cmd_valid,
    output wire               rd_cmd_ready,
    input  wire [ADDR_W-1:0]  rd_cmd_addr,
    input  wire [7:0]         rd_cmd_len,

    // Core read data
    output wire               mem_rvalid,
    output wire [DATA_W-1:0]  mem_rdata,
    output wire               mem_rlast,
    input  wire               mem_rready,

    // AXI4 read master
    output reg  [ADDR_W-1:0]  m_axi_araddr,
    output reg  [7:0]         m_axi_arlen,
    output wire [2:0]         m_axi_arsize,
    output wire [1:0]         m_axi_arburst,
    output reg                m_axi_arvalid,
    input  wire               m_axi_arready,
    input  wire [DATA_W-1:0]  m_axi_rdata,
    input  wire [1:0]         m_axi_rresp,
    input  wire               m_axi_rlast,
    input  wire               m_axi_rvalid,
    output wire               m_axi_rready
);
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value-1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam integer AXI_SIZE = clog2(DATA_W/8);

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_AR   = 2'd1;
    localparam [1:0] ST_R    = 2'd2;

    reg [1:0] state;

    assign m_axi_arsize  = AXI_SIZE[2:0];
    assign m_axi_arburst = 2'b01; // INCR

    assign rd_cmd_ready = (state == ST_IDLE);

    assign mem_rvalid = (state == ST_R) ? m_axi_rvalid : 1'b0;
    assign mem_rdata  = m_axi_rdata;
    assign mem_rlast  = m_axi_rlast;
    assign m_axi_rready = (state == ST_R) ? mem_rready : 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= ST_IDLE;
            m_axi_arvalid <= 1'b0;
            m_axi_araddr  <= {ADDR_W{1'b0}};
            m_axi_arlen   <= 8'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    m_axi_arvalid <= 1'b0;
                    if (rd_cmd_valid) begin
                        m_axi_araddr  <= rd_cmd_addr;
                        m_axi_arlen   <= (rd_cmd_len == 8'd0) ? 8'd0 : (rd_cmd_len - 8'd1);
                        m_axi_arvalid <= 1'b1;
                        state         <= ST_AR;
                    end
                end
                ST_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        state <= ST_R;
                    end
                end
                ST_R: begin
                    if (m_axi_rvalid && mem_rready && m_axi_rlast) begin
                        state <= ST_IDLE;
                    end
                end
                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
