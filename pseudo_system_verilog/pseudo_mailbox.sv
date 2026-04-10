// =======================================================================
// program Name : test
// Author       : Kim Daeyeong
// Date         : 2026-04-10
//
// Description	:
// 	This code implements a producer-consumer model using SystemVerilog.
// 	A queue is used as a FIFO buffer, where the producer inserts data
// 	using push_back and the consumer retrieves data using pop_front.
// 	Synchronization between the producer and consumer is achieved using
// 	events, forming a simple handshake mechanism to prevent race
// 	conditions and ensure proper data transfer order.
//
// Notes	:
// 	-Additional event slot_ready was added cause not using mailbox.
// 	-Queue can do back and front for both push and pop.
//
// =======================================================================

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
