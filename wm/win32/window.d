module ws.wm.win32.window;

version(Windows):

import
	std.conv,
	std.string,
	std.utf,

	ws.string,
	ws.list,
	ws.wm.baseWindow,
	ws.wm.win32.api,
	ws.wm.win32.wm;

__gshared:


class Win32Window: BaseWindow {

	protected {
		int antiAliasing = 1;
		HDC deviceContext;
	
		bool shouldRedraw = false;
	}

	this(WindowHandle handle){
		windowHandle = handle;
	}

	@property
	WindowHandle handle(){
		return windowHandle;
	}

	void addEvent(Event e){
		eventQueue ~= e;
	}

	this(int w, int h, string t){
		title = t;
		size = [w, h];
		eventQueue = new List!Event;
		RECT targetSize = {0, 0, size.x, size.y};
		AdjustWindowRect(&targetSize, WS_OVERLAPPEDWINDOW | WS_VISIBLE, false);
		WNDCLASSW wc;
		wc.lpfnWndProc = cast(WNDPROC)&internalEvents;
		wc.hInstance = wm.getInstance();
		wc.hIcon = LoadIconA(null,IDI_APPLICATION);
		wc.hCursor = LoadCursorA(null, IDC_ARROW);
		wc.hbrBackground = cast(HBRUSH)GetStockObject(BLACK_BRUSH);
		wc.lpszClassName = "wm::windowClass".toUTF16z();
		wc.style = CS_OWNDC;
		RegisterClassW(&wc);
		windowHandle = CreateWindowExW(
			0, wc.lpszClassName, title.toUTF16z(),
			WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT,
			targetSize.right-targetSize.left, targetSize.bottom-targetSize.top,
			null, null, wm.getInstance, null
		);
		if(!windowHandle)
			throw new Exception("CreateWindowW failed");
		RECT r;
		GetWindowRect(windowHandle, &r);
		pos = [r.left, r.right];

		RAWINPUTDEVICE rawMouseDevice;
		rawMouseDevice.usUsagePage = 0x01; 
		rawMouseDevice.usUsage = 0x02;
		rawMouseDevice.dwFlags = RIDEV_INPUTSINK;   
		rawMouseDevice.hwndTarget = windowHandle;
		if(!RegisterRawInputDevices(&rawMouseDevice, 1, RAWINPUTDEVICE.sizeof))
			throw new Exception("Failed to register RID");

		shouldCreateGraphicsContext();
		show();
	}

	override void show(){
		if(isActive)
			return;
		ShowWindow(windowHandle, SW_SHOWNORMAL);
		UpdateWindow(windowHandle);
		activateGraphicsContext();
		isActive = true;
	}
																							
	override void hide(){
		if(!isActive)
			return;
		DestroyWindow(windowHandle);
		isActive = false;
	}

	override void setTitle(string title){
		this.title = title;
		if(isActive)
			SetWindowTextW(windowHandle, title.toUTF16z());
	}

	override string getTitle(){
		wchar[512] str;
		int r = GetWindowTextW(windowHandle, str.ptr, str.length);
		return to!string(str[0..r]);
	}

	override long getPid(){
		DWORD pid;
		DWORD threadId = GetWindowThreadProcessId(windowHandle, &pid);
		return pid;
	}
	

	override void createGraphicsContext(){
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
	}

	override void createGraphicsContextOld(){
		PIXELFORMATDESCRIPTOR pfd = {
			(PIXELFORMATDESCRIPTOR).sizeof, 1, 4 | 32 | 1, 0, 8, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0
		};
		int pixelFormat = ChoosePixelFormat(deviceContext, &pfd);
		SetPixelFormat(deviceContext, pixelFormat, &pfd);
		graphicsContext = wglCreateContext(deviceContext);
		wglMakeCurrent(deviceContext, graphicsContext);
	}

	override void shouldCreateGraphicsContext(){
		try
			createGraphicsContext();
		catch
			createGraphicsContextOld();
		activateGraphicsContext();
		DerelictGL3.reload();
	}

	override void makeCurrent(Context context){
		if(!wglMakeCurrent(deviceContext, context))
			throw new Exception("Failed to activate context, " ~ getLastError());
	}

	override void activateGraphicsContext(){
		if(!wm.activeWindow)
			wm.activeWindow = this;
		makeCurrent(graphicsContext);
	}

	override Context shareContext(){
		auto c = wm.wglCreateContextAttribsARB(deviceContext, graphicsContext, null);
		if(!c)
			throw new Exception("Failed to create shared context, " ~ getLastError());
		return c;
	}

	override void swapBuffers(){
		if(!wm.activeWindow)
			return;
		SwapBuffers(deviceContext);
	}


	override void setCursor(Mouse.cursor cursor){
		version(Windows){
			HCURSOR hcur = null;
			if(cursor != Mouse.cursor.none)
				hcur = LoadCursorW(null, cast(const(wchar)*)MOUSE_CURSOR_TO_HCUR[cast(int)cursor]);
			this.cursor = cursor;
			SetCursor(hcur);
			SetClassLongW(windowHandle, -12, cast(LONG)cast(LONG_PTR)hcur);
		}
	}

	override void setCursorPos(int x, int y){
		POINT p = {cast(long)x, cast(long)y};
		ClientToScreen(windowHandle, &p);
		SetCursorPos(p.x, p.y);
	}


	void sendMessage(uint message, WPARAM wpar, LPARAM lpar){
		SendMessageA(windowHandle, message, wpar, lpar);
	}

	/+
	void setTop(){
		SetForegroundWindow(windowHandle);
	}
	+/

	override void setActive(){
		wm.activeWindow = this;
	}

	override bool processEvent(Event e){
		switch(e.msg){
			/+ Gamepads & Joysticks
			case WM_CREATE: {
				RAWINPUTDEVICE rid;
				rid.usUsagePage = 1;
				rid.usUsage	 = 4; // Joystick
				rid.dwFlags	 = 0;
				rid.hwndTarget  = hWnd;
				if(!RegisterRawInputDevices(&rid, 1, sizeof(RAWINPUTDEVICE)))
					return -1;
				break;
			}
			case WM_INPUT: {
				PRAWINPUT pRawInput;
				UINT	  bufferSize;
				HANDLE	hHeap;
				GetRawInputData((HRAWINPUT)lParam, RID_INPUT, NULL, 
				&bufferSize, sizeof(RAWINPUTHEADER));
				hHeap	 = GetProcessHeap();
				pRawInput = (PRAWINPUT)HeapAlloc(hHeap, 0, bufferSize);
				if(!pRawInput)
					return 0;
				GetRawInputData((HRAWINPUT)lParam, RID_INPUT, 
				pRawInput, &bufferSize, sizeof(RAWINPUTHEADER));
				ParseRawInput(pRawInput);
				HeapFree(hHeap, 0, pRawInput);
			}
			+/
			case WM_INPUT: {
				RAWINPUT input;
				UINT bufferSize = RAWINPUT.sizeof;
				GetRawInputData(cast(HRAWINPUT)e.lpar, RID_INPUT, &input, &bufferSize, RAWINPUTHEADER.sizeof);
				if(input.header.dwType == RIM_TYPEMOUSE){
					onRawMouse(input.mouse.lLastX, input.mouse.lLastY);
				}
				return true;
			}
			case WM_PAINT:
				shouldRedraw = false;
				onDraw();
				return true;
			case WM_SHOWWINDOW:
				onShow();
				return true;
			case WM_CLOSE:
				hide();
				return true;
			case WM_SIZE:
				onResize(LOWORD(e.lpar),HIWORD(e.lpar));
				size = [LOWORD(e.lpar),HIWORD(e.lpar)];
				return true;
			case WM_KEYDOWN:
				Keyboard.key c = cast(Keyboard.key)toLower(cast(char)e.wpar);
				Keyboard.set(c, true);
				onKeyboard(c, true);
				return true;
			case WM_KEYUP:
				auto c = cast(Keyboard.key)toLower(cast(char)e.wpar);
				Keyboard.set(c, false);
				onKeyboard(c, false);
				return true;
			case WM_CHAR:
				onKeyboard(cast(dchar)e.wpar);
				return true;
			case WM_ACTIVATE:
				onKeyboardFocus(LOWORD(e.wpar) > 0 ? true : false); return true;
			case WM_SETCURSOR:
				SetCursor(MOUSE_CURSOR_TO_HCUR[cast(int)cursor]);
				return true;
			case WM_MOUSEMOVE:
				if(!(parent && parent.mouseChild != this)){
					TRACKMOUSEEVENT tme = {
						TRACKMOUSEEVENT.sizeof, 2, windowHandle, 0xFFFFFFFF
					};
					TrackMouseEvent(&tme);
					onMouseFocus(true);
				}
				onMouseMove(GET_X_LPARAM(e.lpar), size.y-GET_Y_LPARAM(e.lpar));
				return true;
			case WM_MOUSELEAVE:
				onMouseFocus(false);
				return true;
			case WM_LBUTTONDOWN:
				onMouseButton(Mouse.buttonLeft, true, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_LBUTTONUP:
				onMouseButton(Mouse.buttonLeft, false, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_MBUTTONDOWN:
				onMouseButton(Mouse.buttonMiddle, true, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_MBUTTONUP:
				onMouseButton(Mouse.buttonMiddle, false, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_RBUTTONDOWN:
				onMouseButton(Mouse.buttonRight, true, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_RBUTTONUP:
				onMouseButton(Mouse.buttonRight, false, LOWORD(e.lpar), HIWORD(e.lpar));
				return true;
			case WM_MOUSEWHEEL:
				onMouseButton(
						GET_WHEEL_DELTA_WPARAM(e.wpar) > 120 ? Mouse.wheelDown : Mouse.wheelUp,
						true, LOWORD(e.lpar), HIWORD(e.lpar)
				);
				return true;
			default:
				return false;
		}
	}

}


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
