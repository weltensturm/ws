module ws.gui.tree;

import
	std.datetime,
	std.math,
	std.algorithm,
	std.conv,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.button;


class DynamicList: Base {
	
	int padding = 5;
	int entryHeight = 25;

	override Base add(Base elem){
		super.add(elem);
		resize([size.w, 0]);
		return elem;
	}

	override void resize(int[2] size){
		int y = size.h-padding-entryHeight;
		int h = padding;
		foreach(c; children){
			if(c.hidden)
				continue;
			c.move(pos.a + [padding, y]);
			c.resize([size.w-padding*2, c.size.h]);
			y -= c.size.h + padding;
			h += c.size.h + padding;
		}
		super.resize([size.w, h]);
	}

}


class Tree: DynamicList {

	string name;
	bool expanded = true;
	int inset = 15;

	this(string name){
		this.name = name;
		auto button = new Button(name);
		button.resize([5, entryHeight]);
		button.leftClick ~= &toggle;
		add(button);
	}

	override void resize(int[2] size){
		int y = size.h-padding-entryHeight;
		int h = padding;
		foreach(i, c; children){
			if(c.hidden)
				continue;
			c.move(pos.a + [padding + (i > 0 ? inset : 0), y]);
			c.resize([size.w-padding*2 - (i > 0 ? inset : 0), c.size.h]);
			y -= c.size.h + padding;
			h += c.size.h + padding;
		}
		Base.resize([size.w, h]);
	}

	void toggle(){
		expanded = !expanded;
		foreach(c; children[1..$])
			if(!expanded)
				c.hide;
			else
				c.show;
		resize(size);
	}

}
