module ws.math.collision;


import 
	ws.math.math,
	ws.math.vector;


struct Line {
	float[3] origin;
	float[3] dir;
}

struct Plane {
	float[3] origin;
	float[3] normal;
}

struct Cube {
	float[3] origin;
	float scale;
}

class Result {
	bool hit;
}

class LinePlaneResult: Result {
	float[3] pos;
}

class LineCubeResult: Result {
	float[3] pos;
	float[3] normal;
	float distance;
}

LinePlaneResult collide(Line line, Plane plane){
	auto numerator = (plane.origin.vec - line.origin.vec) * plane.normal.vec;
	auto denominator = line.dir.vec*plane.normal.vec;
	auto res = new LinePlaneResult;
	res.hit = numerator/denominator > 0.0001;
	res.pos = line.origin.vec + line.dir.vec*(numerator/denominator);
	return res;
}


LineCubeResult collide(Line line, Cube cube){
	
	auto lb = cube.origin.vec-vec(1,1,1)/2*cube.scale;
	auto rt = cube.origin.vec+vec(1,1,1)/2*cube.scale;
	
	float[3] dirfrac;
	dirfrac.x = 1.0f / line.dir.x;
	dirfrac.y = 1.0f / line.dir.y;
	dirfrac.z = 1.0f / line.dir.z;

	float t1 = (lb.x - line.origin.x)*dirfrac.x;
	float t2 = (rt.x - line.origin.x)*dirfrac.x;
	float t3 = (lb.y - line.origin.y)*dirfrac.y;
	float t4 = (rt.y - line.origin.y)*dirfrac.y;
	float t5 = (lb.z - line.origin.z)*dirfrac.z;
	float t6 = (rt.z - line.origin.z)*dirfrac.z;

	float tmin = fmax(fmax(fmin(t1, t2), fmin(t3, t4)), fmin(t5, t6));
	float tmax = fmin(fmin(fmax(t1, t2), fmax(t3, t4)), fmax(t5, t6));

	if (tmax < 0 || tmin > tmax)
	    return null;

	auto res = new LineCubeResult;
	res.distance = tmin;
	res.pos = line.origin.vec + line.dir.vec*res.distance;
	auto help = (res.pos.vec - cube.origin.vec)/cube.scale*2.0001;
	res.normal = help.to!int.to!float;
	return res;
}


float[3] line_plane(float[3] lineStart, float[3] lineDir, float[3] planeOrigin, float[3] planeNormal){
	auto numerator = (vec(planeOrigin) - vec(lineStart)) * vec(planeNormal);
	auto denominator = vec(lineDir)*vec(planeNormal);
	return vec(lineStart) + vec(lineDir)*(numerator/denominator);
}
