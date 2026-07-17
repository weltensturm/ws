
module ws.wm.wayland;

// version(Posix):

// import
// 	std.stdio,
// 	std.traits,
// 	std.string,
// 	std.meta,
// 	std.algorithm,
// 	ws.bindings.wayland_client,
// 	ws.bindings.egl,
// 	ws.gui.base,
// 	ws.wm,
// 	ws.wm.baseWindowManager,
// 	ws.list,
// 	ws.wm.baseWindowManager;


// __gshared:


// class WaylandWindow: Base {
//     wl_surface*      surface;
//     xdg_surface*     xdg_surface_;
//     xdg_toplevel*    top;

//     wl_egl_window*   egl_window;
//     EGLSurface       egl_surface;
//     int              w, h;

//     wl_callback*     frameCb;

//     this(int w, int h, string title){
//         hidden = true;
//         size = [w, h];
//         surface = wl_compositor_create_surface(wm.compositor);
//         xdg_surface_ = xdg_wm_base_get_xdg_surface(wm.wm, surface);
//         xdg_surface_add_listener(xdg_surface_, _, cast(void*)this);
//         top = xdg_surface_get_toplevel(xdg_surface_);
//         xdg_toplevel_set_title(top, title.toStringz);
//         wl_surface_commit(surface);
//         wl_display_roundtrip(wm.display);
//         egl_window = wl_egl_window_create(surface, w, h);
//         egl_surface = eglCreatePlatformWindowSurface(wm.egl_display, null, egl_window, null);
//     }

//     ~this(){
//         eglDestroySurface(wm.egl_display, egl_surface);
//         wl_egl_window_destroy(egl_window);
//         xdg_surface_destroy(xdg_surface_);
//         wl_surface_destroy(surface);
//     }
// }

// class WaylandApp: BaseWindowManager {

//     wl_display*     display;
//     wl_compositor*  compositor;
//     xdg_wm_base*    xdg_wm;

//     EGLDisplay      egl_display;
//     EGLContext      egl_context;

//     Window[]        windows;

// 	this(){
// 		super();

//         display = wl_display_connect(null);

//         auto registry = wl_display_get_registry(display);
//         wl_registry_add_listener(registry, _, null);
//         wl_display_roundtrip(display);

//         egl_display = eglGetPlatformDisplay(EGL_PLATFORM_WAYLAND_KHR, display, null);
//         eglInitialize(egl_display, null, null);

//         EGLConfig cfg;
//         EGLint num;
//         auto attrs = [EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT,
//                       EGL_SURFACE_TYPE,    EGL_WINDOW_BIT,
//                       EGL_NONE];
//         eglChooseConfig(egl_display, attrs.ptr, &cfg, 1, &num);
//         egl_context = eglCreateContext(egl_display, cfg, EGL_NO_CONTEXT, null);
//         eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);

// 	}

// 	// void on(Args...)(WindowHandle window, Args args) if(allSatisfy!(isCallable, args)) {
// 	// 	XWindowAttributes wa;
// 	// 	XGetWindowAttributes(wm.displayHandle, window, &wa);
// 	// 	long mask = wa.your_event_mask;
// 	// 	foreach(dg; args){
// 	// 		bool found;
// 	// 		foreach(mapping; EventMap){
// 	// 			static if(is(mapping.Event* == Parameters!dg[0])){
// 	// 				mask |= mapping.mask;
// 	// 				if(!found){
// 	// 					found = true;
// 	// 					handler[window][mapping.type] ~= (XEvent* e) => mixin("dg(&e." ~ mapping.attribute ~ ")");
// 	// 				}
// 	// 			}
// 	// 		}
// 	// 	}
// 	// 	XSelectInput(displayHandle, window, mask);
// 	// }

// 	~this(){
// 	    eglDestroyContext(egl_display, egl_context);
// 	    wl_display_disconnect(dpy);
// 	}

// 	GraphicsContext currentContext(){
// 		return glXGetCurrentContext();
// 	}

// 	void processEvents(bool syncNext=false){
// 	    if(syncNext){
//     	    wl_display_dispatch_pending(display);
//     	}else{
//     	    wl_display_dispatch(display);
//     	}
// 	}

// }


// private extern(C) {
//     void regAdd(void*, wl_registry* reg, uint name, const(char)* iface, uint){
//         if (strcmp(iface, wl_compositor_interface.name) == 0)
//             wm.compositor = cast(wl_compositor*)wl_registry_bind(reg, name, &wl_compositor_interface, 4);
//         else if (strcmp(iface, xdg_wm_base_interface.name) == 0)
//             wm.xdg_wm = cast(xdg_wm_base*)wl_registry_bind(reg, name, &xdg_wm_base_interface, 2);
//     }
//     void regRem(void*, wl_registry*, uint) {}
//     const wl_registry_listener regL = {&regAdd, &regRem};

//     /* xdg_surface configure: trivial resize demo */
//     void configure(void* data, xdg_surface* surf, uint serial){
//         auto win = cast(WaylandWindow*)data;
//         xdg_surface_ack_configure(surf, serial);
//         wl_egl_window_resize(win.egl_window, win.size.w, win.size.h, 0, 0);
//     }
//     const xdg_surface_listener xdgL = {&configure};

//     /* frame-done → draw next frame */
//     void frameDone(void* data, wl_callback* cb, uint){
//         auto win = cast(WaylandWindow*)data;
//         wl_callback_destroy(cb);                       // re-arm
//         win.frameCb = wl_surface_frame(win.surf);
//         wl_callback_add_listener(win.frameCb, &frameL, win);

//         win.draw();
//     }
//     const wl_callback_listener frameL = {&frameDone};
// }
