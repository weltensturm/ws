module ws.thread.loader;

import
	core.thread,
	std.traits,
	ws.wm,
	ws.thread.awaiter,
	ws.log,
	ws.list,
	ws.event,
	ws.io;

__gshared:


class Loadable {
	
	enum: size_t {
		Idle,
		Loading,
		Loaded,
		Error
	}
	
	this(){
		loadState = Loadable.Idle;
		onLoaded = new LoadedQueue;
	}
	
	void finish(){
		synchronized(this){
			state = Loaded;
		}
	}
	
	@property size_t loadState(){
		synchronized(this) {
			return state;
		}
	}
	
	@property size_t loadState(size_t s){
		synchronized(this){
			state = s;
			if(s == Loaded)
				onLoaded();
			return state;
		}
	}
	
	@property bool loaded(){
		synchronized(this) {
			return state == Loaded;
		}
	}
	
	Loader loader;
	LoadedQueue onLoaded;
	
	private:
		size_t state;
			
		class LoadedQueue: ws.event.Event!() {
			void opOpAssign(string op)(void delegate() d) if(op=="~") {
				if(loaded)
					d();
				else
					super.opOpAssign!op(d);
			}
		}

}


class Loader {
	
	void run(Where where, void delegate() fn){
		final switch(where){
			case Where.Main:
				synchronized(this)
					queue ~= fn;
			break;
			case Where.GL: threadGL.run(fn); break;
			case Where.Any: threadAny.run(fn); break;
		}
	}

	void tick(){
		if(queue.length){
			Function fn;
			synchronized(this){
				//fn = queue[0];
				//queue = queue[1..$];
				fn = queue.popFront();
			}
			fn();
		}
				//queue.popFront()();
	}

	enum Where {
		Main,
		GL,
		Any
	}

	alias void delegate() Function;
	
	
	private class LoaderThread {

		List!Function queue;
		Thread worker;

		void run(Function cb){
			synchronized(this)
				queue ~= cb;
		}

		this(void delegate() precall){
			queue = new List!Function;
			worker = new Thread({
				worker.priority = Thread.PRIORITY_MIN;
				worker.isDaemon = true;
				while(worker.isRunning && queue){
					try {
						while(worker.isRunning && queue && !queue.length)
							worker.sleep(msecs(10));
						if(!queue)
							return;
						Function cb;
						synchronized(this)
							cb = queue.popFront();
						precall();
						cb();
					}catch(Throwable t)
						Log.error("THREAD ERROR: " ~ t.toString());
				}
			});
			worker.start();
		}

	}
	
	void stop(){
		threadGL.queue = null;
		threadAny.queue = null;
	}
	
	//Function[] queue;
	List!Function queue;
	LoaderThread threadGL;
	LoaderThread threadAny;

	this(Window w, GraphicsContext c){
		assert(w);
		assert(c);
		queue = new List!Function;
		threadGL = new LoaderThread({
			w.makeCurrent(c);
		});
		threadAny = new LoaderThread({});


	}
	
}
