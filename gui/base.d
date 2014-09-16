
module ws.gui.base;

import ws.list, ws.wm;

public import ws.gui.point, ws.gui.input, ws.gui.style;


class Base {

	Style style;
	Mouse.cursor cursor;
	Point size;
	Point pos;
	Point cursorPos;
	Base parent;
	Base mouseChild;
	Base keyboardChild;
	bool hidden = false;
	List!Base children;
	List!Base hiddenChildren;


	this(){
		children = new List!Base;
		hiddenChildren = new List!Base;
	}
	
	
	T add(T, Args...)(Args args){
		T e = new T(args);
		add(e);
		return e;
	}
	

	Base add()(Base gui){
		gui.parent = this;
		gui.hidden = false;
		children ~= gui;
		return gui;
	}


	void setTop(Base child){
		if(child.hidden || keyboardChild == child)
			return;

		if(keyboardChild)
			keyboardChild.onKeyboardFocus(false);

		if(parent)
			parent.setTop(this);

		children.remove(child);
		children.pushFront(child);

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
			parent.hiddenChildren.remove(this);
			parent.children.pushFront(this);
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
			parent.children.remove(this);
			parent.hiddenChildren ~= this;
			if(parent.children.length)
				parent.setTop(parent.children.front);
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
	
	void setSize(int[2] s){
		size = s;
		onResize(s[0], s[1]);
	}
	
	void setSize(int w, int h){
		setSize([w, h]);
	}
	
	void setPos(int x, int y){
		onMove(x, y);
		foreach(c; children)
			c.setPos(c.pos.x+x-pos.x, c.pos.y+y-pos.y);
		pos = [x, y];
	}
	
	void setLocalPos(int x, int y){
		if(parent)
			setPos(parent.pos.x+x, parent.pos.y+y);
		else
			setPos(x, y);
	}
	
	void onResize(int w, int h){
		size = [w,h];
	};
	
	void onMove(int w, int h){}
	
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
