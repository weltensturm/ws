module ws.x.font;


import
	std.string,
	x11.Xlib,
	x11.extensions.Xrender,
	ws.bindings.xft,
	ws.bindings.fontconfig;


class Font {

	Display* dpy;
	int ascent;
	int descent;
	uint h;
	XftFont* xfont;
	FcPattern* pattern;

	this(Display* dpy, int screen, string name){
		this(dpy, screen, name, null);
	}

	this(Display* dpy, int screen, string name, FcPattern* pattern){
		if(!name.length && !pattern)
			throw new Exception("No font specified.");
		this.dpy = dpy;
		if(name.length){
			xfont = XftFontOpenName(dpy, screen, name.toStringz);
			pattern = FcNameParse(cast(FcChar8*)name);
			if(!xfont || !pattern){
				if(xfont){
					XftFontClose(dpy, xfont);
					xfont = null;
				}
				throw new Exception("Cannot load font " ~ name);
			}
		}else if(pattern){
			xfont = XftFontOpenPattern(dpy, pattern);
			if(!xfont)
				throw new Exception("Error, cannot load font pattern");
			else
				pattern = null;
		}
		ascent = xfont.ascent;
		descent = xfont.descent;
		h = ascent + descent;
	}

	int[2] size(string text){
		XGlyphInfo ext;
		if(!text.length)
			return [0,0];
		XftTextExtentsUtf8(dpy, xfont, cast(XftChar8*)text.toStringz, cast(int)text.length, &ext);
		return[ext.xOff, h];
	}

	int width(string text){
		return size(text)[0];
	}

	void destroy(){
		if(pattern)
			FcPatternDestroy(pattern);
		XftFontClose(dpy, xfont);
	}

}
