module ws.wm.x11.wm;

version(Posix):

import
	std.stdio,
	derelict.opengl3.gl,
	ws.wm,
	ws.wm.baseWindowManager,
	ws.wm.x11.api,
	ws.wm.x11.window,
	ws.list,
	ws.wm.baseWindowManager;


__gshared:


struct EventMaskMapping {
	int mask;
	int type;
}

enum eventMaskMap = [
	EventMaskMapping(ExposureMask, Expose),
	EventMaskMapping(EnterWindowMask, EnterNotify),
	EventMaskMapping(LeaveWindowMask, LeaveNotify),
	EventMaskMapping(ButtonPressMask, ButtonPress),
	EventMaskMapping(ButtonReleaseMask, ButtonRelease),
	EventMaskMapping(PointerMotionMask, MotionNotify)
];

class X11WindowManager: BaseWindowManager {

	this(){
		XInitThreads();
		super();
		DerelictGL3.load();
		displayHandle = XOpenDisplay(null);
		debug {
			XSynchronize(displayHandle, true);
		}
		glCore = true;
		//load!("glXCreateContextAttribsARB");
		if(!glXCreateContextAttribsARB)
			glCore = false;
		/*if(glCore){
			// Initialize
			int configCount = 0;
			int fbAttribs[] = [
				GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
				GLX_X_RENDERABLE, True,
				GLX_RENDER_TYPE, GLX_RGBA_BIT,
				GLX_RED_SIZE, 8,
				GLX_BLUE_SIZE, 8,
				GLX_GREEN_SIZE, 8,
				GLX_DEPTH_SIZE, 16,
				GLX_STENCIL_SIZE, 8,
				GLX_DOUBLEBUFFER, True,
				GLX_SAMPLE_BUFFERS, True,
				GLX_SAMPLES, 2,
				0
			];
			GLXFBConfig* mFBConfig = glXChooseFBConfig(displayHandle, DefaultScreen(*displayHandle), fbAttribs.ptr, &configCount);
			if(!configCount)
				throw new Exception("osWindow Initialisation: Failed to get frame buffer configuration. Are your drivers up to date?");
			graphicsInfo = cast(XVisualInfo*)glXGetVisualFromFBConfig(displayHandle, mFBConfig[0]);
		}else{*/{

			if(true){
				GLint[] att = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_ALPHA_SIZE, 8, GLX_DOUBLEBUFFER, 0];
				graphicsInfo = cast(XVisualInfo*)glXChooseVisual(displayHandle, 0, att.ptr);
			}else{
				graphicsInfo = new XVisualInfo;
				if(!XMatchVisualInfo(displayHandle, DefaultScreen(displayHandle), 32, TrueColor, graphicsInfo))
					writeln("XMatchVisualInfo failed");
			}
			if(!graphicsInfo)
				writeln("glXChooseVisual failed");
		}
	}

	Display* displayHandle;
	XVisualInfo* graphicsInfo;
	bool glCore;
	GLXFBConfig* mFBConfig;
	T_glXCreateContextAttribsARB glXCreateContextAttribsARB;

	void delegate(XEvent*)[][int][x11.X.Window] handler;
	void delegate(XEvent*)[][int] handlerAll;

	void on(void delegate(XEvent*)[int] handlers){
		foreach(ev, dg; handlers){
			handlerAll[ev] ~= dg;
		}
	}

	void on(x11.X.Window window, void delegate(XEvent*)[int] handlers){
		int mask;
		foreach(ev, dg; handlers){
			foreach(mapping; eventMaskMap){
				if(mapping.type == ev)
					mask |= mapping.mask;
			}
			handler[window][ev] ~= dg;
		}
		//XSelectInput(displayHandle, window, mask);
	}

	~this(){
		XCloseDisplay(displayHandle);
	}

	void processEvents(){
		while(XPending(wm.displayHandle)){
			XEvent e;
			XNextEvent(wm.displayHandle, &e);
			foreach(win; wm.windows){
				if(e.xany.window == win.windowHandle){
					activeWindow = win;
					win.gcActivate;
					win.processEvent(&e);
				}
			}
			if(e.type in handlerAll)
				foreach(handler; handlerAll[e.type])
					handler(&e);
			if(e.xany.window in handler){
				auto handlerWindow = handler[e.xany.window];
				if(e.type in handlerWindow)
					foreach(handlerWindowType; handlerWindow[e.type])
						handlerWindowType(&e);
			}
		}
	}

}
