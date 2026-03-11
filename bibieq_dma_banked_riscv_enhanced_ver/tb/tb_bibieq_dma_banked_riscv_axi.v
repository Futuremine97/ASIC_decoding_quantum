`timescale 1ns/1ps
module tb_bibieq_dma_banked_riscv_axi;
    parameter FAST_MODE = 0;

    localparam ADDR_W = 32;
    localparam DATA_W = 64;
    localparam COUNT_W = 16;
    localparam FIFO_DEPTH = 16;
    localparam FIFO_PTR_W = 4;
    localparam MAX_DESC = 64;

    reg aclk;
    reg aresetn;

    // AXI4-Lite signals
    reg  [ADDR_W-1:0] s_axi_awaddr;
    reg  [2:0]        s_axi_awprot;
    reg               s_axi_awvalid;
    wire              s_axi_awready;
    reg  [31:0]       s_axi_wdata;
    reg  [3:0]        s_axi_wstrb;
    reg               s_axi_wvalid;
    wire              s_axi_wready;
    wire [1:0]        s_axi_bresp;
    wire              s_axi_bvalid;
    reg               s_axi_bready;
    reg  [ADDR_W-1:0] s_axi_araddr;
    reg  [2:0]        s_axi_arprot;
    reg               s_axi_arvalid;
    wire              s_axi_arready;
    wire [31:0]       s_axi_rdata;
    wire [1:0]        s_axi_rresp;
    wire              s_axi_rvalid;
    reg               s_axi_rready;

    // AXI4 read master signals (to memory model)
    wire [ADDR_W-1:0] m_axi_araddr;
    wire [7:0]        m_axi_arlen;
    wire [2:0]        m_axi_arsize;
    wire [1:0]        m_axi_arburst;
    wire              m_axi_arvalid;
    reg               m_axi_arready;
    reg  [DATA_W-1:0] m_axi_rdata;
    reg  [1:0]        m_axi_rresp;
    reg               m_axi_rlast;
    reg               m_axi_rvalid;
    wire              m_axi_rready;

    // AXI4 write master signals (to memory model)
    wire [ADDR_W-1:0] m_axi_awaddr;
    wire [7:0]        m_axi_awlen;
    wire [2:0]        m_axi_awsize;
    wire [1:0]        m_axi_awburst;
    wire              m_axi_awvalid;
    reg               m_axi_awready;
    wire [DATA_W-1:0] m_axi_wdata;
    wire [(DATA_W/8)-1:0] m_axi_wstrb;
    wire              m_axi_wlast;
    wire              m_axi_wvalid;
    reg               m_axi_wready;
    reg  [1:0]        m_axi_bresp;
    reg               m_axi_bvalid;
    wire              m_axi_bready;

    // DUT
    bibieq_dma_banked_riscv_top #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .COUNT_W(COUNT_W),
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_PTR_W(FIFO_PTR_W),
        .FAST_MODE(FAST_MODE)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );

    // Memory model storage
    reg [DATA_W-1:0] desc_mem [0:MAX_DESC-1];
    reg [DATA_W-1:0] result_mem [0:MAX_DESC-1];

    // Scoreboard / coverage
    reg [255:0] expected_mask;
    reg [255:0] seen_mask;
    integer write_count;
    integer error_count;
    integer desc_count;
    integer rd_burst_len;
    integer seed;
    integer i;
    integer status;
    integer timeout;
    integer w_idx;
    string desc_file;
    bit use_desc_file;

    integer cov_even;
    integer cov_odd;
    integer cov_use4ec0;
    integer cov_use4ec1;
    integer cov_phase [0:7];
    integer cov_r [0:7];
    integer cov_ds0;
    integer cov_ds1;
    integer cov_rd_burst_1;
    integer cov_rd_burst_2;
    integer cov_rd_burst_4;
    integer cov_rd_burst_8;
    integer cov_rd_burst_other;
    integer cov_desc_small;
    integer cov_desc_mid;
    integer cov_desc_large;
    integer cov_desc_xl;
    integer cov_bp_r;
    integer cov_bp_w;
    integer cov_fifo_even_hi;
    integer cov_fifo_odd_hi;

    // Read channel internal state
    reg rd_active;
    reg [ADDR_W-1:0] rd_addr;
    reg [7:0] rd_beats_left;
    reg [3:0] rd_pause;

    // Write channel internal state
    reg aw_seen;
    reg [ADDR_W-1:0] aw_addr;
    reg w_seen;
    reg [DATA_W-1:0] w_data;
    reg w_last;

    integer cycle_ctr;
    integer result_base_addr;

    // Descriptor generation temporaries
    reg [7:0]  gen_seg_idx;
    reg        gen_use_4ec;
    reg [2:0]  gen_phase;
    reg [2:0]  gen_r;
    reg        gen_ds;
    reg [15:0] gen_e_q;
    reg [15:0] gen_q_q;
    reg [3:0]  gen_u;
    reg [3:0]  gen_v;

    // Result decode temporaries
    reg [7:0]  result_seg_idx;
    reg [4:0]  result_exact_mask;
    reg        result_exact_valid;

    // Clock
    always #5 aclk = ~aclk;

    // Simple AXI-Lite write task
    task axi_lite_write;
        input [ADDR_W-1:0] addr;
        input [31:0] data;
        integer wait_ctr;
        begin : axil_wr
            // Address phase
            @(negedge aclk);
            s_axi_awaddr  = addr;
            s_axi_awvalid = 1'b1;
            s_axi_wvalid  = 1'b0;

            wait_ctr = 0;
            while (1) begin
                @(posedge aclk);
                wait_ctr = wait_ctr + 1;
                if (s_axi_awready && s_axi_awvalid)
                    break;
                if (wait_ctr > 1000) begin
                    $display("ERROR: AXI-Lite AWREADY timeout (awready=%b bvalid=%b aw_hold=%b)",
                             s_axi_awready, s_axi_bvalid, dut.u_regs.aw_hold);
                    error_count = error_count + 1;
                    dump_dut_state();
                    disable axil_wr;
                end
            end
            @(negedge aclk);
            s_axi_awvalid = 1'b0;

            // Data phase
            @(negedge aclk);
            s_axi_wdata   = data;
            s_axi_wstrb   = 4'hF;
            s_axi_wvalid  = 1'b1;

            wait_ctr = 0;
            while (1) begin
                @(posedge aclk);
                wait_ctr = wait_ctr + 1;
                if (s_axi_wready && s_axi_wvalid)
                    break;
                if (wait_ctr > 1000) begin
                    $display("ERROR: AXI-Lite WREADY timeout (wready=%b bvalid=%b w_hold=%b)",
                             s_axi_wready, s_axi_bvalid, dut.u_regs.w_hold);
                    error_count = error_count + 1;
                    dump_dut_state();
                    disable axil_wr;
                end
            end
            @(negedge aclk);
            s_axi_wvalid = 1'b0;

            @(negedge aclk);
            s_axi_bready = 1'b1;
            wait_ctr = 0;
            while (1) begin
                @(posedge aclk);
                wait_ctr = wait_ctr + 1;
                if (s_axi_bvalid && s_axi_bready)
                    break;
                if (wait_ctr > 1000) begin
                    $display("ERROR: AXI-Lite BVALID timeout (awready=%b wready=%b bvalid=%b aw_hold=%b w_hold=%b)",
                             s_axi_awready, s_axi_wready, s_axi_bvalid,
                             dut.u_regs.aw_hold, dut.u_regs.w_hold);
                    error_count = error_count + 1;
                    dump_dut_state();
                    disable axil_wr;
                end
            end
            @(negedge aclk);
            s_axi_bready = 1'b0;
        end
    endtask

    // Simple AXI-Lite read task
    task axi_lite_read;
        input  [ADDR_W-1:0] addr;
        output [31:0] data;
        integer wait_ctr;
        begin : axil_rd
            @(negedge aclk);
            s_axi_araddr  = addr;
            s_axi_arvalid = 1'b1;
            wait_ctr = 0;
            while (1) begin
                @(posedge aclk);
                wait_ctr = wait_ctr + 1;
                if (s_axi_arready && s_axi_arvalid)
                    break;
                if (wait_ctr > 1000) begin
                    $display("ERROR: AXI-Lite ARREADY timeout");
                    error_count = error_count + 1;
                    dump_dut_state();
                    disable axil_rd;
                end
            end
            @(negedge aclk);
            s_axi_arvalid = 1'b0;

            @(negedge aclk);
            s_axi_rready = 1'b1;
            wait_ctr = 0;
            while (1) begin
                @(posedge aclk);
                wait_ctr = wait_ctr + 1;
                if (s_axi_rvalid && s_axi_rready)
                    break;
                if (wait_ctr > 1000) begin
                    $display("ERROR: AXI-Lite RVALID timeout (arready=%b rvalid=%b)",
                             s_axi_arready, s_axi_rvalid);
                    error_count = error_count + 1;
                    dump_dut_state();
                    disable axil_rd;
                end
            end
            data = s_axi_rdata;
            @(negedge aclk);
            s_axi_rready = 1'b0;
        end
    endtask

    // Coverage helpers
    task init_coverage;
        begin
            cov_even = 0; cov_odd = 0;
            cov_use4ec0 = 0; cov_use4ec1 = 0;
            cov_ds0 = 0; cov_ds1 = 0;
            cov_rd_burst_1 = 0; cov_rd_burst_2 = 0; cov_rd_burst_4 = 0; cov_rd_burst_8 = 0; cov_rd_burst_other = 0;
            cov_desc_small = 0; cov_desc_mid = 0; cov_desc_large = 0; cov_desc_xl = 0;
            cov_bp_r = 0; cov_bp_w = 0;
            cov_fifo_even_hi = 0; cov_fifo_odd_hi = 0;
            for (i = 0; i < 8; i = i + 1) begin
                cov_phase[i] = 0;
                cov_r[i] = 0;
            end
        end
    endtask

    task report_coverage;
        integer j;
        begin
            $display("\n=== Coverage Summary ===");
            $display("seg_idx parity: even=%0d odd=%0d", cov_even, cov_odd);
            $display("use_4ec: 0=%0d 1=%0d", cov_use4ec0, cov_use4ec1);
            $display("ds: 0=%0d 1=%0d", cov_ds0, cov_ds1);
            for (j = 0; j < 8; j = j + 1)
                $display("phase[%0d]=%0d r[%0d]=%0d", j, cov_phase[j], j, cov_r[j]);
            $display("burst bins: 1=%0d 2=%0d 4=%0d 8=%0d other=%0d", cov_rd_burst_1, cov_rd_burst_2, cov_rd_burst_4, cov_rd_burst_8, cov_rd_burst_other);
            $display("desc_count bins: small=%0d mid=%0d large=%0d xl=%0d", cov_desc_small, cov_desc_mid, cov_desc_large, cov_desc_xl);
            $display("backpressure cycles: rd=%0d wr=%0d", cov_bp_r, cov_bp_w);
            $display("fifo high watermark hits: even=%0d odd=%0d", cov_fifo_even_hi, cov_fifo_odd_hi);
            $display("========================\n");
        end
    endtask

    task dump_dut_state;
        begin
            $display("---- DUT STATE @ cycle %0d ----", cycle_ctr);
            $display("AXI-Lite: awv=%b awr=%b wv=%b wr=%b bv=%b br=%b arv=%b arr=%b rv=%b rr=%b",
                     s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready,
                     s_axi_bvalid, s_axi_bready, s_axi_arvalid, s_axi_arready,
                     s_axi_rvalid, s_axi_rready);
            $display("AXI-Lite holds: aw_hold=%b w_hold=%b",
                     dut.u_regs.aw_hold, dut.u_regs.w_hold);
            $display("REGS: desc_base=0x%08x desc_count=%0d rd_burst=%0d result_base=0x%08x",
                     dut.desc_base, dut.desc_count, dut.rd_burst_len, dut.result_base);
            $display("STATUS: busy=%b done=%b fetch_done=%b store_done=%b fifo_even=%0d fifo_odd=%0d",
                     dut.busy, dut.done, dut.fetch_done, dut.store_done, dut.fifo_even_level, dut.fifo_odd_level);
            $display("FETCH: busy=%b done=%b remaining=%0d inflight=%0d rd_cmd_v=%b rd_cmd_r=%b",
                     dut.u_core.fetch_busy, dut.u_core.fetch_done,
                     dut.u_core.u_fetch.remaining_r, dut.u_core.u_fetch.inflight_beats_r,
                     dut.u_core.rd_cmd_valid, dut.u_core.rd_cmd_ready);
            $display("READ AXI: arvalid=%b arready=%b rvalid=%b rready=%b rlast=%b",
                     dut.u_axi_read.m_axi_arvalid, m_axi_arready, m_axi_rvalid, m_axi_rready, m_axi_rlast);
            $display("STORE: busy=%b done=%b remaining=%0d wvalid=%b wready=%b",
                     dut.u_core.store_busy, dut.u_core.store_done,
                     dut.u_core.u_store.remaining_r, dut.u_core.mem_wvalid, dut.u_core.mem_wready);
            $display("--------------------------------");
        end
    endtask

    // Reset and stimulus
    initial begin
        aclk = 1'b0;
        aresetn = 1'b0;

        s_axi_awaddr = {ADDR_W{1'b0}};
        s_axi_awprot = 3'd0;
        s_axi_awvalid = 1'b0;
        s_axi_wdata = 32'd0;
        s_axi_wstrb = 4'h0;
        s_axi_wvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_araddr = {ADDR_W{1'b0}};
        s_axi_arprot = 3'd0;
        s_axi_arvalid = 1'b0;
        s_axi_rready = 1'b0;

        m_axi_arready = 1'b0;
        m_axi_rdata = {DATA_W{1'b0}};
        m_axi_rresp = 2'b00;
        m_axi_rlast = 1'b0;
        m_axi_rvalid = 1'b0;

        m_axi_awready = 1'b0;
        m_axi_wready = 1'b0;
        m_axi_bresp = 2'b00;
        m_axi_bvalid = 1'b0;

        rd_active = 1'b0;
        rd_addr = {ADDR_W{1'b0}};
        rd_beats_left = 8'd0;
        rd_pause = 4'd0;

        aw_seen = 1'b0;
        aw_addr = {ADDR_W{1'b0}};
        w_seen = 1'b0;
        w_data = {DATA_W{1'b0}};
        w_last = 1'b0;

        expected_mask = 256'd0;
        seen_mask = 256'd0;
        write_count = 0;
        error_count = 0;
        cycle_ctr = 0;
        result_base_addr = 32'h1000;

        seed = 32'h13579BDF;
        init_coverage();

        // randomizable parameters
        if (!$value$plusargs("SEED=%d", seed))
            seed = 32'h13579BDF;

        use_desc_file = 1'b0;
        if ($value$plusargs("DESC_FILE=%s", desc_file)) begin
            use_desc_file = 1'b1;
            if (!$value$plusargs("DESC_COUNT=%d", desc_count)) begin
                desc_count = MAX_DESC;
                $display("WARN: DESC_FILE set but DESC_COUNT missing, defaulting to %0d", MAX_DESC);
            end
        end else if (!$value$plusargs("DESC_COUNT=%d", desc_count)) begin
            seed = $random(seed);
            desc_count = (seed % 24) + 8; // 8..31
        end
        if (desc_count > MAX_DESC)
            desc_count = MAX_DESC;

        if (!$value$plusargs("BURST_LEN=%d", rd_burst_len)) begin
            if (use_desc_file) begin
                rd_burst_len = (desc_count < 8) ? desc_count : 8;
            end else begin
                seed = $random(seed);
                rd_burst_len = (seed % 8) + 1; // 1..8
            end
        end
        if (rd_burst_len > desc_count)
            rd_burst_len = desc_count;

        // coverage bins for desc_count and burst
        if (desc_count <= 3) cov_desc_small = cov_desc_small + 1;
        else if (desc_count <= 7) cov_desc_mid = cov_desc_mid + 1;
        else if (desc_count <= 15) cov_desc_large = cov_desc_large + 1;
        else cov_desc_xl = cov_desc_xl + 1;

        if (rd_burst_len == 1) cov_rd_burst_1 = cov_rd_burst_1 + 1;
        else if (rd_burst_len == 2) cov_rd_burst_2 = cov_rd_burst_2 + 1;
        else if (rd_burst_len == 4) cov_rd_burst_4 = cov_rd_burst_4 + 1;
        else if (rd_burst_len == 8) cov_rd_burst_8 = cov_rd_burst_8 + 1;
        else cov_rd_burst_other = cov_rd_burst_other + 1;

        // initialize memories
        for (i = 0; i < MAX_DESC; i = i + 1) begin
            desc_mem[i] = 64'd0;
            result_mem[i] = 64'd0;
        end

        if (use_desc_file) begin
            $readmemh(desc_file, desc_mem);
            for (i = 0; i < desc_count; i = i + 1) begin
                gen_seg_idx = desc_mem[i][63:56];
                gen_use_4ec = desc_mem[i][55];
                gen_phase = desc_mem[i][54:52];
                gen_r = desc_mem[i][51:49];
                gen_ds = desc_mem[i][48];

                expected_mask[gen_seg_idx] = 1'b1;

                // coverage updates
                if (gen_seg_idx[0]) cov_odd = cov_odd + 1; else cov_even = cov_even + 1;
                if (gen_use_4ec) cov_use4ec1 = cov_use4ec1 + 1; else cov_use4ec0 = cov_use4ec0 + 1;
                cov_phase[gen_phase] = cov_phase[gen_phase] + 1;
                cov_r[gen_r] = cov_r[gen_r] + 1;
                if (gen_ds) cov_ds1 = cov_ds1 + 1; else cov_ds0 = cov_ds0 + 1;
            end
        end else begin
            // create randomized descriptors
            for (i = 0; i < desc_count; i = i + 1) begin
                gen_seg_idx = i[7:0];
                seed = $random(seed);
                gen_use_4ec = seed[0];
                seed = $random(seed);
                gen_phase = seed[2:0];
                seed = $random(seed);
                gen_r = seed[2:0] % 5;
                seed = $random(seed);
                gen_ds = seed[0];
                seed = $random(seed);
                gen_e_q = seed[15:0];
                seed = $random(seed);
                gen_q_q = seed[15:0];
                seed = $random(seed);
                gen_u = seed[3:0];
                gen_v = seed[7:4];

                desc_mem[i] = {gen_seg_idx, gen_use_4ec, gen_phase, gen_r, gen_ds, gen_e_q, gen_q_q, gen_u, gen_v, 8'd0};
                expected_mask[gen_seg_idx] = 1'b1;

                // coverage updates
                if (gen_seg_idx[0]) cov_odd = cov_odd + 1; else cov_even = cov_even + 1;
                if (gen_use_4ec) cov_use4ec1 = cov_use4ec1 + 1; else cov_use4ec0 = cov_use4ec0 + 1;
                cov_phase[gen_phase] = cov_phase[gen_phase] + 1;
                cov_r[gen_r] = cov_r[gen_r] + 1;
                if (gen_ds) cov_ds1 = cov_ds1 + 1; else cov_ds0 = cov_ds0 + 1;
            end
        end

        // release reset
        repeat (5) @(posedge aclk);
        aresetn <= 1'b1;
        // wait a few cycles for sync reset deassert inside DUT
        repeat (3) @(posedge aclk);

        // program registers
        axi_lite_write(32'h08, 32'd0);                 // DESC_BASE
        axi_lite_write(32'h0C, desc_count);           // DESC_COUNT
        axi_lite_write(32'h10, rd_burst_len);         // RD_BURST_LEN
        axi_lite_write(32'h14, result_base_addr);     // RESULT_BASE

        // start
        axi_lite_write(32'h00, 32'h1);

        // wait for done
        status = 0;
        timeout = 0;
        while ((timeout < 20000) && (status[1] == 1'b0)) begin
            if ((timeout % 50) == 0)
                axi_lite_read(32'h04, status);
            timeout = timeout + 1;
            @(posedge aclk);
        end
        if (status[1] == 1'b0) begin
            $display("ERROR: timeout waiting for DONE");
            error_count = error_count + 1;
            dump_dut_state();
        end

        // final checks
        if (write_count != desc_count) begin
            $display("ERROR: write_count %0d != desc_count %0d", write_count, desc_count);
            error_count = error_count + 1;
        end
        if (seen_mask != expected_mask) begin
            $display("ERROR: result seg_idx set mismatch");
            error_count = error_count + 1;
        end

        report_coverage();

        // Coverage gating: minimum functional bins must be hit
        begin
            integer cov_fail;
            integer j;
            cov_fail = 0;

            if (cov_even == 0 || cov_odd == 0) cov_fail = cov_fail + 1;
            if (cov_use4ec0 == 0 || cov_use4ec1 == 0) cov_fail = cov_fail + 1;
            if (cov_ds0 == 0 || cov_ds1 == 0) cov_fail = cov_fail + 1;

            for (j = 0; j < 8; j = j + 1) begin
                if (cov_phase[j] == 0) cov_fail = cov_fail + 1;
            end
            for (j = 0; j < 5; j = j + 1) begin
                if (cov_r[j] == 0) cov_fail = cov_fail + 1;
            end

            if (cov_fail != 0) begin
                $display("ERROR: coverage goals not met (%0d bins missing)", cov_fail);
                error_count = error_count + 1;
            end
        end

        if (error_count == 0)
            $display("TEST PASSED (FAST_MODE=%0d)", FAST_MODE);
        else
            $display("TEST FAILED with %0d error(s)", error_count);

        #50 $finish;
    end

    // Simulation watchdog
    initial begin
        #2000000;
        $display("ERROR: SIM TIMEOUT");
        dump_dut_state();
        $finish;
    end

    // Ready/valid backpressure generation and coverage sampling
    always @(posedge aclk) begin
        if (!aresetn) begin
            cycle_ctr <= 0;
            m_axi_arready <= 1'b0;
            m_axi_awready <= 1'b0;
            m_axi_wready  <= 1'b0;
        end else begin
            cycle_ctr <= cycle_ctr + 1;
            // deterministic backpressure patterns
            m_axi_arready <= (cycle_ctr[1:0] != 2'b00); // 75% ready
            m_axi_awready <= (cycle_ctr[2:0] != 3'b000); // 87.5% ready
            m_axi_wready  <= (cycle_ctr[2:0] != 3'b001); // 87.5% ready

            if (m_axi_rvalid && !m_axi_rready)
                cov_bp_r <= cov_bp_r + 1;
            if (m_axi_awvalid && !m_axi_awready)
                cov_bp_w <= cov_bp_w + 1;
            if (m_axi_wvalid && !m_axi_wready)
                cov_bp_w <= cov_bp_w + 1;

            if (dut.fifo_even_level >= (FIFO_DEPTH - 2))
                cov_fifo_even_hi <= cov_fifo_even_hi + 1;
            if (dut.fifo_odd_level >= (FIFO_DEPTH - 2))
                cov_fifo_odd_hi <= cov_fifo_odd_hi + 1;
        end
    end

    // AXI read memory model
    always @(posedge aclk) begin
        if (!aresetn) begin
            rd_active <= 1'b0;
            rd_addr <= {ADDR_W{1'b0}};
            rd_beats_left <= 8'd0;
            rd_pause <= 4'd0;
            m_axi_rvalid <= 1'b0;
            m_axi_rdata <= {DATA_W{1'b0}};
            m_axi_rlast <= 1'b0;
            m_axi_rresp <= 2'b00;
        end else begin
            if (m_axi_arvalid && m_axi_arready) begin
                rd_active <= 1'b1;
                rd_addr <= m_axi_araddr;
                rd_beats_left <= m_axi_arlen + 1'b1;
                rd_pause <= 2;
            end

            if (m_axi_rvalid) begin
                if (m_axi_rready) begin
                    m_axi_rvalid <= 1'b0;
                    if (rd_beats_left != 0) begin
                        rd_beats_left <= rd_beats_left - 1'b1;
                        rd_addr <= rd_addr + (DATA_W/8);
                        if (rd_beats_left == 1)
                            rd_active <= 1'b0;
                    end
                    rd_pause <= 2;
                end
            end else if (rd_active && (rd_beats_left != 0)) begin
                if (rd_pause == 0) begin
                    m_axi_rvalid <= 1'b1;
                    m_axi_rdata  <= desc_mem[rd_addr[ADDR_W-1:3]];
                    m_axi_rlast  <= (rd_beats_left == 1);
                    m_axi_rresp  <= 2'b00;
                end else begin
                    rd_pause <= rd_pause - 1'b1;
                end
            end
        end
    end

    // AXI write memory model + scoreboard
    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_seen <= 1'b0;
            w_seen  <= 1'b0;
            m_axi_bvalid <= 1'b0;
            m_axi_bresp  <= 2'b00;
        end else begin
            if (m_axi_awvalid && m_axi_awready) begin
                aw_seen <= 1'b1;
                aw_addr <= m_axi_awaddr;
                if (m_axi_awlen != 8'd0) begin
                    $display("ERROR: AWLEN expected 0, got %0d", m_axi_awlen);
                    error_count = error_count + 1;
                end
            end

            if (m_axi_wvalid && m_axi_wready) begin
                w_seen <= 1'b1;
                w_data <= m_axi_wdata;
                w_last <= m_axi_wlast;
                if (!m_axi_wlast) begin
                    $display("ERROR: WLAST expected 1 for single-beat write");
                    error_count = error_count + 1;
                end
            end

            if (aw_seen && w_seen && !m_axi_bvalid) begin
                // commit write
                if (aw_addr != (result_base_addr + (write_count * (DATA_W/8)))) begin
                    $display("ERROR: write addr mismatch: got 0x%08x exp 0x%08x", aw_addr, (result_base_addr + (write_count * (DATA_W/8))));
                    error_count = error_count + 1;
                end

                // scoreboard on result data
                result_seg_idx = w_data[63:56];
                result_exact_mask = w_data[52:48];
                result_exact_valid = w_data[42];

                if (!expected_mask[result_seg_idx]) begin
                    $display("ERROR: unexpected seg_idx in result: %0d", result_seg_idx);
                    error_count = error_count + 1;
                end else if (seen_mask[result_seg_idx]) begin
                    $display("ERROR: duplicate seg_idx in result: %0d", result_seg_idx);
                    error_count = error_count + 1;
                end else begin
                    seen_mask[result_seg_idx] = 1'b1;
                end

                if (FAST_MODE) begin
                    if (result_exact_mask != 5'd0 || result_exact_valid != 1'b0) begin
                        $display("ERROR: FAST_MODE expects exact fields zero");
                        error_count = error_count + 1;
                    end
                end

                // store result
                w_idx = (aw_addr - result_base_addr) >> 3;
                result_mem[w_idx] <= w_data;
                write_count <= write_count + 1;

                aw_seen <= 1'b0;
                w_seen  <= 1'b0;
                m_axi_bvalid <= 1'b1;
                m_axi_bresp  <= 2'b00;
            end else if (m_axi_bvalid && m_axi_bready) begin
                m_axi_bvalid <= 1'b0;
            end
        end
    end
endmodule
