module ws.gui.tree;

import
	std.datetime,
	std.math,
	std.algorithm,
	std.conv,
	ws.animation,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.buttonSimple;


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

double sinApproach(double a){
	return (sin((a-0.5)*PI)+1)/2;
}

class Tree: Base {

	Button expander;
	bool expanded = false;
	int padding = 0;
	int inset = 0;
	int tail = 10;

	Animation animation;

	this(Button expander){
		this.expander = expander;
		animation = new Animation(expander.size.h, expander.size.h, 0.3, &sinApproach);
		expander.leftClick ~= &toggle;
		size = [size.w, expander.size.h];
		add(expander);
	}

	override Base add(Base elem){
		super.add(elem);
		update;
		resize(size);
		return elem;
	}

	Base add(Base elem, bool delegate(Base) here){
		foreach(i, c; children ~ null){
			if(here(c)){
				elem.parent = this;
				elem.hidden = false;
				children = children[0..i] ~ elem ~ children[i..$];
				break;
			}
		}
		update;
		resize(size);
		return elem;
	}

	override void resize(int[2] size){
		int y = padding;
		expander.move(pos.a+[0,size.h-expander.size.h]);
		expander.resize([size.w, expander.size.h]);
		foreach_reverse(i, c; children[1..$]){
			c.move(pos.a + [padding + inset, y+tail]);
			c.resize([size.w-padding*2 - inset, c.size.h]);
			y += c.size.h + padding;
		}
		super.resize(size);
	}

	void update(){
		int h = padding + (expanded ? tail : 0);
		foreach(i, c; children[0..expanded ? $ : 1])
			h += c.size.h + padding;
		if(parent && size.h != animation.calculate)
			parent.resizeRequest(this, [size.w, animation.calculate.lround.to!int]);
		if(h != animation.end)
			animation.change(h);
	}

	override void resizeRequest(Base child, int[2] size){
		child.resize(size);
		update;
		animation.replace(animation.end);
	}

	override void remove(Base child){
		super.remove(child);
		update;
	}

	void toggle(){
		expanded = !expanded;
		update;
	}

	override void onDraw(){
		children[0].onDraw;
		if(expanded || size.h != children[0].size.h){
			draw.clip(pos, [size.x, size.h-expander.size.h]);
			super.onDraw;
			draw.noclip;
		}
		update;
	}

}
