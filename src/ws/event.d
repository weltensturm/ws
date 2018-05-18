module ws.event;

import std.functional;

class Event(Args...){
	
	void delegate(Args)[] registered;

	void unbind(){
		registered = [];
	}

	void opOpAssign(string op)(void delegate(Args) d){
		mixin("registered " ~ op ~ "= d;");
	}
	
	void opOpAssign(string op)(void function(Args) d){
		mixin("registered " ~ op ~ "= d.toDelegate;");
	}
	
	void opCall(Args args){
		foreach(d; registered)
			d(args);
	}
	
}
