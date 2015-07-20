module ws.thread.future;

import std.parallelism;


class Future(T) {

	bool done(){
		return task.done;
	}
	
	T get(){
		return task.yieldForce;
	}
	
	protected Task!T task;

}