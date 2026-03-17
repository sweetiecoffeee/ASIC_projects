module my_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_WIDTH = 16,
    parameter AFULL_THRESHOLD = 13,
    parameter AEMPTY_THRESHOLD = 3
)
(
    input clk, rst_n, wr, rd,
    input [DATA_WIDTH-1:0] data_i,
    output full_o, empty_o, afull_o, aempty_o,
    output [DATA_WIDTH-1:0] data_o
);
    localparam FIFO_DEPTH = $clog2(FIFO_WIDTH); // 4
    
    reg [DATA_WIDTH-1:0] mem [0:FIFO_WIDTH-1];      //fifo memory
    reg [FIFO_DEPTH:0] counter, counter_n;          //counter range: 0~31
    reg [FIFO_DEPTH:0] r_ptr, r_ptr_n;              // 5 bit
    reg [FIFO_DEPTH:0] w_ptr, w_ptr_n;
    reg empty, empty_n, full, full_n;
    reg [DATA_WIDTH-1:0] r_data, r_data_n;
    integer i;
    
    //wire assignment
    wire w_en, rd_en;
    assign w_en = wr & ~full;
    assign rd_en = rd & ~empty;
    
    //state transition
    always @(posedge clk) begin
        if(!rst_n) begin
            full    <= 1'b0;
            empty   <= 1'b1;
            counter <= {(FIFO_DEPTH+1){1'b0}};
            r_ptr   <= {(FIFO_DEPTH+1){1'b0}};
            w_ptr   <= {(FIFO_DEPTH+1){1'b0}};
            r_data  <= {(DATA_WIDTH){1'b0}};
            for (i=0; i<FIFO_WIDTH; i=i+1) mem[i]   <= {(DATA_WIDTH){1'b0}};
        end else begin 
            r_ptr   <= r_ptr_n;
            w_ptr   <= w_ptr_n;
            empty   <= empty_n;
            full    <= full_n;
            counter <= counter_n;   
            r_data  <= r_data_n;
            if (w_en) mem[w_ptr[FIFO_DEPTH-1:0]] <= data_i;
        end
    end
    
    //combinational logic
    always @* begin
        r_ptr_n   = r_ptr;
        w_ptr_n   = w_ptr;
        empty_n   = empty;
        full_n    = full;
        counter_n = counter;
        r_data_n  = r_data;  
        if(w_en) begin
            w_ptr_n     =  w_ptr + 1'd1;
            counter_n   = counter_n + 1'd1; 
        end 
        if(rd_en) begin
            r_data_n    = mem[r_ptr[FIFO_DEPTH-1:0]];
            r_ptr_n     =  r_ptr + 1'd1;
            counter_n   =  counter_n - 1'd1;
        end
        empty_n     = (r_ptr_n == w_ptr_n);
        full_n      = (r_ptr_n[FIFO_DEPTH] != w_ptr_n[FIFO_DEPTH]) && (r_ptr_n[FIFO_DEPTH-1:0] == w_ptr_n[FIFO_DEPTH-1:0]);
    end
    
    //output assignment
    assign afull_o  =   (counter >= AFULL_THRESHOLD);
    assign aempty_o =   (counter <= AEMPTY_THRESHOLD);
    assign full_o   =   full;
    assign empty_o  =   empty;
    assign data_o   =   r_data;
endmodule
