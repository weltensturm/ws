module ws.x.property;

import
	std.algorithm,
	std.array,
	std.string,
	std.conv,
	x11.X,
	x11.Xlib,
	x11.Xutil,
	x11.Xatom,
	ws.gui.base,
	ws.wm;


class BaseProperty {

	x11.X.Window window;
	Atom property;
	string name;

	abstract void update();

}


class PropertyList {

	private BaseProperty[] properties;

	void add(BaseProperty property){
		properties ~= property;
	}

	void remove(BaseProperty property){
		properties = properties.without(property);
	}

	void remove(x11.X.Window window){
		properties = properties.filter!(a => a.window != window).array;
	}

	void update(XPropertyEvent* event){
		foreach(property; properties){
			if(property.property == event.atom && property.window == event.window){
				property.update;
			}
		}
	}

}


class Property(ulong Format, bool List): BaseProperty {

	static if(Format == XA_CARDINAL || Format == XA_PIXMAP)
		alias Type = long;
	static if(Format == XA_ATOM)
		alias Type = Atom;
	static if(Format == XA_WINDOW)
		alias Type = x11.X.Window;
	static if(Format == XA_STRING)
		alias Type = string;

	static if(List)
		alias FullType = Type[];
	else
		alias FullType = Type;
	
	FullType value;

	void delegate(FullType)[] handlers;

	void opAssign(FullType value){
		this.value = value;
		set(value);
	}

	void opOpAssign(string op)(void delegate(FullType) handler){
		static if(op == "~")
			handlers ~= handler;
		else static assert(false, op ~ "= not supported");
	}

	alias value this;


	this(x11.X.Window window, string name, PropertyList list = null){
		if(list)
			list.add(this);
		this.window = window;
		this.name = name;
		property = XInternAtom(wm.displayHandle, name.toStringz, false);
		update;
	}

	override void update(){
		value = get;
		foreach(handler; handlers)
			handler(value);
	}

	ubyte* raw(ref ulong count){
		int di;
		ulong dl;
		ubyte* p;
		Atom da;
		if(XGetWindowProperty(wm.displayHandle, window, property, 0L, List || is(Type == string) ? long.max : 1, 0, is(Type == string) ? XInternAtom(wm.displayHandle, "UTF8_STRING", False) : Format, &da, &di, &count, &dl, &p) == 0 && p){
			return p;
		}
		return null;
	}

	void rawset(T1, T2)(Atom format, int size, int mode, T1* data, T2 length){
		XChangeProperty(wm.displayHandle, window, property, format, size, mode, cast(ubyte*)data, cast(int)length);
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
	
	FullType get(){
		ulong count = List ? 0 : 1;
		auto p = raw(count);
		if(!p)
			return FullType.init;
		FullType value;
		static if(List)
			value = (cast(Type*)p)[0..count].dup;
		else static if(is(Type == string))
			value = (cast(char*)p)[0..count].to!string;
		else
			value = *(cast(Type*)p);
		XFree(p);
		return value;
	}

	void set(FullType data){
		static if(List){
			rawset(Format, 32, PropModeReplace, data.ptr, data.length);
		}else static if(is(Type == string)){
			rawset(XInternAtom(wm.displayHandle, "UTF8_STRING", False), 8, PropModeReplace, data.toStringz, data.length);
		}else{
			rawset(Format, 32, PropModeReplace, &data, 1);
		}
	}


}

