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
		title = addNew!Text;
		title.text.set(t);
		title.moveLocal([0,0]);
		input = addNew!InputField;
		input.text.set(tostring(start));
		input.onEnter ~= (line){
			if(!isNumeric(line))
				throw new InputException(input, "Not a number!");
			float d = to!float(line);
			if(d < min || d > max)
				throw new InputException(input, "Too " ~ (d<min ? " small" : " large"));
			slider.setValue(d);
		};
		slider = addNew!Slider;
		slider.set(start, min, max);
		slider.onSlide ~= (v){
			input.text.set(to!string(v));
		};
		onSlide = slider.onSlide;
	}
	
	override void resize(int[2] size){
		
		input.setFont("UbuntuMono-R", cast(int)(size.h/1.4));
		title.setFont("UbuntuMono-R", cast(int)(size.h/1.4));
		
		int inputSize = size.h*5;
		int divider = (size.w - inputSize)/2;
		
		title.resize([divider, size.h]);
		slider.moveLocal([divider, 0]);
		slider.resize([divider, size.h]);
		input.moveLocal([size.w-inputSize, 0]);
		input.resize([inputSize, size.h]);
		
		super.resize(size);
		
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

