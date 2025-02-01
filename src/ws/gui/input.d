
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

static class Keyboard {
	
	alias ulong key;
	
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
	
	static void emulate(key k, bool p){
		version(Windows){
			if(chars[k] == p)
				return;
			chars[k] = p;
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
		static bool[key] chars;
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

