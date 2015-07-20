module ws.log;

import std.file, std.datetime, ws.io;

class Log {

	static string path = "errors.log";

	static void info(string s){
		append(path, "\n[INFO] " ~ Clock.currTime().toString() ~ "\n" ~ s ~ "\n");
		writeln("[INFO] " ~ s);
	}

	static void warning(string s){
		append(path, "\n[WARNING] " ~ Clock.currTime().toString() ~ "\n" ~ s ~ "\n");
		writeln("[WARNING] " ~ s);
	}

	static void error(string s){
		append(path, "\n[ERROR] " ~ Clock.currTime().toString() ~ "\n" ~ s ~ "\n");
		writeln("[ERROR] " ~ s);
	}

}
