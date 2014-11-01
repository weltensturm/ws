module ws.wm.win32.wm;

version(Windows):

import
	std.utf,

	ws.list,
	ws.log,
	ws.gui.input,
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
		auto ptr = wglGetProcAddress(s);
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
		windowClass.hIcon = LoadIconA(null, IDI_APPLICATION);
		windowClass.hCursor = LoadCursorA(null, IDC_ARROW);
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
		foreach(window; windows)
			window.processEvents;
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
	static LRESULT internalEvents(HWND window, UINT msg, WPARAM wpar, LPARAM lpar) nothrow {
		try {
			foreach(w; cast(List!Win32Window)wm.windows){
				if(w.handle == window){
					w.addEvent(Event(msg, wpar, lpar));
					if(msg == WM_CLOSE)
						return 0;
				}
			}
		} catch(Throwable)
			assert(0);
		return DefWindowProcW(window, msg, wpar, lpar);
	}

