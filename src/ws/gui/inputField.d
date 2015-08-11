module ws.gui.inputField;

import
	ws.event,
	ws.io,
	ws.time,
	ws.math.math,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.text;


class InputField: Text {
	
	bool hasFocus = false;
	Event!string onEnter;

	string error;
	double errorTime;
	bool blockChar;

	this(){
		super();
		setCursor(Mouse.cursor.text);
		onEnter = new Event!string;
	}

	override void onKeyboard(dchar c){
		if(hasFocus && !blockChar){
			text ~= c;
			blockChar = false;
		}
	}

	override void onKeyboard(Keyboard.key key, bool pressed){
		if(!pressed)
			return;
		blockChar = true;
		switch(key){
			case Keyboard.backspace:
				if(text.cursor.prev){
					auto toDelete = text.cursor.prev;
					text.cursor.prev = toDelete.prev;
					text.remove(toDelete);
					text.update(text.cursor.prev);
				}
				break;
				
			case Keyboard.del:
				if(text.cursor.next){
					auto toDelete = text.cursor.next;
					text.cursor.next = toDelete.next;
					text.remove(toDelete);
					text.update(text.cursor.prev);
				}
				break;
				
			case Keyboard.enter:
				try
					onEnter(text.toString());
				catch(InputException e){
					error = e.msg;
					errorTime = time.now;
				}
				break;
				
			case Keyboard.right:
				if(Keyboard.get(Keyboard.control))
					while(text.cursor.next && text.cursor.next.get().c != ' ')
						++text.cursor;
				else
					++text.cursor;
				break;
				
			case Keyboard.left:
				if(Keyboard.get(Keyboard.control))
					while(text.cursor.prev && text.cursor.prev.get().c != ' ')
						--text.cursor;
				else
					--text.cursor;
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
		super.onDraw();
		auto color = style.fg.normal;
		if(hasFocus){
			Draw.setColor(color[0], color[1], color[2], color[3]*clamp!float(sin(time.now*PI*2) + 0.5, 0, 1));
			if(!text.cursor.prev)
				Draw.line(pos[0] + 4, pos[1] + 3, pos[0] + 4, pos[1] + size[1]-2);
			else {
				auto lpos =
						pos.a + text.cursor.prev.get().pos
						+ [text.cursor.prev.get().glyph.advance+2, -2];
				draw.line(lpos, lpos.a + [0, size[1]-4]);
			}
		}
		auto t = time.now;
		if(errorTime+2 > t){
			auto alpha = clamp!float(errorTime+2 - t, 0, 1)/1;
			Draw.setColor(1,0,0,alpha);
			Draw.rect(pos, size);
			Draw.setFont(font);
			Draw.setColor(1,1,1,alpha);
			Draw.text(pos.a + [2, cast(int)(font.size*0.6)], error);
		}
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
