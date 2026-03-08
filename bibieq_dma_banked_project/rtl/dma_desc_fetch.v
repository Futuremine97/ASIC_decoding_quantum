module dma_desc_fetch #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64,
    parameter COUNT_W = 16
) (
    input  wire                clk,
    input  wire                rst,
    input  wire                start,
    input  wire [ADDR_W-1:0]   base_addr,
    input  wire [COUNT_W-1:0]  desc_count,
    input  wire [7:0]          burst_len,
    output reg                 busy,
    output reg                 done,
    output wire                rd_cmd_valid,
    input  wire                rd_cmd_ready,
    output wire [ADDR_W-1:0]   rd_cmd_addr,
    output wire [7:0]          rd_cmd_len,
    input  wire                mem_rvalid,
    input  wire [DATA_W-1:0]   mem_rdata,
    input  wire                mem_rlast,
    output wire                mem_rready,
    output wire                desc_valid,
    output wire [DATA_W-1:0]   desc_data,
    output wire [7:0]          desc_index,
    output wire                desc_last,
    input  wire                desc_ready
);
    localparam integer BYTES_PER_BEAT = DATA_W / 8;

    reg [ADDR_W-1:0]  cmd_addr_r;
    reg [COUNT_W-1:0] remaining_r;
    reg [7:0]         inflight_beats_r;

    wire [7:0] effective_burst;
    wire [7:0] next_burst;
    wire       cmd_fire;
    wire       desc_fire;

    assign effective_burst = (burst_len == 8'd0) ? 8'd1 : burst_len;
    assign next_burst = (remaining_r < effective_burst) ? remaining_r[7:0] : effective_burst;

    assign rd_cmd_valid = busy & (inflight_beats_r == 8'd0) & (remaining_r != {COUNT_W{1'b0}});
    assign rd_cmd_addr  = cmd_addr_r;
    assign rd_cmd_len   = next_burst;
    assign cmd_fire     = rd_cmd_valid & rd_cmd_ready;

    assign desc_valid   = busy & mem_rvalid;
    assign desc_data    = mem_rdata;
    assign desc_index   = mem_rdata[63:56];
    assign mem_rready   = busy & desc_ready;
    assign desc_fire    = desc_valid & desc_ready;
    assign desc_last    = desc_fire & (remaining_r == {{(COUNT_W-1){1'b0}},1'b1});

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy             <= 1'b0;
            done             <= 1'b0;
            cmd_addr_r       <= {ADDR_W{1'b0}};
            remaining_r      <= {COUNT_W{1'b0}};
            inflight_beats_r <= 8'd0;
        end else begin
            done <= 1'b0;

            if (start) begin
                busy             <= (desc_count != {COUNT_W{1'b0}});
                cmd_addr_r       <= base_addr;
                remaining_r      <= desc_count;
                inflight_beats_r <= 8'd0;
            end else begin
                if (cmd_fire) begin
                    cmd_addr_r       <= cmd_addr_r + (next_burst * BYTES_PER_BEAT);
                    inflight_beats_r <= next_burst;
                end

                if (desc_fire) begin
                    if (remaining_r != {COUNT_W{1'b0}})
                        remaining_r <= remaining_r - {{(COUNT_W-1){1'b0}},1'b1};

                    if (inflight_beats_r != 8'd0)
                        inflight_beats_r <= inflight_beats_r - 8'd1;

                    if (remaining_r == {{(COUNT_W-1){1'b0}},1'b1}) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                end

                // Safety: if memory marks last beat early, force command window closed.
                if (desc_fire && mem_rlast)
                    inflight_beats_r <= 8'd0;
            end
        end
    end
endmodule
