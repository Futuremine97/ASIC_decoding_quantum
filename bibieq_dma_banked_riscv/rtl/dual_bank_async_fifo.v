module dual_bank_async_fifo #(
    parameter DATA_W = 64,
    parameter ADDR_W = 4,
    parameter IDX_W  = 8
) (
    // Write domain
    input  wire               wr_clk,
    input  wire               wr_rst_n,
    input  wire               wr_valid,
    input  wire [DATA_W-1:0]  wr_data,
    input  wire [IDX_W-1:0]   wr_index,
    output wire               wr_ready,

    // Read domain
    input  wire               rd_clk,
    input  wire               rd_rst_n,
    output wire               even_valid,
    output wire [DATA_W-1:0]  even_data,
    input  wire               even_ready,
    output wire               odd_valid,
    output wire [DATA_W-1:0]  odd_data,
    input  wire               odd_ready
);
    wire even_sel;
    wire odd_sel;
    wire even_wr_ready;
    wire odd_wr_ready;

    assign odd_sel  = wr_index[0];
    assign even_sel = ~wr_index[0];

    assign wr_ready = odd_sel ? odd_wr_ready : even_wr_ready;

    async_fifo #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) u_even_fifo (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_valid(wr_valid & even_sel),
        .wr_data(wr_data),
        .wr_ready(even_wr_ready),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_valid(even_valid),
        .rd_data(even_data),
        .rd_ready(even_ready)
    );

    async_fifo #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W)
    ) u_odd_fifo (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_valid(wr_valid & odd_sel),
        .wr_data(wr_data),
        .wr_ready(odd_wr_ready),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_valid(odd_valid),
        .rd_data(odd_data),
        .rd_ready(odd_ready)
    );
endmodule
