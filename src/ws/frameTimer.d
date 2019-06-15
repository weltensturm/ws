module ws.frameTimer;


import ws.time;


class FrameTimer {

	double now;
	double dur;

	this(){
		now = .now;
	}

	void tick(){
		auto newNow = .now;
		dur = (newNow - now);
		now = newNow;
	}

}