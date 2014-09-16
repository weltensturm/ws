module ws.math;

public import
	std.math,
	ws.math.matrix,
	ws.math.angle,
	ws.math.vector,
	ws.math.quaternion;


T clamp(T, E = T)(T a, E min, E max){
	return a<min ? min : (a>max ? max : a);
}


