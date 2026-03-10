module engine_exact #(
    parameter Q = 16,
    parameter MAX_SITES = 5
) (
    input  wire [2:0]  nsites,
    input  wire [MAX_SITES*Q-1:0] a_bus,
    input  wire [Q-1:0] rand_u,
    output reg  [MAX_SITES-1:0] fault_mask,
    output reg  [2:0] first_hit_idx,
    output reg        first_hit_valid
);
    reg [Q-1:0] a0, a1, a2, a3, a4;
    reg [Q:0] cumulative;
    integer i;
    reg [2:0] hit_idx_tmp;
    reg hit_valid_tmp;

    always @* begin
        a0 = a_bus[(0*Q) +: Q];
        a1 = a_bus[(1*Q) +: Q];
        a2 = a_bus[(2*Q) +: Q];
        a3 = a_bus[(3*Q) +: Q];
        a4 = a_bus[(4*Q) +: Q];

        hit_idx_tmp   = 3'd0;
        hit_valid_tmp = 1'b0;
        cumulative    = {1'b0, {Q{1'b0}}};

        if ((nsites >= 3'd1) && !hit_valid_tmp) begin
            cumulative = cumulative + a0;
            if (rand_u < cumulative[Q-1:0]) begin
                hit_idx_tmp   = 3'd0;
                hit_valid_tmp = 1'b1;
            end
        end
        if ((nsites >= 3'd2) && !hit_valid_tmp) begin
            cumulative = cumulative + a1;
            if (rand_u < cumulative[Q-1:0]) begin
                hit_idx_tmp   = 3'd1;
                hit_valid_tmp = 1'b1;
            end
        end
        if ((nsites >= 3'd3) && !hit_valid_tmp) begin
            cumulative = cumulative + a2;
            if (rand_u < cumulative[Q-1:0]) begin
                hit_idx_tmp   = 3'd2;
                hit_valid_tmp = 1'b1;
            end
        end
        if ((nsites >= 3'd4) && !hit_valid_tmp) begin
            cumulative = cumulative + a3;
            if (rand_u < cumulative[Q-1:0]) begin
                hit_idx_tmp   = 3'd3;
                hit_valid_tmp = 1'b1;
            end
        end
        if ((nsites >= 3'd5) && !hit_valid_tmp) begin
            cumulative = cumulative + a4;
            if (rand_u < cumulative[Q-1:0]) begin
                hit_idx_tmp   = 3'd4;
                hit_valid_tmp = 1'b1;
            end
        end

        fault_mask      = {MAX_SITES{1'b0}};
        first_hit_idx   = hit_idx_tmp;
        first_hit_valid = hit_valid_tmp;

        if (hit_valid_tmp) begin
            for (i = 0; i < MAX_SITES; i = i + 1) begin
                if ((i >= hit_idx_tmp) && (i < nsites))
                    fault_mask[i] = 1'b1;
            end
        end
    end
endmodule
