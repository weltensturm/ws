module ws.log;

import
	core.sync.mutex,
	std.array,
	std.conv,
	std.algorithm;


class Log {

	enum Level {
		info,
		warning,
		error
	}

	alias Logger = void delegate(Level, string, string, size_t);

	private __gshared Logger[] loggers;
	private __gshared Mutex lock;

	shared static this(){
		lock = new Mutex;
	}

	static auto addLogger(Logger logger){
		synchronized(lock){
			loggers ~= logger;
		}
		return logger;
	}

	static void removeLogger(Logger logger){
		synchronized(lock){
			loggers = loggers.filter!(a => a != logger).array;
		}
	}

	static string format(Args...)(Args args){
		string result;
		foreach(s; args){
			result ~= s.to!string;
		}
		return result;
	}

	static void log(Level level, string s, string file, size_t line){
		synchronized(lock){
			foreach(logger; loggers){
				logger(level, s, file, line);
			}
		}
	}

	static void info(string file=__FILE__, size_t line=__LINE__, Args...)(Args args){
		log(Level.info, format(args), file, line);
	}

	static void warning(string file=__FILE__, size_t line=__LINE__, Args...)(Args args){
		log(Level.warning, format(args), file, line);
	}

	static void error(string file=__FILE__, size_t line=__LINE__, Args...)(Args args){
		log(Level.error, format(args), file, line);
	}

}
