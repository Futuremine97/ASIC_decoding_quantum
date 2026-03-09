`timescale 1ns/1ps
module tb_bibieq_dma_banked_top;
    reg clk;
    reg rst;
    reg start;
    wire busy;
    wire done;

    wire rd_cmd_valid;
    reg  rd_cmd_ready;
    wire [31:0] rd_cmd_addr;
    wire [7:0]  rd_cmd_len;
    reg  mem_rvalid;
    reg  [63:0] mem_rdata;
    reg  mem_rlast;
    wire mem_rready;

    wire mem_wvalid;
    wire [31:0] mem_waddr;
    wire [63:0] mem_wdata;
    wire mem_wlast;
    reg  mem_wready;

    wire [4:0] fifo_even_level;
    wire [4:0] fifo_odd_level;
    wire fetch_done;
    wire store_done;

    reg [63:0] desc_mem [0:7];
    integer cmd_idx;
    integer beats_left;
    integer stream_ptr;

    bibieq_dma_banked_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .desc_src_base(32'd0),
        .desc_count(16'd4),
        .rd_burst_len(8'd2),
        .result_dst_base(32'd1024),
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

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        rd_cmd_ready = 1;
        mem_rvalid = 0;
        mem_rdata = 64'd0;
        mem_rlast = 0;
        mem_wready = 1;
        cmd_idx = 0;
        beats_left = 0;
        stream_ptr = 0;

        // seg_idx[63:56], use_4ec[55], phase[54:52], r[51:49], ds[48], e_q[47:32], q_q[31:16], u[15:12], v[11:8]
        desc_mem[0] = {8'd0,1'b1,3'd2,3'd2,1'b1,16'd6553,16'd6553,4'd1,4'd2,8'd0};
        desc_mem[1] = {8'd1,1'b0,3'd4,3'd3,1'b0,16'd8192,16'd4096,4'd2,4'd3,8'd0};
        desc_mem[2] = {8'd2,1'b1,3'd6,3'd4,1'b1,16'd9830,16'd9830,4'd3,4'd1,8'd0};
        desc_mem[3] = {8'd3,1'b1,3'd7,3'd1,1'b0,16'd3276,16'd3276,4'd4,4'd0,8'd0};

        #20 rst = 0;
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        #300 $finish;
    end

    always @(posedge clk) begin
        if (rst) begin
            beats_left <= 0;
            stream_ptr <= 0;
            mem_rvalid <= 0;
            mem_rlast  <= 0;
            mem_rdata  <= 64'd0;
        end else begin
            if (rd_cmd_valid && rd_cmd_ready) begin
                beats_left <= rd_cmd_len;
                stream_ptr <= rd_cmd_addr[31:3];
            end

            if ((beats_left > 0) && mem_rready) begin
                mem_rvalid <= 1'b1;
                mem_rdata  <= desc_mem[stream_ptr];
                mem_rlast  <= (beats_left == 1);
                stream_ptr <= stream_ptr + 1;
                beats_left <= beats_left - 1;
            end else begin
                mem_rvalid <= 1'b0;
                mem_rlast  <= 1'b0;
            end
        end
    end
endmodule
