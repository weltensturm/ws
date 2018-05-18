module ws.gui.inputField;

import
	std.conv,
	ws.event,
	ws.io,
	ws.time,
	ws.math.math,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.text;


class InputField: Base {
	
	bool hasFocus = false;
	Event!string onEnter;

	string rawText;
	size_t cursor;

	string error;
	double errorTime;
	bool blockChar;
	string font;
	size_t fontSize;

	this(){
		setCursor(Mouse.cursor.text);
		onEnter = new Event!string;
	}

	string text(){
		return rawText;
	}

	void text(string text){
		rawText = text;
		cursor = cursor.min(text.length).max(0);
	}

	void setFont(string font, size_t size){
		this.font = font;
		this.fontSize = size;
	}

	override void onKeyboard(dchar c){
		if(!blockChar){
			text = text[0..cursor] ~ c.to!string ~ text[cursor..$];
			cursor++;
			blockChar = false;
		}
	}

	override void onKeyboard(Keyboard.key key, bool pressed){
		if(!pressed)
			return;
		blockChar = true;
		switch(key){
			case Keyboard.backspace:
				if(cursor > 0){
					rawText = rawText[0..cursor-1] ~ rawText[cursor..$];
					cursor--;
				}
				break;
				
			case Keyboard.del:
				if(cursor < rawText.length){
					rawText = rawText[0..cursor] ~ rawText[cursor+1..$];
				}
				break;
				
			case Keyboard.enter:
				try
					onEnter(rawText);
				catch(InputException e){
					error = e.msg;
					errorTime = now;
				}
				break;
				
			case Keyboard.right:
				if(Keyboard.get(Keyboard.control))
					while(cursor < rawText.length && rawText[cursor+1] != ' ')
						++cursor;
				else if(cursor < rawText.length)
					++cursor;
				break;
				
			case Keyboard.left:
				if(Keyboard.get(Keyboard.control))
					while(cursor > 0 && rawText[cursor-1] != ' ')
						--cursor;
				else if(cursor > 0)
					--cursor;
				break;
				
			default:
				blockChar = false;
				break;
		}

	}


	override void onKeyboardFocus(bool hasFocus){
		this.hasFocus = hasFocus;
	}


	override void onDraw(){
		auto color = style.fg.normal;
		if(hasFocus || hasMouseFocus){
			auto alpha = (sin(now*PI*2)+0.5).min(1).max(0);
			draw.setColor([1,1,1,alpha]);
			int x = draw.width(text[0..cursor]);
			draw.rect(pos.a + [x+4, 4], [1, size.h-8]);
		}
		auto t = now;
		if(errorTime+2 > t){
			auto alpha = clamp!float(errorTime+2 - t, 0, 1)/1;
			draw.setColor([1,0,0,alpha]);
			draw.rect(pos, size);
			draw.setFont("Consolas", 9);
			draw.setColor([1,1,1,alpha]);
			draw.text(pos.a + [2, 0], size.h, error);
		}
		draw.setColor([1,1,1]);
		draw.text(pos, size.h, text);
	}


}


class InputException: Exception {
	InputField text;
	this(InputField t, string msg, string file = __FILE__, size_t line = __LINE__){
		text = t;
		super(msg, null, file, line);
	}
	this(InputField t, string msg, Exception cause, string file = __FILE__, size_t line = __LINE__){
		text = t;
		super(msg, cause, file, line);
	}
}
