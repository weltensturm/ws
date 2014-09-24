module ws.wm.x11.wm;

version(Posix):

import
	derelict.opengl3.gl,
	ws.wm.baseWindowManager,
	ws.wm.x11.api,
	ws.wm.x11.window,
	ws.list,
	ws.wm.baseWindow,
	ws.wm.baseWindowManager;


__gshared:



static wm(){
	static X11WindowManager _wm;
	if(!_wm)
		_wm = new X11WindowManager;
	return _wm;
}

class X11WindowManager: BaseWindowManager {

	package {
		Display* displayHandle;
		XVisualInfo* graphicsInfo;
		XSetWindowAttributes windowAttributes;
		long windowMask;
		long eventMask;
		bool glCore;
		GLXFBConfig* mFBConfig;
		T_glXCreateContextAttribsARB glXCreateContextAttribsARB;


		this(){
			import ws.io; writeln(XEvent.sizeof);
			super();
			DerelictGL3.load();
			displayHandle = XOpenDisplay(null);
			XSynchronize(displayHandle, true);
			glCore = true;
			eventMask = ExposureMask | StructureNotifyMask | KeyPressMask |
				KeyReleaseMask | KeymapStateMask | PointerMotionMask | ButtonPressMask |
				ButtonReleaseMask | EnterWindowMask | LeaveWindowMask;
			windowMask = CWBorderPixel | CWBitGravity | CWEventMask | CWColormap;
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
				GLint att[] = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, 0];
				graphicsInfo = glXChooseVisual(displayHandle, 0, att.ptr);
				if(!graphicsInfo)
					throw new Exception("glXChooseVisual failed");
			}
			windowAttributes.event_mask = eventMask;
			windowAttributes.border_pixel = 0;
			windowAttributes.bit_gravity = StaticGravity;
			windowAttributes.colormap = XCreateColormap(
					displayHandle, XRootWindow(displayHandle, graphicsInfo.screen),
					graphicsInfo.visual, AllocNone
			);
		}
		
		~this(){
			XCloseDisplay(displayHandle);
		}
		
	}

	override void processEvents(){
		while(XPending(wm.displayHandle)){
			XEvent e;
			XNextEvent(wm.displayHandle, &e);
			foreach(win; wm.windows){
				if(e.xany.window == win.windowHandle && win.isActive){
					activeWindow = win;
					win.activateGraphicsContext();
					win.processEvent(e);
				}
			}
		}
	}

}
