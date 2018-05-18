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

    import ws.wm.win32.api;

    private static GraphicsContext current;


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
                    throw new Exception("wglChoosePixelFormatARB failed: %s".format(glGetError()));
                SetPixelFormat(deviceContext, pixelFormat, null);
                int[] attribs = [
                    0x2091, 3,
                    0x2092, 2,
                    0x9126, 0x00000001,
                    0
                ];
                handle = wm.wglCreateContextAttribsARB(deviceContext, null, attribs.ptr);
                if(!handle)
                    throw new Exception("wglCreateContextAttribsARB() failed: %s".format(glGetError()));
            }catch(Exception e){
                PIXELFORMATDESCRIPTOR pfd = {
                    (PIXELFORMATDESCRIPTOR).sizeof, 1, 4 | 32 | 1, 0, 8, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0
                };
                int pixelFormat = ChoosePixelFormat(deviceContext, &pfd);
                SetPixelFormat(deviceContext, pixelFormat, &pfd);
                handle = core.sys.windows.wingdi.wglCreateContext(deviceContext);
            }
            this.sharedHandle = handle;
            wglMakeCurrent(deviceContext, handle);
            DerelictGL3.reload();
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
    import derelictX = derelict.util.xtypes;

    private static GraphicsContext current;


    class GlContext {
        
        GraphicsContext handle;
        WindowHandle window;

        this(WindowHandle window){
            this.window = window;
            GLint[] att = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_ALPHA_SIZE, 8, GLX_DOUBLEBUFFER, 0];
            auto graphicsInfo = cast(XVisualInfo*)glXChooseVisual(wm.displayHandle, 0, att.ptr);
            try {
                if(!wm.glCore)
                    throw new Exception("disabled");
                int[] attribs = [
                    GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
                    GLX_CONTEXT_MINOR_VERSION_ARB, 3,
                    0
                ];
                handle = wm.glXCreateContextAttribsARB(
                        wm.displayHandle, wm.mFBConfig[0], null, cast(int)True, attribs.ptr
                );
                if(!handle)
                    throw new Exception("glXCreateContextAttribsARB failed");
            }catch(Exception e){
                /+wm.glCore = false;
                GLint att[] = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, 0];
                wm.graphicsInfo = glXChooseVisual(wm.displayHandle, 0, att.ptr);
                handle = glXCreateContext(wm.displayHandle, wm.graphicsInfo, null, True);+/
                
                handle = glXCreateContext(wm.displayHandle, cast(derelictX.XVisualInfo*)wm.graphicsInfo, null, True);
                if(!handle)
                    throw new Exception("glXCreateContext failed");
            }
            glXMakeCurrent(wm.displayHandle, cast(uint)window, cast(__GLXcontextRec*)handle);
            DerelictGL3.reload();
        }

        void swapBuffers(){
            version(Posix){
                glXSwapBuffers(wm.displayHandle, cast(uint)window);
            }
        }

        template opDispatch(string s){
            auto opDispatch(Args...)(Args args){
                if(current != handle){
                    glXMakeCurrent(wm.displayHandle, cast(uint)window, cast(__GLXcontextRec*)handle);
                    current = handle;
                }
                assert(glXGetCurrentContext() == cast(__GLXcontextRec*)handle);
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

