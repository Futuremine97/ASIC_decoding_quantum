module reset_sync (
    input  wire clk,
    input  wire arst_n,
    output wire srst_n
);
    reg [1:0] sync;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            sync <= 2'b00;
        else
            sync <= {sync[0], 1'b1};
    end

    assign srst_n = sync[1];
endmodule
