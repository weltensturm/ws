module ws.bindings.xft;

version(Posix):

import
	x11.X,
	x11.Xlib,
	x11.Xutil,
	x11.extensions.Xrender,
	ws.bindings.fontconfig;

extern(C){

	alias Picture = XID;
	alias XftChar8 = char;
	alias XftResult = FcResult;

	struct XftColor {
		ulong pixel;
		XRenderColor color;
	}
	struct XftFont {
		int ascent;
		int descent;
		int height;
		int max_advance_width;
		FcCharSet* charset;
		FcPattern* pattern;
	}
	struct XftDraw{}

	Picture XftDrawPicture(XftDraw *draw);

	void XftFontClose(Display*, XftFont*);
	XftDraw *XftDrawCreate (Display*, Drawable, Visual*, Colormap);
	void XftDrawChange(XftDraw*, Drawable);
	void XftDrawDestroy(XftDraw*);
	void XftDrawStringUtf8(XftDraw*, XftColor*, XftFont*, int, int, const(char)*, int);
	void XftDrawString32(XftDraw*, XftColor*, XftFont*, int, int, const(dchar)*, int);
	Bool XftDrawSetClipRectangles(XftDraw*, int, int, XRectangle*, int);
	Bool XftDrawSetClip(XftDraw*, Region);
	void XftColorFree(Display*, Visual*, Colormap, XftColor*);
	Bool XftColorAllocName (Display*, Visual*, Colormap, const(char)*, XftColor*);
	XftFont* XftFontOpenName (Display*, int, const(char)*);
	XftFont* XftFontOpenPattern(Display*, FcPattern*);
	Bool XftCharExists(Display*, XftFont*, long);
	void XftTextExtentsUtf8(Display*, XftFont*, const(char)*, int, XGlyphInfo*);
	FcPattern* XftFontMatch(Display*, int, FcPattern*, XftResult*);
	
}
