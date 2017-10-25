module ws.gl.context;


version(Posix):


import
    std.conv,
    std.algorithm,
    ws.wm,
    ws.exception,
    ws.gl.gl;



version(Posix):

import ws.wm.x11.api;
import derelictX = derelict.util.xtypes;

alias GLXContext = void*;


class GlContext {
    
    GLXContext handle;

    this(){
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
        DerelictGL3.reload();
    }

    void activate(x11.X.Window window){
        glXMakeCurrent(wm.displayHandle, cast(uint)window, cast(__GLXcontextRec*)handle);
    }

}

