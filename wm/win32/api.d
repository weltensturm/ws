module ws.wm.win32.api;

public import
	derelict.opengl3.gl3,
	derelict.opengl3.wgl,
	core.sys.windows.windows;

__gshared:

version(Windows):


extern(Windows){

	alias WindowHandle = HWND;
	
	alias Context = HGLRC;
	
	struct Event {
		UINT msg;
		WPARAM wpar;
		LPARAM lpar;
	}

	struct RAWMOUSE {
		USHORT usFlags;
		union {
			ULONG  ulButtons;
			struct {
				USHORT usButtonFlags;
				USHORT usButtonData;
			};
		};
		ULONG  ulRawButtons;
		LONG   lLastX;
		LONG   lLastY;
		ULONG  ulExtraInformation;
	}

	struct RAWKEYBOARD {
		USHORT MakeCode;
		USHORT Flags;
		USHORT Reserved;
		USHORT VKey;
		UINT   Message;
		ULONG  ExtraInformation;
	}

	struct RAWHID {
		DWORD dwSizeHid;
		DWORD dwCount;
		BYTE  bRawData[1];
	}

	struct RAWINPUTHEADER {
		DWORD  dwType;
		DWORD  dwSize;
		HANDLE hDevice;
		WPARAM wParam;
	}

	struct RAWINPUT {
		RAWINPUTHEADER header;
		union {
			RAWMOUSE    mouse;
			RAWKEYBOARD keyboard;
			RAWHID      hid;
		}
	}

	alias RAWINPUT* HRAWINPUT;

	UINT GetRawInputData(
		HRAWINPUT hRawInput,
		UINT uiCommand,
		LPVOID pData,
		PUINT pcbSize,
		UINT cbSizeHeader
	);

	BOOL RegisterRawInputDevices(RAWINPUTDEVICE* pRawInputDevices, UINT uiNumDevices, UINT cbSize);


	const int WM_INPUT = 0x00FF;
	const int RID_INPUT = 0x10000003;
	const int RIM_TYPEMOUSE = 0;
	const int RIDEV_INPUTSINK = 0x00000100;

	HWND GetTopWindow(void*);
	HWND GetWindow(void*, uint);
	
	int GetWindowTextW(HWND, LPWSTR, int);
	
	DWORD GetWindowThreadProcessId(HWND, DWORD*);
	void SwitchToThisWindow(HWND, BOOL);

	alias nothrow BOOL function(HDC, const(int)*, const(FLOAT)*, UINT, int*, UINT*) T_wglChoosePixelFormatARB;
	alias nothrow HGLRC function(HDC, HGLRC, const(int)*) T_wglCreateContextAttribsARB;
	
	nothrow BOOL SetWindowTextW(HWND,LPCWSTR);  
	nothrow HANDLE CreateWindowExW(DWORD,LPCWSTR,LPCWSTR,DWORD,int,int,int,int,HWND,HMENU,HINSTANCE,LPVOID);
	nothrow LRESULT DefWindowProcW(HWND,UINT,WPARAM,LPARAM);
	DWORD SetClassLongW(HWND,int,LONG);

	int ChoosePixelFormat(HDC, const PIXELFORMATDESCRIPTOR*);
	int DestroyWindow(void*);
	uint glewInit();

	BOOL SwapBuffers(HDC);

	ATOM RegisterClassW(const(WNDCLASSW)*);
	struct WNDCLASSW {
		uint style;
		WNDPROC lpfnWndProc;
		int cbClsExtra;
		int cbWndExtra;
		HINSTANCE hInstance;
		HICON hIcon;
		HCURSOR hCursor;
		HBRUSH hbrBackground;
		LPCWSTR lpszMenuName;
		LPCWSTR lpszClassName;
	}
	
	BOOL SendNotifyMessageA(HWND,UINT,WPARAM,LPARAM);
	
	struct TRACKMOUSEEVENT {
		DWORD cbSize;
		DWORD dwFlags;
		HWND  hwndTrack;
		DWORD dwHoverTime;
	};

	struct RAWINPUTDEVICE {
		USHORT usUsagePage;
		USHORT usUsage;
		DWORD	dwFlags;
		HWND   hwndTarget;
	}

	BOOL TrackMouseEvent(TRACKMOUSEEVENT*);
	const int WM_MOUSELEAVE = 0x2A3;
	const int WM_MOUSEWHEEL = 522;
	
	int GET_WHEEL_DELTA_WPARAM(WPARAM w){
		return (cast(WORD)(((cast(DWORD)w)>>16)&0xFFFF));
	}
	int GET_X_LPARAM(LPARAM l){
		return (cast(int)cast(short)(cast(WORD)(cast(DWORD)l)));
	}
	int GET_Y_LPARAM(LPARAM l){
		return (cast(int)(cast(WORD)((cast(DWORD)l>>16)&0xFFFF)));
	}

		short GetKeyState(int nVirtKey);


	HWND FindWindowW(LPCWSTR lpClassName, LPCWSTR lpWindowName);

	BOOL PostMessageA(
		HWND hWnd,
		UINT Msg,
		WPARAM wParam,
		LPARAM lParam
	);


}
