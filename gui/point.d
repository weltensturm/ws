
module ws.gui.point;


struct Point {


	int[2] data = [0,0];


	this(int x, int y){
		data = [x, y];
	}
	
	this(int[2] d){
		data = d;
	}


	@property ref int x(){
		return data[0];
	}


	@property ref int y(){
		return data[1];
	}
	

	Point opBinary(string op)(double other){
		mixin("
			return Point(
				cast(int)(data[0] " ~ op ~ " other),
				cast(int)(data[1] " ~ op ~ " other)
			);
		");	
	}

	
	Point opBinary(string op)(int[2] other){
		mixin("
			return Point(
				data[0] " ~ op ~ " other[0],
				data[1] " ~ op ~ " other[1]
			);
		");
	}

	Point opOpAssign(string op)(int[2] other){
		mixin("this = this " ~ op ~ "other;");
		return this;
	}


	alias data this;
	

}
