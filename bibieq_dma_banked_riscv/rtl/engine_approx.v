module engine_approx #(
    parameter Q = 16,
    parameter MAX_SITES = 5
) (
    input  wire [2:0]  nsites,
    input  wire [MAX_SITES*Q-1:0] a_bus,
    input  wire [MAX_SITES*Q-1:0] rand_bus,
    output reg  [MAX_SITES-1:0] fault_mask,
    output reg  [MAX_SITES*Q-1:0] cumulative_bus
);
    reg [Q-1:0] a0, a1, a2, a3, a4;
    reg [Q-1:0] r0, r1, r2, r3, r4;
    reg [Q:0] c0, c1, c2, c3, c4;

    always @* begin
        a0 = a_bus[(0*Q) +: Q];
        a1 = a_bus[(1*Q) +: Q];
        a2 = a_bus[(2*Q) +: Q];
        a3 = a_bus[(3*Q) +: Q];
        a4 = a_bus[(4*Q) +: Q];

        r0 = rand_bus[(0*Q) +: Q];
        r1 = rand_bus[(1*Q) +: Q];
        r2 = rand_bus[(2*Q) +: Q];
        r3 = rand_bus[(3*Q) +: Q];
        r4 = rand_bus[(4*Q) +: Q];

        c0 = a0;
        c1 = a0 + a1;
        c2 = a0 + a1 + a2;
        c3 = a0 + a1 + a2 + a3;
        c4 = a0 + a1 + a2 + a3 + a4;

        cumulative_bus = {c4[Q-1:0], c3[Q-1:0], c2[Q-1:0], c1[Q-1:0], c0[Q-1:0]};

        fault_mask[0] = (nsites >= 3'd1) && (r0 < c0[Q-1:0]);
        fault_mask[1] = (nsites >= 3'd2) && (r1 < c1[Q-1:0]);
        fault_mask[2] = (nsites >= 3'd3) && (r2 < c2[Q-1:0]);
        fault_mask[3] = (nsites >= 3'd4) && (r3 < c3[Q-1:0]);
        fault_mask[4] = (nsites >= 3'd5) && (r4 < c4[Q-1:0]);
    end
endmodule
