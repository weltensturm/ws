module ws.x.property;

import
	std.algorithm,
	std.array,
	std.string,
	std.conv,
    ws.bindings.xlib,
	ws.x.atoms,
	ws.gui.base,
	ws.wm,
	ws.identity;


mixin template WindowProperties(string wsv) {

	static foreach(line; wsv.splitLines().map!strip.filter!`a.length`) {
		mixin(iq{
			Property!(cast(long)$(line.split()[1].strip("[]")),
			          $(line.split()[1].endsWith("[]").to!string))
			    $(line.split()[0]);
		}.text);
	}

	void setPropertyWindow(WindowHandle window) {
		static foreach(line; wsv.splitLines().map!strip.filter!`a.length`) {
			{
				enum format = line.split()[1].strip("[]");
				enum isList = line.split()[1].endsWith("[]") ? "true" : "false";
				enum name = line.split()[0];
				mixin("this." ~ name ~ " = new Property!(cast(long)" ~ format ~ ", " ~ isList ~ ")(window, \"" ~ name ~ "\");");
			}
		}
	}

	void updateProperties(){
		static foreach(line; wsv.splitLines().map!strip.filter!`a.length`) {
			{
				enum name = line.split()[0];
				mixin(iq{
					$(name).update();
				}.text);
			}
		}
	}

	void updateProperties(XPropertyEvent* event){
		static foreach(line; wsv.splitLines().map!strip.filter!`a.length`) {
			{
				enum name = line.split()[0];
				mixin(iq{
					auto property = this.$(name);
					if(property.property == event.atom && property.window == event.window){
						property.update;
					}
				}.text);
			}
		}
	}
}


class Property(long Format, bool List) {

	WindowHandle window;
	Atom property;
	string name;
	bool exists;

	static if(Format == XA_CARDINAL || Format == XA_PIXMAP || Format == XA_VISUALID)
		alias Type = long;
	static if(Format == XA_ATOM)
		alias Type = Atom;
	static if(Format == XA_WINDOW)
		alias Type = WindowHandle;
	static if(Format == XA_STRING)
		alias Type = string;

	static if(List)
		alias FullType = Type[];
	else
		alias FullType = Type;

	FullType value;
	alias value this;

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

	this(WindowHandle window, string name){
		this.window = window;
		this.name = name;
		property = XInternAtom(wm.displayHandle, name.toStringz, false);
		update;
	}

	this(WindowHandle window, Atom property){
		this.window = window;
		this.name = name;
		this.property = property;
		update;
	}

	void update(){
		auto newValue = get;
		foreach(handler; handlers)
			handler(newValue);
		value = newValue;
	}

	ubyte* raw(ref ulong count){
		int di;
		ulong dl;
		ubyte* p;
		Atom da;
		if(XGetWindowProperty(wm.displayHandle, window, property, 0L,
		                      List || is(Type == string) ? long.max : 1,
		                      0,
		                      is(Type == string) ? Atoms.UTF8_STRING : Format,
		                      &da, &di, &count, &dl, &p) == 0 && p){
			exists = true;
			return p;
		}
		exists = false;
		return null;
	}

	void rawset(T1, T2)(Atom format, int size, int mode, T1* data, T2 length){
		XChangeProperty(wm.displayHandle, window, property, format, size, mode, cast(ubyte*)data, cast(int)length);
	}

	void request(WindowHandle window, Type[] data){
		XEvent e;
		e.type = ClientMessage;
		e.xclient.window = window;
		e.xclient.message_type = property;
		e.xclient.format = 32;
		e.xclient.data.l[0..data.length] = cast(long[])data;
		XSendEvent(wm.displayHandle, this.window, false, SubstructureNotifyMask|SubstructureRedirectMask, &e);
	}

	void request(Type[] data){
		request(window, data);
	}

	FullType get(){
		ulong count = List ? 0 : 1;
		auto p = raw(count);
		if(!p)
			return FullType.init;
		FullType value;
		static if(List){
			value = (cast(Type*)p)[0..count].dup;
		}else static if(is(Type == string))
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
			rawset(Atoms.UTF8_STRING, 8, PropModeReplace, data.toStringz, data.length);
		}else{
			rawset(Format, 32, PropModeReplace, &data, 1);
		}
	}

}


class PropertyError: Exception {
	this(string msg){
		super(msg);
	}
}


auto dispatchProperty(string name)(WindowHandle window){

	struct Proxy {

		T get(T)(){
			ulong count;
			int format;
			ulong bytes_after;
			ubyte* p;
			Atom type;

			if(XGetWindowProperty(wm.displayHandle, window, Atoms.opDispatch!name, 0L, long.max, 0, AnyPropertyType,
			   &type, &format, &count, &bytes_after, &p) == 0 && p){

				scope(exit)
					XFree(p);

				import std.stdio, std.traits, std.range;

				static if(is(T == string)){
					return (cast(char*)p)[0..count].to!string;
				}else static if(isIterable!T){
					alias Type = ElementType!T;
					Type[] result;
					result.length = count;
					auto casted = cast(Type*)p;
					foreach(i; 0..count){
						result[i] = casted[i];
					}
					return result;
				}else{
					return *(cast(T*)p);
				}

			}
			return T.init;
		}

		void get(T)(void delegate(T) fn){
			ulong count;
			int format;
			ulong bytes_after;
			ubyte* p;
			Atom type;

			if(XGetWindowProperty(wm.displayHandle, window, Atoms.opDispatch!name, 0L, long.max, 0, AnyPropertyType,
			   &type, &format, &count, &bytes_after, &p) == 0 && p){

				import std.stdio, std.traits, std.range;
				writeln(type, ' ', format, ' ', count);

				static if(is(T == string)){
					fn((cast(char*)p)[0..count].to!string);
				}else static if(isIterable!T){
					alias Type = ElementType!T;
					Type[] result;
					result.length = count;
					auto casted = cast(Type*)p;
					foreach(i; 0..count){
						result[i] = casted[i];
					}
					fn(result);
				}else{
					fn(cast(T*)p);
				}

				XFree(p);
			}
		}

		void get(T)(void function(T) fn){
			import std.functional;
			get(fn.toDelegate);
		}

	}

	return Proxy();

}


auto props(WindowHandle window){

	struct Dispatcher {

		auto opDispatch(string name)(){
			return dispatchProperty!name(window);
		}

	}

	return Dispatcher();

}

