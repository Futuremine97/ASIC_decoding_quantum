module dual_bank_fifo #(
    parameter DATA_W = 64,
    parameter DEPTH  = 16,
    parameter PTR_W  = 4,
    parameter IDX_W  = 8
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               in_valid,
    input  wire [DATA_W-1:0]  in_data,
    input  wire [IDX_W-1:0]   in_index,
    output wire               in_ready,
    output wire               even_valid,
    output wire [DATA_W-1:0]  even_data,
    input  wire               even_ready,
    output wire               odd_valid,
    output wire [DATA_W-1:0]  odd_data,
    input  wire               odd_ready,
    output wire [PTR_W:0]     even_level,
    output wire [PTR_W:0]     odd_level,
    output wire               empty,
    output wire               full_even,
    output wire               full_odd
);
    reg [DATA_W-1:0] mem_even [0:DEPTH-1];
    reg [DATA_W-1:0] mem_odd  [0:DEPTH-1];

    reg [PTR_W-1:0] wr_ptr_even;
    reg [PTR_W-1:0] rd_ptr_even;
    reg [PTR_W-1:0] wr_ptr_odd;
    reg [PTR_W-1:0] rd_ptr_odd;
    reg [PTR_W:0]   count_even;
    reg [PTR_W:0]   count_odd;

    wire wr_to_odd;
    wire wr_to_even;
    wire wr_fire;
    wire rd_even_fire;
    wire rd_odd_fire;
    wire wr_even_fire;
    wire wr_odd_fire;

    assign wr_to_odd   = in_index[0];
    assign wr_to_even  = ~in_index[0];
    assign full_even   = (count_even == DEPTH);
    assign full_odd    = (count_odd  == DEPTH);
    assign in_ready    = wr_to_odd ? ~full_odd : ~full_even;
    assign wr_fire     = in_valid & in_ready;

    assign even_valid  = (count_even != 0);
    assign odd_valid   = (count_odd  != 0);
    assign even_data   = mem_even[rd_ptr_even];
    assign odd_data    = mem_odd[rd_ptr_odd];
    assign rd_even_fire = even_valid & even_ready;
    assign rd_odd_fire  = odd_valid  & odd_ready;
    assign wr_even_fire = wr_fire & wr_to_even;
    assign wr_odd_fire  = wr_fire & wr_to_odd;

    assign even_level = count_even;
    assign odd_level  = count_odd;
    assign empty      = (count_even == 0) & (count_odd == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_even <= {PTR_W{1'b0}};
            rd_ptr_even <= {PTR_W{1'b0}};
            wr_ptr_odd  <= {PTR_W{1'b0}};
            rd_ptr_odd  <= {PTR_W{1'b0}};
            count_even  <= {(PTR_W+1){1'b0}};
            count_odd   <= {(PTR_W+1){1'b0}};
        end else begin
            if (wr_even_fire) begin
                mem_even[wr_ptr_even] <= in_data;
                wr_ptr_even <= wr_ptr_even + {{(PTR_W-1){1'b0}}, 1'b1};
            end
            if (rd_even_fire) begin
                rd_ptr_even <= rd_ptr_even + {{(PTR_W-1){1'b0}}, 1'b1};
            end
            case ({wr_even_fire, rd_even_fire})
                2'b10: count_even <= count_even + {{PTR_W{1'b0}}, 1'b1};
                2'b01: count_even <= count_even - {{PTR_W{1'b0}}, 1'b1};
                default: count_even <= count_even;
            endcase

            if (wr_odd_fire) begin
                mem_odd[wr_ptr_odd] <= in_data;
                wr_ptr_odd <= wr_ptr_odd + {{(PTR_W-1){1'b0}}, 1'b1};
            end
            if (rd_odd_fire) begin
                rd_ptr_odd <= rd_ptr_odd + {{(PTR_W-1){1'b0}}, 1'b1};
            end
            case ({wr_odd_fire, rd_odd_fire})
                2'b10: count_odd <= count_odd + {{PTR_W{1'b0}}, 1'b1};
                2'b01: count_odd <= count_odd - {{PTR_W{1'b0}}, 1'b1};
                default: count_odd <= count_odd;
            endcase
        end
    end
endmodule
