module ws.gui.checkBox;

import
	ws.event,
	ws.gl.draw,
	ws.gui.point,
	ws.gui.button;


class CheckBox: Button {

	this(string s){
		super(s);
		update = new Event!(bool);
		leftClick ~= {
			state = !state;
		};
	}

	Event!(bool) update;

	@property bool state(){
		return m_state;
	}

	@property void state(bool s){
		if(s == m_state)
			return;
		update(s);
		m_state = s;
	}

	override void onDraw(){
		super.onDraw();
		draw.setColor([1,0,0]);
		auto height = size.y();
		draw.rect(pos.a + size - [height-3, height-3], [height-6, height-6]);
		draw.setColor([0,0,0]);
		draw.rect(pos.a + size - [height-5, height-5], [height-10, height-10]);
		if(state){
			draw.setColor([1,0,0]);
			draw.rect(pos.a+size-[height-7, height-7], [height-14, height-14]);
		}
	}

	protected {
		bool m_state;
	}

}