
module ws.gui.mouse_old;

__gshared:

static class mouse {
	alias int button;
	
	static const {
		button buttonLeft = 1;
		button buttonRight = 2;
		button buttonMiddle = 4;
		version(Posix){
			button wheelUp = 5;
			button wheelDown = 6;
			button button4 = 7;
			button button5 = 8;
		}else{
			button wheelUp = 10;
			button wheelDown = 11;
			button button4 = 5;
			button button5 = 6;
		}
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
