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
    integer i;
    reg [Q-1:0] a [0:MAX_SITES-1];
    reg [Q-1:0] r [0:MAX_SITES-1];
    reg [Q:0]   c [0:MAX_SITES-1];

    always @* begin
        // Defaults to avoid any latch inference in combinational logic
        cumulative_bus = {MAX_SITES*Q{1'b0}};
        fault_mask     = {MAX_SITES{1'b0}};

        for (i = 0; i < MAX_SITES; i = i + 1) begin
            a[i] = a_bus[(i*Q) +: Q];
            r[i] = rand_bus[(i*Q) +: Q];
            c[i] = { (Q+1){1'b0} };
        end

        if (MAX_SITES > 0) begin
            c[0] = {1'b0, a[0]};
            cumulative_bus[(0*Q) +: Q] = c[0][Q-1:0];
            if (0 < nsites)
                fault_mask[0] = (r[0] < c[0][Q-1:0]);
        end

        for (i = 1; i < MAX_SITES; i = i + 1) begin
            c[i] = c[i-1] + a[i];
            cumulative_bus[(i*Q) +: Q] = c[i][Q-1:0];
            if (i < nsites)
                fault_mask[i] = (r[i] < c[i][Q-1:0]);
        end
    end
endmodule
