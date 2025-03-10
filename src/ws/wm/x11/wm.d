module ws.wm.x11.wm;

version(Posix):

import
	std.stdio,
	std.traits,
	std.string,
	std.meta,
	std.algorithm,
	ws.wm,
	ws.wm.baseWindowManager,
	ws.wm.x11.api,
	ws.wm.x11.window,
	ws.list,
	ws.wm.baseWindowManager;


__gshared:



private struct Mapping(alias m, int t, T, string fn){
	enum mask = m;
	enum type = t;
	alias Event = T;
	enum attribute = fn;
}

pragma(msg, ButtonPressMask);

alias EventMap = AliasSeq!(
	Mapping!(ButtonPressMask, 			ButtonPress, 		XButtonPressedEvent,		"xbutton"),
	Mapping!(ButtonReleaseMask,			ButtonRelease, 		XButtonReleasedEvent,		"xbutton"),
	Mapping!(ColormapChangeMask, 		ColormapNotify, 	XColormapEvent,				"xcolormap"),
	Mapping!(EnterWindowMask, 			EnterNotify, 		XEnterWindowEvent,			"xcrossing"),
	Mapping!(LeaveWindowMask, 			LeaveNotify, 		XLeaveWindowEvent,			"xcrossing"),
	Mapping!(ExposureMask,				Expose, 			XExposeEvent,				"xexpose"),
	Mapping!(GCGraphicsExposures, 		GraphicsExpose, 	XGraphicsExposeEvent,		"xgraphicsexpose"),
	Mapping!(GCGraphicsExposures,		NoExpose, 			XNoExposeEvent,				"xnoexpose"),
	Mapping!(FocusChangeMask, 			FocusIn, 			XFocusInEvent,				"xfocus"),
	Mapping!(FocusChangeMask,			FocusOut, 			XFocusOutEvent,				"xfocus"),
	Mapping!(KeymapStateMask, 			KeymapNotify, 		XKeymapEvent,				"xkeymap"),
	Mapping!(KeyPressMask, 				KeyPress, 			XKeyPressedEvent,			"xkey"),
	Mapping!(KeyReleaseMask, 			KeyRelease, 		XKeyReleasedEvent,			"xkey"),
	Mapping!(PointerMotionMask, 		MotionNotify, 		XPointerMovedEvent,			"xmotion"),
	Mapping!(PropertyChangeMask, 		PropertyNotify, 	XPropertyEvent,				"xproperty"),
	Mapping!(ResizeRedirectMask, 		ResizeRequest, 		XResizeRequestEvent,		"xresizerequest"),
	Mapping!(StructureNotifyMask, 		CirculateNotify, 	XCirculateEvent,			"xcirculate"),
	Mapping!(StructureNotifyMask,		ConfigureNotify, 	XConfigureEvent,			"xconfigure"),
	Mapping!(StructureNotifyMask,		DestroyNotify, 		XDestroyWindowEvent,		"xdestroywindow"),
	Mapping!(StructureNotifyMask,		GravityNotify, 		XGravityEvent,				"xgravity"),
	Mapping!(StructureNotifyMask,		MapNotify, 			XMapEvent,					"xmap"),
	Mapping!(StructureNotifyMask,		ReparentNotify, 	XReparentEvent,				"xreparent"),
	Mapping!(StructureNotifyMask,		UnmapNotify, 		XUnmapEvent,				"xunmap"),

	Mapping!(SubstructureNotifyMask, 	CirculateNotify, 	XCirculateEvent,			"xcirculate"),
	Mapping!(SubstructureNotifyMask,	ConfigureNotify, 	XConfigureEvent,            "xconfigure"),
	Mapping!(SubstructureNotifyMask,	CreateNotify, 		XCreateWindowEvent,         "xcreatewindow"),
	Mapping!(SubstructureNotifyMask,	GravityNotify, 		XGravityEvent,              "xgravity"),
	Mapping!(SubstructureNotifyMask,	MapNotify, 			XMapEvent,                  "xmap"),
	Mapping!(SubstructureNotifyMask,	ReparentNotify, 	XReparentEvent,             "xreparent"),
	Mapping!(SubstructureNotifyMask,	UnmapNotify, 		XUnmapEvent,                "xunmap"),
	Mapping!(SubstructureRedirectMask, 	CirculateRequest, 	XCirculateRequestEvent,     "xcirculaterequest"),
	Mapping!(SubstructureRedirectMask,	ConfigureRequest, 	XConfigureRequestEvent,     "xconfigurerequest"),
	Mapping!(SubstructureRedirectMask,	MapRequest, 		XMapRequestEvent,           "xmaprequest"),

	Mapping!(None, 						ClientMessage, 		XClientMessageEvent,		"xclient"),
	Mapping!(None, 						MappingNotify, 		XMappingEvent,				"xmapping"),
	Mapping!(None, 						SelectionClear, 	XSelectionClearEvent,		"xselectionclear"),
	Mapping!(None, 						SelectionNotify, 	XSelectionEvent,			"xselection"),
	Mapping!(None, 						SelectionRequest, 	XSelectionRequestEvent,		"xselectionrequest"),
	Mapping!(VisibilityChangeMask, 		VisibilityNotify, 	XVisibilityEvent,			"xvisibility")
);


class X11WindowManager: BaseWindowManager {

	this(){
		XInitThreads();
		super();
		displayHandle = XOpenDisplay(null);
		glCore = true;
		glXCreateContextAttribsARB = cast(T_glXCreateContextAttribsARB)
                glXGetProcAddress(cast(ubyte*)"glXCreateContextAttribsARB".toStringz);
		if(!glXCreateContextAttribsARB)
			glCore = false;
        
		if(glCore){

            auto getFramebufferConfigs = (int[int] attributes){
                int[] attribs;
                foreach(key, value; attributes){
                    attribs ~= [key, value];
                }
                attribs ~= 0;

                int configCount;
                GLXFBConfig* mFBConfig = glXChooseFBConfig(displayHandle, DefaultScreen(displayHandle),
                                                           attribs.ptr, &configCount);
                auto result = mFBConfig[0..configCount].dup;
                XFree(mFBConfig);
                return result;
            };

            auto fbAttribs = [
                GLX_DRAWABLE_TYPE: GLX_WINDOW_BIT,
                GLX_X_RENDERABLE: True,
                GLX_RENDER_TYPE: GLX_RGBA_BIT,
                GLX_ALPHA_SIZE: 8,
				GLX_RED_SIZE: 8,
				GLX_BLUE_SIZE: 8,
				GLX_GREEN_SIZE: 8,
				GLX_DEPTH_SIZE: 16,
				GLX_DOUBLEBUFFER: True,
				/+
				GLX_STENCIL_SIZE: 8,
				GLX_SAMPLE_BUFFERS: True,
				GLX_SAMPLES: 2,
				+/
            ];

            auto fbConfigs = getFramebufferConfigs(fbAttribs);

            if(!fbConfigs.length)
                throw new Exception("No FB matches");
			
			foreach(config; fbConfigs){
				auto info = cast(XVisualInfo*)glXGetVisualFromFBConfig(displayHandle, config);
				if(info.depth == 32){
					graphicsInfo = info;
					break;
				}
			}

			if(!graphicsInfo)
				throw new Exception("Failed to find FB config");

		}else{
			graphicsInfo = new XVisualInfo;
			if(!XMatchVisualInfo(displayHandle, DefaultScreen(displayHandle), 32, TrueColor, graphicsInfo))
				writeln("XMatchVisualInfo failed");
			if(!graphicsInfo)
				writeln("glXChooseVisual failed");
		}
	}

	Display* displayHandle;
	XVisualInfo* graphicsInfo;
	bool glCore;
	GLXFBConfig* mFBConfig;
	T_glXCreateContextAttribsARB glXCreateContextAttribsARB;

	void delegate(XEvent*)[][int][WindowHandle] handler;
	void delegate(XEvent*)[][int] handlerAll;

	void on(void delegate(XEvent*)[int] handlers){
		foreach(ev, dg; handlers){
			handlerAll[ev] ~= dg;
		}
	}

	void on()(WindowHandle window, void delegate(XEvent*)[int] handlers){
		XWindowAttributes wa;
		XGetWindowAttributes(wm.displayHandle, window, &wa);
		long mask = wa.your_event_mask;
		foreach(ev, dg; handlers){
			foreach(mapping; EventMap){
				if(mapping.type == ev)
					mask |= mapping.mask;
			}
			handler[window][ev] ~= dg;
		}
		XSelectInput(displayHandle, window, mask);
	}

	void on(Args...)(WindowHandle window, Args args) if(allSatisfy!(isCallable, args)) {
		XWindowAttributes wa;
		XGetWindowAttributes(wm.displayHandle, window, &wa);
		long mask = wa.your_event_mask;
		foreach(dg; args){
			bool found;
			foreach(mapping; EventMap){
				static if(is(mapping.Event* == Parameters!dg[0])){
					mask |= mapping.mask;
					if(!found){
						found = true;
						handler[window][mapping.type] ~= (XEvent* e) => mixin("dg(&e." ~ mapping.attribute ~ ")");
					}
				}
			}
		}
		XSelectInput(displayHandle, window, mask);
	}

	~this(){
		XCloseDisplay(displayHandle);
	}

	GraphicsContext currentContext(){
		return glXGetCurrentContext();
	}

	void processEvents(void delegate(XEvent*) handleAll=null, bool syncNext=false){
		XEvent e;
		while(XPending(displayHandle) || syncNext){
			syncNext = false;
			XNextEvent(displayHandle, &e);
			if(handleAll)
				handleAll(&e);
			foreach(win; wm.windows){
				if(e.xany.window == win.windowHandle){
					activeWindow = win;
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
