module ws.gui.textSimple;

import
	std.utf,
	ws.io,
	ws.list,
	ws.gl.gl,
	ws.gl.draw,
	ws.gl.shader,
	ws.gui.base,
	ws.gui.point;


class Text: Base {

	string text;
	Shader shader;

	this(){
		style.bg.normal = [0, 0, 0, 0.5];
		style.fg.normal = [1, 1, 1, 1];
		setFont("sans", 11);
	}


	void setFont(string f, int size){
	}


	override void onDraw(){
		draw.setColor(style.fg.normal);
		draw.text(pos.a + [5,0], size.h, text);
	}

}
