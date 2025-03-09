module ws.wm.x11.api;

version(Posix):

public import
	ws.bindings.xlib,
	ws.bindings.glx;

extern(C){

	alias T_glXCreateContextAttribsARB = GLXContext function(Display*, GLXFBConfig, GLXContext, Bool, const int*);

}
