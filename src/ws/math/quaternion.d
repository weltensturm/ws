module ws.math.quaternion;

import std.math, ws.math.matrix, ws.math.vector, ws.math.angle;


struct Quaternion {
	
	float w = 1;
	float x = 0;
	float y = 0;
	float z = 0;
	
	this(float iw, float ix, float iy, float iz){
		w = iw; x = ix; y = iy; z = iz;
	}
	
	this(float iw, Vector!3 v){
		fromAngleAxis(iw, v);
	}
	
	this(Angle a){
		this = euler(a);
	}
	
	@property Quaternion normal(){
		float len = length;
		return Quaternion(w/len, x/len, y/len, z/len);
	}
	
	void normalize(){
		float len = length;
		w /= len;
		x /= len;
		y /= len;
		z /= len;
	}
	
	@property float length(){
		return sqrt(x*x + y*y + z*z + w*w);
	}
	
	@property Vector!3 forward(){
		return this*Vector!3(0,0,-1);
	}
	
	@property Vector!3 up(){
		return this*Vector!3(0,1,0);
	}
 
	@property Vector!3 right(){
		return this*Vector!3(1,0,0);
    }

	@property Quaternion inverse(){
		return Quaternion(w, -x, -y, -z);
	}
	
	static Quaternion euler(Angle a){
		Quaternion q;
		float sinp = sin(a.p*PI/360);
		float siny = sin(a.y*PI/360);
		float sinr = sin(a.r*PI/360);
		float cosp = cos(a.p*PI/360);
		float cosy = cos(a.y*PI/360);
		float cosr = cos(a.r*PI/360);
		q.x = sinr*cosp*cosy - cosr*sinp*siny;
		q.y = cosr*sinp*cosy + sinr*cosp*siny;
		q.z = cosr*cosp*siny - sinr*sinp*cosy;
		q.w = cosr*cosp*cosy + sinr*sinp*siny;
		q.normalize();
		return q;
	}


	static Quaternion euler(double p, double y, double r){
		return euler(Angle(p, y, r));
	}


	Angle euler(){
		auto sqw = w*w;
		auto sqx = x*x;
		auto sqy = y*y;
		auto sqz = z*z;
		auto test = 2.0 * (y*w - x*z);
		Angle ang;
		if(test < 1.0001 && test > 0.9999){
			ang.y = -2.0*atan2(x, w);
			ang.r = 0;
			ang.p = PI/2;
		}else if(test > -1.0001 && test < -0.9999){
			ang.y = 2.0*atan2(x, w);
			ang.r = 0;
			ang.p = PI/-2;
		}else{
			ang.y = atan2(2*(x*y +z*w), (sqx - sqy - sqz + sqw));
			ang.r = atan2(2*(y*z +x*w),(-sqx - sqy + sqz + sqw));
			ang.p = asin(clamp(test, -1, 1));
		}
		ang.p = ang.p * 180/PI;
		ang.y = ang.y * 180/PI;
		ang.r = ang.r * 180/PI;
		return ang;
	}

	Quaternion fromAngleAxis(float angle, Vector!3 dir){
		auto v = dir.normal;
		auto s = sin(angle*PI/360);
		this = Quaternion(
			cos(angle/PI/360),
			v.x*s,
			v.y*s,
			v.z*s
		).normal;
		return this;
	}


	void rotate(float angle, float x, float y, float z){
		rotate(angle, Vector!3(x,y,z));
	}


	void rotate(float angle, Vector!3 v){
		Quaternion t;
		t.fromAngleAxis(angle, v);
		this = t*this;
	} 


	Matrix!(4,4) matrix(){
		float x2 = x * x;
		float y2 = y * y;
		float z2 = z * z;
		float xy = x * y;
		float xz = x * z;
		float yz = y * z;
		float wx = w * x;
		float wy = w * y;
		float wz = w * z;

		return new Matrix!(4,4)([
			1-2*(y2 + z2), 2*(xy - wz), 2*(xz + wy), 0,
			2*(xy + wz), 1-2*(x2 + z2), 2*(yz - wx), 0,
			2*(xz - wy), 2*(yz + wx), 1-2*(x2 + y2), 0,
			0, 0, 0, 1
		]);
	}

	Quaternion opBinary(string op)(Quaternion other) if(op=="*"){
		return Quaternion(
			w * other.w - x * other.x - y * other.y - z * other.z,
			w * other.x + x * other.w + y * other.z - z * other.y,
			w * other.y + y * other.w + z * other.x - x * other.z,
			w * other.z + z * other.w + x * other.y - y * other.x
		);
	}

	Vector!3 opBinary(string op)(Vector!3 v) if(op=="*"){
		auto o = this*(Quaternion(0, v.x, v.y, v.z)*inverse);
		return Vector!3(o.x, o.y, o.z);
	}

	void opOpAssign(string op, T)(T other){
		mixin("this = this " ~ op ~ " other;");
	}

}

private double clamp(double n, double min, double max){
	return n < min ? min : (n > max ? max : n);
}

unittest {

	import std.string;
	void assertEqual(T1, T2)(T1 o1, T2 o2){
		assert(o1 == o2, "%s not equal %s".format(o1, o2));
	}

	assertEqual((Quaternion(Angle(0,0,90))*Vector!3(0,1,0)).normal, Vector!3(0,0,1));
	assertEqual((Quaternion(Angle(-90,0,0))*Vector!3(1,0,0)).normal, Vector!3(0,0,1));
	assertEqual((Quaternion(Angle(0,90,0))*Vector!3(1,0,0)).normal, Vector!3(0,1,0));
	Quaternion f = Angle(0,95,90);
	assertEqual(f.euler(), Angle(0,95,90));
	Quaternion conv = Quaternion.euler(f.euler());
	assertEqual(f, conv);
}



