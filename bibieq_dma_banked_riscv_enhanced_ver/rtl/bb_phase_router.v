module bb_phase_router #(
    parameter L = 6,
    parameter M = 6,
    parameter UW = 4,
    parameter VW = 4
) (
    input  wire [2:0] phase,
    input  wire [UW-1:0] u,
    input  wire [VW-1:0] v,
    output reg         x_valid,
    output reg         x_target_is_l,
    output reg         x_target_is_r,
    output reg [UW-1:0] x_u,
    output reg [VW-1:0] x_v,
    output reg         z_valid,
    output reg         z_source_is_l,
    output reg         z_source_is_r,
    output reg [UW-1:0] z_u,
    output reg [VW-1:0] z_v
);
    function integer wrap_u;
        input integer base;
        input integer delta;
        integer tmp;
        begin
            tmp = base + delta;
            while (tmp < 0)
                tmp = tmp + L;
            while (tmp >= L)
                tmp = tmp - L;
            wrap_u = tmp;
        end
    endfunction

    function integer wrap_v;
        input integer base;
        input integer delta;
        integer tmp;
        begin
            tmp = base + delta;
            while (tmp < 0)
                tmp = tmp + M;
            while (tmp >= M)
                tmp = tmp - M;
            wrap_v = tmp;
        end
    endfunction

    integer xu_tmp;
    integer xv_tmp;
    integer zu_tmp;
    integer zv_tmp;

    always @* begin
        x_valid = 1'b0;
        z_valid = 1'b0;
        x_target_is_l = 1'b0;
        x_target_is_r = 1'b0;
        z_source_is_l = 1'b0;
        z_source_is_r = 1'b0;
        xu_tmp = u;
        xv_tmp = v;
        zu_tmp = u;
        zv_tmp = v;

        case (phase)
            3'd1: begin
                z_valid = 1'b1;
                z_source_is_r = 1'b1;
                zu_tmp = wrap_u(u, -3); // A1^T = (-3,0)
                zv_tmp = wrap_v(v,  0);
            end
            3'd2: begin
                x_valid = 1'b1;
                x_target_is_l = 1'b1;
                xu_tmp = wrap_u(u, 0);  // A2 = (0,1)
                xv_tmp = wrap_v(v, 1);

                z_valid = 1'b1;
                z_source_is_r = 1'b1;
                zu_tmp = wrap_u(u, 0);  // A3^T = (0,-2)
                zv_tmp = wrap_v(v, -2);
            end
            3'd3: begin
                x_valid = 1'b1;
                x_target_is_r = 1'b1;
                xu_tmp = wrap_u(u, 1);  // B2 = (1,0)
                xv_tmp = wrap_v(v, 0);

                z_valid = 1'b1;
                z_source_is_l = 1'b1;
                zu_tmp = wrap_u(u, 0);  // B1^T = (0,-3)
                zv_tmp = wrap_v(v, -3);
            end
            3'd4: begin
                x_valid = 1'b1;
                x_target_is_r = 1'b1;
                xu_tmp = wrap_u(u, 0);  // B1 = (0,3)
                xv_tmp = wrap_v(v, 3);

                z_valid = 1'b1;
                z_source_is_l = 1'b1;
                zu_tmp = wrap_u(u, -1); // B2^T = (-1,0)
                zv_tmp = wrap_v(v,  0);
            end
            3'd5: begin
                x_valid = 1'b1;
                x_target_is_r = 1'b1;
                xu_tmp = wrap_u(u, 2);  // B3 = (2,0)
                xv_tmp = wrap_v(v, 0);

                z_valid = 1'b1;
                z_source_is_l = 1'b1;
                zu_tmp = wrap_u(u, -2); // B3^T = (-2,0)
                zv_tmp = wrap_v(v,  0);
            end
            3'd6: begin
                x_valid = 1'b1;
                x_target_is_l = 1'b1;
                xu_tmp = wrap_u(u, 3);  // A1 = (3,0)
                xv_tmp = wrap_v(v, 0);

                z_valid = 1'b1;
                z_source_is_r = 1'b1;
                zu_tmp = wrap_u(u, 0);  // A2^T = (0,-1)
                zv_tmp = wrap_v(v, -1);
            end
            3'd7: begin
                x_valid = 1'b1;
                x_target_is_l = 1'b1;
                xu_tmp = wrap_u(u, 0);  // A3 = (0,2)
                xv_tmp = wrap_v(v, 2);
            end
            default: begin
                x_valid = 1'b0;
                z_valid = 1'b0;
            end
        endcase

        x_u = xu_tmp[UW-1:0];
        x_v = xv_tmp[VW-1:0];
        z_u = zu_tmp[UW-1:0];
        z_v = zv_tmp[VW-1:0];
    end
endmodule
