module ws.wm.x11.window;

version(Posix):

import
	std.conv,
	std.uni,
	std.string,
	ws.draw,
	ws.wm,
	ws.gui.base,
	ws.list,
	ws.x.atoms,
	ws.x.draw,
	derelict.opengl3.gl3,
	ws.wm.x11.api;

import derelictX = derelict.util.xtypes;

__gshared:


class X11Window: Base {

	Mouse.cursor cursor = Mouse.cursor.inherit;
	string title;
	bool isActive = true;
	WindowHandle windowHandle;
	GraphicsContext graphicsContext;
	List!WindowEvent eventQueue;

	XIC inputContext;
	int oldX, oldY;
	int jumpTargetX, jumpTargetY;
	DrawEmpty _draw;
	int[2] _cursorPos;

	bool _keyboardFocus;
	bool mouseFocus;
	Base _dragging;
	bool draggingUnfocus;

	this(WindowHandle handle){
		assert(handle);
		windowHandle = handle;
		wmDelete = XInternAtom(wm.displayHandle, "WM_DELETE_WINDOW".toStringz, True);
		utf8 = XInternAtom(wm.displayHandle, "UTF8_STRING", false);
		netWmName = XInternAtom(wm.displayHandle, "_NET_WM_NAME".toStringz, False);
	}

	XSetWindowAttributes windowAttributes;

	Atom wmDelete;
	Atom utf8;
	Atom netWmName;

	this(int w, int h, string t, bool override_redirect=false){
		hidden = true;
		title = t;
		size = [w, h];
		eventQueue = new List!WindowEvent;

		auto eventMask =
				ExposureMask |
				StructureNotifyMask |
				SubstructureRedirectMask |
				KeyPressMask |
				KeyReleaseMask |
				KeymapStateMask |
				PointerMotionMask |
				ButtonPressMask |
				ButtonReleaseMask |
				EnterWindowMask |
				LeaveWindowMask |
				FocusChangeMask;

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
		windowAttributes.border_pixmap = None;
		windowAttributes.border_pixel = 0;
		windowAttributes.bit_gravity = NorthWestGravity;
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
		utf8 = XInternAtom(wm.displayHandle, "UTF8_STRING", false);
		netWmName = XInternAtom(wm.displayHandle, "_NET_WM_NAME".toStringz, False);
		XSetWMProtocols(wm.displayHandle, windowHandle, &wmDelete, 1);
		drawInit;
		assert(windowHandle);
	}

	override DrawEmpty draw(){
		return _draw;
	}

	void draw(DrawEmpty draw){
		_draw = draw;
	}

	override int[2] cursorPos(){
		return _cursorPos;
	}

	override Base draggingChild(){
		return _dragging;
	}

	override void onMouseButton(Mouse.button button, bool pressed, int x, int y){
		if(button == Mouse.buttonLeft){
			if(pressed){
				auto child = mouseChild;
				while(child && child.mouseChild){
					child = child.mouseChild;
				}
				_dragging = child;
			}else{
				_dragging = null;
				if(draggingUnfocus){
					onMouseFocus(false);
				}
			}
		}
		super.onMouseButton(button, pressed, x, y);
	}

	override void show(){
		XMapWindow(wm.displayHandle, windowHandle);
	}

	override void onShow(){
		hidden = false;
		resized(size);
	}

	void close(){
		if(!isActive)
			return;
		hidden = true;
		isActive = false;
		wm.windows.remove(this);
		XDestroyWindow(wm.displayHandle, windowHandle);
	}

	override void hide(){
		XUnmapWindow(wm.displayHandle, windowHandle);
	}

	override void onHide(){
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
		isActive = false;
		draw.destroy;
	}

	@property
	bool active(){
		return isActive;
	}

	void onRawMouse(int x, int y){}


	override void setCursor(Mouse.cursor cursor){
		struct Cache {
			uint shape;
			ulong cached;
		}
		static Cache[] cache = [
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
		ulong c = 0;
		if(cursor >= 0 && cursor <= cache.length){
			if(!cache[cursor].cached)
				cache[cursor].cached = XCreateFontCursor(wm.displayHandle, cache[cursor].shape);
			c = cache[cursor].cached;
		}else{
			switch(cursor){
				case Mouse.cursor.none:
					__gshared Cursor cursorNone = 0;
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
		XSetTextProperty(wm.displayHandle, windowHandle, &tp, Atoms._NET_WM_NAME);
	}


	bool gettextprop(WindowHandle w, Atom atom, ref string text){
		char** list;
		int n;
		XTextProperty name;
		XGetTextProperty(wm.displayHandle, w, &name, atom);
		if(!name.nitems)
			return false;
		if(name.encoding == Atoms.STRING){
			text = to!string(*name.value);
		}else{
			if(XmbTextPropertyToTextList(wm.displayHandle, &name, &list, &n) >= XErrorCode.Success && n > 0 && *list){
				text = (*list).to!string;
				XFreeStringList(list);
			}
		}
		XFree(name.value);
		return true;
	}

	string getTitle(){
		Atom actType;
		size_t nItems, bytes;
		int actFormat;
		ubyte* data;
		XGetWindowProperty(
				wm.displayHandle, windowHandle, Atoms._NET_WM_NAME, 0, 0x77777777, False, Atoms.UTF8_STRING,
				&actType, &actFormat, &nItems, &bytes, &data
		);
		auto text = to!string(cast(char*)data);
		XFree(data);
		if(!text.length){
			if(!gettextprop(windowHandle, Atoms._NET_WM_NAME, text))
				gettextprop(windowHandle, Atoms.WM_NAME, text);
		}
		return text;
	}

	GraphicsContext gcShare(){
		return glXCreateContext(wm.displayHandle, cast(derelictX.XVisualInfo*)wm.graphicsInfo, cast(__GLXcontextRec*)graphicsContext, True);
	}


	void makeCurrent(GraphicsContext c){
		glXMakeCurrent(wm.displayHandle, cast(uint)windowHandle, cast(__GLXcontextRec*)c);
	}

	void onPaste(string){}

	void processEvent(WindowEvent* e){
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
				if(!isActive)
					break;
				char[25] str;
				KeySym ks;
				Status st;
				size_t l = Xutf8LookupString(inputContext, &e.xkey, str.ptr, 25, &ks, &st);
				foreach(dchar c; str[0..l])
					if(!c.isControl)
						onKeyboard(c);
				break;
			case KeyRelease: onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), false); break;
			case MotionNotify:
				_cursorPos = [e.xmotion.x, size.y - e.xmotion.y];
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
			case ButtonPress: onMouseButton(e.xbutton.button, true, cursorPos.x, cursorPos.y); break;
			case ButtonRelease: onMouseButton(e.xbutton.button, false, cursorPos.x, cursorPos.y); break;
			case EnterNotify:
				onMouseFocus(true);
				mouseFocus=true;
				draggingUnfocus = false;
				break;
			case LeaveNotify:
				if(!draggingChild){
					onMouseFocus(false);
					mouseFocus=false;
				}else{
					draggingUnfocus = true;
				}
				break;
			case FocusIn: onKeyboardFocus(true); _keyboardFocus=true; break;
			case FocusOut: onKeyboardFocus(false); _keyboardFocus=false; break;
			case MapNotify: onShow; break;
			case UnmapNotify: onHide; break;
			case DestroyNotify: onDestroy; break;
			case Expose: onDraw(); break;
			case ClientMessage:
				if(e.xclient.message_type == wmDelete){
					close();
				}
				break;
			case KeymapNotify: XRefreshKeyboardMapping(&e.xmapping); break;
			case SelectionNotify:
				if(e.xselection.property == utf8){
					char* p;
					int actualFormat;
					size_t count;
					Atom actualType;
					XGetWindowProperty(
						wm.displayHandle, windowHandle, utf8, 0, 1024, false, utf8,
						&actualType, &actualFormat, &count, &count, cast(ubyte**)&p
					);
					onPaste(p.to!string);
					XFree(p);
				}
				break;
			default:break;
		}
	}

	@property
	override bool hasMouseFocus(){
		return mouseFocus;
	}

	override bool hasFocus(){
		return _keyboardFocus;
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

	void drawInit(){
		draw = new XDraw(this);
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
