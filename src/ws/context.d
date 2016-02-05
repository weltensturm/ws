module ws.context;


import
	core.sync.mutex,
	std.string,
	std.stdio,
	std.process,
	std.parallelism,
	std.regex,
	std.algorithm,
	std.array,
	std.file;


void execute(string context, string type, string serialized, string command, string parameter=""){
	auto dg = {
		try{
			string command = (command.strip ~ ' ' ~ parameter).strip;
			if(!serialized.length)
				serialized = command;
			"running: \"%s\" in %s".format(command, context).writeln;
			auto pipes = pipeShell(command);
			auto pid = pipes.pid.processID;
			context.logExec(formatExec(pid, type, serialized, parameter));
			auto reader = task({
				foreach(line; pipes.stdout.byLine){
					if(line.length)
						context.log("%s stdout %s".format(pid, line));
				}
			});
			reader.executeInNewThread;
			foreach(line; pipes.stderr.byLine){
				if(line.length)
					context.log("%s stderr %s".format(pid, line));
			}
			reader.yieldForce;
			auto res = pipes.pid.wait;
			context.log("%s exit %s".format(pid, res));
			context.logExec("%s exit %s".format(pid, res));
		}catch(Throwable t)
			writeln(t);
	};
	task(dg).executeInNewThread;
}


void openFile(string context, string path){
	context.openPath(path, "file");
}


void openDir(string context, string path){
	context.openPath(path, "directory");
}


void openPath(string context, string path, string type){
	auto command = `exo-open "%s" || xdg-open "%s"`.format(path,path);
	context.execute(type, path, command);
}


string[] bangSplit(string text){
	return text.split(regex(`(?<!\\)\!`)).map!`a.replace("\\!", "!")`.array;
}

string bangJoin(string[] parts){
	return parts.map!`a.replace("!", "\\!")`.join("!");
}


string formatExec(long pid, string type, string serialized, string parameter){
	return "%s exec %s!%s!%s".format(pid, type, serialized, parameter);
}


string unixEscape(string path){
	return path
		.replace(" ", "\\ ")
		.replace("(", "\\(")
		.replace(")", "\\)");
}

string unixClean(string path){
	return path
		.replace("\\ ", " ")
		.replace("\\(", "(")
		.replace("\\)", ")");
}


__gshared private Mutex logMutex;

shared static this(){
	logMutex = new Mutex;
}

void log(string context, string text){
	synchronized(logMutex){
		auto path = context ~ ".log";
		if(path.exists)
			path.append(text ~ '\n');
		else
			std.file.write(path, text ~ '\n');
	}
}

void logExec(string context, string text){
	context.log(text);
	synchronized(logMutex){
		auto path = context ~ ".exec";
		if(path.exists)
			path.append(text ~ '\n');
		else
			std.file.write(path, text ~ '\n');
	}
}

