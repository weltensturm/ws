module ws.gui.tabs;

import 
	std.algorithm,
	ws.list,
	ws.io,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.button;


class TabButton: Button {
	this(string s){
		super(s);
	}
	bool active;
	void disable(){
		mouseFocus = false;
		active = false;
	}
	void activate(){
		mouseFocus = true;
		active = true;
	}
	override void onMouseFocus(bool focus){
		if(!active)
			mouseFocus = focus;
		if(!focus)
			pressed = false;
	}
}


class Tabs: Base {

	Point buttonSize = Point(150, 30);
	long active = -1;
	double activeSmooth = 0;
	enum: int {
		top, bottom, left, right
	}
	int position;
	double offset = 0.5;
	Style buttonStyle;

	this(int pos = top){
		position = pos;
		pages = new List!Page;
	}

	override void setStyle(Style style){
		super.setStyle(style);
		swap(style.bg.normal, style.bg.hover);
		buttonStyle = style;
	}

	protected string font = "Ubuntu-B";

	Page addPage(string name, Base gui){
		auto b = add!TabButton(name);
		b.setSize(buttonSize);
		b.font = font;
		b.setStyle = buttonStyle;
		size_t current = pages.length;
		b.leftClick ~= {
			if(active > -1){
				pages[cast(size_t)active].content.hide();
				pages[cast(size_t)active].button.disable();
			}
			b.activate();
			gui.show();
			active = current;
			updateSize();
		};
		pages ~= Page(b, add(gui));
		gui.hide();
		updateSize();
		return pages.back;
	}

	void updateSize(){
		int x = (position == left ? buttonSize.x : 0);
		int y = (position == bottom ? buttonSize.y : 0);
		if(active > -1){
			auto gui = pages[cast(size_t)active].content;
			gui.setLocalPos(x, y);
			gui.setSize(size-Point(
				position == left || position == right ? buttonSize.x : 0,
				position == top || position == bottom ? buttonSize.y : 0
			));
		}
		auto s = Point(0,0);
		foreach(p; pages)
			s += p.button.size;
		Point start = (size - s)*offset;
		foreach(p; pages){
			p.button.setLocalPos(
				position == right ? size.x-buttonSize.x :
				position == left ? 0 :
				start.x,
				position == top ? size.y-buttonSize.y :
				position == bottom ? 0 :
				size.y-start.y
			);
			start += p.button.size;
		}
	}

	override void onDraw(){
		if(active > -1){
			draw.setColor(style.bg.normal);
			auto g = pages[cast(size_t)active].content;
			draw.rect(g.pos, g.size);
		}
		super.onDraw();
	}

	override void onResize(int w, int h){
		updateSize();
	}

	struct Page {
		TabButton button;
		Base content;
	}

	List!Page pages;

}
