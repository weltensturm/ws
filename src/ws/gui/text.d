module ws.gui.text;

import
	std.utf,
	ws.io,
	ws.list,
	ws.gl.gl,
	ws.gl.draw,
	ws.gl.font,
	ws.gl.shader,
	ws.gui.base;


class Text: Base {

	Font font;
	String text;
	Shader shader;

	this(){
		super();
		style.bg.normal = [0, 0, 0, 0.5];
		style.fg.normal = [1, 1, 1, 1];
		text = new String;
		shader = Shader.load("2d_texture", [gl.attributeVertex: "vVertex", gl.attributeTexture: "vTexture0"]);
		setFont("sans", 11);
	}


	void setFont(string f, int size){
		font = Font.load(f, size);
		text.set(text.toString());
	}


	override void resize(int[2] size){
		super.resize(size);
		text.set(text.toString());
	}


	override void onDraw(){
		if(text.queue.length){
			text ~= text.queue;
			text.queue = "";
		}
		glActiveTexture(GL_TEXTURE0);
		shader.use();
		shader["Screen"].set(draw.screen);
		shader["Image"].set(0);
		shader["Color"].set(style.fg.normal);
		float[3] scale = [1,1,0];
		shader["Scale"].set(scale);
		float[3] fp;
		foreach(g; text){
			if(
				g.c == '\n' || g.pos.x > size.x ||
				g.pos.y < 0 - cast(int)(font.size*1.4) ||
				g.pos.y > size.y || g.pos.x < -g.glyph.advance
			)
				continue;
			glBindTexture(GL_TEXTURE_2D, g.glyph.tex);
			fp = [cast(int)g.pos.x + pos.x, cast(int)g.pos.y + pos.y, 0];
			shader["Offset"].set(fp);
			g.glyph.vao.draw();
		}
	}


	/++
		List of characters (dchar + screen position + OpenGL glyph)
	+/
	class String: List!Character {

		void opOpAssign(string op)(string s) if(op=="~") {
			foreach(dchar c; s)
				this ~= c;
			//return s.toUTF32();
		}

		void opOpAssign(string op)(dchar c) if(op=="~"){
			if(c == '\n')
				lines++;
			if(gl.active()){
				auto character = new Character(c);
				if(!length || !cursor.next){
					push(character);
					cursor.prev = end;
				}else{
					auto it = super.insert(cursor.next, character, true);
					cursor.prev = it;
					cursor.next = ++it;
				}
				update(cursor.prev);
			}else
				queue ~= c;
		}

		void set(string s){
			clear();
			this ~= s;
		}

		override void clear(){
			super.clear();
			cursor.prev = begin();
			cursor.next = end();
		}

		override string toString(){
			string s;
			foreach(g; text)
				s ~= g.c;
			return s;
		}

		Cursor cursor;

		void update(Iterator it){
			if(!begin)
				return;
			it = begin;//(it ? it : begin());
			Point start = Point(cast(int)(font.size*0.3), cast(int)(cast(int)(font.size*1.4)*lines + font.size*0.4));
			if(it.prev){
				start = 
					it.prev.get().c == '\n'
					? Point(2, it.prev.get().pos.y - cast(int)(font.size*1.4))
					: it.prev.get().pos + Point(cast(int)it.prev.get().glyph.advance, 0);
			}
			while(it){
				it.get().pos = start;
				if(it.get().c=='\n'){
					start.x = 2;
					start.y -= cast(int)(font.size*1.4);
				}else{
					start.x += it.get().glyph.advance;
				}
				it = it.next;
			}
		}
		
		struct Cursor {
			Iterator prev;
			Iterator next;
			void opUnary(string s)() if(s == "--") {
				if(prev){
					next = prev;
					prev = prev.prev;
				}
			}
			void opUnary(string s)() if(s == "++") {
				if(next){
					prev = next;
					next = next.next;
				}
			}
		}

		string queue;

		protected:
			long lines;

	}

	class Character {
		dchar c;
		Point pos;
		Font.Glyph glyph;
		this(dchar c){
			this.c = c;
			glyph = font[c];
		}
	}


}
