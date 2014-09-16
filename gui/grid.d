module ws.gui.grid;

import
	ws.gui.point,
	ws.gui.base;


class Grid: Base {

	Point tileSize;

	int lineElements;
	int padding;

	this(Point ts){
		tileSize = ts;
	}

	override void onResize(int w, int h){
		lineElements = w/(tileSize.x+10);
		if(lineElements < 1)
			return;
		padding = (w - tileSize.x*lineElements + 1)/lineElements;
		int i = 0;
		foreach(c; children){
			int line = i / lineElements;
			int slot = i - line*lineElements;
			c.setPos(pos.x + slot*(tileSize.x + padding), pos.y + line*(tileSize.y + padding/5 + 5));
			c.setSize(tileSize);
			i++;
		}
	}
	
}

