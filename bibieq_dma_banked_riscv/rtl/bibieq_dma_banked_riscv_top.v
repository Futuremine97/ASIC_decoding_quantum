module bibieq_dma_banked_riscv_top #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64,
    parameter COUNT_W = 16,
    parameter FIFO_DEPTH = 16,
    parameter FIFO_PTR_W = 4,
    parameter INBUF_DEPTH = 4,
    parameter INBUF_PTR_W = 2,
    parameter Q = 16,
    parameter MAX_SITES = 5,
    parameter L = 6,
    parameter M = 6,
    parameter UW = 4,
    parameter VW = 4,
    parameter FAST_MODE = 0,
    parameter FAST_MODE_EVEN = FAST_MODE,
    parameter FAST_MODE_ODD  = FAST_MODE,
    parameter IDLE_GATE = 1
) (
    input  wire                    aclk,
    input  wire                    aresetn,

    // AXI4-Lite control interface
    input  wire [ADDR_W-1:0]       s_axi_awaddr,
    input  wire [2:0]              s_axi_awprot,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,
    input  wire [31:0]             s_axi_wdata,
    input  wire [3:0]              s_axi_wstrb,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,
    output wire [1:0]              s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,
    input  wire [ADDR_W-1:0]       s_axi_araddr,
    input  wire [2:0]              s_axi_arprot,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,
    output wire [31:0]             s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,

    // AXI4 read master (descriptor fetch)
    output wire [ADDR_W-1:0]       m_axi_araddr,
    output wire [7:0]              m_axi_arlen,
    output wire [2:0]              m_axi_arsize,
    output wire [1:0]              m_axi_arburst,
    output wire                    m_axi_arvalid,
    input  wire                    m_axi_arready,
    input  wire [DATA_W-1:0]       m_axi_rdata,
    input  wire [1:0]              m_axi_rresp,
    input  wire                    m_axi_rlast,
    input  wire                    m_axi_rvalid,
    output wire                    m_axi_rready,

    // AXI4 write master (result writeback)
    output wire [ADDR_W-1:0]       m_axi_awaddr,
    output wire [7:0]              m_axi_awlen,
    output wire [2:0]              m_axi_awsize,
    output wire [1:0]              m_axi_awburst,
    output wire                    m_axi_awvalid,
    input  wire                    m_axi_awready,
    output wire [DATA_W-1:0]       m_axi_wdata,
    output wire [(DATA_W/8)-1:0]   m_axi_wstrb,
    output wire                    m_axi_wlast,
    output wire                    m_axi_wvalid,
    input  wire                    m_axi_wready,
    input  wire [1:0]              m_axi_bresp,
    input  wire                    m_axi_bvalid,
    output wire                    m_axi_bready
);
    wire                  core_rst;
    wire                  aresetn_sync;
    wire                  start_pulse;
    wire                  soft_reset_pulse;
    wire [ADDR_W-1:0]     desc_base;
    wire [COUNT_W-1:0]    desc_count;
    wire [7:0]            rd_burst_len;
    wire [ADDR_W-1:0]     result_base;
    wire                  busy;
    wire                  done;
    wire                  fetch_done;
    wire                  store_done;
    wire [FIFO_PTR_W:0]   fifo_even_level;
    wire [FIFO_PTR_W:0]   fifo_odd_level;

    wire                  rd_cmd_valid;
    wire                  rd_cmd_ready;
    wire [ADDR_W-1:0]     rd_cmd_addr;
    wire [7:0]            rd_cmd_len;
    wire                  mem_rvalid;
    wire [DATA_W-1:0]     mem_rdata;
    wire                  mem_rlast;
    wire                  mem_rready;

    wire                  mem_wvalid;
    wire [ADDR_W-1:0]     mem_waddr;
    wire [DATA_W-1:0]     mem_wdata;
    wire                  mem_wlast;
    wire                  mem_wready;

    reset_sync u_reset_sync (
        .clk(aclk),
        .arst_n(aresetn),
        .srst_n(aresetn_sync)
    );

    assign core_rst = ~aresetn_sync | soft_reset_pulse;

    axi_lite_regs #(
        .ADDR_W(ADDR_W),
        .DATA_W(32),
        .COUNT_W(COUNT_W),
        .BURST_W(8),
        .FIFO_LEVEL_W(FIFO_PTR_W)
    ) u_regs (
        .clk(aclk),
        .aresetn(aresetn_sync),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .desc_base(desc_base),
        .desc_count(desc_count),
        .rd_burst_len(rd_burst_len),
        .result_base(result_base),
        .start_pulse(start_pulse),
        .soft_reset_pulse(soft_reset_pulse),
        .busy(busy),
        .done(done),
        .fetch_done(fetch_done),
        .store_done(store_done),
        .fifo_even_level(fifo_even_level),
        .fifo_odd_level(fifo_odd_level)
    );

    bibieq_dma_banked_top #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .COUNT_W(COUNT_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_PTR_W(FIFO_PTR_W),
        .INBUF_DEPTH(INBUF_DEPTH),
        .INBUF_PTR_W(INBUF_PTR_W),
        .Q(Q),
        .MAX_SITES(MAX_SITES),
        .L(L),
        .M(M),
        .UW(UW),
        .VW(VW),
        .FAST_MODE(FAST_MODE),
        .FAST_MODE_EVEN(FAST_MODE_EVEN),
        .FAST_MODE_ODD(FAST_MODE_ODD),
        .IDLE_GATE(IDLE_GATE)
    ) u_core (
        .clk(aclk),
        .rst(core_rst),
        .start(start_pulse),
        .desc_src_base(desc_base),
        .desc_count(desc_count),
        .rd_burst_len(rd_burst_len),
        .result_dst_base(result_base),
        .busy(busy),
        .done(done),
        .rd_cmd_valid(rd_cmd_valid),
        .rd_cmd_ready(rd_cmd_ready),
        .rd_cmd_addr(rd_cmd_addr),
        .rd_cmd_len(rd_cmd_len),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),
        .mem_rready(mem_rready),
        .mem_wvalid(mem_wvalid),
        .mem_waddr(mem_waddr),
        .mem_wdata(mem_wdata),
        .mem_wlast(mem_wlast),
        .mem_wready(mem_wready),
        .fifo_even_level(fifo_even_level),
        .fifo_odd_level(fifo_odd_level),
        .fetch_done(fetch_done),
        .store_done(store_done)
    );

    axi_read_master #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) u_axi_read (
        .clk(aclk),
        .rst(core_rst),
        .rd_cmd_valid(rd_cmd_valid),
        .rd_cmd_ready(rd_cmd_ready),
        .rd_cmd_addr(rd_cmd_addr),
        .rd_cmd_len(rd_cmd_len),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),
        .mem_rready(mem_rready),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

    axi_write_master #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) u_axi_write (
        .clk(aclk),
        .rst(core_rst),
        .mem_wvalid(mem_wvalid),
        .mem_waddr(mem_waddr),
        .mem_wdata(mem_wdata),
        .mem_wlast(mem_wlast),
        .mem_wready(mem_wready),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );
endmodule
