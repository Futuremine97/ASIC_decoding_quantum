module bibieq_dma_banked_riscv_ahb_top #(
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
    parameter IDLE_GATE = 1,
    parameter BASE_ADDR = 32'h2000_0000,
    parameter ADDR_MASK = 32'hFFFF_F000
) (
    input  wire                    hclk,
    input  wire                    hresetn,

    // AHB-Lite control interface
    input  wire [ADDR_W-1:0]       haddr,
    input  wire                    hwrite,
    input  wire [1:0]              htrans,
    input  wire                    hsel,
    input  wire                    hready,
    input  wire [31:0]             hwdata,
    output wire [31:0]             hrdata,
    output wire                    hreadyout,
    output wire                    hresp,

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
    wire                  hresetn_sync;
    wire                  start_pulse;
    wire                  soft_reset_pulse;
    wire [31:0]           desc_base;
    wire [COUNT_W-1:0]    desc_count;
    wire [7:0]            rd_burst_len;
    wire [31:0]           result_base;
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
        .clk(hclk),
        .arst_n(hresetn),
        .srst_n(hresetn_sync)
    );

    assign core_rst = ~hresetn_sync | soft_reset_pulse;

    ahb_lite_regs #(
        .ADDR_W(ADDR_W),
        .DATA_W(32),
        .COUNT_W(COUNT_W),
        .BURST_W(8),
        .FIFO_LEVEL_W(FIFO_PTR_W),
        .BASE_ADDR(BASE_ADDR),
        .ADDR_MASK(ADDR_MASK)
    ) u_ahb_regs (
        .hclk(hclk),
        .hresetn(hresetn_sync),
        .haddr(haddr),
        .hwrite(hwrite),
        .htrans(htrans),
        .hsel(hsel),
        .hready(hready),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hreadyout(hreadyout),
        .hresp(hresp),
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
        .clk(hclk),
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
        .clk(hclk),
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
        .clk(hclk),
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
