module ws.x.atoms;


import
    std.string,
    x11.X,
    x11.Xlib,
    ws.wm;


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
