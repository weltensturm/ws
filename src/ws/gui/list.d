module ws.gui.list;

import
	std.datetime,
	std.math,
	std.algorithm,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.button;


class List: Base {
	
	int padding = 10;
	int entryHeight = 30;
	double scroll = 0;
	double scrollSpeed = 0;
	long frameTime;
	long frameLast;
	
	override void resize(int[2] size){
		update;
		super.resize(size);
	}

	void update(){
		auto height = ((entryHeight+padding)*cast(long)children.length-size.h+padding).max(0);
		int y = cast(int)(pos.y + size.h - padding - entryHeight + height*scroll).lround;
		foreach(c; children){
			c.move([pos.x + padding, y]);
			c.resize([size.w-padding*2, entryHeight]);
			y -= c.size.y + padding;
		}
		
	}

	override void onMouseButton(Mouse.button button, bool pressed, int x, int y){
		if(button == Mouse.wheelDown){
			if(pressed && scroll < 1){
				scrollSpeed += 1.0/children.length;
				return;
			}
		}else if(button == Mouse.wheelUp){
			if(pressed && scroll > 0){
				scrollSpeed -= 1.0/children.length;
				return;
			}
		}
		super.onMouseButton(button, pressed, x, y);
	}

	override void onDraw(){
		if(hidden)
			return;
		frameTime = Clock.currSystemTick.msecs-frameLast;
		scroll = (scroll + scrollSpeed*frameTime/30.0).min(1).max(0);
		scrollSpeed = scrollSpeed.eerp(0, frameTime/2000.0);
		frameLast = Clock.currSystemTick.msecs;
		update;
		draw.setColor(style.bg.normal);
		draw.rect(pos, size);
		super.onDraw();
	}

}


double eerp(double current, double target, double speed){
	auto dir = current < target ? 1 : -1;
	auto diff = (current-target).abs;
	return current + (dir*(diff*speed+speed)).min(diff).max(-diff);
}

