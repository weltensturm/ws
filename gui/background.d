module ws.gui.background;

import ws.gui.base, ws.gl.draw;

class Background: Base {
	float[4] color;
	this(float[4] c){
		color = c;
	}
	override void onDraw(){
		draw.setColor(color);
		draw.rect(pos, size);
	}
}
