module ws.math.transform;


import
	ws.math.vector,
	ws.math.quaternion,
	ws.math.matrix;


class Transform {
	
	protected Matrix!(4,4) matrix;

	this(Vector!3 pos, Quaternion ang){
		matrix = new Matrix!(4,4);
		matrix.rotate(ang);
		matrix.translate(pos);
	}

	Vector!3 to(Vector!3 pos){
		return Vector!3(matrix*pos);
	}

	Vector!3 from(Vector!3 pos){
		return Vector!3(matrix.inverse*pos);
	}

}