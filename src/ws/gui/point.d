module ws.gui.point;


public import ws.math: x, y;

alias w = x;
alias h = y;


Point a(int[2] data){
	return Point(data);
}


struct Point {

	int[2] data = [0,0];

	this(int x, int y){
		data = [x, y];
	}
	
	this(int[2] d){
		data = d;
	}

	Point opBinary(string op, T)(T[2] other) if(__traits(isArithmetic,T)) {
		mixin("
			return Point(
				data[0] " ~ op ~ " cast(int)other[0],
				data[1] " ~ op ~ " cast(int)other[1]
			);
		");
	}

	Point opBinary(string op)(Point other){
		return opBinary!op(other.data);
	}

	Point opBinary(string op)(double other){
		mixin("
			return Point(
				cast(int)(data[0] " ~ op ~ " other),
				cast(int)(data[1] " ~ op ~ " other)
			);
		");	
	}

	Point opOpAssign(string op)(int[2] other){
		mixin("this = this " ~ op ~ "other;");
		return this;
	}

	alias data this;
	
}
