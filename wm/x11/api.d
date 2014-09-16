module ws.wm.x11.api;

version(Posix):

public import X11.Xlib, X11.keysymdef, derelict.opengl3.glx;

void load(string s)(){
	auto ptr = glXGetProcAddress(s.toStringz());
	if(!ptr)
		throw new Exception("failed to get function \"" ~ s ~ "\"");
	mixin(s ~ " = cast(typeof(" ~ s ~ "))ptr;");
}

extern(C){
	alias GLXContext function(derelict.util.xtypes.Display*, GLXFBConfig, GLXContext, derelict.util.xtypes.Bool, const int*) T_glXCreateContextAttribsARB;
}

alias GLXContext Context;
