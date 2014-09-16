module ws.testing;

import std.string;

void assertEqual(T1, T2)(T1 o1, T2 o2){
	assert(o1 == o2, "%s not equal %s".format(o1, o2));
}
