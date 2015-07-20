module ws.script.lua;

import
	ws.list,
	ws.io,
	ws.exception,
	ws.string,
	ws.sys.library;

__gshared:


class Lua {

	class Var {

		enum: int { Number, String, Table, Reference };

		int reference;

		this(int t){
			if(t == Number)
				push(0);
			else if(t == String)
				push("");
			else if(t == Table)
				lua_createtable(state, 0, 0);
			reference = luaL_ref(state, LUA_REGISTRYINDEX);
		}

		void setTop(){
			lua_rawgeti(state, LUA_REGISTRYINDEX, reference);
		}

		~this(){
			luaL_unref(state, LUA_REGISTRYINDEX, reference);
		}

		bool valid(){
			setTop();
			scope(exit)
				lua_pop(state, 1);
			return lua_type(state, -1) != 0;
		}

		Var opIndex(string s){
			mixin(checkstack);
			setTop();
			scope(exit)
				lua_pop(state, 1);
			lua_getfield(state, LUA_REGISTRYINDEX, s.toStringz());
			return new Var(Reference);
		}

		void opIndexAssign(T)(T value, string key){
			mixin(checkstack);
			setTop();
			push(value);
			lua_setfield(state, -2, key.toStringz());
			lua_pop(state, 1);
		}

		void opIndexAssign(T)(T value, int key){
			opIndexAssign(value, tostring(key));
		}

		int opApply(int delegate(Var) dg){
			mixin(checkstack);
			setTop();
			if(lua_type(state, -1) != 5)
				throw new Exception("Lua Var is not a table, cannot iterate");
			int result = 0;
			lua_pushnil(state);
			Var[] list;
			while(lua_next(state, -2))
				list ~= new Var(Reference);
			foreach(v; list){
				result = dg(v);
				if(result)
					break;
			}
			return result;
		}


		int opApply(int delegate(string, Var) dg){
			mixin(checkstack);
			setTop();
			if(lua_type(state, -1) != 5)
				throw new Exception("Lua Var is not a table, cannot iterate");
			int result = 0;
			lua_pushnil(state);
			Var[string] list;
			while(lua_next(state, -2)){
				bool n = false;
				if(lua_isnumber(state, -2)){
					setTop();
					lua_pushvalue(state, -3);
					lua_pushvalue(state, -3);
					n = true;
				}
				list[Lua.toString(-2)] = new Var(Reference);
				if(n)
					lua_settop(state, -(3)-1);
			}
			lua_pop(state, 1);
			foreach(k, e; list){
				result = dg(k, e);
				if(result)
					break;
			}
			return result;
		}


		Var opCall(Args...)(Args args){
			mixin(checkstack);
			int i=lua_gettop(state);
			scope(exit)
				assert(i == lua_gettop(state));
			setTop();
			foreach(a; args)
				push(a);
			check(lua_pcall(state, args.length, 1, 0));
			return new Var(Var.Reference);
		}

		override string toString(){
			mixin(checkstack);
			setTop();
			scope(exit)
				lua_pop(state, 1);
			if(!valid()){
				return "nil";
			}else if(getType() == "table"){
				if(true)
					return "Table: 0x" ~ tostring(lua_topointer(state, -1));
				else{
					string s = "{\n";
					foreach(k, e; this)
						s ~= indent(k ~ " = " ~ e.toString()) ~ "\n";
					s ~= "}";
					return s;
				}
			}else if(getType() == "userdata"){
				if(this["__tostring"].valid()){
					return this["__tostring"]().toString();
				}else{
					PtrContainer!(void*) container = *cast(PtrContainer!(void*)*)lua_touserdata(state, -1);
					return "Userdata: 0x" ~ tostring(cast(void*)container.reference);
				}
			}else if(getType() == "function"){
				return "Function: 0x" ~ tostring(lua_topointer(state, -1));
			}else{
				return tostring(luaL_checklstring(state, -1, null));
			}
		}


		T userdata(T)(){
			mixin(checkstack);
			setTop();
			scope(exit)
				lua_pop(state, 1);
			return getUserdata!T("", -1);
		}


		void invalidate(){
			setTop();
			lua_getfield(state, LUA_REGISTRYINDEX, "nil");
			lua_setmetatable(state, -2);
		}

		void setMetatable(string s){
			mixin(checkstack);
			setTop();
			luaL_getmetatable(state, s.toStringz());
			if(lua_type(state, -1) == 0)
				writeln("Warning: " ~ s ~ " is nil");
			//metatable(s).setTop();
			lua_setmetatable(state, -2);
			lua_pop(state, 1);
		}

		Var getMetatable(){
			mixin(checkstack);
			setTop();
			scope(exit)
				lua_pop(state, 1);
			lua_getmetatable(state, -1);
			return new Var(Var.Reference);
		}

		string getType(){
			mixin(checkstack);
			setTop();
			scope(exit)
				lua_pop(state, 1);
			int t = lua_type(state, -1);
			return tostring(lua_typename(state, t));
		}

		private string indent(string s){
			string n = "\t";
			foreach(c; s){
				n ~= c;
				if(c == '\n')
					n ~= '\t';
			}
			return n;
		}

	}
	
	
	void run(string s){
		check(luaL_loadstring(state, s.toStringz()) || lua_pcall(state, 0, -1, 0));
	}
	

	void runFile(string path){
		fileStack ~= path;
		check(luaL_loadfile(state, path.toStringz()) || lua_pcall(state, 0, -1, 0));
		fileStack.popBack();
	}


	Var opIndex(string key){
		mixin(checkstack);
		lua_getfield(state, LUA_GLOBALSINDEX, key.toStringz());
		return new Var(Var.Reference);
	}


	void opIndexAssign(T)(T t, string key){
		mixin(checkstack);
		push(t);
		lua_setfield(state, LUA_GLOBALSINDEX, key.toStringz());
	}
	

	Var table(Args...)(Args args){
		mixin(checkstack);
		lua_createtable(state, 0, 0);
		pushField(args);
		return new Var(Var.Reference);
	}


	Var metatable(string n){
		mixin(checkstack);
		luaL_newmetatable(state, n.toStringz());
		return new Var(Var.Reference);
	}


	/+
	void startMetatable(string name){
		luaL_newmetatable(state, name.toStringz());
	}
	+/

	Var newUserdata(T)(T e, string n=""){
		mixin(checkstack);
		assert(e);
		//n = (n.length ? n : typeid(T).toString());
		auto container = cast(PtrContainer!T*)lua_newuserdata(state, (PtrContainer!T).sizeof);
		//lua_getfield(state, LUA_GLOBALSINDEX, n.toStringz());
		//lua_pushstring(state, "__index");
		//lua_pushvalue(state, -2);
		//lua_settable(state, -3); // metatable.__index = metatable
		//lua_setmetatable(state, -2);
		container.reference = e;
		return new Var(Var.Reference);
	}


	protected {

		string printStack(){
			mixin(checkstack);
			string s = "Lua Stack {\n";
			for(int i=1; i<=lua_gettop(state); i++){
				lua_pushvalue(state, i);
				auto v = new Var(Var.Reference);
				s ~= "\t%s = %s\n".format(i, v);
			}
			s ~= "}\n";
			return s;
		}
	
		string toString(int i){
			return tostring(luaL_checklstring(state, i, null));
		}
	
	
		T get(T)(int idx){
			static if(is(T == string))
				return toString(idx);
			else static if(is(T == double) || is(T==long) || is(T==int))
				return cast(T)luaL_checknumber(state, idx);
			else static if(is(T == Var)){
				lua_pushvalue(state, idx);
				return new Var(Var.Reference);
			}else
				return getUserdata!T();
			//else static assert(0, "Return type not implemented");
		}
		
		void push(Ret, Args...)(Ret function(Args) f){
			push(delegate Ret(Args args){ return f(args); });
		}
		
		void push(Ret, Args...)(Ret delegate(Args) f){
			push(delegate int(int argc) nothrow {
				try {
					Args args;
					foreach(i, T; Args)
						args[i] = get!T(i+1);
					static if(is(Ret==void)){
						f(args);
						return 0;
					}else{
						push(f(args));
						return 1;
					}
				}catch(Exception e)
					writeln("Error in delegate: ", e);
				return 0;
			});
		}
		
		void push()(double n){
			lua_pushnumber(state, n);
		}
		
		void push()(string s){
			lua_pushstring(state, s.toStringz());
		}
		
		void push()(Var v){
			v.setTop();
		}
		
		void push()(Function f){
			closures ~= f;
			lua_pushnumber(state, closures.length-1);
			lua_pushcclosure(state, &staticClosure, 1);
		}
		
	
		void pushField()(){}
	
	
		void pushField(Args...)(string c, string g, Args args){
			lua_pushstring(state, n.toStringz);
			lua_getfield(state, LUA_GLOBALSINDEX, n.toStringz);
			lua_settable(state, -3);
			pushField(args);
		}
	
	
		void pushField(T, Args...)(string n, T t, Args args){
			push(t);
			lua_setfield(state, -2, n.toStringz());
			pushField(args);
		}


		private struct PtrContainer(T) {
			T reference;
		}


		/// return reference to userdata on stack
		T getUserdata(T)(string n="", int i = 1){
			mixin(checkstack);
			n = (n.length ? n : typeid(T).toString());
			auto container = cast(PtrContainer!T*)lua_touserdata(state, i);
			if(!container)
				luaL_argerror(state, i, "'%s' expected".format(n).toStringz());
			return container.reference;
			/+ Checks if ud's metatable is the same as luaL_getmetatable(state,n)
			n = (n.length ? n : typeid(T).toString());
			auto container = cast(PtrContainer!T*)luaL_checkudata(state, i, n.toStringz());
			if(!container)
				luaL_argerror(state, i, "'%' expected".format(n).toStringz());
			return container.reference;
			+/
		}

	}


	alias nothrow int delegate(int) Function;

	protected {
		/+
		const static string checkstack = "
			int checkstacksize=lua_gettop(state);
			scope(exit)
				assert(checkstacksize == lua_gettop(state), \"Before: \" ~ tostring(checkstacksize) ~ \"\nNow: \" ~ printStack());
		";
		+/
		const static string checkstack = ""; 
		Library library;
		state_ptr state;
		List!string fileStack;
		Function[] closures;
		size_t closureCurrent = 0;
	}

	this(){
		library = luaLib.load();
		state = luaL_newstate();
		//luaL_openlibs(state);
		luaopen_base(state);
		luaopen_table(state);

		/*lua_pushcclosure(state, luaopen_table, 0);
		pushLiteral("table");
		lua_call(state, 1, 0);*/
		fileStack = new List!string;
		states[state] = this;
	}


	~this(){
		lua_close(state);
	}


	state_ptr getState(){
		return state;
	}
	

	private void check(int e){
		if(e){
			writeln("Lua error: ", lua_tolstring(state, -1, null));
			lua_settop(state, -2);
		}
	}


	static Lua[state_ptr] states;


	extern(C) static int staticClosure(state_ptr state){
		return states[state].closures[cast(size_t)lua_tonumber(state,-10003)](lua_gettop(state));
	}


}


extern(C){
	const int LUA_REGISTRYINDEX	= -10000;
	const int LUA_ENVIRONINDEX = -10001;
	const int LUA_GLOBALSINDEX = -10002;

	alias void* state_ptr;

	alias int function(state_ptr) lua_CFunction;

	version(Windows)
		private const string LibraryFile = "lua51";
	version(Posix)
		private const string LibraryFile = "lua5.1";

	void lua_pop(state_ptr state, int n){
		lua_settop(state, -(n)-1);
	}

	void luaL_getmetatable(state_ptr s, const(char)* n){
		lua_getfield(s, LUA_REGISTRYINDEX, n);
	}

	mixin library!(
		"luaLib", LibraryFile,
		"luaL_newstate", state_ptr function(),
		"luaL_openlibs", void function(state_ptr),
		"luaL_newmetatable", void function(state_ptr, const(char)*),
		"luaL_checknumber", double function(state_ptr, int),
		"luaL_loadstring", int function(state_ptr, const(char)*),
		"luaL_loadfile", int function(state_ptr, const(char)*),
		"luaL_checkudata", void* function(state_ptr, int, const(char)*),
		"luaL_argerror", int function(state_ptr, int, const(char)*),
		"luaL_ref", int function(state_ptr, int),
		"luaL_unref", void function(state_ptr, int, int),
		"lua_setfield", void function(state_ptr, int, const(char)*),
		"lua_getfield", void function(state_ptr, int, const(char)*),
		"lua_pcall", int function(state_ptr, int, int, int),
		"lua_call", void function(state_ptr, int, int),
		"luaL_checklstring", const(char*) function(state_ptr, int, size_t*),
		"luaopen_base", int function(state_ptr),
		"luaopen_table", int function(state_ptr),
		"lua_close", void function(state_ptr),
		"lua_createtable", void function(state_ptr, int, int),
		"lua_setmetatable", int function(state_ptr, int),
		"lua_getmetatable", int function(state_ptr, int),
		"lua_settable", void function(state_ptr, int),
		"lua_pushvalue", void function(state_ptr, int),
		"lua_isstring", int function(state_ptr, int),
		"lua_isnumber", int function(state_ptr, int),
		"lua_settop", void function(state_ptr, int),
		"lua_gettop", int function(state_ptr),
		"lua_tonumber", double function(state_ptr, int),
		"lua_tolstring", const(char)* function(state_ptr, int, size_t*),
		"lua_touserdata", void* function(state_ptr, int),
		"lua_topointer", void* function(state_ptr, int),
		"lua_pushstring", void function(state_ptr, const char*),
		"lua_pushnumber", void function(state_ptr, double),
		"lua_pushcclosure", "void function(state_ptr, lua_CFunction, int)",
		"lua_newuserdata", void* function(state_ptr, size_t),
		"lua_rawseti", void function(state_ptr, int, int),
		"lua_rawgeti", void function(state_ptr, int, int),
		"lua_pushnil", void function(state_ptr),
		"lua_next", int function(state_ptr, int),
		"lua_type", int function(state_ptr, int),
		"lua_typename", const(char)* function(state_ptr, int)
	);
	
}
