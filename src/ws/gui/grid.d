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

	override void resize(int[2] size){
		lineElements = size.w/(tileSize.x+10);
		if(lineElements < 1)
			return;
		padding = (size.w - tileSize.x*lineElements + 1)/lineElements;
		int i = 0;
		foreach(c; children){
			int line = i / lineElements;
			int slot = i - line*lineElements;
			c.move([pos.x + slot*(tileSize.x + padding), pos.y + line*(tileSize.y + padding/5 + 5)]);
			c.resize(tileSize);
			i++;
		}
	}
	
}

