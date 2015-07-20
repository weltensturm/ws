
module ws.list;

import std.conv, ws.io;

__gshared:


class List(T) {

	protected {

		struct Node {
			T obj;
			Node* prev;
			Node* next;
		}

		Node* mBegin;
		Node* mEnd;
		size_t mLength;

		alias Type = T;

	}


	TList opCast(TList)(){
		auto list = new TList;
		foreach(e; this)
			list ~= cast(TList.Type)e;
		return list;
	}


	Node* checkBegin(){
		if(!mBegin){
			mBegin = new Node;
			mEnd = mBegin;
		}
		return mBegin;
	}

	Node* checkEnd(){
		checkBegin();
		return mEnd;
	}

	ref T opIndex(size_t idx){
		assert(idx < mLength);
		Node* it = mBegin;
		while(idx--)
			it = it.next;
		return it.obj;
	}
	
	void opOpAssign(string op)(T e){
		static if(op=="~")
			push(e);
		else static if(op=="-")
			remove(e);
		else static assert(0, "Operator " ~ op ~ " not implemented");
	}
	
	void push(T e){
		if(!mBegin){
			mBegin = new Node;
			mBegin.obj = e;
			mEnd = mBegin;
		}else{
			mEnd.next = new Node;
			mEnd.next.prev = mEnd;
			mEnd.next.obj = e;
			mEnd = mEnd.next;
		}
		++mLength;
	}
	
	void pushFront(T e){
		if(!mBegin){
			mBegin = new Node;
			mBegin.obj = e;
			mEnd = mBegin;
		}else{
			mBegin.prev = new Node;
			mBegin.prev.next = mBegin;
			mBegin.prev.obj = e;
			mBegin = mBegin.prev;
		}
		++mLength;
	}


	Iterator insert(Iterator where, T obj, bool before = false){
		auto node = new Node;
		node.next = (before ? where.node : where.node.next);
		node.prev = (before ? where.node.prev : where.node);
		node.obj = obj;
		if(node.next)
			node.next.prev = node;
		if(node.prev)
			node.prev.next = node;
		++mLength;
		return Iterator(node);
	}


	ref T popBack(){
		assert(mLength, "list is empty");
		auto tmp = mEnd;
		if(mEnd.prev){
			mEnd.prev.next = null;
			mEnd = tmp.prev;
			--mLength;
		}else
			clear();
		return tmp.obj;
	}
	
	ref T popFront(){
		assert(mLength, "list is empty");
		auto tmp = mBegin;
		if(mBegin.next){
			mBegin.next.prev = null;
			mBegin = mBegin.next;
			--mLength;
		}else
			clear();
		return tmp.obj;
	}

	void remove(T e){
		auto it = mBegin;
		while(it){
			if(it.obj == e) break;
			it = it.next;
		}
		if(!it)
			throw new Exception("element not in list");
		remove(Iterator(it));
	}


	void remove(Iterator it){
		if(it.node.prev)
			it.node.prev.next = it.node.next;
		else
			mBegin = it.node.next;
		if(it.node.next)
			it.node.next.prev = it.node.prev;
		else
			mEnd = it.node.prev;
		--mLength;
	}
	
	
	List opBinary(string op)(List other) if(op=="~"){
		auto n = new List;
		foreach(c; this)
			n.push(c);
		foreach(c; other)
			n.push(c);
		return n;
	}
	
	
	int opApply(int delegate(Iterator,T) callback){
		int result = 0;
		auto it = begin();
		while(it){
			result = callback(it, it.get());
			it = it.next;
			if(result)
				break;
		}
		return result;
	}

	int opApply(int delegate(T) cb){
		return opApply((i, T e){
			return cb(e);
		});
	}
	
	
	int opApplyReverse(int delegate(T) callback){
		int result = 0;
		auto it = mEnd;
		while(it){
			auto obj = it.obj;
			it = it.prev;
			result = callback(obj);
			if(result) break;
		}
		return result;
	}
	
	
	override string toString(){
		string tmp = "List!" ~ typeid(T).toString() ~ " = [\n";
		auto it = mBegin;
		while(it){
			tmp ~= "\t" ~ to!string(it.obj) ~ ",\n";
			it = it.next;
		}
		tmp ~= "]";
		return tmp;
	}
	
	
	@property bool empty() const {
		return !mBegin;
	}
	

	void clear(){
		mBegin = null;
		mEnd = null;
		mLength = 0;
	}
	
	
	@property ref T front(){
		assert(mBegin);
		return mBegin.obj;
	}

	@property void front(ref T f){
		assert(mBegin);
		mBegin.obj = f;
	}
	

	@property ref T back(){
		assert(mEnd);
		return mEnd.obj;
	}

	@property void back(ref T b){
		assert(mEnd);
		mEnd.obj = b;
	}

	@property nothrow size_t length(){
		return mLength;
	}


	@property nothrow Iterator begin(){
		return Iterator(mBegin);
	}
	
	
	@property nothrow Iterator end(){
		return Iterator(mEnd);
	}
	
	
	struct Iterator {

		Node* node;

		T get(){
			return node.obj;
		}

		@property Iterator prev(){
			return Iterator(node.prev);
		}

		@property Iterator next(){
			return Iterator(node.next);
		}

		private nothrow this(Node* node){
			this.node = node;
		}

		bool opCast(T)() if(is(T==bool)) {
			return node !is null;
		}

		Iterator opUnary(string s)(){
			static if(s == "++"){
				if(node.next)
					node = node.next;
			}else static if(s == "--"){
				if(node.prev)
					node = node.prev;
			}else
				assert(false, "Not implemented");
			return this;
		}

	}

	
	unittest {
		auto test = new List!int;
		test.push(5);
		test.push(10);
		assert(test.mLength == 2);
		
		assert(test[0]*test[1] == 5*10);
		
		test.remove(5);
		assert(test.mLength == 1);
		
		assert(test[0] == 10);
		
		test.push(12);
		auto it = test.end();
		test.insert(it, 11, true);
		
		assert(test.mLength == 3);
		
		foreach(i; test)
			if(i == 11){
				test.remove(i);
				test.push(100);
			}
		
		assert(test[0] == 10);
		assert(test[1] == 12);
		assert(test[2] == 100);
		assert(test.mLength == 3);
		
		test.back *= 5;
		assert(test.back == 500);
		
		foreach(i; test)
			test.popFront();
		assert(test.mLength == 0);
			
	}

}


