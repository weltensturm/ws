module ws.math.fixedpoint;


/+
	Type: int
	Max: 21474.83647
+/

class Fixedpoint(Type){
	
	Type n = 0;
	
	Fixedpoint opBinary(string op)(Type o){
		mixin("Fixedpoint t = (cast(long double)n)/(sizeof(Type)/2)*8;"); 
	}
	
}