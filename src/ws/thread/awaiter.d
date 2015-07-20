module ws.thread.awaiter;

import
	core.thread,
	std.parallelism,
	ws.list,
	ws.exception,
	ws.io;

__gshared:


class Awaiter {
	
	this(){
		fibers = new List!Fiber;
	}

	/++
		Creates a Fiber (coroutine) and puts it into 'fibers'.
		To complete the work, call 'tick' from a repeating function.
	+/
	void spawn(void delegate() f){
		fibers ~= new Fiber(f);
	}

	/++
		Creates a Fiber (coroutine) and puts it into 'fibers'.
		After that, it waits until the fiber has been processed.
		This is supposed to be called from worker threads that were started with $(D async).
	+/
	void process(void delegate() func){
		assert(!thread_isMainThread(), "Cannot run 'process' from main thread, deadlock");
		auto f = new Fiber(func);
		fibers ~= f;
		while(f.state != Fiber.State.TERM)
			Thread.yield();
	}
	
	/// Creates a new Thread from inside a Fiber and waits until it completed its work.
	T async(T)(T delegate() func){
		if(!Fiber.getThis())
			exception("Cannot call \"async\" from non-fiber. Use it in a spawn({ .. here .. })");
		T result;
		auto t = new Task({
			try
				result = func();
			catch(Exception e)
				writeln("THREAD ERROR:\n", e);
		});
		TaskPool.taskPool().put(t);
		while(!t.done)
			Fiber.getThis().yield();
		return result;
	}

	/// Creates a new Thread from inside a Fiber and waits until it completed its work.
	void async(T: void)(T delegate() func){
		if(!Fiber.getThis())
			exception("Cannot call \"async\" from non-fiber. Use it in a spawn({ .. here .. })");
		auto t = new Thread({
			try
				func();
			catch(Exception e)
				writeln("THREAD ERROR:\n", e);
		});
		t.start();
		while(t.isRunning)
			Fiber.getThis().yield();
			
	}
	
	void tick(){
		foreach(f; fibers){
			f.call();
			if(f.state == Fiber.State.TERM)
				fibers.remove(f);
		}
	}
	
	List!Fiber fibers;
	
}

