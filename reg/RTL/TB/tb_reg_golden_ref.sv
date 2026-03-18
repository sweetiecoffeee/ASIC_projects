`timescale 1ns/1ps

module tb_my_reg;

    parameter int N = 8;

    logic clk;
    logic rst_n;
    logic en;
    logic [N-1:0] data_i;
    logic [N-1:0] data_o;

    // DUT
    my_reg #(
        .N(N)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .d(data_i),
        .q(data_o)
    );
    
    initial begin
	   $dumpfile("wave.vcd");
	   $dumpvars(0, tb_my_reg);  
    end

    //------------------------------------------------------------
    // clock generation
    //------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //------------------------------------------------------------
    // golden reference model
    //------------------------------------------------------------
    logic [N-1:0] golden;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            golden <= '0;
        else if (en)
            golden <= data_i;
    end

    //------------------------------------------------------------
    // checker
    //------------------------------------------------------------
    always @(posedge clk) begin
        #1;
        if (data_o !== golden) begin
            $display("[%0t] ERROR: expected=%h got=%h",
                      $time, golden, data_o);
            $finish;
        end
    end

    //------------------------------------------------------------
    // stimulus
    //------------------------------------------------------------
    initial begin

        $display("===== TEST START =====");

        rst_n  = 0;
        en     = 0;
        data_i = 0;

        repeat(3) @(posedge clk);
        rst_n = 1;

        //--------------------------------------------------------
        // test enable load
        //--------------------------------------------------------
        repeat(5) begin
            @(posedge clk);
            en = 1;
            data_i = $urandom;
        end

        //--------------------------------------------------------
        // test hold behavior
        //--------------------------------------------------------
        @(posedge clk);
        en = 0;
        data_i = $urandom;

        repeat(3) @(posedge clk);

        //--------------------------------------------------------
        // random test
        //--------------------------------------------------------
        repeat(20) begin
            @(posedge clk);
            en = $urandom % 2;
            data_i = $urandom;
        end

        //--------------------------------------------------------
        // reset test
        //--------------------------------------------------------
        @(posedge clk);
        rst_n = 0;

        repeat(2) @(posedge clk);
        rst_n = 1;

        //--------------------------------------------------------
        // finish
        //--------------------------------------------------------
        repeat(5) @(posedge clk);

        $display("===== TEST PASS =====");
        $finish;

    end

endmodule

