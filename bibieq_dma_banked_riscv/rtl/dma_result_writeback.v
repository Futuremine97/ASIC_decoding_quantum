module dma_result_writeback #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64,
    parameter COUNT_W = 16
) (
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire [ADDR_W-1:0]   base_addr,
    input  wire [COUNT_W-1:0]  total_results,
    output reg                 busy,
    output reg                 done,
    input  wire                s_valid,
    input  wire [DATA_W-1:0]   s_data,
    output wire                s_ready,
    output wire                mem_wvalid,
    output wire [ADDR_W-1:0]   mem_waddr,
    output wire [DATA_W-1:0]   mem_wdata,
    output wire                mem_wlast,
    input  wire                mem_wready
);
    localparam integer BYTES_PER_BEAT = DATA_W / 8;

    reg [ADDR_W-1:0]  addr_r;
    reg [COUNT_W-1:0] remaining_r;

    wire fire;

    assign mem_wvalid = busy & s_valid;
    assign mem_wdata  = s_data;
    assign mem_waddr  = addr_r;
    assign mem_wlast  = (remaining_r == {{(COUNT_W-1){1'b0}}, 1'b1});
    assign s_ready    = busy & mem_wready;
    assign fire       = mem_wvalid & mem_wready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy        <= 1'b0;
            done        <= 1'b0;
            addr_r      <= {ADDR_W{1'b0}};
            remaining_r <= {COUNT_W{1'b0}};
        end else begin
            done <= 1'b0;

            if (start) begin
                busy        <= (total_results != {COUNT_W{1'b0}});
                addr_r      <= base_addr;
                remaining_r <= total_results;
            end else if (fire) begin
                if (remaining_r != {COUNT_W{1'b0}})
                    remaining_r <= remaining_r - {{(COUNT_W-1){1'b0}}, 1'b1};

                if (remaining_r == {{(COUNT_W-1){1'b0}}, 1'b1}) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    addr_r <= addr_r + BYTES_PER_BEAT;
                end
            end
        end
    end
endmodule
