.PHONY: simv
.PHONY: comp_class_arguments
all: clean comp_class_arguments simv

clean:
	\rm -rf simv *.log +* vvp*

comp_class_arguments:	clean
	iverilog -g2012 -o simv pseudo_class_arguments.sv 2>&1 | tee comp.log

simv:
	echo "==== Simulation Start ====" | tee simv.log
	./simv >> simv.log
	echo "==== Simulation END ====" >> simv.log
