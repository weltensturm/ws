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

alias void delegate() Function;


interface Loader {

	void run(Function);

	int length();

}


class LoaderQueue: Loader {
	
	private List!Function queue;

	this(){
		queue = new List!Function;
	}

	override int length(){
		synchronized(this){
			return cast(int)queue.length;
		}
	}

	override void run(Function fn){
		synchronized(this){
			queue ~= fn;
		}
	}

	void tick(){
		if(length){
			Function fn;
			synchronized(this){
				fn = queue.popFront();
			}
			fn();
		}
	}

}


class LoaderThread: LoaderQueue {

	private Thread worker;

	this(void delegate() precall){
		queue = new List!Function;
		worker = new Thread({
			worker.priority = Thread.PRIORITY_MIN;
			worker.isDaemon = true;
			while(worker.isRunning && queue){
				try {
					while(worker && worker.isRunning && queue && !queue.length)
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
