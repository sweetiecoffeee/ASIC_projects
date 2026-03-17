all:	clean simv wave

clean:	
	rm -rf wave.* simv
simv:   clean
	iverilog -g2012 -o simv -I../RTL -I..RTL/TB ../RTL/fifo.v \
       	../RTL/TB/tb_fifo.sv
wave:   simv
	./simv
	gtkwave wave.vcd

