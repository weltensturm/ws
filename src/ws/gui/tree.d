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

	override Base add(Base elem){
		super.add(elem);
		update;
		return elem;
	}

	override void resize(int[2] size){
		int y = size.h-padding;
		int h = padding;
		foreach(c; children){
			if(c.hidden)
				continue;
			c.move(pos.a + [padding, y-c.size.h]);
			c.resize([size.w-padding*2, c.size.h]);
			y -= c.size.h + padding;
			h += c.size.h + padding;
		}
		super.resize(size);
	}

	void update(){
		int h = padding;
		foreach(i, c; children){
			if(c.hidden)
				continue;
			h += c.size.h + padding;
		}
		if(parent)
			parent.resizeRequest(this, [size.w, h]);
	}

	override void resizeRequest(Base child, int[2] size){
		child.resize(size);
		update;
	}

}


class Tree: Base {

	Button expander;
	bool expanded = false;
	int inset = 15;
	int padding = 5;

	this(Button expander){
		this.expander = expander;
		expander.leftClick ~= &toggle;
		add(expander);
	}

	override Base add(Base elem){
		super.add(elem);
		if(!expanded && elem != expander)
			elem.hide;
		else
			elem.show;
		update;
		return elem;
	}

	override void resize(int[2] size){
		int y = size.h-padding;
		int h = padding;
		foreach(i, c; children){
			if(c.hidden)
				continue;
			c.move(pos.a + [padding + (i > 0 ? inset : 0), y-c.size.h]);
			c.resize([size.w-padding*2 - (i > 0 ? inset : 0), c.size.h]);
			y -= c.size.h + padding;
			h += c.size.h + padding;
		}
		super.resize(size);
	}

	void update(){
		int h = padding;
		foreach(i, c; children){
			if(c.hidden)
				continue;
			h += c.size.h + padding;
		}
		if(parent)
			parent.resizeRequest(this, [size.w, h]);
	}

	override void resizeRequest(Base child, int[2] size){
		child.resize(size);
		update;
	}

	override void remove(Base child){
		super.remove(child);
		update;
	}

	void toggle(){
		expanded = !expanded;
		foreach(c; children[1..$])
			if(!expanded)
				c.hide;
			else
				c.show;
		update;
	}

}
