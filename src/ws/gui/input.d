
module ws.gui.input;

import io = ws.io;
import std.conv;

version(linux) {
	import ws.bindings.xlib;
}

version(Windows)
	import core.sys.windows.windows;


enum Keys = [
    "buttonLeft": Mouse.buttonLeft,
    "buttonRight": Mouse.buttonRight,
    "buttonMiddle": Mouse.buttonMiddle,
    "wheelUp": Mouse.wheelUp,
    "wheelDown": Mouse.wheelDown,
    "button4": Mouse.button4,
    "button5": Mouse.button5,
    
    "shift": Keyboard.shift,
    "control": Keyboard.control,
    "caps": Keyboard.caps,
    "win": Keyboard.win,
    "escape": Keyboard.escape,
    "enter": Keyboard.enter,
    "backspace": Keyboard.backspace,
    "space": Keyboard.space,
    "delete": Keyboard.del,
    "left": Keyboard.left,
    "right": Keyboard.right,
    "up": Keyboard.up,
    "down": Keyboard.down
];


static class Mouse {
	alias int button;
	
	static const {
		version(Posix){
			button buttonLeft = 1;
			button buttonRight = 3;
			button buttonMiddle = 2;
			button wheelUp = 4;
			button wheelDown = 5;
			button button4 = 8;
			button button5 = 9;
		}else{
			button buttonLeft = 1;
			button buttonRight = 2;
			button buttonMiddle = 4;
			button wheelUp = 10;
			button wheelDown = 11;
			button button4 = 5;
			button button5 = 6;
		}
		int X = 5500;
		int Y = 5501;
	}
	
	enum cursor {
		arrow,
		inverted,
		text,
		sizeAll,
		sizeVert,
		sizeHoriz,
		pointTR,
		pointTL,
		pointBR,
		pointBL,
		hand,
		inherit,
		none
	}
}

struct KeySym {
	alias Type = ulong;
	Type keysym;
}

struct KeyCode {
	alias Type = uint;
	Type keycode;
}

static class Keyboard {
	
	version(Windows){
		enum: KeySym.Type {
			shift = KeySym(16),
			control = KeySym(17),
			caps = KeySym(20),
			win = KeySym(91),
			escape = KeySym(27),
			enter = KeySym(13),
			backspace = KeySym(8),
			space = KeySym(32),
			del = KeySym(46),
			
			left = KeySym(37),
			up = KeySym(38),
			right = KeySym(39),
			down = KeySym(40)
		}
	}
	version(linux){
		enum: KeySym.Type {
			
			shift = XK_Shift_L,
			shiftR = XK_Shift_R,
			control = XK_Control_L,
			controlR = XK_Control_R,
			caps = XK_Caps_Lock,
			win = XK_Super_L,
			winR = XK_Super_R,

			escape =	XK_Escape,
			enter = XK_Return,

			backspace = XK_BackSpace,
			space = XK_space,
			del = XK_Delete,

			left = XK_Left,
			up = XK_Up,
			right = XK_Right,
			down = XK_Down,

		}
	}
	
	static bool get(ulong i){
		return keys[i];
	}
	
	static void set(ulong i, bool p){
		keys[i] = p;
	}
	
	static void emulate(KeyCode k, bool p){
		version(Windows){
			if(keys[k] == p)
				return;
			keys[k] = p;
			INPUT ip;
			ip.type = INPUT_KEYBOARD;
			ip.ki.wScan = 0;
			ip.ki.time = 0;
			ip.ki.dwExtraInfo = 0;
			ip.ki.wVk = k.to!ushort;
			ip.ki.dwFlags = (p ? 0 : KEYEVENTF_KEYUP);
			SendInput(1, &ip, INPUT.sizeof);
		}
	}

	protected {
		static bool[ulong] keys;
	}
	
}


version(Windows)
extern(Windows){

	uint SendInput(uint cInputs, INPUT* pInputs, int cbSize);

	struct INPUT {
		DWORD type;
		union {
			MOUSEINPUT	  mi;
			KEYBDINPUT	  ki;
			HARDWAREINPUT   hi;
		};
	}

	struct MOUSEINPUT {
		LONG	dx;
		LONG	dy;
		DWORD   mouseData;
		DWORD   dwFlags;
		DWORD   time;
		ULONG_PTR dwExtraInfo;
	}

	struct KEYBDINPUT {
		WORD	wVk;
		WORD	wScan;
		DWORD   dwFlags;
		DWORD   time;
		ULONG_PTR dwExtraInfo;
	}

	struct HARDWAREINPUT {
		DWORD   uMsg;
		WORD	wParamL;
		WORD	wParamH;
	}

	const int INPUT_KEYBOARD = 1;
	const int KEYEVENTF_KEYUP = 2;

}

