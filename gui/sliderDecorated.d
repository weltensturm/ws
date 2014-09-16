module ws.gui.sliderDecorated;

import
	std.conv,
	ws.event,
	ws.string,
	ws.gl.draw,
	ws.gui.base,
	ws.gui.inputField,
	ws.gui.text,
	ws.gui.slider;

class SliderDecorated: Base {
	
	this(string t, float min = 0, float max = 1, float start = 0.5){
		style.bg = [0, 0, 0, 0.5]; 
		title = add!Text();
		title.text.set(t);
		title.setLocalPos(0,0);
		input = add!InputField();
		input.text.set(tostring(start));
		input.onEnter ~= (line){
			if(!isNumeric(line))
				throw new InputException(input, "Not a number!");
			float d = to!float(line);
			if(d < min || d > max)
				throw new InputException(input, "Too " ~ (d<min ? " small" : " large"));
			slider.setValue(d);
		};
		slider = add!Slider();
		slider.set(start, min, max);
		slider.onSlide ~= (v){
			input.text.set(to!string(v));
		};
		onSlide = slider.onSlide;
	}
	
	override void onResize(int w, int h){
		
		input.setFont("UbuntuMono-R", cast(int)(h/1.4));
		title.setFont("UbuntuMono-R", cast(int)(h/1.4));
		
		int inputSize = h*5;
		int divider = (w - inputSize)/2;
		
		title.setSize(divider, h);
		slider.setLocalPos(divider, 0);
		slider.setSize(divider, h);
		input.setLocalPos(w-inputSize, 0);
		input.setSize(inputSize, h);
		
	}
	
	override void onDraw(){
		draw.setColor(style.bg.normal);
		draw.rect(pos, size);
		super.onDraw();
	}
	
	Event!float onSlide;
	
	protected {
		Text title;
		InputField input;
		Slider slider;
	}
	
}

