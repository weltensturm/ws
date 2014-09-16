
module ws.math.math;

public import std.math;

T clamp(T, E = T)(T a, E min, E max){
	return a<min ? min : (a>max ? max : a);
}

double pow(double n, double e){
	int sign = (n > 0 ? 1 : -1);
	double pow = (n*sign)^^e;
	return pow*sign;
}
