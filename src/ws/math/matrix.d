
module ws.math.matrix;

import std.math, ws.string, ws.math.vector, ws.math.quaternion;

private alias float Type;


class Matrix(size_t Width, size_t Height) {


	Type[Width*Height] data;


	this(){
		for(size_t x=0; x<Width; ++x)
			for(size_t y=0; y<Height; y++)
				data[x + y*Width] = x==y ? 1 : 0;
	}
	

	this(Matrix o){
		data = o.data;
	}


	this(const Type[Width*Height] f){
		data = f;
	}


	Matrix dup(){
		return new Matrix(this);
	}


	Matrix opAssign(Type[Width*Height] f){
		data = f;
		return this;
	}


	ref Type opIndex(size_t i){
		return data[i];
	}

	ref Type opIndex(size_t x, size_t y){
		return data[y*Width+x];
	}


	@property static Matrix identity(){
		return new Matrix;
	}

	static if(Width == 4 && Height == 4){
		
		void scale(float x, float y, float z){
			auto t = new Matrix!(4,4);
			t[0] = x; t[5] = y; t[10] = z;
			this *= t;
		}
	
	
		void translate(float[3] v){
			auto t = new Matrix!(4,4);
			t[12] = v.x; t[13] = v.y; t[14] = v.z;
			this *= t;
		}
	
	
		void translate(Type x, Type y, Type z){
			auto t = new Matrix!(4,4);
			t[12] = x; t[13] = y; t[14] = z;
			this *= t;
		}
	
	
		void rotate(Quaternion q){
			data = (this*q).data;
		}
		
		
		void rotate(Type angle, Type x, Type y, Type z){
			double mag = sqrt(x*x + y*y + z*z);
			if (mag == 0.0)
				return;
			auto r = new Matrix!(4,4);
			double s = sin(angle*PI/180);
			double c = cos(angle*PI/180);
			double one_c = 1.0 - c;
			x /= mag;
			y /= mag;
			z /= mag;
			r.data[0] = (one_c*x*x) + c;
			r.data[4] = (one_c*x*y) - z*s;
			r.data[8] = (one_c*x*z) + y*s;
			r.data[1] = (one_c*y*x) + z*s;
			r.data[1+4] = (one_c*y*y) + c;
			r.data[1+8] = (one_c*y*z) - x*s;
			r.data[2] = (one_c*z*x) - y*s;
			r.data[2+4] = (one_c*z*y) + x*s;
			r.data[2+8] = (one_c*z*z) + c;
			this *= r;
		}

		Matrix inverse(){
			// http://rodolphe-vaillant.fr/?e=7
			auto res = new Matrix;
			Type MINOR(int r0, int r1, int r2, int c0, int c1, int c2)
			{
				return this[4*r0+c0] * (this[4*r1+c1] * this[4*r2+c2] - this[4*r2+c1] * this[4*r1+c2]) -
					   this[4*r0+c1] * (this[4*r1+c0] * this[4*r2+c2] - this[4*r2+c0] * this[4*r1+c2]) +
					   this[4*r0+c2] * (this[4*r1+c0] * this[4*r2+c1] - this[4*r2+c0] * this[4*r1+c1]);
			}
			Type det()
			{
				return this[0] * MINOR(1, 2, 3, 1, 2, 3) -
					   this[1] * MINOR(1, 2, 3, 0, 2, 3) +
					   this[2] * MINOR(1, 2, 3, 0, 1, 3) -
					   this[3] * MINOR(1, 2, 3, 0, 1, 2);
			}
			res[ 0] =  MINOR(1,2,3,1,2,3); res[ 1] = -MINOR(0,2,3,1,2,3); res[ 2] =  MINOR(0,1,3,1,2,3); res[ 3] = -MINOR(0,1,2,1,2,3);
			res[ 4] = -MINOR(1,2,3,0,2,3); res[ 5] =  MINOR(0,2,3,0,2,3); res[ 6] = -MINOR(0,1,3,0,2,3); res[ 7] =  MINOR(0,1,2,0,2,3);
			res[ 8] =  MINOR(1,2,3,0,1,3); res[ 9] = -MINOR(0,2,3,0,1,3); res[10] =  MINOR(0,1,3,0,1,3); res[11] = -MINOR(0,1,2,0,1,3);
			res[12] = -MINOR(1,2,3,0,1,2); res[13] =  MINOR(0,2,3,0,1,2); res[14] = -MINOR(0,1,3,0,1,2); res[15] =  MINOR(0,1,2,0,1,2);
			Type inv_det = 1.0 / det();
			for(int i = 0; i < 16; ++i)
				res[i] = res[i] * inv_det;
			return res;
		}

	}


	Matrix!(Height,Width) transpose(){
		auto res = new Matrix!(Height,Width);
		for(int x=0; x<Width; x++)
			for(int y=0; y<Height; y++)
				res[y, x] = this[x, y];
		return res;
	}
	

	Type[3] opBinary(string op)(Type[3] v) if(op=="*" && Width == 4) {
		Type[4] ve = v ~ 1;
		ve = opBinary!op(ve);
		return [ve[0], ve[1], ve[2]];
	}

	
	Type[Width] opBinary(string op)(Type[Width] v) if(op=="*") {
		Type[Width] res = 0;
		for(int x=0; x<Width; x++)
			for(int y=0; y<Height; y++)
				res[x] += v[y] * this[x, y];
		return res;
	}


	auto opBinary(string op, T)(T v) if(op=="*"){
		static if(is(T==Type)){
			
			auto o = new Matrix;
			for (long i=0; i<Width*Height; ++i)
				mixin("o[i] " ~ op ~ "= v;");
			return o;
							
		}else static if(is(T==Matrix)){
			
			auto o = new Matrix;
			for (int i = 0; i < Width; i++)
				for(int y = 0; y < Width; y++){
					o.data[i+Width*y] = 0;
					for(int x = 0; x < Width; x++)
						o.data[i+Width*y] += data[i+Width*x] * v.data[x+Width*y];
				}
			return o;
				
		}else static if(is(T==Quaternion)){
			
			auto o = new Matrix;
			o = this * v.matrix();
			return o;

		}else{
			import std.traits;
			static assert(false, "Cannot multiply Matrix!(%s,%s) with %s".format(Width,Height, fullyQualifiedName!T));
		}
	}
	
	
	Matrix opOpAssign(string op)(Matrix n){
		mixin("data = (this " ~ op ~ " n).data;");
		return this;
	}
	

	override string toString(){
		string s = "Matrix!(%,%){\n".tostring(Width, Height);
		for(size_t y=0; y<Height; y++){
			s ~= '\t';
			for(size_t x=0; x<Width; x++)
				s ~= ' '.tostring(data[y*Width+x], x==Width-1 ? (y==Height-1 ? "\n" : ",\n") : ",");
				//s ~= tostring(' ', data[y*Width+x], x==Width-1 ? (y==Height-1 ? "\n" : ",\n") : ",");
		}
		s ~= "}";
		return s;
	}


}


unittest {

	auto mat1 = new Matrix!(3,3)([
		1, 2, 3,
		4, 5, 6,
		7, 8, 9
	]);
	float[3] vec = [10, 11, 12];
	float[3] resultExpected = [
		mat1[0,0] * vec[0] + mat1[0,1] * vec[1] + mat1[0,2] * vec[2],
		mat1[1,0] * vec[0] + mat1[1,1] * vec[1] + mat1[1,2] * vec[2],
		mat1[2,0] * vec[0] + mat1[2,1] * vec[1] + mat1[2,2] * vec[2]
	];
	float[3] result = mat1*vec;
	assert(result == resultExpected);

}

