module ws.bindings.Xdbe;


/******************************************************************************
 *
 * Copyright (c) 1994, 1995  Hewlett-Packard Company
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL HEWLETT-PACKARD COMPANY BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Except as contained in this notice, the name of the Hewlett-Packard
 * Company shall not be used in advertising or otherwise to promote the
 * sale, use or other dealings in this Software without prior written
 * authorization from the Hewlett-Packard Company.
 *
 *     Header file for Xlib-related DBE
 *
 *****************************************************************************/


version(Posix):


extern(C):


public import x11.X, x11.Xlib;


/* Values for swap_action field of XdbeSwapInfo structure */
enum XdbeUndefined =    0;
enum XdbeBackground =   1;
enum XdbeUntouched =    2;
enum XdbeCopied =       3;

/* Errors */
enum XdbeBadBuffer =    0;

enum DBE_PROTOCOL_NAME = "DOUBLE-BUFFER";

/* Current version numbers */
enum DBE_MAJOR_VERSION =       1;
enum DBE_MINOR_VERSION =       0;

/* Used when adding extension; also used in Xdbe macros */
enum DbeNumberEvents =         0;
enum DbeBadBuffer =            0;
enum DbeNumberErrors =         (DbeBadBuffer + 1);


struct XdbeVisualInfo {
    VisualID    visual;    /* one visual ID that supports double-buffering */
    int         depth;     /* depth of visual in bits                      */
    int         perflevel; /* performance level of visual                  */
}

struct XdbeScreenVisualInfo {
    int                 count;          /* number of items in visual_depth   */
    XdbeVisualInfo      *visinfo;       /* list of visuals & depths for scrn */
}

alias XdbeBackBuffer = Drawable;

alias XdbeSwapAction = ubyte;

struct XdbeSwapInfo {
    Window      swap_window;    /* window for which to swap buffers   */
    XdbeSwapAction  swap_action;    /* swap action to use for swap_window */
}

struct XdbeBackBufferAttributes {
    Window  window;         /* window that buffer belongs to */
}

struct XdbeBufferError {
    int         type;
    Display     *display;   /* display the event was read from */
    XdbeBackBuffer  buffer;     /* resource id                     */
    ulong   serial;     /* serial number of failed request */
    ubyte   error_code; /* error base + XdbeBadBuffer      */
    ubyte   request_code;   /* major opcode of failed request  */
    ubyte   minor_code; /* minor opcode of failed request  */
}


Status XdbeQueryExtension(
    Display*        /* dpy                  */,
    int*        /* major_version_return */,
    int*        /* minor_version_return */
);

XdbeBackBuffer XdbeAllocateBackBufferName(
    Display*        /* dpy         */,
    Window      /* window      */,
    XdbeSwapAction  /* swap_action */
);

Status XdbeDeallocateBackBufferName(
    Display*        /* dpy    */,
    XdbeBackBuffer  /* buffer */
);

Status XdbeSwapBuffers(
    Display*        /* dpy         */,
    XdbeSwapInfo*   /* swap_info   */,
    int         /* num_windows */
);

Status XdbeBeginIdiom(
    Display*        /* dpy */
);

Status XdbeEndIdiom(
    Display*        /* dpy */
);

XdbeScreenVisualInfo *XdbeGetVisualInfo(
    Display*        /* dpy               */,
    Drawable*       /* screen_specifiers */,
    int*        /* num_screens       */
);

void XdbeFreeVisualInfo(
    XdbeScreenVisualInfo*   /* visual_info */
);

XdbeBackBufferAttributes *XdbeGetBackBufferAttributes(
    Display*        /* dpy    */,
    XdbeBackBuffer  /* buffer */
);
