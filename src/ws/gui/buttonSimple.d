module ws.gui.buttonSimple;

import
	ws.event,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.style,
	ws.gui.textSimple,
	ws.gui.point;


class Button: Base {
	
	Event!() leftClick;
	Event!() rightClick;

	string text;
	bool pressed;
	bool mouseFocus;
	string font = "sans";
	int fontSize = 12;

	this(string text){
		leftClick = new Event!();
		rightClick = new Event!();
		Style style;
		style.bg = Color(
				[0.1, 0.1, 0.1, 0.5],
				[0.2, 0.2, 0.2, 0.7],
				[0.2, 0.2, 0.2, 1],
		);
		style.fg = Color(
				[1, 1, 1, 0.9],
				[1, 1, 1, 1],
				[1, 1, 1, 1]
		);
		this.text = text;
		setStyle(style);
	}


	override void setStyle(Style style){
		super.setStyle(style);
	}


	override void onDraw(){
		draw.setColor(pressed ? style.bg.active :
				(mouseFocus ? style.bg.hover
						: style.bg.normal));
		draw.rect(pos, size);
		/+
		draw.setColor(pressed ? style.fg.active :
				(mouseFocus ? style.fg.hover
						: style.fg.normal));
		+/
		draw.setColor(style.fg);
		draw.setFont(font, fontSize);
		draw.text(pos, size.h, text);
		super.onDraw();
	}


	override void onMouseButton(Mouse.button button, bool p, int x, int y){
		super.onMouseButton(button, p, x, y);
		if(!p && pressed){
			if(button == Mouse.buttonLeft)
				leftClick();
			else if(button == Mouse.buttonRight)
				rightClick();
			pressed = false;
		}
		pressed = p;
	}
	
	
	override void onMouseFocus(bool focus){
		mouseFocus = focus;
		if(!focus)
			pressed = false;
		super.onMouseFocus(focus);
	}


}

