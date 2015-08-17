
module ws.gui.base;

import
	std.algorithm,
	std.array,
	ws.draw,
	ws.wm,
	ws.gui.dragger;

public import
	ws.gui.point,
	ws.gui.input,
	ws.gui.style;

T[] without(T)(T[] array, T elem){
	auto i = array.countUntil(elem);
	if(i < 0)
		return array;
	return array[0..i] ~ array[i+1..$];
}


class Base {

	Style style;
	Mouse.cursor cursor;
	int[2] size;
	int[2] pos;
	int[2] cursorPos;
	Base parent;
	Base mouseChild;
	Base keyboardChild;
	bool hidden = false;
	Base[] children;
	DrawEmpty _draw;
	bool[int] buttons;
	bool dragging;

	T addNew(T, Args...)(Args args){
		T e = new T(args);
		add(e);
		return e;
	}
	

	Base add(Base gui){
		assert(!gui.parent);
		gui.parent = this;
		gui.hidden = false;
		children ~= gui;
		return gui;
	}

	Base[] hiddenChildren(){
		return children.filter!"a.hidden".array;
	}

	void remove(Base widget){
		children = children.without(widget);
		if(widget.parent == this)
			widget.parent = null;
	}



	Base findChild(int x, int y, Base[] filter=[]){
		foreach(child; children){
			if(child.hidden || filter.canFind(child))
				continue;
			if(child.pos.x < x && child.pos.x+child.size.x > x && child.pos.y < y && child.pos.y+child.size.y > y){
				return child;
			}
		}
		if(filter.canFind(this))
			return null;
		return this;
	}


	Base drag(int[2] offset){
		return null;
	}

	Base dropTarget(int x, int y, Base draggable){
		auto targetChild = findChild(x, y, [this,draggable]);
		if(targetChild)
			return targetChild.dropTarget(x, y, draggable);
		return null;
	}

	void dropPreview(int x, int y, Base draggable, bool start){
		assert(false, "dropPreview not implemented");
	}

	void drop(int x, int y, Base draggable){
		if(findChild(x, y, [this,draggable]))
			findChild(x, y, [this,draggable]).drop(x, y, draggable);	
	}


	Base root(){
		if(parent)
			return parent.root;
		return this;
	}

	Draggable grab(int x, int y){
		if(findChild(x, y) != this)
			return findChild(x, y).grab(x, y);
		return null;
	}

	void receive(Draggable what){
		assert(0, "receiveShadow implies receive");
	}

	Base receiveShadow(Draggable what, int x, int y){
		foreach(child; children)
			if(child.pos.x < x && child.pos.x+child.size.x > x && child.pos.y < y && child.pos.y+child.size.y > y)
				return child.receiveShadow(what, x, y);
		return null;
	}


	void setTop(Base child){
		if(child.hidden || keyboardChild == child)
			return;

		if(keyboardChild)
			keyboardChild.onKeyboardFocus(false);

		if(parent)
			parent.setTop(this);

		children = children.without(child);
		children = child ~ children;

		keyboardChild = child;
		child.onKeyboardFocus(true);
	}

	@property
	bool hasFocus(){
		if(!parent)
			return false;
		return parent.keyboardChild == this;
	}

	@property
	bool hasMouseFocus(){
		if(!parent)
			return false;
		return parent.mouseChild == this;
	}

	void show(){
		if(!hidden)
			return;
		hidden = false;
		if(parent)
			root.onMouseMove(cursorPos.x, cursorPos.y);
		onShow;
	}

	void hide(){
		if(hidden)
			return;
		hidden = true;
		onMouseFocus(false);
		onKeyboardFocus(false);
		if(parent){
			if(parent.keyboardChild == this){
				foreach(pc; parent.children){
					if(pc.hidden)
						continue;
					parent.setTop(pc);
					break;
				}
			}
			auto p = parent;
			while(p.parent)
				p = p.parent;
			p.onMouseMove(cursorPos.x, cursorPos.y);
		}
		onHide();
	}
			
	void onShow(){};
	void onHide(){};
	
	void onClose(){};
	
	void resize(int[2] size){
		this.size = size;
	}

	void move(int[2] pos){
		foreach(c; children)
			c.move([c.pos.x+pos.x-this.pos.x, c.pos.y+pos.y-this.pos.y]);
		this.pos = pos;
	}

	void moveLocal(int[2] pos){
		if(parent)
			move([parent.pos.x+pos.x, parent.pos.y+pos.y]);
		else
			move(pos);
	}
	
	void onKeyboard(Keyboard.key key, bool pressed){
		if(keyboardChild)
			keyboardChild.onKeyboard(key, pressed);
	};
	
	void onKeyboard(dchar c){
		if(keyboardChild)
			keyboardChild.onKeyboard(c);
	};
	
	void onKeyboardFocus(bool focus){
		if(keyboardChild)
			keyboardChild.onKeyboardFocus(false);
	}

	void onMouseMove(int x, int y){
		bool foundFocus = false;
		cursorPos = [x,y];
		if(dragging){
			foundFocus = true;
		}else{
			auto child = findChild(x, y);
			if(child == mouseChild){
				foundFocus = true;
			}else if(child && child != this){
				if(mouseChild)
					mouseChild.onMouseFocus(false);
				child.onMouseFocus(true);
				wm.active.setCursor(child.cursor);
				mouseChild = child;
				foundFocus = true;
			}
		}

		if(mouseChild){
			if(!foundFocus){
				mouseChild.onMouseFocus(false);
				mouseChild = null;
				wm.active.setCursor(cursor);
			}else{
				mouseChild.onMouseMove(x, y);
			}
		}
	};
	
	void onMouseButton(Mouse.button b, bool p, int x, int y){
		buttons[b] = p;
		if(mouseChild)
			mouseChild.onMouseButton(b, p, x, y);
		if(!buttons.values.any && dragging){
			dragging = false;
			onMouseMove(x, y);
		}else if(buttons.values.any && !dragging)
			dragging = true;
	};
	
	void onMouseFocus(bool f){
		if(!f && mouseChild){
			mouseChild.onMouseFocus(false);
			mouseChild = null;
		}
	};
	
	void setCursor(Mouse.cursor c){
		cursor = c;
		if(parent && parent.mouseChild == this)
			wm.active.setCursor(cursor);
	}
	
	@property
	DrawEmpty draw(){
		if(!_draw && parent)
			return parent.draw;
		return _draw;
	}
	
	void onDraw(){
		foreach_reverse(c; children)
			if(!c.hidden)
				c.onDraw;
	}
	
	void setStyle(Style style){
		this.style = style;
	}

}
