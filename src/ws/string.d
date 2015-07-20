
module ws.string;

public import std.string;
import std.conv;

__gshared:

static dchar formatChar = '%';

string tostring(Args...)(Args args){
	try {
		static if(args.length > 0){
			static if(is(typeof(args[0]) == string) && args.length >= 2){
				if(args[0].find(formatChar) < args[0].length){
					size_t i = args[0].find(formatChar);
					return args[0][0..i] ~ to!string(args[1]) ~ tostring(args[0][i+1..$], args[2..$]);
				}else
					return args[0] ~ to!string(args[1]) ~ tostring(args[2..$]);
			}else
				return to!string(args[0]) ~ tostring(args[1..$]);
		}else
			return "";
	}catch(Exception e){
		return "tostring error\n" ~ e.toString();
	}
}

size_t find(string s, string what, size_t start = 0){
	size_t right = 0;
	foreach(i, c; s){
		if(c == what[right])
			right++;
		else
			right = 0;
		if(right == what.length)
			return i - right + 1;
	}
	return s.length;
}

size_t find(string s, dchar what, size_t start = 0){
	for(; start < s.length; start++)
		if(s[start] == what)
			return start;
	return s.length;
}

unittest {
	auto s = "hello there";
	assert(s.find("there!") == s.length);
	assert(s.find("there") == 6);
	assert(s.find('r') == 9);
}

/*
size_t findLast(string s, string what, size_t start = 0){
	size_t right = 0;
	foreach_reverse(i, c; s){
		if(c == what[$-right])
			right++;
		else
			right = 0;
		if(right == what.length)
			return i - right + 1;
	}
	return s.length;
}
*/

size_t findLast(string s, dchar what, size_t start = 0){
	if(!start) start = s.length-1;
	for(; start < s.length; start--)
		if(s[start] == what)
			return start;
	return s.length;
}

unittest {
	assert("hello there".findLast('l') == 3);
}

string[] split(string what, string splitter){
	string[] v;
	string tmp = what;
	for(size_t i = tmp.find(splitter); i < tmp.length; i = tmp.find(splitter)){
		v ~= tmp[0..i];
		tmp = tmp[i+splitter.length..$];
	}
	if(tmp.length)
		v ~= tmp;
	return v;
}

string[] split(string what, dchar splitter){
	string[] v;
	size_t last = 0;
	foreach(i, dchar c; what){
		if(c == splitter){
			v ~= what[last .. i];
			last = i+1;
		}
	}
	if(last < what.length)
		v ~= what[last..$];
	return v;
}


unittest {
	assert("a b c d efg".split(" ") == ["a", "b", "c", "d", "efg"]);
}