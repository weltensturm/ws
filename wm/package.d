module ws.wm;

__gshared:


version(Windows){
	import derelict.opengl3.wgl;
	pragma(lib, "gdi32.lib");
	pragma(lib, "DerelictGL3.lib");
	pragma(lib, "DerelictUtil.lib");
	import
		ws.wm.win32.api,
		ws.wm.win32.window,
		ws.wm.win32.wm;
	alias Window = Win32Window;
	alias WindowHandle = HWND;
	alias Event = ws.wm.win32.api.Event;
	alias WindowManager = Win32WindowManager;
	alias GraphicsContext = Context;
}
version(Posix){
	import X11.Xlib;
	pragma(lib, "DerelictGL3");
	pragma(lib, "DerelictUtil");
	pragma(lib, "dl");
	import
		ws.wm.x11.api,
		ws.wm.x11.window,
		ws.wm.x11.wm;
	alias Window = X11Window;
	alias WindowManager = X11WindowManager;
	alias GraphicsContext = GLXContext;
	alias Event = XEvent;
}


WindowManager wm(){
	version(Windows)
		return ws.wm.win32.wm.wm;
	version(Posix)
		return ws.wm.x11.wm.wm;
};
