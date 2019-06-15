module ws.x.draw;

version(Posix):


import
    std.string,
    std.algorithm,
    std.math,
    std.conv,
    std.range,
    x11.X,
    x11.Xlib,
    x11.extensions.render,
    x11.extensions.Xrender,
    x11.extensions.Xfixes,
    ws.draw,
    ws.wm,
    ws.bindings.xft,
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
    Picture picture;
    int[2] size;
    ~this(){
        // TODO: fix crash if X connection closes before this is called
        XRenderFreePicture(wm.displayHandle, picture);
    }
}


class ManagedPicture {
    Display* dpy;
    Picture picture;
    alias picture this;
    this(Display* dpy, Drawable drawable, XRenderPictFormat* format){
        this.dpy = dpy;
        XRenderPictureAttributes pa;
        pa.subwindow_mode = IncludeInferiors;
        picture = XRenderCreatePicture(dpy, drawable, format, CPSubwindowMode, &pa);
    }
    ~this(){
        XRenderFreePicture(dpy, picture);
    }
}


struct ClipStack {
    XserverRegion[] stack;

    void push(XserverRegion region){
        XserverRegion newregion = XFixesCreateRegion(wm.displayHandle, null, 0);
        XFixesCopyRegion(wm.displayHandle, newregion, region);
        if(stack.length)
            XFixesIntersectRegion(wm.displayHandle, newregion, stack[$-1], newregion);
        stack ~= newregion;
    }

    void push(int[2] pos, int[2] size){
        XRectangle r = {
            pos.x.to!short,
            pos.y.to!short,
            size.w.max(0).to!ushort,
            size.h.max(0).to!ushort
        };
        XserverRegion region = XFixesCreateRegion(wm.displayHandle, &r, 1);
        if(stack.length)
            XFixesIntersectRegion(wm.displayHandle, region, stack[$-1], region);
        stack ~= region;
    }

    void clip(XftDraw* xft, GC gc, Picture picture){
        if(stack.length){
            int count;
            auto area = XFixesFetchRegion(wm.displayHandle, stack[$-1], &count);
            XftDrawSetClipRectangles(xft, 0, 0, area, count);
            XFree(area);
            XFixesSetPictureClipRegion(wm.displayHandle, picture, 0, 0, stack[$-1]);
            if(gc)
                XFixesSetGCClipRegion(wm.displayHandle, gc, 0, 0, stack[$-1]);
        }else{
            if(gc)
                XFixesSetGCClipRegion(wm.displayHandle, gc, 0, 0, None);
            XFixesSetPictureClipRegion(wm.displayHandle, picture, 0, 0, None);
            XftDrawSetClip(xft, null);
        }
    }

    void pop(){
        XFixesDestroyRegion(wm.displayHandle, stack[$-1]);
        stack.length -= 1;
    }

    XserverRegion all(){
        return stack[$-1];
    }
}


class PixmapDoubleBuffer {

    Pixmap pixmap;
    WindowHandle window;
    GC gc;
    int[2] size;

    alias pixmap this;

    this(WindowHandle window, int[2] size, GC gc, int depth){
        pixmap = XCreatePixmap(wm.displayHandle, window, size.w, size.h, depth);
        this.window = window;
        this.size = size;
        this.gc = gc;
    }

    void swap(){
        XCopyArea(wm.displayHandle, pixmap, window, gc, 0, 0, size.w, size.h, 0, 0);
    }

    ~this(){
        XFreePixmap(wm.displayHandle, pixmap);
    }

}


class XDraw: DrawEmpty {

    int[2] size;
    Display* dpy;
    int screen;
    x11.X.Window window;
    Visual* visual;
    XftDraw* xft;
    GC gc;

    Color color;
    Color[long[4]] colors;

    ws.x.font.Font font;
    ws.x.font.Font[string] fonts;

    ClipStack clipStack;

    Xdbe.BackBuffer drawable;
    //PixmapDoubleBuffer drawable; // TODO: flatman splits/floating title bars break with this

    ManagedPicture picture;

    this(ws.wm.Window window){
        this(wm.displayHandle, window.windowHandle);
    }

    this(Display* dpy, x11.X.Window window){
        XWindowAttributes wa;
        XGetWindowAttributes(dpy, window, &wa);
        this.dpy = dpy;
        screen = DefaultScreen(dpy);
        this.window = window;
        this.size = [wa.width, wa.height];
        gc = XCreateGC(dpy, window, 0, null);
        XSetLineAttributes(dpy, gc, 1, LineSolid, CapButt, JoinMiter);
        //drawable = new PixmapDoubleBuffer(window, size, gc, wa.depth);
        drawable = new Xdbe.BackBuffer(dpy, window);
        xft = XftDrawCreate(dpy, drawable, wa.visual, wa.colormap);
        visual = wa.visual;
        auto format = XRenderFindVisualFormat(dpy, wa.visual);
        picture = new ManagedPicture(dpy, drawable, format);
    }

    override int width(string text){
        debug {
            assert(font, "No font active");
        }
        return font.width(text);
    }

    override void resize(int[2] size){
        this.size = size;
        XWindowAttributes wa;
        XGetWindowAttributes(dpy, window, &wa);
        /+
        .destroy(drawable);
        drawable = new PixmapDoubleBuffer(window, size, gc, wa.depth);
        +/
        auto format = XRenderFindVisualFormat(dpy, wa.visual);
        .destroy(picture);
        picture = new ManagedPicture(dpy, drawable, format);
        XftDrawChange(xft, drawable);
    }

    override void destroy(){
        foreach(font; fonts)
            font.destroy;
        .destroy(drawable);
        .destroy(picture);
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
        clipStack.push([pos.x, this.size.h-size.h-pos.y], size);
        //clipStack.push(pos, size);
        clipStack.clip(xft, gc, picture);
    }

    void clip(XserverRegion region){
        clipStack.push(region);
        clipStack.clip(xft, gc, picture);
    }

    override void noclip(){
        clipStack.pop;
        clipStack.clip(xft, gc, picture);
    }

    override void rect(int[2] pos, int[2] size){
        auto a = this.color.rgba[3]/255.0;
        XRenderColor color = {
            (this.color.rgba[0]*255*a).to!ushort,
            (this.color.rgba[1]*255*a).to!ushort,
            (this.color.rgba[2]*255*a).to!ushort,
            (this.color.rgba[3]*255).to!ushort
        };
        XRenderFillRectangle(dpy, PictOpOver, picture, &color, pos.x, this.size.h-size.h-pos.y, size.w, size.h);
    }

    override void rectOutline(int[2] pos, int[2] size){
        clip(pos.a + [1,1], size.a - [2,2]);
        rect(pos, size);
        noclip;
    }

    override void line(int[2] start, int[2] end){
        XSetForeground(dpy, gc, color.pix);
        XDrawLine(dpy, drawable, gc, start.x, start.y, end.x, end.y);
    }

    override int text(int[2] pos, string text, double offset=-0.2){
        if(text.length){
            text = text.replace("\t", "    ");
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

    Icon icon(ubyte[] data, int[2] size){
        assert(data.length == size.w*size.h*4, "%s != %s*%s*4".format(data.length, size.w, size.h));
        auto res = new Icon;

        auto img = XCreateImage(
                dpy,
                null,
                32,
                ZPixmap,
                0,
                cast(char*)data.ptr,
                cast(uint)size.w,
                cast(uint)size.h,
                32,
                0
        );

        auto pixmap = XCreatePixmap(dpy, drawable, size.w, size.h, 32);

        XRenderPictureAttributes attributes;
        auto gc = XCreateGC(dpy, pixmap, 0, null);
        XPutImage(dpy, pixmap, gc, img, 0, 0, 0, 0, size.w, size.h);
        auto pictformat = XRenderFindStandardFormat(dpy, PictStandardARGB32);
        res.picture = XRenderCreatePicture(dpy, pixmap, pictformat, 0, &attributes);
        XRenderSetPictureFilter(dpy, res.picture, "best", null, 0);
        XFreePixmap(dpy, pixmap);
        XFreeGC(dpy, gc);

        res.size = size;
        return res;
        /+
        res.pixmap = XCreatePixmap(wm.displayHandle, window, DisplayWidth(wm.displayHandle, 0), DisplayHeight(wm.displayHandle, 0), DefaultDepth(wm.displayHandle, 0));
        res.picture = XRenderCreatePicture(wm.displayHandle, pixmap, format, 0, null);
        XFreePixmap(wm.displayHandle, res.pixmap);
        +/

    }

    void icon(Icon icon, int x, int y, double scale, Picture alpha=None){
        XTransform xform = {[
            [XDoubleToFixed( 1 ), XDoubleToFixed( 0 ), XDoubleToFixed( 0 )],
            [XDoubleToFixed( 0 ), XDoubleToFixed( 1 ), XDoubleToFixed( 0 )],
            [XDoubleToFixed( 0 ), XDoubleToFixed( 0 ), XDoubleToFixed( scale )]
        ]};
        XRenderSetPictureTransform(dpy, icon.picture, &xform);
        XRenderComposite(dpy, PictOpOver, icon.picture, alpha, picture, 0, 0, 0, 0, x, y, (icon.size.w*scale).to!int, (icon.size.h*scale).to!int);
    }

    override void clear(){
        XRenderColor color = {0, 0, 0, 0};
        XRenderFillRectangle(dpy, PictOpSrc, picture, &color, 0, 0, size.w, size.h);
    }

    override void finishFrame(){
        //XCopyArea(dpy, drawable, window, gc, 0, 0, size.w, size.h, 0, 0);
        //XRenderComposite(dpy, PictOpSrc, picture, None, frontBuffer, 0, 0, 0, 0, 0, 0, size.w, size.h);
        drawable.swap;
        //XSync(dpy, False);
    }

}
