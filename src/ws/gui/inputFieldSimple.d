module ws.gui.inputFieldSimple;

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

	string text;
	long cursor;

	string error;
	double errorTime;
	bool blockChar;

	this(){
		setCursor(Mouse.cursor.text);
		onEnter = new Event!string;
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
					text = text[0..cursor-1] ~ text[cursor..$];
					cursor--;
				}
				break;
				
			case Keyboard.del:
				if(cursor < text.length){
					text = text[0..cursor] ~ text[cursor+1..$];
				}
				break;
				
			case Keyboard.enter:
				try
					onEnter(text);
				catch(InputException e){
					error = e.msg;
					errorTime = time.now;
				}
				break;
				
			case Keyboard.right:
				if(Keyboard.get(Keyboard.control))
					while(cursor < text.length && text[cursor+1] != ' ')
						++cursor;
				else if(cursor < text.length)
					++cursor;
				break;
				
			case Keyboard.left:
				if(Keyboard.get(Keyboard.control))
					while(cursor > 0 && text[cursor-1] != ' ')
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
		draw.setColor([0.867,0.514,0]);
		draw.rectOutline(pos, size);
		auto color = style.fg.normal;
		if(hasFocus || hasMouseFocus){
			auto alpha = (sin(time.now*PI*2)+0.5).min(1).max(0)*0.9+0.1;
			draw.setColor([1*alpha,1*alpha,1*alpha]);
			int x = draw.width(text[0..cursor]);
			draw.rect(pos.a + [x+4, 4], [1, size.h-8]);
		}
		auto t = time.now;
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
