module ws.gui.osWindow;

import std.range, std.string, std.algorithm, std.utf, std.ascii: toLower;
import derelict.opengl3.gl3;

import
	ws.io,
	std.conv,
	ws.list,
	ws.string,
	ws.gl.gl,
	ws.gui.base,
	ws.gui.input,
	ws.gui.point;


version(Windows){
	import core.sys.windows.windows;
	import derelict.opengl3.wgl;
	pragma(lib, "gdi32.lib");
	pragma(lib, "DerelictGL3.lib");
	pragma(lib, "DerelictUtil.lib");
}
version(Posix){
	import X11.Xlib;
	pragma(lib, "DerelictGL3");
	pragma(lib, "DerelictUtil");
	pragma(lib, "dl");
}


__gshared:


WindowManager wm;

static this(){
	if(!wm)
		wm = new WindowManager;
}

class osWindow: Base {

	this(WindowHandle handle){
		windowHandle = handle;
	}

	this(int w, int h, string t){
		title = t;
		size = [w, h];
		version(Windows){
			eventQueue = new List!event;
			RECT targetSize = {0, 0, size.x, size.y};
			AdjustWindowRect(&targetSize, WS_OVERLAPPEDWINDOW | WS_VISIBLE, false);
			WNDCLASSW wc;
			wc.lpfnWndProc = cast(WNDPROC)&WindowManager.internalEvents;
			wc.hInstance = wm.appInstance;
			wc.hIcon = LoadIconA(null,IDI_APPLICATION);
			wc.hCursor = LoadCursorA(null, IDC_ARROW);
			wc.hbrBackground = cast(HBRUSH)GetStockObject(BLACK_BRUSH);
			wc.lpszClassName = "wm::windowClass".toUTF16z();
			wc.style = CS_OWNDC;
			RegisterClassW(&wc);
			windowHandle = CreateWindowExW(
				0, wc.lpszClassName, title.toUTF16z(),
				WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT,
				targetSize.right-targetSize.left, targetSize.bottom-targetSize.top, null, null, wm.appInstance, null
			);
			if(!windowHandle) throw new Exception("CreateWindowW failed");
			RECT r;
			GetWindowRect(windowHandle, &r);
			pos = [r.left, r.right];
		}version(Posix){
			eventQueue = new List!XEvent;
			windowHandle = XCreateWindow(
				wm.displayHandle,
				XDefaultRootWindow(wm.displayHandle),
				0, 0, size.x, size.y, 0,
				wm.graphicsInfo.depth,
				InputOutput,
				wm.graphicsInfo.visual,
				wm.windowMask,
				&wm.windowAttributes
			);
			inputContext = XCreateIC(
        		XOpenIM(wm.displayHandle, null, null, null),
				XNClientWindow, windowHandle,
				XNFocusWindow, windowHandle,
				XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
				null
			);
			XSelectInput(wm.displayHandle, windowHandle, wm.eventMask);
			Atom wmDelete = XInternAtom(wm.displayHandle, cast(char*)"WM_DELETE_WINDOW".toStringz, True);
			XSetWMProtocols(wm.displayHandle, windowHandle, &wmDelete, 1);
		}
		shouldCreateGraphicsContext();
		show();
	}

	
	override void show(){
		if(isActive) return;
		version(Windows){
			ShowWindow(windowHandle, SW_SHOWNORMAL);
			UpdateWindow(windowHandle);
		}version(Posix){
			XMapWindow(wm.displayHandle, windowHandle);
		}
		activateGraphicsContext();
		//onResize(size.x, size.y);
		isActive = true;
		wm.windows ~= this;
	}
	
	
	override void hide(){
		if(!isActive) return;
		version(Windows)
			DestroyWindow(windowHandle);
		version(Posix)
			XUnmapWindow(wm.displayHandle, windowHandle);
		isActive = false;
		wm.windows.remove(this);
	}


	void close(){
		hide();
	}
	
	
	void swapBuffers(){
		if(!wm.activeWindow) return;
		version(Windows){
			SwapBuffers(deviceContext);
		}version(Posix){
			glXSwapBuffers(wm.displayHandle, cast(uint)windowHandle);
		}
	}
	

	override void setCursor(Mouse.cursor cursor){
		version(Windows){
			HCURSOR hcur = null;
			if(cursor != Mouse.cursor.none)
				hcur = LoadCursorW(null, cast(const(wchar)*)wm.MOUSE_CURSOR_TO_HCUR[cast(int)cursor]);
			this.cursor = cursor;
			SetCursor(hcur);
			SetClassLongW(windowHandle, -12, cast(LONG)cast(LONG_PTR)hcur);
		}
		version(Posix){
			struct cursorCacheEntry {
				uint shape;
				int cached;
			}
			static cursorCacheEntry cursorCache[] = [
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
							char cursorNoneBits[32];
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
	}


	void setCursorPos(int x, int y){
		version(Windows){
				POINT p = {cast(long)x, cast(long)y};
				ClientToScreen(windowHandle, &p);
				SetCursorPos(p.x, p.y);
		}version(Posix){
				XWarpPointer(
						wm.displayHandle, XDefaultRootWindow(wm.displayHandle),
						windowHandle, 0,0,0,0, x, size.y - y
				);
				XFlush(wm.displayHandle);
		}
	}


	string getTitle(){
		version(Windows){
			wchar[512] str;
			int r = GetWindowTextW(windowHandle, str.ptr, str.length);
			return to!string(str[0..r]);
		}
		version(Posix){
			Atom netWmName, utf8, actType;
			ulong nItems, bytes;
			int actFormat;
			byte* data;
			netWmName = XInternAtom(wm.displayHandle, "_NET_WM_NAME", False);
			utf8 = XInternAtom(wm.displayHandle, "UTF8_STRING", False);
			
			XGetWindowProperty(
					wm.displayHandle, windowHandle, netWmName, 0, 0x77777777, False, utf8,
					&actType, &actFormat, &nItems, &bytes, &data
			);
			return to!string(data);
		}
	}
	
	
	long getPid(){
		version(Windows){
			DWORD pid;
			DWORD threadId = GetWindowThreadProcessId(windowHandle, &pid);
			return pid;
		}
		else
			assert(false, "Not implemented");
	}
	

	void setTitle(string t){
		title = t;
		if(!isActive) return;
		version(Windows)
			SetWindowTextW(windowHandle, title.toUTF16z());
		version(Posix){
			XTextProperty tp;
			char* c = cast(char*)title.toStringz;
			XStringListToTextProperty(&c, 1, &tp);
			XSetWMName(wm.displayHandle, windowHandle, &tp);
		}
	}


	void setFront(){
		version(Windows)
			SwitchToThisWindow(windowHandle, 0);
		else
			assert(false, "Not implemented");
	}


	Context shareContext(){
		version(Windows)
			return wm.wglCreateContextAttribsARB(deviceContext, graphicsContext, null);
		version(Posix)
			return glXCreateContext(wm.displayHandle, wm.graphicsInfo, graphicsContext, True);
	}


	void makeCurrent(Context c){
		version(Windows){
			if(!wglMakeCurrent(deviceContext, c))
				throw new Exception("Failed to activate context, " ~ getLastError());
		}version(Posix){
			glXMakeCurrent(wm.displayHandle, windowHandle, c);
		}
	}


	void createGraphicsContext(){
		version(Windows){
			deviceContext = GetDC(windowHandle);
			if(!deviceContext)
				throw new Exception("window.Show failed: GetDC");
			uint formatCount = 0;
			int pixelFormat;
			int iAttribList[] = [
				0x2001, true,
				0x2010, true,
				0x2011, true,
				0x2003, 0x2027,
				0x2014, 0x202B,
				0x2014, 24,
				0x201B, 8,
				0x2022, 16,
				0x2023, 8,
				0x2011, true,
				0x2041, antiAliasing > 1 ? true : false,
				0x2042, antiAliasing,
				0
			];
			wm.wglChoosePixelFormatARB(deviceContext, iAttribList.ptr, null, 1, &pixelFormat, &formatCount);
			if(!formatCount)
				throw new Exception(tostring("wglChoosePixelFormatARB failed: ", glGetError()));
			SetPixelFormat(deviceContext, pixelFormat, null);
			int attribs[] = [
				0x2091, 3,
				0x2092, 2,
				0x9126, 0x00000001,
				0
			];
			graphicsContext = wm.wglCreateContextAttribsARB(deviceContext, null, attribs.ptr);
			if(!graphicsContext)
				throw new Exception(tostring("wglCreateContextAttribsARB() failed: ", glGetError()));
		}version(Posix){
			if(!wm.glCore)
				throw new Exception("disabled");
			int attribs[] = [
				GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
				GLX_CONTEXT_MINOR_VERSION_ARB, 3,
				0
			];
			graphicsContext = wm.glXCreateContextAttribsARB(
					wm.displayHandle, wm.mFBConfig[0], null, cast(int)True, attribs.ptr
			);
			if(!graphicsContext)
				throw new Exception("glXCreateContextAttribsARB failed");
		}
	}
	
	
	void createGraphicsContextOld(){
		version(Windows){
			PIXELFORMATDESCRIPTOR pfd = {
				(PIXELFORMATDESCRIPTOR).sizeof, 1, 4 | 32 | 1, 0, 8, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0
			};
			int pixelFormat = ChoosePixelFormat(deviceContext, &pfd);
			SetPixelFormat(deviceContext, pixelFormat, &pfd);
			graphicsContext = wglCreateContext(deviceContext);
			wglMakeCurrent(deviceContext, graphicsContext);
		}version(Posix){
			/+wm.glCore = false;
			GLint att[] = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, 0];
			wm.graphicsInfo = glXChooseVisual(wm.displayHandle, 0, att.ptr);
			graphicsContext = glXCreateContext(wm.displayHandle, wm.graphicsInfo, null, True);+/
			
			graphicsContext = glXCreateContext(wm.displayHandle, wm.graphicsInfo, null, True);
			if(!graphicsContext)
				throw new Exception("glXCreateContext failed");
		}
	}
	
	
	void shouldCreateGraphicsContext(){
		try {
			createGraphicsContext();
		}catch(Exception e){
			//io.writeln("Creating deprecated graphics context");
			createGraphicsContextOld();
		}
		activateGraphicsContext();
		DerelictGL3.reload();
	}
	
	
	void activateGraphicsContext(){
		if(!wm.activeWindow)
			wm.activeWindow = this;
		makeCurrent(graphicsContext);
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
	
	version(Windows)
	void sendMessage(uint message, WPARAM wpar, LPARAM lpar){
		SendMessageA(windowHandle, message, wpar, lpar);
		/+
		DWORD errcode = GetLastError();
		LPCSTR msgBuf;
		DWORD i = FormatMessageA(
			cast(uint)(
			FORMAT_MESSAGE_ALLOCATE_BUFFER |
			FORMAT_MESSAGE_FROM_SYSTEM |
			FORMAT_MESSAGE_IGNORE_INSERTS),
			null,
			errcode,
			cast(uint)MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
			cast(LPSTR)&msgBuf,
			0,
			null);
		string text = to!string(msgBuf);
		LocalFree(cast(HLOCAL)msgBuf);
		writeln(text);
		+/
	}

	version(Windows){

		string getLastError(){
			DWORD errcode = GetLastError();
			if(!errcode)
				return "No error";
			LPCSTR msgBuf;
			DWORD i = FormatMessageA(
				cast(uint)(
				FORMAT_MESSAGE_ALLOCATE_BUFFER |
				FORMAT_MESSAGE_FROM_SYSTEM |
				FORMAT_MESSAGE_IGNORE_INSERTS),
				null,
				errcode,
				cast(uint)MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
				cast(LPSTR)&msgBuf,
				0,
				null
			);
			string text = to!string(msgBuf);
			LocalFree(cast(HLOCAL)msgBuf);
			return text;
		}

	}

	WindowHandle osHandle(){
		return windowHandle;
	}

	protected:
	
		int antiAliasing = 1; 
	
		version(Windows){
			alias WindowHandle = HWND;
			alias HGLRC Context;
			struct event {
				UINT msg;
				WPARAM wpar;
				LPARAM lpar;
			}
			List!event eventQueue;
			HDC deviceContext;
		}version(Posix){
			alias WindowHandle = Window;
			List!XEvent eventQueue;
			XIC inputContext;
			alias GLXContext Context;
		}
		
		WindowHandle windowHandle;
		Context graphicsContext;
	
		Point pos, size;
		bool isActive = false;
		bool shouldRedraw = false;
		string title;
		Mouse.cursor cursor = Mouse.cursor.inherit;
		
		
}


class WindowNotFound: Exception {
	@safe pure nothrow
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null){
    	super(msg, file, line, next);
	}
}


class WindowManager {
	
	
	bool hasActiveWindows(){
		return (windows.length() > 0);
	}
	

	osWindow[] getAllWindows(){
		version(Windows){
			osWindow[] list;
			HWND h = GetTopWindow(null);
			while(h){
				list ~= new osWindow(h);
				h = GetWindow(h, 2);
			}
			return list;
		}else
			assert(false, "Not implemented");
	}

	
	void processEvents(bool noblock = true){
		version(Windows){
			if(noblock){
				MSG msg;
				while(PeekMessageA(&msg, null, 0, 0, PM_REMOVE)){
					TranslateMessage(&msg);
					DispatchMessageA(&msg);
				}
			}else{
				MSG msg;
			    if(GetMessageA(&msg, null, 0, 0)){
			        TranslateMessage(&msg);
			        DispatchMessageA(&msg);
			    }
		    }
		    wm.internalEventsProcess();
		}version(Posix){
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

	void setTop(osWindow win){
		version(Windows)
			SetForegroundWindow(win.windowHandle);
		else
			assert(false, "Not implemented");
	}

	long[2] getCursorPos(){
		version(Windows){
			POINT point;
			GetCursorPos(&point);
			return [point.x, point.y];
		}
		else
			assert(false, "Not implemented");
	}

	osWindow findWindow(string title){
		version(Windows){
			HWND window = FindWindowW(null, title.toUTF16z());
			if(!window)
				throw new WindowNotFound("Could not find window \"" ~ title ~ "\"");
			return new osWindow(window);
		}
		else
			assert(false, "Not implemented");
	}


	
	bool isKeyDown(Keyboard.key key){
		version(Windows)
			return GetKeyState(cast(int)key) < 0;
		else
			assert(false, "Not implemented");
	}


	osWindow activeWindow;
	
	private:

		bool blockChar;
		
		List!osWindow windows;
			
		version(Windows){
			HINSTANCE appInstance;
			WNDCLASSA windowClass = {0};
			T_wglChoosePixelFormatARB wglChoosePixelFormatARB;
			T_wglCreateContextAttribsARB wglCreateContextAttribsARB;
		}version(Posix){
			Display* displayHandle;
			XVisualInfo* graphicsInfo;
			XSetWindowAttributes windowAttributes;
			long windowMask;
			long eventMask;
			bool glCore;
			GLXFBConfig* mFBConfig;
			T_glXCreateContextAttribsARB glXCreateContextAttribsARB;
		}


		void load(string s)(){
			version(Windows) auto ptr = wglGetProcAddress(s.toStringz());
			version(Posix) auto ptr = glXGetProcAddress(s.toStringz());
			if(!ptr)
				throw new Exception("failed to get function \"" ~ s ~ "\"");
			mixin(s ~ " = cast(typeof(" ~ s ~ "))ptr;");
		}


		version(Windows){
			static HCURSOR getCursor(int i){
				return cast(LPWSTR)(cast(DWORD)(cast(WORD)i));
			}
			HCURSOR MOUSE_CURSOR_TO_HCUR[] = [
				getCursor(32512), // IDC_ARROW
				getCursor(32516), // IDC_UPARROW
		
				getCursor(32513), // IDC_BEAM
		
				getCursor(32646), // IDC_SIZEALL
				getCursor(32645), // IDC_SIZENS
				getCursor(32644), // IDC_SIZEWE
				getCursor(32642), // IDC_SIZENWSE
				getCursor(32643), // IDC_SIZENESW
				getCursor(32643), // IDC_SIZENESW
				getCursor(32642), // IDC_SIZENWSE
		
				getCursor(32649), // IDC_HAND
		
				getCursor(32512), // IDC_ARROW
				null,
			];
			
			extern(Windows)
			static LRESULT internalEvents(HWND window, UINT msg, WPARAM wpar, LPARAM lpar){
				foreach(w; wm.windows)
					if(w.windowHandle == window){
						w.eventQueue ~= osWindow.event(msg, wpar, lpar);
						if(msg == WM_CLOSE) return 0;
						break;
					}
				return DefWindowProcW(window, msg, wpar, lpar);
			}
		}
		
		
		void internalEventsProcess(){
			foreach(w; windows){
				foreach(e; w.eventQueue){
					w.eventQueue.popFront();
					version(Windows){
						if(w.isActive){
							wm.activeWindow = w;
							switch(e.msg){
								/+ Gamepads & Joysticks
								case WM_CREATE: {
									RAWINPUTDEVICE rid;
									rid.usUsagePage = 1;
									rid.usUsage     = 4; // Joystick
									rid.dwFlags     = 0;
									rid.hwndTarget  = hWnd;
									if(!RegisterRawInputDevices(&rid, 1, sizeof(RAWINPUTDEVICE)))
										return -1;
									break;
								}
								case WM_INPUT: {
									PRAWINPUT pRawInput;
									UINT      bufferSize;
									HANDLE    hHeap;
									GetRawInputData((HRAWINPUT)lParam, RID_INPUT, NULL, 
									&bufferSize, sizeof(RAWINPUTHEADER));
									hHeap     = GetProcessHeap();
									pRawInput = (PRAWINPUT)HeapAlloc(hHeap, 0, bufferSize);
									if(!pRawInput)
										return 0;
									GetRawInputData((HRAWINPUT)lParam, RID_INPUT, 
									pRawInput, &bufferSize, sizeof(RAWINPUTHEADER));
									ParseRawInput(pRawInput);
									HeapFree(hHeap, 0, pRawInput);
								}
								+/
								case WM_PAINT:
									w.shouldRedraw = false;
									w.onDraw();
									break;
								case WM_SHOWWINDOW:
									w.onShow(); break;
								case WM_CLOSE:
									w.close(); break;
								case WM_SIZE:
									w.onResize(LOWORD(e.lpar),HIWORD(e.lpar));
									w.size = [LOWORD(e.lpar),HIWORD(e.lpar)];
									break;
								case WM_KEYDOWN:
									Keyboard.key c = cast(Keyboard.key)toLower(cast(char)e.wpar);
									Keyboard.set(c, true);
									w.onKeyboard(c, true);
									break;
								case WM_KEYUP:
									auto c = cast(Keyboard.key)toLower(cast(char)e.wpar);
									Keyboard.set(c, false);
									w.onKeyboard(c, false);
									break;
								case WM_CHAR:
									if(!blockChar)
										w.onKeyboard(cast(dchar)e.wpar);
									blockChar = false;
									break;
								case WM_ACTIVATE:
									w.onKeyboardFocus(LOWORD(e.wpar) > 0 ? true : false); break;
								case WM_SETCURSOR:
									SetCursor(MOUSE_CURSOR_TO_HCUR[cast(int)w.cursor]);
									break;
								case WM_MOUSEMOVE:
									if(!(w.parent && w.parent.mouseChild != w)){
										TRACKMOUSEEVENT tme = {
											TRACKMOUSEEVENT.sizeof, 2, w.windowHandle, 0xFFFFFFFF
										};
										TrackMouseEvent(&tme);
										w.onMouseFocus(true);
									}
									w.onMouseMove(GET_X_LPARAM(e.lpar), w.size.y-GET_Y_LPARAM(e.lpar));
									break;
								case WM_MOUSELEAVE: w.onMouseFocus(false); break;
								case WM_LBUTTONDOWN: w.onMouseButton(Mouse.buttonLeft, true, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_LBUTTONUP: w.onMouseButton(Mouse.buttonLeft, false, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_MBUTTONDOWN: w.onMouseButton(Mouse.buttonMiddle, true, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_MBUTTONUP: w.onMouseButton(Mouse.buttonMiddle, false, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_RBUTTONDOWN: w.onMouseButton(Mouse.buttonRight, true, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_RBUTTONUP: w.onMouseButton(Mouse.buttonRight, false, LOWORD(e.lpar), HIWORD(e.lpar)); break;
								case WM_MOUSEWHEEL:
									w.onMouseButton(
											GET_WHEEL_DELTA_WPARAM(e.wpar) > 120 ? Mouse.wheelDown : Mouse.wheelUp,
											true, LOWORD(e.lpar), HIWORD(e.lpar)
									); break;
								default: break;
							}
						}
					}
					version(Posix){
						activeWindow = w;
						w.activateGraphicsContext();
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
								if(!w.onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), true)){
									char str[25];
									size_t l = Xutf8LookupString(w.inputContext, &e.xkey, str.ptr, 25, null, null);
									if(l){
										string s;
										for(size_t i=0; i<l; ++i)
											s ~= str[i];
										foreach(dchar c; s)
											w.onKeyboard(c);
									}
								}
								break;
							case KeyRelease: w.onKeyboard(cast(Keyboard.key)XLookupKeysym(&e.xkey,0), false); break;
							case MotionNotify: w.onMouseMove(e.xmotion.x, w.size.y - e.xmotion.y); break;
							case ButtonPress: w.onMouseButton(e.xbutton.button, true, e.xbutton.x, e.xbutton.y); break;
							case ButtonRelease: w.onMouseButton(e.xbutton.button, false, e.xbutton.x, e.xbutton.y); break;
							case EnterNotify: w.onMouseFocus(true); break;
							case LeaveNotify: w.onMouseFocus(false); break;
							case Expose: w.shouldRedraw = false; w.onDraw(); break;
							case ClientMessage: w.close(); break;
							case KeymapNotify: XRefreshKeyboardMapping(&e.xmapping); break;
							default:break;
						}
						break;
					}
					
				}
			}
		}


		this(){
			DerelictGL3.load();
			windows = new List!osWindow;
			version(Windows){
				appInstance = GetModuleHandleW(null);
				
				// the following is solely to retrieve wglChoosePixelFormat && wglCreateContext
				HWND dummyWindow = CreateWindowExA(
						0, "STATIC", "", WS_POPUP | WS_DISABLED,
						0, 0, 1, 1, null, null, appInstance, null
				);
				PIXELFORMATDESCRIPTOR dummyFormatDescriptor = {
					(PIXELFORMATDESCRIPTOR).sizeof, 1, 4 | 32 | 1, 0, 8, 0,
					0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0
				};
				HDC dummyDeviceContext = GetDC(dummyWindow);
				int pixelFormat = ChoosePixelFormat(dummyDeviceContext, &dummyFormatDescriptor);
				SetPixelFormat(dummyDeviceContext, pixelFormat, &dummyFormatDescriptor);
				HGLRC dummyContext = wglCreateContext(dummyDeviceContext);
				wglMakeCurrent(dummyDeviceContext, dummyContext);
				try {
					load!"wglChoosePixelFormatARB"();
					load!"wglCreateContextAttribsARB"();
				} catch (Exception e)
					throw new Exception("OpenGL 3.3 not supported");
				wglMakeCurrent(null, null);
				wglDeleteContext(dummyContext);
				ReleaseDC(dummyWindow, dummyDeviceContext);
				DestroyWindow(dummyWindow);
			}version(Posix){
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
		}
		
		
		~this(){
			version(Posix) XCloseDisplay(displayHandle);
		}
		
		
}

private:

	version(Posix) extern(C){
		alias GLXContext function(derelict.util.xtypes.Display*, GLXFBConfig, GLXContext, derelict.util.xtypes.Bool, const int*) T_glXCreateContextAttribsARB;
	}

	version(Windows) extern(Windows){

		HWND GetTopWindow(void*);
		HWND GetWindow(void*, uint);
		
		int GetWindowTextW(HWND, LPWSTR, int);
		
		DWORD GetWindowThreadProcessId(HWND, DWORD*);
		void SwitchToThisWindow(HWND, BOOL);

		alias nothrow BOOL function(HDC, const(int)*, const(FLOAT)*, UINT, int*, UINT*) T_wglChoosePixelFormatARB;
		alias nothrow HGLRC function(HDC, HGLRC, const(int)*) T_wglCreateContextAttribsARB;
		
		nothrow BOOL SetWindowTextW(HWND,LPCWSTR);  
		nothrow HANDLE CreateWindowExW(DWORD,LPCWSTR,LPCWSTR,DWORD,int,int,int,int,HWND,HMENU,HINSTANCE,LPVOID);
		nothrow LRESULT DefWindowProcW(HWND,UINT,WPARAM,LPARAM);
		DWORD SetClassLongW(HWND,int,LONG);

		int ChoosePixelFormat(HDC, const PIXELFORMATDESCRIPTOR*);
		int DestroyWindow(void*);
		uint glewInit();

		BOOL SwapBuffers(HDC);

		ATOM RegisterClassW(const(WNDCLASSW)*);
		struct WNDCLASSW {
			uint style;
			WNDPROC lpfnWndProc;
			int cbClsExtra;
			int cbWndExtra;
			HINSTANCE hInstance;
			HICON hIcon;
			HCURSOR hCursor;
			HBRUSH hbrBackground;
			LPCWSTR lpszMenuName;
			LPCWSTR lpszClassName;
		}
		
		BOOL SendNotifyMessageA(HWND,UINT,WPARAM,LPARAM);
		
		struct TRACKMOUSEEVENT {
			DWORD cbSize;
			DWORD dwFlags;
			HWND  hwndTrack;
			DWORD dwHoverTime;
		};
		
		BOOL TrackMouseEvent(TRACKMOUSEEVENT*);
		const int WM_MOUSELEAVE = 0x2A3;
		const int WM_MOUSEWHEEL = 522;
		
		int GET_WHEEL_DELTA_WPARAM(WPARAM w){
			return (cast(WORD)(((cast(DWORD)w)>>16)&0xFFFF));
		}
		int GET_X_LPARAM(LPARAM l){
			return (cast(int)cast(short)(cast(WORD)(cast(DWORD)l)));
		}
		int GET_Y_LPARAM(LPARAM l){
			return (cast(int)(cast(WORD)((cast(DWORD)l>>16)&0xFFFF)));
		}
	
   		short GetKeyState(int nVirtKey);


		HWND FindWindowW(LPCWSTR lpClassName, LPCWSTR lpWindowName);

		BOOL PostMessageA(
			HWND hWnd,
			UINT Msg,
			WPARAM wParam,
			LPARAM lParam
		);


	}
