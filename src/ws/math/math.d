
module ws.math.math;

public import std.math;

T min(T, E=T)(T n1, E n2){
	return n1<n2 ? n1 : n2;
}

T max(T, E=T)(T n1, E n2){
	return n1>n2 ? n1 : n2;
}

T clamp(T, E = T)(T a, E min, E max){
	return a<min ? min : (a>max ? max : a);
}

double pow(double n, double e){
	int sign = (n > 0 ? 1 : -1);
	double pow = (n*sign)^^e;
	return pow*sign;
}
