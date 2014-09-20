module ws.wm.baseWindow;

public import
	ws.gui.base,
	ws.gui.input;

import
	ws.wm,
	ws.list;


class BaseWindow: Base {

	package {
		Mouse.cursor cursor = Mouse.cursor.inherit;
		string title;
		bool isActive = false;
		WindowHandle windowHandle;
		GraphicsContext graphicsContext;
		List!Event eventQueue;
	}

	this(){
		eventQueue = new List!Event;
	}

	void onRawMouse(int x, int y){}

	@property
	bool active(){
		return isActive;
	}

	void processEvents(){
		foreach(i, e; eventQueue){
			eventQueue.popFront();
			if(isActive){
				setActive();
				processEvent(e);
			}
		}
	}

	void setActive(){
		throw new Exception("Not implemented");
	}

	void processEvent(Event){
		throw new Exception("Not implemented");
	}

	void initialize(){
		throw new Exception("Not implemented");
	}

	override void setCursor(Mouse.cursor){
		throw new Exception("Not implemented");
	}
	void setCursorPos(int x, int y){
		throw new Exception("Not implemented");
	}
	void setTitle(string){
		throw new Exception("Not implemented");
	}
	string getTitle(){
		throw new Exception("Not implemented");
	}
	long getPid(){
		throw new Exception("Not implemented");
	}
	void setFront(){
		throw new Exception("Not implemented");
	}

	GraphicsContext shareContext(){
		throw new Exception("Not implemented");
	}
	void makeCurrent(GraphicsContext){
		throw new Exception("Not implemented");
	}
	void createGraphicsContext(){
		throw new Exception("Not implemented");
	}
	void createGraphicsContextOld(){
		throw new Exception("Not implemented");
	}
	void shouldCreateGraphicsContext(){
		throw new Exception("Not implemented");
	}
	void activateGraphicsContext(){
		throw new Exception("Not implemented");
	}
	void swapBuffers(){
		throw new Exception("Not implemented");
	}
	long[2] getScreenSize(){
		throw new Exception("Not implemented");
	}

}
