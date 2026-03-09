module bibieq_dma_banked_top #(
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
    parameter SYNC_START = 1
) (
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire [ADDR_W-1:0]   desc_src_base,
    input  wire [COUNT_W-1:0]  desc_count,
    input  wire [7:0]          rd_burst_len,
    input  wire [ADDR_W-1:0]   result_dst_base,
    output wire                busy,
    output wire                done,

    // Read DMA / memory side
    output wire                rd_cmd_valid,
    input  wire                rd_cmd_ready,
    output wire [ADDR_W-1:0]   rd_cmd_addr,
    output wire [7:0]          rd_cmd_len,
    input  wire                mem_rvalid,
    input  wire [DATA_W-1:0]   mem_rdata,
    input  wire                mem_rlast,
    output wire                mem_rready,

    // Write DMA / memory side
    output wire                mem_wvalid,
    output wire [ADDR_W-1:0]   mem_waddr,
    output wire [DATA_W-1:0]   mem_wdata,
    output wire                mem_wlast,
    input  wire                mem_wready,

    // Debug/observability
    output wire [FIFO_PTR_W:0] fifo_even_level,
    output wire [FIFO_PTR_W:0] fifo_odd_level,
    output wire                fetch_done,
    output wire                store_done
);
    wire               desc_valid;
    wire [DATA_W-1:0]  desc_data;
    wire [7:0]         desc_index;
    wire               desc_ready;
    wire               desc_last_unused;
    wire               fetch_busy;

    wire               fifo_even_valid;
    wire [DATA_W-1:0]  fifo_even_data;
    wire               fifo_even_ready;
    wire               fifo_odd_valid;
    wire [DATA_W-1:0]  fifo_odd_data;
    wire               fifo_odd_ready;
    wire               fifo_empty;
    wire               fifo_full_even_unused;
    wire               fifo_full_odd_unused;

    wire               even_result_valid;
    wire [63:0]        even_result_data;
    wire               even_result_ready;
    wire               odd_result_valid;
    wire [63:0]        odd_result_data;
    wire               odd_result_ready;

    wire               merged_valid;
    wire [63:0]        merged_data;
    wire               merged_ready;
    wire               store_busy;

    wire start_sync;

    generate
        if (SYNC_START) begin : gen_start_sync
            sync_2ff #(.INIT(1'b0)) u_start_sync (
                .clk(clk),
                .rst(rst),
                .d(start),
                .q(start_sync)
            );
        end else begin : gen_start_passthru
            assign start_sync = start;
        end
    endgenerate

    dma_desc_fetch #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .COUNT_W(COUNT_W)
    ) u_fetch (
        .clk(clk),
        .rst(rst),
        .start(start_sync),
        .base_addr(desc_src_base),
        .desc_count(desc_count),
        .burst_len(rd_burst_len),
        .busy(fetch_busy),
        .done(fetch_done),
        .rd_cmd_valid(rd_cmd_valid),
        .rd_cmd_ready(rd_cmd_ready),
        .rd_cmd_addr(rd_cmd_addr),
        .rd_cmd_len(rd_cmd_len),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),
        .mem_rready(mem_rready),
        .desc_valid(desc_valid),
        .desc_data(desc_data),
        .desc_index(desc_index),
        .desc_last(desc_last_unused),
        .desc_ready(desc_ready)
    );

    dual_bank_fifo #(
        .DATA_W(DATA_W),
        .DEPTH(FIFO_DEPTH),
        .PTR_W(FIFO_PTR_W),
        .IDX_W(8),
        .INBUF_DEPTH(INBUF_DEPTH),
        .INBUF_PTR_W(INBUF_PTR_W)
    ) u_fifo (
        .clk(clk),
        .rst(rst),
        .in_valid(desc_valid),
        .in_data(desc_data),
        .in_index(desc_index),
        .in_ready(desc_ready),
        .even_valid(fifo_even_valid),
        .even_data(fifo_even_data),
        .even_ready(fifo_even_ready),
        .odd_valid(fifo_odd_valid),
        .odd_data(fifo_odd_data),
        .odd_ready(fifo_odd_ready),
        .even_level(fifo_even_level),
        .odd_level(fifo_odd_level),
        .empty(fifo_empty),
        .full_even(fifo_full_even_unused),
        .full_odd(fifo_full_odd_unused)
    );

    segment_worker #(
        .Q(Q), .MAX_SITES(MAX_SITES), .UW(UW), .VW(VW), .L(L), .M(M),
        .FAST_MODE(FAST_MODE_EVEN),
        .SEED0(16'h1357), .SEED1(16'h2468), .SEED2(16'h369C),
        .SEED3(16'h48AD), .SEED4(16'h55AA), .SEED5(16'hA55A)
    ) u_even_worker (
        .clk(clk),
        .rst(rst),
        .desc_valid(fifo_even_valid),
        .desc_data(fifo_even_data),
        .desc_ready(fifo_even_ready),
        .result_valid(even_result_valid),
        .result_data(even_result_data),
        .result_ready(even_result_ready)
    );

    segment_worker #(
        .Q(Q), .MAX_SITES(MAX_SITES), .UW(UW), .VW(VW), .L(L), .M(M),
        .FAST_MODE(FAST_MODE_ODD),
        .SEED0(16'h1111), .SEED1(16'h2222), .SEED2(16'h3333),
        .SEED3(16'h4444), .SEED4(16'h5555), .SEED5(16'h6666)
    ) u_odd_worker (
        .clk(clk),
        .rst(rst),
        .desc_valid(fifo_odd_valid),
        .desc_data(fifo_odd_data),
        .desc_ready(fifo_odd_ready),
        .result_valid(odd_result_valid),
        .result_data(odd_result_data),
        .result_ready(odd_result_ready)
    );

    result_arbiter #(.DATA_W(64)) u_arb (
        .clk(clk),
        .rst(rst),
        .s0_valid(even_result_valid),
        .s0_data(even_result_data),
        .s0_ready(even_result_ready),
        .s1_valid(odd_result_valid),
        .s1_data(odd_result_data),
        .s1_ready(odd_result_ready),
        .m_valid(merged_valid),
        .m_data(merged_data),
        .m_ready(merged_ready)
    );

    dma_result_writeback #(
        .ADDR_W(ADDR_W),
        .DATA_W(64),
        .COUNT_W(COUNT_W)
    ) u_store (
        .clk(clk),
        .rst(rst),
        .start(start_sync),
        .base_addr(result_dst_base),
        .total_results(desc_count),
        .busy(store_busy),
        .done(store_done),
        .s_valid(merged_valid),
        .s_data(merged_data),
        .s_ready(merged_ready),
        .mem_wvalid(mem_wvalid),
        .mem_waddr(mem_waddr),
        .mem_wdata(mem_wdata),
        .mem_wlast(mem_wlast),
        .mem_wready(mem_wready)
    );

    assign busy = fetch_busy | store_busy | ~fifo_empty | even_result_valid | odd_result_valid;
    assign done = store_done;
endmodule
