module ws.gui.slider;

import
	ws.io,
	ws.string,
	ws.event,
	ws.math.math,
	ws.gl.draw,
	ws.gui.base;

class Slider: Base {

	float[4] background = [0.2, 0.2, 0.2, 1];
	float[4] slider = [1, 0.2, 0.2, 1];

	Event!float onSlide;

	override void onMouseButton(Mouse.button b, bool p, int x, int y){
		if(p)
			slide(x, y);
		sliding = p;
	}

	override void onMouseFocus(bool f){
		if(!f)
			sliding = false;
	}

	override void onMouseMove(int x, int y){
		if(sliding)
			slide(x, y);
	}

	override void onDraw(){
		draw.setColor(background);
		draw.rect(pos, size);
		draw.setColor([0,0,0,1]);
		draw.rect(pos + Point(0, size.y/2-1), Point(size.x, 2));
		int x = cast(int)((current - min)/(max-min) * (size.x-width) + pos.x+width/2);
		draw.setColor(slider);
		draw.rect(pos + Point(0, size.y/2-1), Point(x-pos.x, 2));
		draw.rect(pos + Point(x-pos.x-width/2, 3), Point(width,width));
		//draw.setColor(slider);
		draw.setColor([0.1,0.1,0.1,1]);
		//draw.rect(pos + Point(x-pos.x, 2), Point(2, size.y-4));
		draw.rect(pos + Point(x-pos.x-width/2+2, 5), Point(width-4,width-4));
	}

	this(){
		super();
		onSlide = new Event!float;
	}

	void setValue(float v){
		if(v != current){
			if(v < min || v > max)
				throw new RangeError(v, min, max);
			current = v;
			onSlide(v);
		}
	}

	void set(float value, float min, float max){
		if(max <= min)
			throw new Exception(tostring("Min is larger than max (% > %)", min, max));
		if(value < min || value > max)
			throw new RangeError(value, min, max);
		current = value;
		this.min = min;
		this.max = max;
	}

	override void resize(int[2] size){
		width = size.h-6;
		super.resize(size);
	}

	protected:
		float min = 0;
		float max = 1;
		float current = 0.5;
		int width;
		bool sliding;

		void slide(int x, int y){
			float normalized = clamp(cast(float)(x-pos.x-width/2)/cast(float)(size.x-width), 0, 1);
			setValue((max - min)*normalized + min);
		}

}

class RangeError: Exception {
	
	this(float v, float min, float max){
		super(tostring("Range error (Value: %, min: %, max: %)", v, min, max));
	}
	
}
