module axi_write_master #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64
) (
    input  wire                    clk,
    input  wire                    rst,

    // Core write stream
    input  wire                    mem_wvalid,
    input  wire [ADDR_W-1:0]       mem_waddr,
    input  wire [DATA_W-1:0]       mem_wdata,
    input  wire                    mem_wlast,
    output wire                    mem_wready,

    // AXI4 write master
    output reg  [ADDR_W-1:0]       m_axi_awaddr,
    output reg  [7:0]              m_axi_awlen,
    output wire [2:0]              m_axi_awsize,
    output wire [1:0]              m_axi_awburst,
    output reg                     m_axi_awvalid,
    input  wire                    m_axi_awready,
    output reg  [DATA_W-1:0]       m_axi_wdata,
    output reg  [(DATA_W/8)-1:0]   m_axi_wstrb,
    output reg                     m_axi_wlast,
    output reg                     m_axi_wvalid,
    input  wire                    m_axi_wready,
    input  wire [1:0]              m_axi_bresp,
    input  wire                    m_axi_bvalid,
    output reg                     m_axi_bready
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

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_SEND  = 2'd1;
    localparam [1:0] ST_WAITB = 2'd2;

    reg [1:0] state;
    reg aw_done;
    reg w_done;

    assign m_axi_awsize  = AXI_SIZE[2:0];
    assign m_axi_awburst = 2'b01; // INCR

    assign mem_wready = (state == ST_IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= ST_IDLE;
            m_axi_awvalid<= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            aw_done      <= 1'b0;
            w_done       <= 1'b0;
            m_axi_awaddr <= {ADDR_W{1'b0}};
            m_axi_awlen  <= 8'd0;
            m_axi_wdata  <= {DATA_W{1'b0}};
            m_axi_wstrb  <= {(DATA_W/8){1'b0}};
            m_axi_wlast  <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid  <= 1'b0;
                    m_axi_bready  <= 1'b0;
                    aw_done       <= 1'b0;
                    w_done        <= 1'b0;

                    if (mem_wvalid) begin
                        m_axi_awaddr <= mem_waddr;
                        m_axi_awlen  <= 8'd0; // single-beat
                        m_axi_wdata  <= mem_wdata;
                        m_axi_wstrb  <= {(DATA_W/8){1'b1}};
                        m_axi_wlast  <= 1'b1;
                        m_axi_awvalid<= 1'b1;
                        m_axi_wvalid <= 1'b1;
                        state        <= ST_SEND;
                    end
                end
                ST_SEND: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_done <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        w_done <= 1'b1;
                    end
                    if ((aw_done || (m_axi_awvalid && m_axi_awready)) && (w_done || (m_axi_wvalid && m_axi_wready))) begin
                        m_axi_bready <= 1'b1;
                        state <= ST_WAITB;
                    end
                end
                ST_WAITB: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
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
