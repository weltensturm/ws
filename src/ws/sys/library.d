
module ws.sys.library;

import
	std.string,
	std.conv,
	std.traits,
	ws.log;

version(Windows) import derelict.util.wintypes;
version(Posix) import core.sys.posix.dlfcn;


string embedFunc(string n, string t)(){
	return t ~ ' ' ~ n ~ ";\n";
}

string embedFunc(string n, T)(){
	return fullyQualifiedName!T ~ ' ' ~ n ~ ";\n";
}

string getFunc()(){
	return "";
}

string getFunc(string n, T, More...)(){
	return embedFunc!(n, T)() ~ getFunc!More();
	//return t ~ ' ' ~ n ~ ";\n" ~ getFunc!More();
}

string getFunc(string n, string t, More...)(){
	return embedFunc!(n, t)() ~ getFunc!More();
}

string loadFunc(string f)(){
	return f ~ " = cast(typeof(" ~ f ~ "))l.get(\"" ~ f ~ "\");";
}


Library fillLibrary(alias Fillable)(string path){
	auto library = new Library(path);
	foreach(member; __traits(allMembers, Fillable)){
		mixin("enum isFP = isFunctionPointer!(Fillable." ~ member ~ ");");
		static if(isFP){
			mixin("assert(!hasUnsharedAliasing!(typeof(Fillable." ~ member ~ ")));");
			mixin("Fillable." ~ member ~ " = cast(typeof(Fillable." ~ member ~ "))library.get(member);");
			mixin("assert(Fillable." ~ member ~ " != null);");
		}
	}
	return library;
}


mixin template library(string refname, string name, Args...){

	mixin("
		struct " ~ refname ~ " {
			import ws.log;
			__gshared Library lib;
			shared static this(){
				try
					lib = load();
				catch(Exception e){
					ws.log.Log.error(e.toString());
					throw e;
				}
			}
			static Library load(){
				Library l = new Library(\"" ~ name ~ "\");
				loadFuncs!Args(l);
				return l;
			}
		}
	");
	
	void loadFuncs(string f, More...)(Library l){
		mixin(loadFunc!(f)());
		static if(More.length >= 2)
			loadFuncs!(More[1..$])(l);
	}

	// put last due to possible override
	mixin(getFunc!Args());

}

class Library {

	void* get(string s){
		void* p = null;
		version(Windows)
			p = GetProcAddress(lib, s.toStringz());
		version(Posix)
			p = dlsym(lib, s.toStringz);
		if(!p)
			throw new Exception("Failed to load symbol \"" ~ s ~ "\": " ~ getError());
		return p;
	}
	

	T call(T, string name, Args...)(Args args){
		alias T function(Args) FT;
		static FT func;
		if(!func)
			func = cast(FT)get(name);
		return func(args);
	}
	

	this(string s, string vers = ""){
		version(Windows)
			lib = LoadLibraryA(s.toStringz());
		version(Posix)
			lib = dlopen(("lib" ~ s ~ ".so" ~ vers).toStringz(), RTLD_NOW);
		if(!lib)
			throw new Exception("Failed to load library \"" ~ s ~ "\": " ~ getError());
	}


	~this(){
		version(Windows)
			FreeLibrary(lib);
		version(Posix)
			dlclose(lib);
	}

	version(Windows) private HMODULE lib;
	version(Posix) private void* lib;

	private string getError(){
		version(Windows){
			DWORD errcode = GetLastError();
			LPCSTR msgBuf;
			DWORD i = FormatMessageA(
				FORMAT_MESSAGE_ALLOCATE_BUFFER |
				FORMAT_MESSAGE_FROM_SYSTEM |
				FORMAT_MESSAGE_IGNORE_INSERTS,
				null,
				errcode,
				MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
				cast(LPCSTR)&msgBuf,
				0,
				null);
			string text = to!string(msgBuf);
			LocalFree(cast(HLOCAL)msgBuf);
			if(i >= 2)
				i -= 2;
			return text[0 .. i] ~ " (%s)".format(errcode);
		}version(Posix){
			auto err = dlerror();
			if(!err)
				return "Unknown Error";
			return to!string(err);		
		}
	}
}


class AutoLibrary {

	protected {
		Library lib;
		string prefix;

	}

	this(string name, string prefix){
		this.prefix = prefix;
		lib = new Library(name);
	}



}

