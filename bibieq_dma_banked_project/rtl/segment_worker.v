module segment_worker #(
    parameter Q = 16,
    parameter MAX_SITES = 5,
    parameter UW = 4,
    parameter VW = 4,
    parameter L = 6,
    parameter M = 6,
    parameter SEED0 = 16'h1234,
    parameter SEED1 = 16'h2345,
    parameter SEED2 = 16'h3456,
    parameter SEED3 = 16'h4567,
    parameter SEED4 = 16'h5678,
    parameter SEED5 = 16'h6789
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        desc_valid,
    input  wire [63:0] desc_data,
    output wire        desc_ready,
    output wire        result_valid,
    output wire [63:0] result_data,
    input  wire        result_ready
);
    // Descriptor format (64-bit)
    // [63:56] seg_idx
    // [55]    use_4ec
    // [54:52] phase
    // [51:49] r
    // [48]    ds
    // [47:32] e_q (Q0.16)
    // [31:16] q_q (Q0.16)
    // [15:12] u
    // [11:8]  v
    // [7:0]   reserved

    wire [7:0] seg_idx;
    wire       use_4ec;
    wire [2:0] phase;
    wire [2:0] r;
    wire       ds;
    wire [Q-1:0] e_q;
    wire [Q-1:0] q_q;
    wire [UW-1:0] u;
    wire [VW-1:0] v;

    assign seg_idx  = desc_data[63:56];
    assign use_4ec  = desc_data[55];
    assign phase    = desc_data[54:52];
    assign r        = desc_data[51:49];
    assign ds       = desc_data[48];
    assign e_q      = desc_data[47:32];
    assign q_q      = desc_data[31:16];
    assign u        = desc_data[15:12];
    assign v        = desc_data[11:8];

    wire [15:0] rand0, rand1, rand2, rand3, rand4, rand5;
    wire desc_fire;

    wire        checkpoint_valid;
    wire [1:0]  checkpoint_id;
    wire [Q-1:0] p_flag_q;
    wire [MAX_SITES*Q-1:0] a_bus_unused;
    wire [MAX_SITES-1:0] exact_mask;
    wire [2:0]  exact_first_hit_idx;
    wire        exact_first_hit_valid;
    wire [MAX_SITES-1:0] approx_mask;
    wire [MAX_SITES*Q-1:0] approx_cumulative_unused;
    wire        x_valid;
    wire        x_target_is_l;
    wire        x_target_is_r;
    wire [UW-1:0] x_u;
    wire [VW-1:0] x_v;
    wire        z_valid;
    wire        z_source_is_l;
    wire        z_source_is_r;
    wire [UW-1:0] z_u;
    wire [VW-1:0] z_v;

    reg         out_valid_r;
    reg  [63:0] out_data_r;

    assign desc_ready  = ~out_valid_r | result_ready;
    assign desc_fire   = desc_valid & desc_ready;
    assign result_valid = out_valid_r;
    assign result_data  = out_data_r;

    lfsr16 u_rng0 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED0), .value(rand0));
    lfsr16 u_rng1 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED1), .value(rand1));
    lfsr16 u_rng2 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED2), .value(rand2));
    lfsr16 u_rng3 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED3), .value(rand3));
    lfsr16 u_rng4 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED4), .value(rand4));
    lfsr16 u_rng5 (.clk(clk), .rst(rst), .enable(desc_fire), .seed(SEED5), .value(rand5));

    ec_schedule_ctrl u_sched (
        .phase(phase),
        .use_4ec(use_4ec),
        .checkpoint_valid(checkpoint_valid),
        .checkpoint_id(checkpoint_id)
    );

    bb_phase_router #(.L(L), .M(M), .UW(UW), .VW(VW)) u_router (
        .phase(phase),
        .u(u),
        .v(v),
        .x_valid(x_valid),
        .x_target_is_l(x_target_is_l),
        .x_target_is_r(x_target_is_r),
        .x_u(x_u),
        .x_v(x_v),
        .z_valid(z_valid),
        .z_source_is_l(z_source_is_l),
        .z_source_is_r(z_source_is_r),
        .z_u(z_u),
        .z_v(z_v)
    );

    segment_processor #(.Q(Q), .MAX_SITES(MAX_SITES)) u_seg (
        .r(r),
        .ds(ds),
        .e_q(e_q),
        .q_q(q_q),
        .rand_exact(rand0),
        .rand_approx({rand5, rand4, rand3, rand2, rand1}),
        .p_flag_q(p_flag_q),
        .a_bus(a_bus_unused),
        .exact_mask(exact_mask),
        .exact_first_hit_idx(exact_first_hit_idx),
        .exact_first_hit_valid(exact_first_hit_valid),
        .approx_mask(approx_mask),
        .approx_cumulative_bus(approx_cumulative_unused)
    );

    wire [63:0] packed_result;
    assign packed_result = {
        seg_idx,                  // [63:56]
        checkpoint_valid,         // [55]
        checkpoint_id,            // [54:53]
        exact_mask,               // [52:48]
        approx_mask,              // [47:43]
        exact_first_hit_valid,    // [42]
        exact_first_hit_idx,      // [41:39]
        p_flag_q,                 // [38:23]
        x_valid,                  // [22]
        x_target_is_l,            // [21]
        x_target_is_r,            // [20]
        x_u,                      // [19:16]
        x_v,                      // [15:12]
        z_valid,                  // [11]
        z_source_is_l,            // [10]
        z_source_is_r,            // [9]
        z_u,                      // [8:5]
        z_v,                      // [4:1]
        1'b0                      // [0]
    };

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid_r <= 1'b0;
            out_data_r  <= 64'd0;
        end else begin
            if (desc_fire) begin
                out_valid_r <= 1'b1;
                out_data_r  <= packed_result;
            end else if (out_valid_r & result_ready) begin
                out_valid_r <= 1'b0;
            end
        end
    end
endmodule
