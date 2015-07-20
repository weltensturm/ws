module ws.gui.dragger;


import
	ws.gui.base;


class Draggable {

	Base handle(){
		assert(0);
	}

	void move(int x, int y){

	}

	Base shadow(){
		assert(0);
	}

}


class Dragger {

	Base root;
	Draggable grabbed;
	Base shadowHolder;

	this(Base root){
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


