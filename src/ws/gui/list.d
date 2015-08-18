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
		super.resize(size);
		update;
	}

	void update(){
		auto height = ((entryHeight+padding)*cast(long)children.length-size.h+padding+entryHeight).max(0);
		int y = cast(int)(pos.y + size.h - padding - entryHeight + scroll*entryHeight);
		foreach(c; children){
			c.move([pos.x + padding, y]);
			c.resize([size.w-padding*2, entryHeight]);
			y -= c.size.y + padding;
		}
		onMouseMove(cursorPos.x, cursorPos.y);
		
	}

	override void onMouseButton(Mouse.button button, bool pressed, int x, int y){
		if(button == Mouse.wheelDown){
			if(pressed && scroll < children.length){
				scrollSpeed += 1.0;
				return;
			}
		}else if(button == Mouse.wheelUp){
			if(pressed && scroll > 0){
				scrollSpeed -= 1.0;
				return;
			}
		}
		super.onMouseButton(button, pressed, x, y);
	}

	override void onDraw(){
		if(hidden)
			return;
		frameTime = Clock.currSystemTick.msecs-frameLast;
		frameLast = Clock.currSystemTick.msecs;
		if(scrollSpeed){
			scroll = (scroll + scrollSpeed*frameTime/60.0).min(children.length).max(0);
			scrollSpeed = scrollSpeed.eerp(0, frameTime/1000.0, frameTime/350.0, frameTime/350.0);
			update;
		}
		draw.setColor(style.bg.normal);
		draw.rect(pos, size);
		super.onDraw();
	}

}


double eerp(double current, double target, double a, double b, double c){
	auto dir = current < target ? 1 : -1;
	auto diff = (current-target).abs;
	return current + (dir*(a*diff^^2 + b*diff + c)).min(diff).max(-diff);
}

