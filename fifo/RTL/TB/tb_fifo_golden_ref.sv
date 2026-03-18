`timescale 1ns / 1ps

module tb_fifo;

    //--------------------------------------------------------------------------
    // Parameters / Types
    //--------------------------------------------------------------------------
    localparam int DATA_WIDTH       = 32;
    localparam int FIFO_WIDTH       = 16;
    localparam int AFULL_THRESHOLD  = 13;
    localparam int AEMPTY_THRESHOLD = 3;

    typedef logic [DATA_WIDTH-1:0] data_t;

    //--------------------------------------------------------------------------
    // DUT signals
    //--------------------------------------------------------------------------
    logic                  clk;
    logic                  rst_n;
    logic                  wr;
    logic                  rd;
    logic [DATA_WIDTH-1:0] data_i;
    logic                  full_o;
    logic                  empty_o;
    logic                  afull_o;
    logic                  aempty_o;
    logic [DATA_WIDTH-1:0] data_o;

    // Scoreboard queue
    data_t exp_q[$];

    //--------------------------------------------------------------------------
    // DUT instance
    //--------------------------------------------------------------------------
    my_fifo #(
        .DATA_WIDTH       (DATA_WIDTH),
        .FIFO_WIDTH       (FIFO_WIDTH),
        .AFULL_THRESHOLD  (AFULL_THRESHOLD),
        .AEMPTY_THRESHOLD (AEMPTY_THRESHOLD)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr       (wr),
        .rd       (rd),
        .data_i   (data_i),
        .full_o   (full_o),
        .empty_o  (empty_o),
        .afull_o  (afull_o),
        .aempty_o (aempty_o),
        .data_o   (data_o)
    );

    //--------------------------------------------------------------------------
    // Dump
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fifo);
    end

    //--------------------------------------------------------------------------
    // Clock
    //--------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //--------------------------------------------------------------------------
    // Utility tasks
    //--------------------------------------------------------------------------
    task automatic init_signals;
    begin
        rst_n  = 1'b1;
        wr     = 1'b0;
        rd     = 1'b0;
        data_i = '0;
    end
    endtask

    task automatic apply_reset;
    begin
        wr     = 1'b0;
        rd     = 1'b0;
        data_i = '0;
        rst_n  = 1'b0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
    end
    endtask

    task automatic check_reset_flags;
    begin
        if (empty_o !== 1'b1 || full_o !== 1'b0) begin
            $display("[%0t] ERROR: Reset flags wrong. empty=%b full=%b",
                     $time, empty_o, full_o);
            $finish;
        end

        if (aempty_o !== 1'b1 || afull_o !== 1'b0) begin
            $display("[%0t] ERROR: Reset almost flags wrong. aempty=%b afull=%b",
                     $time, aempty_o, afull_o);
            $finish;
        end
    end
    endtask

    task automatic check_fifo_empty;
    begin
        if (empty_o !== 1'b1 || full_o !== 1'b0) begin
            $display("[%0t] ERROR: FIFO should be empty. empty=%b full=%b",
                     $time, empty_o, full_o);
            $finish;
        end
    end
    endtask

    task automatic check_fifo_full;
    begin
        if (full_o !== 1'b1 || empty_o !== 1'b0) begin
            $display("[%0t] ERROR: FIFO should be full. full=%b empty=%b",
                     $time, full_o, empty_o);
            $finish;
        end
    end
    endtask

    task automatic dump_mem;
        integer idx;
    begin
        for (idx = 0; idx < FIFO_WIDTH; idx = idx + 1) begin
            $display("[%0t] FIFO mem[%0d] = 0x%08h", $time, idx, dut.mem[idx]);
        end
    end
    endtask

    //--------------------------------------------------------------------------
    // Write / Read tasks
    //--------------------------------------------------------------------------
    task automatic fifo_write(input data_t din);
        bit was_full;
    begin
        @(negedge clk);
        was_full = full_o;

        if (was_full) begin
            $display("[%0t] WARNING: write requested while FULL (ignored by DUT)", $time);
        end

        data_i = din;
        wr     = 1'b1;

        @(posedge clk);
        #1;

        if (!was_full) begin
            exp_q.push_back(din);
            $display("[%0t] WRITE OK: data=0x%08h, exp_q.size=%0d",
                     $time, din, exp_q.size());
        end

        @(negedge clk);
        wr     = 1'b0;
        data_i = '0;
    end
    endtask

    task automatic fifo_read_scoreboard;
        bit    was_empty;
        data_t expected;
        data_t actual;
    begin
        @(negedge clk);
        was_empty = empty_o;

        if (was_empty) begin
            $display("[%0t] WARNING: read requested while EMPTY (ignored by DUT)", $time);
        end

        rd = 1'b1;

        @(posedge clk);
        #1;
        actual = data_o;

        if (!was_empty) begin
            if (exp_q.size() == 0) begin
                $display("[%0t] ERROR: scoreboard underflow. got=0x%08h", $time, actual);
                $finish;
            end

            expected = exp_q.pop_front();

            if (actual !== expected) begin
                $display("[%0t] ERROR: read mismatch. expected=0x%08h got=0x%08h",
                         $time, expected, actual);
                $finish;
            end
            else begin
                $display("[%0t] READ OK: data=0x%08h, exp_q.size=%0d",
                         $time, actual, exp_q.size());
            end
        end

        @(negedge clk);
        rd = 1'b0;
    end
    endtask

    task automatic fifo_read_no_check;
        bit    was_empty;
        data_t actual;
    begin
        @(negedge clk);
        was_empty = empty_o;

        if (was_empty) begin
            $display("[%0t] WARNING: read requested while EMPTY (ignored by DUT)", $time);
        end

        rd = 1'b1;

        @(posedge clk);
        #1;
        actual = data_o;

        if (!was_empty) begin
            $display("[%0t] INFO: read data = 0x%08h", $time, actual);
        end

        @(negedge clk);
        rd = 1'b0;
    end
    endtask

    task automatic fifo_simul_rw(input data_t din, input data_t expected);
        bit was_empty;
        bit was_full;
	data_t dummy;
    begin
        @(negedge clk);
        was_empty = empty_o;
        was_full  = full_o;

        $display("[%0t] INFO: before simul R/W : r_ptr=%b, w_ptr=%b",
                 $time, dut.r_ptr, dut.w_ptr);

        data_i = din;
        wr     = 1'b1;
        rd     = 1'b1;

        @(posedge clk);
        #1;

        if (!was_empty) begin
            if (data_o !== expected) begin
                $display("[%0t] ERROR: Simul R/W mismatch. expected=0x%08h got=0x%08h",
                         $time, expected, data_o);
                $finish;
            end
            else begin
                $display("[%0t] INFO: Simul R/W OK. read=0x%08h write=0x%08h",
                         $time, data_o, din);
            end
        end
	
        // scoreboard update
        if (!was_empty && exp_q.size() != 0) begin
            dummy = exp_q.pop_front();
        end
        if (!was_full) begin
            exp_q.push_back(din);
        end

        @(negedge clk);
        wr     = 1'b0;
        rd     = 1'b0;
        data_i = '0;
    end
    endtask

    //--------------------------------------------------------------------------
    // Main stimulus
    //--------------------------------------------------------------------------
    integer i;

    initial begin
        init_signals();
        apply_reset();

        // ------------------------------------------------
        // 1) Reset state check
        // ------------------------------------------------
        $display("\n=== TEST 1: Reset state check ===");
        check_reset_flags();

        // ------------------------------------------------
        // 2) Single write/read
        // ------------------------------------------------
        $display("\n=== TEST 2: Single write/read ===");
        fifo_write(32'hA5A5_0001);

        if (empty_o !== 1'b0) begin
            $display("[%0t] ERROR: After one write, empty should be 0", $time);
            $finish;
        end

        fifo_read_scoreboard();

        if (empty_o !== 1'b1) begin
            $display("[%0t] ERROR: After read back, empty should be 1", $time);
            $finish;
        end

        // ------------------------------------------------
        // 3) Fill FIFO
        // ------------------------------------------------
        $display("\n=== TEST 3: Fill FIFO ===");
        for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
            fifo_write(data_t'(i));

            if ((i + 1) >= AFULL_THRESHOLD && afull_o !== 1'b1) begin
                $display("[%0t] ERROR: afull_o should be 1 when count >= %0d (i=%0d)",
                         $time, AFULL_THRESHOLD, i);
                $finish;
            end
        end

        check_fifo_full();

        // FULL 상태 write
        $display("\n=== TEST 3-1: Write while FULL (should be ignored) ===");
        fifo_write(32'hDEAD_BEEF);

        // ------------------------------------------------
        // 4) Drain FIFO
        // ------------------------------------------------
        $display("\n=== TEST 4: Drain FIFO ===");
        for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
            fifo_read_scoreboard();

            if (((FIFO_WIDTH - 1 - i) <= AEMPTY_THRESHOLD) && aempty_o !== 1'b1) begin
                $display("[%0t] ERROR: aempty_o should be 1 when remaining <= %0d (after i=%0d)",
                         $time, AEMPTY_THRESHOLD, i);
                $finish;
            end
        end

        check_fifo_empty();

        if (exp_q.size() != 0) begin
            $display("[%0t] ERROR: scoreboard queue should be empty, size=%0d",
                     $time, exp_q.size());
            $finish;
        end

        // ------------------------------------------------
        // 5) Simultaneous read/write
        // ------------------------------------------------
        $display("\n=== TEST 5: Simultaneous read/write ===");

        for (i = 0; i < 8; i = i + 1) begin
            fifo_write(32'h1000_0000 + i);
        end

        for (i = 0; i < 4; i = i + 1) begin
            fifo_simul_rw(32'h2000_0000 + i, 32'h1000_0000 + i);
        end

        // 남아 있는 데이터들 확인해보고 싶으면 계속 read
        $display("\n=== TEST 5-1: Drain remaining data after simul R/W ===");
        while (!empty_o) begin
            fifo_read_scoreboard();
        end

        if (exp_q.size() != 0) begin
            $display("[%0t] ERROR: scoreboard queue should be empty after final drain, size=%0d",
                     $time, exp_q.size());
            $finish;
        end

        $display("\n=== DEBUG: DUT memory dump ===");
        dump_mem();

        $display("\n*** ALL TESTS PASSED ***");
        $finish;
    end

endmodule
