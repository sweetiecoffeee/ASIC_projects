.PHONY: simv
clean:
	\rm -rf simv *.log +* vvp*

comp_week_random:	clean
	iverilog -g2012 -o simv pseudo_random_week.sv 2>&1 | tee comp.log
	echo "==== Simulation Start ====" | tee simv.log
	echo "SEED=1"    >> simv.log
	vvp simv +SEED=1 >> simv.log
	echo "SEED=2"    >> simv.log
	vvp simv +SEED=2 >> simv.log
	echo "SEED=3"    >> simv.log
	vvp simv +SEED=3 >> simv.log
	echo "SEED=4"    >> simv.log
	vvp simv +SEED=4 >> simv.log
	echo "SEED=5"    >> simv.log
	vvp simv +SEED=5 >> simv.log
	echo "==== Simulation END ====" >> simv.log

simv:
	./simv | tee simv.log
