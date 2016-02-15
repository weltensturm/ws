module ws.time;

import
	core.thread,
	std.datetime;

double now(){
	return MonoTime.currTime.ticks / cast(double)MonoTime.ticksPerSecond;
}

void sleep(double s){
	Thread.sleep(dur!"msecs"(cast(int)(s*1000)));
}

