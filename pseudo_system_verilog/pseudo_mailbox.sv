program test;
	event data_ready, slot_ready;
	class Producer;
		task gen;
			for (int i =1; i <4; i++) begin
				$display("Producer puts [%0d] to mailbox", i);
				mbx.push_back(i); -> data_ready;
				@(slot_ready);
			end
		endtask
	endclass : Producer

	class Consumer;
		task get;
			int i;
			repeat(3) begin
				@(data_ready);
				$display("Consumer gets [%0d] from mailbox", mbx.pop_front());
				-> slot_ready;
			end
		endtask
	endclass : Consumer

	Producer p;
	Consumer c;
	int mbx[$];

	initial begin
		p = new;
		c = new;
		fork
			p.gen;
			c.get;
			join
	end
endprogram
