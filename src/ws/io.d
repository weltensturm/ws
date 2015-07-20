

module ws.io;

import std.stdio, std.utf, ws.string;

__gshared:

void write(Args...)(Args args) nothrow {
	try {
		writeFunc(tostring(args));
	}catch(Exception e){
		try{
			std.stdio.write("writeFunc failed");
			std.stdio.writeln(e.toString());
			std.stdio.stdout.flush();
		}catch(Exception e)
			assert(0, "writeln raised an exception");
	}
}

void writeln(Args...)(Args args) nothrow {
	write(args, '\n');
}

void delegate(string) writeFunc;

shared static this(){
	writeFunc = delegate(string s){
		std.stdio.write(s);
		std.stdio.stdout.flush();
	};
}
