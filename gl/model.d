
module ws.gl.model;

import file = std.file, std.parallelism;

import
	std.path,
	std.file,
	std.algorithm,
	std.conv,
	ws.io,
	ws.exception,
	ws.thread.loader,
	ws.gl.gl,
	ws.gl.batch,
	ws.gl.texture,
	ws.gl.material,
	ws.file.obj,
	ws.file.bbatch,
	ws.log,
	ws.string,
	ws.math.vector;


__gshared:


class Model: Loadable {

	string path;
	BatchMaterial[] data;

	alias Ptr=void*;
	bool[Ptr] alreadyAdded;

	package Loader batchFinisher;
	package Loader materialFinisher;
	package Loader glFinisher;

	this(string p, Loader glFinisher=null, Loader batchFinisher=null, Loader materialFinisher=null){
		path = p;
		this.batchFinisher = batchFinisher;
		this.materialFinisher = materialFinisher;
		this.glFinisher = glFinisher;
		if(glFinisher)
			glFinisher.run(&finish);
		else
			finish;
	}

	override protected void finish(){
		loadState = Loading;
		if(path.extension == ".obj"){
			auto mdl = new OBJ("models/" ~ path);
			long count=0;
			foreach(object; mdl.objects){
				foreach(material; object.materials.values){
					count++;
					auto b = new BatchMaterial;
					if(batchFinisher)
						batchFinisher.run({
							synchronized(this){
								b.batch = new ModelBatch(material);
							}
						});
					else if(!glFinisher)
						b.batch = new ModelBatch(material);
					else
						assert(0, "Running in glFinisher but no way to finish batch in main");
					b.material = new ModelMaterial(mdl, material.name, materialFinisher);
					data ~= b;
				}
			}
			writeln("max ", count);
		}else if(path.extension == ".bb"){
			BinaryBatch mdl;
			if(!exists("models/" ~ path)){
				mdl = BinaryBatch.fromObj(path.setExtension("obj"));
				mdl.save;
			}else
				mdl = new BinaryBatch(path);
			foreach(vm; mdl.data){
				auto b = new BatchMaterial;
				data ~= b;
				batchFinisher.run({
					b.batch = new ModelBatch(vm);
				});
			}
		}else{
			assert(0, "Unknown extension in " ~ path);
		}
		loadState = Loaded;

	}

}

class BatchMaterial {
	ModelBatch batch;
	ModelMaterial material;
}

class ModelMaterial {

	DeferredMaterial material;
	alias material this;

	this(OBJ mdl, string material_name, Loader materialFinisher=null){
		try {
			material = new DeferredMaterial(mdl.path ~ ':' ~ material_name);
			float[3] col = [1,1,1];
			material.addUniform("diffuseColor", col);
			bool hasDiffuse = false;
			bool hasNormal = false;
			foreach(mtllib; mdl.mtllibs){
				foreach(mtl; mtllib.mtls){
					if(mtl.name == material_name){
						if(mtl.mapDiffuse.length){
							material.linkVertex("diffuse_tex", "forwardTexCoords");
							material.linkFragment("diffuse_tex");
							material.addTexture("diffuse", mtl.mapDiffuse);
							hasDiffuse = true;
						}
						if(mtl.mapBump.length){
							//material.linkVertex("normal_bump");
							material.linkFragment("normal_bump");
							material.addTexture("normal_bump", mtl.mapBump);
							hasNormal = true;
						}
						break;
					}
				}
			}
			if(!hasDiffuse){
				material.linkFragment("diffuse_default");
			}
			if(!hasNormal){
				material.linkVertex("normal_default", "forwardNormal");
				material.linkFragment("normal_default");
			}
			if(materialFinisher)
				materialFinisher.run(&material.finish);
			else
				material.finish;
		}catch(Exception e){
			Log.warning(e.toString());
			material = null;
		}
	}

}

class ModelBatch {
	
	Batch batch;
	alias batch this;

	this(OBJ.Material material){
		assert(!batch);
		batch = new Batch;
		batch.begin(material.vertcount);
		foreach(polygon; material.polygons){
			foreach(vertex; polygon.vertices){
				float[2] uvw = vertex.uvw.data[0..2];
				batch.addPoint(vertex.pos, vertex.normal, uvw);
			}
		}
		batch.finish();
	}

	this(VertMat vm){
		assert(!batch);
		batch = new Batch;
		batch.begin(cast(int)(vm.vertices.length));
		foreach(vert; vm.vertices)
			batch.addPoint(vert[0..3], vert[3..6], vert[6..8]);
		batch.finish;
	}
};


