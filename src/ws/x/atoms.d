module ws.x.atoms;


import
    std.string,
    ws.wm,
	ws.bindings.c_xlib;


class Atoms {

	static Atom opDispatch(string name)(){
		struct Tmp {
			__gshared Atom atom;
			static Atom get(){
				if(!atom)
					atom = XInternAtom(wm.displayHandle, name.toStringz, false);
				return atom;
			}
		}
		return Tmp.get;
	}

}
