
module ws.math.vector;

import
	std.algorithm,
	std.range,
	std.math,
	std.traits,
	ws.string;


T asqrt(T)(T n){
	static if(is(T == int))
		return cast(int)sqrt(cast(float)n);
	else
		return sqrt(n);
}

ref T x(T)(T[] array){
	return array[0];
}
alias w = x;

ref T y(T)(T[] array){
	return array[1];
}
alias h = y;

ref T z(T)(T[] array){
	return array[2];
}


auto length(T)(T array) if(isStaticArray!T) {
	return asqrt(array[].map!"a^^2".sum);
}

alias len = length;

T normal(T)(T array) if(isStaticArray!T) {
	auto len = array.length;
	if(1/len == 1.0f/0.0f)
		len = 1;
	T res;
	foreach(i, n; array)
		res[i] = n/len;
	return res;
}


T dot(int N, T)(T[N] data, T[N] other){
	T result = 0;
	foreach(i, n; data)
		result += n*other[i];
	return result;
}

T add(T)(T data, T other) if(isStaticArray!T) {
	T res;
	foreach(i, n; data)
		res[i] = n - other[i];
	return res;
}

T sub(T)(T data, T other) if(isStaticArray!T) {
	T res;
	foreach(i, n; data)
		res[i] = n - other[i];
	return res;
}

T[N] mul(int N, T)(T[N] data, T val){
	T[N] res;
	foreach(i, n; data)
		res[i] = n*val;
	return res;
}

T[N] div(int N, T)(T[N] data, T val){
	T[N] res;
	foreach(i,d; data)
		res[i] = d/val;
	return res;
}


auto vec(Args...)(Args args){
	float[Args.length] data;
	foreach(i, a; args)
		data[i] = a;
	return Vector!(Args.length)(data);
}

Vector!Size vec(size_t Size, Type)(Type[Size] data){
	return Vector!Size.from(data);
}


struct Vector(size_t Size = 3, Type = float) {
	
	this(Type[Size] data){
		this.data = data;
	}
	
	this(Type[] data){
		assert(data.length == Size);
		this.data = data;
	}

	static Vector from(T)(T arg) if(isStaticArray!T) {
		Vector res;
		foreach(i, d; arg)
			res[i] = cast(Type)d;
		return res;
	}

	static Vector from(T)(T arg) if(!isStaticArray!T) {
		Vector vec;
		vec.data = arg;
		return vec;
	}

	auto opAssign(Type[Size] data){
		this.data = data;
	}

	static if(Size==2){
		Type[Size] data = [0, 0];
		this(Type a, Type b){
			data = [a,b];
		}
	}
	
	static if(Size==3){
		Type[Size] data = [0, 0, 0];
		this(Type a, Type b, Type c){
			data = [a,b,c];
		}
	}

	static if(Size==4){
		Type[Size] data = [0, 0, 0, 0];
		this(Type a, Type b, Type c, Type d){
			data = [a,b,c,d];
		}
	}

	Type distance(Vector other){
		Type l = 0;
		for(size_t i=0; i<Size; ++i)
			l += (data[i]-other.data[i])*(data[i]-other.data[i]);
		return asqrt(l);
	}
	
	@property Type length(){
		Type f = 0;
		foreach(n; data)
			f += n*n;
		return asqrt(f);
	}
	
	static if(Size > 0)
	@property ref Type x(){
		return data[0];
	}
	
	static if(Size > 1)
	@property ref Type y(){
		return data[1];
	}
	
	static if(Size > 2)
	@property ref Type z(){
		return data[2];
	}

	bool nan(){
		static if(is(Type == int))
			return false;
		else {
			foreach(n; data)
				if(!isFinite(n))
					return true;
			return false;
		}
	}

	Type dot()(Vector other){
		Type result = 0;
		foreach(i, n; data)
			result += n*other[i];
		return result;
	}
	
	
	static Ttype dot(Ttype, Tsize)(Ttype[Tsize] a, Ttype[Tsize] b){
		Type r = 0;
		foreach(i, n; a)
			r += n*b[i];
		return r;
	}
	
	
	Vector cross()(Vector other) if(Size==3){
		return Vector(
			y*other.z - z*other.y,
			z*other.x - x*other.z,
			x*other.y - y*other.x
		);
	}

	@property Vector normal(){
		auto len = length;
		if(len)
			return this / len;
		else
			return Vector();
	}
	
	ref Type opIndex(size_t idx){
		return data[idx];
	}
	
	Vector opUnary(string op)(){
		Vector o;
		foreach(i, n; data)
			mixin("o.data[i] = " ~ op ~ "n;");
		return o;
	}
	
	Type opBinary(string op: "*")(Vector other){
		return dot(other);
	}
	
	Vector!(Size+1) opBinary(string op: "~")(Type n){
		return Vector!(Size+1)(data ~ n);
	}

	Vector opBinary(string op)(Vector other){
		Vector o;
		foreach(i, ref n; data)
			mixin("o[i] = n" ~ op ~ "other[i];");
		return o;
	}
	
	Vector opBinary(string op)(Type s){
		Vector o;
		foreach(i, ref n; data)
			mixin("o[i] = n" ~ op ~ "s;");
		return o;
	}
	
	Vector opOpAssign(string op, T)(T other){
		mixin("this = this " ~ op ~ " other;");
		return this;
	}
	
	
	string toString(){
		string s = "Vector!%(".tostring(Size);
		foreach(i, n; data)
			s ~= n.tostring(i==data.length-1 ? "": ", ");
		s ~= ")";
		return s;
	}


	Vector!(Size, T) to(T)(){
		Vector!(Size, T) r;
		foreach(i, n; data)
			r.data[i] = cast(T)n;
		return r;
	}


	alias data this;

	
}
