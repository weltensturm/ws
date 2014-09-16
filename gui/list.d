module ws.gui.list;

import
	ws.gl.draw,
	ws.gui.base,
	ws.gui.button;


class List: Base {
	
	int padding = 10;
	int entryHeight = 30;
	
	override void onResize(int w, int h){
		int y = pos.y + h - padding - entryHeight;
		foreach(c; children){
			c.setPos(pos.x + padding, y);
			c.setSize(w-padding*2, entryHeight);
			y -= c.size.y + padding;
		}
	}

	override void onDraw(){
		draw.setColor(style.bg.normal);
		draw.rect(pos, size);
		super.onDraw();
	}

}