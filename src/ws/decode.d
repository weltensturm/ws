
module ws.decode;

import std.stdio, std.conv, ws.io, ws.string;


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


	private {
		void error(long line, string s){
			throw new Exception("[" ~ tostring(line) ~ "]: " ~ s);
		}

		string queue;
		string comments;
		CallbackText callback;
		bool wholeBlock = true;
		File* myFile;
	}

	static void text(string text, CallbackText callback){
		new Decode(false, text ~ '\n', callback);
	}


	static void file(string path, CallbackText callback){
		try
			new Decode(true, path, callback);
		catch(Exception e){
			throw new Exception("Error in file \"" ~ path ~ "\"", e);
		}
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
			myFile = new File(what, "r");
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
		char[1] buf;
		while(!myFile.eof() && i++ < 200){
			myFile.rawRead(buf);
			if(buf.length){
				auto c = buf[0];
				if(c == '\r')
					continue;
				queue ~= c;
			}else{
				queue ~= '\n';
				break;
			}
		}
		return true;
	}


	void process(){
		string[2] data;
		size_t state = 0;
		long currentLevel = 0;
		bool inString = false;
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
				inString = !inString;

			}else if((state ? c.isContentChar() : c.isCommandChar()) || inString || currentLevel>1 || (currentLevel==1 && c != '}')){
				data[state] ~= c;

			}else if(data[0].strip.length && !state){
				state = 1;
				
			}else if(state){
				if(!currentLevel && data[1].length){
					callback(data[0].strip, data[1].strip, false);
					state = 0;
					data = ["", ""];
				}
			}

			if(!inComment && !inString){
				if(c == '{'){
					state = 1;
					++currentLevel;
				}else if(c == '}'){
					--currentLevel;
					if(!currentLevel){
						callback(data[0].strip, data[1].strip, true);
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

};



unittest {
	string t =
			"level1 {\n" ~
			"	level2item1 cookies\n" ~
			"	level2item2 hurr\n" ~
			"#	level2comment awesomeness\n" ~
			"	level3block {\n" ~
			"		a 1\n" ~
			"	}\n" ~
			"}";
			
	Decode.text(t, delegate(string cmd, string args, bool b){
		assert(b && cmd == "level1");
		Decode.text(args, delegate(string cmd2, string args2, bool b2){
			assert(b2 == (cmd2 == "level3block"));
			if(cmd2 == "level2item1")
				assert(args2 == "cookies");
			else if(cmd2 == "level2item2")
				assert(args2 == "hurr");
			else if(cmd2 == "level3block"){
				assert(args2.strip() == "a 1");
			}else
				assert(0);
		});
	});

	string anonblocks =
			"level1 {\n" ~
			"	{\n" ~
			"		a 1\n" ~
			"	 }\n" ~
			"	{ b 2 }\n" ~
			"}\n";

	Decode.text(anonblocks, delegate(string cmd, string args, bool b){
		assert(b && cmd == "level1");
		Decode.text(args, delegate(string cmd2, string args2, bool b2){
			assert(b2);
			Decode.text(args2, delegate(string cmd3, string args3, bool b3){
				if(cmd3 == "a")
					assert(args3 == "1");
				else if(cmd3 == "b")
					assert(args3 == "2");
				else
					assert(false);
			});
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

