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


	void setVel(Vector!3 vel){
		onLoaded ~= {
			auto v = vel.to!double();
			setLinearVel(rigid, v.x, v.y, v.z);
		};
	}

	Vector!3 getVel(){
		if(loaded){
			btScalar[3] vel;
			getLinearVel(rigid, vel.ptr);
			return Vector!3(cast(float)vel[0], cast(float)vel[1], cast(float)vel[2]);
		}
		return Vector!3(); 
	}

	void setPos(Vector!3 pos){
		onLoaded ~= {
			auto v = (pos*2).to!double();
			ws.physics.bullet.cbullet.translate(rigid, v.x, v.y, v.z);
		};
	}

	Vector!3 getPos(){
		if(loaded){
			assert(rigid);
			btScalar[3] pos;
			getTranslate(rigid, pos.ptr);
			return Vector!3(cast(float)pos[0], cast(float)pos[1], cast(float)pos[2])/2;
		}
		return Vector!3();
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

	void applyForce(Vector!3 f){
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


	override void finish(){
		//shape = loadObjCompound(("models/"~path).toStringz());
		assert(shape);
		rigid = addRigid(shape.shape, 100, world);
		assert(rigid);
		setUserPointer(rigid, cast(void*)this);
		loadState = Loaded;
	}

}

