// =======================================================================
// program Name : test
// Author       : Kim Daeyeong
// Date         : 2026-04-14
//
// Description  :
//	A lightweight SystemVerilog project showcasing enum-based modeling
//	and class abstraction for seeded pseudo-random selection. Emphasizes
//	reproducibility, clean design, and compatibility with limited 
//	simulators such as Icarus Verilog.
//
// Notes        :
//	-Typedef enum inside a class is not supported in Icarus verilog.
//	-Randomization is controlled via $urandom with user-defined seeds.
//	-'day_to_string' is implemented as a static function as it does
//	 not rely on object state.	
//	-Actual SV codes are written below.
//
// =======================================================================


program test;

	//my_pseudo_code
	
	typedef enum logic [2:0] {MON, TUE, WED, THU, FRI, SAT, SUN} DAYS;

	class Days;
		DAYS day;

		static function string day_to_string(DAYS d);
			case(d)
				MON:		return	"MON";
				TUE:		return	"TUE";
				WED:		return	"WED";
				THU:		return	"THU";
				FRI:		return	"FRI";
				SAT:		return	"SAT";
				SUN:		return	"SUN";
				default:	return "UNKNOWN";
			endcase
		endfunction : day_to_string

		function void pick_random_day(DAYS in_day);
			this.day = in_day;
		endfunction : pick_random_day
	endclass : Days

	//Prototype & fixed array caused by unsupported feature
	Days days;
	DAYS queue_week[5];
	DAYS queue_weekend[2];
	int rand_idx;
	int seed;
	int dummy;	//for no warning message

	initial begin
		queue_week[0]		= MON;
		queue_week[1]		= TUE;
		queue_week[2]		= WED;
		queue_week[3]		= THU;
		queue_week[4]		= FRI;

		queue_weekend[0]	= SAT;
		queue_weekend[1]	= SUN;

		days		= new;

		//random seed for rand_idx
		if (!$value$plusargs("SEED=%d", seed))
			seed = 12345;
		dummy	= $urandom(seed);
		for (int i = 0; i <7; i++) dummy = $urandom();

		//random day from week
		rand_idx = $urandom_range(0, 4);
		days.pick_random_day(queue_week[rand_idx]);
		$display("Chosen day during Week    is \"%s\"", days.day_to_string(days.day));

		//random day from weeekend
		rand_idx = $urandom_range(0, 1);
		days.pick_random_day(queue_weekend[rand_idx]);
		$display("Chosen day during Weekend is \"%s\"", days.day_to_string(days.day));
	end

	////Below codes are for original SystemVerilog which i studied.
	//class Days;
	//	typedef enum {SUN, MON, TUE, WED, THU, FRI, SAT} DAYS;
	//	DAYS queue_day[$];
	//	rand DAYS day;
	//	constraint my_day {day inside queue_day;}
	//endclass : Days

	//Days days;

	//initial begin
	//	days = new;

	//	days.queue_day = '{Days::MON, Days::TUE, Days::WED, Days::THU, Days::FRI};
	//	assert(days.randomize());
	//	$display("Chosen day during Week is \"%s\"", days.day.name);

	//	days.queue_day = '{Days::SAT, Days::SUN};
	//	assert(days.randomize());
	//	$display("Chosen day during Weekend is \"%s\"", days.day.name);

	//end

endprogram
