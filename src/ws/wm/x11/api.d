module ws.wm.x11.api;

version(Posix):

public import
	derelict.opengl3.glx,
	ws.bindings.xlib;

extern(C){

	alias void* GLXContext;
	//alias void* GLXFBConfig;

	alias GLXContext function(Display*, GLXFBConfig, GLXContext, Bool, const int*) T_glXCreateContextAttribsARB;

	enum GLX_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
	enum GLX_CONTEXT_MINOR_VERSION_ARB = 0x2092;

}
