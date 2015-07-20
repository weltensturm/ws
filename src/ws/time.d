module ws.time;

import
	core.thread,
	std.datetime;

class time {

	static @property double now(){
		return cast(double)Clock.currAppTick().length / cast(double)TickDuration.ticksPerSec;
	}

	static void sleep(double s){
		Thread.sleep(dur!"msecs"(cast(int)(s*1000)));
	}

}

