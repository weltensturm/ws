module ws.x.draw;

version(Posix):


import
	std.string,
	std.algorithm,
	std.math,
	x11.X,
	x11.Xlib,
	ws.draw,
	ws.bindings.xft,
	ws.gui.point,
	ws.x.font;


class Color {

	ulong pix;
	XftColor rgb;

	this(Display* dpy, int screen, string name){
		Colormap cmap = DefaultColormap(dpy, screen);
		Visual* vis = DefaultVisual(dpy, screen);
		if(!XftColorAllocName(dpy, vis, cmap, name.toStringz, &rgb))
			throw new Exception("Cannot allocate color " ~ name);
		pix = rgb.pixel;
	}

}

class Cur {
	Cursor cursor;
	this(Display* dpy, int shape){
		cursor = XCreateFontCursor(dpy, shape);
	}
	void destroy(Display* dpy){
		XFreeCursor(dpy, cursor);
	}
}

class XDraw: DrawEmpty {

	int[2] size;
	Display* dpy;
	int screen;
	Window root;
	Drawable drawable;
	XftDraw* xft;
	GC gc;

	Color color;
	Color[string] colors;

	ws.x.font.Font font;
	ws.x.font.Font[string] fonts;

	this(Display* dpy, int screen, Window root, int w, int h){
		this.dpy = dpy;
		this.screen = screen;
		this.root = root;
		w = w;
		h = h;
		drawable = XCreatePixmap(dpy, root, w, h, DefaultDepth(dpy, screen));
		gc = XCreateGC(dpy, root, 0, null);
		XSetLineAttributes(dpy, gc, 1, LineSolid, CapButt, JoinMiter);
		auto cmap = DefaultColormap(dpy, screen);
		auto vis = DefaultVisual(dpy, screen);
		xft = XftDrawCreate(dpy, drawable, vis, cmap);
	}

	override int width(string text){
		return font.width(text);
	}

	override void resize(int[2] size){
		this.size = size;
		if(drawable)
			XFreePixmap(dpy, drawable);
		drawable = XCreatePixmap(dpy, root, size.w, size.h, DefaultDepth(dpy, screen));
		XftDrawChange(xft, drawable);
	}

	void destroy(){
		foreach(font; fonts)
			font.destroy;
		XFreePixmap(dpy, drawable);
		XftDrawDestroy(xft);
		XFreeGC(dpy, gc);
	}

	override void setFont(string font, int size){
		if(font !in fonts)
			fonts[font] = new ws.x.font.Font(dpy, screen, font);
		this.font = fonts[font];
	}

	override int fontHeight(){
		return font.h;
	}

	override void setColor(float[3] color){
		auto name = "#%02x%02x%02x".format(
			(color[0]*255).lround.min(255).max(0),
			(color[1]*255).lround.min(255).max(0),
			(color[2]*255).lround.min(255).max(0)
		);
		if(name !in colors)
			colors[name] = new Color(dpy, screen, name);
		this.color = colors[name];
	}

	override void setColor(float[4] color){
		setColor(color[0..3]);
	}

	void clip(int[2] pos, int[2] size){
		auto rect = XRectangle(cast(short)pos[0], cast(short)pos[1], cast(short)size[0], cast(short)size[1]);
		XftDrawSetClipRectangles(xft, 0, 0, &rect, 1);
		XSetClipRectangles(dpy, gc, 0, 0, &rect, 1, Unsorted);
	}

	void noclip(){
		XSetClipMask(dpy, gc, None);
		XftDrawSetClip(xft, null);
	}

	override void rect(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XFillRectangle(dpy, drawable, gc, pos.x, this.size.h-size.h-pos.y, size.w+1, size.h+1);
	}

	override void rectOutline(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XDrawRectangle(dpy, drawable, gc, pos.x+1, this.size.h-pos.y+1, size.w-1, size.h-1);
	}

	override void text(int[2] pos, string text, double offset=-0.2){
		if(text.length){
			auto width = width(text);
			auto fontHeight = font.h;
			auto offsetRight = max(0.0,-offset)*fontHeight;
			auto offsetLeft = max(0.0,offset-1)*fontHeight;
			auto x = pos.x - min(1,max(0,offset))*width + offsetRight - offsetLeft;
			auto y = this.size.h - pos.y - 1;
			XftDrawStringUtf8(xft, &color.rgb, font.xfont, cast(int)x.lround, cast(int)y.lround, text.toStringz, cast(int)text.length);
		}
	}
	
	override void text(int[2] pos, int h, string text, double offset=-0.2){
		pos.y += ((h-font.h)/2.0).lround;
		this.text(pos, text, offset);
	}

	override void finishFrame(){
		XCopyArea(dpy, drawable, root, gc, 0, 0, size.w, size.h, 0, 0);
		XSync(dpy, False);
	}

}
