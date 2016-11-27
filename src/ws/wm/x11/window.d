module ws.wm.x11.window;

version(Posix):

import
	std.conv,
	std.string,
	ws.wm,
	ws.gui.base,
	ws.list,
	derelict.opengl3.gl3,
	ws.wm.x11.api;

import derelictX = derelict.util.xtypes;

__gshared:


class X11Window: Base {

	Mouse.cursor cursor = Mouse.cursor.inherit;
	string title;
	bool isActive = false;
	WindowHandle windowHandle;
	GraphicsContext graphicsContext;
	List!Event eventQueue;

	XIC inputContext;
	int oldX, oldY;
	int jumpTargetX, jumpTargetY;

	bool mouseFocus;

	this(WindowHandle handle){
		assert(handle);
		windowHandle = handle;
	}

	XSetWindowAttributes windowAttributes;

	Atom wmDelete;

	this(int w, int h, string t, bool override_redirect=false){
		title = t;
		size = [w, h];
		eventQueue = new List!Event;
		
		auto eventMask =
				ExposureMask |
				StructureNotifyMask |
				KeyPressMask |
				KeyReleaseMask |
				KeymapStateMask |
				PointerMotionMask |
				ButtonPressMask |
				ButtonReleaseMask |
				EnterWindowMask |
				LeaveWindowMask;
		
		auto windowMask =
				CWBorderPixel |
				CWBitGravity |
				CWEventMask |
				CWColormap |
				CWBackPixmap |
				(override_redirect ? CWOverrideRedirect : 0);

		auto root = XDefaultRootWindow(wm.displayHandle); 

		windowAttributes.override_redirect = override_redirect;
		windowAttributes.background_pixmap = None;
		windowAttributes.event_mask = eventMask;
		windowAttributes.border_pixel = 0;
		windowAttributes.bit_gravity = StaticGravity;
		windowAttributes.colormap = XCreateColormap(wm.displayHandle, root, wm.graphicsInfo.visual, AllocNone);
		
		windowHandle = XCreateWindow(
			wm.displayHandle,
			root,
			0, 0, cast(size_t)size.x, cast(size_t)size.y, 0,
			wm.graphicsInfo.depth,
			InputOutput,
			wm.graphicsInfo.visual,
			windowMask,
			&windowAttributes
		);
		
		inputContext = XCreateIC(
			XOpenIM(wm.displayHandle, null, null, null),
			XNClientWindow, windowHandle,
			XNFocusWindow, windowHandle,
			XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
			null
		);
		XSelectInput(wm.displayHandle, windowHandle, eventMask);
		wmDelete = XInternAtom(wm.displayHandle, "WM_DELETE_WINDOW".toStringz, True);
		XSetWMProtocols(wm.displayHandle, windowHandle, &wmDelete, 1);
		gcInit;
		drawInit;
		show;
		resized(size);
		assert(windowHandle);
	}


	override void show(){
		if(isActive)
			return;
		XMapWindow(wm.displayHandle, windowHandle);
		gcActivate;
		onShow;
		onKeyboardFocus(true);
	}
	
	override void onShow(){
		isActive = true;
		hidden = false;
	}
	
	override void hide(){
		if(!isActive)
			return;
		XUnmapWindow(wm.displayHandle, windowHandle);
		onHide;
		//wm.windows.remove(this);
	}
	
	override void onHide(){
		isActive = false;
		hidden = true;
	}

	void swapBuffers(){
		glXSwapBuffers(wm.displayHandle, cast(uint)windowHandle);
	}

	override void onDraw(){
		super.onDraw;
		draw.finishFrame;
	}

	void onDestroy(){
		draw.destroy;
	}

	@property
	bool active(){
		return isActive;
	}

	void onRawMouse(int x, int y){}


	override void setCursor(Mouse.cursor cursor){
		struct cursorCacheEntry {
			uint shape;
			int cached;
		}
		static cursorCacheEntry[] cursorCache = [
			{XC_arrow, 0},
			{XC_top_left_arrow, 0},
			{XC_xterm, 0},
			{XC_crosshair, 0},
			{XC_sb_v_double_arrow, 0},
			{XC_sb_h_double_arrow, 0},
			{XC_top_right_corner, 0},
			{XC_top_left_corner, 0},
			{XC_bottom_right_corner, 0},
			{XC_bottom_left_corner, 0},
			{XC_hand1, 0},
		];
		int c = 0;
		if((cast(int)cursor >= 0) && (cast(int)cursor < cursorCache.sizeof / cursorCache[0].sizeof)){
			cursorCacheEntry *entry = &cursorCache[cast(int)cursor];
			if(entry.cached == 0){
				entry.cached = cast(int)XCreateFontCursor(wm.displayHandle, entry.shape);
			}
			c = entry.cached;
		}else{
			switch(cursor){
				case Mouse.cursor.none:
					static Cursor cursorNone = 0;
					if(cursorNone == 0){
						char[32] cursorNoneBits;
						foreach(ref ch; cursorNoneBits)
							ch = 0;
						XColor dontCare;
						Pixmap cursorNonePixmap;
						//memset(cursorNoneBits, 0, cursorNoneBits.sizeof);
						//memset(&dontCare, 0, dontCare.sizeof);
						cursorNonePixmap = XCreateBitmapFromData(
								wm.displayHandle,
								XDefaultRootWindow(wm.displayHandle),
								cursorNoneBits.ptr, 16, 16
						);
						if(cursorNonePixmap != 0){
							cursorNone = XCreatePixmapCursor(
								wm.displayHandle, cursorNonePixmap,
								cursorNonePixmap, &dontCare,
								&dontCare, 0, 0
							);
							XFreePixmap(wm.displayHandle, cursorNonePixmap);
						}
					}
					c = cast(int)cursorNone;
					break;
				case Mouse.cursor.inherit:
					c = 0;
					break;
				default: break;
			}
		}
		if(cursor == Mouse.cursor.inherit)
			XUndefineCursor(wm.displayHandle, windowHandle);
		else
			XDefineCursor(wm.displayHandle, windowHandle, c);
	}


	void setCursorPos(int x, int y){
		jumpTargetX = x;
		jumpTargetY = y;
		XWarpPointer(
				wm.displayHandle, XDefaultRootWindow(wm.displayHandle),
				windowHandle, 0,0,0,0, x, size.y - y
		);
		XFlush(wm.displayHandle);
	}

	void setTitle(string t){
		title = t;
		if(!isActive)
			return;
		XTextProperty tp;
		char* c = cast(char*)title.toStringz;
		XStringListToTextProperty(&c, 1, &tp);
		XSetWMName(wm.displayHandle, windowHandle, &tp);
	}

	string getTitle(){
		Atom netWmName, utf8, actType;
		size_t nItems, bytes;
		int actFormat;
		ubyte* data;
		netWmName = XInternAtom(wm.displayHandle, "_NET_WM_NAME".toStringz, False);
		utf8 = XInternAtom(wm.displayHandle, "UTF8_STRING".toStringz, False);
		XGetWindowProperty(
				wm.displayHandle, windowHandle, netWmName, 0, 0x77777777, False, utf8,
				&actType, &actFormat, &nItems, &bytes, &data
		);
		auto text = to!string(cast(char*)data);
		XFree(data);
		return text;
	}
	
	GraphicsContext gcShare(){
		return glXCreateContext(wm.displayHandle, cast(derelictX.XVisualInfo*)wm.graphicsInfo, cast(__GLXcontextRec*)graphicsContext, True);
	}


	void makeCurrent(GraphicsContext c){
		glXMakeCurrent(wm.displayHandle, cast(uint)windowHandle, cast(__GLXcontextRec*)c);
	}

	
	void processEvent(Event* e){
		switch(e.type){
			case ConfigureNotify:
				if(size.x != e.xconfigure.width || size.y != e.xconfigure.height){
					resized([e.xconfigure.width, e.xconfigure.height]);
				}
				if(pos.x != e.xconfigure.x || pos.y != e.xconfigure.y){
					moved([e.xconfigure.x, e.xconfigure.y]);
				}
				break;
			case KeyPress:
				onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), true);
				char[25] str;
				KeySym ks;
				Status st;
				size_t l = Xutf8LookupString(inputContext, &e.xkey, str.ptr, 25, &ks, &st);
				foreach(dchar c; str[0..l])
					onKeyboard(c);
				break;
			case KeyRelease: onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), false); break;
			case MotionNotify:
				onMouseMove(e.xmotion.x, size.y - e.xmotion.y);
				if(distance(e.xmotion.x, jumpTargetX) > 1 || distance(e.xmotion.y, jumpTargetY) > 1)
				//if(e.xmotion.x != jumpTargetX || e.xmotion.y != jumpTargetY)
					onRawMouse((e.xmotion.x - oldX), (e.xmotion.y - oldY));
				else{
					jumpTargetX = int.max;
					jumpTargetY = int.max;
				}
				oldX = e.xmotion.x;
				oldY = e.xmotion.y;
				break;
			case ButtonPress: onMouseButton(e.xbutton.button, true, e.xbutton.x, size.h-e.xbutton.y); break;
			case ButtonRelease: onMouseButton(e.xbutton.button, false, e.xbutton.x, size.h-e.xbutton.y); break;
			case EnterNotify: onMouseFocus(true); mouseFocus=true; break;
			case LeaveNotify: onMouseFocus(false); mouseFocus=false; break;
			case MapNotify: onShow; break;
			case UnmapNotify: onHide; break;
			case DestroyNotify: onDestroy; break;
			case Expose: onDraw(); break;
			case ClientMessage:
				if(e.xclient.message_type == wmDelete){
					hide();
				}
				break;
			case KeymapNotify: XRefreshKeyboardMapping(&e.xmapping); break;
			default:break;
		}
	}

	@property
	override bool hasMouseFocus(){
		return mouseFocus;
	}

	override void resize(int[2] size){
		XResizeWindow(wm.displayHandle, windowHandle, size.w, size.h);
	}

	override void move(int[2] pos){
		XMoveWindow(wm.displayHandle, windowHandle, pos.x, pos.y);
	}

	void resized(int[2] size){
		this.size = size;
		if(draw)
			draw.resize(size);
	}

	void moved(int[2] pos){
		this.pos = pos;
	}

	void gcInit(){
		try {
			if(!wm.glCore)
				throw new Exception("disabled");
			int[] attribs = [
				GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
				GLX_CONTEXT_MINOR_VERSION_ARB, 3,
				0
			];
			graphicsContext = wm.glXCreateContextAttribsARB(
					wm.displayHandle, wm.mFBConfig[0], null, cast(int)True, attribs.ptr
			);
			if(!graphicsContext)
				throw new Exception("glXCreateContextAttribsARB failed");
		}catch(Exception e){
			/+wm.glCore = false;
			GLint att[] = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, 0];
			wm.graphicsInfo = glXChooseVisual(wm.displayHandle, 0, att.ptr);
			graphicsContext = glXCreateContext(wm.displayHandle, wm.graphicsInfo, null, True);+/
			
			graphicsContext = glXCreateContext(wm.displayHandle, cast(derelictX.XVisualInfo*)wm.graphicsInfo, null, True);
			if(!graphicsContext)
				throw new Exception("glXCreateContext failed");
		}
		gcActivate();
		DerelictGL3.reload();
	}
	
	
	void gcActivate(){
		if(!wm.activeWindow)
			wm.activeWindow = this;
		if(graphicsContext)
			makeCurrent(graphicsContext);
	}

	void drawInit(){
		//_draw = new GlDraw;
	}

	long[2] getScreenSize(){
		version(Windows){
			RECT size;
			GetWindowRect(windowHandle, &size);
			return [
				size.right - size.left,
				size.bottom - size.top
			];
		}else
			assert(false, "Not implemented");
	}
	
}


import std.math;

int distance(int a, int b){
	return abs(a-b);
}


