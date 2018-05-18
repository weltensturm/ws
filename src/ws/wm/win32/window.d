module ws.wm.win32.window;

version(Windows):

import
	std.conv,
	std.string,
	std.utf,

	ws.string,
	ws.list,
	ws.gui.base,
	ws.draw,
	ws.wm.win32.api,
	ws.wm.win32.wm,
	ws.wm;

__gshared:


class Win32Window: Base {

	Mouse.cursor cursor = Mouse.cursor.inherit;
	string title;
	WindowHandle windowHandle;
	List!Event eventQueue;

	int antiAliasing = 1;
	HDC deviceContext;

	bool hasMouse;
	bool _hasFocus;
	Base _dragging;
	bool draggingUnfocus;
	int[2] _cursorPos;

	bool isActive = true;
	DrawEmpty _draw;

	this(WindowHandle handle){
		windowHandle = handle;
	}

	this(int w, int h, string t){
		title = t;
		size = [w, h];
		RECT targetSize = {0, 0, size.x, size.y};
		AdjustWindowRect(&targetSize, WS_OVERLAPPEDWINDOW | WS_VISIBLE, false);
		windowHandle = CreateWindowExW(
			0, wm.windowClass.lpszClassName, title.toUTF16z(),
			WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT,
			targetSize.right-targetSize.left, targetSize.bottom-targetSize.top,
			null, null, wm.getInstance, null
		);
		if(!windowHandle)
			throw new Exception("CreateWindowW failed");
		RECT r;
		GetWindowRect(windowHandle, &r);
		pos = [r.left, r.right];

		drawInit;

		RAWINPUTDEVICE rawMouseDevice;
		rawMouseDevice.usUsagePage = 0x01; 
		rawMouseDevice.usUsage = 0x02;
		rawMouseDevice.hwndTarget = windowHandle;
		if(!RegisterRawInputDevices(&rawMouseDevice, 1, RAWINPUTDEVICE.sizeof))
			throw new Exception("Failed to register RID");
		
		if(GetFocus == windowHandle)
			onKeyboardFocus(true);
		
	}

	override DrawEmpty draw(){
		return _draw;
	}

	void draw(DrawEmpty draw){
		_draw = draw;
	}

	@property
	WindowHandle handle(){
		return windowHandle;
	}

	override void show(){
		if(!hidden)
			return;
		ShowWindow(windowHandle, SW_SHOWNORMAL);
		UpdateWindow(windowHandle);
		onKeyboardFocus(true);
		resized(size);
		super.show;
	}

	override void hide(){
		if(hidden)
			return;
		DestroyWindow(windowHandle);
		super.hide;
	}

	override void resize(int[2] size){
		super.resize(size);
	}

	void resized(int[2] size){
		if(draw)
			draw.resize(size);
		this.size = size;
	}

	void setTitle(string title){
		this.title = title;
		SetWindowTextW(windowHandle, title.toUTF16z());
	}

	string getTitle(){
		wchar[512] str;
		int r = GetWindowTextW(windowHandle, str.ptr, str.length);
		return to!string(str[0..r]);
	}

	long getPid(){
		DWORD pid;
		DWORD threadId = GetWindowThreadProcessId(windowHandle, &pid);
		return pid;
	}
	
	@property
	override bool hasFocus(){
		return _hasFocus;
	}
	
	override void onKeyboardFocus(bool focus){
		_hasFocus = focus;
	}

	void swapBuffers(){
		SwapBuffers(deviceContext);
	}

	override void onDraw(){
		super.onDraw;
		draw.finishFrame;
	}

	void onRawMouse(int x, int y){}

	void setActive(){
		wm.activeWindow = this;
	}

	override void setCursor(Mouse.cursor cursor){
		HCURSOR hcur = null;
		if(cursor != Mouse.cursor.none)
			hcur = LoadCursorW(null, cast(const(wchar)*)MOUSE_CURSOR_TO_HCUR[cast(int)cursor]);
		this.cursor = cursor;
		SetCursor(hcur);
		SetClassLongW(windowHandle, -12, cast(LONG)cast(LONG_PTR)hcur);
	}

	void setCursorPos(int x, int y){
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

	void drawInit(){
		//_draw = new GlDraw;
	}

	override int[2] cursorPos(){
		return _cursorPos;
	}

	override Base draggingChild(){
		return _dragging;
	}

	override void onMouseMove(int x, int y){
		_cursorPos = [x, y];
		super.onMouseMove(x, y);
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
