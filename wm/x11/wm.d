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


static X11WindowManager wm;

static this(){
	wm = new X11WindowManager;
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

		void internalEventsProcess(){

			foreach(w; windows){
				foreach(e; w.eventQueue){
					w.eventQueue.popFront();
					activeWindow = w;
					w.activateGraphicsContext();
					w.processEvent(e);
				}
			}
		}


		this(){
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

	override void processEvents(bool noblock){
		while(XPending(wm.displayHandle)){
			XEvent e;
			XNextEvent(wm.displayHandle, &e);
			foreach(win; wm.windows){
				if(e.xany.window == win.windowHandle && win.isActive){
					win.eventQueue ~= e;
					wm.internalEventsProcess();
				}
			}
		}
	}

}


protected:

	void processEvent(X11Window w, XEvent e){
		switch(e.type){
			case ConfigureNotify:
				if(w.size.x != e.xconfigure.width || w.size.y != e.xconfigure.height){
					w.onResize(e.xconfigure.width, e.xconfigure.height);
					w.size.x = e.xconfigure.width; w.size.y = e.xconfigure.height;
				}
				if(w.pos.x != e.xconfigure.x || w.pos.y != e.xconfigure.y){
					w.onMove(e.xconfigure.x, e.xconfigure.y);
					w.pos.x = e.xconfigure.x; w.pos.y = e.xconfigure.y;
				}
				break;
			case KeyPress:
				w.onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), true);
				char str[25];
				size_t l = Xutf8LookupString(w.inputContext, &e.xkey, str.ptr, 25, null, null);
				if(l){
					string s;
					for(size_t i=0; i<l; ++i)
						s ~= str[i];
					foreach(dchar c; s)
						w.onKeyboard(c);
				}
				break;
			case KeyRelease: w.onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), false); break;
			case MotionNotify: w.onMouseMove(e.xmotion.x, w.size.y - e.xmotion.y); break;
			case ButtonPress: w.onMouseButton(e.xbutton.button, true, e.xbutton.x, e.xbutton.y); break;
			case ButtonRelease: w.onMouseButton(e.xbutton.button, false, e.xbutton.x, e.xbutton.y); break;
			case EnterNotify: w.onMouseFocus(true); break;
			case LeaveNotify: w.onMouseFocus(false); break;
			case Expose: w.shouldRedraw = false; w.onDraw(); break;
			case ClientMessage: w.hide(); break;
			case KeymapNotify: XRefreshKeyboardMapping(&e.xmapping); break;
			default:break;
		}
	}

