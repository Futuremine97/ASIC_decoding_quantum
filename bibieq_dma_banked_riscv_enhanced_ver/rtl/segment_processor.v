module segment_processor #(
    parameter Q = 16,
    parameter MAX_SITES = 5,
    parameter FAST_MODE = 0
) (
    input  wire [2:0]  r,
    input  wire        ds,
    input  wire [Q-1:0] e_q,
    input  wire [Q-1:0] q_q,
    input  wire [Q-1:0] rand_exact,
    input  wire [MAX_SITES*Q-1:0] rand_approx,
    output wire [Q-1:0] p_flag_q,
    output wire [MAX_SITES*Q-1:0] a_bus,
    output wire [MAX_SITES-1:0] exact_mask,
    output wire [2:0] exact_first_hit_idx,
    output wire       exact_first_hit_valid,
    output wire [MAX_SITES-1:0] approx_mask,
    output wire [MAX_SITES*Q-1:0] approx_cumulative_bus
);
    wire [2:0] nsites;
    assign nsites = r + 3'd1;

    posterior_calc #(.Q(Q), .MAX_SITES(MAX_SITES)) u_post (
        .r(r),
        .ds(ds),
        .e_q(e_q),
        .q_q(q_q),
        .p_flag_q(p_flag_q),
        .a_bus(a_bus)
    );

    generate
        if (FAST_MODE) begin : gen_fast_mode
            assign exact_mask = {MAX_SITES{1'b0}};
            assign exact_first_hit_idx = 3'd0;
            assign exact_first_hit_valid = 1'b0;
        end else begin : gen_full_mode
            engine_exact #(.Q(Q), .MAX_SITES(MAX_SITES)) u_exact (
                .nsites(nsites),
                .a_bus(a_bus),
                .rand_u(rand_exact),
                .fault_mask(exact_mask),
                .first_hit_idx(exact_first_hit_idx),
                .first_hit_valid(exact_first_hit_valid)
            );
        end
    endgenerate

    engine_approx #(.Q(Q), .MAX_SITES(MAX_SITES)) u_approx (
        .nsites(nsites),
        .a_bus(a_bus),
        .rand_bus(rand_approx),
        .fault_mask(approx_mask),
        .cumulative_bus(approx_cumulative_bus)
    );
endmodule
