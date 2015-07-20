
module ws.math.angle;

import std.math;
import ws.math.vector;

struct Angle {

	float p, y, r;

	@property Vector!3 forward(){
		float pcos=cos(PI/180*p);
		return Vector!3(pcos*sin(PI/180*y), pcos*cos(PI/180*y), sin(PI/180*p));
	}

	@property Vector!3 up(){
		float pcos=cos(PI/180*p+90);
		return Vector!3(pcos*sin(PI/180*y), pcos*cos(PI/180*y), sin(PI/180*p+90));
	}

	@property Vector!3 right(){
		float rcos=cos(PI/180*r);
		return Vector!3(rcos*sin(PI/180*(y+90)), rcos*cos(PI/180*(y+90)), sin(PI/180*r));
	}

}
