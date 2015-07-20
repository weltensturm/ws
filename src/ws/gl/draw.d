module ws.gl.draw;

import
	ws.exception,
	ws.gl.gl,
	ws.gl.batch,
	ws.gl.shader,
	ws.gl.font,
	ws.gl.texture,
	ws.math.vector,
	ws.gui.point;


class draw {
	
	static void setScreenResolution(long x, long y){
		screen[0] = x; screen[1] = y;
	}
	
	
	static void setColor(float r, float g, float b, float a=1){
		color = [r, g, b, a];
	}
	
	
	static void setColor(float[4] f){
		color = f;
	}
	
	
	static void setFont(string f, int size){
		font = Font.load(f, size);
	}

	static void setFont(Font f){
		font = f;
	}
	
	
	static void rect(float x, float y, float w, float h){
		auto s = activateShader(type.rect);
		float[3] offset = [x, y, 1];
		float[3] scale = [w, h, 1];
		s["Screen"].set(screen);
		s["Color"].set(color);
		s["Offset"].set(offset);
		s["Scale"].set(scale);
		batchRect.draw();
	}
	
	static void rect(int[2] pos, int[2] size){
		rect(pos[0], pos[1], size[0], size[1]);
	}

	static void rectOutline(int x, int y, int w, int h){
		line(x, y, x+w, y);
		line(x, y, x, y+h);
		line(x, y+h, x+w, y+h);
		line(x+w, y, x+w, y+h);
	}

	static void rectOutline(int[2] pos, int[2] size){
		rectOutline(pos[0], pos[1], size[0], size[1]);
	}

	static void texturedRect(Point pos, Point size){
		if(!texture)
			exception("No texture active");
		auto s = activateShader(type.texture);
		float[3] offset = [pos.x, pos.y, 0];
		float[3] scale = [size.x, size.y, 0];
		s["Screen"].set(screen);
		s["Color"].set(color);
		s["Offset"].set(offset);
		s["Scale"].set(scale);
		s["Image"].set(0);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture.id);
		batchRectTexture.draw();
	}

	
	static void line(float x1, float y1, float x2, float y2){
		auto s = activateShader(type.line);
		float[3] offset = [x1+0.25,y1+0.25,0];
		float[3] scale = [1,1,0];
		s["Screen"].set(screen);
		s["Color"].set(color);
		s["Offset"].set(offset);
		s["Scale"].set(scale);
		batchLine.updateVertices([x2-x1+0.25, y2-y1+0.25, 0], 1);
		batchLine.draw();
	}

	static void line(int[2] start, int[2] end){
		line(start[0], start[1], end[0], end[1]);
	}


	static void text(Point pos, string text){
		if(!font)
			exception("no font active");
		auto s = activateShader(type.text);
		float[3] scale = [1,1,0];
		s["Screen"].set(screen);
		s["Image"].set(0);
		s["Color"].set(color);
		s["Scale"].set(scale);
		float x = pos.x;
		float y = pos.y;
		glActiveTexture(GL_TEXTURE0);
		foreach(dchar c; text){
			if(c == '\n'){
				x = pos.x;
				y -= font.size*1.4;
				continue;
			}
			auto g = font[c];
			glBindTexture(GL_TEXTURE_2D, g.tex);
			float[3] p = [cast(int)x, cast(int)y, 0];
			s["Offset"].set(p);
			g.vao.draw();
			x += g.advance;
		}
	}

	static float[3] screen = [10,10,1];
	static float[4] color = [1,1,1,1];
	static Texture texture;

	private:
	
		static Font font;
		enum type {
			rect = 1,
			line,
			text,
			texture
		}

		static Shader activateShader(type t){
			if(!(t in shaders)){
				final switch(t){
					case type.texture:
						batchRectTexture = new Batch;
						batchRectTexture.begin(4, gl.triangleFan);
						batchRectTexture.addPoint([0, 0, 0], [0,0]);
						batchRectTexture.addPoint([1, 0, 0], [1,0]);
						batchRectTexture.addPoint([1, 1, 0], [1,1]);
						batchRectTexture.addPoint([0, 1, 0], [0,1]);
						batchRectTexture.finish();
						shaders[t] = Shader.load("2d_texture", [gl.attributeVertex: "vVertex", gl.attributeTexture: "vTexture0"]);
						break;
					case type.rect:
						batchRect = new Batch;
						batchRect.begin(4, gl.triangleFan);
						batchRect.add([0, 0, 0]);
						batchRect.add([1, 0, 0]);
						batchRect.add([1, 1, 0]);
						batchRect.add([0, 1, 0]);
						batchRect.finish();
						shaders[t] = Shader.load("2d_rect", [gl.attributeVertex: "vVertex"]);
						break;
					case type.line:
						batchLine = new Batch;
						batchLine.begin(2, gl.lines);
						batchLine.add([0,0,0]);
						batchLine.add([0,10,0]);
						batchLine.finish();
						shaders[t] = Shader.load("2d_rect", [gl.attributeVertex: "vVertex"]);
						break;
					case type.text:
						shaders[t] = Shader.load("2d_texture", [gl.attributeVertex: "vVertex", gl.attributeTexture: "vTexture0"]);
				}
			}
			shaders[t].use();
			return shaders[t];
		}
		static Shader[type] shaders;
		
		static Batch batchRect;
		static Batch batchRectTexture;
		static Batch batchLine;
		
}
