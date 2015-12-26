module ws.x.property;

import
	std.string,
	x11.X,
	x11.Xlib,
	x11.Xutil,
	x11.Xatom,
	ws.wm;

class Property(ulong Format, bool List){

	Atom property;
	x11.X.Window window;
	
	static if(Format == XA_CARDINAL || Format == XA_PIXMAP)
		alias Type = long;
	static if(Format == XA_ATOM)
		alias Type = Atom;
	static if(Format == XA_WINDOW)
		alias Type = x11.X.Window;

	this(x11.X.Window window, string name){
		this.window = window;
		property = XInternAtom(wm.displayHandle, name.toStringz, false);
	}


	ubyte* raw(ref ulong count){
		int di;
		ulong dl;
		ubyte* p;
		Atom da;
		if(XGetWindowProperty(wm.displayHandle, window, property, 0L, List ? long.max : 1, 0, Format,
		                      &da, &di, &count, &dl, &p) == 0 && p){
			return p;
		}
		return null;
	}

	void request(Type[] data){
		XEvent e;
		e.type = ClientMessage;
		e.xclient.window = window;
		e.xclient.message_type = property;
		e.xclient.format = 32;
		e.xclient.data.l[0..data.length] = cast(long[])data;
		XSendEvent(wm.displayHandle, XDefaultRootWindow(wm.displayHandle), false, SubstructureNotifyMask|SubstructureRedirectMask, &e);
	}
	
	static if(List)
		Type[] get(){
			ulong count;
			auto p = raw(count);
			auto d = (cast(Type*)p)[0..count].dup;
			XFree(p);
			return d;
		}
	else{
		Type get(){
			ulong n=1;
			auto p = raw(n);
			if(!p)
				return Type.init;
			auto d = *(cast(Type*)p);
			XFree(p);
			return d;
		}
		void set(Type data){
			XChangeProperty(wm.displayHandle, window, property, Format, 32, PropModeReplace, cast(ubyte*)&data, 1);
		}
	}


}


/+

module dock.proputil;

import dock;


alias CARDINAL = long;

Display* dpy;


class Property {
	
	x11.X.Window window;
	Atom property;
	int format;
	
	this(x11.X.Window window, string name){
		this.window = window;
		if(!dpy)
			dpy = XOpenDisplay(null);
		property = XInternAtom(dpy, name.toStringz, false);
	}
	
	ubyte* _rawget(ref ulong count){
		int di;
		ulong dl;
		ubyte* p;
		Atom da;
		if(XGetWindowProperty(dpy, window, property, 0L, count, false, format,
		                      &da, &di, &count, &dl, &p) == 0 && p){
			return p;
		}
		return null;
	}

	T[] _get_list(T)(ulong count){
		auto p = _rawget(count);
		auto d = (cast(T*)p)[0..count].dup;
		XFree(p);
		return d;
	}

	T _get_one(T)(){
		ulong n=1;
		auto p = _rawget(n);
		if(!p)
			return T.init;
		auto d = *(cast(T*)p);
		XFree(p);
		return d;
	}

	void _request(T)(T[] data){
		XEvent e;
		e.type = ClientMessage;
		e.xclient.window = window;
		e.xclient.message_type = property;
		e.xclient.format = 32;
		e.xclient.data.l[0..data.length] = cast(long[])data;
		XSendEvent(dpy, root, false, SubstructureNotifyMask|SubstructureRedirectMask, &e);
	}

	void set(CARDINAL data){
		XChangeProperty(dpy, window, property, format, 32, PropModeReplace, cast(ubyte*)&data, 1);
	}

	void setAtoms(Atom[] data){
		XChangeProperty(dpy, window, property, format, 32, PropModeReplace, cast(ubyte*)data.ptr, cast(int)data.length);
	}

}

class AtomProperty: Property {
	
	this(x11.X.Window window, string name){
		super(window, name);
		format = XA_ATOM;
	}

	Atom get(){
		return _get_one!Atom;
	}
	
	void request(Atom[] data){
		_request(data);
	}

}

class AtomListProperty: Property {
	
	this(x11.X.Window window, string name){
		super(window, name);
		format = XA_ATOM;
	}

	Atom[] get(ulong n){
		return _get_list!Atom(n);
	}

}

class CardinalProperty: Property {

	this(x11.X.Window window, string name){
		super(window, name);
		format = XA_CARDINAL;
	}

	CARDINAL get(){
		return _get_one!CARDINAL;
	}

	void request(CARDINAL[] data){
		_request(data);
	}

}

class CardinalListProperty: Property {
	
	this(x11.X.Window window, string name){
		super(window, name);
		format = XA_CARDINAL;
	}

	CARDINAL[] get(ulong n){
		return _get_list!CARDINAL(n);
	}
	
}

class WindowListProperty: Property {


	this(x11.X.Window window, string name){
		super(window, name);
		format = XA_WINDOW;
	}

	x11.X.Window[] get(ulong n){
		return _get_list!(x11.X.Window)(n);
	}

}

void request(Atom atom, long[] data){
	XEvent e;
	e.type = ClientMessage;
	e.xclient.message_type = atom;
	e.xclient.format = 32;
	e.xclient.data.l[0..data.length] = data;
	XSendEvent(dpy, root, false, SubstructureNotifyMask|SubstructureRedirectMask, &e);
}

+/
