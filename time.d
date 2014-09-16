module ws.time;

import std.datetime;
version(Windows) import core.sys.windows.windows;

class time {

	static @property double now(){
		//return Clock.currTime().stdTime*10*1000*1000;
		return cast(double)Clock.currAppTick().length / cast(double)TickDuration.ticksPerSec;
	}

	static void sleep(double s){
		if(s <= 0) return;
		version(Windows){
			Sleep(cast(uint)(s * 1000.0));
		}version(linux){
			timespec t = { 0, cast(long)(s * 1000000.0) };
			nanosleep(&t, null);
		}

	}

}

version(Posix) extern(C){

	int nanosleep(const timespec*, timespec*);
	struct timespec {
		long tv_sec;
		long tv_nsec;
	}

}

