module ws.physics.bullet.cbullet;

import ws.sys.library;

extern(C){
	
	struct btCompoundShape{}
	struct btConvexHullShape{}
	struct btDynamicsWorld{}
	struct btRigidBody{}
	struct BulletWorld{}
	struct DebugDrawer{}

	alias float btScalar;

	struct RayResult {
		btRigidBody* object;
		float distance;
		float x, y, z;
	}

	mixin library!(
		"cbullet", "cbullet",
		
		"setLinearVel", void function(btRigidBody*, btScalar, btScalar, btScalar),
		"getLinearVel", void function(btRigidBody*, btScalar*),
		"translate", void function(btRigidBody*, btScalar, btScalar, btScalar),
		"getTranslate", void function(btRigidBody*, btScalar*),
		"rotate", void function(btRigidBody*, btScalar*),
		"getRotate", void function(btRigidBody*, btScalar*),
		"setMass", void function(btRigidBody*, btScalar),
		"applyForce", void function(btRigidBody*, btScalar, btScalar, btScalar),
		"setUserPointer", void function(btRigidBody*, void*),
		"getUserPointer", void* function(btRigidBody*),

		"createDebugDrawer", "DebugDrawer* function(BulletWorld*, void*, void function(void* userdata, btScalar*, btScalar*, btScalar*))",
		"debugDrawWorld", void function(BulletWorld*),

		"createShape", btConvexHullShape* function(btScalar* points, int numPoints),
		"loadSimpleCompound", btCompoundShape* function(btConvexHullShape**, btScalar*, int),
		"createWorld", BulletWorld* function(),
		"destroyWorld", void function(BulletWorld*),
		"tickWorld", void function(BulletWorld*, btScalar),
		"getWorld", btDynamicsWorld* function(BulletWorld*),
		"addRigid", btRigidBody* function(btCompoundShape*, btScalar, btDynamicsWorld*),
		"removeRigid", void function(btDynamicsWorld*, btRigidBody*),
		"btDelete", void function(void*),
		"trace", RayResult function(BulletWorld*, btScalar sx, btScalar sy, btScalar sz, btScalar ex, btScalar ey, btScalar ez)
	);
	
}
