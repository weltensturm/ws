module ws.x.drawSimple;

version(Posix):


import
    std.string,
    std.algorithm,
    std.math,
    std.conv,
    std.range,
    ws.bindings.xlib,
    ws.draw,
    ws.wm,
    ws.gui.point,
    ws.x.backbuffer,
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


class XDrawSimple: DrawEmpty {

    int[2] size;
    Display* dpy;
    int screen;
    WindowHandle window;
    GC gc;

    Color color;
    Color[long[4]] colors;

    this(ws.wm.Window window){
        this(wm.displayHandle, window.windowHandle);
    }

    this(Display* dpy, WindowHandle window){
        XWindowAttributes wa;
        XGetWindowAttributes(dpy, window, &wa);
        this.dpy = dpy;
        screen = DefaultScreen(dpy);
        this.window = window;
        this.size = [wa.width, wa.height];
        XGCValues gcValues;
        gcValues.subwindow_mode = IncludeInferiors;
        gc = XCreateGC(dpy, window, GCSubwindowMode, &gcValues);
	    XSetBackground(dpy,gc,0);
        XSetLineAttributes(dpy, gc, 1, LineSolid, CapButt, JoinMiter);
        XSetFillStyle(dpy, gc, FillSolid);
    }

    override void resize(int[2] size){
        this.size = size;
    }

    override void destroy(){
        XFreeGC(dpy, gc);
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

    override void rect(int[2] pos, int[2] size){
        XSetForeground(dpy, gc, color.pix);
        XFillRectangle(dpy, window, gc, pos.x, pos.y, size.w, size.h);
    }

    override void line(int[2] start, int[2] end){
        XSetForeground(dpy, gc, color.pix);
        XDrawLine(dpy, window, gc, start.x, start.y, end.x, end.y);
    }

    override void clear(){
        XClearWindow(dpy, window);
    }

}
