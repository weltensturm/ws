module composite.xpresent;

import
    x11.X,
    x11.Xlib,
    x11.extensions.Xrandr;


extern(C):


/*
 * Copyright © 2013 Keith Packard
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that copyright
 * notice and this permission notice appear in supporting documentation, and
 * that the name of the copyright holders not be used in advertising or
 * publicity pertaining to distribution of the software without specific,
 * written prior permission.  The copyright holders make no representations
 * about the suitability of this software for any purpose.  It is provided "as
 * is" without express or implied warranty.
 *
 * THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 * EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THIS SOFTWARE.
 */

/*
 * This revision number also appears in configure.ac, they have
 * to be manually synchronized
 */
enum PRESENT_MAJOR = 1;
enum PRESENT_MINOR = 2;
enum PRESENT_REVISION = 0;
enum PRESENT_VERSION = ((PRESENT_MAJOR * 10_000) + (PRESENT_MINOR * 100) + (PRESENT_REVISION));

/**
 * Generic Present event. All Present events have the same header.
 */

private alias uint8_t = ubyte;
private alias uint32_t = uint;
private alias uint64_t = ulong;
private alias XSyncFence = uint32_t;
private alias XserverRegion = XID;

enum PresentNumberErrors = 0;
enum PresentNumberEvents = 0;

/* Requests */
enum X_PresentQueryVersion = 0;
enum X_PresentPixmap = 1;
enum X_PresentNotifyMSC = 2;
enum X_PresentSelectInput = 3;
enum X_PresentQueryCapabilities = 4;

enum PresentNumberRequests = 5;

/* Present operation options */
enum PresentOptionNone = 0;
enum PresentOptionAsync = (1 << 0);
enum PresentOptionCopy = (1 << 1);
enum PresentOptionUST = (1 << 2);
enum PresentOptionSuboptimal = (1 << 3);

enum PresentAllOptions = (PresentOptionAsync |
                           PresentOptionCopy |
                           PresentOptionUST |
                           PresentOptionSuboptimal);

/* Present capabilities */

enum PresentCapabilityNone = 0;
enum PresentCapabilityAsync = 1;
enum PresentCapabilityFence = 2;
enum PresentCapabilityUST = 4;

enum PresentAllCapabilities = (PresentCapabilityAsync |
                                 PresentCapabilityFence |
                                 PresentCapabilityUST);

/* Events */

enum PresentConfigureNotify = 0;
enum PresentCompleteNotify = 1;
enum PresentIdleNotify = 2;
version(PRESENT_FUTURE_VERSION)
    enum PresentRedirectNotify = 3;



/* Event Masks */
enum PresentConfigureNotifyMask = 1;
enum PresentCompleteNotifyMask = 2;
enum PresentIdleNotifyMask = 4;
version(PRESENT_FUTURE_VERSION)
    enum PresentRedirectNotifyMask = 8;



version(PRESENT_FUTURE_VERSION)
    enum PRESENT_REDIRECT_NOTIFY_MASK = PresentRedirectNotifyMask;
else
    enum PRESENT_REDIRECT_NOTIFY_MASK = 0;

enum PresentAllEvents = (PresentConfigureNotifyMask |
                            PresentCompleteNotifyMask |
                            PresentIdleNotifyMask |
                            PRESENT_REDIRECT_NOTIFY_MASK);

/* Complete Kinds */

enum PresentCompleteKindPixmap = 0;
enum PresentCompleteKindNotifyMSC = 1;

/* Complete Modes */

enum PresentCompleteModeCopy = 0;
enum PresentCompleteModeFlip = 1;
enum PresentCompleteModeSkip = 2;
enum PresentCompleteModeSuboptimalCopy = 3;


struct XPresentNotify {
    Window      window;
    uint32_t    serial;
}

struct XPresentEvent {
    int type;			/* event base */
    ulong serial;
    Bool send_event;
    Display *display;
    int extension;
    int evtype;
}

struct XPresentConfigureNotifyEvent {
    int type;			/* event base */
    ulong serial;
    Bool send_event;
    Display *display;
    int extension;
    int evtype;

    uint32_t eid;
    Window window;
    int x,y;
    uint width, height;
    int off_x, off_y;
    int pixmap_width, pixmap_height;
    long pixmap_flags;
}

struct XPresentCompleteNotifyEvent {
    int type;			/* event base */
    ulong serial;
    Bool send_event;
    Display *display;
    int extension;
    int evtype;

    uint32_t eid;
    Window window;
    uint32_t serial_number;
    uint64_t ust;
    uint64_t msc;
    uint8_t kind;
    uint8_t mode;
}

struct XPresentIdleNotifyEvent {
    int type;			/* event base */
    ulong serial;
    Bool send_event;
    Display *display;
    int extension;
    int evtype;

    uint32_t eid;
    Window window;
    uint32_t serial_number;
    Pixmap pixmap;
    XSyncFence idle_fence;
}

version(PRESENT_FUTURE_VERSION){

struct XPresentRedirectNotifyEvent {
    int type;			/* event base */
    ulong serial;
    Bool send_event;
    Display *display;
    int extension;
    int evtype;

    uint32_t eid;
    Window event_window;

    Window window;
    Pixmap pixmap;
    uint32_t serial_number;

    XserverRegion valid_region;
    XserverRegion update_region;

    XRectangle valid_rect;
    XRectangle update_rect;

    int x_off, y_off;

    RRCrtc target_crtc;

    XSyncFence wait_fence;
    XSyncFence idle_fence;

    uint32_t options;

    uint64_t target_msc;
    uint64_t divisor;
    uint64_t remainder;
    XPresentNotify *notifies;
    int nnotifies;
}

}

Bool XPresentQueryExtension (Display *dpy,
                             int *major_opcode_return,
                             int *event_base_return,
                             int *error_base_return);

Status XPresentQueryVersion (Display *dpy,
			    int     *major_version_return,
			    int     *minor_version_return);

int XPresentVersion();

void
XPresentPixmap(Display *dpy,
               Window window,
               Pixmap pixmap,
               uint32_t serial,
               XserverRegion valid,
               XserverRegion update,
               int x_off,
               int y_off,
               RRCrtc target_crtc,
               XSyncFence wait_fence,
               XSyncFence idle_fence,
               uint32_t options,
               uint64_t target_msc,
               uint64_t divisor,
               uint64_t remainder,
               XPresentNotify *notifies,
               int nnotifies);

void
XPresentNotifyMSC(Display *dpy,
                  Window window,
                  uint32_t serial,
                  uint64_t target_msc,
                  uint64_t divisor,
                  uint64_t remainder);

XID
XPresentSelectInput(Display *dpy,
                    Window window,
                    uint event_mask);

void
XPresentFreeInput(Display *dpy,
                  Window window,
                  XID event_id);

uint32_t
XPresentQueryCapabilities(Display *dpy,
                          XID target);
