module ws.wm.baseWindowManager;

import
	std.algorithm,
	ws.wm,
	ws.gui.input;

 
class WindowNotFound: Exception {
	@safe pure nothrow
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
		super(msg, file, line, next);
	}
}


class BaseWindowManager {
	
	package {
		Window activeWindow;
		Window[] windows;
	}

	this(){}

	void add(Window window){
		windows ~= window;
	}

	void remove(Window window){
		auto at = windows.countUntil(window);
		windows = windows[0 .. at] ~ windows[at .. $];
	}

	bool hasActiveWindows(){
		int c;
		foreach(window; windows)
			if(window.isActive)
				return true;
		return false;
	}

	Window active(){
		return activeWindow;
	}

}

