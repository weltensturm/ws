module ws.physics.bullet.object;

import
	std.conv,
	std.string,
	ws.io,
	ws.math.vector,
	ws.math.quaternion,
	ws.file.obj,
	ws.thread.loader,
	ws.physics.bullet.cbullet,
	ws.physics.bullet.shape;


class BulletObject: Loadable {
	
	this(BulletWorld* world, Shape shape){
		assert(world);
		this.shape = shape;
		this.path = path;
		this.world = getWorld(world);
	}

	string path;

	protected {
		btDynamicsWorld* world;
		Shape shape;
		btRigidBody* rigid;
	}


	void setVel(float[3] vel){
		onLoaded ~= {
			setLinearVel(rigid, vel[0], vel[1], vel[2]);
		};
	}

	float[3] getVel(){
		if(loaded){
			btScalar[3] vel;
			getLinearVel(rigid, vel.ptr);
			return [cast(float)vel[0], cast(float)vel[1], cast(float)vel[2]];
		}
		return [0,0,0];
	}

	void setPos(float[3] pos){
		onLoaded ~= {
			ws.physics.bullet.cbullet.translate(rigid, pos[0]*2, pos[1]*2, pos[2]*2);
		};
	}

	float[3] getPos(){
		if(loaded){
			assert(rigid);
			btScalar[3] pos;
			getTranslate(rigid, pos.ptr);
			return [pos[0]/2, pos[1]/2, pos[2]/2];
		}
		return [0,0,0];
	}
	
	void setAngle(Quaternion a){
		onLoaded ~= {
			btScalar[4] data = [a.z, -a.y, a.x, a.w];
			rotate(rigid, data.ptr);
		};
	}
	
	Quaternion getAngle(){
		if(!loaded)
			return Quaternion();
		btScalar[4] data;
		getRotate(rigid, data.ptr);
		return Quaternion(data[2], -data[1], data[0], data[3])*Quaternion.euler(0,-180,0);
	}

	void applyForce(float[3] f){
		ws.physics.bullet.cbullet.applyForce(rigid, f[0], f[1], f[2]);
	}

	void destroy(){
		onLoaded ~= {
			assert(rigid, "Object already destroyed");
			removeRigid(world, rigid);
		};
	}


	void setMass(double m){
		ws.physics.bullet.cbullet.setMass(rigid, m);
	}

	/+
	double getMass(){
		return ws.physics.bullet.cbullet.getMass(rigid);
	}
	+/

	override void finish(){
		//shape = loadObjCompound(("models/"~path).toStringz());
		assert(shape);
		rigid = addRigid(shape.shape, 100, world);
		assert(rigid);
		setUserPointer(rigid, cast(void*)this);
		loadState = Loaded;
	}

}

