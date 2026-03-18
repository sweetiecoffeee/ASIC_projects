// =======================================================================
// Module Name  : my_reg
// Author       : Kim Daeyeong
// Date         : 2026-03-18
//
// Description  :
//	Parameteriable N-bit register with enable signal and 
//	asynchronous actice-low reset
//
// Parameter	:
// 	N	: Data width of the register
//
// Ports	:
// 	clk	: Clock input
// 	rst_n	: Active-low reset
// 	en	: Load enable
// 	d	: N-bit input data to the register
// 	q	: N-bit output data from the register
//
// =======================================================================

module my_reg #(
	parameter	N = 1
)
(
	input logic		clk,
	input logic		rst_n,
	input logic		en,
	input logic	[N-1:0]	d,
	output logic	[N-1:0] q
);

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) q <= '0;
	else if (en) q <= d;
end

endmodule

