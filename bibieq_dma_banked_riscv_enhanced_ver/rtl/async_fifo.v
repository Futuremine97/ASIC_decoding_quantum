module async_fifo #(
    parameter DATA_W = 64,
    parameter ADDR_W = 4
) (
    // Write domain
    input  wire                 wr_clk,
    input  wire                 wr_rst_n,
    input  wire                 wr_valid,
    input  wire [DATA_W-1:0]    wr_data,
    output wire                 wr_ready,

    // Read domain
    input  wire                 rd_clk,
    input  wire                 rd_rst_n,
    output wire                 rd_valid,
    output wire [DATA_W-1:0]    rd_data,
    input  wire                 rd_ready
);
    localparam DEPTH = (1 << ADDR_W);

    reg [DATA_W-1:0] mem [0:DEPTH-1];

    // Binary and Gray pointers (ADDR_W+1 for full/empty)
    reg [ADDR_W:0] wr_ptr_bin;
    reg [ADDR_W:0] wr_ptr_gray;
    reg [ADDR_W:0] rd_ptr_bin;
    reg [ADDR_W:0] rd_ptr_gray;

    // Sync gray pointers across domains
    reg [ADDR_W:0] rd_ptr_gray_sync1;
    reg [ADDR_W:0] rd_ptr_gray_sync2;
    reg [ADDR_W:0] wr_ptr_gray_sync1;
    reg [ADDR_W:0] wr_ptr_gray_sync2;

    function [ADDR_W:0] bin2gray;
        input [ADDR_W:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    wire [ADDR_W:0] wr_ptr_bin_next;
    wire [ADDR_W:0] wr_ptr_gray_next;
    wire [ADDR_W:0] rd_ptr_bin_next;
    wire [ADDR_W:0] rd_ptr_gray_next;

    wire full;
    wire empty;
    wire wr_fire;
    wire rd_fire;

    assign wr_fire = wr_valid & wr_ready;
    assign rd_fire = rd_valid & rd_ready;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_fire ? {{ADDR_W{1'b0}}, 1'b1} : { (ADDR_W+1){1'b0} });
    assign wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_fire ? {{ADDR_W{1'b0}}, 1'b1} : { (ADDR_W+1){1'b0} });
    assign rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);

    // Full when next write pointer == synchronized read pointer with MSBs inverted
    assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_W:ADDR_W-1], rd_ptr_gray_sync2[ADDR_W-2:0]});
    assign wr_ready = ~full;

    // Empty when next read pointer == synchronized write pointer
    assign empty = (rd_ptr_gray_next == wr_ptr_gray_sync2);
    assign rd_valid = ~empty;

    assign rd_data = mem[rd_ptr_bin[ADDR_W-1:0]];

    // Write domain logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {(ADDR_W+1){1'b0}};
            wr_ptr_gray <= {(ADDR_W+1){1'b0}};
        end else begin
            if (wr_fire) begin
                mem[wr_ptr_bin[ADDR_W-1:0]] <= wr_data;
                wr_ptr_bin  <= wr_ptr_bin_next;
                wr_ptr_gray <= wr_ptr_gray_next;
            end
        end
    end

    // Read domain logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {(ADDR_W+1){1'b0}};
            rd_ptr_gray <= {(ADDR_W+1){1'b0}};
        end else begin
            if (rd_fire) begin
                rd_ptr_bin  <= rd_ptr_bin_next;
                rd_ptr_gray <= rd_ptr_gray_next;
            end
        end
    end

    // Synchronize pointers
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= {(ADDR_W+1){1'b0}};
            rd_ptr_gray_sync2 <= {(ADDR_W+1){1'b0}};
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= {(ADDR_W+1){1'b0}};
            wr_ptr_gray_sync2 <= {(ADDR_W+1){1'b0}};
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
endmodule
