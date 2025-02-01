module ws.gui.text;

import
	std.utf,
	std.algorithm,
	std.conv,
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

	string font;
	int fontSize;

	double offset = -0.2;

	this(){
		style.bg.normal = [0, 0, 0, 0.5];
		style.fg.normal = [1, 1, 1, 1];
		setFont("sans", 11);
	}


	void setFont(string f, int size){
		font = f;
		fontSize = size;
	}


	override void onDraw(){
		draw.setFont(font, fontSize);
		draw.setColor(style.fg.normal);
		auto w = draw.width(text);
		auto x = w*(-offset) + size.w*offset;
		draw.text([pos.x + x.to!int, pos.y], size.h, text, 0);
	}

}
