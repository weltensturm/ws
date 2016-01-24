module ws.x.draw;

version(Posix):


import
	std.string,
	std.algorithm,
	std.math,
	std.conv,
	x11.X,
	x11.Xlib,
	x11.extensions.render,
	x11.extensions.Xrender,
	ws.draw,
	ws.bindings.xft,
	ws.gui.point,
	ws.x.font;


class Color {

	ulong pix;
	XftColor rgb;
	long[4] rgba;

	this(Display* dpy, int screen, long[4] values){
		Colormap cmap = DefaultColormap(dpy, screen);
		Visual* vis = DefaultVisual(dpy, screen);
		rgba = values;
		auto name = "#%02x%02x%02x".format(values[0], values[1], values[2]);
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

class Icon {
	XImage* img;
	int width;
	int height;
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
	Color[long[4]] colors;

	ws.x.font.Font font;
	ws.x.font.Font[string] fonts;

	XRectangle[] clipStack;

	this(Display* dpy, int screen, Window root, int w, int h){
		this.dpy = dpy;
		this.screen = screen;
		this.root = root;
		size = [w,h];
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
		font ~= ":size=%d".format(size);
		if(font !in fonts)
			fonts[font] = new ws.x.font.Font(dpy, screen, font);
		this.font = fonts[font];
	}

	override int fontHeight(){
		return font.h;
	}

	override void setColor(float[3] color){
		setColor([color[0], color[1], color[2], 1]);
	}

	override void setColor(float[4] color){
		long[4] values = [
			(color[0]*255).lround.max(0).min(255),
			(color[1]*255).lround.max(0).min(255),
			(color[2]*255).lround.max(0).min(255),
			(color[3]*255).lround.max(0).min(255)
		];
		if(values !in colors)
			colors[values] = new Color(dpy, screen, values);
		this.color = colors[values];
	}

	override void clip(int[2] pos, int[2] size){
		pos[1] = this.size[1] - pos[1] - size[1];
		if(clipStack.length){
			auto rect = clipStack[$-1];
			auto maxx = rect.x + rect.width;
			auto maxy = rect.y + rect.height;
			pos = [
					pos.x.max(rect.x).min(maxx),
					pos.y.max(rect.y).min(maxy)
			];
			size = [
					(pos.x+size.w.min(rect.width)).min(maxx)-pos.x,
					(pos.y+size.h.min(rect.height)).min(maxy)-pos.y
			];
		}
		auto rect = XRectangle(cast(short)pos[0], cast(short)pos[1], cast(short)size[0], cast(short)size[1]);
		XftDrawSetClipRectangles(xft, 0, 0, &rect, 1);
		XSetClipRectangles(dpy, gc, 0, 0, &rect, 1, Unsorted);
		clipStack ~= rect;
	}

	override void noclip(){
		clipStack = clipStack[0..$-1];
		if(clipStack.length){
			auto rect = clipStack[$-1];
			XftDrawSetClipRectangles(xft, 0, 0, &rect, 1);
			XSetClipRectangles(dpy, gc, 0, 0, &rect, 1, Unsorted);
		}else{
			XSetClipMask(dpy, gc, None);
			XftDrawSetClip(xft, null);
		}
	}

	override void rect(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XFillRectangle(dpy, drawable, gc, pos.x, this.size.h-size.h-pos.y, size.w, size.h);
		/+
		XRenderColor color;
		color.red =   this.color.rgba[0].to!ushort;
		color.green = this.color.rgba[1].to!ushort;
		color.blue =  this.color.rgba[2].to!ushort;
		color.alpha = this.color.rgba[3].to!ushort;
		XRenderFillRectangle(dpy, PictOpSrc, picture, &color, pos.x, this.size.h-size.h-pos.y, size.w, size.h);
		+/
	}

	override void rectOutline(int[2] pos, int[2] size){
		XSetForeground(dpy, gc, color.pix);
		XDrawRectangle(dpy, drawable, gc, pos.x, this.size.h-pos.y-size.h, size.w, size.h);
	}

	override int text(int[2] pos, string text, double offset=-0.2){
		if(text.length){
			auto width = width(text);
			auto fontHeight = font.h;
			auto offsetRight = max(0.0,-offset)*fontHeight;
			auto offsetLeft = max(0.0,offset-1)*fontHeight;
			auto x = pos.x - min(1,max(0,offset))*width + offsetRight - offsetLeft;
			auto y = this.size.h - pos.y - 2;
			XftDrawStringUtf8(xft, &color.rgb, font.xfont, cast(int)x.lround, cast(int)y.lround, text.toStringz, cast(int)text.length);
			return this.width(text);
		}
		return 0;
	}
	
	override int text(int[2] pos, int h, string text, double offset=-0.2){
		pos.y += ((h-font.h)/2.0).lround;
		return this.text(pos, text, offset);
	}

	struct IconQueueData {
		Icon icon;
		int x;
		int y;
	}

	IconQueueData[] iconQueue;

	void icon(Icon icon, int x, int y){
		iconQueue ~= IconQueueData(icon, x, y);
		//XPutImage(dpy, drawable, gc, icon.img, 0, 0, x, y, cast(uint)icon.width, cast(uint)icon.height);
	}

	override void finishFrame(){
		foreach(q; iconQueue){
			XPutImage(dpy, drawable, gc, q.icon.img, 0, 0, q.x, q.y, cast(uint)q.icon.width, cast(uint)q.icon.height);
		}
		XCopyArea(dpy, drawable, root, gc, 0, 0, size.w, size.h, 0, 0);
		//iconQueue = [];
		XSync(dpy, False);
	}

}

