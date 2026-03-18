// =======================================================================
// Module Name	: my_fifo
// Author	: Kim Daeyeong
// Date		: 2026-03-18
//
// Description	:
// 	Parameteriable synchronous FIFO buffer with general RTL structure
// 	(combinational + sequential logic)
//
// 	- Single clock
// 	- Supports simultaneous read/write operation
// 	- Provides full, empty, almost full, almost empty flag signals
//	
//	Data is written into the FIFO when 'wr' is asserted and Fifo is 
//	not Full. Data is read from the FIFO when 'rd' is asserted and 
//	FIfo is not empty.
//
//	The FIFO uses circular pointer addressing and extra bit for 
//	overaround.
//
// Parameters	:
// 	DATA_WIDTH	  : width of stored data
// 	FIFO_WIDTH	  : WIDTH of FIFO (number of entries)
// 	AFULL_THRESHOLD	  : almost full flag threshold
// 	AEMPTHY_THERSHOLD : almost empthy flag threshold
//
// Interface(Port - wire type)	:
// 	clk	: system clock
// 	rst_n	: active-low synchronous reset
// 	wr	: write request
// 	rd	: read request
// 	data_i	: input data
// 	data_o	: output data
// 	full_o	: FIFO full flag
// 	empty_o	: FIFO empty flag
// 	afull_o	: FIFO almost full flag
// 	aempty_o: FIFO almost empty flag
//
// Notes	:
// 	- Write operation ignored when FIFO is full
// 	- Read operation ignored when FIFO is empty
// 	- Simultaneous read/write allowed when FIFO not full/empty
//
//=========================================================================

module my_fifo #(
	//Parameters
	parameter	DATA_WIDTH 		= 32,
	parameter	FIFO_WIDTH		= 16,
	parameter	AFULL_THRESHOLD		= 13,
	parameter	AEMPTY_THRESHOLD	= 3

)
(	//Port
	input logic				clk,
	input logic				rst_n,
	input logic				wr,
	input logic				rd,
	input logic	[DATA_WIDTH-1:0]	data_i,
	output logic	[DATA_WIDTH-1:0]	data_o,
	output logic 				full_o,
	output logic 				empty_o,
	output logic 				afull_o,
	output logic 				aempty_o
);
	localparam FIFO_DEPTH	= $clog2(FIFO_WIDTH);		//FIFO_DEPTH = 4 for WIDTH 16
	
	//Internal regs & wires
	logic	[DATA_WIDTH-1:0]	mem[0:FIFO_WIDTH-1];	//FIFO circular buffer memory
	logic				full, empty;
	logic				full_n, empty_n;
	logic	[DATA_WIDTH-1:0]	data_r, data_r_n;	//data_r -> data_o
	logic	[FIFO_DEPTH:0]		r_ptr, w_ptr;		//read, write pointer with extra bit
	logic	[FIFO_DEPTH:0]		r_ptr_n, w_ptr_n;
	logic	[FIFO_DEPTH:0]		counter, counter_n;	//counter for threshold of afull & aempty	
	logic				wr_en, rd_en;

	assign wr_en	= wr & ~full;
	assign rd_en	= rd & ~empty;

	//Sequential logic
	always_ff @(posedge clk) begin
		if(!rst_n) begin
			for(int i = 0; i < FIFO_WIDTH; i=i+1) mem[i]	<= {(DATA_WIDTH){1'b0}};
			full 	<= 1'b0;
			empty	<= 1'b1;
			data_r	<= {(DATA_WIDTH){1'b0}};
			r_ptr	<= {(FIFO_DEPTH+1){1'b0}};		
			w_ptr	<= {(FIFO_DEPTH+1){1'b0}};
			counter	<= {(FIFO_DEPTH){1'b0}};		
		end else begin
			full	<= full_n;
			empty	<= empty_n;
			data_r	<= data_r_n;
			r_ptr	<= r_ptr_n;
			w_ptr	<= w_ptr_n;
			counter	<= counter_n;
			if(wr_en) mem[w_ptr[FIFO_DEPTH-1:0]] <= data_i;
		end
	end
	
	//Combinational logic
	always @(*) begin
		full_n		= full;
		empty_n		= empty;
		data_r_n	= data_r;
		r_ptr_n		= r_ptr;
		w_ptr_n		= w_ptr;
		counter_n	= counter;

		//Read operation
		if(rd_en) begin
			data_r_n	= mem[r_ptr[FIFO_DEPTH-1:0]]; //reads without extra bit
			r_ptr_n		= r_ptr + 1'b1;
			counter_n	= counter_n - 1'b1;
		end

		//Write operation
		if(wr_en) begin
			w_ptr_n		= w_ptr + 1'b1;
			counter_n	= counter_n + 1'b1;
		end

		//empty : pointers are same
		//full : pointers are same except extra bit
		empty_n		= (r_ptr_n == w_ptr_n);		      
		full_n		= ((r_ptr_n[FIFO_DEPTH] != w_ptr_n[FIFO_DEPTH])
				&&(r_ptr_n[FIFO_DEPTH-1:0] == w_ptr_n[FIFO_DEPTH-1:0]));
	end

	//Almost full, empty threshold, port assign
	assign afull_o		= (counter >= AFULL_THRESHOLD);
	assign aempty_o		= (counter <= AEMPTY_THRESHOLD);
	assign data_o		= data_r;
	assign full_o		= full;
	assign empty_o		= empty;
endmodule
