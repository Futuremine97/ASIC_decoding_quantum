`timescale 1ns/1ps
module tb_dual_bank_fifo;
    reg clk;
    reg rst;
    reg in_valid;
    reg [63:0] in_data;
    reg [7:0] in_index;
    wire in_ready;
    wire even_valid;
    wire [63:0] even_data;
    reg even_ready;
    wire odd_valid;
    wire [63:0] odd_data;
    reg odd_ready;
    wire [4:0] even_level;
    wire [4:0] odd_level;
    wire empty;
    wire full_even;
    wire full_odd;

    dual_bank_fifo #(.DATA_W(64), .DEPTH(16), .PTR_W(4), .IDX_W(8)) dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_data(in_data), .in_index(in_index), .in_ready(in_ready),
        .even_valid(even_valid), .even_data(even_data), .even_ready(even_ready),
        .odd_valid(odd_valid), .odd_data(odd_data), .odd_ready(odd_ready),
        .even_level(even_level), .odd_level(odd_level), .empty(empty), .full_even(full_even), .full_odd(full_odd)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        in_valid = 0;
        in_data = 64'd0;
        in_index = 8'd0;
        even_ready = 0;
        odd_ready = 0;

        #20 rst = 0;

        // enqueue even, odd, even, odd
        push_desc(8'd0, 64'h00AA000000000001);
        push_desc(8'd1, 64'h01BB000000000002);
        push_desc(8'd2, 64'h02CC000000000003);
        push_desc(8'd3, 64'h03DD000000000004);

        #10;
        even_ready = 1;
        odd_ready  = 1;
        #40;
        even_ready = 0;
        odd_ready  = 0;

        #20 $finish;
    end

    task push_desc;
        input [7:0] idx;
        input [63:0] data;
        begin
            @(posedge clk);
            in_valid <= 1'b1;
            in_index <= idx;
            in_data  <= data;
            while (!in_ready)
                @(posedge clk);
            @(posedge clk);
            in_valid <= 1'b0;
        end
    endtask
endmodule
