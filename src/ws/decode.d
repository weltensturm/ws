
module ws.decode;

import std.stream, std.conv, ws.io, ws.string;


private {

	alias void delegate(string, string, bool) CallbackText;
	alias void delegate(double) CallbackNum;
	alias void delegate(string) Callback;
	
	bool isCommandChar(char c){
	    // return find(" \t\n;{}", c).empty;
		return c != ' ' && c != '\t' && c != '\n' && c != ';' && c != '{' && c != '}';
	}

	bool isContentChar(char c){
	    // return find("\n\;{}", c).empty;
		return c != '\n' && c != ';' && c != '{' && c != '}';
	}

}


bool isNumberChar(char c){
	return (c>=cast(int)'0' && c<=cast(int)'9') || c=='-' || c=='+' || c=='.';
}


class Decode {


	static void text(string text, CallbackText callback){
		new Decode(false, text ~ '\n', callback);
	}


	static void file(string path, CallbackText callback){
		new Decode(true, path, callback);
	}
 

    static void file(string path, Callback[string] list, Callback[string] blist = Callback[string].init){
        file(path, (name, value, block){
            if(!block){
				if(name !in list)
					throw new Exception("No handler for \"" ~ name ~ "\"");
				list[name](value);
            }else{
            	if(name !in blist)
            		throw new Exception("No handler for \"" ~ name ~ "\" as block");
            	blist[name](value);
            }
        });
    }
    

	this(bool isFile, string what, CallbackText cb){
		callback = cb;
		if(isFile){
			myFile = new BufferedFile(what);
			getSome();
		}else
			queue = what;
		process();
		scope(exit)
			if(myFile)
				myFile.close();
	}


	bool getSome(){
		if(!myFile || myFile.eof())
			return false;

		size_t i = 0;
		char c;
		while(!myFile.eof() && i++ < 200){
			myFile.read(c);
			if(c == '\r') continue;
			queue ~= c;
			if(myFile.eof())
				queue ~= '\n';
		}
		return true;
	}


	void process(){
		string[2] data;
		size_t state = 0;
		long currentLevel = 0;
		bool inQuote = false;
		bool inComment = false;
		int line = 1;

		for(size_t i=0; i<queue.length; ++i){
			char c = queue[i];

			if(c == '\n')
				line++;

			if(inComment){
				if(c == '\n')
					inComment = false;
				else {
					if(i == queue.length-1 && !getSome())
						throw new Exception("something failed hard");
					continue;
				}
			}else if(c == '#'){
				inComment = true;
			}else if(c == '\"'){
				inQuote = !inQuote;

			}else if((state ? c.isContentChar() : c.isCommandChar()) || inQuote || currentLevel>1 || (currentLevel==1 && c != '}')){
				data[state] ~= c;

			}else if(data[0].length && !state){
				state = 1;
				
			}else if(state){
				if(!currentLevel && data[1].length){
					callback(data[0], data[1], false);
					state = 0;
					data = ["", ""];
				}
			}

			if(!inComment && !inQuote){
				if(c == '{'){
					++currentLevel;
				}else if(c == '}'){
					--currentLevel;
					if(!currentLevel){
						callback(data[0], data[1], true);
						state = 0;
						data = ["", ""];
					}else if(currentLevel < 0)
						error(line, "Too many }");
				}
			}

			if(i == queue.length-1 && !getSome()){
				if(currentLevel)
					error(line, "Unfinished {} block in text");
				else if(data[0].length)
					error(line, "Unfinished command, queue: %s".format(queue));
				else if(data[1].length)
					error(line, "Unfinished argument");
			}

		}
	}


	private:
		void error(long line, string s){
			throw new Exception("[" ~ tostring(line) ~ "]: " ~ s);
		}

		string queue;
		string comments;
		CallbackText callback;
		bool wholeBlock = true;
		BufferedFile myFile;
};



unittest {
	string t =
			"level1 {\n"
			"	level2item1 cookies\n"
			"	level2item2 hurr\n"
			"#	level2comment awesomeness\n"
			"}";
			
	Decode.text(t, delegate(string cmd, string args, bool b){
		assert(b && cmd == "level1");
		Decode.text(args, delegate(string cmd2, string args2, bool b2){
			assert(!b2);
			if(cmd2 == "level2item1")
				assert(args2 == "cookies");
			else if(cmd2 == "level2item2")
				assert(args2 == "hurr");
			else
				assert(0);
		});
	});
}


void toNumbers(string text, CallbackNum callback){
	string n;
	foreach(i, c; text){
		if(isNumberChar(c)){
			n ~= c;
			if(i == text.length-1)
				callback(to!real(n));
		}else if(n.length){
			callback(to!real(n));
			n = "";
		}
	}
}


double[] toNumbers(string text){
	size_t current;
	double[] numbers;
	string n;
	foreach(i, c; text){
		if(isNumberChar(c)){
			n ~= c;
			if(i == text.length-1)
				numbers ~= to!real(n);
		}else if(n.length){
			numbers ~= to!real(n);
			n = "";
		}
	}
	return numbers;
}

