
module ws.physics.ode.ode;

import ws.math.vector, ws.io, ws.exception;
public import derelict.ode.ode;

version(Windows)
	pragma(lib, "DerelictODE.lib");

class Ode {
	
	this(){
		DerelictODE.load();
		dInitODE();
	}
	void load(args...)(){
		foreach(s; args)
			mixin(s ~ " = cast(typeof(" ~ s ~ "))get(\"" ~ s ~ "\");");
	}
	
	static class World {
		this(){
			id = dWorldCreate(); 
		}
		~this(){
			dWorldDestroy(id);
		}
		dWorldID id;
		Body createBody(){
			return new Body(dBodyCreate(id));
		}
		void setGravity(dReal x, dReal y, dReal z){
			dWorldSetGravity(id, x, y, z);
		}
		void setCFM(dReal n){
			dWorldSetCFM(id, n);
		}
		void quickStep(dReal step){
			dWorldQuickStep(id, step);
		}
	}
	
	
	static class Space {
		
		this(){
			id = dHashSpaceCreate(null);
		}
		~this(){
			dSpaceDestroy(id);
		}
		
		extern(C) static staticCollide(void* data, dGeomID g1, dGeomID g2){
			(*(cast(void delegate(Geom,Geom)*)data))(new Geom(g1), new Geom(g2));
		}
		
		void collide(void delegate(Geom g1, Geom g2) callback){
			dSpaceCollide(id, cast(void*)&callback, &staticCollide);
		}
		
		Geom createSphere(dReal radius){
			return new Geom(dCreateSphere(id, radius));
		}
		
		void createPlane(dReal a, dReal b, dReal c, dReal d){
			dCreatePlane(id, a, b, c, d);
		}
		
		dSpaceID id;
	}
	
	
	static class Geom {
		dGeomID id;
		this(dGeomID i){
			id = i;
		}
		void setBody(Body b){
			dGeomSetBody(id, b.id);
		}
		Vector!3 getPos(){
			const(dReal)* p = dGeomGetPosition(id);
			return Vector!3(p[0], p[1], p[2]);
		}
		Body getBody(){
			auto b = dGeomGetBody(id);
			if(!b)
				exception("Geom does not have Body");
			return new Body(b);
		}
		/+Quaternion getAngle(){
			dReal* a = dGeomGetRotation(id);
		}+/
	}
	
	
	static class Body {
		this(dBodyID i){
			if(!i)
				exception("Invalid dBodyID");
			id = i;
			dMassSetSphereTotal(&mass, 1, 1);
			dBodySetMass(id, &mass);
		}
		dBodyID id;
		void setMass(dReal m){
			dMassSetSphereTotal(&mass, 1, m);
		}
		void setPos(dReal x, dReal y, dReal z){
			dBodySetPosition(id, x, y, z);
		}
		Vector!3 getPos(){
			dReal* p = dBodyGetPosition(id);
			return Vector!3(p[0], p[1], p[2]);
		}
		dMass mass;
	}
	
	
}

