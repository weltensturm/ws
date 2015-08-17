module ws.gui.button;

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

	Text title;
	bool pressed;
	bool mouseFocus;
	string m_font = "sans";
	int m_font_size = 12;

	@property string font(string s=""){
		if(s.length){
			m_font = s;
			title.setFont(m_font, m_font_size);
		}
		return m_font;
	}

	@property int fontSize(int i=0){
		if(i > 0){
			m_font_size = i;
			title.setFont(m_font, m_font_size);
		}
		return m_font_size;
	}

	@property void text(string s){
		title.text = s;
	}

	@property string text(){
		return title.text;
	}

	this(string t){
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
		title = addNew!Text;
		title.text = t;
		setStyle(style);
	}


	override void setStyle(Style style){
		super.setStyle(style);
		title.style = style;
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
		super.onDraw();
	}

	override void resize(int[2] size){
		title.resize(size);
		fontSize = cast(int)(size.h/1.8);
		super.resize(size);
	}

	override void onMouseButton(Mouse.button button, bool p, int x, int y){
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
	}


}

