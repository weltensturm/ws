module ws.nullable;

class Nullable(T){
	this(T data){
		this.data = data;
	}
	T data;
	alias data this;
}

