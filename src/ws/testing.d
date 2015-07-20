module ws.testing;

import std.string;

void assertEqual(T1, T2)(T1 o1, T2 o2){
	assert(o1 == o2, "%s not equal %s".format(o1, o2));
}

/+
void check(Args...)(){
	bool r = false;
	mixin("r = " ~ stringify!Args);
	if(!r)
		throw new Exception("Failed: " ~ stringify!Args);
}


string stringify()(){
	return "";
}

string stringify(S, Args...)(){
	return S ~= stringify!(Args);
}
+/