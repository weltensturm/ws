module ws.wm.win32.wm;

version(Windows):

import
	std.utf,
	std.string,
	std.conv,
	
	ws.list,
	ws.log,
	ws.gui.input,
	ws.gui.point,
	ws.wm.win32.api,
	ws.wm.win32.window,
	ws.wm.baseWindowManager,
	ws.wm;

__gshared:


class Win32WindowManager: BaseWindowManager {

	T_wglChoosePixelFormatARB wglChoosePixelFormatARB;
	T_wglCreateContextAttribsARB wglCreateContextAttribsARB;

	HINSTANCE appInstance;
	WNDCLASSW windowClass = {0};

	void load(string s)(){
		auto ptr = core.sys.windows.wingdi.wglGetProcAddress(s);
		if(!ptr)
			throw new Exception("failed to get function \"" ~ s ~ "\"");
		mixin(s ~ " = cast(typeof(" ~ s ~ "))ptr;");
	}

	this(){
		super();
		DerelictGL3.load();
		appInstance = GetModuleHandleW(null);
		
		windowClass.lpfnWndProc = cast(WNDPROC)&internalEvents;
		windowClass.hInstance = appInstance;
		windowClass.hIcon = LoadIconW(null, IDI_APPLICATION);
		windowClass.hCursor = LoadCursorW(null, IDC_ARROW);
		windowClass.hbrBackground = cast(HBRUSH)GetStockObject(BLACK_BRUSH);
		windowClass.lpszClassName = "wm::windowClass".toUTF16z();
		windowClass.style = CS_OWNDC;
		RegisterClassW(&windowClass);
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
	}

	HINSTANCE getInstance(){
		return appInstance;
	}

	Window[] systemWindows(){
		Window[] list;
		HWND h = GetTopWindow(null);
		while(h){
			list ~= new Win32Window(h);
			h = GetWindow(h, 2);
		}
		return list;
	}

	void processEvents(){
		MSG msg;
		while(PeekMessageA(&msg, null, 0, 0, PM_REMOVE)){
			TranslateMessage(&msg);
			DispatchMessageA(&msg);
		}
		foreach(e; eventQueue){
			e();
		}
		eventQueue = [];
	}

	long[2] getCursorPos(){
		POINT point;
		GetCursorPos(&point);
		return [point.x, point.y];
	}

	Win32Window findWindow(string title){
		HWND window = FindWindowW(null, title.toUTF16z());
		if(!window)
			throw new WindowNotFound("Could not find window \"" ~ title ~ "\"");
		return new Win32Window(window);
	}

	bool isKeyDown(Keyboard.key key){
		return GetKeyState(cast(int)key) < 0;
	}

}


protected:

	static HCURSOR getCursor(int i){
		return cast(LPWSTR)(cast(DWORD)(cast(WORD)i));
	}

	HCURSOR[] MOUSE_CURSOR_TO_HCUR = [
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

	void delegate()[] eventQueue;

	void delegate() translateEvent(Win32Window window, UINT msg, WPARAM wpar, LPARAM lpar){
		switch(msg){
			case WM_INPUT:
				import ws.log;
				byte[] bytes;
				UINT bufferSize = RAWINPUT.sizeof;

				GetRawInputData(cast(HRAWINPUT)lpar, RID_INPUT, NULL, &bufferSize, RAWINPUTHEADER.sizeof);
				bytes.length = bufferSize;

				if(GetRawInputData(cast(HRAWINPUT)lpar, RID_INPUT, bytes.ptr, &bufferSize, RAWINPUTHEADER.sizeof) == cast(UINT)-1)
					return {};
				auto input = (cast(RAWINPUT[])bytes)[0];
				//import ws.io; writeln(cast(byte[RAWINPUT.sizeof])input);
				if(input.header.dwType == RIM_TYPEMOUSE){
					if(input.mouse.usFlags & MOUSE_MOVE_ABSOLUTE){
						Log.info("absolute");
					}else{
						if(input.mouse.lLastX || input.mouse.lLastY)
							return { window.onRawMouse(input.mouse.lLastX, input.mouse.lLastY); };
					}
				}
				break;
			//case WM_PAINT:
			case WM_SHOWWINDOW:
					return { window.onShow; };
			case WM_CLOSE:
					return { window.hide; };
			case WM_SIZE:
				return {
					window.resized([LOWORD(lpar),HIWORD(lpar)]);
				};
			case WM_KEYDOWN:
				return {
					Keyboard.key c = cast(Keyboard.key)toLower(cast(char)wpar);
					Keyboard.set(c, true);
					window.onKeyboard(c, true);
				};
			case WM_KEYUP:
				return {
					auto c = cast(Keyboard.key)toLower(cast(char)wpar);
					Keyboard.set(c, false);
					window.onKeyboard(c, false);
				};
			case WM_CHAR:
				return {
					window.onKeyboard(cast(dchar)wpar);
				};
			case WM_ACTIVATE:
				return {
					window.onKeyboardFocus(LOWORD(wpar) > 0 ? true : false);
				};
			case WM_SETCURSOR:
				return {
					SetCursor(MOUSE_CURSOR_TO_HCUR[cast(int)window.cursor]);
				};
			case WM_MOUSEMOVE:
				int x = GET_X_LPARAM(lpar);
				int y = GET_Y_LPARAM(lpar);
				if(!window.hasMouse){
					TRACKMOUSEEVENT tme = {
						TRACKMOUSEEVENT.sizeof, 2, window.windowHandle, 0xFFFFFFFF
					};
					TrackMouseEvent(&tme);
					window.onMouseFocus(true);
					window.hasMouse = true;
				}
				return {
					window.onMouseMove(x, window.size.y-y);
				};
			case WM_MOUSELEAVE:
				return {
					window.hasMouse = false;
					window.onMouseFocus(false);
				};
			case WM_LBUTTONDOWN:
				return {
					window.onMouseButton(Mouse.buttonLeft, true, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_LBUTTONUP:
				return {
					window.onMouseButton(Mouse.buttonLeft, false, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_MBUTTONDOWN:
				return {
					window.onMouseButton(Mouse.buttonMiddle, true, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_MBUTTONUP:
				return {
					window.onMouseButton(Mouse.buttonMiddle, false, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_RBUTTONDOWN:
				return {
					window.onMouseButton(Mouse.buttonRight, true, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_RBUTTONUP:
				return {
					window.onMouseButton(Mouse.buttonRight, false, LOWORD(lpar), window.size.y-HIWORD(lpar));
				};
			case WM_MOUSEWHEEL:
				return {
					window.onMouseButton(
						GET_WHEEL_DELTA_WPARAM(wpar) > 120 ? Mouse.wheelDown : Mouse.wheelUp,
						true, LOWORD(lpar), window.size.y-HIWORD(lpar)
				);
			};
			default:break;
		}
		return {};
	}

	extern(Windows)
	static LRESULT internalEvents(HWND window, UINT msg, WPARAM wpar, LPARAM lpar) nothrow {
		try {
			foreach(w; cast(List!Win32Window)wm.windows){
				if(w.handle == window){
					eventQueue ~= translateEvent(w, msg, wpar, lpar);
					if(msg == WM_CLOSE)
						return 0;
				}
			}
		} catch(Throwable)
			assert(0);
		return DefWindowProcW(window, msg, wpar, lpar);
	}

