module ws.x.backbuffer;


version(linux):


import ws.bindings.Xdbe, std.string;


__gshared:


class Xdbe {
    
    static class BackBuffer {
        
        Display* dpy;
        XdbeSwapInfo info;
        XdbeBackBuffer dbe;

        alias dbe this;

        this(Display* dpy, Window window){
            info.swap_window = window;
            info.swap_action = XdbeCopied;
            this.dpy = dpy;
            dbe = XdbeAllocateBackBufferName(dpy, window, XdbeCopied);
            if(!dbe)
                throw new Exception("Failed to allocate Xdbe backbuffer");
        }
        
        ~this(){
            XdbeDeallocateBackBufferName(dpy, dbe);
            // TODO: ensure X connection
        }

        void swap(){
            XdbeSwapBuffers(dpy, &info, 1);
        }

    }

    static int versionMajor,
               versionMinor;
    
    static void init(Display* dpy){
        if (XdbeQueryExtension(dpy, &versionMajor, &versionMinor)){
            if(versionMajor >= 1)
                return;
        }
        throw new Exception("Xdbe unsuitable, version %s.%s".format(versionMajor, versionMinor));
    }
}