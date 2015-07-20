module ws.gui.list;

import
	ws.gl.draw,
	ws.gui.base,
	ws.gui.button;


class List: Base {
	
	int padding = 10;
	int entryHeight = 30;
	
	override void resize(int[2] size){
		int y = pos.y + size.h - padding - entryHeight;
		foreach(c; children){
			c.move([pos.x + padding, y]);
			c.resize([size.w-padding*2, entryHeight]);
			y -= c.size.y + padding;
		}
		super.resize(size);
	}

	override void onDraw(){
		draw.setColor(style.bg.normal);
		draw.rect(pos, size);
		super.onDraw();
	}

}