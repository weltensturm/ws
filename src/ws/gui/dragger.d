module ws.gui.dragger;


import
	ws.gui.base;


class Draggable {

	Widget handle(){
		assert(0);
	}

	void move(int x, int y){

	}

	Widget shadow(){
		assert(0);
	}

}


class Dragger {

	Widget root;
	Draggable grabbed;
	Widget shadowHolder;

	this(Widget root){
		this.root = root;
	}

	void grab(int x, int y){
		if(grabbed)
			return;
		grabbed = root.grab(x, y);
	}

	void drop(int x, int y){
		if(shadowHolder){
			shadowHolder.receive(grabbed);
			grabbed = null;
		}
	}

	void draw(){
		if(grabbed)
			grabbed.shadow.onDraw;
	}

	void move(int x, int y){
		if(grabbed){
			grabbed.move(x, y);
		}
		if(shadowHolder)
			shadowHolder.receiveShadow(null, x, y);
		shadowHolder = root.receiveShadow(grabbed, x, y);
	}
}


