.PHONY: simv
clean:
	\rm -rf simv *.log
comp:
	iverilog -g2012 -o simv pseudo_mailbox.sv 2>&1 | tee comp.log
simv:
	./simv | tee simv.log
