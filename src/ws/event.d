module ws.event;

import ws.list;

class Event(Args...){
	
	this(){
		list = new List!(void delegate(Args));
	}
	
	void opOpAssign(string op)(void delegate(Args) d){
		mixin("list " ~ op ~ "= d;");
	}
	
	void opCall(Args args){
		foreach(d; list)
			d(args);
	}
	
	List!(void delegate(Args)) list;
	
}
