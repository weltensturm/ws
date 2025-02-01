module ws.bindings.xlib;

import std.math;
public import ws.bindings.c_xlib;


alias Status = XStatus;
alias Bool = XBool;

alias abs = std.math.abs;

static XFixed XDoubleToFixed(double d) {
    return cast(XFixed)(d * 65536);
}

alias XEvent = ws.bindings.c_xlib.XEvent;
alias Damage = CARD32;

