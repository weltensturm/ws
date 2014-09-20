module ws.wm.baseWindowManager;

import
	ws.list,
	ws.wm.baseWindow;

 
class WindowNotFound: Exception {
	@safe pure nothrow
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
		super(msg, file, line, next);
	}
}


class BaseWindowManager {
	
	package {
		BaseWindow activeWindow;
		List!BaseWindow windows;
	}

	this(){
		windows = new List!BaseWindow;
	}

	void add(BaseWindow window){
		windows ~= window;
	}

	void removeWindow(BaseWindow window){
		windows.remove(window);
	}

	bool hasActiveWindows(){
		int c;
		foreach(window; windows)
			if(window.active)
				c++; // ha ha
		return c > 0;
	}

	BaseWindow active(){
		return activeWindow;
	}

	void processEvents(bool noblock = true){
		assert(false, "Not implemented");
	}

	void setTop(BaseWindow win){
		assert(false, "Not implemented");
	}

	long[2] getCursorPos(){
		assert(false, "Not implemented");
	}

	bool isKeyDown(Keyboard.key key){
		assert(false, "Not implemented");
	}

	BaseWindow[] systemWindows(){
		assert(false, "Not implemented");
	}

	BaseWindow findWindow(string title){
		assert(false, "Not implemented");
	}

}

