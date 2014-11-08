
module ws.gl.model;

import file = std.file, std.parallelism;

import
	std.path,
	std.file,
	std.algorithm,
	std.conv,
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

	Loader mainFinisher;
	Loader glFinisher;

	this(string p, Loader glFinisher=null, Loader mainFinisher=null){
		path = p;
		this.mainFinisher = mainFinisher;
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
			foreach(object; mdl.objects){
				foreach(material; object.materials.values){
					auto b = new BatchMaterial;
					if(mainFinisher)
						mainFinisher.run({
							synchronized(this){
								b.batch = new ModelBatch(material);
							}
						});
					else if(!glFinisher)
						b.batch = new ModelBatch(material);
					else
						assert(0, "Running in glFinisher but no way to finish batch in main");
					b.material = new ModelMaterial(mdl, material.name, mainFinisher);
					data ~= b;
				}
			}
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
				mainFinisher.run({
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

	Material material;
	alias material this;

	this(OBJ mdl, string material_name, Loader materialFinisher=null){
		try {
			string[string] partsVertex = ["singlelight": "forwardSpecular"];
			string[string] partsFragment = ["singlelight": "getSpecular"];
			int[string] attributes = [
				"vertex": gl.attributeVertex,
				"normal": gl.attributeNormal,
				"texture": gl.attributeTexture
			];
			material = new Material(
				mdl.path ~ ':' ~ material_name, partsVertex, partsFragment, attributes
			);
			float[3] col = [1,1,1];
			material.addUniform("diffuseColor", col);
			foreach(mtllib; mdl.mtllibs){
				foreach(mtl; mtllib.mtls){
					if(mtl.name == material_name){
						if(mtl.mapDiffuse.length){
							material.linkVertex("texture", "getTexCoords");
							material.linkFragment("texture", "getTexColor");
							material.addTexture("Texture", mtl.mapDiffuse);
						}
						/*if(mtl.mapBump.length){
						partsVertex["bump"] = "forwardBump";
						partsFragment["bump"] = "getBump";
						b.material.addTexture("Bump", mtl.mapBump);
						}*/
						break;
					}
				}
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


