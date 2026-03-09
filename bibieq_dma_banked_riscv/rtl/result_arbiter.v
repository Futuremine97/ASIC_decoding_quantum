module result_arbiter #(
    parameter DATA_W = 64
) (
    input  wire              clk,
    input  wire              rst,
    input  wire              s0_valid,
    input  wire [DATA_W-1:0] s0_data,
    output wire              s0_ready,
    input  wire              s1_valid,
    input  wire [DATA_W-1:0] s1_data,
    output wire              s1_ready,
    output wire              m_valid,
    output wire [DATA_W-1:0] m_data,
    input  wire              m_ready
);
    reg rr_sel;
    wire choose_s1;
    wire fire;

    assign choose_s1 = s1_valid & (~s0_valid | rr_sel);

    assign m_valid  = choose_s1 ? s1_valid : s0_valid;
    assign m_data   = choose_s1 ? s1_data  : s0_data;
    assign s0_ready = m_ready & m_valid & ~choose_s1;
    assign s1_ready = m_ready & m_valid &  choose_s1;
    assign fire     = m_valid & m_ready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_sel <= 1'b0;
        end else if (fire) begin
            if (s0_valid & s1_valid)
                rr_sel <= ~rr_sel;
            else if (s0_valid)
                rr_sel <= 1'b1;
            else if (s1_valid)
                rr_sel <= 1'b0;
        end
    end
endmodule
