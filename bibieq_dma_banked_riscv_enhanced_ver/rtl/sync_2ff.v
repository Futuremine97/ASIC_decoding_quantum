module sync_2ff #(
    parameter INIT = 1'b0
) (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output wire q
);
    reg ff1;
    reg ff2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ff1 <= INIT;
            ff2 <= INIT;
        end else begin
            ff1 <= d;
            ff2 <= ff1;
        end
    end

    assign q = ff2;
endmodule
