`timescale 1ns / 1ps

module tb_fifo();
    // parameters
    localparam DATA_WIDTH      = 32;
    localparam FIFO_WIDTH      = 16;
    localparam AFULL_THRESHOLD = 13;
    localparam AEMPTY_THRESHOLD= 3;

    // DUT signals
    reg                     clk;
    reg                     rst_n;
    reg                     wr;
    reg                     rd;
    reg  [DATA_WIDTH-1:0]   data_i;
    wire                    full_o;
    wire                    empty_o;
    wire                    afull_o;
    wire                    aempty_o;
    wire [DATA_WIDTH-1:0]   data_o;

    // DUT instance
    my_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_WIDTH(FIFO_WIDTH),
        .AFULL_THRESHOLD(AFULL_THRESHOLD),
        .AEMPTY_THRESHOLD(AEMPTY_THRESHOLD)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr        (wr),
        .rd        (rd),
        .data_i    (data_i),
        .full_o    (full_o),
        .empty_o   (empty_o),
        .afull_o   (afull_o),
        .aempty_o  (aempty_o),
        .data_o    (data_o)
    );

    initial begin
	    $dumpfile("wave.vcd");
	    $dumpvars(0, tb_fifo);
	end

    // clock gen
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns period

    // tasks
    task automatic fifo_write(input [DATA_WIDTH-1:0] din);
    begin
        // wr를 한 클럭 동안 1로
        @(negedge clk);
        if (full_o) begin
            $display("[%0t] WARNING: write requested while FULL (ignored by DUT)", $time);
        end
        data_i = din;
        wr     = 1'b1;
        @(negedge clk);
        wr     = 1'b0;
    end
    endtask

    task automatic fifo_read(input [DATA_WIDTH-1:0] expected);
    begin
        @(negedge clk);
        if (empty_o) begin
            $display("[%0t] WARNING: read requested while EMPTY (ignored by DUT)", $time);
        end
        rd = 1'b1;
        @(posedge clk);  // 이 포지엣지에서 data_o가 업데이트됨
        #1; // 작은 delay 후 비교
        if (!empty_o) begin
            if (data_o !== expected) begin
                $display("[%0t] ERROR: read data mismatch. expected=0x%08h, got=0x%08h",
                         $time, expected, data_o);
                $stop;
            end else begin
                $display("[%0t] INFO: read OK. data=0x%08h", $time, data_o);
            end
        end
        @(negedge clk);
        rd = 1'b0;
    end
    endtask

    task automatic fifo_read_all;
    begin
        @(negedge clk);
        if (empty_o) begin
            $display("[%0t] WARNING: read requested while EMPTY (ignored by DUT)", $time);
        end
        rd = 1'b1;
        @(posedge clk);  // 이 포지엣지에서 data_o가 업데이트됨
        #1; // 작은 delay 후 비교
        if (!empty_o) begin
            $display("[%0t] INFO: read OK. data=0x%08h", $time, data_o);
        end
        @(negedge clk);
        rd = 1'b0;
    end
    endtask
    // main stimulus
    integer i;

    initial begin
        // init
        wr     = 0;
        rd     = 0;
        data_i = 0;

        // reset
        rst_n = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // -------------------------------
        // 1) Reset 상태 체크
        // -------------------------------
        $display("=== TEST 1: Reset state check ===");
        if (empty_o !== 1'b1 || full_o !== 1'b0) begin
            $display("[%0t] ERROR: Reset flags wrong. empty=%b full=%b", $time, empty_o, full_o);
            $stop;
        end
        if (aempty_o !== 1'b1 || afull_o !== 1'b0) begin
            $display("[%0t] ERROR: Reset almost flags wrong. aempty=%b afull=%b",
                     $time, aempty_o, afull_o);
            $stop;
        end

        // -------------------------------
        // 2) 단일 write/read
        // -------------------------------
        $display("=== TEST 2: Single write/read ===");
        fifo_write(32'hA5A5_0001);
        if (empty_o !== 1'b0) begin
            $display("[%0t] ERROR: After one write, empty should be 0", $time);
            $stop;
        end
        fifo_read(32'hA5A5_0001);
        if (empty_o !== 1'b1) begin
            $display("[%0t] ERROR: After read back, empty should be 1", $time);
            $stop;
        end

        // -------------------------------
        // 3) 가득 채워보기 (0~15)
        // -------------------------------
        $display("=== TEST 3: Fill FIFO ===");
        for (i = 0; i < FIFO_WIDTH; i = i+1) begin
            fifo_write(i);
            // afull_o 체크 (i+1이 AFULL_THRESHOLD 이상이면 HIGH 기대)
            if (i+1 >= AFULL_THRESHOLD && afull_o !== 1'b1) begin
                $display("[%0t] ERROR: afull_o should be 1 when count >= %0d (i=%0d)",
                         $time, AFULL_THRESHOLD, i);
                $stop;
            end
        end
        if (full_o !== 1'b1) begin
            $display("[%0t] ERROR: FIFO should be FULL after %0d writes", $time, FIFO_WIDTH);
            $stop;
        end
        if (empty_o !== 1'b0) begin
            $display("[%0t] ERROR: FIFO should not be EMPTY when full", $time);
            $stop;
        end

        // FULL 상태에서 write 시도
        $display("=== TEST 3-1: Write while FULL (should be ignored) ===");
        fifo_write(32'hDEAD_BEEF);  // w_en=0이라 무시되어야 함

        // -------------------------------
        // 4) 가득 찬 상태에서 모두 read
        // -------------------------------
        $display("=== TEST 4: Drain FIFO ===");
        for (i = 0; i < FIFO_WIDTH; i = i+1) begin
            fifo_read(i);  // 0~15 순서대로 나와야 함
            // aempty_o 체크: 남은 개수 <= threshold면 1
            if ((FIFO_WIDTH-1 - i) <= AEMPTY_THRESHOLD && aempty_o !== 1'b1) begin
                $display("[%0t] ERROR: aempty_o should be 1 when remaining <= %0d (after i=%0d)",
                         $time, AEMPTY_THRESHOLD, i);
                $stop;
            end
        end
        if (empty_o !== 1'b1 || full_o !== 1'b0) begin
            $display("[%0t] ERROR: After draining, empty should=1, full=0 (empty=%b full=%b)",
                     $time, empty_o, full_o);
            $stop;
        end

        // -------------------------------
        // 5) 중간 깊이에서 동시 read/write
        // -------------------------------
        $display("=== TEST 5: Simultaneous read/write (pipeline behavior) ===");
        // 8개 채우기 (100~107)
        for (i = 0; i < 8; i = i+1) begin
            fifo_write(32'h1000_0000 + i);
        end

        // 몇 사이클 동안 wr, rd 동시에 (200~203 쓰면서 100~103 읽힘 기대)
        for (i = 0; i < 4; i = i+1) begin
            @(negedge clk);
            // 동시 read/write
	    //display for each read, write pointer
	    $display("[%0t] INFO: read&write pointer : r_ptr=5'b%5b, w_ptr=5'b%5b", $time, dut.r_ptr, dut.w_ptr);
            wr     = 1'b1;
            rd     = 1'b1;
            data_i = 32'h2000_0000 + i;

            @(posedge clk);
            #1;
            // 이 시점의 data_o는 100~103 순서
            if (data_o !== (32'h1000_0000 + i)) begin
                $display("[%0t] ERROR: Simul R/W mismatch. expected=0x%08h, got=0x%08h",
                         $time, (32'h1000_0000 + i), data_o);
                $stop;
            end
            end
	for (i = 0; i < FIFO_WIDTH; i = i + 1) begin
		$display("[%0t] FIfo mem data (idx:%0d): 0x%08h",
                         $time, i, dut.mem[i]);
	end
	$finish;
            end
endmodule
