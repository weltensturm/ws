
module ws.gui.base;

import
	std.algorithm,
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
	Base[] hiddenChildren;
	
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

	void remove(Base widget){
		if(widget.hidden)
			hiddenChildren = hiddenChildren.without(widget);
		else
			children = children.without(widget);
		if(widget.parent == this)
			widget.parent = null;
	}

	
	Draggable grab(int x, int y){
		if(mouseChild)
			return mouseChild.grab(x, y);
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

	void show(){
		if(!hidden)
			return;
		hidden = false;
		if(parent){
			parent.hiddenChildren = parent.hiddenChildren.without(this);
			parent.children = this ~ parent.children;
			parent.setTop(this);
			auto p = parent;
			while(p.parent)
				p = p.parent;
			p.onMouseMove(cursorPos.x, cursorPos.y);
		}
		onShow();
	}

	void hide(){
		if(hidden)
			return;
		hidden = true;
		onMouseFocus(false);
		onKeyboardFocus(false);
		if(parent){
			/+
			if(parent.keyboardChild == this)
				onKeyboardFocus(false);
			if(parent.mouseChild == this)
				parent.onMouseFocus(false);
			+/
			parent.children = parent.children.without(this);
			parent.hiddenChildren ~= this;
			if(parent.children.length)
				parent.setTop(parent.children[0]);
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
		foreach(child; children){
			if(child.pos.x < x && child.pos.x+child.size.x > x && child.pos.y < y && child.pos.y+child.size.y > y){
				if(mouseChild == child){
					foundFocus = true;
					break;
				}
				if(mouseChild)
					mouseChild.onMouseFocus(false);
				child.onMouseFocus(true);
				wm.active.setCursor(child.cursor);
				mouseChild = child;
				foundFocus = true;
				break;
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
		if(p && parent && (b == Mouse.buttonLeft || b == Mouse.buttonRight))
			parent.setTop(this);	
		if(keyboardChild && keyboardChild != mouseChild){
			keyboardChild.onKeyboardFocus(false);
			keyboardChild = null;
		}
		if(mouseChild)
			return mouseChild.onMouseButton(b, p, x, y);
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
	
	void onDraw(){
		foreach_reverse(c; children)
			c.onDraw();
	}
	
	void setStyle(Style style){
		this.style = style;
	}

}
