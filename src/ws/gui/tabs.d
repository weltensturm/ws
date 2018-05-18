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
	protected int fontSize = 12;

	Page addPage(TabButton button, Base gui){
		add(button);
		add(gui);
		button.font = font;
		button.fontSize = fontSize;
		button.setStyle = buttonStyle;
		button.resize(buttonSize);
		size_t current = pages.length;
		button.leftClick ~= {
			if(active > -1){
				pages[cast(size_t)active].content.hide();
				pages[cast(size_t)active].button.disable();
			}
			button.activate();
			gui.show();
			setTop(gui);
			active = current;
			updateSize();
		};
		pages ~= Page(button, gui);
		gui.hide();
		updateSize();
		return pages.back;
	}

	Page addPage(string name, Base gui){
		auto button = new TabButton(name);
		return addPage(button, gui);
	}

	void updateSize(){
		int x = (position == left ? buttonSize.x : 0);
		int y = (position == bottom ? buttonSize.y : 0);
		if(active > -1){
			auto gui = pages[cast(size_t)active].content;
			gui.moveLocal([x, y]);
			gui.resize([
				size.w - (position == left || position == right ? buttonSize.x : 0),
				size.h - (position == top || position == bottom ? buttonSize.y : 0)
			]);
		}
		auto s = Point(0,0);
		foreach(p; pages)
			s += p.button.size;
		int[2] start = (size.a - s)*offset;
		foreach(p; pages){
			p.button.moveLocal([
				position == right ? size.x-buttonSize.x :
				position == left ? 0 :
				start.x,
				position == top ? size.y-buttonSize.y :
				position == bottom ? 0 :
				size.y-start.y-buttonSize.h
			]);
			start = start.a + p.button.size;
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

	override void resize(int[2] size){
		super.resize(size);
		updateSize();
	}

	struct Page {
		TabButton button;
		Base content;
	}

	List!Page pages;

}
