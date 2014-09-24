module ws.wm.x11.api;

version(Posix):

public import X11.keysymdef;
import core.stdc.config;

pragma(lib, "X11");
pragma(lib, "GL");

extern(C){
	
	alias int Status;
	alias int Bool;
	const int False = 0;
	const int True = 1;
	
	const int InputOutput = 1;
	const int InputOnly = 2;
	
	const int AllocNone = 0;
	const int StaticGravity = 10;
	
	alias c_ulong VisualID;
	alias c_ulong Time;
	alias c_ulong Atom;
	alias GLXContext Context;

	struct _XIC;
	alias _XIC* XIC;
	
	struct _XDisplay;
	alias _XDisplay* Display;
	
	alias char* XPointer;
	
	alias c_ulong CARD32;
	
	alias CARD32 XID;
	
	alias XID Window;
	alias XID Drawable;
	alias XID Pixmap;
	alias XID Cursor;
	alias XID Colormap;
	alias XID KeySym;

	struct XTextProperty {
	    ubyte* value;		/* same as Property routines */
	    Atom encoding;			/* prop type */
	    int format;				/* prop data format: 8, 16, or 32 */
	    c_ulong nitems;		/* number of data items in value */
	}
	
	struct XColor {
		c_ulong pixel;
		ushort red, green, blue;
		char flags;
		char pad;
	}

	Window XCreateWindow(Display*, Window, int, int, uint, uint, uint, int, uint, Visual*, c_ulong, XSetWindowAttributes*);
	int XUnmapWindow(Display*, Window);
	Window XDefaultRootWindow(Display*);
	int XSelectInput(Display*, Window, c_long);
	Atom XInternAtom(Display*, const char*, Bool);
	Status XSetWMProtocols(Display*, Window, Atom*, int);
	XVisualInfo* glXChooseVisual(Display*, int, int*);
	GLXContext glXCreateContext(Display*, XVisualInfo*, GLXContext, Bool);
	void glXMakeCurrent(Display*, GLXDrawable, GLXContext);
	int XPending(Display*);
	int XNextEvent(Display*, XEvent*);
	KeySym XLookupKeysym(XKeyEvent*, int);
	int Xutf8LookupString(XIC, XKeyPressedEvent*, char*, int, KeySym*, Status*);
	int XRefreshKeyboardMapping(XMappingEvent*);
	Display *XOpenDisplay(const char*);
	Colormap XCreateColormap(Display*, Window, Visual*, int);
	Window XRootWindow(Display*, int);
	int XCloseDisplay(Display*);
	int XSynchronize(Display*, Bool);
	int XMapWindow(Display*, Window);
	XIC XCreateIC(XIM, ...);
	XIM XOpenIM(Display*, void*, char*, char*);
	int XWarpPointer(Display*, Window, Window, int, int, uint, uint, int, int);
	int XFlush(Display*);
	Status XStringListToTextProperty(char**, int, XTextProperty*);
	void XSetWMName(Display*, Window, XTextProperty*);
	Cursor XCreateFontCursor(Display*, uint);	
	Pixmap XCreateBitmapFromData(Display*, Drawable, const(char)*, uint, uint);
	int XDefineCursor(Display*, Window, Cursor);
	int XUndefineCursor(Display*, Window);
	Cursor XCreatePixmapCursor(Display*, Pixmap, Pixmap, XColor*, XColor*, uint, uint);
	int XFreePixmap(Display*, Pixmap);
	alias GLXContext function(Display*, GLXFBConfig, GLXContext, Bool, const int*) T_glXCreateContextAttribsARB;
	int XGetWindowProperty(Display*, Window, Atom, long, long, Bool, Atom, Atom*, int*, c_ulong*, c_ulong*, ubyte**);

	const int XC_num_glyphs = 154;
	const int XC_X_cursor = 0;
	const int XC_arrow = 2;
	const int XC_based_arrow_down = 4;
	const int XC_based_arrow_up = 6;
	const int XC_boat = 8;
	const int XC_bogosity = 10;
	const int XC_bottom_left_corner = 12;
	const int XC_bottom_right_corner = 14;
	const int XC_bottom_side = 16;
	const int XC_bottom_tee = 18;
	const int XC_box_spiral = 20;
	const int XC_center_ptr = 22;
	const int XC_circle = 24;
	const int XC_clock = 26;
	const int XC_coffee_mug = 28;
	const int XC_cross = 30;
	const int XC_cross_reverse = 32;
	const int XC_crosshair = 34;
	const int XC_diamond_cross = 36;
	const int XC_dot = 38;
	const int XC_dotbox = 40;
	const int XC_double_arrow = 42;
	const int XC_draft_large = 44;
	const int XC_draft_small = 46;
	const int XC_draped_box = 48;
	const int XC_exchange = 50;
	const int XC_fleur = 52;
	const int XC_gobbler = 54;
	const int XC_gumby = 56;
	const int XC_hand1 = 58;
	const int XC_hand2 = 60;
	const int XC_heart = 62;
	const int XC_icon = 64;
	const int XC_iron_cross = 66;
	const int XC_left_ptr = 68;
	const int XC_left_side = 70;
	const int XC_left_tee = 72;
	const int XC_leftbutton = 74;
	const int XC_ll_angle = 76;
	const int XC_lr_angle = 78;
	const int XC_man = 80;
	const int XC_middlebutton = 82;
	const int XC_mouse = 84;
	const int XC_pencil = 86;
	const int XC_pirate = 88;
	const int XC_plus = 90;
	const int XC_question_arrow = 92;
	const int XC_right_ptr = 94;
	const int XC_right_side = 96;
	const int XC_right_tee = 98;
	const int XC_rightbutton = 100;
	const int XC_rtl_logo = 102;
	const int XC_sailboat = 104;
	const int XC_sb_down_arrow = 106;
	const int XC_sb_h_double_arrow = 108;
	const int XC_sb_left_arrow = 110;
	const int XC_sb_right_arrow = 112;
	const int XC_sb_up_arrow = 114;
	const int XC_sb_v_double_arrow = 116;
	const int XC_shuttle = 118;
	const int XC_sizing = 120;
	const int XC_spider = 122;
	const int XC_spraycan = 124;
	const int XC_star = 126;
	const int XC_target = 128;
	const int XC_tcross = 130;
	const int XC_top_left_arrow = 132;
	const int XC_top_left_corner = 134;
	const int XC_top_right_corner = 136;
	const int XC_top_side = 138;
	const int XC_top_tee = 140;
	const int XC_trek = 142;
	const int XC_ul_angle = 144;
	const int XC_umbrella = 146;
	const int XC_ur_angle = 148;
	const int XC_watch = 150;
	const int XC_xterm = 152;

	const char* XNVaNestedList = "XNVaNestedList";
	const char* XNQueryInputStyle = "queryInputStyle";
	const char* XNClientWindow = "clientWindow";
	const char* XNInputStyle = "inputStyle";
	const char* XNFocusWindow = "focusWindow";
	const char* XNResourceName = "resourceName";
	const char* XNResourceClass = "resourceClass";
	const char* XNGeometryCallback = "geometryCallback";
	const char* XNDestroyCallback = "destroyCallback";
	const char* XNFilterEvents = "filterEvents";
	const char* XNPreeditStartCallback = "preeditStartCallback";
	const char* XNPreeditDoneCallback = "preeditDoneCallback";
	const char* XNPreeditDrawCallback = "preeditDrawCallback";
	const char* XNPreeditCaretCallback = "preeditCaretCallback";
	const char* XNPreeditStateNotifyCallback = "preeditStateNotifyCallback";
	const char* XNPreeditAttributes = "preeditAttributes";
	const char* XNStatusStartCallback = "statusStartCallback";
	const char* XNStatusDoneCallback = "statusDoneCallback";
	const char* XNStatusDrawCallback = "statusDrawCallback";
	const char* XNStatusAttributes = "statusAttributes";
	const char* XNArea = "area";
	const char* XNAreaNeeded = "areaNeeded";
	const char* XNSpotLocation = "spotLocation";
	const char* XNColormap = "colorMap";
	const char* XNStdColormap = "stdColorMap";
	const char* XNForeground = "foreground";
	const char* XNBackground = "background";
	const char* XNBackgroundPixmap = "backgroundPixmap";
	const char* XNFontSet = "fontSet";
	const char* XNLineSpace = "lineSpace";
	const char* XNCursor = "cursor";
	
	const int XIMPreeditArea		= 0x0001L;
	const int XIMPreeditCallbacks	= 0x0002L;
	const int XIMPreeditPosition	= 0x0004L;
	const int XIMPreeditNothing		= 0x0008L;
	const int XIMPreeditNone		= 0x0010L;
	const int XIMStatusArea			= 0x0100L;
	const int XIMStatusCallbacks	= 0x0200L;
	const int XIMStatusNothing		= 0x0400L;
	const int XIMStatusNone			= 0x0800L;
	
	struct _XIM;
	alias _XIM* XIM;
	
	const int CWBackPixmap = (1<<0);
	const int CWBackPixel = (1<<1);
	const int CWBorderPixmap = (1<<2);
	const int CWBorderPixel = (1<<3);
	const int CWBitGravity = (1<<4);
	const int CWWinGravity = (1<<5);
	const int CWBackingStore = (1<<6);
	const int CWBackingPlanes	 = (1<<7);
	const int CWBackingPixel	 = (1<<8);
	const int CWOverrideRedirect = (1<<9);
	const int CWSaveUnder = (1<<10);
	const int CWEventMask = (1<<11);
	const int CWDontPropagate	 = (1<<12);
	const int CWColormap = (1<<13);
	const int CWCursor	 = (1<<14);

	const int NoEventMask = 0;
	const int KeyPressMask = (1<<0);
	const int KeyReleaseMask = (1<<1);
	const int ButtonPressMask = (1<<2);
	const int ButtonReleaseMask = (1<<3);
	const int EnterWindowMask = (1<<4);
	const int LeaveWindowMask = (1<<5);
	const int PointerMotionMask = (1<<6);
	const int PointerMotionHintMask = (1<<7);
	const int Button1MotionMask = (1<<8);
	const int Button2MotionMask = (1<<9);
	const int Button3MotionMask = (1<<10);
	const int Button4MotionMask = (1<<11);
	const int Button5MotionMask = (1<<12);
	const int ButtonMotionMask = (1<<13);
	const int KeymapStateMask = (1<<14);
	const int ExposureMask = (1<<15);
	const int VisibilityChangeMask = (1<<16);
	const int StructureNotifyMask = (1<<17);
	const int ResizeRedirectMask = (1<<18);
	const int SubstructureNotifyMask = (1<<19);
	const int SubstructureRedirectMask = (1<<20);
	const int FocusChangeMask = (1<<21);
	const int PropertyChangeMask = (1<<22);
	const int ColormapChangeMask = (1<<23);
	const int OwnerGrabButtonMask = (1<<24);

	struct XSetWindowAttributes {
	 Pixmap background_pixmap;	/* background or None or ParentRelative */
	 c_ulong background_pixel;	/* background pixel */
	 Pixmap border_pixmap;	/* border of the window */
	 c_ulong border_pixel;	/* border pixel value */
	 int bit_gravity;	/* one of bit gravity values */
	 int win_gravity;	/* one of the window gravity values */
	 int backing_store;	/* NotUseful, WhenMapped, Always */
	 c_ulong backing_planes;/* planes to be preseved if possible */
	 c_ulong backing_pixel;/* value to use in restoring planes */
	 Bool save_under;	/* should bits under be saved? (popups) */
	 c_long event_mask;	/* set of events that should be saved */
	 c_long do_not_propagate_mask;	/* set of events that should not propagate */
	 Bool override_redirect;	/* boolean value for override-redirect */
	 Colormap colormap;	/* color map to be associated with window */
	 Cursor cursor;	/* cursor to be displayed (or None) */
	}

	struct XExtData {
		int number;	/* number returned by XRegisterExtension */
		XExtData* next;	/* next item on list of data for structure */
		int function(XExtData* extension) free_private;
		XPointer private_data;	/* data private to this extension. */
	}

	struct Visual {
		XExtData *ext_data;	/* hook for extension to hang data */
		VisualID visualid;	/* visual id of this visual */
		int c_class;	/* C++ class of screen (monochrome, etc.) */
		c_ulong red_mask, green_mask, blue_mask;	/* mask values */
		int bits_per_rgb;	/* log base 2 of distinct color values */
		int map_entries;	/* color map entries */
	}
	
	struct XVisualInfo {
		Visual *visual;
		VisualID visualid;
		int screen;
		int depth;
		int c_class;
		c_ulong red_mask;
		c_ulong green_mask;
		c_ulong blue_mask;
		int colormap_size;
		int bits_per_rgb;
	}

	// glx
	
	const int GLX_RGBA = 4;
	const int GLX_DOUBLEBUFFER = 5;
	const int GLX_DEPTH_SIZE = 12;
	const int GLX_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
 	const int GLX_CONTEXT_MINOR_VERSION_ARB = 0x2092;
	
	void glXSwapBuffers(Display*, GLXDrawable);
	
	struct __GLXFBConfigRec;
	alias __GLXFBConfigRec* GLXFBConfig;
	
	//struct __GLXcontextRec;
	alias void* GLXContext;
	
	alias XID GLXDrawable;
	
	// events
	
	const int KeyPress = 2;
	const int KeyRelease = 3;
	const int ButtonPress = 4;
	const int ButtonRelease = 5;
	const int MotionNotify = 6;
	const int EnterNotify = 7;
	const int LeaveNotify = 8;
	const int FocusIn = 9;
	const int FocusOut = 10;
	const int KeymapNotify = 11;
	const int Expose = 12;
	const int GraphicsExpose = 13;
	const int NoExpose = 14;
	const int VisibilityNotify = 15;
	const int CreateNotify = 16;
	const int DestroyNotify = 17;
	const int UnmapNotify = 18;
	const int MapNotify = 19;
	const int MapRequest = 20;
	const int ReparentNotify = 21;
	const int ConfigureNotify = 22;
	const int ConfigureRequest = 23;
	const int GravityNotify = 24;
	const int ResizeRequest = 25;
	const int CirculateNotify = 26;
	const int CirculateRequest = 27;
	const int PropertyNotify = 28;
	const int SelectionClear = 29;
	const int SelectionRequest = 30;
	const int SelectionNotify = 31;
	const int ColormapNotify = 32;
	const int ClientMessage = 33;
	const int MappingNotify = 34;
	const int GenericEvent = 35;
	const int LASTEvent = 36;

	struct XKeyEvent {
		int type;	/* of event */
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;	 /* "event" window it is reported relative to */
		Window root;	 /* root window that the event occurred on */
		Window subwindow;	/* child window */
		Time time;	/* milliseconds */
		int x, y;	/* pointer x, y coordinates in event window */
		int x_root, y_root;	/* coordinates relative to root */
		uint state;	/* key or button mask */
		uint keycode;	/* detail */
		Bool same_screen;	/* same screen flag */
	}
	alias XKeyEvent XKeyPressedEvent;
	alias XKeyEvent XKeyReleasedEvent;
	
	struct XButtonEvent {
		int type;	/* of event */
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;	 /* "event" window it is reported relative to */
		Window root;	 /* root window that the event occurred on */
		Window subwindow;	/* child window */
		Time time;	/* milliseconds */
		int x, y;	/* pointer x, y coordinates in event window */
		int x_root, y_root;	/* coordinates relative to root */
		uint state;	/* key or button mask */
		uint button;	/* detail */
		Bool same_screen;	/* same screen flag */
	}
	alias XButtonEvent XButtonPressedEvent;
	alias XButtonEvent XButtonReleasedEvent;
	
	struct XMotionEvent {
		int type;	/* of event */
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;	 /* "event" window reported relative to */
		Window root;	 /* root window that the event occurred on */
		Window subwindow;	/* child window */
		Time time;	/* milliseconds */
		int x, y;	/* pointer x, y coordinates in event window */
		int x_root, y_root;	/* coordinates relative to root */
		uint state;	/* key or button mask */
		char is_hint;	/* detail */
		Bool same_screen;	/* same screen flag */
	}
	alias XMotionEvent XPointerMovedEvent;
	
	struct XCrossingEvent {
		int type;	/* of event */
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;	 /* "event" window reported relative to */
		Window root;	 /* root window that the event occurred on */
		Window subwindow;	/* child window */
		Time time;	/* milliseconds */
		int x, y;	/* pointer x, y coordinates in event window */
		int x_root, y_root;	/* coordinates relative to root */
		int mode;	/* NotifyNormal, NotifyGrab, NotifyUngrab */
		int detail;
		/*
		 * NotifyAncestor, NotifyVirtual, NotifyInferior,
		 * NotifyNonlinear,NotifyNonlinearVirtual
		 */
		Bool same_screen;	/* same screen flag */
		Bool focus;	/* boolean focus */
		uint state;	/* key or button mask */
	}
	alias XCrossingEvent XEnterWindowEvent;
	alias XCrossingEvent XLeaveWindowEvent;
	
	struct XFocusChangeEvent {
		int type;	/* FocusIn or FocusOut */
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;	/* window of event */
		int mode;	/* NotifyNormal, NotifyWhileGrabbed,
		 NotifyGrab, NotifyUngrab */
		int detail;
		/*
		 * NotifyAncestor, NotifyVirtual, NotifyInferior,
		 * NotifyNonlinear,NotifyNonlinearVirtual, NotifyPointer,
		 * NotifyPointerRoot, NotifyDetailNone
		 */
	}
	alias XFocusChangeEvent XFocusInEvent;
	alias XFocusChangeEvent XFocusOutEvent;

	/* generated on EnterWindow and FocusIn when KeyMapState selected */
	struct XKeymapEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;
		char key_vector[32];
	}

	struct XExposeEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;
		int x, y;
		int width, height;
		int count;	/* if non-zero, at least this many more */
	}
	
	struct XGraphicsExposeEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Drawable drawable;
		int x, y;
		int width, height;
		int count;	/* if non-zero, at least this many more */
		int major_code;	/* core is CopyArea or CopyPlane */
		int minor_code;	/* not defined in the core */
	}
	
	struct XNoExposeEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Drawable drawable;
		int major_code;	/* core is CopyArea or CopyPlane */
		int minor_code;	/* not defined in the core */
	}
	
	struct XVisibilityEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window window;
		int state;	/* Visibility state */
	}
	
	struct XCreateWindowEvent {
		int type;
		c_ulong serial;	/* # of last request processed by server */
		Bool send_event;	/* true if this came from a SendEvent request */
		Display *display;	/* Display the event was read from */
		Window parent;	/* parent of the window */
		Window window;	/* window id of window created */
		int x, y;	/* window location */
		int width, height;	/* size of window */
		int border_width;	/* border width */
		Bool override_redirect;	/* creation should be overridden */
	}
	
	struct XDestroyWindowEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	}
	
	struct XUnmapEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Bool from_configure;
	}
	
	struct XMapEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Bool override_redirect;	/* boolean, is override set... */
	}
	
	struct XMapRequestEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
	}
	
	struct XReparentEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Window parent;
	int x, y;
	Bool override_redirect;
	}

	struct XConfigureEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	Bool override_redirect;
	}

	struct XGravityEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	int x, y;
	}
	
	struct XResizeRequestEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	int width, height;
	}

	struct XConfigureRequestEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	int detail;	/* Above, Below, TopIf, BottomIf, Opposite */
	c_ulong value_mask;
	}
	
	struct XCirculateEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	int place;	/* PlaceOnTop, PlaceOnBottom */
	}

	struct XCirculateRequestEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
	int place;	/* PlaceOnTop, PlaceOnBottom */
	}
	
	struct XPropertyEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom atom;
	Time time;
	int state;	/* NewValue, Deleted */
	}

	struct XSelectionClearEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom selection;
	Time time;
	}

	struct XSelectionRequestEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window owner;
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;
	Time time;
	}

	struct XSelectionEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;	/* ATOM or None */
	Time time;
	}
	
	struct XColormapEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Colormap colormap;	/* COLORMAP or None */
	Bool c_new;	/* C++ */
	int state;	/* ColormapInstalled, ColormapUninstalled */
	}
	
	struct XClientMessageEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom message_type;
	int format;
	union data {
	char b[20];
	short s[10];
	c_long l[5];
	};
	}

	struct XMappingEvent{
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;	/* unused */
	int request;	/* one of MappingModifier, MappingKeyboard,
	 MappingPointer */
	int first_keycode;	/* first keycode */
	int count;	/* defines range of change w. first_keycode*/
	}
	
	struct XErrorEvent {
	int type;
	Display *display;	/* Display the event was read from */
	XID resourceid;	/* resource id */
	c_ulong serial;	/* serial number of failed request */
	byte error_code;	/* error code of failed request */
	byte request_code;	/* Major op-code of failed request */
	byte minor_code;	/* Minor op-code of failed request */
	}

	struct XAnyEvent {
	int type;
	c_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;/* Display the event was read from */
	Window window;	/* window on which event was requested in event mask */
	}

 	struct XGenericEvent {
	int type; /* of event. Always GenericEvent */
	c_ulong serial; /* # of last request processed */
	Bool send_event; /* true if from SendEvent request */
	Display *display; /* Display the event was read from */
	int extension; /* major opcode of extension that caused the event */
	int evtype; /* actual event type. */
	}

	struct XGenericEventCookie {
	int type; /* of event. Always GenericEvent */
	c_ulong serial; /* # of last request processed */
	Bool send_event; /* true if from SendEvent request */
	Display *display; /* Display the event was read from */
	int extension; /* major opcode of extension that caused the event */
	int evtype; /* actual event type. */
	uint cookie;
	void *data;
	}
	
	union XEvent {
	int type;
	XAnyEvent xany;
	XKeyEvent xkey;
	XButtonEvent xbutton;
	XMotionEvent xmotion;
	XCrossingEvent xcrossing;
	XFocusChangeEvent xfocus;
	XExposeEvent xexpose;
	XGraphicsExposeEvent xgraphicsexpose;
	XNoExposeEvent xnoexpose;
	XVisibilityEvent xvisibility;
	XCreateWindowEvent xcreatewindow;
	XDestroyWindowEvent xdestroywindow;
	XUnmapEvent xunmap;
	XMapEvent xmap;
	XMapRequestEvent xmaprequest;
	XReparentEvent xreparent;
	XConfigureEvent xconfigure;
	XGravityEvent xgravity;
	XResizeRequestEvent xresizerequest;
	XConfigureRequestEvent xconfigurerequest;
	XCirculateEvent xcirculate;
	XCirculateRequestEvent xcirculaterequest;
	XPropertyEvent xproperty;
	XSelectionClearEvent xselectionclear;
	XSelectionRequestEvent xselectionrequest;
	XSelectionEvent xselection;
	XColormapEvent xcolormap;
	XClientMessageEvent xclient;
	XMappingEvent xmapping;
	XErrorEvent xerror;
	XKeymapEvent xkeymap;
	XGenericEvent xgeneric;
	XGenericEventCookie xcookie;
	c_long pad[24];
	}
	
}
