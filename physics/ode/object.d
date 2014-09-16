module ws.physics.ode.object;

import
	std.conv,
	ws.io,
	ws.math.vector,
	ws.math.quaternion,
	ws.file.obj,
	ws.thread.loader,
	ws.physics.ode.ode;

class OdeObject: Loadable {
	
	this(string path, Ode.World world, Ode.Space space){
		this.path = path;
		this.world = world;
		this.space = space;
	}

	string path;
	Ode.World world;
	Ode.Space space;

	protected {
		dGeomID[] odePrimitives;
		dBodyID odeBody;
	}


	void setVel(Vector!3 vel){
		onLoaded ~= {
			auto v = vel.to!double();
			dBodySetLinearVel(odeBody, v.x, v.y, v.z);
		};
	}

	Vector!3 getVel(){
		if(loaded){
			dReal* vel = dBodyGetLinearVel(odeBody);
			return Vector!3(cast(float)vel[0], cast(float)vel[1], cast(float)vel[2]);
		}
		return Vector!3(); 
	}

	void setPos(Vector!3 pos){
		onLoaded ~= {
			auto v = pos.to!double();
			dBodySetPosition(odeBody, v.x, v.y, v.z);
		};
	}

	Vector!3 getPos(){
		if(loaded){
			dReal* pos = dBodyGetPosition(odeBody);
			return Vector!3(cast(float)pos[0], cast(float)pos[1], cast(float)pos[2]);
		}
		return Vector!3();
	}
	
	void setAngle(Quaternion a){
		onLoaded ~= {
			dReal[4] data = [a.w, a.x, a.y, a.z];
			dBodySetQuaternion(odeBody, data);
		};
	}
	
	Quaternion getAngle(){
		if(!loaded)
			return Quaternion();
		dReal* data = dBodyGetQuaternion(odeBody);
		return Quaternion(data[0], data[1], data[2], data[3]);
	}

	void destroy(){
		assert(odeBody, "Object already destroyed");
		onLoaded ~= {
			dBodyDestroy(odeBody);
			odeBody = null;
			foreach(ref g; odePrimitives){
				dGeomDestroy(g);
				g = null;
			}
		};
	}


	void setMass(double m){
		dMassAdjust(&mass, m);
	}


	dMass mass;
	
	
	/+
	void makeStatic(bool t){
		dJointAttach(
	}
	+/


	/// Loads .obj models into an ODE TriMesh, thanks to Irrlicht
	override void finish(){
		assert(!odeBody, "Already initialized");
		auto model = new DataOBJ("models/" ~ path);
		dMassSetZero(&mass);
		odeBody = dBodyCreate(world.id);
		//if("mass" in model.options)
		//	mass = to!double(model.options["mass"]);
		foreach(object; model.objects){
			foreach(material; object.materials){
				assert(model.vertices.length, "No vertices in physics model");
				foreach(vertex; model.vertices)
					foreach(n; vertex)
						vertices ~= n;
				foreach(poly; material.polygons)
					foreach(index; poly)
						indices ~= index[0];
				dTriMeshDataID data = dGeomTriMeshDataCreate();
				dGeomTriMeshDataBuildSimple(
					data, cast(dReal*)vertices.ptr, vertices.length, indices.ptr, indices.length
				);
				auto geom = dCreateTriMesh(space.id, data, null, null, null);
				dGeomSetData(geom, cast(void*)this);
				dGeomSetBody(geom, odeBody);
				//dMass m;
				//dMassSetTrimesh(&m, 1, geom);
				//dMassAdd(&mass, &m);
				odePrimitives ~= geom;
			}
		}
		dMassSetBox(&mass, 1, 1, 1, 1);
		dBodySetMass(odeBody, &mass);
		loadState = Loaded;
	}

	private {
		uint[] indices;
		double[] vertices;
	}

}

