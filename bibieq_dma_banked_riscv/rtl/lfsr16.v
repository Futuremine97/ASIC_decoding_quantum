module lfsr16 (
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,
    input  wire [15:0] seed,
    output reg  [15:0] value
);
    wire feedback;
    assign feedback = value[15] ^ value[13] ^ value[12] ^ value[10];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            value <= (seed == 16'd0) ? 16'h1ACE : seed;
        end else if (enable) begin
            value <= {value[14:0], feedback};
        end
    end
endmodule
