// =======================================================================
// Program Name	: test
// Author	: Kim Daeyeong
// Date		: 2026-04-20
//
// Description	:
// 	This project shows a simple example of using a SystemVerilog class
// 	to represent a bus transaction. The 'MyBusTran' class contains an
// 	address and four data values, which are initialized using a 
// 	constructor with default and custom inputs. Instead of using an
// 	array, separate variables (data0 ~ data3) are used to ensure stable
// 	behabior in simulators like Icarus Verilog. The testbench creates
// 	multiple objects with different inputs to demonstrate how the
// 	constructor works.
// Notes	:
// 	- Array is not fully supported in class at Icarus Verilog
//
// =======================================================================

program test;
	class MyBusTran;
		logic [31:0]	addr;
	        logic [31:0]	crc;
		logic [31:0]	data0,data1,data2,data3;	
		//logic [31:0]	data[4];

		function new(logic [31:0] a = 5, d = 7);
			addr		= a;

			data0		= d;
			data1		= d;
			data2		= d;
			data3		= d;

			//foreach(data[i])
			//	data[i]	= d;
		endfunction : new

		function void display();
			$display("Addr    = 0x%08h", addr);
			$display("Data[0] = 0x%08h", data0);
			$display("Data[1] = 0x%08h", data1);
			$display("Data[2] = 0x%08h", data2);
			$display("Data[3] = 0x%08h\n", data3);

			//foreach(data[i])
			//	$display("Data[%0d] = 0x%8h", i, data[i]);
		endfunction : display

	endclass : MyBusTran

	MyBusTran a, b, c, d;

	initial begin
		a	= new;
		a.display();
		b	= new(9);
		b.display();
		c	= new(11, 20);
		c.display();
		d	= new(, 15);
		d.display();
	end
endprogram
