module ws.exception;

import ws.string;

__gshared:


class exception: Exception {

	static void opCall(string t, string file = __FILE__, size_t line = __LINE__){
		throw new exception(t, file, line);
	}

	static void opCall(string t, Exception cause, string file = __FILE__, size_t line = __LINE__){
		throw new exception(t, cause, file, line);
	}

	static bool showSource = true;

	private static long count = 0;
	long current;

	this(string msg, string file, size_t line){
		current = ++count;
		super(msg, null, file, line);
	}

	this(string msg, Exception cause, string file, size_t line){
		current = count;
		super(msg, cause, file, line);
	}

	override string toString(){
		string m;
		if(next)
			m ~= '\n' ~ next.toString();
		return showSource ? tostring("[%] %[%]: ", current, file, line, msg, m) : msg ~ m;
	}	
}
