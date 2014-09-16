module ws.physics.bullet.shape;

import
	ws.io,
	ws.file.obj,
	ws.math.vector,
	ws.physics.bullet.cbullet;


class Shape {

	this(string path){
		auto model = new DataOBJ("models/" ~ path);
		assert(model.vertices.length, "No vertices in physics model");
		btConvexHullShape*[] shapes;
		float[] centroids;
		foreach(object; model.objects){
			foreach(material; object.materials){
				Vector!3 centroid;
				foreach(poly; material.polygons)
					foreach(vert; poly){
						centroid += model.vertices[vert[0]];
					}

				centroid /= material.polygons.length*3;
				btScalar[] cloud;
				bool[size_t] indices;
				foreach(poly; material.polygons)
					foreach(vert; poly){
						if(vert[0] !in indices){
							indices[vert[0]] = true;
							foreach(num; (model.vertices[vert[0]]*2 - centroid))
								cloud ~= num;
						}
					}
				shapes ~= createShape(cloud.ptr, cast(int)(cloud.length/3));
				foreach(f; centroid)
					centroids ~= f;
			}
		}
		shape = loadSimpleCompound(shapes.ptr, centroids.ptr, cast(int)shapes.length);
	}

	btCompoundShape* shape;

}
