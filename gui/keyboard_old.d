
module ws.gui.keyboard_old;

import io = ws.io;

version(linux){
	import X11.keysymdef;
}

class keyboard {
	
	alias ushort key;
	
	version(Windows){
		enum: key {
			shift = 16,
			control = 17,
			caps = 20,
			win = 91,
			escape = 27,
			enter = 13,
			backspace = 8,
			space = 32,
			del = 46,
			
			left = 37,
			up = 38,
			right = 39,
			down = 40
		}
	}
	version(linux){
		enum: key {
			
			shift = cast(key)XK_Shift_L,
			shiftR = cast(key)XK_Shift_R,
			control = cast(key)XK_Control_L,
			controlR = cast(key)XK_Control_R,
			caps = cast(key)XK_Caps_Lock,
			win = cast(key)XK_Super_L,
			winR = cast(key)XK_Super_R,

			escape =	cast(key)XK_Escape,
			enter = cast(key)XK_Return,

			backspace = cast(key)XK_BackSpace,
			space = cast(key)XK_space,
			del = cast(key)XK_Delete,

			left = cast(key)XK_Left,
			up = cast(key)XK_Up,
			right = cast(key)XK_Right,
			down = cast(key)XK_Down,

		}
	}
	
	static bool get(key i){
		return chars[i];
	}
	
	static void set(key i, bool p){
		chars[i] = p;
	}
	
	private static bool[key.max] chars = [false];
	
}
