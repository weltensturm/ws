module ws.gl.context;


import
    std.conv,
    std.algorithm,
    std.string,
    std.traits,
    ws.wm,
    ws.exception,
    ws.gl.gl;


version(Windows){


    string getLastError(){
        DWORD errcode = GetLastError();
        if(!errcode)
            return "No error";
        LPCSTR msgBuf;
        DWORD i = FormatMessageA(
            cast(uint)(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS),
            null,
            errcode,
            cast(uint)MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            cast(LPSTR)&msgBuf,
            0,
            null
        );
        string text = to!string(msgBuf);
        LocalFree(cast(HLOCAL)msgBuf);
        return text;
    }


    import ws.wm.win32.api;

    private static GraphicsContext current;

    auto chooseBestPixelFormat(){
        
    }

    __gshared class GlContext {

        GraphicsContext handle;
        __gshared GraphicsContext sharedHandle;
        WindowHandle window;
        HDC deviceContext;

        private GraphicsContext spawn(){
            auto c = wm.wglCreateContextAttribsARB(GetDC(window), sharedHandle, null);
            if(!c)
                throw new Exception("Failed to create shared context");
            return c;
        }

        this(WindowHandle window, GraphicsContext context){
            this.window = window;
            this.handle = context;
            this.sharedHandle = context;
        }

        this(WindowHandle window){
            enum antiAliasing = 0;
            this.window = window;
            deviceContext = GetDC(window);
            try {
                if(!deviceContext)
                    throw new Exception("window.Show failed: GetDC");
                uint formatCount = 0;
                int pixelFormat;
                int[] iAttribList = [
                    0x2001, true,
                    0x2010, true,
                    0x2011, true,
                    0x2003, 0x2027,
                    0x2014, 0x202B,
                    0x2014, 24,
                    0x201B, 8,
                    0x2022, 16,
                    0x2023, 8,
                    0x2011, true,
                    0x2041, antiAliasing > 1 ? true : false,
                    0x2042, antiAliasing,
                    0
                ];
                wm.wglChoosePixelFormatARB(deviceContext, iAttribList.ptr, null, 1, &pixelFormat, &formatCount);
                if(!formatCount)
                    throw new Exception("wglChoosePixelFormatARB failed: %s".format(getLastError()));
                SetPixelFormat(deviceContext, pixelFormat, null);
            }catch(Exception e){
                ubyte depth = 32;
                ubyte color = 24;
                ubyte stencil = 8;
                PIXELFORMATDESCRIPTOR descriptor;
                descriptor.nSize        = descriptor.sizeof;
                descriptor.nVersion     = 1;
                descriptor.iLayerType   = PFD_MAIN_PLANE;
                descriptor.dwFlags      = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
                descriptor.iPixelType   = PFD_TYPE_RGBA;
                descriptor.cColorBits   = depth;
                descriptor.cDepthBits   = color;
                descriptor.cStencilBits = stencil;
                descriptor.cAlphaBits   = depth == 32 ? 8 : 0;
                auto pixelFormat = ChoosePixelFormat(deviceContext, &descriptor);
                SetPixelFormat(deviceContext, pixelFormat, &descriptor);
            }

            try {
                enum WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
                enum WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;
                enum WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;
                int[] attribs = [
                    WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
                    WGL_CONTEXT_MINOR_VERSION_ARB, 3,
                    //WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB, 1,
                    0, 0
                ];
                handle = wm.wglCreateContextAttribsARB(deviceContext, null, attribs.ptr);
                if(!handle)
                    throw new Exception("wglCreateContextAttribsARB() failed: %s".format(getLastError()));
            }catch(Exception e){
                import std.stdio; writeln(e);
                handle = core.sys.windows.wingdi.wglCreateContext(deviceContext);
            }
            this.sharedHandle = handle;
            wglMakeCurrent(deviceContext, handle);
        }

        void swapBuffers(){
            assert(handle == sharedHandle, "Can only swap from main");
            SwapBuffers(deviceContext);
        }

        template opDispatch(string s){
            auto opDispatch(Args...)(Args args){
                if(!handle && sharedHandle){
                    synchronized(this){
                        handle = spawn;
                    }
                }
                if(current != handle){
                    wglMakeCurrent(window, handle);
                    current = handle;
                }
                assert(wglGetCurrentContext() == handle);
                debug { gl.check("?"); }
                enum s = s[0..1].capitalize ~ s[1..$];
                mixin("alias returns = ReturnType!(gl" ~ s ~ ");");
                static if(!is(returns == void)){
                    mixin("auto result = gl" ~ s ~ "(args);");
                    debug { gl.check("gl" ~ s); }
                    return result;
                }else{
                    mixin("gl" ~ s ~ "(args);");
                    debug { gl.check("gl" ~ s); }
                }
            }
        }

    }


}


version(Posix){

    import ws.wm.x11.api;

    private static GraphicsContext current;

    T_glXCreateContextAttribsARB glXCreateContextAttribsARB;

    class GlContext {

        GraphicsContext handle;
        WindowHandle window;
        Display* display;

        this(WindowHandle window){
            this(wm.displayHandle, window);
        }

        this(Display* display, WindowHandle window){
            this.window = window;
            this.display = display;
            XVisualInfo* graphicsInfo;
            try {

        		wm.glCore = true;
        		glXCreateContextAttribsARB = cast(T_glXCreateContextAttribsARB)
                                             glXGetProcAddress(cast(ubyte*)"glXCreateContextAttribsARB".toStringz);
        		if(!glXCreateContextAttribsARB)
        			wm.glCore = false;

                if(!wm.glCore)
                    throw new Exception("disabled");
                
                XWindowAttributes wa;
                assert(XGetWindowAttributes(display, window, &wa));

                XVisualInfo visual;
                visual.screen   = DefaultScreen(display);
                visual.visualid = XVisualIDFromVisual(wa.visual);
                int visualCount = 0;
                graphicsInfo = XGetVisualInfo(display, VisualIDMask | VisualScreenMask, &visual, &visualCount);
                
                size_t config = size_t.max;

                int nbConfigs = 0;
                GLXFBConfig* configs = glXChooseFBConfig(display, DefaultScreen(display), null, &nbConfigs);

                foreach(i, fbc; configs[0..nbConfigs]){
                    auto vis = cast(XVisualInfo*)glXGetVisualFromFBConfig(display, fbc);
                    if(!vis)
                        continue;
                    scope(exit)
                        XFree(vis);
                    if(vis.visualid == visual.visualid){
                        config = i;
                        break;
                    }
                }

                import std.stdio;
                writeln(*graphicsInfo);

                if(config == size_t.max)
                    throw new Exception("Failed to get FB config");

                int[] attribs = [
                    GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
                    GLX_CONTEXT_MINOR_VERSION_ARB, 3,
                    0
                ];

                handle = glXCreateContextAttribsARB(
                        display, configs[config], null, cast(int)True, attribs.ptr
                );
                if(!handle)
                    throw new Exception("glXCreateContextAttribsARB failed");

                debug(glContextInfo){
                    import std.stdio;
                    writeln(graphicsInfo.depth);
                }

            }catch(Exception e){
                import std.stdio;
                writeln(e);
                GLint[] att = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_ALPHA_SIZE, 8, GLX_DOUBLEBUFFER, 0];
                graphicsInfo = cast(XVisualInfo*)glXChooseVisual(display, 0, att.ptr);
                handle = glXCreateContext(display, graphicsInfo, null, True);
                if(!handle)
                    throw new Exception("glXCreateContext failed");
            }
            glXMakeCurrent(display, cast(uint)window, cast(__GLXcontextRec*)handle);
            current = handle;

        }

        void swapBuffers(){
            glXSwapBuffers(display, cast(uint)window);
        }

        template opDispatch(string s){
            auto opDispatch(Args...)(Args args){
                enum s = s[0..1].capitalize ~ s[1..$];
                if(current != handle){
                    debug(glContextSwitch){
                        import std.stdio;
                        writeln("CONTEXT SWITCH %s -> %s".format(current, handle));
                    }
                    glXMakeCurrent(display, cast(uint)window, cast(__GLXcontextRec*)handle);
                    current = handle;
                }
                assert(glXGetCurrentContext() == cast(__GLXcontextRec*)handle);
                debug { gl.check("?"); }
                mixin("alias returns = typeof((){ return gl" ~ s ~ "(args); }() );");
                static if(!is(returns == void)){
                    mixin("auto result = gl" ~ s ~ "(args);");
                    debug { gl.check("gl" ~ s); }
                    return result;
                }else{
                    mixin("gl" ~ s ~ "(args);");
                    debug { gl.check("gl" ~ s); }
                }
            }
        }

    }

}
