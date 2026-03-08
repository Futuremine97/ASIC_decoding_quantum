module posterior_calc #(
    parameter Q = 16,
    parameter MAX_SITES = 5
) (
    input  wire [2:0]  r,
    input  wire        ds,
    input  wire [Q-1:0] e_q,
    input  wire [Q-1:0] q_q,
    output reg  [Q-1:0] p_flag_q,
    output reg  [MAX_SITES*Q-1:0] a_bus
);
    localparam [Q-1:0] ONE = {Q{1'b1}};

    function [Q-1:0] qmul;
        input [Q-1:0] a;
        input [Q-1:0] b;
        reg   [2*Q-1:0] prod;
        begin
            prod = a * b;
            qmul = prod >> Q;
        end
    endfunction

    function [Q-1:0] qdiv;
        input [Q-1:0] num;
        input [Q-1:0] den;
        reg   [2*Q-1:0] num_ext;
        begin
            if (den == 0)
                qdiv = 0;
            else begin
                num_ext = num << Q;
                qdiv = num_ext / den;
            end
        end
    endfunction

    reg [Q-1:0] one_minus_e;
    reg [Q-1:0] one_minus_q;
    reg [Q-1:0] pow0, pow1, pow2, pow3, pow4, pow5;
    reg [Q-1:0] pow_n;
    reg [Q-1:0] hit_any;
    reg [Q-1:0] denom;
    reg [Q-1:0] base;
    reg [Q-1:0] a0, a1, a2, a3, a4;

    always @* begin
        one_minus_e = ONE - e_q;
        one_minus_q = ONE - q_q;

        pow0 = ONE;
        pow1 = qmul(pow0, one_minus_e);
        pow2 = qmul(pow1, one_minus_e);
        pow3 = qmul(pow2, one_minus_e);
        pow4 = qmul(pow3, one_minus_e);
        pow5 = qmul(pow4, one_minus_e);

        case (r + 3'd1)
            3'd1: pow_n = pow1;
            3'd2: pow_n = pow2;
            3'd3: pow_n = pow3;
            3'd4: pow_n = pow4;
            default: pow_n = pow5;
        endcase

        hit_any  = ONE - pow_n;
        p_flag_q = qmul(hit_any, one_minus_q) + qmul(pow_n, q_q);
        denom    = ds ? p_flag_q : (ONE - p_flag_q);
        base     = ds ? one_minus_q : q_q;

        a0 = (r >= 3'd0) ? qdiv(qmul(qmul(e_q, pow0), base), denom) : {Q{1'b0}};
        a1 = (r >= 3'd1) ? qdiv(qmul(qmul(e_q, pow1), base), denom) : {Q{1'b0}};
        a2 = (r >= 3'd2) ? qdiv(qmul(qmul(e_q, pow2), base), denom) : {Q{1'b0}};
        a3 = (r >= 3'd3) ? qdiv(qmul(qmul(e_q, pow3), base), denom) : {Q{1'b0}};
        a4 = (r >= 3'd4) ? qdiv(qmul(qmul(e_q, pow4), base), denom) : {Q{1'b0}};

        a_bus = {a4, a3, a2, a1, a0};
    end
endmodule
