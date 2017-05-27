module ws.wm.baseWindowManager;

import
	ws.list,
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
		List!Window windows;
	}

	this(){
		windows = new List!Window;
	}

	void add(Window window){
		windows ~= window;
	}

	void remove(Window window){
		windows.remove(window);
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

