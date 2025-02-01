
#define abs _c_abs
#define min _c_min
#define max _c_max

#include "X11/Xmd.h"
#include "X11/X.h"
#include "X11/Xlib.h"
#include "X11/Xatom.h"
#include "X11/Xft/Xft.h"
#include "X11/cursorfont.h"
#include "X11/Xprotostr.h"
#include "X11/extensions/Xdbe.h"
#include "X11/extensions/sync.h"
#include "X11/extensions/render.h"
#include "X11/extensions/presentproto.h"
#include "X11/extensions/Xpresent.h"
#include "X11/extensions/xfixesproto.h"
#include "X11/extensions/Xfixes.h"
#include "X11/extensions/Xinerama.h"
#include "X11/extensions/Xcomposite.h"
#include "X11/extensions/Xdamage.h"
#include "X11/extensions/damageproto.h"

#define XK_MISCELLANY
#define XK_LATIN1
#include "X11/keysymdef.h"

typedef int XBool;
typedef int XStatus;

#undef RevertToPointerRoot
#define RevertToPointerRoot 1

#undef abs
#undef min
#undef max

#undef XDoubleToFixed
