module ec_schedule_ctrl (
    input  wire [2:0] phase,
    input  wire       use_4ec,
    output reg        checkpoint_valid,
    output reg [1:0]  checkpoint_id
);
    // Hardware-friendly bundle boundary mapping:
    // A->after phase 2, B->after phase 4, C->after phase 6, D->after phase 7.
    // 4EC uses A/B/C/D, 2EC uses B/D.
    always @* begin
        checkpoint_valid = 1'b0;
        checkpoint_id    = 2'd0;
        case (phase)
            3'd2: begin
                checkpoint_id    = 2'd0; // A
                checkpoint_valid = use_4ec;
            end
            3'd4: begin
                checkpoint_id    = 2'd1; // B
                checkpoint_valid = 1'b1;
            end
            3'd6: begin
                checkpoint_id    = 2'd2; // C
                checkpoint_valid = use_4ec;
            end
            3'd7: begin
                checkpoint_id    = 2'd3; // D
                checkpoint_valid = 1'b1;
            end
            default: begin
                checkpoint_valid = 1'b0;
                checkpoint_id    = 2'd0;
            end
        endcase
    end
endmodule
