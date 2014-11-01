
module ws.gl.model;

import file = std.file, std.parallelism;

import
	std.path,
	std.file,
	ws.exception,
	ws.thread.loader,
	ws.gl.gl,
	ws.gl.batch,
	ws.gl.texture,
	ws.gl.material,
	ws.file.obj,
	ws.file.bbatch,
	ws.io,
	ws.log,
	ws.string,
	ws.math.vector;


__gshared:


class Model: Loadable {

	string path;
	BatchMaterial[] data;

	Loader mainFinisher;

	this(string p, Loader glFinisher=null, Loader mainFinisher=null){
		path = p;
		this.mainFinisher = mainFinisher;
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
					data ~= b;
					if(mainFinisher)
						mainFinisher.run({b.finishBatch(material);});
					else
						b.finishBatch(material);
					b.finishMaterial(mdl, material.name);
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
				b.finishBatch(vm);
			}
		}else{
			assert(0, "Unknown extension in " ~ path);
		}
		loadState = Loaded;
	}

	class BatchMaterial {

		Batch batch;
		Material mat;

		private:

			void finishBatch(OBJ.Material material){
				assert(!batch);
				assert(material);
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

			void finishBatch(VertMat vm){
				assert(!batch);
				batch = new Batch;
				batch.begin(cast(int)(vm.vertices.length));
				foreach(vert; vm.vertices)
					batch.addPoint(vert[0..3], vert[3..6], vert[6..8]);
				batch.finish;
			}

			void finishMaterial(OBJ mdl, string material_name){
				assert(!mat);
				try {
					string[string] partsVertex = ["singlelight": "forwardSpecular"];
					string[string] partsFragment = ["singlelight": "getSpecular"];
					int[string] attributes = [
						"vertex": gl.attributeVertex,
						"normal": gl.attributeNormal,
						"texture": gl.attributeTexture
					];
					mat = new Material(
						path ~ ':' ~ material_name, partsVertex, partsFragment, attributes
					);
					float[3] col = [1,1,1];
					mat.addUniform("diffuseColor", col);
					foreach(mtllib; mdl.mtllibs){
						foreach(mtl; mtllib.mtls){
							if(mtl.name == material_name){
								if(mtl.mapDiffuse.length){
									mat.linkVertex("texture", "getTexCoords");
									mat.linkFragment("texture", "getTexColor");
									mat.addTexture("Texture", mtl.mapDiffuse);
								}
								/*if(mtl.mapBump.length){
								partsVertex["bump"] = "forwardBump";
								partsFragment["bump"] = "getBump";
								b.mat.addTexture("Bump", mtl.mapBump);
								}*/
								break;
							}
						}
					}
					if(mainFinisher)
						mainFinisher.run(&mat.finish);
					else
						mat.finish;
				}catch(Exception e){
					Log.warning(e.toString());
					mat = null;
				}
			}

	};

}



