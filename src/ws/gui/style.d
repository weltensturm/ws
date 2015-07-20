module ws.gui.style;


struct Style {

	Color
		bg,
		fg;

}


struct Color {

	float[4] normal;
	float[4] hover;
	float[4] active;

	void opAssign(float[4] c){
		normal = c;
		float[4] diff = c[] - 0.5;
		hover = c[] - diff[]/2;
		active = c[] - diff[]/1.5;
	}

	alias normal this;

	Color complement(){
		auto newColor = this;
		foreach(i, num; normal[0..3])
			newColor.normal[i] += (avg(normal[0..3]) < 0.5 ? 0.5 : -0.5);
		foreach(i, num; hover[0..3])
			newColor.hover[i] += (avg(hover[0..3]) < 0.5 ? 0.5 : -0.5);
		foreach(i, num; active[0..3])
			newColor.active[i] += (avg(active[0..3]) < 0.5 ? 0.5 : -0.5);
		return newColor;
	}

}


private {
	float avg(float[] c){
		float r = 0;
		foreach(n; c)
			r += n;
		return r/c.length;
	}
}