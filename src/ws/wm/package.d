module ws.wm;

__gshared:


version(Windows){
	pragma(lib, "gdi32.lib");
	pragma(lib, "DerelictUtil.lib");
	import
		ws.wm.win32.api,
		ws.wm.win32.window,
		ws.wm.win32.wm;
	alias Window = Win32Window;
	alias WindowHandle = HWND;
	alias WindowEvent = ws.wm.win32.api.Event;
	alias WindowManager = Win32WindowManager;
	alias GraphicsContext = Context;
}
version(Posix){
	import
		ws.wm.x11.api,
		ws.wm.x11.window,
		ws.wm.x11.wm;
	alias Window = X11Window;
	alias WindowHandle = ws.wm.x11.api.Window;
	alias WindowManager = X11WindowManager;
	alias GraphicsContext = GLXContext;
	alias WindowEvent = XEvent;
}


WindowManager wm(){
	static bool loaded;
	__gshared WindowManager wm;
	synchronized {
		if(!loaded && wm)
			return wm;
		if(!wm){
			wm = new WindowManager;
			loaded = true;
		}
	}
	return wm;
}

