all:	clean simv wave
clean:	
	\rm -rf wave.* simv*

simv:	clean
	iverilog -g2012 -o simv -I../RTL -I..RTL/TB ../RTL/fifo.sv \
       	../RTL/TB/tb_fifo_golden_ref.sv
	./simv | tee simv.log

wave:	  
	gtkwave wave.vcd

